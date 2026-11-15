extends PanelContainer
## Jurnal: tujuan utama cerita (dari Story.main_objective) di atas, lalu side quest yang sedang berjalan
## dan yang sudah selesai, beserta petunjuknya.
## Pemakainya memanggil open() dan menanggapi sinyal closed.

signal closed

const COLOR_GOLD := Color("c9a85c")

var _list: VBoxContainer
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
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size.x = 640
	add_child(column)

	var title := Label.new()
	title.text = Loc.t("Jurnal")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	column.add_child(_list)

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
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	# Tujuan utama cerita selalu tampil paling atas, juga sebelum ada side quest.
	var objective := Story.main_objective(Game.flags)
	var main_head := Label.new()
	main_head.text = Loc.t("Tujuan Utama")
	main_head.add_theme_color_override("font_color", COLOR_GOLD)
	_list.add_child(main_head)
	var main_goal := Label.new()
	main_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_goal.custom_minimum_size.x = 620
	main_goal.add_theme_color_override("font_color", Color("ffd866"))
	main_goal.text = Loc.t(objective.goal)
	_list.add_child(main_goal)
	var main_recap := Label.new()
	main_recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_recap.custom_minimum_size.x = 620
	main_recap.add_theme_font_size_override("font_size", 15)
	main_recap.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	main_recap.text = Loc.t("Terakhir: %s") % Loc.t(objective.recap)
	_list.add_child(main_recap)
	_list.add_child(HSeparator.new())
	var side_head := Label.new()
	side_head.text = Loc.t("Side Quest")
	side_head.add_theme_color_override("font_color", COLOR_GOLD)
	_list.add_child(side_head)

	var entries := Quests.journal(Game.flags)
	for entry: Dictionary in entries:
		var q: Dictionary = Quests.LIST[entry.id]
		var done: bool = entry.state == "done"
		var head := Label.new()
		head.text = "%s%s   -   %s" % [Loc.t(q.name), Loc.t("  (sulit)") if q.get("hard", false) else "", Loc.t(Quests.STATE_LABELS[entry.state])]
		head.add_theme_color_override("font_color", Color(1, 1, 1, 0.5) if done else Color("ffd866"))
		_list.add_child(head)
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = 620
		body.add_theme_font_size_override("font_size", 15)
		body.add_theme_color_override("font_color", Color(1, 1, 1, 0.5 if done else 0.85))
		var hint: String = Loc.t(q.goal) if entry.state == "active" else (Loc.t(q.back) if entry.state == "won" else "")
		var prize := Quests.prize_text(entry.id)
		body.text = prize if hint == "" else "%s\n%s" % [hint, prize]
		_list.add_child(body)
	if entries.is_empty():
		var empty := Label.new()
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 620
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		empty.text = Loc.t("Belum ada side quest. Bicaralah dengan penduduk di tiap permukiman.")
		_list.add_child(empty)
	var offers := Quests.open_offers(Game.flags)
	if offers > 0:
		var more := Label.new()
		more.add_theme_font_size_override("font_size", 14)
		more.add_theme_color_override("font_color", Color("8fe08a"))
		more.text = Loc.t("Ada %d quest yang belum diambil di permukiman yang sudah kalian kunjungi.") % offers
		_list.add_child(more)
	visible = true
	_close.grab_focus()
