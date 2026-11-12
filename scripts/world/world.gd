extends Node2D
## Scene peta (isometrik). Dipakai untuk semua peta di WorldMap.MAPS: peta dunia dan desa.
## Pemain berjalan petak demi petak (keyboard atau klik), bisa bertemu monster, bicara dengan NPC,
## pindah peta lewat portal, dan memicu adegan cerita (lihat Story).
##
## Tanah digambar datar di _draw(); benda yang punya tinggi (gunung, pohon, rumah, NPC, pemain)
## adalah sprite di dalam _objects yang diurutkan otomatis menurut posisi Y (y-sort).

signal advance  # pemain menekan lanjut saat dialog
signal chosen(index: int)  # pemain memilih salah satu pilihan dialog
signal shop_closed  # pemain selesai berbelanja

const HALF_W := 32  # setengah lebar belah ketupat petak
const HALF_H := 16  # setengah tingginya
const STEP_TIME := 0.15  # lama satu langkah searah sisi petak
const BASE_STEP_PX := 35.78  # panjang langkah itu di layar: sqrt(32^2 + 16^2)
const INPUT_SETTLE := 0.05
# Arah lurus dulu baru silang, supaya rute klik lebih suka mengikuti sisi petak.
const STEP_DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
const GRACE_STEPS := 4  # langkah aman setelah masuk peta / selesai battle
const MSG_TIME := 3.5
const TYPE_DELAY := 0.028  # jeda antar huruf saat teks dialog muncul
const TYPE_BLIP_EVERY := 2  # satu bunyi "tet" tiap sekian huruf

const COLOR_PANEL := Color(0.06, 0.09, 0.13, 0.9)
const COLOR_BORDER := Color("c9a85c")
const SPRITES := "res://assets/sprites/"
const PIXEL := 2.0  # sprite digambar 1x, ditampilkan 2x
const ZOOM := 1.5  # 2x sprite * 1.5 = piksel art tampil 3x (tetap bilangan bulat)
const TREE_ANCHOR := Vector2(14, 32)
const MOUNTAIN_ANCHOR := Vector2(16, 31)
const HOUSE_ANCHOR := Vector2(20, 38)
const PERSON_ANCHOR := Vector2(12, 30)
const BACKDROPS := {"grass": "lembah", "forest_floor": "hutan", "mist_grass": "kabut", "mist_floor": "kabut"}
const GROUND_VARIANTS := {"grass": 3, "forest_floor": 2, "mist_grass": 3, "mist_floor": 2, "water": 3, "rock": 2, "path": 3}
const GROUND_PRIORITY := {"water": 0, "path": 1, "rock": 2, "grass": 3, "mist_grass": 3, "forest_floor": 4, "mist_floor": 4}
const EDGE_SIDES := {"ne": Vector2i(0, -1), "se": Vector2i(1, 0), "sw": Vector2i(0, 1), "nw": Vector2i(-1, 0)}

var _tile := Vector2i.ZERO
var _moving := false
var _busy := false  # dialog, pindah peta, atau masuk battle: gerak dimatikan
var _dialog_open := false
var _typing := false  # teks dialog sedang muncul huruf demi huruf
var _skip_typing := false  # pemain menekan lanjut saat teks masih muncul: tampilkan sisanya sekaligus
var _steps := 0
var _msg_left := 0.0
var _bounds := Rect2()
var _view := "front"
var _last_dir := Vector2i.ZERO
var _dir_held := 0.0
var _path: Array = []  # petak-petak rute hasil klik mouse
var _talk_after := ""  # id NPC yang diajak bicara setelah rute klik selesai
var _npc_at := {}  # Vector2i -> data NPC (yang sedang terlihat di peta ini)
var _npc_sprites := {}  # id NPC -> Sprite2D
var _textures := {}

var _marker: Line2D
var _objects: Node2D
var _player: Sprite2D
var _zone_label: Label
var _party_label: Label
var _msg_panel: PanelContainer
var _msg_label: Label
var _dialog_panel: PanelContainer
var _dialog_name: Label
var _dialog_text: Label
var _dialog_choices: VBoxContainer
var _dialog_hint: Label
var _menu_panel: PanelContainer
var _menu_box: VBoxContainer
var _menu_open := false
var _menu_title: Label
var _menu_hint: Label
var _shop_open := false
var _bag: PanelContainer  # tampilan tas (scripts/ui/bag_view.gd)
var _bag_open := false
var _bag_from_menu := false  # tas dibuka dari menu Esc (bukan lewat pintasan)
var _shop_view: PanelContainer  # tampilan toko (scripts/ui/shop_view.gd)
var _shop_stock: Array = []
var _fade: ColorRect


func _ready() -> void:
	WorldMap.current = Game.map_id
	_tile = Game.player_tile
	var w := WorldMap.width()
	var h := WorldMap.height()
	_bounds = Rect2(-h * HALF_W, -HALF_H, (w + h) * HALF_W, (w + h) * HALF_H)
	_build_marker()
	_build_objects()
	_build_player()
	_build_hud()
	_update_hud()
	if Game.pending_scene != "":
		var key := Game.pending_scene
		Game.pending_scene = ""
		_run_scene(Story.scene(key))
	elif Game.world_message != "":
		_show_message(Game.world_message)
	Game.world_message = ""
	Audio.play_music("dunia" if Game.map_id == "dunia" else "desa")


## Posisi layar dari titik tengah sebuah petak.
func _iso(t: Vector2i) -> Vector2:
	return Vector2((t.x - t.y) * HALF_W, (t.x + t.y) * HALF_H)


## Kebalikan _iso(): petak yang berada di bawah sebuah titik di dunia.
func _tile_at(pos: Vector2) -> Vector2i:
	var u := pos.x / HALF_W
	var v := pos.y / HALF_H
	return Vector2i(roundi((u + v) * 0.5), roundi((v - u) * 0.5))


## Bisa diinjak: medannya boleh, dan tidak ada NPC yang berdiri di sana.
func _walkable(t: Vector2i) -> bool:
	return WorldMap.is_walkable(t, Game.flags) and not _npc_at.has(t)


# ---------------------------------------------------------------- gerak

func _process(delta: float) -> void:
	if _msg_left > 0.0:
		_msg_left -= delta
		if _msg_left <= 0.0:
			_msg_panel.visible = false
	if _moving or _busy:
		return
	var dir := _input_dir()
	# Tunggu sekejap sampai arah stabil, supaya menekan dua tombol (jalan miring)
	# tidak terbaca sebagai satu tombol dulu.
	if dir != _last_dir:
		_last_dir = dir
		_dir_held = 0.0
	_dir_held += delta
	if dir == Vector2i.ZERO:
		# Tidak ada tombol ditekan: lanjutkan rute hasil klik mouse, kalau ada.
		if not _path.is_empty():
			var next: Vector2i = _path.pop_front()
			if _path.is_empty():
				_marker.visible = false
			_begin_step(next - _tile)
		return
	_cancel_path()  # keyboard selalu menang atas rute klik
	if _dir_held < INPUT_SETTLE:
		return
	var step := _resolve_step(dir)
	if step == Vector2i.ZERO:
		_face(dir, "stand")
		return
	_begin_step(step)


func _begin_step(step: Vector2i) -> void:
	_moving = true
	_tile += step
	Audio.sfx("step")
	_face(step, "a" if _steps % 2 == 0 else "b")
	# Lama langkah sebanding jarak di layar, supaya kecepatan terasa sama ke semua arah.
	var screen_step := Vector2((step.x - step.y) * HALF_W, (step.x + step.y) * HALF_H).length()
	var tween := create_tween()
	tween.tween_property(_player, "position", _iso(_tile) + Vector2(0, 1), STEP_TIME * screen_step / BASE_STEP_PX)
	tween.finished.connect(_on_step)


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var clicked := click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	if _dialog_open:
		if clicked or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			if _typing:
				_skip_typing = true
			else:
				Audio.sfx("ui_ok")
				advance.emit()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_I:  # I: buka/tutup tas
		get_viewport().set_input_as_handled()
		_toggle_bag()
		return
	if event.is_action_pressed("ui_cancel"):  # Esc: buka/tutup menu
		get_viewport().set_input_as_handled()
		if _shop_open:
			Audio.sfx("ui_cancel")
			shop_closed.emit()
		elif _bag_open:
			pass  # tampilan tas menangani Esc sendiri
		elif _menu_open:
			Audio.sfx("ui_cancel")
			_close_menu()
		elif not _busy and not _moving:
			Audio.sfx("ui_ok")
			_open_menu()
		return
	if clicked and not _busy:
		var target := _tile_at(get_global_mouse_position())
		if _npc_at.has(target):
			_walk_to_npc(target)
		elif not _walk_to(target):
			_show_message("Tidak ada jalan ke sana.")


## Mulai berjalan otomatis ke petak tujuan. Mengembalikan false kalau tidak terjangkau.
func _walk_to(target: Vector2i) -> bool:
	var path := _find_path(_tile, target)
	if path.is_empty():
		_cancel_path()
		return target == _tile
	_path = path
	_talk_after = ""
	_marker.position = _iso(target)
	_marker.visible = true
	return true


## Jalan ke petak di sebelah NPC, lalu ajak bicara.
func _walk_to_npc(target: Vector2i) -> void:
	var npc: Dictionary = _npc_at[target]
	var d := (target - _tile).abs()
	if max(d.x, d.y) <= 1:
		_talk(npc.id)
		return
	var best: Array = []
	for dir: Vector2i in STEP_DIRS:
		var path := _find_path(_tile, target + dir)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	if best.is_empty():
		_show_message("Tidak ada jalan ke sana.")
		return
	_path = best
	_talk_after = npc.id
	_marker.position = _iso(target)
	_marker.visible = true


func _cancel_path() -> void:
	_path.clear()
	_talk_after = ""
	_marker.visible = false


## Rute terpendek (dalam jumlah langkah) dengan aturan gerak yang sama seperti keyboard:
## 8 arah, langkah silang tidak boleh memotong sudut petak terlarang.
func _find_path(from: Vector2i, to: Vector2i) -> Array:
	if from == to or not _walkable(to):
		return []
	var came := {from: from}
	var queue: Array = [from]
	var head := 0
	while head < queue.size() and not came.has(to):
		var t: Vector2i = queue[head]
		head += 1
		for d: Vector2i in STEP_DIRS:
			var n := t + d
			if came.has(n) or not _walkable(n):
				continue
			if d.x != 0 and d.y != 0 and not (_walkable(t + Vector2i(d.x, 0)) and _walkable(t + Vector2i(0, d.y))):
				continue
			came[n] = t
			queue.append(n)
	if not came.has(to):
		return []
	var path: Array = []
	var cursor := to
	while cursor != from:
		path.push_front(cursor)
		cursor = came[cursor]
	return path


## Tombol mengikuti arah layar: atas = ke atas layar, kanan = ke kanan layar.
## Dua tombol sekaligus = jalan miring mengikuti sisi petak.
func _input_dir() -> Vector2i:
	var sx := 0
	var sy := 0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		sx -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		sx += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		sy -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		sy += 1
	# Arah layar -> arah petak (peta isometrik diputar 45 derajat).
	return Vector2i(signi(sx + sy), signi(sy - sx))


## Langkah yang benar-benar diambil untuk arah yang diminta.
## Langkah silang (dua sumbu petak sekaligus) tidak boleh memotong sudut petak terlarang;
## kalau terhalang, pemain meluncur di sepanjang penghalang lewat salah satu sumbunya.
## Menabrak NPC = mengajaknya bicara.
func _resolve_step(dir: Vector2i) -> Vector2i:
	var a := Vector2i(dir.x, 0)
	var b := Vector2i(0, dir.y)
	var options: Array = [dir]
	if dir.x != 0 and dir.y != 0:
		if _walkable(_tile + a) and _walkable(_tile + b) and _walkable(_tile + dir):
			return dir
		options = [a, b] if _steps % 2 == 0 else [b, a]
	for option: Vector2i in options:
		if _walkable(_tile + option):
			return option
	for option: Vector2i in [dir, a, b]:
		if option == Vector2i.ZERO:
			continue
		if _npc_at.has(_tile + option):
			_talk(_npc_at[_tile + option].id)
			break
		if WorldMap.tile_at(_tile + option).has("gate"):
			_show_message(WorldMap.tile_at(_tile + option).locked)
			break
	return Vector2i.ZERO


func _on_step() -> void:
	_moving = false
	_steps += 1
	_face(Vector2i.ZERO, "stand")
	Game.player_tile = _tile
	_update_hud()
	var tile := WorldMap.tile_at(_tile)

	if tile.has("portal"):
		_travel(tile.portal)
	elif tile.has("boss"):
		var rule: Dictionary = Db.BOSS_RULES[tile.boss]
		if Game.flags.has(tile.boss):
			_show_message("Sarang ini sudah kosong.")
		elif not Game.flags.has(rule.need):  # belum punya rekan yang dibutuhkan
			_run_scene(Story.scene(rule.blocked))
		else:
			_start_battle(Db.BOSSES[tile.boss], rule.backdrop, rule.after)
	elif tile.has("scene"):
		_run_scene(Story.scene(tile.scene))
	elif String(tile.zone).begins_with("Hutan Kabut") and not Game.flags.has("kabut_intro"):
		_run_scene(Story.scene("kabut_intro"))
	elif tile.has("rate") and _steps > GRACE_STEPS and randf() < float(tile.rate):
		# Jumlah monster menyesuaikan besar party, supaya awal permainan (Arlen sendirian) tetap adil.
		var group: Array = Db.random_group(tile.table)
		_start_battle(group.slice(0, Game.party.size() + 1), BACKDROPS[_material(_tile)])
	elif _path.is_empty() and _talk_after != "":
		var npc_id := _talk_after
		_cancel_path()
		_talk(npc_id)


func _start_battle(enemy_ids: Array, backdrop: String = "lembah", after_scene: String = "") -> void:
	_busy = true
	_cancel_path()
	Audio.sfx("encounter")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.35)
	await tween.finished
	Game.start_battle(enemy_ids, backdrop, after_scene)


## Pindah ke peta lain lewat portal.
func _travel(map_id: String) -> void:
	_busy = true
	_cancel_path()
	Audio.sfx("door")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	await tween.finished
	var from_map := Game.map_id
	Game.map_id = map_id
	Game.player_tile = WorldMap.arrival(map_id, from_map)
	get_tree().change_scene_to_file(Game.WORLD_SCENE)


## Arah langkah -> gambar Arlen. Bergerak ke bawah layar = tampak depan, ke atas = tampak belakang;
## gambar dicerminkan saat bergerak ke kiri layar.
func _face(dir: Vector2i, pose: String) -> void:
	var sx := dir.x - dir.y
	var sy := dir.x + dir.y
	if sy != 0:
		_view = "front" if sy > 0 else "back"
	if sx != 0:
		_player.flip_h = sx < 0
	_player.texture = _tex("arlen_%s_%s" % [_view, pose])


# ---------------------------------------------------------------- dialog dan adegan

func _talk(npc_id: String) -> void:
	if _busy:
		return
	var npc := Story.npc(npc_id)
	if _npc_at.has(npc.get("tile")):  # hadapkan Arlen ke lawan bicaranya
		_face(npc.tile - _tile, "stand")
	_run_scene(Story.talk(npc_id, Game.flags, Game.gold))


## Jalankan sebuah adegan sampai habis (atau sampai sebuah battle dimulai).
func _run_scene(steps: Array) -> void:
	if steps.is_empty():
		return
	_busy = true
	_cancel_path()
	_msg_panel.visible = false
	var finished: bool = await _run_steps(steps)
	if not finished:
		return  # battle dimulai; scene ini sedang berganti
	_dialog_panel.visible = false
	_dialog_open = false
	_refresh_npcs()
	_update_hud()
	_dir_held = -0.25  # jeda singkat supaya tombol yang masih tertekan tidak langsung memicu lagi
	_busy = false


## Munculkan teks dialog huruf demi huruf dengan bunyi "tetetet".
## Menekan lanjut saat teks masih muncul langsung menampilkan seluruhnya.
func _type_text() -> void:
	var text := _dialog_text.text
	_typing = true
	_skip_typing = false
	_dialog_hint.visible = false
	for i in range(1, text.length() + 1):
		if _skip_typing:
			break
		_dialog_text.visible_characters = i
		if i % TYPE_BLIP_EVERY == 0 and text[i - 1] != " ":
			Audio.sfx("text")
		await get_tree().create_timer(TYPE_DELAY).timeout
	_dialog_text.visible_characters = -1
	_dialog_hint.visible = true
	_typing = false


## Mengembalikan false kalau adegan terhenti karena battle dimulai.
func _run_steps(steps: Array) -> bool:
	for step: Dictionary in steps:
		if step.has("text"):
			_dialog_name.text = step.get("who", "")
			_dialog_name.visible = _dialog_name.text != ""
			_dialog_text.text = step.text
			_dialog_hint.visible = true
			_dialog_choices.visible = false
			_dialog_panel.visible = true
			_dialog_open = true
			await _type_text()
			await advance
		elif step.has("choice"):
			var options: Array = step.choice
			_dialog_hint.visible = false
			_dialog_choices.visible = true
			_dialog_open = false  # pilihan dijawab lewat tombol, bukan tombol lanjut
			for child in _dialog_choices.get_children():
				child.queue_free()
			for i in options.size():
				var button := Button.new()
				button.text = options[i].text
				button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
				button.pressed.connect(func() -> void: Audio.sfx("ui_ok"))
				button.pressed.connect(func() -> void: chosen.emit(i))
				_dialog_choices.add_child(button)
				if i == 0:
					button.grab_focus()
			var index: int = await chosen
			for child in _dialog_choices.get_children():
				child.queue_free()
			var completed: bool = await _run_steps(options[index].steps)
			if not completed:
				return false
		else:
			match step.get("do", ""):
				"flag":
					Game.flags[step.flag] = true
				"join":
					Game.join(step.id)
					Audio.play_jingle("join")
					_update_hud()
				"pay":
					Game.gold = max(0, Game.gold - int(step.gold))
					Audio.sfx("coin")
					_update_hud()
				"shop":
					_shop_view.set_shop_name(step.get("name", "Toko Pak Joko"))
					await _shop(step.stock)
				"rest":  # menginap: pulih, jadi titik kembali, dan menyimpan permainan
					Game.rest_at_inn()
					Game.save_game()
					Audio.play_jingle("inn")
					_update_hud()
				"battle":
					_dialog_panel.visible = false
					_dialog_open = false
					_busy = false
					_start_battle(step.ids, step.get("backdrop", "lembah"), step.get("after", ""))
					return false
	return true


# ---------------------------------------------------------------- menu (Esc), tas, dan toko

## Isi panel menu. items: {"text", "cb", "disabled"?, "hint"?}; hint tampil saat tombol disorot.
func _fill_menu(title: String, items: Array, hint: String = "", focus_index: int = 0) -> void:
	for child in _menu_box.get_children():
		_menu_box.remove_child(child)
		child.queue_free()
	_menu_title.text = title
	_menu_hint.text = hint
	for i in items.size():
		var button := Button.new()
		button.text = items[i].text
		button.disabled = items[i].get("disabled", false)
		button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
		button.pressed.connect(func() -> void: Audio.sfx("ui_ok"))
		button.pressed.connect(items[i].cb)
		if items[i].has("hint"):
			var item_hint: String = items[i].hint
			button.focus_entered.connect(func() -> void: _menu_hint.text = item_hint)
			button.mouse_entered.connect(func() -> void: _menu_hint.text = item_hint)
		_menu_box.add_child(button)
	var focus := clampi(focus_index, 0, items.size() - 1)
	if (_menu_box.get_child(focus) as Button).disabled:
		focus = items.size() - 1  # tombol terakhir selalu Kembali/Selesai
	(_menu_box.get_child(focus) as Button).grab_focus()
	_menu_panel.visible = true


func _open_menu() -> void:
	_busy = true
	_menu_open = true
	_cancel_path()
	_fill_menu("Menu", [
		{"text": "Lanjut bermain", "cb": _close_menu},
		{"text": "Barang", "cb": func() -> void:
			_bag_from_menu = true
			_open_bag()},
		{"text": "Simpan permainan", "cb": _menu_save},
		{"text": "Muat simpanan terakhir", "cb": _menu_load, "disabled": not Game.has_save()},
		{"text": "Kembali ke layar judul", "cb": func() -> void: get_tree().change_scene_to_file(Game.TITLE_SCENE)},
	])


func _close_menu() -> void:
	_menu_panel.visible = false
	_menu_open = false
	_dir_held = -0.25
	_busy = false


func _menu_save() -> void:
	var saved := Game.save_game()
	if saved:
		Audio.sfx("save")
	_close_menu()
	_show_message("Permainan disimpan." if saved else "Gagal menyimpan permainan.")


func _menu_load() -> void:
	if Game.load_game():
		get_tree().change_scene_to_file(Game.WORLD_SCENE)
	else:
		_close_menu()
		_show_message("Simpanan tidak bisa dibaca.")


## Pintasan tas (tombol ikon tas atau tombol I): buka langsung dari peta, atau tutup kalau sedang terbuka.
func _toggle_bag() -> void:
	if _bag_open:
		if _bag.visible:
			_close_bag()
	elif not _busy and not _moving:
		_busy = true
		_cancel_path()
		_bag_from_menu = false
		_open_bag()


## Buka tampilan tas. Di peta hanya ramuan HP/MP yang bisa dipakai; sisanya khusus pertarungan.
func _open_bag(focus_item: String = "", message: String = "") -> void:
	_menu_panel.visible = false
	_bag_open = true
	_bag.open(Game.items, Game.bag_slots,
		func(item_id: String) -> bool: return Db.ITEMS[item_id].kind in ["heal", "mp"],
		true, focus_item, message)


## Tutup tas: kembali ke menu Esc kalau dibuka dari sana, atau langsung ke peta kalau lewat pintasan.
func _close_bag() -> void:
	_bag.visible = false
	_bag_open = false
	_menu_panel.visible = false
	if _bag_from_menu:
		_open_menu()
	else:
		_dir_held = -0.25
		_busy = false


func _menu_item_target(item_id: String) -> void:
	_bag.visible = false
	var item: Dictionary = Db.ITEMS[item_id]
	var items: Array = []
	for m: Battler in Game.party:
		items.append({"text": "%s   HP %d/%d   MP %d/%d" % [m.display_name, m.hp, m.max_hp, m.mp, m.max_mp],
			"cb": func() -> void: _menu_use_item(item_id, m)})
	items.append({"text": "< Kembali", "cb": func() -> void: _open_bag(item_id)})
	_fill_menu("%s untuk siapa?" % item.name, items, item.desc)


func _menu_use_item(item_id: String, target: Battler) -> void:
	var lines: Array = []
	if BattleEngine.apply_item(item_id, target, lines):
		Game.remove_item(item_id)
		Audio.sfx("potion")
		_update_hud()
	_open_bag(item_id, lines[0])


func _menu_discard(item_id: String) -> void:
	Game.remove_item(item_id)
	_open_bag(item_id, "Membuang 1 %s." % Db.ITEMS[item_id].name)


## Buka toko dan tunggu sampai pemain selesai berbelanja.
func _shop(stock: Array) -> void:
	_dialog_panel.visible = false
	_dialog_open = false
	_shop_open = true
	_shop_stock = stock
	_shop_view.open(stock)
	await shop_closed
	_shop_view.visible = false
	_shop_open = false


func _shop_buy(item_id: String) -> void:
	var item: Dictionary = Db.ITEMS[item_id]
	if Game.gold < int(item.price) or not Game.add_item(item_id):
		return
	Game.gold -= int(item.price)
	Audio.sfx("coin")
	_update_hud()
	_shop_view.open(_shop_stock, item_id, "Membeli %s." % item.name)


func _shop_upgrade() -> void:
	if not Game.upgrade_bag():
		return
	Audio.sfx("coin")
	_update_hud()
	_shop_view.open(_shop_stock, "__tas", "Tas diperbesar menjadi %d slot." % Game.bag_slots)

func _show_message(text: String) -> void:
	_msg_label.text = text
	_msg_panel.visible = true
	_msg_left = MSG_TIME


func _update_hud() -> void:
	var zone: String = WorldMap.tile_at(_tile).zone
	if zone == "":
		zone = WorldMap.map_name() if Game.map_id != "dunia" else "Jalan"
	_zone_label.text = "%s\nEmas: %d\nEsc: menu   I: tas" % [zone, Game.gold]
	var lines: Array = []
	for m: Battler in Game.party:
		lines.append("%-7s Lv %d   HP %d/%d   MP %d/%d" % [m.display_name, m.level, m.hp, m.max_hp, m.mp, m.max_mp])
	_party_label.text = "\n".join(lines)


# ---------------------------------------------------------------- tanah (datar)

func _tex(sprite_name: String) -> Texture2D:
	if not _textures.has(sprite_name):
		_textures[sprite_name] = load(SPRITES + sprite_name + ".png")
	return _textures[sprite_name]


## Pilihan varian yang tetap untuk petak yang sama, supaya peta tidak berubah tiap dibuka.
func _variant(t: Vector2i, count: int) -> int:
	return posmod(hash(t), count)


func _draw() -> void:
	draw_rect(_bounds.grow(400), Color("4b473d") if WorldMap.outside() == "^" else (Color("2a5450") if WorldMap.is_mist() else Color("2f5a34")))
	var w := WorldMap.width()
	var h := WorldMap.height()
	var view := _bounds.grow(HALF_W * 2)
	var far: Array = []
	# Petak di luar peta ikut digambar (pegunungan atau hutan) supaya sudut layar tidak kosong.
	for y in range(-w / 2 - 2, h + w / 2 + 2):
		for x in range(-h / 2 - 2, w + h / 2 + 2):
			var t := Vector2i(x, y)
			var c := _iso(t)
			if not view.has_point(c):
				continue
			_draw_ground(t, c)
			if not WorldMap.in_bounds(t):
				far.append(t)
	far.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.x + p.y < q.x + q.y)
	for t: Vector2i in far:
		var prop := _far_prop(t)
		if not prop.is_empty():
			var tex := _tex(prop.name)
			draw_texture_rect(tex, Rect2(_iso(t) - Vector2(prop.anchor) * PIXEL, tex.get_size() * PIXEL), false)


## Hiasan di luar batas peta: pegunungan yang dijarangkan, atau hutan lebat di sekeliling desa.
func _far_prop(t: Vector2i) -> Dictionary:
	if WorldMap.outside() == "^":
		var sprite_name := _mountain_name(t, 1, 5)
		return {} if sprite_name == "" else {"name": sprite_name, "anchor": MOUNTAIN_ANCHOR}
	if _variant(t + Vector2i(7, 3), 10) < 8:
		return {"name": _tree_name(t), "anchor": TREE_ANCHOR}
	return {}


## Dari 10 kemungkinan: sebanyak `snowy` jadi gunung bersalju, sampai `hills` jadi bukit, sisanya kosong.
func _mountain_name(t: Vector2i, snowy: int, hills: int) -> String:
	var v := _variant(t + Vector2i(7, 3), 10)
	if v < snowy:
		return "mountain_%d" % _variant(t, 3)
	if v < hills:
		return "hill_%d" % _variant(t, 2)
	return ""


func _tree_name(t: Vector2i) -> String:
	if WorldMap.is_mist():
		return "mist_pine" if _variant(t, 10) < 5 else "mist_round"
	return "tree_pine" if _variant(t, 10) < 3 else "tree_round"


func _material(t: Vector2i) -> String:
	match WorldMap.char_at(t):
		".", "g", "h", "I":
			return "mist_grass" if WorldMap.is_mist() else "grass"
		"f", "Y":
			return "mist_floor" if WorldMap.is_mist() else "forest_floor"
		",":
			return "mist_grass"
		"F", "Q":
			return "mist_floor"
		"~":
			return "water"
		"^", "B":
			return "rock"
	return "path"


func _draw_ground(t: Vector2i, c: Vector2) -> void:
	var mat := _material(t)
	var rect := Rect2(c - Vector2(HALF_W, HALF_H), Vector2(HALF_W, HALF_H) * 2)
	draw_texture_rect(_tex("%s_%d" % [mat, _variant(t, GROUND_VARIANTS[mat])]), rect, false)
	# Bahan tetangga yang prioritasnya lebih tinggi merambat sedikit ke petak ini.
	for side: String in EDGE_SIDES:
		var other := _material(t + EDGE_SIDES[side])
		if GROUND_PRIORITY[other] > GROUND_PRIORITY[mat]:
			draw_texture_rect(_tex("edge_%s_%s_%d" % [other, side, _variant(t, 2)]), rect, false)


# ---------------------------------------------------------------- benda bertinggi (y-sort)

func _build_objects() -> void:
	_objects = Node2D.new()
	_objects.y_sort_enabled = true
	add_child(_objects)
	for y in WorldMap.height():
		for x in WorldMap.width():
			var t := Vector2i(x, y)
			var sprite: Sprite2D = null
			match WorldMap.char_at(t):
				"^":
					sprite = _sprite(_mountain_name(t, 6, 10), MOUNTAIN_ANCHOR)
				"f", "Y":
					sprite = _sprite(_tree_name(t), TREE_ANCHOR)
				"F":
					sprite = _sprite("mist_pine" if _variant(t, 10) < 5 else "mist_round", TREE_ANCHOR)
				"T", "h", "D":
					sprite = _sprite("house", HOUSE_ANCHOR)
				"Q":  # sarang Ratu Laba-laba: gua yang sama, bernuansa ungu
					sprite = _sprite("lair_empty" if Game.flags.has(WorldMap.tile_at(t).boss) else "lair_occupied", Vector2(18, 30))
					sprite.modulate = Color(0.78, 0.66, 1.0)
				"P":
					sprite = _sprite("gate_open" if Game.flags.has(WorldMap.tile_at(t).gate) else "gate_closed", Vector2(20, 30))
				"I":
					sprite = _sprite("inn", HOUSE_ANCHOR)
				"B":
					sprite = _sprite("lair_empty" if Game.flags.has(WorldMap.tile_at(t).boss) else "lair_occupied", Vector2(18, 30))
				"G":
					sprite = _sprite("gate_open" if Game.flags.has(WorldMap.tile_at(t).gate) else "gate_closed", Vector2(20, 30))
			if sprite != null:
				sprite.position = _iso(t)
				_objects.add_child(sprite)
	for npc: Dictionary in Story.NPCS.get(Game.map_id, []):
		var sprite := _sprite("%s_front_stand" % npc.sprite, PERSON_ANCHOR)
		sprite.position = _iso(npc.tile)
		_objects.add_child(sprite)
		_npc_sprites[npc.id] = sprite
	_refresh_npcs()


## Tampilkan/sembunyikan NPC sesuai penanda cerita (mis. Mira hilang dari peta setelah bergabung).
func _refresh_npcs() -> void:
	_npc_at.clear()
	for npc: Dictionary in Story.NPCS.get(Game.map_id, []):
		var shown := Story.npc_visible(npc, Game.flags)
		(_npc_sprites[npc.id] as Sprite2D).visible = shown
		if shown:
			_npc_at[npc.tile] = npc


## Sprite 1x yang ditampilkan 2x; anchor = titik di gambar yang menempel di tengah petak.
func _sprite(sprite_name: String, anchor: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _tex(sprite_name)
	sprite.centered = false
	sprite.offset = -anchor
	sprite.scale = Vector2(PIXEL, PIXEL)
	return sprite


## Penanda petak tujuan klik: bingkai belah ketupat di atas tanah, di bawah benda-benda.
func _build_marker() -> void:
	_marker = Line2D.new()
	_marker.points = PackedVector2Array([
		Vector2(0, -HALF_H + 2), Vector2(HALF_W - 4, 0), Vector2(0, HALF_H - 2), Vector2(-HALF_W + 4, 0)])
	_marker.closed = true
	_marker.width = 2.0
	_marker.default_color = Color("ffd866")
	_marker.visible = false
	add_child(_marker)


func _build_player() -> void:
	_player = _sprite("arlen_front_stand", PERSON_ANCHOR)
	_player.position = _iso(_tile) + Vector2(0, 1)
	_objects.add_child(_player)

	var camera := Camera2D.new()
	camera.position = Vector2(0, -6)
	camera.scale = Vector2.ONE / PIXEL
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.limit_left = int(_bounds.position.x)
	camera.limit_top = int(_bounds.position.y)
	camera.limit_right = int(_bounds.end.x)
	camera.limit_bottom = int(_bounds.end.y)
	_player.add_child(camera)


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 17
	root.theme = ui_theme
	layer.add_child(root)

	var zone_panel := _make_panel()
	zone_panel.position = Vector2(16, 16)
	root.add_child(zone_panel)
	_zone_label = Label.new()
	zone_panel.add_child(_zone_label)

	var party_panel := _make_panel()
	party_panel.anchor_left = 1.0
	party_panel.anchor_right = 1.0
	party_panel.offset_left = -16
	party_panel.offset_right = -16
	party_panel.offset_top = 16
	party_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(party_panel)
	_party_label = Label.new()
	party_panel.add_child(_party_label)

	_msg_panel = _make_panel()
	_msg_panel.anchor_left = 0.5
	_msg_panel.anchor_right = 0.5
	_msg_panel.anchor_top = 1.0
	_msg_panel.anchor_bottom = 1.0
	_msg_panel.offset_bottom = -24
	_msg_panel.offset_top = -24
	_msg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_msg_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_msg_panel.visible = false
	root.add_child(_msg_panel)
	_msg_label = Label.new()
	_msg_panel.add_child(_msg_label)

	# Kotak dialog: nama pembicara, teks, lalu pilihan (kalau ada).
	_dialog_panel = _make_panel()
	_dialog_panel.anchor_left = 0.5
	_dialog_panel.anchor_right = 0.5
	_dialog_panel.anchor_top = 1.0
	_dialog_panel.anchor_bottom = 1.0
	_dialog_panel.offset_left = -430
	_dialog_panel.offset_right = 430
	_dialog_panel.offset_top = -24
	_dialog_panel.offset_bottom = -24
	_dialog_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dialog_panel.visible = false
	root.add_child(_dialog_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_dialog_panel.add_child(column)
	_dialog_name = Label.new()
	_dialog_name.add_theme_color_override("font_color", COLOR_BORDER)
	column.add_child(_dialog_name)
	_dialog_text = Label.new()
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.custom_minimum_size = Vector2(820, 56)
	_dialog_text.add_theme_font_size_override("font_size", 19)
	column.add_child(_dialog_text)
	_dialog_choices = VBoxContainer.new()
	column.add_child(_dialog_choices)
	_dialog_hint = Label.new()
	_dialog_hint.text = "Spasi / Enter / klik untuk lanjut"
	_dialog_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialog_hint.add_theme_font_size_override("font_size", 13)
	_dialog_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	column.add_child(_dialog_hint)

	# Menu Esc: simpan, muat, kembali ke judul.
	_menu_panel = _make_panel()
	_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_menu_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_menu_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu_panel.visible = false
	root.add_child(_menu_panel)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 8)
	menu_column.custom_minimum_size.x = 380
	_menu_panel.add_child(menu_column)
	_menu_title = Label.new()
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_color_override("font_color", COLOR_BORDER)
	menu_column.add_child(_menu_title)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 6)
	menu_column.add_child(_menu_box)
	_menu_hint = Label.new()
	_menu_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_hint.custom_minimum_size = Vector2(360, 44)
	_menu_hint.add_theme_font_size_override("font_size", 14)
	_menu_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	menu_column.add_child(_menu_hint)

	# Tombol pintasan tas di pojok kiri bawah.
	var bag_button := Button.new()
	bag_button.focus_mode = Control.FOCUS_NONE  # supaya Spasi/Enter tidak memicunya
	bag_button.tooltip_text = "Tas (I)"
	bag_button.anchor_top = 1.0
	bag_button.anchor_bottom = 1.0
	bag_button.offset_left = 16
	bag_button.offset_right = 80
	bag_button.offset_top = -80
	bag_button.offset_bottom = -16
	for state: String in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.12, 0.17, 0.25, 0.95) if state == "hover" else COLOR_PANEL
		box.border_color = Color("ffd866") if state == "hover" else COLOR_BORDER
		box.set_border_width_all(2)
		box.set_corner_radius_all(6)
		bag_button.add_theme_stylebox_override(state, box)
	bag_button.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		_toggle_bag())
	root.add_child(bag_button)
	var bag_icon := TextureRect.new()
	bag_icon.texture = _tex("icon_tas")
	bag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag_icon.stretch_mode = TextureRect.STRETCH_SCALE
	bag_icon.size = Vector2(48, 48)
	bag_icon.position = Vector2(8, 4)
	bag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_button.add_child(bag_icon)
	var bag_key := Label.new()
	bag_key.text = "I"
	bag_key.add_theme_font_size_override("font_size", 13)
	bag_key.add_theme_color_override("font_color", COLOR_BORDER)
	bag_key.position = Vector2(49, 43)
	bag_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_button.add_child(bag_key)

	_shop_view = (load("res://scripts/ui/shop_view.gd") as GDScript).new()
	_shop_view.buy.connect(_shop_buy)
	_shop_view.upgrade.connect(_shop_upgrade)
	_shop_view.closed.connect(func() -> void: shop_closed.emit())
	root.add_child(_shop_view)

	_bag = (load("res://scripts/ui/bag_view.gd") as GDScript).new()
	_bag.picked.connect(_menu_item_target)
	_bag.discarded.connect(_menu_discard)
	_bag.closed.connect(_close_bag)
	root.add_child(_bag)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	return panel
