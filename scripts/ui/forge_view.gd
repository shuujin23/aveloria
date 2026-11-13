extends PanelContainer
## Tampilan pandai besi dengan empat tab: Beli perlengkapan, Tempa (enhance), Tempa Ulang (acak sifat),
## dan Jual Bahan. Semua aksi langsung mengubah Game; pemakainya memanggil open(tier, nama) lalu
## menanggapi sinyal changed (emas/stat berubah) dan closed.

signal changed
signal closed

const GearIcon := preload("res://scripts/ui/gear_icon.gd")
const TABS := ["Beli", "Tempa", "Tempa Ulang", "Jual Bahan"]
const TAB_HINTS := [
	"Perlengkapan langsung dipakai tokoh pemiliknya. Barang lama di slot itu tergantikan.",
	"Tiap tingkat tempa menambah stat dan berpeluang memberi sifat (efek status) kalau belum punya.",
	"Mengacak sifat senjata menjadi sifat lain. Tingkat tempa tidak berubah.",
	"Jual bahan yang tidak terpakai. Tekan kartu untuk menjual satu.",
]
const CARD_SIZE := Vector2(330, 88)
const COLOR_GOLD := Color("c9a85c")

var _tier := 1
var _tab := 0
var _member := 0
var _title: Label
var _purse: Label
var _tab_box: HBoxContainer
var _member_box: HBoxContainer
var _grid: GridContainer
var _detail: Label


func _init() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.13, 0.96)
	style.border_color = COLOR_GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	visible = false

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.add_theme_color_override("font_color", COLOR_GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_purse = Label.new()
	header.add_child(_purse)

	_tab_box = HBoxContainer.new()
	_tab_box.add_theme_constant_override("separation", 6)
	column.add_child(_tab_box)
	_member_box = HBoxContainer.new()
	_member_box.add_theme_constant_override("separation", 6)
	column.add_child(_member_box)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	var scroll := ScrollContainer.new()  # tab Jual Bahan bisa berisi sampai 16 kartu
	scroll.custom_minimum_size = Vector2(CARD_SIZE.x * 2 + 22, CARD_SIZE.y * 3 + 16)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	scroll.add_child(_grid)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(CARD_SIZE.x * 2 + 8, 68)
	_detail.add_theme_font_size_override("font_size", 15)
	column.add_child(_detail)

	var done := Button.new()
	done.text = Loc.t("Selesai")
	done.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	done.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		closed.emit())
	column.add_child(done)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_cancel")
		closed.emit()


## Buka pandai besi. tier = tingkat perlengkapan yang dijualnya (1..3).
func open(tier: int, shop_name: String) -> void:
	_tier = tier
	_title.text = shop_name
	_tab = 0
	_member = 0
	visible = true
	_rebuild(0)


## Susun ulang semua isi. focus_card = kartu yang disorot; message = teks pengganti petunjuk tab.
func _rebuild(focus_card: int = 0, message: String = "") -> void:
	for box: Node in [_tab_box, _member_box, _grid]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	_purse.text = Loc.t("Emas: %d") % Game.gold
	_member = clampi(_member, 0, Game.party.size() - 1)

	for i in TABS.size():
		_tab_box.add_child(_toggle(Loc.t(TABS[i]), i == _tab, func() -> void:
			_tab = i
			_rebuild()))
	_member_box.visible = _tab != 3
	for i in Game.party.size():
		var m: Battler = Game.party[i]
		_member_box.add_child(_toggle("%s (%s)" % [m.display_name, Loc.t(m.job)], i == _member, func() -> void:
			_member = i
			_rebuild()))

	_detail.text = Loc.t(TAB_HINTS[_tab]) if message == "" else message
	var cards: Array = []
	var who: Battler = Game.party[_member]
	match _tab:
		0:
			for slot: String in Db.GEAR_SLOTS:
				cards.append(_buy_card(who, slot))
		1:
			for slot: String in Db.GEAR_SLOTS:
				cards.append(_enhance_card(who, slot))
		2:
			for slot: String in Db.GEAR_SLOTS:
				cards.append(_reforge_card(who, slot))
		3:
			for mat_id: String in Db.MATERIALS:
				if int(Game.mats.get(mat_id, 0)) > 0:
					cards.append(_sell_card(mat_id))
			if cards.is_empty():
				_detail.text = Loc.t("Kantong bahan kosong. Monster menjatuhkan bahan saat dikalahkan.") if message == "" else message
	if cards.is_empty():
		(_tab_box.get_child(_tab) as Button).grab_focus()
	else:
		(cards[clampi(focus_card, 0, cards.size() - 1)] as Button).grab_focus()
	if message != "":
		_detail.text = message  # menyorot kartu barusan menimpa pesan; kembalikan


func _toggle(text: String, active: bool, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if active:
		button.add_theme_color_override("font_color", Color("ffd866"))
		button.add_theme_color_override("font_focus_color", Color("ffd866"))
	button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	button.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		on_press.call())
	return button


# ---------------------------------------------------------------- kartu tiap tab

func _buy_card(m: Battler, slot: String) -> Button:
	var gear_id := Db.gear_id(m.id, slot, _tier)
	var g := Db.gear(gear_id)
	var entry := {"id": gear_id, "plus": 0, "trait": ""}
	var reason := Game.gear_block(gear_id)
	var desc := Loc.t("%s untuk %s: %s.") % [g.name, m.display_name, Db.gear_stat_text(gear_id, 0)]
	if m.equip.has(slot):
		var old: Dictionary = m.equip[slot]
		desc += Loc.t("\nSekarang memakai %s (%s).") % [Db.gear_title(old), Db.gear_stat_text(old.id, int(old.plus))]
		if reason == "" and (int(old.plus) > 0 or old["trait"] != ""):
			desc += Loc.t(" Tingkat tempa dan sifat barang lama tidak ikut pindah.")
	else:
		desc += Loc.t("\nSlot %s masih kosong.") % Loc.t(Db.GEAR_SLOT_NAMES[slot])
	var index := Db.GEAR_SLOTS.find(slot)
	return _card(GearIcon.gear(entry), g.name, Loc.t("%d emas") % g.price, Db.gear_stat_text(gear_id, 0), desc, reason,
		func() -> void:
			if Game.buy_gear(gear_id):
				Audio.sfx("coin")
				changed.emit()
				_rebuild(index, Loc.t("%s membeli dan memakai %s.") % [m.display_name, g.name]))


func _enhance_card(m: Battler, slot: String) -> Button:
	if not m.equip.has(slot):
		return _empty_card(slot)
	var entry: Dictionary = m.equip[slot]
	var plus := int(entry.plus)
	var cost := Db.enhance_cost(entry.id, plus)
	var index := Db.GEAR_SLOTS.find(slot)
	var trait_text := Db.trait_text(entry)
	if cost.is_empty():
		return _card(GearIcon.gear(entry), Db.gear_title(entry), Loc.t("Tempa maksimal"), Db.gear_stat_text(entry.id, plus),
			Loc.t("%s sudah +%d.%s") % [Db.gear(entry.id).name, plus, "" if trait_text == "" else Loc.t("\nSifat: ") + trait_text],
			Loc.t("Sudah mencapai tingkat tempa maksimal."), func() -> void: pass)
	var reason := "" if Game.can_pay(cost) else Loc.t("Emas atau bahan belum cukup.")
	var desc := "%s  ->  +%d: %s." % [Db.gear_stat_text(entry.id, plus), plus + 1, Db.gear_stat_text(entry.id, plus + 1)]
	if trait_text == "":
		desc += Loc.t("\nPeluang mendapat sifat: %d%%.") % roundi(float(Db.TRAIT_GAIN_CHANCE[plus]) * 100.0)
	else:
		desc += Loc.t("\nSifat: %s; peluangnya naik menjadi %d%%.") % [trait_text, roundi(Db.trait_chance(plus + 1) * 100.0)]
	return _card(GearIcon.gear(entry), Db.gear_title(entry), Loc.t("ke +%d:  %d emas") % [plus + 1, cost.gold],
		Db.mats_text(cost.mats, Game.mats), desc, reason,
		func() -> void:
			var result := Game.enhance(m, slot)
			if not result.ok:
				return
			changed.emit()
			var text := Loc.t("%s kini +%d.") % [Db.gear(entry.id).name, int(entry.plus)]
			if result["trait"] != "":
				Audio.play_jingle("fanfare")
				text += Loc.t("\nMendapat sifat baru: %s!") % Db.trait_text(entry)
			else:
				Audio.sfx("buff")
			_rebuild(index, text))


func _reforge_card(m: Battler, slot: String) -> Button:
	if not m.equip.has(slot):
		return _empty_card(slot)
	var entry: Dictionary = m.equip[slot]
	var cost := Db.reforge_cost(entry.id)
	var index := Db.GEAR_SLOTS.find(slot)
	var trait_text := Db.trait_text(entry)
	var options: Array = []
	for status_id: String in Db.trait_pool(entry.id):
		options.append(Loc.t(Db.STATUSES[status_id].name))
	return _card(GearIcon.gear(entry), Db.gear_title(entry), Loc.t("%d emas") % cost.gold, Db.mats_text(cost.mats, Game.mats),
		Loc.t("Sifat sekarang: %s.\nSifat yang mungkin: %s.") % [Loc.t("belum ada") if trait_text == "" else trait_text, ", ".join(options)],
		Game.reforge_block(m, slot),
		func() -> void:
			if Game.reforge(m, slot) != "":
				Audio.sfx("buff")
				changed.emit()
				_rebuild(index, Loc.t("Sifat %s berubah menjadi: %s.") % [Db.gear_title(entry), Db.trait_text(entry)]))


func _sell_card(mat_id: String) -> Button:
	var mat: Dictionary = Db.MATERIALS[mat_id]
	var count := int(Game.mats.get(mat_id, 0))
	var index := 0
	for other: String in Db.MATERIALS:
		if other == mat_id:
			break
		if int(Game.mats.get(other, 0)) > 0:
			index += 1
	var card := _card(GearIcon.material(mat_id), Loc.t(mat.name), Loc.t("jual %d emas") % mat.sell, Loc.t("punya %d") % count,
		Loc.t("%s: bahan %s dari %s. Dipakai untuk menempa perlengkapan tingkat %d.") % [Loc.t(mat.name), Db.RARITIES[mat.rarity].name,
			Loc.t(Db.REGION_NAMES[mat.region]), mat.region] if int(mat.region) <= Db.GEAR_TIERS else
		Loc.t("%s: bahan %s dari %s. Tidak dipakai untuk menempa; laku dijual mahal.") % [Loc.t(mat.name), Db.RARITIES[mat.rarity].name,
			Loc.t(Db.REGION_NAMES[mat.region])], "",
		func() -> void:
			if Game.sell_mat(mat_id):
				Audio.sfx("coin")
				changed.emit()
				_rebuild(index, Loc.t("Menjual 1 %s seharga %d emas.") % [Loc.t(mat.name), mat.sell]))
	return card


func _empty_card(slot: String) -> Button:
	var card := _card(null, Loc.t(Db.GEAR_SLOT_NAMES[slot]), Loc.t("kosong"), "", Loc.t("Slot %s masih kosong. Beli dulu di tab Beli.") % Loc.t(Db.GEAR_SLOT_NAMES[slot]),
		Loc.t("Slot ini kosong."), func() -> void: pass)
	return card


## Satu kartu: ikon di kiri; judul, baris harga, dan catatan di kanan.
## reason = alasan tidak bisa ditekan (kartu diredupkan dan menekannya hanya menampilkan alasan itu).
func _card(icon: Control, title: String, price: String, note: String, desc: String, reason: String, on_press: Callable) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("243044") if state == "hover" else Color("1a2332")
		box.border_color = Color("ffd866") if state == "focus" else Color("3a4860")
		if state == "focus":
			box.bg_color = Color(0, 0, 0, 0)
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		card.add_theme_stylebox_override(state, box)

	var body := Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.modulate.a = 0.45 if reason != "" else 1.0
	card.add_child(body)
	if icon != null:
		icon.position = Vector2(14, (CARD_SIZE.y - icon.size.y) * 0.5)
		body.add_child(icon)
	_text(body, title, Vector2(76, 8), 17, Color.WHITE)
	_text(body, price, Vector2(76, 33), 15, Color("ffd866"))
	_text(body, note, Vector2(76, 57), 13, Color(1, 1, 1, 0.7))

	var show_detail := func() -> void:
		_detail.text = desc if reason == "" else "%s\n(%s)" % [desc, reason]
		Audio.sfx("ui_move")
	card.focus_entered.connect(show_detail)
	card.mouse_entered.connect(show_detail)
	card.pressed.connect(func() -> void:
		if reason == "":
			on_press.call()
		else:
			Audio.sfx("ui_cancel")
			_detail.text = reason)
	_grid.add_child(card)
	return card


func _text(parent: Control, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
