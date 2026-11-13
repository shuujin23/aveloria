extends PanelContainer
## Layar Perlengkapan: empat slot tiap anggota party beserta statnya, dan isi kantong bahan.
## Hanya untuk melihat; membeli dan menempa dilakukan di pandai besi. Pemakainya memanggil open()
## dan menanggapi sinyal closed.

signal closed

const GearIcon := preload("res://scripts/ui/gear_icon.gd")
const SLOT_SIZE := Vector2(64, 64)
const COLOR_GOLD := Color("c9a85c")

var _rows: VBoxContainer
var _mats: HFlowContainer
var _mats_title: Label
var _detail: Label
var _close: Button


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
	column.custom_minimum_size.x = 760
	add_child(column)

	var title := Label.new()
	title.text = Loc.t("Perlengkapan")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(title)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	column.add_child(_rows)
	column.add_child(HSeparator.new())

	_mats_title = Label.new()
	_mats_title.add_theme_color_override("font_color", COLOR_GOLD)
	_mats_title.add_theme_font_size_override("font_size", 15)
	column.add_child(_mats_title)
	_mats = HFlowContainer.new()
	_mats.add_theme_constant_override("h_separation", 6)
	_mats.add_theme_constant_override("v_separation", 6)
	column.add_child(_mats)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(740, 46)
	_detail.add_theme_font_size_override("font_size", 15)
	column.add_child(_detail)

	_close = Button.new()
	_close.text = Loc.t("Tutup")
	_close.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	_close.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		closed.emit())
	column.add_child(_close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_cancel")
		closed.emit()


func open() -> void:
	for box: Node in [_rows, _mats]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()

	for m: Battler in Game.party:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var who := Label.new()
		who.text = "%s\n%s  Lv %d" % [m.display_name, Loc.t(m.job), m.level]
		who.custom_minimum_size.x = 130
		who.add_theme_font_size_override("font_size", 15)
		row.add_child(who)
		for slot: String in Db.GEAR_SLOTS:
			row.add_child(_slot(m, slot))
		var stats := Label.new()
		stats.text = "HP %d   MP %d\nATK %d   DEF %d\nMAG %d   SPD %d" % [m.max_hp, m.max_mp, m.atk, m.defense, m.mag, m.agi]
		stats.add_theme_font_size_override("font_size", 14)
		stats.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		row.add_child(stats)
		_rows.add_child(row)

	var total := 0
	for mat_id: String in Db.MATERIALS:
		var count := int(Game.mats.get(mat_id, 0))
		if count <= 0:
			continue
		total += count
		var mat: Dictionary = Db.MATERIALS[mat_id]
		var cell := _cell(GearIcon.material(mat_id, count), Loc.t("%s   (%s, %s)   punya %d\nBahan tempa. Harga jual %d emas.") % [
			Loc.t(mat.name), Db.RARITIES[mat.rarity].name, Loc.t(Db.REGION_NAMES[mat.region]), count, mat.sell])
		_mats.add_child(cell)
	_mats_title.text = Loc.t("Kantong bahan") if total > 0 else Loc.t("Kantong bahan: kosong. Monster menjatuhkan bahan tempa saat dikalahkan.")

	_detail.text = Loc.t("Sorot perlengkapan atau bahan untuk melihat keterangannya. Beli dan tempa di pandai besi.")
	visible = true
	_close.grab_focus()


func _slot(m: Battler, slot: String) -> Button:
	if not m.equip.has(slot):
		var empty := _cell(null, Loc.t("%s %s: kosong. Pandai besi menjual perlengkapan untuk tiap tokoh.") % [
			Loc.t(Db.GEAR_SLOT_NAMES[slot]), m.display_name])
		var label := Label.new()
		label.text = Loc.t(Db.GEAR_SLOT_NAMES[slot])
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
		label.size = SLOT_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.add_child(label)
		return empty
	var entry: Dictionary = m.equip[slot]
	var text := "%s   (%s %s)   %s" % [Db.gear_title(entry), Loc.t(Db.GEAR_SLOT_NAMES[slot]), m.display_name,
		Db.gear_stat_text(entry.id, int(entry.plus))]
	var trait_text := Db.trait_text(entry)
	text += Loc.t("\nSifat: %s") % trait_text if trait_text != "" else Loc.t("\nBelum punya sifat. Menempa berpeluang memberinya sifat.")
	return _cell(GearIcon.gear(entry), text)


## Satu kotak: ikon (boleh kosong) yang menampilkan `text` saat disorot.
func _cell(icon: Control, text: String) -> Button:
	var cell := Button.new()
	cell.custom_minimum_size = SLOT_SIZE
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("243044") if state == "hover" else Color("1a2332")
		box.border_color = Color("ffd866") if state == "focus" else Color("3a4860")
		if state == "focus":
			box.bg_color = Color(0, 0, 0, 0)
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		cell.add_theme_stylebox_override(state, box)
	if icon != null:
		icon.position = (SLOT_SIZE - icon.size) * 0.5
		cell.add_child(icon)
	var show_text := func() -> void:
		_detail.text = text
		Audio.sfx("ui_move")
	cell.focus_entered.connect(show_text)
	cell.mouse_entered.connect(show_text)
	return cell
