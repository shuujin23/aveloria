extends Control
## Layar penutup setelah Raja Monster kalah: ucapan tamat, keempat tokoh, kredit, lalu kembali ke judul.

const SPRITES := "res://assets/sprites/"
const HEROES := ["selene", "arlen", "mira", "kael"]
const CREDITS := [
	"Musik: \"Generic 8-bit JRPG Soundtrack\" oleh AVGVSTA (CC-BY 4.0)",
	"Efek suara: Kenney, artisticdude, rubberduck (CC0)",
	"Semua audio dari opengameart.org; rincian di assets/audio/KREDIT.md",
	"Dibuat dengan Godot Engine",
]


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

	_label("TAMAT", 60, 84, Color("ffd866"), 16)
	_label("Aveloria kembali damai.", 170, 24, Color.WHITE, 6)

	for i in HEROES.size():
		var hero := TextureRect.new()
		hero.texture = load(SPRITES + "%s_front_stand.png" % HEROES[i])
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_SCALE
		hero.size = hero.texture.get_size() * 5.0
		hero.position = Vector2(640 - HEROES.size() * 70 + i * 140 + 10, 235)
		add_child(hero)

	var stats := "Level akhir: %s        Kemenangan: %d" % [
		",  ".join(Game.party.map(func(m: Battler) -> String: return "%s %d" % [m.display_name, m.level])), Game.wins]
	_label(stats, 420, 18, Color.WHITE, 5)
	for i in CREDITS.size():
		_label(CREDITS[i], 470 + i * 26, 15, Color(1, 1, 1, 0.9), 4)

	var button := Button.new()
	button.text = "Kembali ke layar judul"
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.offset_left = -170
	button.offset_right = 170
	button.offset_top = 610
	button.custom_minimum_size.y = 44
	button.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		get_tree().change_scene_to_file(Game.TITLE_SCENE))
	add_child(button)
	button.grab_focus()
	Audio.play_music("ending")


func _label(text: String, top: float, font_size: int, color: Color, outline: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.offset_top = top
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color("10141c"))
	add_child(label)
