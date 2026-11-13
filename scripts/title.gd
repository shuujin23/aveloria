extends Control
## Layar judul: Lanjutkan (kalau ada simpanan), Permainan Baru, Keluar.

const SPRITES := "res://assets/sprites/"
const HEROES := ["selene", "arlen", "mira", "kael"]

var _continue: Button
var _new_game: Button
var _confirming := false
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
	menu.offset_top = 450
	menu.add_theme_constant_override("separation", 10)
	add_child(menu)

	_continue = _add_button(menu, "Lanjutkan", _on_continue)
	_continue.disabled = not Game.has_save()
	var summary := Game.save_summary()
	if summary != "":
		_continue.text = "Lanjutkan\n%s" % summary
	_new_game = _add_button(menu, "Permainan Baru", _on_new_game)
	_add_button(menu, "Keluar", func() -> void: get_tree().quit())
	(_new_game if _continue.disabled else _continue).grab_focus()

	var credit := Label.new()
	credit.text = "Musik: AVGVSTA (CC-BY 4.0)   -   Efek suara: Kenney, artisticdude, rubberduck (CC0)   -   opengameart.org"
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
	_update_button.text = "Versi %s tersedia  -  buka halaman unduhan" % tag.trim_prefix("v")
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
	button.custom_minimum_size.y = 44
	button.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	button.pressed.connect(func() -> void: Audio.sfx("ui_ok"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_continue() -> void:
	if Game.load_game():
		get_tree().change_scene_to_file(Game.WORLD_SCENE)
	else:
		_continue.text = "Simpanan tidak bisa dibaca"
		_continue.disabled = true


## Kalau sudah ada simpanan, minta konfirmasi sekali lagi sebelum memulai dari awal.
func _on_new_game() -> void:
	if Game.has_save() and not _confirming:
		_confirming = true
		_new_game.text = "Mulai dari awal? Tekan sekali lagi\n(simpanan lama tertimpa saat menyimpan)"
		return
	Game.new_game()
	get_tree().change_scene_to_file(Game.WORLD_SCENE)
