extends PanelContainer
## Layar Jurus: skill tree tiap tokoh (tiga cabang) dan susunan jurus yang dibawa ke pertarungan.
## Menekan jurus yang belum terbuka membukanya dengan poin jurus; menekan jurus yang sudah terbuka
## membawa atau melepasnya (paling banyak Db.SKILL_SLOTS). Pemakainya memanggil open() lalu
## menanggapi sinyal changed (emas berubah) dan closed.

signal changed
signal closed

const COLOR_GOLD := Color("c9a85c")
const CARD_SIZE := Vector2(256, 56)

var _member := 0
var _member_box: HBoxContainer
var _info: Label
var _columns: HBoxContainer
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
	add_child(column)

	var title := Label.new()
	title.text = Loc.t("Jurus")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(title)

	_member_box = HBoxContainer.new()
	_member_box.add_theme_constant_override("separation", 6)
	column.add_child(_member_box)

	_info = Label.new()
	_info.add_theme_color_override("font_color", Color("ffd866"))
	column.add_child(_info)

	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 10)
	column.add_child(_columns)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(CARD_SIZE.x * 3 + 20, 66)
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
	for i in Game.party.size():  # buka langsung di tokoh pertama yang masih punya poin jurus
		if (Game.party[i] as Battler).skill_points_left() > 0:
			_member = i
			break
	visible = true
	_rebuild("")


## Susun ulang isi. focus_skill = jurus yang disorot; message = teks pengganti keterangan.
func _rebuild(focus_skill: String, message: String = "") -> void:
	for box: Node in [_member_box, _columns]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	var m: Battler = Game.party[_member]

	for i in Game.party.size():
		var other: Battler = Game.party[i]
		var tab := Button.new()
		tab.text = other.display_name if other.skill_points_left() == 0 else "%s (+%d)" % [other.display_name, other.skill_points_left()]
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

	_info.text = Loc.t("%s   %s  Lv %d        Poin jurus: %d        Dibawa: %d/%d") % [m.display_name, Loc.t(m.job), m.level,
		m.skill_points_left(), m.loadout.size(), Db.SKILL_SLOTS]
	var first: Button = null
	var wanted: Button = null
	for branch: Dictionary in Db.SKILL_TREES[m.id]:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		var head := Label.new()
		head.text = Loc.t(branch.name)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_theme_color_override("font_color", COLOR_GOLD)
		box.add_child(head)
		for skill_id: String in branch.skills:
			var card := _card(m, skill_id)
			box.add_child(card)
			if first == null:
				first = card
			if skill_id == focus_skill:
				wanted = card
		_columns.add_child(box)

	var block := Game.skill_respec_block(m)
	_respec.text = Loc.t("Atur ulang jurus  (%d emas)") % Game.respec_price(m)
	_respec.disabled = block != ""
	_respec.tooltip_text = block
	(wanted if wanted != null else first).grab_focus()
	if message != "":
		_detail.text = message


## Kartu satu jurus: nama dan MP di atas, keadaannya di bawah.
func _card(m: Battler, skill_id: String) -> Button:
	var sk: Dictionary = Db.SKILLS[skill_id]
	var open_now: bool = m.unlocked.has(skill_id)
	var carried: bool = m.loadout.has(skill_id)
	var block := Game.skill_block(m, skill_id)
	var passive: bool = Db.is_passive(skill_id)
	var state := ""
	var color := Color(1, 1, 1, 0.4)
	if passive and open_now:
		state = Loc.t("Pasif: selalu aktif")
		color = Color("8fd8ff")
	elif carried:
		state = Loc.t("Dibawa")
		color = Color("ffd866")
	elif open_now:
		state = Loc.t("Terbuka, tidak dibawa")
		color = Color.WHITE
	elif block == "":
		state = Loc.t("Buka: %d poin") % Db.unlock_cost(m.id, skill_id)
		color = Color("8fe08a")
	else:
		state = Loc.t("Terkunci: %d poin") % Db.unlock_cost(m.id, skill_id)

	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	for look: String in ["normal", "hover", "pressed", "focus"]:
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color("243044") if look == "hover" else Color("1a2332")
		frame.border_color = Color("ffd866") if look == "focus" else (Color("c9a85c") if carried else Color("3a4860"))
		if look == "focus":
			frame.bg_color = Color(0, 0, 0, 0)
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(4)
		card.add_theme_stylebox_override(look, frame)
	_text(card, "%s   %s" % [Loc.t(sk.name), Loc.t("Pasif") if passive else "%d MP" % m.skill_cost(skill_id)], Vector2(10, 6), 16, color if open_now else Color(1, 1, 1, 0.6 if block == "" else 0.4))
	_text(card, state, Vector2(10, 30), 13, color)

	var hint: String = Loc.t(sk.desc)
	if not open_now and block != "":
		hint += "\n" + block
	elif not open_now:
		hint += "\n" + Loc.t("Tekan untuk membuka jurus ini.")
	elif passive:
		hint += "\n" + Loc.t("Jurus pasif selalu aktif dan tidak memakai tempat di susunan.")
	elif carried:
		hint += "\n" + Loc.t("Tekan untuk melepasnya dari susunan.")
	else:
		hint += "\n" + Loc.t("Tekan untuk membawanya ke pertarungan.")
	var show_hint := func() -> void:
		_detail.text = hint
		Audio.sfx("ui_move")
	card.focus_entered.connect(show_hint)
	card.mouse_entered.connect(show_hint)
	card.pressed.connect(func() -> void: _press(m, skill_id))
	return card


func _press(m: Battler, skill_id: String) -> void:
	if not m.unlocked.has(skill_id):
		var block := Game.skill_block(m, skill_id)
		if block != "":
			Audio.sfx("ui_cancel")
			_detail.text = block
			return
		m.unlock(skill_id)
		Audio.sfx("buff")
		changed.emit()
		var note: String = Loc.t("%s membuka %s.") % [m.display_name, Loc.t(Db.SKILLS[skill_id].name)]
		if Db.is_passive(skill_id):
			note += " " + Loc.t("Jurus pasif selalu aktif dan tidak memakai tempat di susunan.")
		elif not m.loadout.has(skill_id):
			note += " " + Loc.t("Susunan sudah penuh; lepas satu jurus kalau ingin membawanya.")
		_rebuild(skill_id, note)
		return
	if Db.is_passive(skill_id):
		Audio.sfx("ui_move")
		_detail.text = Loc.t(Db.SKILLS[skill_id].desc) + "\n" + Loc.t("Jurus pasif selalu aktif dan tidak memakai tempat di susunan.")
		return
	var was_carried: bool = m.loadout.has(skill_id)
	if Game.toggle_loadout(m, skill_id):
		Audio.sfx("ui_ok")
		changed.emit()
		_rebuild(skill_id)
	else:
		Audio.sfx("ui_cancel")
		_detail.text = Loc.t("Minimal satu jurus harus dibawa.") if was_carried else Loc.t("Susunan sudah penuh (%d jurus). Lepas satu dulu.") % Db.SKILL_SLOTS


func _on_respec() -> void:
	var m: Battler = Game.party[_member]
	if Game.respec_skills(m):
		Audio.sfx("coin")
		changed.emit()
		_rebuild("", Loc.t("Poin jurus %s dikembalikan. Buka lagi sesukamu.") % m.display_name)
	else:
		Audio.sfx("ui_cancel")
		_detail.text = Game.skill_respec_block(m)


func _text(parent: Control, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
