extends RefCounted
## Pembuat ikon untuk perlengkapan dan bahan, dipakai layar Perlengkapan, pandai besi, dan hasil pertarungan.

const SPRITES := "res://assets/sprites/"


## Ikon sebuah perlengkapan yang dipakai ({"id", "plus", "trait"}): gambar barang,
## "+N" di pojok kanan bawah, dan ikon sifat di pojok kiri atas.
static func gear(entry: Dictionary, px: float = 48.0) -> Control:
	var root := _picture("gear_%s" % entry.id, px)
	var rarity := Db.gear_rarity(entry)
	if rarity != "common":  # garis bawah berwarna rarity, seperti pada ikon bahan
		var bar := ColorRect.new()
		bar.color = Color(String(Db.GEAR_RARITIES[rarity].color))
		bar.size = Vector2(px, 3)
		bar.position = Vector2(0, px - 1)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
	var plus := int(entry.get("plus", 0))
	if plus > 0:
		root.add_child(_corner_text("+%d" % plus, px, Color("ffd866")))
	var status_id: String = entry.get("trait", "")
	if status_id != "":
		var badge := TextureRect.new()
		badge.texture = load(SPRITES + "status_%s.png" % status_id)
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_SCALE
		badge.size = Vector2(24, 24)
		badge.position = Vector2(-6, -6)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(badge)
	return root


## Ikon sebuah bahan dengan jumlahnya (count < 0 = tanpa angka). Bingkai bawahnya berwarna kategori.
static func material(mat_id: String, count: int = -1, px: float = 48.0) -> Control:
	var root := _picture("mat_%s" % mat_id, px)
	var bar := ColorRect.new()
	bar.color = Color(String(Db.RARITIES[Db.MATERIALS[mat_id].rarity].color))
	bar.size = Vector2(px, 3)
	bar.position = Vector2(0, px - 1)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	if count >= 0:
		root.add_child(_corner_text("x%d" % count, px, Color.WHITE))
	return root


static func _picture(sprite_name: String, px: float) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(px, px)
	root.size = Vector2(px, px)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = load(SPRITES + sprite_name + ".png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = Vector2(px, px)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)
	return root


static func _corner_text(text: String, px: float, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color("10141c"))
	label.size = Vector2(px + 6, 18)
	label.position = Vector2(0, px - 15)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
