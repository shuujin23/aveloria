extends PanelContainer
## Layar Status: stat tiap anggota party dan pembagian poin stat yang didapat tiap naik level.
## Pemakainya memanggil open() lalu menanggapi sinyal changed (stat atau emas berubah) dan closed.

signal changed
signal closed

const COLOR_GOLD := Color("c9a85c")
const HINTS := {
	"max_hp": "HP maksimum. Tiap poin +%d.",
	"max_mp": "MP maksimum; pemulihan MP tiap ronde ikut naik. Tiap poin +%d.",
	"atk": "Kekuatan serangan biasa dan jurus fisik. Tiap poin +%d.",
	"defense": "Mengurangi kerusakan fisik yang diterima. Tiap poin +%d.",
	"mag": "Kekuatan sihir dan penyembuhan. Tiap poin +%d.",
	"agi": "Menentukan urutan giliran di pertarungan. Tiap poin +%d.",
}

var _member := 0
var _member_box: HBoxContainer
var _info: Label
var _rows: GridContainer
var _detail: Label
var _respec: Button
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
	column.custom_minimum_size.x = 560
	add_child(column)

	var title := Label.new()
	title.text = Loc.t("Status")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(title)

	_member_box = HBoxContainer.new()
	_member_box.add_theme_constant_override("separation", 6)
	column.add_child(_member_box)

	_info = Label.new()
	_info.add_theme_color_override("font_color", Color("ffd866"))
	column.add_child(_info)

	_rows = GridContainer.new()
	_rows.columns = 3
	_rows.add_theme_constant_override("h_separation", 16)
	_rows.add_theme_constant_override("v_separation", 6)
	column.add_child(_rows)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(540, 46)
	_detail.add_theme_font_size_override("font_size", 15)
	column.add_child(_detail)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	_respec = _button(actions, "", _on_respec)
	_close = _button(actions, Loc.t("Tutup"), func() -> void: closed.emit())


func _button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_cancel")
		closed.emit()


func open() -> void:
	_member = clampi(_member, 0, Game.party.size() - 1)
	# Buka langsung di tokoh pertama yang masih punya poin, kalau ada.
	for i in Game.party.size():
		if (Game.party[i] as Battler).points_left() > 0:
			_member = i
			break
	visible = true
	_rebuild("")


## Susun ulang isi. focus_stat = baris yang disorot; message = teks pengganti petunjuk.
func _rebuild(focus_stat: String, message: String = "") -> void:
	for box: Node in [_member_box, _rows]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	var m: Battler = Game.party[_member]

	for i in Game.party.size():
		var other: Battler = Game.party[i]
		var tab := Button.new()
		tab.text = other.display_name if other.points_left() == 0 else "%s (+%d)" % [other.display_name, other.points_left()]
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _member:
			tab.add_theme_color_override("font_color", Color("ffd866"))
			tab.add_theme_color_override("font_focus_color", Color("ffd866"))
		tab.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
		tab.pressed.connect(func() -> void:
			Audio.sfx("ui_ok")
			_member = i
			_rebuild(""))
		_member_box.add_child(tab)

	_info.text = Loc.t("%s   %s  Lv %d        Poin tersisa: %d") % [m.display_name, Loc.t(m.job), m.level, m.points_left()]
	var first: Button = null
	var wanted: Button = null
	for stat_name: String in Db.STAT_POINT_VALUE:
		var per_point: int = Db.STAT_POINT_VALUE[stat_name]
		var spent := int(m.alloc.get(stat_name, 0))
		var value := Label.new()
		value.text = "%s  %d" % [Db.STAT_LABELS[stat_name], int(m.get(stat_name))]
		value.custom_minimum_size.x = 120
		_rows.add_child(value)
		var bonus := Label.new()
		bonus.text = "" if spent == 0 else Loc.t("+%d dari %d poin") % [spent * per_point, spent]
		bonus.custom_minimum_size.x = 200
		bonus.add_theme_font_size_override("font_size", 14)
		bonus.add_theme_color_override("font_color", Color("8fe08a"))
		_rows.add_child(bonus)
		var plus := Button.new()
		plus.text = "+%d %s" % [per_point, Db.STAT_LABELS[stat_name]]
		plus.custom_minimum_size.x = 110
		plus.disabled = m.points_left() <= 0
		var hint: String = Loc.t(HINTS[stat_name]) % per_point
		var show_hint := func() -> void:
			_detail.text = hint
			Audio.sfx("ui_move")
		plus.focus_entered.connect(show_hint)
		plus.mouse_entered.connect(show_hint)
		plus.pressed.connect(func() -> void:
			if Game.spend_point(m, stat_name):
				Audio.sfx("buff")
				changed.emit()
				_rebuild(stat_name))
		_rows.add_child(plus)
		if first == null and not plus.disabled:
			first = plus
		if stat_name == focus_stat and not plus.disabled:
			wanted = plus

	var block := Game.respec_block(m)
	_respec.text = Loc.t("Atur ulang poin  (%d emas)") % Game.respec_price(m)
	_respec.disabled = block != ""
	_respec.tooltip_text = block
	_detail.text = Loc.t("Tiap naik level, tiap tokoh mendapat %d poin stat. Bagikan sesukamu; stat dasar tetap naik sendiri.") % Db.STAT_POINTS_PER_LEVEL
	if m.points_left() == 0 and block != "":
		_detail.text = block
	if wanted != null:
		wanted.grab_focus()
	elif first != null:
		first.grab_focus()
	else:
		_close.grab_focus()
	if message != "":
		_detail.text = message


func _on_respec() -> void:
	var m: Battler = Game.party[_member]
	if Game.respec(m):
		Audio.sfx("coin")
		changed.emit()
		_rebuild("", Loc.t("Poin %s dikembalikan. Bagikan lagi sesukamu.") % m.display_name)
	else:
		Audio.sfx("ui_cancel")
		_detail.text = Game.respec_block(m)
