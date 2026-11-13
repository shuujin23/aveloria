extends PanelContainer
## Tampilan tas: kisi slot berikon, rincian barang yang disorot, dan tombol aksi.
## Dipakai scene peta (pakai/buang barang) dan layar battle (memilih barang untuk dipakai).
## Pemakainya memanggil open() lalu menanggapi sinyal picked / discarded / closed.

signal picked(item_id: String)  # pemain memilih memakai barang ini
signal discarded(item_id: String)  # pemain membuang satu barang ini
signal closed

const SPRITES := "res://assets/sprites/"
const COLUMNS := 6
const SLOT_SIZE := Vector2(68, 68)
const ICON_SIZE := Vector2(48, 48)
const COLOR_GOLD := Color("c9a85c")

var _title: Label
var _grid: GridContainer
var _name: Label
var _desc: Label
var _use: Button
var _drop: Button
var _selected := ""
var _usable := Callable()
var _counts := {}


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
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(_title)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(_grid)

	_name = Label.new()
	_name.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(_name)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(COLUMNS * (SLOT_SIZE.x + 6), 48)
	_desc.add_theme_font_size_override("font_size", 15)
	column.add_child(_desc)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	_use = _action(actions, Loc.t("Pakai"), func() -> void:
		if _selected != "":
			picked.emit(_selected))
	_drop = _action(actions, Loc.t("Buang 1"), func() -> void:
		if _selected != "":
			discarded.emit(_selected))
	_action(actions, Loc.t("Tutup"), func() -> void: closed.emit())


func _action(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	button.pressed.connect(func() -> void: Audio.sfx("ui_ok"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_cancel")
		closed.emit()


## Tampilkan tas.
##   counts        id barang -> jumlah yang ditampilkan
##   capacity      jumlah slot tas
##   usable        Callable(item_id) -> bool: apakah barang itu bisa dipakai sekarang
##   allow_discard tampilkan tombol Buang
##   focus_item    barang yang langsung disorot (mis. yang baru saja dipakai)
##   message       teks pengganti deskripsi sampai pemain menyorot slot lain
func open(counts: Dictionary, capacity: int, usable: Callable, allow_discard: bool,
		focus_item: String = "", message: String = "") -> void:
	_counts = counts
	_usable = usable
	_drop.visible = allow_discard
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()

	var stacks := Db.stacks_of(counts)
	_title.text = Loc.t("Tas   %d / %d slot   (tiap slot memuat %d barang sejenis)") % [min(stacks.size(), capacity), capacity, Db.STACK_MAX]
	var first: Button = null
	var wanted: Button = null
	for i in max(capacity, stacks.size()):
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		_style_slot(slot, i >= capacity)
		if i < stacks.size():
			var item_id: String = stacks[i].id
			_fill_slot(slot, item_id, stacks[i].count)
			slot.focus_entered.connect(func() -> void: _select(item_id))
			slot.mouse_entered.connect(func() -> void: _select(item_id))
			slot.pressed.connect(func() -> void:
				if _usable.call(item_id):
					Audio.sfx("ui_ok")
					picked.emit(item_id)
				else:
					Audio.sfx("ui_cancel"))
			if first == null:
				first = slot
			if item_id == focus_item and wanted == null:
				wanted = slot
		else:
			slot.disabled = true
			slot.focus_mode = Control.FOCUS_NONE
		_grid.add_child(slot)

	visible = true
	_selected = ""
	_name.text = Loc.t("Tas kosong") if first == null else ""
	_desc.text = Loc.t("Doran di desa menjual ramuan.") if first == null else ""
	_use.disabled = true
	_drop.disabled = true
	if wanted != null:
		wanted.grab_focus()
	elif first != null:
		first.grab_focus()
	else:
		(_use.get_parent().get_child(2) as Button).grab_focus()
	if message != "":
		_desc.text = message



## Bingkai slot: kosong pun tetap terlihat sebagai kotak, supaya kapasitas tas terbaca sekilas.
## overflow = slot di luar kapasitas (hanya muncul kalau isi tas melebihi kapasitas).
func _style_slot(slot: Button, overflow: bool) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("1a2332") if state != "hover" else Color("243044")
		box.border_color = Color("3a4860")
		if state == "focus":
			box.bg_color = Color(0, 0, 0, 0)
			box.border_color = Color("ffd866")
		elif overflow:
			box.border_color = Color("a04a4a")
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		slot.add_theme_stylebox_override(state, box)


func _fill_slot(slot: Button, item_id: String, count: int) -> void:
	var icon := TextureRect.new()
	icon.texture = load(SPRITES + "icon_%s.png" % item_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = ICON_SIZE
	icon.position = (SLOT_SIZE - ICON_SIZE) * 0.5 - Vector2(0, 4)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var amount := Label.new()
	amount.text = "x%d" % count
	amount.add_theme_font_size_override("font_size", 14)
	amount.add_theme_constant_override("outline_size", 5)
	amount.add_theme_color_override("font_outline_color", Color("10141c"))
	amount.size = Vector2(SLOT_SIZE.x - 6, 18)
	amount.position = Vector2(0, SLOT_SIZE.y - 21)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(amount)


func _select(item_id: String) -> void:
	if item_id != _selected:
		Audio.sfx("ui_move")
	_selected = item_id
	var item: Dictionary = Db.ITEMS[item_id]
	var can_use: bool = _usable.call(item_id)
	_name.text = Loc.t("%s   (punya %d)") % [Loc.t(item.name), int(_counts.get(item_id, 0))]
	_desc.text = Loc.t(item.desc) if can_use else Loc.t("%s (Tidak bisa dipakai sekarang.)") % Loc.t(item.desc)
	_use.disabled = not can_use
	_drop.disabled = false
