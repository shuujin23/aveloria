extends Control
## Layar judul: Lanjutkan (kalau ada simpanan), Permainan Baru, pilihan bahasa, Keluar.
## Simpanan ada di beberapa slot (Game.SAVE_SLOTS); daftar slot muncul saat perlu memilih.

const SPRITES := "res://assets/sprites/"
const HEROES := ["selene", "arlen", "mira", "kael"]

var _continue: Button
var _new_game: Button
var _menu: VBoxContainer
var _slot_box: VBoxContainer
var _confirm_slot := -1  # slot berisi yang sedang menunggu tekan kedua sebelum ditimpa permainan baru
var _update_button: Button  # muncul di pojok kanan atas kalau ada versi lebih baru


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var backdrop := TextureRect.new()
	backdrop.texture = load(SPRITES + "bg_lembah.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var title := Label.new()
	title.text = "AVELORIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_right = 1.0
	title.offset_top = 70
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color("ffd866"))
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_outline_color", Color("10141c"))
	add_child(title)

	# Keempat tokoh berdiri di padang.
	for i in HEROES.size():
		var hero := TextureRect.new()
		hero.texture = load(SPRITES + "%s_front_stand.png" % HEROES[i])
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_SCALE
		hero.size = hero.texture.get_size() * 5.0
		hero.position = Vector2(640 - HEROES.size() * 70 + i * 140 + 10, 250)
		add_child(hero)

	var menu := VBoxContainer.new()
	menu.anchor_left = 0.5
	menu.anchor_right = 0.5
	menu.offset_left = -190
	menu.offset_right = 190
	menu.offset_top = 425
	menu.add_theme_constant_override("separation", 8)
	add_child(menu)

	_menu = menu
	_slot_box = VBoxContainer.new()  # daftar slot; menggantikan menu utama selagi memilih slot
	_slot_box.anchor_left = 0.5
	_slot_box.anchor_right = 0.5
	_slot_box.offset_left = -290
	_slot_box.offset_right = 290
	_slot_box.offset_top = 425
	_slot_box.add_theme_constant_override("separation", 8)
	_slot_box.visible = false
	add_child(_slot_box)

	_continue = _add_button(menu, Loc.t("Lanjutkan"), _on_continue)
	_continue.disabled = Game.used_slots().is_empty()
	var summary := Game.save_summary(Game.latest_slot())
	if Game.used_slots().size() > 1:
		_continue.text = Loc.t("Lanjutkan\n%d simpanan") % Game.used_slots().size()
	elif summary != "":
		_continue.text = Loc.t("Lanjutkan\n%s") % summary
	_new_game = _add_button(menu, Loc.t("Permainan Baru"), _on_new_game)
	_add_button(menu, Loc.label(), func() -> void:  # ganti bahasa lalu susun ulang layar ini
		Loc.toggle()
		get_tree().reload_current_scene())
	_add_button(menu, Loc.t("Keluar"), func() -> void: get_tree().quit())
	(_new_game if _continue.disabled else _continue).grab_focus()

	var credit := Label.new()
	credit.text = Loc.t("Musik: AVGVSTA (CC-BY 4.0)   -   Efek suara: Kenney, artisticdude, rubberduck (CC0)   -   opengameart.org")
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.anchor_top = 1.0
	credit.anchor_right = 1.0
	credit.anchor_bottom = 1.0
	credit.offset_top = -34
	credit.add_theme_font_size_override("font_size", 13)
	credit.add_theme_constant_override("outline_size", 4)
	credit.add_theme_color_override("font_outline_color", Color("10141c"))
	add_child(credit)

	var version := Label.new()
	version.text = "v%s" % UpdateCheck.current_version()
	version.position = Vector2(14, 10)
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_constant_override("outline_size", 4)
	version.add_theme_color_override("font_outline_color", Color("10141c"))
	add_child(version)
	# Hanya game hasil ekspor yang memeriksa versi baru (atau kalau dijalankan dengan "-- --cek-versi").
	if OS.has_feature("template") or OS.get_cmdline_user_args().has("--cek-versi"):
		_check_update()
	Audio.play_music("title")


## Tanya GitHub rilis terbaru. Tanpa internet atau kalau jawabannya aneh, tidak terjadi apa-apa.
func _check_update() -> void:
	var request := HTTPRequest.new()
	request.timeout = UpdateCheck.TIMEOUT
	add_child(request)
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		request.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			_offer_update(UpdateCheck.latest_tag(body.get_string_from_utf8())))
	if request.request(UpdateCheck.API_URL, ["User-Agent: Aveloria", "Accept: application/vnd.github+json"]) != OK:
		request.queue_free()


## Tampilkan tombol unduh kalau `tag` lebih baru daripada versi game ini.
func _offer_update(tag: String) -> void:
	if tag == "" or not UpdateCheck.is_newer(tag, UpdateCheck.current_version()) or _update_button != null:
		return
	_update_button = Button.new()
	_update_button.text = Loc.t("Versi %s tersedia  -  buka halaman unduhan") % tag.trim_prefix("v")
	_update_button.add_theme_font_size_override("font_size", 16)
	_update_button.add_theme_color_override("font_color", Color("ffd866"))
	_update_button.anchor_left = 1.0
	_update_button.anchor_right = 1.0
	_update_button.offset_right = -14
	_update_button.offset_top = 10
	_update_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_update_button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	_update_button.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		OS.shell_open(UpdateCheck.PAGE_URL))
	add_child(_update_button)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	button.pressed.connect(func() -> void: Audio.sfx("ui_ok"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


## Satu simpanan: langsung dimuat. Beberapa simpanan: pemain memilih slotnya.
func _on_continue() -> void:
	var used: Array = Game.used_slots()
	if used.size() > 1:
		_show_slots(false)
	elif used.size() == 1:
		_load_slot(used[0])


func _load_slot(index: int) -> void:
	if Game.load_game(index):
		get_tree().change_scene_to_file(Game.WORLD_SCENE)
	else:
		_hide_slots()
		_continue.text = Loc.t("Simpanan tidak bisa dibaca")
		_continue.disabled = true
		_new_game.grab_focus()


## Belum ada simpanan: langsung mulai di Slot 1. Kalau sudah ada, pemain memilih slot untuk permainan baru.
func _on_new_game() -> void:
	if Game.used_slots().is_empty():
		_start_new(0)
	else:
		_show_slots(true)


func _start_new(index: int) -> void:
	Game.new_game()
	Game.slot = index
	get_tree().change_scene_to_file(Game.WORLD_SCENE)


## Tampilkan daftar slot menggantikan menu utama. for_new = memilih slot untuk permainan baru
## (slot berisi butuh tekan kedua); kalau tidak, memilih simpanan yang dimuat (slot kosong mati).
func _show_slots(for_new: bool) -> void:
	_confirm_slot = -1
	for child in _slot_box.get_children():
		_slot_box.remove_child(child)
		child.queue_free()
	var head := Label.new()
	head.text = Loc.t("Pilih slot untuk permainan baru") if for_new else Loc.t("Pilih simpanan yang dilanjutkan")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_color_override("font_color", Color("ffd866"))
	head.add_theme_constant_override("outline_size", 6)
	head.add_theme_color_override("font_outline_color", Color("10141c"))
	_slot_box.add_child(head)
	var focus: Button = null
	var latest: int = Game.latest_slot()
	for i in Game.SAVE_SLOTS:
		var button := _add_button(_slot_box, Game.slot_label(i), func() -> void: _on_slot(i, for_new))
		if for_new:
			if focus == null and not Game.has_save(i):  # tawarkan slot kosong pertama
				focus = button
		else:
			button.disabled = not Game.has_save(i)
			if i == latest:
				focus = button
	var back := _add_button(_slot_box, Loc.t("Kembali"), _hide_slots)
	_menu.visible = false
	_slot_box.visible = true
	(focus if focus != null else back).grab_focus()


func _hide_slots() -> void:
	_slot_box.visible = false
	_menu.visible = true
	(_new_game if _continue.disabled else _continue).grab_focus()


func _on_slot(index: int, for_new: bool) -> void:
	if not for_new:
		_load_slot(index)
	elif Game.has_save(index) and _confirm_slot != index:
		_confirm_slot = index  # slot berisi: minta tekan sekali lagi
		for i in Game.SAVE_SLOTS:
			(_slot_box.get_child(i + 1) as Button).text = Game.slot_label(i)
		(_slot_box.get_child(index + 1) as Button).text = Loc.t("Slot %d berisi simpanan. Tekan sekali lagi untuk menimpanya") % (index + 1)
	else:
		_start_new(index)
