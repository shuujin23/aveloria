extends Control
## Layar battle isometrik: party di kiri-bawah, musuh di kanan-atas.
## Tiap ronde pemain memilih perintah untuk semua anggota party, lalu aksi dijalankan satu per satu
## lengkap dengan animasi. Aturan battle sendiri ada di BattleEngine; file ini hanya tampilan.
##
## Susunan node:
##   _world (Node2D, ikut bergetar saat layar diguncang)
##     tanah (satu gambar yang disusun dari petak-petak)
##     _unit_layer (y-sort: sprite party dan monster)
##     _fx (efek: tebasan, proyektil, partikel)
##   _tint (warna suasana untuk jurus besar)
##   _tags (batang HP di kaki tiap monster)
##   panel bawah (menu, pesan, status party)

signal results_closed  # pemain menekan Lanjut di layar hasil pertarungan

const MSG_DELAY := 0.45
const SPRITES := "res://assets/sprites/"
const PIXEL := 3.0  # sprite digambar 1x, ditampilkan 3x
const FIELD_CENTER := Vector2(640, 235)
const FIELD_HEIGHT := 414.0  # bagian layar di atas panel
const TILE_HALF := Vector2(48, 24)  # setengah ukuran petak di layar

# Jenis animasi -> efek suara saat aksi dimulai (kunci di Audio.SFX).
const FX_SOUND := {"attack": "swing", "heavy_slash": "swing", "spin": "swing", "bite": "bite", "fire": "fire",
	"ice_storm": "ice", "light": "magic", "arrow": "arrow", "arrow_rain": "arrow", "heal": "heal", "heal_all": "heal",
	"bless": "buff", "rally": "buff", "debuff": "debuff", "spore": "slime", "quake": "quake", "guard": "guard",
	"lava": "fire", "dark": "magic"}

const STATUS_ICON_SIZE := Vector2(24, 24)  # ikon efek status 12x12 ditampilkan 2x
const COLOR_PANEL := Color("0f1622")
const COLOR_BORDER := Color("c9a85c")
const COLOR_ACTIVE := Color("ffd866")
const COLOR_DOWN := Color("d0655a")
const GearIcon := preload("res://scripts/ui/gear_icon.gd")

# Posisi berdiri dalam koordinat petak arena (0,0 = tengah). Urutan = urutan anggota party.
const PARTY_SLOTS := [Vector2(0, 1), Vector2(0, 4), Vector2(-3, 4), Vector2(-3, 1)]
const ENEMY_SLOTS := {
	1: [Vector2(2.5, -1.5)],  # agak ke depan supaya bos yang tinggi tidak terpotong di atas layar
	2: [Vector2(0, -2.5), Vector2(3, -2.5)],
	3: [Vector2(0, -1.5), Vector2(3, -1.5), Vector2(1.5, -4)],
	4: [Vector2(0, -1), Vector2(3, -1), Vector2(0, -4), Vector2(3, -4)],
}
# Titik kaki tiap sprite (piksel 1x).
const HERO_ANCHOR := Vector2(12, 30)
const MONSTER_ANCHOR := {
	"jamur": Vector2(18, 32), "kelelawar": Vector2(22, 34), "serigala": Vector2(26, 32),
	"goblin": Vector2(18, 40), "ogre": Vector2(34, 66),
	"laba_laba": Vector2(24, 29), "roh_kabut": Vector2(16, 36), "ratu": Vector2(40, 55),
	"kadal_bara": Vector2(26, 26), "elang_abu": Vector2(26, 34), "golem_batu": Vector2(22, 44), "lahar": Vector2(36, 73),
	"ksatria_kelam": Vector2(22, 44), "bayangan": Vector2(16, 36), "gargoyle": Vector2(26, 34), "raja": Vector2(34, 78),
	"lendir_emas": Vector2(18, 29), "mata_kabut": Vector2(18, 39), "kura_magma": Vector2(26, 31), "peti_terkutuk": Vector2(19, 33),
}
# Per latar: bahan tanah, jumlah variannya, hiasan di belakang arena, dan kerapatannya.
const ARENAS := {
	"lembah": {"ground": "grass", "variants": 3, "decor": ["tree_round", "tree_pine"], "rate": 0.2},
	"hutan": {"ground": "forest_floor", "variants": 2, "decor": ["tree_round", "tree_pine", "tree_round"], "rate": 0.75},
	"kabut": {"ground": "mist_grass", "variants": 3, "decor": ["mist_round", "mist_pine"], "rate": 0.6},
	"gua": {"ground": "rock", "variants": 2, "decor": ["hill_0", "hill_1"], "rate": 0.7},
	"abu": {"ground": "ash", "variants": 3, "decor": ["dead_tree_0", "hill_0", "dead_tree_1", "hill_1"], "rate": 0.5},
	"kawah": {"ground": "cinder", "variants": 2, "decor": ["hill_0", "hill_1", "dead_tree_0"], "rate": 0.6},
	"kastil": {"ground": "floor", "variants": 3, "decor": ["wall_block"], "rate": 1.0},
	"takhta": {"ground": "carpet", "variants": 2, "decor": ["wall_block"], "rate": 1.0},
}

var engine: BattleEngine

var _units := {}  # Battler -> {"sprite": Sprite2D, "home": Vector2, "height": float, "tag": Control, "bar": ProgressBar}
var _shown_hp := {}  # Battler -> HP yang terakhir ditampilkan, untuk mendeteksi siapa yang baru kena
var _party_rows: Array = []  # {"name": Label, "stats": Label, "bar": ProgressBar}
var _order: Array = []  # petarung dalam urutan giliran ronde ini
var _turn := -1  # indeks giliran yang sedang berjalan di _order
var _current: Battler  # tokoh yang sedang memilih perintah (null saat aksi berjalan)
var _last_cmd := {}  # perintah terakhir yang dipilih pemain
var _hold := false  # uji tampilan: perintah hanya dicatat, tidak dijalankan
var _back_cb := Callable()

var _world: Node2D
var _unit_layer: Node2D
var _fx: Node2D
var _cursor: Polygon2D
var _tint: ColorRect
var _tags: Control
var _info: Label
var _hint: Label
var _menu_title: Label
var _menu_box: VBoxContainer
var _log: RichTextLabel
var _bag: PanelContainer  # tampilan tas (scripts/ui/bag_view.gd)
var _bag_actor: Battler
var _results: PanelContainer  # layar hasil pertarungan
var _results_running := false  # batang XP masih terisi
var _results_skip := false
var _pick_list: Array = []  # sasaran yang sedang bisa dipilih (kosong = tidak sedang memilih sasaran)
var _pick_cb := Callable()
var _hover: Battler  # unit di bawah penunjuk mouse saat memilih sasaran
var _active_ring: Line2D  # lingkaran emas di kaki tokoh yang sedang memilih perintah / sedang beraksi
var _target_ring: Line2D  # lingkaran di kaki sasaran yang sedang disorot
var _banner: Label  # keterangan di atas arena: giliran siapa dan sedang apa
var _order_box: HBoxContainer  # urutan aksi ronde ini
var _order_chips: Array = []


func _ready() -> void:
	_build_ui()
	_build_bag()
	_new_battle()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var back_pressed := event.is_action_pressed("ui_cancel") \
		or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT)
	if back_pressed and _back_cb.is_valid():  # Esc atau klik kanan: kembali
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_cancel")
		_back_cb.call()
		return
	if _pick_list.is_empty():
		return
	# Sedang memilih sasaran: arahkan mouse ke petarung di arena lalu klik.
	var motion := event as InputEventMouseMotion
	if motion != null:
		var unit := _unit_at(motion.position)
		if unit != _hover:
			_hover = unit
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if unit != null else Input.CURSOR_ARROW)
			if unit != null:
				_point_at(unit)
				_hint.text = _describe(unit)
				Audio.sfx("ui_move")
	elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var unit := _unit_at(click.position)
		if unit != null:
			get_viewport().set_input_as_handled()
			Audio.sfx("ui_ok")
			var on_pick := _pick_cb
			on_pick.call(unit)


## Sasaran sah yang berada di bawah sebuah titik layar (yang terdekat kalau bertumpuk).
func _unit_at(pos: Vector2) -> Battler:
	var best: Battler = null
	var best_distance := INF
	for b: Battler in _pick_list:
		var rect: Rect2 = _units[b].rect
		if rect.grow(6).has_point(pos):
			var distance := pos.distance_to(rect.get_center())
			if distance < best_distance:
				best = b
				best_distance = distance
	return best


## Keterangan singkat seorang petarung: HP/MP untuk rekan, stat untuk musuh, plus efek status.
func _describe(b: Battler) -> String:
	var text := "%s   ATK %d  DEF %d  SPD %d" % [b.display_name, roundi(b.stat("atk")), roundi(b.stat("defense")), roundi(b.stat("agi"))]
	if b.is_enemy and Db.rarity_of(b.id) != "common":
		text = "[%s]  %s" % [Db.RARITIES[Db.rarity_of(b.id)].name, text]
	if not b.is_enemy:
		text = "%s   HP %d/%d  MP %d/%d" % [b.display_name, b.hp, b.max_hp, b.mp, b.max_mp]
	var tags := _status_tags(b)
	return text if tags == "" else "%s   [%s]" % [text, tags]


## Perintah dalam satu baris, mis. "Bola Api > Goblin Perampok" atau "Bertahan".
func _cmd_text(cmd: Dictionary) -> String:
	var target: Battler = cmd.get("target")
	var to := "" if target == null else " > %s" % target.display_name
	match cmd.kind:
		"attack":
			return Loc.t("Serang") + to
		"defend":
			return Loc.t("Bertahan")
		"item":
			return String(Loc.t(Db.ITEMS[cmd.item].name)) + to
		"skill":
			var sk: Dictionary = Db.SKILLS[cmd.skill]
			var is_enemy: bool = (cmd.actor as Battler).is_enemy
			match sk.target:
				"all_enemies":
					to = Loc.t(" > seluruh party") if is_enemy else Loc.t(" > semua musuh")
				"all_allies":
					to = Loc.t(" > semua monster") if is_enemy else Loc.t(" > seluruh party")
				"self":
					to = ""
			return String(Loc.t(sk.name)) + to
	return ""


func _set_banner(text: String) -> void:
	_banner.text = text
	(_banner.get_parent().get_parent() as Control).visible = text != ""


## Lingkaran emas di kaki petarung yang sedang memilih perintah atau sedang beraksi.
func _mark_active(b: Battler) -> void:
	_active_ring.visible = b != null and _units.has(b)
	if _active_ring.visible:
		_active_ring.position = _home(b) + Vector2(0, 2)


## Deretan nama sesuai urutan giliran ronde ini (ditentukan SPD), tampil sejak awal ronde.
func _build_order() -> void:
	for child in _order_box.get_children():
		_order_box.remove_child(child)
		child.queue_free()
	_order_chips.clear()
	for b: Battler in _order:
		var chip := Label.new()
		chip.text = " %s " % b.display_name
		chip.add_theme_font_size_override("font_size", 13)
		_order_box.add_child(chip)
		_order_chips.append(chip)
	_order_box.visible = true
	_mark_order()


## Tandai giliran yang sedang berjalan: yang sudah lewat diredupkan, yang sedang beraksi berlatar emas.
func _mark_order() -> void:
	for i in _order_chips.size():
		var chip: Label = _order_chips[i]
		var b: Battler = _order[i]
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(3)
		box.bg_color = Color("5a2a2a") if b.is_enemy else Color("24406a")
		chip.add_theme_color_override("font_color", Color.WHITE)
		chip.modulate.a = 1.0
		if i == _turn:
			box.bg_color = COLOR_ACTIVE
			chip.add_theme_color_override("font_color", Color("10141c"))
		elif i < _turn or not b.is_alive():
			chip.modulate.a = 0.35
		chip.add_theme_stylebox_override("normal", box)

# ---------------------------------------------------------------- alur battle

func _new_battle() -> void:
	# Kalau scene ini dijalankan langsung (tanpa lewat peta), pakai kelompok acak untuk uji coba.
	var ids: Array = Game.encounter if not Game.encounter.is_empty() else Db.random_group("lembah_padang")
	engine = BattleEngine.new(Game.party, BattleEngine.make_encounter(ids))
	engine.items = Game.items
	var music := "battle" if engine.can_flee() else "boss"
	for e: Battler in engine.enemies:
		if e.id == "raja":
			music = "raja"
	Audio.play_music(music)
	_current = null
	_log.clear()
	_build_units()
	_show_menu("", [])
	_refresh()
	if not engine.can_flee():
		var boss: Battler = engine.enemies[0]
		for e: Battler in engine.enemies:
			if e.is_boss:
				boss = e
		await _say(Loc.t("%s menghadang jalan!") % boss.display_name)
	else:
		await _say(Loc.t("Segerombolan monster muncul!"))
		for e: Battler in engine.enemies:
			if Db.rarity_of(e.id) == "super":
				Audio.sfx("buff")
				await _say(Loc.t("Monster super rare: %s! Bahannya sangat langka.") % e.display_name)
	if not engine.opening_lines.is_empty():  # sifat perlengkapan yang aktif di awal pertarungan
		_refresh()
		for line: String in engine.opening_lines:
			await _say(line)
	_start_round()


## Awal ronde: urutan giliran diundi sekali (SPD tertinggi cenderung lebih dulu) dan langsung ditampilkan,
## lalu tiap petarung beraksi saat gilirannya tiba.
func _start_round() -> void:
	_order = engine.round_order()
	_turn = -1
	_build_order()
	_next_turn()


## Lanjut ke petarung berikutnya di urutan ronde ini; kalau sudah habis, tutup rondenya.
func _next_turn() -> void:
	_turn += 1
	while _turn < _order.size() and not (_order[_turn] as Battler).is_alive():
		_turn += 1
	if _turn >= _order.size():
		_end_round()
		return
	var actor: Battler = _order[_turn]
	_mark_order()
	if actor.is_enemy:
		_current = null
		_refresh()
		_run_turn(engine.enemy_command(actor))
	else:
		_current = actor
		_ask_command()


## Tampilkan menu perintah untuk tokoh yang sedang mendapat giliran.
func _ask_command() -> void:
	var actor := _current
	_refresh()
	var foes := engine.living(engine.enemies)
	var items: Array = [
		{"text": Loc.t("Serang"), "hint": Loc.t("Serangan biasa ke satu musuh."), "unit": actor,
			"cb": func() -> void: _pick_target(Loc.t("Serang siapa?"), foes,
				func(t: Battler) -> void: _push({"actor": actor, "kind": "attack", "target": t}))},
		{"text": Loc.t("Jurus"), "hint": Loc.t("Gunakan jurus khusus (memakai MP)."), "disabled": actor.skills.is_empty(), "unit": actor,
			"cb": func() -> void: _skill_menu(actor)},
		{"text": Loc.t("Barang"), "hint": Loc.t("Pakai barang dari tas."), "disabled": not _has_items(), "unit": actor,
			"cb": func() -> void: _item_menu(actor)},
		{"text": Loc.t("Bertahan"), "hint": Loc.t("Kerusakan yang diterima sampai giliran berikutnya jadi setengah, dan MP pulih dua kali lipat."), "unit": actor,
			"cb": func() -> void: _push({"actor": actor, "kind": "defend"})},
		{"text": Loc.t("Kabur"), "hint": Loc.t("Coba melarikan diri. Kalau gagal, giliran ini hangus."), "unit": actor,
			"disabled": not engine.can_flee(), "cb": _attempt_flee},
	]
	_show_menu(Loc.t("Giliran %s (%s)") % [actor.display_name, Loc.t(actor.job)], items)
	_set_banner(Loc.t("Giliran %s: pilih perintah") % actor.display_name)
	_mark_active(actor)


func _skill_menu(actor: Battler) -> void:
	_set_banner(Loc.t("%s: pilih jurus") % actor.display_name)
	var items: Array = []
	for skill_id: String in actor.skills:
		var sk: Dictionary = Db.SKILLS[skill_id]
		items.append({"text": "%s  (%d MP)" % [Loc.t(sk.name), sk.mp], "hint": Loc.t(sk.desc), "disabled": actor.mp < sk.mp, "unit": actor,
			"cb": func() -> void: _choose_skill(actor, skill_id)})
	_show_menu(Loc.t("Jurus %s") % actor.display_name, items, _ask_command)


func _choose_skill(actor: Battler, skill_id: String) -> void:
	var sk: Dictionary = Db.SKILLS[skill_id]
	var cmd := {"actor": actor, "kind": "skill", "skill": skill_id}
	var on_pick := func(t: Battler) -> void:
		cmd["target"] = t
		_push(cmd)
	match sk.target:
		"enemy":
			_pick_target(Loc.t("%s ke siapa?") % Loc.t(sk.name), engine.living(engine.enemies), on_pick,
				func() -> void: _skill_menu(actor))
		"ally":
			_pick_target(Loc.t("%s untuk siapa?") % Loc.t(sk.name),
				engine.living(engine.others(actor) if sk.kind == "mp" else engine.party), on_pick,
				func() -> void: _skill_menu(actor))
		_:
			_push(cmd)


func _available(item_id: String) -> int:
	return int(Game.items.get(item_id, 0))


func _has_items() -> bool:
	for item_id: String in Db.ITEMS:
		if _available(item_id) > 0:
			return true
	return false


## Sasaran yang sah untuk sebuah barang: Air Kehidupan hanya untuk rekan yang tumbang,
## barang lain untuk yang masih berdiri.
func _item_targets(item_id: String) -> Array:
	var targets: Array = []
	for m: Battler in engine.party:
		if m.is_alive() != (Db.ITEMS[item_id].kind == "revive"):
			targets.append(m)
	return targets


## Buka tampilan tas untuk memilih barang yang dipakai `actor` di gilirannya.
func _item_menu(actor: Battler) -> void:
	_bag_actor = actor
	_show_menu(Loc.t("Barang"), [])
	var counts := {}
	for item_id: String in Db.ITEMS:
		if _available(item_id) > 0:
			counts[item_id] = _available(item_id)
	_bag.open(counts, Game.bag_slots,
		func(item_id: String) -> bool: return not _item_targets(item_id).is_empty(), false)


func _on_bag_picked(item_id: String) -> void:
	_bag.visible = false
	var actor := _bag_actor
	_pick_target(Loc.t("%s untuk siapa?") % Loc.t(Db.ITEMS[item_id].name), _item_targets(item_id),
		func(t: Battler) -> void: _push({"actor": actor, "kind": "item", "item": item_id, "target": t}),
		func() -> void: _item_menu(actor))


func _on_bag_closed() -> void:
	_bag.visible = false
	_ask_command()

## Pilih sasaran: lewat daftar di menu, atau dengan mengarahkan mouse ke petarung di arena lalu klik.
func _pick_target(title: String, list: Array, on_pick: Callable, back: Callable = _ask_command) -> void:
	var items: Array = []
	for t: Battler in list:
		items.append({"text": t.display_name, "hint": _describe(t), "unit": t,
			"cb": func() -> void: on_pick.call(t)})
	_show_menu(title, items, back)
	_pick_list = list
	_pick_cb = on_pick
	_set_banner(Loc.t("%s   Klik sasaran di arena, atau pilih dari daftar.") % title)
	if not list.is_empty():
		_point_at(list[0])


## Perintah sudah lengkap: langsung jalankan sebagai giliran tokoh itu.
func _push(cmd: Dictionary) -> void:
	_last_cmd = cmd
	if _hold:  # uji tampilan: perintah hanya dicatat, lalu menu yang sama dibuka lagi
		_ask_command()
		return
	_current = null
	_run_turn(cmd)


## Kabur menghabiskan giliran tokoh yang mencobanya kalau gagal.
func _attempt_flee() -> void:
	_current = null
	_show_menu("", [])
	_refresh()
	await _say(Loc.t("Party mencoba kabur..."))
	if engine.try_flee():
		Audio.sfx("flee")
		await _say(Loc.t("Berhasil lolos!"))
		_mark_active(null)
		_set_banner("")
		_show_menu(Loc.t("Lolos"), [{"text": Loc.t("Lanjut"), "hint": Loc.t("Kembali ke peta."),
			"cb": func() -> void: Game.return_to_world()}])
	else:
		await _say(Loc.t("Gagal! Jalan keluar terhalang."))
		_next_turn()


## Jalankan satu giliran (tokoh atau monster) lengkap dengan animasinya, lalu lanjut ke giliran berikutnya.
func _run_turn(cmd: Dictionary) -> void:
	_show_menu("", [])
	var actor: Battler = cmd.actor
	_mark_active(actor)
	# Mesin battle langsung mengubah HP; tampilan baru diperbarui tepat saat animasi "mengenai".
	var targets := engine.resolve_targets(cmd)
	var animate: bool = cmd.kind != "skill" or actor.mp >= int(Db.SKILLS[cmd.skill].mp)
	_set_banner(Loc.t("Giliran %s:   %s") % [actor.display_name, _cmd_text(cmd)])
	var lines := engine.execute(cmd)
	if not lines.is_empty():
		_log.append_text(String(lines[0]) + "\n")
		if animate:
			await _play_fx(cmd, targets)
		else:
			await _wait(MSG_DELAY)
		_refresh()
		for line: String in lines.slice(1):
			await _say(line)
		await _end_fx(actor)
	if engine.is_victory() or engine.is_defeat():
		_mark_active(null)
		_order_box.visible = false
		_set_banner("")
		if engine.is_victory():
			_victory()
		else:
			_defeat()
		return
	_next_turn()


## Akhir ronde: terbakar/racun melukai, efek yang habis masa berlakunya hilang, dan MP pulih.
func _end_round() -> void:
	_mark_active(null)
	_order_box.visible = false
	_set_banner("")
	for line: String in engine.end_round():
		_refresh()
		await _say(line)
	_refresh()
	if engine.is_victory():
		_victory()
	elif engine.is_defeat():
		_defeat()
	else:
		_start_round()


func _victory() -> void:
	var was_boss := not engine.can_flee()
	Audio.play_jingle("victory", false)
	await _say(Loc.t("Semua monster dikalahkan!"))
	# Catat keadaan tiap anggota sebelum hadiah dibagikan, untuk layar hasil.
	var before: Array = []
	for m: Battler in engine.party:
		before.append({"alive": m.is_alive(), "level": m.level, "xp": m.xp, "skills": m.skills.duplicate(),
			"stats": {"HP": m.max_hp, "MP": m.max_mp, "ATK": m.atk, "DEF": m.defense, "MAG": m.mag, "SPD": m.agi}})
	var reward := engine.grant_rewards()
	Game.gold += reward.gold
	Game.add_mats(reward.drops)
	Game.wins += 1
	if was_boss:
		for e: Battler in engine.enemies:
			if Db.BOSSES.has(e.id):
				Game.flags[e.id] = true
	_refresh()
	_show_menu("", [])
	_mark_active(null)
	_order_box.visible = false
	_set_banner("")
	await _show_results(reward, before, was_boss)
	Game.return_to_world("", true)


## Layar hasil pertarungan: emas dan XP yang didapat, batang XP tiap anggota yang terisi bertahap,
## kenaikan level beserta kenaikan stat, dan jurus baru. Selesai saat pemain menekan Lanjut.
func _show_results(reward: Dictionary, before: Array, was_boss: bool) -> void:
	_results = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.13, 0.97)
	style.border_color = COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	_results.add_theme_stylebox_override("panel", style)
	_results.set_anchors_preset(Control.PRESET_CENTER)
	_results.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_results.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_results)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size.x = 720
	_results.add_child(column)

	var title := Label.new()
	title.text = Loc.t("Menang!")
	for e: Battler in engine.enemies:
		if was_boss and e.is_boss:
			title.text = Loc.t("%s tumbang!") % e.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_ACTIVE)
	column.add_child(title)
	var summary := Label.new()
	summary.text = Loc.t("+%d XP untuk tiap anggota yang bertahan        +%d emas  (total %d)") % [reward.xp, reward.gold, Game.gold]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(summary)
	if not (reward.drops as Dictionary).is_empty():  # bahan yang dijatuhkan monster
		var drop_row := HBoxContainer.new()
		drop_row.alignment = BoxContainer.ALIGNMENT_CENTER
		drop_row.add_theme_constant_override("separation", 14)
		var drop_title := Label.new()
		drop_title.text = Loc.t("Bahan:")
		drop_row.add_child(drop_title)
		for mat_id: String in Db.MATERIALS:
			if not reward.drops.has(mat_id):
				continue
			var mat: Dictionary = Db.MATERIALS[mat_id]
			drop_row.add_child(GearIcon.material(mat_id, int(reward.drops[mat_id]), 32.0))
			var mat_name := Label.new()
			mat_name.text = Loc.t(mat.name)
			mat_name.add_theme_font_size_override("font_size", 14)
			mat_name.add_theme_color_override("font_color", Color(String(Db.RARITIES[mat.rarity].color)))
			drop_row.add_child(mat_name)
		column.add_child(drop_row)
	column.add_child(HSeparator.new())

	var rows: Array = []
	for i in engine.party.size():
		var m: Battler = engine.party[i]
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 12)
		var name_label := Label.new()
		name_label.text = m.display_name
		name_label.custom_minimum_size.x = 90
		var level_label := Label.new()
		level_label.text = "Lv %d" % int(before[i].level)
		level_label.custom_minimum_size.x = 60
		var bar := _make_bar(Color("6ab0ff"))
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = Db.xp_to_next(int(before[i].level))
		bar.value = int(before[i].xp)
		var xp_label := Label.new()
		xp_label.custom_minimum_size.x = 110
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		xp_label.text = "%d / %d" % [int(before[i].xp), Db.xp_to_next(int(before[i].level))]
		top.add_child(name_label)
		top.add_child(level_label)
		top.add_child(bar)
		top.add_child(xp_label)
		var note := Label.new()
		note.add_theme_font_size_override("font_size", 14)
		note.add_theme_color_override("font_color", Color("9ad0ff"))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.add_child(top)
		box.add_child(note)
		column.add_child(box)
		rows.append({"level": level_label, "bar": bar, "xp": xp_label, "note": note})

	_results_running = true
	_results_skip = false
	var button := Button.new()
	button.text = Loc.t("Lewati")
	button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	button.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		if _results_running:
			_results_skip = true  # tampilkan hasil akhir sekarang juga
		else:
			results_closed.emit())
	column.add_child(button)
	button.grab_focus()
	Audio.sfx("coin")

	for i in engine.party.size():
		await _animate_xp(engine.party[i], before[i], rows[i])
	_results_running = false
	button.text = Loc.t("Lanjut")
	await results_closed


## Isi batang XP satu anggota dari keadaan sebelum ke sesudah, berhenti sejenak di tiap kenaikan level.
func _animate_xp(m: Battler, was: Dictionary, row: Dictionary) -> void:
	if not was.alive:
		(row.note as Label).text = Loc.t("Tumbang saat pertarungan berakhir: tidak mendapat XP.")
		(row.note as Label).add_theme_color_override("font_color", COLOR_DOWN)
		return
	var level: int = was.level
	var from: int = was.xp
	while level < m.level:
		var need := Db.xp_to_next(level)
		await _fill_xp(row, from, need, need)
		level += 1
		from = 0
		(row.level as Label).text = "Lv %d" % level
		(row.level as Label).add_theme_color_override("font_color", COLOR_ACTIVE)
		Audio.sfx("buff")
		if not _results_skip:
			await _wait(0.25)
	await _fill_xp(row, from, m.xp, Db.xp_to_next(m.level))

	if m.level > int(was.level):
		var now := {"HP": m.max_hp, "MP": m.max_mp, "ATK": m.atk, "DEF": m.defense, "MAG": m.mag, "SPD": m.agi}
		var gains: Array = []
		for stat_name: String in now:
			var gain := int(now[stat_name]) - int(was.stats[stat_name])
			if gain > 0:
				gains.append("%s +%d" % [stat_name, gain])
		var text := Loc.t("Naik level!   ") + "   ".join(gains)
		var learned: Array = []
		for skill_id: String in m.skills:
			if not (was.skills as Array).has(skill_id):
				learned.append(Loc.t(Db.SKILLS[skill_id].name))
		if not learned.is_empty():
			text += Loc.t("\nJurus baru: ") + ", ".join(learned)
		(row.note as Label).text = text


func _fill_xp(row: Dictionary, from: int, to: int, need: int) -> void:
	var bar: ProgressBar = row.bar
	bar.max_value = need
	bar.value = from
	if not _results_skip and to > from:
		var tween := create_tween()
		tween.tween_property(bar, "value", float(to), 0.2 + 0.5 * float(to - from) / need)
		await tween.finished
	bar.value = to
	(row.xp as Label).text = "%d / %d" % [to, need]

func _defeat() -> void:
	Audio.play_jingle("game_over", false)
	await _say(Loc.t("Seluruh party tumbang..."))
	_show_menu(Loc.t("Kalah"), [{"text": Loc.t("Kembali ke desa"), "hint": Loc.t("Party dipulihkan, tetapi separuh emas hilang."),
		"cb": Game.defeat_to_respawn}])


func _say(text: String) -> void:
	_log.append_text(text + "\n")
	await _wait(MSG_DELAY)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# ---------------------------------------------------------------- animasi aksi

## Mainkan animasi sebuah aksi sampai saat "mengenai" sasaran. Setelah fungsi ini selesai,
## pemanggil memperbarui HP di layar, lalu memanggil _end_fx() untuk mengembalikan suasana.
func _play_fx(cmd: Dictionary, targets: Array) -> void:
	if targets.is_empty():
		return
	var actor: Battler = cmd.actor
	var first: Battler = targets[0]
	var fx := "attack"
	if cmd.kind == "defend":
		fx = "guard"
	elif cmd.kind == "item":
		fx = "heal"
	elif cmd.kind == "skill":
		fx = Db.SKILL_FX.get(cmd.skill, "heavy_slash")
	var area := Vector2.ZERO  # titik tengah semua sasaran
	for t: Battler in targets:
		area += _center(t) / targets.size()
	_fx_sound(fx, cmd)
	if fx != "guard":  # ancang-ancang: senjata terangkat sebelum bergerak
		_pose(actor, "windup")
		await _wait(0.14)

	match fx:
		"guard":
			_ring(_home(actor), Color("7fb7e0"), 46.0)
			await _wait(0.25)
		"attack":
			await _melee(actor, first, Color.WHITE, false)
		"heavy_slash":
			await _melee(actor, first, Color("ffd866"), true)
		"bite":
			await _melee(actor, first, Color("ff6a5a"), true)
		"fire":
			await _hop(actor)
			await _projectile(_center(actor), _center(first), Color("ff8a2a"), 11.0, Color("ffd23a"), 0.28)
			_burst(_center(first), Color("ff8a2a"), 24, 230.0, 8.0)
			_burst(_center(first), Color("ffe14a"), 12, 130.0, 5.0)
			_shake(4.0, 0.15)
		"light":
			await _hop(actor)
			_beam(_home(first), Color("fff2a0"))
			_burst(_center(first), Color("fff2a0"), 16, 150.0, 5.0, Vector2(0, -80))
			await _wait(0.2)
		"arrow":
			await _hop(actor)
			await _projectile(_center(actor), _center(first), Color("f0e6d0"), 4.0, Color(1, 1, 1, 0.6), 0.15)
			_burst(_center(first), Color.WHITE, 8, 150.0, 4.0)
		"heal":
			await _hop(actor)
			_rise(_home(first), Color("8ff0a0"))
			await _wait(0.35)
		"bless":
			_tint_to(Color(0.5, 0.7, 1.0, 0.18))
			await _hop(actor)
			for t: Battler in targets:
				_arrows(_center(t), true, Color("7fb7e0"))
				_ring(_home(t), Color("7fb7e0"), 46.0)
			await _wait(0.45)
		"rally":  # pekik perang: seluruh party terbakar semangat
			_tint_to(Color(1.0, 0.5, 0.3, 0.18))
			await _hop(actor)
			_shake(4.0, 0.25)
			for t: Battler in targets:
				_arrows(_center(t), true, Color("ff8a5a"))
				_ring(_home(t), Color("ff8a5a"), 46.0)
			await _wait(0.45)
		"buff_self":
			_arrows(_center(actor), true, Color("ff8a5a"))
			_shake(3.0, 0.2)
			await _wait(0.4)
		"debuff":
			await _hop(actor)
			_arrows(_center(first), false, Color("b07ae0"))
			_burst(_center(first), Color("b07ae0"), 10, 90.0, 5.0, Vector2(0, 80))
			await _wait(0.4)
		"spore":
			_tint_to(Color(0.4, 0.7, 0.3, 0.22))
			_stream(_center(actor), Vector2(16, 16), Color("b8e07a"), 50, (area - _center(actor)).normalized(), 330.0, 6.0, 0.9, 0.5)
			await _wait(0.7)

		# ----- jurus besar: mengubah suasana seluruh arena -----
		"spin":  # pusaran debu, tanah bergetar
			_tint_to(Color(1.0, 0.92, 0.6, 0.2))
			await _dash(actor, _home(actor).lerp(area + Vector2(0, 30), 0.8))
			_ring(area + Vector2(0, 30), Color("ffd866"), 170.0)
			_ring(area + Vector2(0, 30), Color.WHITE, 110.0)
			_stream(area, Vector2(150, 50), Color("d9c9a0"), 50, Vector2(1, -0.25), 300.0, 5.0, 0.4, 0.3)
			_shake(8.0, 0.3)
			await _wait(0.3)
		"ice_storm":  # arena membiru, badai salju turun, serpihan es pecah di tiap musuh
			_tint_to(Color(0.4, 0.68, 1.0, 0.34))
			await _hop(actor)
			_stream(area + Vector2(90, -230), Vector2(300, 20), Color("e8f6ff"), 110, Vector2(-0.45, 1), 430.0, 5.0, 0.65, 0.8)
			await _wait(0.5)
			for t: Battler in targets:
				_burst(_center(t), Color("bfe6ff"), 14, 180.0, 6.0)
				_ring(_home(t), Color("e8f6ff"), 50.0)
			_shake(5.0, 0.3)
			await _wait(0.3)
		"arrow_rain":  # langit menggelap, hujan panah
			_tint_to(Color(0.08, 0.08, 0.2, 0.4))
			await _hop(actor)
			_stream(area + Vector2(100, -240), Vector2(260, 20), Color("f0e6d0"), 70, Vector2(-0.4, 1), 720.0, 1.0, 0.36, 0.6, _line_texture())
			await _wait(0.42)
			for t: Battler in targets:
				_burst(_center(t), Color.WHITE, 8, 150.0, 4.0)
			await _wait(0.25)
		"heal_all":  # cahaya keemasan menyinari seluruh party
			_tint_to(Color(1.0, 0.88, 0.45, 0.26))
			await _hop(actor)
			for t: Battler in targets:
				_beam(_home(t), Color("fff2a0"))
				_rise(_home(t), Color("8ff0a0"))
			await _wait(0.5)
		"lava":  # semburan lahar: arena memerah, bara menghujani seluruh party
			_tint_to(Color(1.0, 0.32, 0.08, 0.34))
			await _hop(actor, 30.0)
			_stream(_center(actor), Vector2(24, 24), Color("ff8a2a"), 80, (area - _center(actor)).normalized(), 380.0, 7.0, 0.9, 0.5)
			await _wait(0.5)
			for t: Battler in targets:
				_burst(_center(t), Color("ff8a2a"), 14, 190.0, 7.0)
				_burst(_center(t), Color("ffd23a"), 6, 110.0, 5.0)
			_shake(8.0, 0.3)
			await _wait(0.25)
		"dark":  # badai kegelapan: arena menggelap, bayangan menghantam seluruh party
			_tint_to(Color(0.18, 0.05, 0.3, 0.5))
			await _hop(actor, 30.0)
			_stream(area + Vector2(-60, -220), Vector2(280, 20), Color("b08ae0"), 90, Vector2(0.35, 1), 460.0, 6.0, 0.6, 0.7)
			await _wait(0.5)
			for t: Battler in targets:
				_burst(_center(t), Color("7a4ab8"), 16, 200.0, 7.0)
				_ring(_home(t), Color("b08ae0"), 50.0)
			_shake(10.0, 0.35)
			await _wait(0.3)
		"quake":  # hantaman yang mengguncang seluruh layar
			_tint_to(Color(0.5, 0.3, 0.1, 0.3))
			await _hop(actor, 46.0)
			_shake(15.0, 0.5)
			for t: Battler in targets:
				_burst(_home(t), Color("c2a471"), 14, 170.0, 6.0)
			await _wait(0.4)


## Suara sebuah aksi saat dimulai. Suara kena pukul dimainkan terpisah saat HP berkurang (_refresh).
func _fx_sound(fx: String, cmd: Dictionary) -> void:
	if cmd.kind == "item":
		Audio.sfx("potion")
	elif fx == "buff_self":
		Audio.sfx("roar" if (cmd.actor as Battler).is_enemy else "buff")
	else:
		Audio.sfx(FX_SOUND.get(fx, "swing"))


## Kembalikan pelaku ke tempatnya dan hilangkan warna suasana.
func _end_fx(actor: Battler) -> void:
	var tint := create_tween()
	tint.tween_property(_tint, "color:a", 0.0, 0.25)
	_pose(actor, "stand")
	var sprite: Sprite2D = _units[actor].sprite
	if sprite.position != _home(actor):
		var tween := create_tween()
		tween.tween_property(sprite, "position", _home(actor), 0.18)
		await tween.finished


## Ganti gambar tokoh: "stand" biasa, "windup" senjata terangkat, "strike" senjata terayun/dilepas.
## Monster hanya punya satu gambar, jadi tidak berubah.
func _pose(b: Battler, pose: String) -> void:
	if not b.is_enemy:
		(_units[b].sprite as Sprite2D).texture = load(SPRITES + "%s_back_%s.png" % [b.id, pose])


func _home(b: Battler) -> Vector2:
	return _units[b].home


## Titik tengah badan sebuah unit.
func _center(b: Battler) -> Vector2:
	return _home(b) + Vector2(0, -float(_units[b].height) * 0.5)


func _melee(actor: Battler, target: Battler, color: Color, heavy: bool) -> void:
	await _dash(actor, _home(actor).lerp(_home(target), 0.74))
	_slash(_center(target), color, heavy)
	if heavy:
		_shake(5.0, 0.2)
	await _wait(0.1)


func _dash(b: Battler, to: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(_units[b].sprite, "position", to, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	_pose(b, "strike")


func _hop(b: Battler, height: float = 16.0) -> void:
	var sprite: Sprite2D = _units[b].sprite
	var tween := create_tween()
	tween.tween_property(sprite, "position", _home(b) + Vector2(0, -height), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", _home(b), 0.1).set_ease(Tween.EASE_IN)
	await tween.finished
	_pose(b, "strike")


## Efek sementara: masuk ke lapisan efek, lalu dihapus setelah `life` detik.
func _add_fx(node: Node2D, life: float) -> void:
	_fx.add_child(node)
	get_tree().create_timer(life).timeout.connect(node.queue_free)


func _slash(pos: Vector2, color: Color, heavy: bool) -> void:
	Audio.sfx("heavy_slash" if heavy else "slash")
	for flip: float in ([1.0, -1.0] if heavy else [1.0]):
		var arc := Line2D.new()
		for i in 9:
			var angle: float = lerp(-2.3, -0.1, i / 8.0)
			arc.add_point(Vector2(cos(angle) * flip, sin(angle)) * 46.0 + Vector2(0, 20))
		arc.width = 12.0 if heavy else 7.0
		arc.default_color = color
		arc.position = pos
		arc.scale = Vector2(0.5, 0.5)
		_add_fx(arc, 0.3)
		var tween := create_tween().set_parallel()
		tween.tween_property(arc, "scale", Vector2(1.3, 1.3), 0.22)
		tween.tween_property(arc, "modulate:a", 0.0, 0.22)


## Cincin yang melebar di tanah (pipih, mengikuti sudut pandang isometrik).
func _ring(pos: Vector2, color: Color, radius: float) -> void:
	var ring := Line2D.new()
	for i in 24:
		var angle := TAU * i / 24.0
		ring.add_point(Vector2(cos(angle), sin(angle) * 0.5) * radius)
	ring.closed = true
	ring.width = 5.0
	ring.default_color = color
	ring.position = pos
	ring.scale = Vector2(0.25, 0.25)
	_add_fx(ring, 0.45)
	var tween := create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.35)


func _beam(foot: Vector2, color: Color) -> void:
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-16, -500), Vector2(16, -500), Vector2(22, 8), Vector2(-22, 8)])
	beam.color = Color(color, 0.65)
	beam.position = foot
	_add_fx(beam, 0.5)
	create_tween().tween_property(beam, "modulate:a", 0.0, 0.45)


func _arrows(pos: Vector2, up: bool, color: Color) -> void:
	for i in 3:
		var arrow := Polygon2D.new()
		var tip := -9.0 if up else 9.0
		arrow.polygon = PackedVector2Array([Vector2(-8, -tip), Vector2(0, tip), Vector2(8, -tip)])
		arrow.color = color
		arrow.position = pos + Vector2((i - 1) * 22, 10 if up else -30)
		_add_fx(arrow, 0.7)
		var tween := create_tween().set_parallel()
		tween.tween_property(arrow, "position:y", arrow.position.y + (-46.0 if up else 46.0), 0.6).set_delay(i * 0.06)
		tween.tween_property(arrow, "modulate:a", 0.0, 0.6).set_delay(i * 0.06)


func _projectile(from: Vector2, to: Vector2, color: Color, radius: float, trail_color: Color, time: float) -> void:
	var ball := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 8:
		points.append(Vector2.from_angle(TAU * i / 8.0) * radius)
	ball.polygon = points
	ball.color = color
	ball.position = from
	var trail := CPUParticles2D.new()
	trail.amount = 24
	trail.lifetime = 0.25
	trail.local_coords = false
	trail.spread = 180.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_max = 30.0
	trail.scale_amount_min = radius * 0.3
	trail.scale_amount_max = radius * 0.7
	trail.color = trail_color
	ball.add_child(trail)
	_fx.add_child(ball)
	var tween := create_tween()
	tween.tween_property(ball, "position", to, time)
	await tween.finished
	ball.queue_free()


## Ledakan partikel sekali jadi.
func _burst(pos: Vector2, color: Color, amount: int, speed: float, size: float, gravity: Vector2 = Vector2(0, 320)) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = gravity
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color = color
	_add_fx(p, 0.9)
	p.emitting = true


## Partikel naik pelan dari kaki (penyembuhan).
func _rise(foot: Vector2, color: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = foot
	p.amount = 18
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(22, 6)
	p.direction = Vector2.UP
	p.spread = 12.0
	p.gravity = Vector2(0, -40)
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	_add_fx(p, 1.2)
	p.emitting = true


## Aliran partikel dari sebuah area selama `duration` detik (salju, panah, debu, spora).
func _stream(pos: Vector2, extents: Vector2, color: Color, amount: int, dir: Vector2, speed: float,
		size: float, life: float, duration: float, texture: Texture2D = null) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = dir
	p.spread = 6.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.8
	p.initial_velocity_max = speed
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color = color
	if texture != null:
		p.texture = texture
		p.rotation = dir.angle() - PI / 2.0
		p.direction = Vector2.DOWN
	_add_fx(p, duration + life + 0.2)
	# Disambungkan ke method milik partikel itu sendiri, supaya otomatis batal kalau partikelnya
	# sudah terhapus lebih dulu (battle selesai dan scene berganti).
	get_tree().create_timer(duration).timeout.connect(p.set_emitting.bind(false))


## Garis tipis putih untuk partikel panah.
func _line_texture() -> Texture2D:
	var img := Image.create(3, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


func _tint_to(color: Color) -> void:
	_tint.color = Color(color, 0.0)
	create_tween().tween_property(_tint, "color:a", color.a, 0.18)


func _shake(strength: float, time: float) -> void:
	var tween := create_tween()
	var steps := 6
	for i in steps:
		var fade := 1.0 - float(i) / steps
		tween.tween_property(_world, "position", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fade, time / steps)
	tween.tween_property(_world, "position", Vector2.ZERO, 0.04)


## Kedip merah singkat pada sesuatu yang baru saja kena serangan.
func _flash(node: CanvasItem) -> void:
	var tween := create_tween()
	for i in 2:
		tween.tween_property(node, "self_modulate", Color(1.0, 0.35, 0.35), 0.06)
		tween.tween_property(node, "self_modulate", Color.WHITE, 0.08)


## Uji tampilan: mainkan animasi sebuah jurus tanpa menjalankan aturan battle.
func _preview_fx(skill_id: String) -> void:
	var cmd := {"actor": engine.party[0], "kind": "attack", "target": engine.enemies[0]}
	if skill_id != "":
		cmd = {"actor": engine.party[0], "kind": "skill", "skill": skill_id, "target": engine.enemies[0]}
		for m: Battler in engine.party + engine.enemies:
			if Db.CHARACTERS.has(m.id) and _learns(m.id, skill_id) or m.is_enemy and m.skills.has(skill_id):
				cmd["actor"] = m
		if cmd.actor.is_enemy or Db.SKILLS[skill_id].target == "ally":
			cmd["target"] = engine.party[0]
	await _play_fx(cmd, engine.resolve_targets(cmd))


func _learns(char_id: String, skill_id: String) -> bool:
	for list: Array in (Db.CHARACTERS[char_id].learn as Dictionary).values():
		if list.has(skill_id):
			return true
	return false


# ---------------------------------------------------------------- tampilan

func _refresh() -> void:
	_info.text = Loc.t("Emas: %d     Menang: %d") % [Game.gold, Game.wins]

	var current := _current
	for i in Game.party.size():
		var m: Battler = Game.party[i]
		var row: Dictionary = _party_rows[i]
		(row.name as Label).text = "%s   Lv %d" % [m.display_name, m.level]
		(row.stats as Label).text = "HP %d/%d    MP %d/%d" % [m.hp, m.max_hp, m.mp, m.max_mp]
		# ATK/DEF/SPD setelah efek status: hijau kalau sedang naik, merah kalau sedang turun.
		for stat_name: String in ["atk", "defense", "agi"]:
			var label: Label = row[stat_name]
			var base := int(m.get(stat_name))
			var now := roundi(m.stat(stat_name))
			label.text = "%s %d" % [{"atk": "ATK", "defense": "DEF", "agi": "SPD"}[stat_name], now]
			label.add_theme_color_override("font_color",
				Color("8fe08a") if now > base else (Color("ff8a7a") if now < base else Color(1, 1, 1, 0.7)))
		# Baris tokoh yang sedang memilih perintah diberi latar.
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(1.0, 0.85, 0.4, 0.16) if m == current else Color(0, 0, 0, 0)
		frame.border_color = COLOR_ACTIVE if m == current else Color(0, 0, 0, 0)
		frame.border_width_left = 3
		frame.set_content_margin_all(1)
		frame.content_margin_left = 8
		(row.frame as PanelContainer).add_theme_stylebox_override("panel", frame)
		_fill_statuses(row.status, m)
		(row.bar as ProgressBar).max_value = m.max_hp
		(row.bar as ProgressBar).value = m.hp
		var tint := Color.WHITE
		if not m.is_alive():
			tint = COLOR_DOWN
		elif m == current:
			tint = COLOR_ACTIVE
		(row.name as Label).add_theme_color_override("font_color", tint)
		var sprite: Sprite2D = _units[m].sprite
		sprite.modulate = _status_tint(m) if m.is_alive() else Color(0.4, 0.4, 0.5, 0.7)
		if m.hp < int(_shown_hp.get(m, m.hp)):
			Audio.sfx("hero_hurt")
			_flash(row.stats)
			_flash(sprite)
			_recoil(sprite, Vector2(-10, 5))
		_shown_hp[m] = m.hp
	if current != null:
		_mark_active(current)

	for e: Battler in engine.enemies:
		var unit: Dictionary = _units[e]
		(unit.bar as ProgressBar).value = e.hp
		_fill_statuses(unit.status, e)
		if e.is_alive():
			(unit.sprite as Sprite2D).modulate = _status_tint(e)
		if e.hp < int(_shown_hp.get(e, e.hp)):
			if Db.ENEMIES[e.id].get("voice", "") == "soft":  # monster kecil: bunyi ringan, bukan geraman
				Audio.sfx("soft_hurt" if e.is_alive() else "soft_die")
			else:
				Audio.sfx("enemy_hurt" if e.is_alive() else "enemy_die")
			_flash(unit.sprite)
			_recoil(unit.sprite, Vector2(10, -5))
			if not e.is_alive():  # kalah: memudar setelah kedipnya selesai
				var fade := create_tween().set_parallel()
				fade.tween_property(unit.sprite, "modulate:a", 0.0, 0.3).set_delay(0.25)
				fade.tween_property(unit.tag, "modulate:a", 0.0, 0.3).set_delay(0.25)
				(unit.sprite as Sprite2D).modulate = Color.WHITE
		_shown_hp[e] = e.hp


## Nama semua efek status yang sedang aktif beserta sisa rondenya, mis. "ATK Naik 3, Racun 4".
## Dipakai di baris petunjuk saat sebuah petarung disorot, supaya arti tiap ikon mudah dikenali.
func _status_tags(b: Battler) -> String:
	var tags: Array = []
	for status_id: String in b.statuses:
		tags.append("%s %d" % [Loc.t(Db.STATUSES[status_id].name), b.statuses[status_id]])
	return ", ".join(tags)


## Isi sebuah deretan dengan ikon efek status petarung, masing-masing diikuti sisa rondenya.
## Hanya disusun ulang kalau efeknya berubah.
func _fill_statuses(box: HBoxContainer, b: Battler) -> void:
	var signature := str(b.statuses) if b.is_alive() else ""
	if box.get_meta("signature", "-") == signature:
		return
	box.set_meta("signature", signature)
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	if signature == "":
		return
	for status_id: String in b.statuses:
		var icon := TextureRect.new()
		icon.texture = load(SPRITES + "status_%s.png" % status_id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.custom_minimum_size = STATUS_ICON_SIZE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
		var turns := Label.new()
		turns.text = str(b.statuses[status_id])
		turns.add_theme_font_size_override("font_size", 12)
		turns.add_theme_constant_override("outline_size", 4)
		turns.add_theme_color_override("font_outline_color", Color("10141c"))
		turns.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(turns)


## Sprite ikut berubah warna saat terbakar atau keracunan.
func _status_tint(b: Battler) -> Color:
	if b.has_status("burn"):
		return Color(1.0, 0.72, 0.55)
	if b.has_status("poison"):
		return Color(0.72, 1.0, 0.68)
	return Color.WHITE


## Terdorong sedikit lalu kembali, relatif terhadap posisi saat ini.
func _recoil(sprite: Sprite2D, push: Vector2) -> void:
	var start := sprite.position
	var tween := create_tween()
	tween.tween_property(sprite, "position", start + push, 0.05)
	tween.tween_property(sprite, "position", start, 0.12)


func _show_menu(title: String, items: Array, back: Callable = Callable()) -> void:
	for child in _menu_box.get_children():
		_menu_box.remove_child(child)
		child.queue_free()
	_menu_title.text = title
	_hint.text = ""
	_cursor.visible = false
	_target_ring.visible = false
	_back_cb = back
	_pick_list = []  # _pick_target mengisinya lagi kalau menu ini memang pemilihan sasaran
	_hover = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	var all_items := items.duplicate()
	if back.is_valid():
		all_items.append({"text": Loc.t("< Kembali"), "hint": Loc.t("Kembali ke pilihan sebelumnya (Esc)."), "cb": back})

	var first: Button = null
	for item: Dictionary in all_items:
		var button := Button.new()
		button.text = item.text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = item.get("disabled", false)
		var hint: String = item.get("hint", "")
		var unit: Battler = item.get("unit")
		var on_focus := func() -> void:
			_hint.text = hint
			_point_at(unit)
			Audio.sfx("ui_move")
		button.pressed.connect(func() -> void: Audio.sfx("ui_ok"))
		button.focus_entered.connect(on_focus)
		button.mouse_entered.connect(on_focus)
		button.pressed.connect(item.cb)
		_menu_box.add_child(button)
		if first == null and not button.disabled:
			first = button
	if first != null:
		first.grab_focus()


## Panah penunjuk di atas kepala unit yang sedang dipilih.
func _point_at(b: Battler) -> void:
	_cursor.visible = b != null and _units.has(b)
	_target_ring.visible = _cursor.visible and not _pick_list.is_empty()
	if _cursor.visible:
		_cursor.position = _home(b) + Vector2(0, -float(_units[b].height) - 14.0)
		_target_ring.position = _home(b) + Vector2(0, 2)
		_target_ring.default_color = Color("ff6a5a") if b.is_enemy else Color("7fe08a")


func _field_pos(slot: Vector2) -> Vector2:
	return FIELD_CENTER + Vector2((slot.x - slot.y) * TILE_HALF.x, (slot.x + slot.y) * TILE_HALF.y)


func _build_units() -> void:
	for child in _unit_layer.get_children() + _tags.get_children():
		child.queue_free()
	_units.clear()
	_shown_hp.clear()

	for i in engine.party.size():
		var m: Battler = engine.party[i]
		_add_unit(m, "%s_back_stand" % m.id, HERO_ANCHOR, _field_pos(PARTY_SLOTS[i % PARTY_SLOTS.size()]))

	var slots: Array = ENEMY_SLOTS[clampi(engine.enemies.size(), 1, 4)]
	for i in engine.enemies.size():
		var e: Battler = engine.enemies[i]
		var unit := _add_unit(e, "monster_%s" % e.id, MONSTER_ANCHOR[e.id], _field_pos(slots[i % slots.size()]))
		# Hanya batang HP di kaki monster; namanya muncul di menu sasaran dan lewat panah penunjuk.
		var bar := _make_bar(Color("d0655a"))
		bar.custom_minimum_size = Vector2(84, 7)
		bar.size = Vector2(84, 7)
		bar.position = unit.home + Vector2(-42, 6)
		bar.max_value = e.max_hp
		bar.value = e.hp
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE  # jangan menghalangi klik ke monster
		_tags.add_child(bar)
		var status_label := HBoxContainer.new()  # deretan ikon efek status di bawah batang HP
		status_label.alignment = BoxContainer.ALIGNMENT_CENTER
		status_label.add_theme_constant_override("separation", 1)
		status_label.size = Vector2(220, STATUS_ICON_SIZE.y)
		status_label.position = unit.home + Vector2(-110, 15)
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tags.add_child(status_label)
		unit["tag"] = bar
		unit["bar"] = bar
		unit["status"] = status_label


func _add_unit(b: Battler, sprite_name: String, anchor: Vector2, home: Vector2) -> Dictionary:
	var sprite := Sprite2D.new()
	sprite.texture = load(SPRITES + sprite_name + ".png")
	sprite.centered = false
	sprite.offset = -anchor
	sprite.scale = Vector2(PIXEL, PIXEL)
	sprite.position = home
	_unit_layer.add_child(sprite)
	var unit := {"sprite": sprite, "home": home, "height": anchor.y * PIXEL,
		"rect": Rect2(home - anchor * PIXEL, sprite.texture.get_size() * PIXEL)}  # area klik di layar
	_units[b] = unit
	_shown_hp[b] = b.hp
	return unit


## Susun tanah arena menjadi satu gambar: petak-petak belah ketupat plus hiasan di belakang arena.
func _build_ground() -> Sprite2D:
	var arena: Dictionary = ARENAS[Game.backdrop]
	var w := int(ceil(1280.0 / PIXEL)) + 2
	var h := int(ceil(FIELD_HEIGHT / PIXEL)) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var center := Vector2i(FIELD_CENTER / PIXEL)
	var decor: Array = []
	for y in range(-20, 21):
		for x in range(-20, 21):
			var p := center + Vector2i((x - y) * 16, (x + y) * 8)
			if p.x < -16 or p.x > w + 16 or p.y < -8 or p.y > h + 8:
				continue
			var key := Vector2i(x, y)
			var tile := _image("%s_%d" % [arena.ground, posmod(hash(key), int(arena.variants))])
			img.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), p - Vector2i(16, 8))
			# Hiasan hanya di bagian atas (di belakang semua petarung), supaya tidak perlu diurutkan dengan unit.
			if p.y < 42 and float(posmod(hash(key + Vector2i(31, 17)), 100)) / 100.0 < float(arena.rate):
				decor.append(key)
	decor.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x + a.y < b.x + b.y)
	for key: Vector2i in decor:
		var names: Array = arena.decor
		var sprite_name: String = names[posmod(hash(key), names.size())]
		var prop := _image(sprite_name)
		var anchor := Vector2i(16, 31) if (sprite_name.begins_with("hill") or sprite_name.begins_with("wall")) else Vector2i(14, 32)
		img.blend_rect(prop, Rect2i(Vector2i.ZERO, prop.get_size()), center + Vector2i((key.x - key.y) * 16, (key.x + key.y) * 8) - anchor)

	var ground := Sprite2D.new()
	ground.texture = ImageTexture.create_from_image(img)
	ground.centered = false
	ground.scale = Vector2(PIXEL, PIXEL)
	ground.position = Vector2(-PIXEL, -PIXEL)
	if Game.backdrop == "gua":
		ground.modulate = Color(0.72, 0.68, 0.66)
	return ground


func _image(sprite_name: String) -> Image:
	var img := (load(SPRITES + sprite_name + ".png") as Texture2D).get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 18
	theme = ui_theme

	mouse_filter = Control.MOUSE_FILTER_IGNORE  # klik di arena diteruskan ke _unhandled_input
	var backing := ColorRect.new()
	backing.color = Color("141a26")
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)

	_world = Node2D.new()
	add_child(_world)
	_world.add_child(_build_ground())
	_active_ring = _make_ring(COLOR_ACTIVE, 34.0, 4.0)  # di bawah sprite, di atas tanah
	_world.add_child(_active_ring)
	_target_ring = _make_ring(Color("ff6a5a"), 40.0, 3.0)
	_world.add_child(_target_ring)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_active_ring, "scale", Vector2(1.12, 1.12), 0.45)
	pulse.tween_property(_active_ring, "scale", Vector2(0.94, 0.94), 0.45)
	_unit_layer = Node2D.new()
	_unit_layer.y_sort_enabled = true
	_world.add_child(_unit_layer)
	_fx = Node2D.new()
	_world.add_child(_fx)
	_cursor = Polygon2D.new()
	_cursor.polygon = PackedVector2Array([Vector2(-9, -12), Vector2(9, -12), Vector2(0, 2)])
	_cursor.color = COLOR_ACTIVE
	_cursor.visible = false
	_world.add_child(_cursor)

	_tint = ColorRect.new()
	_tint.color = Color(0, 0, 0, 0)
	_tint.size = Vector2(1280, FIELD_HEIGHT)  # hanya arena, tidak sampai ke panel
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tint)

	_tags = Control.new()
	_tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tags)

	_info = Label.new()
	_info.position = Vector2(16, 10)
	_add_text_outline(_info)
	add_child(_info)

	# Keterangan giliran di tengah atas, dengan urutan aksi ronde di bawahnya.
	var banner_panel := PanelContainer.new()
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.06, 0.09, 0.13, 0.82)
	banner_style.border_color = COLOR_BORDER
	banner_style.set_border_width_all(1)
	banner_style.set_corner_radius_all(5)
	banner_style.set_content_margin_all(6)
	banner_style.content_margin_left = 14
	banner_style.content_margin_right = 14
	banner_panel.add_theme_stylebox_override("panel", banner_style)
	banner_panel.anchor_left = 0.5
	banner_panel.anchor_right = 0.5
	banner_panel.offset_top = 6
	banner_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.visible = false
	add_child(banner_panel)
	var banner_col := VBoxContainer.new()
	banner_col.add_theme_constant_override("separation", 4)
	banner_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_child(banner_col)
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_color", COLOR_ACTIVE)
	banner_col.add_child(_banner)
	_order_box = HBoxContainer.new()
	_order_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_order_box.add_theme_constant_override("separation", 4)
	_order_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_box.visible = false
	banner_col.add_child(_order_box)

	_hint = Label.new()
	_hint.anchor_top = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = 20
	_hint.offset_right = -20
	_hint.offset_top = -340
	_hint.offset_bottom = -312
	_hint.add_theme_color_override("font_color", COLOR_ACTIVE)
	_add_text_outline(_hint)
	add_child(_hint)

	var bottom := HBoxContainer.new()
	bottom.anchor_top = 1.0
	bottom.anchor_right = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 16
	bottom.offset_right = -16
	bottom.offset_top = -306
	bottom.offset_bottom = -16
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)

	var menu_panel := _make_panel(280)
	bottom.add_child(menu_panel)
	var menu_col := VBoxContainer.new()
	menu_panel.add_child(menu_col)
	_menu_title = Label.new()
	_menu_title.add_theme_color_override("font_color", COLOR_BORDER)
	menu_col.add_child(_menu_title)
	_menu_box = VBoxContainer.new()
	menu_col.add_child(_menu_box)

	var log_panel := _make_panel(0)
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.scroll_following = true
	_log.focus_mode = Control.FOCUS_NONE
	log_panel.add_child(_log)

	var party_panel := _make_panel(360)
	bottom.add_child(party_panel)
	var party_col := VBoxContainer.new()
	party_col.add_theme_constant_override("separation", 1)
	party_panel.add_child(party_col)
	for m: Battler in Game.party:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_row := HBoxContainer.new()  # nama dan level di kiri; ATK, DEF, SPD di kanan
		name_row.add_theme_constant_override("separation", 10)
		name_row.add_child(name_label)
		var stat_labels := {}
		for stat_name: String in ["atk", "defense", "agi"]:
			var stat_label := Label.new()
			stat_label.add_theme_font_size_override("font_size", 13)
			name_row.add_child(stat_label)
			stat_labels[stat_name] = stat_label
		var stats_label := Label.new()
		stats_label.add_theme_font_size_override("font_size", 15)
		var bar := _make_bar(Color("5fbf6a"))
		var status_label := HBoxContainer.new()  # deretan ikon efek status, rata kanan
		status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_label.alignment = BoxContainer.ALIGNMENT_END
		status_label.add_theme_constant_override("separation", 1)
		status_label.custom_minimum_size.y = STATUS_ICON_SIZE.y
		var stats_row := HBoxContainer.new()  # angka HP/MP di kiri, efek status di kanan
		stats_row.add_child(stats_label)
		stats_row.add_child(status_label)
		box.add_child(name_row)
		box.add_child(stats_row)
		box.add_child(bar)
		var frame := PanelContainer.new()  # latarnya menyala untuk tokoh yang sedang memilih perintah
		frame.add_child(box)
		party_col.add_child(frame)
		var row := {"name": name_label, "stats": stats_label, "bar": bar, "status": status_label, "frame": frame}
		row.merge(stat_labels)
		_party_rows.append(row)


func _build_bag() -> void:
	_bag = (load("res://scripts/ui/bag_view.gd") as GDScript).new()
	_bag.picked.connect(_on_bag_picked)
	_bag.closed.connect(_on_bag_closed)
	add_child(_bag)
	_bag.offset_top = -150  # di tengah arena, di atas panel status
	_bag.offset_bottom = -150


## Lingkaran pipih di tanah (mengikuti sudut pandang isometrik).
func _make_ring(color: Color, radius: float, width: float) -> Line2D:
	var ring := Line2D.new()
	for i in 24:
		var angle := TAU * i / 24.0
		ring.add_point(Vector2(cos(angle), sin(angle) * 0.5) * radius)
	ring.closed = true
	ring.width = width
	ring.default_color = color
	ring.visible = false
	return ring


func _make_panel(min_width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = min_width
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _add_text_outline(label: Label) -> void:
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color("10141c"))


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color("2a3140")
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar
