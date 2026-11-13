extends SceneTree
## Pembuat sprite pixel art Aveloria. Semua gambar di assets/sprites/ dihasilkan skrip ini.
##   Godot_console.exe --headless --path . -s res://tools/gen_sprites.gd [-- C:/folder/pratinjau.png]
## Setelah itu jalankan "--import" supaya Godot mengenali PNG baru.
##
## Sprite digambar pada resolusi 1x (petak 32x16) dan ditampilkan 2x di game.
## Cahaya datang dari kiri-atas: sisi kiri terang, sisi kanan gelap.

const OUT := "res://assets/sprites/"
const CLEAR := Color(0, 0, 0, 0)

var rng := RandomNumberGenerator.new()
var _made := {}  # nama -> Image, untuk lembar pratinjau


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_ground("grass", "5a9e4f", "6db35c", "4a8a44", 3, "grass")
	_ground("forest_floor", "4a8546", "5a9a52", "3c7340", 2, "grass")
	_ground("mist_grass", "4c8a80", "5f9e92", "3f766e", 3, "grass")
	_ground("mist_floor", "3d7069", "4b8279", "315d59", 2, "grass")
	_ground("path", "c2a471", "d4b986", "a98c5c", 3, "path")
	_ground("water", "3a6fb5", "6b9ddb", "2f5e9e", 3, "water")
	_ground("rock", "6b6558", "7c7566", "59544a", 2, "path")
	# Pegunungan Abu
	_ground("ash", "8a8478", "9c968a", "767064", 3, "path")
	_ground("cinder", "5c5650", "6e6860", "4a4540", 2, "path")
	_ground("lava", "e0622a", "ffb040", "b03a1c", 3, "water")
	_dead_tree("dead_tree_0", false)
	_dead_tree("dead_tree_1", true)
	# Kastil Kelam
	_ground("floor", "5a5866", "68667a", "4a4856", 3, "path")
	_ground("floor_dark", "44424e", "525060", "36343e", 2, "path")
	_ground("carpet", "8a2a34", "a03a44", "6e1e28", 2, "path")
	_wall_block()
	_throne()
	_altar()
	_chest("chest_closed", false)
	_chest("chest_open", true)

	var green := ["8fd06a", "5fae4e", "3d8a40", "2a6a38", "1c4a2e"]
	var teal := ["7cc4b0", "4e9c8c", "33766e", "235a58", "173f42"]
	_tree("tree_round", green, false)
	_tree("tree_pine", green, true)
	_tree("mist_round", teal, false)
	_tree("mist_pine", teal, true)

	_edges("grass", "5a9e4f", "6db35c", "4a8a44")
	_edges("forest_floor", "4a8546", "5a9a52", "3c7340")
	_edges("mist_grass", "4c8a80", "5f9e92", "3f766e")
	_edges("mist_floor", "3d7069", "4b8279", "315d59")
	_edges("path", "c2a471", "d4b986", "a98c5c")
	_edges("rock", "6b6558", "7c7566", "59544a")
	_edges("ash", "8a8478", "9c968a", "767064")
	_edges("cinder", "5c5650", "6e6860", "4a4540")

	_mountain("mountain_0", Vector2(16, 3), true)
	_mountain("mountain_1", Vector2(12, 8), true)
	_mountain("mountain_2", Vector2(20, 6), true)
	_mountain("hill_0", Vector2(15, 17), false)
	_mountain("hill_1", Vector2(19, 20), false)

	_house("house", ["cf5a44", "a9432f", "a23f33", "7e2e26"])
	_house("inn", ["4f7fc8", "3a62a0", "3a5f9a", "2a4878"])
	_lair("lair_occupied", true)
	_lair("lair_empty", false)
	_gate("gate_closed", true)
	_gate("gate_open", false)
	# Tiap tokoh: warna badan dasar + kostum dan senjata sesuai perannya (digambar di _dress_*).
	_hero("arlen", {}, _dress_arlen)
	_hero("selene", {"h": "d8d0e8", "H": "a8a0c0", "b": "6a3fa0", "B": "4a2a78", "c": "4a2a78", "C": "3a2060", "p": "4a2a78", "t": "2a1c44"}, _dress_selene)
	_hero("mira", {"h": "f0d070", "H": "c8a040", "b": "f0f0f8", "B": "c8ccdc", "c": "7fb7e0", "C": "5a94c4", "p": "f0f0f8", "t": "8a7a5a"}, _dress_mira)
	_hero("kael", {"h": "3a2c28", "H": "241a18", "b": "86603a", "B": "6b4a2a", "c": "4a8a44", "C": "346a34", "p": "5a4a3a"}, _dress_kael)

	# Warga desa.
	_hero("npc_tetua", {"h": "e8e8ee", "H": "b8b8c4", "b": "7a5a3a", "B": "5f4326", "c": "5f4326", "C": "4d3320", "p": "7a5a3a"}, _dress_tetua)
	_hero("npc_sari", {"h": "6a4028", "H": "4a2a18", "b": "4a8a6a", "B": "346a50", "c": "f0f0f8", "C": "c8ccdc", "p": "4a8a6a"}, _dress_sari)
	_hero("npc_dimas", {"h": "3a2c28", "H": "241a18", "b": "e0b040", "B": "b88a28", "c": "e0b040", "C": "b88a28", "p": "5a6a9a"}, _dress_dimas)
	_hero("npc_joko", {"h": "3a2c28", "H": "241a18", "b": "3a8a8a", "B": "2a6a6a", "c": "e0b040", "C": "b88a28", "p": "6a5644"}, _dress_joko)
	# Warga Pos Pemburu.
	_hero("npc_darma", {"h": "8a8a8a", "H": "6a6a6a", "b": "6a5a4a", "B": "4e4236", "c": "7a5a3a", "C": "5f4326", "p": "4a4038"}, _dress_darma)
	_hero("npc_ningsih", {"h": "3a2c28", "H": "241a18", "b": "9a4a3a", "B": "7a342a", "c": "e8e0d0", "C": "c8c0b0", "p": "9a4a3a"}, _dress_ningsih)
	_hero("npc_sabar", {"h": "5a4030", "H": "3a2818", "b": "5a7a5a", "B": "425c42", "c": "d8b860", "C": "b09040", "p": "5a4a3a"}, _dress_sabar)
	# Warga Dusun Embun.
	_hero("npc_laras", {"h": "d8d8e0", "H": "a8a8b8", "b": "3a7a78", "B": "2a5a5c", "c": "2a5a5c", "C": "1c4448", "p": "3a7a78"}, _dress_laras)
	_hero("npc_wiryo", {"h": "5a4030", "H": "3a2818", "b": "8a6a4a", "B": "6a4e34", "c": "c8ccdc", "C": "a0a4b4", "p": "4a4a5a"}, _dress_wiryo)
	_hero("npc_rumi", {"h": "3a2c28", "H": "241a18", "b": "8a4a8a", "B": "6a346a", "c": "e0b040", "C": "b88a28", "p": "8a4a8a"}, _dress_rumi)

	# Ikon barang (16x16) untuk tampilan tas.
	_icon_bottle("icon_ramuan", ["ff8a8a", "e04848", "b82e3a", "8a1e2e"], 4.0, false)
	_icon_bottle("icon_ramuan_besar", ["ff8a8a", "e04848", "b82e3a", "8a1e2e"], 5.6, true)
	_icon_bottle("icon_penawar", ["b8f08a", "6cc04e", "469a3c", "2e742e"], 4.0, false)
	_icon_bottle("icon_eter", ["9ad0ff", "4a8ae0", "3466b8", "244a8a"], 4.0, false)
	_icon_drop("icon_air_kehidupan")
	_icon_bottle("icon_ramuan_kekuatan", ["ffd08a", "ff9a3a", "d8702a", "a84e1c"], 4.0, true)
	_icon_bottle("icon_ramuan_pelindung", ["d8b8ff", "a070e0", "7a4ab8", "56308a"], 4.0, true)
	_icon_bottle("icon_ramuan_angin", ["c8fff0", "5fd0c0", "3aa69a", "277a72"], 4.0, true)
	_icon_bag("icon_tas")
	_gear_icons()
	_material_icons()
	# Pandai besi di tiap permukiman.
	_hero("npc_gatot", {"h": "3a2c28", "H": "241a18", "b": "9a4a3a", "B": "7a342a", "c": "d8b890", "C": "b09068", "p": "4a4038"}, _dress_pandai)
	_hero("npc_sena", {"h": "d8d8e0", "H": "a8a8b8", "b": "3a6a8a", "B": "2a4e6a", "c": "d8b890", "C": "b09068", "p": "3a4a5a"}, _dress_pandai)
	_hero("npc_rekso", {"h": "5a4030", "H": "3a2818", "b": "5a5a5a", "B": "424242", "c": "d8b890", "C": "b09068", "p": "4a3a2a"}, _dress_pandai)
	_monster_lendir_emas()
	_monster_mata_kabut()
	_monster_kura_magma()
	_monster_peti_terkutuk()
	_status_icons()
	_logo()

	_monster_jamur()
	_monster_kelelawar()
	_monster_serigala()
	_monster_goblin()
	_monster_ogre()
	# Hutan Kabut
	_spider("monster_laba_laba", 1.0, ["8a7ab8", "5e4e8c", "44386a", "2c2448"], false)
	_spider("monster_ratu", 1.75, ["a05a9a", "7a3a78", "5a2a5c", "3a1a40"], true)
	_wisp("monster_roh_kabut", ["f0ffff", "b0ecf8", "6cc0e8", "4a8ad0"], ["ffffff", "f0ffff", "d0f4fc", "b0ecf8"], "244a8a", "244a8a")
	# Pegunungan Abu
	_monster_kadal_bara()
	_bird("monster_elang_abu", ["e0dcd4", "b0aaa0", "807a72", "565048"], ["5e5850", "c8c2b8", "948e84"], "ffe14a")
	_golem("monster_golem_batu", 1.0, ["a8a296", "847e72", "625c52", "443f38"], "2c2824", "7fe0f0")
	_golem("monster_lahar", 1.7, ["8a6258", "5e4038", "44302a", "2c1e1a"], "ff8a2a", "ffd23a")
	# Kastil Kelam
	_golem("monster_ksatria_kelam", 1.0, ["8a8aa8", "5e5e7c", "42425c", "2a2a40"], "c8503f", "ff4a3a", 0, false, true)
	_wisp("monster_bayangan", ["b08ae0", "7a4ab8", "56308a", "341c5c"], ["e8d8ff", "c8a8f0", "a880e0", "8a5ac8"], "ffe14a", "1c1030")
	_bird("monster_gargoyle", ["9a94a8", "726c84", "524c62", "363246"], ["363246", "8a84a0", "625c78"], "ff4a3a")
	_golem("monster_raja", 1.6, ["7a5a9a", "523a72", "3a2854", "241a38"], "ff4a5a", "ffe14a", 9, true, true)

	_backdrop("bg_lembah", ["6fb4e8", "a8d8f0"], "7fb08a", "5a9e58", ["5a9e4f", "6db35c", "4a8a44"], "")
	_backdrop("bg_hutan", ["4f8fb8", "86bcc8"], "3f7a50", "2f6a40", ["4a8546", "5a9a52", "3c7340"], "trees")
	_backdrop("bg_kabut", ["7fa8a8", "b8d0c8"], "6a9c94", "4a8078", ["4c8a80", "5f9e92", "3f766e"], "trees")
	_backdrop("bg_gua", ["2a2420", "3a322c"], "332b26", "40362f", ["4a4038", "5a4e44", "3a322c"], "cave")

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_preview(args[0])
	print("Sprite dibuat: %d" % _made.size())
	quit()


# ---------------------------------------------------------------- alat bantu

func _new(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	return img


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _save(img: Image, sprite_name: String) -> void:
	img.save_png(OUT + sprite_name + ".png")
	_made[sprite_name] = img


## Angka acak 0..1 yang tetap untuk koordinat yang sama.
func _n(x: int, y: int, salt: int = 0) -> float:
	return float(posmod(hash(Vector3i(x, y, salt)), 1000)) / 1000.0


func _fill_poly(img: Image, pts: Array, fn: Callable) -> void:
	var poly := PackedVector2Array(pts)
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				_px(img, x, y, fn.call(x, y))


## Garis tepi 1 piksel di luar bentuk.
func _outline(img: Image, c: Color) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var nx := x + d.x
				var ny := y + d.y
				if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height() and src.get_pixel(nx, ny).a > 0.0:
					img.set_pixel(x, y, c)
					break


## Bayangan lonjong di tanah; hanya mengisi piksel yang masih kosong.
func _shadow(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.28))


func _in_diamond(x: int, y: int) -> bool:
	var half := 2 * (y + 1) if y < 8 else 2 * (16 - y)
	return x >= 16 - half and x < 16 + half


# ---------------------------------------------------------------- petak tanah (32x16)

func _ground(sprite_name: String, base_hex: String, light_hex: String, dark_hex: String, variants: int, style: String) -> void:
	var base := Color(base_hex)
	var light := Color(light_hex)
	var dark := Color(dark_hex)
	for v in variants:
		rng.seed = hash(sprite_name) + v * 977
		var img := _new(32, 16)
		var speck := 0.03 if style == "water" else 0.09
		for y in 16:
			for x in 32:
				if not _in_diamond(x, y):
					continue
				var r := rng.randf()
				var c := base
				if r < speck:
					c = light
				elif r < speck * 2.0:
					c = dark
				img.set_pixel(x, y, c)
		for i in 4:
			var x := rng.randi_range(8, 22)
			var y := rng.randi_range(4, 11)
			match style:
				"grass":  # rumpun rumput kecil
					_dot(img, x, y, dark)
					_dot(img, x + 2, y, dark)
					_dot(img, x + 1, y - 1, light)
				"water":  # riak
					var length := rng.randi_range(3, 5)
					for k in length:
						_dot(img, x + k, y, light)
						_dot(img, x + k + 1, y + 1, dark)
				"path":  # kerikil
					_dot(img, x, y, dark)
					_dot(img, x + 1, y, dark)
					_dot(img, x, y - 1, light)
		_save(img, "%s_%d" % [sprite_name, v])


## Petak peralihan: bahan ini "merambat" sedikit ke petak tetangga di sepanjang satu sisi,
## dengan tepi tidak rata, supaya batas antar jenis tanah tidak bergerigi lurus.
## Sisi: ne = tetangga y-1, se = x+1, sw = y+1, nw = x-1.
func _edges(mat: String, base_hex: String, light_hex: String, dark_hex: String) -> void:
	var base := Color(base_hex)
	var light := Color(light_hex)
	var dark := Color(dark_hex)
	var sides := ["ne", "se", "sw", "nw"]
	for side in 4:
		for v in 2:
			rng.seed = hash(mat) + side * 31 + v * 977
			var img := _new(32, 16)
			for y in 16:
				for x in 32:
					if not _in_diamond(x, y):
						continue
					# Koordinat dalam petak: a searah sumbu x peta, b searah sumbu y peta (0..1).
					var dx := x + 0.5 - 16.0
					var dy := y + 0.5 - 8.0
					var a := (dx / 16.0 + dy / 8.0 + 1.0) * 0.5
					var b := (dy / 8.0 + 1.0 - dx / 16.0) * 0.5
					var dist := b
					var along := a
					match side:
						1:
							dist = 1.0 - a
							along = b
						2:
							dist = 1.0 - b
						3:
							dist = a
							along = b
					var limit := 0.19 + (_n(int(along * 9.0), v, hash(mat) + side) - 0.5) * 0.18
					if dist > limit:
						continue
					var r := rng.randf()
					var c := base
					if dist > limit - 0.07:
						c = dark
					elif r < 0.09:
						c = light
					img.set_pixel(x, y, c)
			_save(img, "edge_%s_%s_%d" % [mat, sides[side], v])


func _dot(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < 32 and y >= 0 and y < 16 and _in_diamond(x, y):
		img.set_pixel(x, y, c)


# ---------------------------------------------------------------- pohon (28x36, jangkar 14,32)

func _tree(sprite_name: String, pal_hex: Array, pine: bool) -> void:
	var pal: Array = []
	for h: String in pal_hex:
		pal.append(Color(h))
	var img := _new(28, 36)
	var trunk := [Color("86603a"), Color("6b4a2a"), Color("6b4a2a"), Color("4d3320")]
	for y in range(20, 33):
		for x in range(12, 16):
			_px(img, x, y, trunk[x - 12])

	var salt := hash(sprite_name)
	for y in 30:
		for x in 28:
			var t := -99.0
			if pine:
				for tier in 3:
					var apex := 2.0 + tier * 7.0
					var base := apex + 12.0
					var half := 6.0 + tier * 2.5
					if y >= apex and y <= base and abs(x + 0.5 - 14.0) <= (y - apex + 1.0) / 13.0 * half:
						t = (x - 14.0) / 9.0 + (0.45 if y > base - 2.0 else 0.0)
			else:
				for c: Vector3 in [Vector3(14, 13, 10), Vector3(7, 17, 6), Vector3(21, 17, 6), Vector3(14, 7, 6)]:
					if Vector2(x + 0.5 - c.x, y + 0.5 - c.y).length() <= c.z:
						t = ((x - 14.0) * 0.5 + (y - 13.0) * 0.85) / 11.0
			if t < -50.0:
				continue
			t += (_n(x / 2, y / 2, salt) - 0.5) * 0.5
			var shade := 3
			if t < -0.45:
				shade = 0
			elif t < 0.0:
				shade = 1
			elif t < 0.45:
				shade = 2
			_px(img, x, y, pal[shade])
	_outline(img, pal[4])
	_shadow(img, 14, 32, 10, 4)
	_save(img, sprite_name)


# ---------------------------------------------------------------- gunung (32x40, jangkar 16,31)

func _mountain(sprite_name: String, peak: Vector2, snow: bool) -> void:
	var img := _new(32, 40)
	var left := Vector2(1, 31)
	var right := Vector2(31, 31)
	var bottom := Vector2(16, 38)
	var salt := hash(sprite_name)
	var snow_line := peak.y + 11.0
	var jag := [0, 2, 1, 3, 0, 2, -1, 1]

	var face := func(x: int, y: int, lit: bool) -> Color:
		if snow and y < snow_line + jag[x % 8]:
			return Color("f4f6fa") if lit else Color("c5ccda")
		var c := Color("9a9282") if lit else Color("6e675a")
		var r := _n(x, y, salt)
		if _n(0, y / 3, salt) < 0.3 and r < 0.7:  # lapisan batuan
			c = c.darkened(0.12)
		elif r < 0.08:
			c = c.darkened(0.2)
		elif r > 0.94:
			c = c.lightened(0.15)
		return c

	_fill_poly(img, [peak, left, bottom], func(x: int, y: int) -> Color: return face.call(x, y, true))
	_fill_poly(img, [peak, bottom, right], func(x: int, y: int) -> Color: return face.call(x, y, false))
	_outline(img, Color("3a352f"))
	_save(img, sprite_name)


# ---------------------------------------------------------------- rumah desa (40x48, jangkar 20,38)

func _house(sprite_name: String, roof: Array) -> void:
	var img := _new(40, 48)
	var beam := Color("6b4a2a")
	var beam_dark := Color("543a22")

	_fill_poly(img, [Vector2(6, 38), Vector2(20, 45), Vector2(20, 31), Vector2(6, 24)], func(x: int, y: int) -> Color:
		var u := (20.0 - x) / 14.0
		var v := (45.0 - (20.0 - x) * 0.5) - y
		if u < 0.08 or u > 0.9 or v > 12.0 or v < 1.0:
			return beam
		if u > 0.3 and u < 0.72 and v > 4.0 and v < 10.5:  # jendela
			if u < 0.38 or u > 0.64 or v > 9.5 or v < 5.0:
				return beam
			return Color("9fd0f0") if v > 7.5 else Color("5a94c4")
		return Color("e8dcc0") if _n(x, y, 1) > 0.08 else Color("d8cbac"))

	_fill_poly(img, [Vector2(20, 45), Vector2(34, 38), Vector2(34, 24), Vector2(20, 31)], func(x: int, y: int) -> Color:
		var u := (x - 20.0) / 14.0
		var v := (45.0 - (x - 20.0) * 0.5) - y
		if u < 0.08 or u > 0.9 or v > 12.0 or v < 1.0:
			return beam_dark
		if u > 0.3 and u < 0.7 and v < 9.5:  # pintu
			if u < 0.37 or u > 0.63 or v > 8.5:
				return beam_dark
			return Color("d9a441") if (u > 0.55 and v > 3.5 and v < 5.0) else Color("8a5c34")
		return Color("c9ba98") if _n(x, y, 2) > 0.08 else Color("b8a985"))

	_fill_poly(img, [Vector2(4, 25), Vector2(20, 34), Vector2(20, 6)], func(x: int, y: int) -> Color:
		return Color(String(roof[1])) if posmod(int(y - x * 0.5), 4) == 0 else Color(String(roof[0])))
	_fill_poly(img, [Vector2(20, 34), Vector2(36, 25), Vector2(20, 6)], func(x: int, y: int) -> Color:
		return Color(String(roof[3])) if posmod(int(y + x * 0.5), 4) == 0 else Color(String(roof[2])))

	for y in range(9, 19):  # cerobong
		for x in range(25, 29):
			var brick := Color("8f8a84") if x < 27 else Color("6f6a66")
			_px(img, x, y, Color("4a4644") if y == 9 else brick)

	_outline(img, Color("3a2a26"))
	_shadow(img, 20, 40, 18, 7)
	_save(img, sprite_name)


# ---------------------------------------------------------------- sarang semi-bos (36x42, jangkar 18,30)

func _lair(sprite_name: String, occupied: bool) -> void:
	var img := _new(36, 42)
	_fill_poly(img, [Vector2(2, 30), Vector2(5, 17), Vector2(13, 6), Vector2(24, 8), Vector2(32, 18), Vector2(34, 30), Vector2(18, 39)],
		func(x: int, y: int) -> Color:
			var c := Color("6a5f54") if x < 18 else Color("4a4139")
			var r := _n(x, y, 7)
			if r < 0.1:
				c = c.darkened(0.2)
			elif r > 0.93:
				c = c.lightened(0.15)
			return c)
	for y in range(15, 35):  # mulut gua
		for x in range(9, 28):
			var d := Vector2((x + 0.5 - 18.0) / 7.5, (y + 0.5 - 26.0) / 10.0).length()
			if d <= 1.0 and y <= 33:
				_px(img, x, y, Color("0d0908") if d < 0.8 else Color("241b17"))
	if occupied:
		for p: Vector2i in [Vector2i(14, 24), Vector2i(15, 24), Vector2i(20, 24), Vector2i(21, 24)]:
			_px(img, p.x, p.y, Color("ff4a3a"))
		_px(img, 14, 25, Color("a02018"))
		_px(img, 21, 25, Color("a02018"))
	_outline(img, Color("1f1815"))
	_save(img, sprite_name)


# ---------------------------------------------------------------- gerbang (40x40, jangkar 20,30)

func _gate(sprite_name: String, closed: bool) -> void:
	var img := _new(40, 40)
	var a := Vector2i(28, 26)  # tiang belakang
	var b := Vector2i(12, 34)  # tiang depan
	_post(img, a)
	if closed:
		for x in range(b.x + 2, a.x):
			var base_y := int(round(b.y + (a.y - b.y) * float(x - b.x) / float(a.x - b.x)))
			for h in range(2, 16):
				var c := Color("8a5c34") if (x % 4) != 0 else Color("5a3a1e")
				if h == 5 or h == 12:
					c = Color("4a3018")
				_px(img, x, base_y - h, c)
	_post(img, b)
	_outline(img, Color("2a2420"))
	_save(img, sprite_name)


func _post(img: Image, p: Vector2i) -> void:
	for h in 19:
		for dx in range(-1, 3):
			var c := Color("9a9aa2") if dx < 1 else Color("6f6f78")
			if h >= 17:
				c = Color("b8b8c0") if dx < 1 else Color("8a8a92")
			_px(img, p.x + dx, p.y - h, c)


# ---------------------------------------------------------------- Arlen (16x24, jangkar 8,22)

const ARLEN_PALETTE := {
	"k": "2a1f2e", "h": "8a5a30", "H": "5f3a1c", "s": "f0c9a0", "S": "d09f78",
	"b": "3b6fd1", "B": "2a4f9e", "c": "c8503f", "C": "96392d", "g": "d9a441",
	"p": "6a5644", "t": "3a2c28", "w": "d9dde3",
}

const ARLEN_FRONT := [
	"................",
	".....kkkkkk.....",
	"....khhhhhhk....",
	"...khhhhhhhhk...",
	"...khhhhhhhhk...",
	"...khhhhssssk...",
	"...khhhsksskk...",
	"...kHhssssssk...",
	"....kHssssSk....",
	"....kkSSSSkk....",
	"...kcccccccck...",
	"..kbbbccccbbbk..",
	".kbbbbbbbbbbbbk.",
	".ksbbbbbbbbbbsk.",
	".kskbbbbbbbbksk.",
	".kk.kggggggk.kk.",
	"....kbbbbbBk....",
	"....kBBBBBBk....",
	"....kppkkppk....",
]

const ARLEN_BACK := [
	"................",
	".....kkkkkk.....",
	"....khhhhhhk....",
	"...khhhhhhhhk...",
	"...khhhhhhhhk...",
	"...khhhhhhhhk...",
	"...khHhhhhhsk...",
	"...kHHhhhhHsk...",
	"....kHHHHHHk....",
	"....kkHHSSkk....",
	"...kcccccccck...",
	"..kbccccccccbk..",
	".kbbccccccccbbk.",
	".ksbccccccccbsk.",
	".kskccccccccksk.",
	".kk.kcccccCk.kk.",
	"....kCCCCCCk....",
	"....kBBBBBBk....",
	"....kppkkppk....",
]

const ARLEN_LEGS := {
	"stand": [
		"....kppkkppk....",
		"....kppkkppk....",
		"....kttkkttk....",
		"...kkttkkttkk...",
		"....kkk..kkk....",
	],
	"a": [
		"....kppkkppk....",
		"....kppkkppk....",
		"....kttkkttk....",
		"...kkttk.kkk....",
		"....kkk.........",
	],
	"b": [
		"....kppkkppk....",
		"....kppkkppk....",
		"....kttkkttk....",
		"....kkk.kttkk...",
		".........kkk....",
	],
}


## Kanvas tokoh 24x32: badan dasar 16x24 ditaruh di (4,8) supaya ada ruang untuk topi dan senjata.
## Titik kaki (jangkar) = (12, 30). Fungsi _dress_* menggambar kostum dengan koordinat badan (0..15, 0..23).
const HERO_OFFSET := Vector2i(4, 8)


func _hero(hero_id: String, swap: Dictionary, dress: Callable) -> void:
	var palette := ARLEN_PALETTE.duplicate()
	palette.merge(swap, true)
	for view: String in ["front", "back"]:
		var body: Array = ARLEN_FRONT if view == "front" else ARLEN_BACK
		for pose: String in ARLEN_LEGS:
			var rows: Array = body + ARLEN_LEGS[pose]
			var img := _new(24, 32)
			for y in rows.size():
				var row: String = rows[y]
				if row.length() != 16:
					push_error("Baris badan %s/%s #%d panjangnya %d, harus 16" % [view, pose, y, row.length()])
				for x in min(16, row.length()):
					var ch := row[x]
					if palette.has(ch):
						_hp(img, x, y, String(palette[ch]))
			dress.call(img, view == "front", "idle")
			_outline_new(img, Color(String(ARLEN_PALETTE["k"])))
			_save(img, "%s_%s_%s" % [hero_id, view, pose])
	# Pose serangan untuk layar battle (tampak belakang): ancang-ancang lalu ayunan/lepasan.
	for action: String in ["windup", "strike"]:
		var rows: Array = ARLEN_BACK + ARLEN_LEGS["stand"]
		var img := _new(24, 32)
		for y in rows.size():
			var row: String = rows[y]
			for x in min(16, row.length()):
				if palette.has(row[x]):
					_hp(img, x, y, String(palette[row[x]]))
		dress.call(img, false, action)
		_outline_new(img, Color(String(ARLEN_PALETTE["k"])))
		_save(img, "%s_back_%s" % [hero_id, action])


## Piksel dalam koordinat badan.
func _hp(img: Image, x: int, y: int, hex: String) -> void:
	_px(img, x + HERO_OFFSET.x, y + HERO_OFFSET.y, Color(hex))


func _hrect(img: Image, x0: int, y0: int, x1: int, y1: int, hex: String) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_hp(img, x, y, hex)


func _hclear(img: Image, x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(img, x + HERO_OFFSET.x, y + HERO_OFFSET.y, CLEAR)


## Garis tepi hanya di sekitar piksel kostum (badan dasar sudah punya garis tepinya sendiri).
func _outline_new(img: Image, k: Color) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height():
					continue
				var c := src.get_pixel(nx, ny)
				if c.a > 0.0 and not c.is_equal_approx(k):
					img.set_pixel(x, y, k)
					break


## Jubah panjang sampai kaki (penyihir dan pendeta).
func _robe(img: Image, main: String, fold: String, trim: String) -> void:
	_hclear(img, 0, 18, 15, 23)
	for y in range(16, 23):
		var x0 := 4 if y < 18 else (3 if y < 21 else 2)
		for x in range(x0, 16 - x0):
			_hp(img, x, y, trim if y == 22 else (fold if x % 3 == 0 else main))
	_hrect(img, 5, 23, 6, 23, "2a1f2e")
	_hrect(img, 9, 23, 10, 23, "2a1f2e")


## Perisai bundar: baja biru dengan pinggiran emas.
func _shield(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var d := pow((x + 0.5 - cx) / rx, 2.0) + pow((y + 0.5 - cy) / ry, 2.0)
			if d > 1.0:
				continue
			if d > 0.6:
				_hp(img, x, y, "d9a441")
			else:
				_hp(img, x, y, "6a8ac8" if x + 0.5 < cx else "46649c")
	_hp(img, int(cx), int(cy), "f0d070")


## Tetua Bram: jubah cokelat, janggut putih, tongkat jalan.
func _dress_tetua(img: Image, front: bool, _action: String) -> void:
	_robe(img, "7a5a3a", "5f4326", "c8a040")
	if front:
		_hrect(img, 6, 8, 9, 11, "e8e8ee")
		_hrect(img, 7, 12, 8, 12, "b8b8c4")
	_hrect(img, 15, 11, 15, 22, "6b4a2a")
	_hrect(img, 14, 10, 15, 10, "6b4a2a")


## Marla, pemilik penginapan: gaun hijau dengan celemek putih, rambut disanggul.
func _dress_sari(img: Image, front: bool, _action: String) -> void:
	_robe(img, "4a8a6a", "346a50", "f0f0f8")
	_hrect(img, 6, -1, 9, 0, "6a4028")
	if front:
		_hrect(img, 5, 12, 10, 20, "f0f0f8")
		_hrect(img, 5, 12, 5, 20, "c8ccdc")


## Finn, anak desa: topi merah.
func _dress_dimas(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 5, 1, 10, 1, "c8503f")
	_hrect(img, 4, 2, 11, 3, "c8503f")
	if front:
		_hrect(img, 8, 4, 13, 4, "96392d")


## Doran, pedagang: sorban kuning, kumis, tas selempang.
func _dress_joko(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 5, 0, 10, 0, "e0b040")
	_hrect(img, 4, 1, 11, 3, "e0b040")
	_hrect(img, 9, 1, 11, 3, "b88a28")
	if front:
		_hrect(img, 6, 8, 9, 8, "3a2c28")
		for i in 5:
			_hp(img, 5 + i, 11 + i * 3 / 5, "5f4326")
		_hrect(img, 10, 14, 12, 16, "86603a")


## Tetua Aldric, kepala pemburu: topi bulu, jubah kulit, tombak.
func _dress_darma(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 5, 0, 10, 0, "7a5a3a")
	_hrect(img, 4, 1, 11, 3, "7a5a3a")
	_hrect(img, 4, 3, 11, 3, "c8b898")
	if front:
		_hrect(img, 6, 8, 9, 9, "8a8a8a")  # janggut
	_hrect(img, 16, -2, 16, 22, "6b4a2a")  # tombak
	_hrect(img, 16, -5, 16, -3, "c9d1dc")
	_hp(img, 15, -3, "c9d1dc")
	_hp(img, 17, -3, "c9d1dc")


## Brenna, penjaga pondok singgah: gaun merah bata, kerudung putih.
func _dress_ningsih(img: Image, front: bool, _action: String) -> void:
	_robe(img, "9a4a3a", "7a342a", "e8e0d0")
	_hrect(img, 5, 1, 10, 1, "e8e0d0")
	_hrect(img, 4, 2, 11, 3 if front else 9, "e8e0d0")
	_hrect(img, 3, 3, 3, 9, "e8e0d0")
	_hrect(img, 12, 3, 12, 9, "c8c0b0")


## Tobin, pedagang lapak: caping jerami, rompi hijau.
func _dress_sabar(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 6, -1, 9, 0, "d8b860")
	_hrect(img, 4, 1, 11, 1, "d8b860")
	_hrect(img, 2, 2, 13, 3, "d8b860")
	_hrect(img, 9, 2, 13, 3, "b09040")
	if front:
		_hrect(img, 6, 12, 9, 14, "e8e0d0")


## Tetua Elowen, tetua dusun: jubah hijau-biru, rambut putih disanggul, tongkat jalan.
func _dress_laras(img: Image, _front: bool, _action: String) -> void:
	_robe(img, "3a7a78", "2a5a5c", "c8a040")
	_hrect(img, 6, -1, 9, 0, "d8d8e0")
	_hrect(img, 15, 11, 15, 22, "6b4a2a")
	_hrect(img, 14, 10, 15, 10, "6b4a2a")


## Osric, pemilik penginapan dusun: rompi cokelat, celemek, kumis.
func _dress_wiryo(img: Image, front: bool, _action: String) -> void:
	if front:
		_hrect(img, 6, 12, 9, 17, "e8e0d0")
		_hrect(img, 6, 8, 9, 8, "3a2818")


## Nessa, penjaga warung: kerudung kuning, gaun ungu panjang.
func _dress_rumi(img: Image, front: bool, _action: String) -> void:
	_robe(img, "8a4a8a", "6a346a", "e0b040")
	_hrect(img, 5, 1, 10, 1, "e0b040")
	_hrect(img, 4, 2, 11, 3 if front else 9, "e0b040")
	_hrect(img, 3, 3, 3, 9, "e0b040")
	_hrect(img, 12, 3, 12, 9, "b88a28")


## Arlen, Ksatria: zirah baja, jubah merah, pedang di tangan, perisai.
## action: "idle" pedang tegak, "windup" pedang terangkat tinggi, "strike" pedang terayun ke depan.
func _dress_arlen(img: Image, front: bool, action: String) -> void:
	_hrect(img, 2, 11, 4, 11, "c9d1dc")  # pelindung bahu
	_hrect(img, 11, 11, 13, 11, "9aa4b2")
	if front:
		for y in range(11, 15):  # pelat dada
			for x in range(5, 11):
				_hp(img, x, y, "e8ecf2" if (y == 11 and x < 8) else ("c9d1dc" if x < 8 else "9aa4b2"))
		_shield(img, 0.5, 15.0, 3.6, 4.2)
	else:
		_shield(img, 8.0, 13.5, 4.2, 4.6)  # perisai disandang di punggung
	match action:
		"windup":
			_hrect(img, 13, 8, 14, 12, "3b6fd1")  # lengan terangkat
			_hrect(img, 13, 7, 14, 7, "f0c9a0")
			_hrect(img, 14, -6, 14, 4, "e8ecf2")
			_hrect(img, 15, -5, 15, 4, "9aa4b2")
			_hp(img, 14, -7, "e8ecf2")
			_hrect(img, 12, 5, 16, 5, "d9a441")
			_hp(img, 14, 6, "6b4a2a")
		"strike":
			_hrect(img, 14, 12, 15, 13, "3b6fd1")  # lengan terjulur
			_hp(img, 15, 12, "f0c9a0")
			for i in 5:  # bilah miring ke depan
				_hp(img, 16 + i, 11 - i, "e8ecf2")
				_hp(img, 16 + i, 12 - i, "9aa4b2")
			_hp(img, 15, 10, "d9a441")
			_hp(img, 17, 13, "d9a441")
		_:
			_hrect(img, 15, 2, 15, 12, "e8ecf2")  # bilah pedang
			_hrect(img, 16, 3, 16, 12, "9aa4b2")
			_hp(img, 15, 1, "e8ecf2")
			_hrect(img, 14, 13, 17, 13, "d9a441")
			_hrect(img, 15, 14, 15, 15, "6b4a2a")
			_hp(img, 15, 16, "d9a441")


## Tongkat tegak dengan hiasan kepala di (17, top). Dipakai penyihir dan pendeta.
## "windup": tongkat terangkat dan kepala tongkat bersinar; "strike": tongkat dicondongkan ke depan.
func _staff(img: Image, action: String, sleeve: String, wood: String, head: Callable) -> void:
	match action:
		"windup":
			_hrect(img, 14, 9, 16, 9, sleeve)
			_hp(img, 16, 9, "f0c9a0")
			_hrect(img, 17, -1, 17, 17, wood)
			head.call(17, -4, true)
		"strike":
			_hrect(img, 14, 12, 15, 12, sleeve)
			_hp(img, 16, 12, "f0c9a0")
			for y in range(1, 21):
				_hp(img, 15 + (20 - y) / 5, y, wood)
			head.call(19, -1, true)
		_:
			_hrect(img, 14, 13, 16, 13, sleeve)
			_hp(img, 16, 13, "f0c9a0")
			_hrect(img, 17, 2, 17, 22, wood)
			head.call(17, -1, false)


## Selene, Penyihir: topi runcing, jubah ungu panjang, tongkat berbola sihir.
func _dress_selene(img: Image, front: bool, action: String) -> void:
	_robe(img, "6a3fa0", "4a2a78", "b48ae0")
	if front:
		_hrect(img, 3, 8, 3, 10, "d8d0e8")  # rambut perak di sisi wajah
		_hrect(img, 12, 8, 12, 10, "a8a0c0")
	else:
		_hrect(img, 5, 4, 10, 13, "d8d0e8")  # rambut perak panjang di punggung
		_hrect(img, 5, 4, 5, 13, "a8a0c0")
		_hrect(img, 10, 4, 10, 13, "a8a0c0")
		_hrect(img, 6, 14, 9, 14, "a8a0c0")
	_hclear(img, 0, 0, 15, 3)  # topi menggantikan puncak kepala
	_hrect(img, 0, 3, 15, 3, "4a2a78")
	_hrect(img, 1, 2, 14, 2, "6a3fa0")
	var cone := {0: [4, 11], -1: [5, 11], -2: [5, 10], -3: [6, 10], -4: [7, 10], -5: [9, 11], -6: [11, 12]}
	for y: int in cone:
		for x in range(cone[y][0], cone[y][1] + 1):
			_hp(img, x, y, "6a3fa0" if x < 8 else "4a2a78")
	_hrect(img, 4, 1, 11, 1, "d9a441")
	_staff(img, action, "6a3fa0", "86603a", func(x: int, y: int, glow: bool) -> void:
		if glow:  # bola sihir membesar dan bersinar saat merapal
			_hrect(img, x - 2, y - 2, x + 2, y + 2, "bff4ff")
			_hrect(img, x - 1, y - 3, x + 1, y + 3, "bff4ff")
			_hrect(img, x - 3, y - 1, x + 3, y + 1, "bff4ff")
		_hrect(img, x - 1, y - 1, x + 1, y + 1, "7fe0f0")
		_hp(img, x, y - 2, "7fe0f0")
		_hp(img, x - 1, y - 1, "f0ffff")
		_hp(img, x - 1, y + 2, "d9a441")
		_hp(img, x + 1, y + 2, "d9a441"))


## Mira, Pendeta: kerudung putih, jubah putih berselempang biru, tongkat suci berlambang matahari.
func _dress_mira(img: Image, front: bool, action: String) -> void:
	_robe(img, "f0f0f8", "c8ccdc", "5a94c4")
	if front:
		_hrect(img, 7, 11, 8, 21, "5a94c4")  # selempang
		for y: int in [12, 17]:
			_hrect(img, 7, y, 8, y, "f0d070")
		_hrect(img, 5, 1, 10, 1, "f0f0f8")  # kerudung
		_hrect(img, 4, 2, 11, 2, "f0f0f8")
	else:
		_hrect(img, 5, 1, 10, 1, "f0f0f8")
		_hrect(img, 4, 2, 11, 11, "f0f0f8")
		_hrect(img, 10, 2, 11, 11, "c8ccdc")
		_hrect(img, 4, 12, 11, 12, "5a94c4")
	_hrect(img, 4, 3, 11, 3, "7fb7e0")
	_hrect(img, 7, 3, 8, 3, "f0d070")
	_hrect(img, 3, 3, 3, 11, "f0f0f8")
	_hrect(img, 12, 3, 12, 11, "c8ccdc")
	_staff(img, action, "f0f0f8", "c8a040", func(x: int, y: int, glow: bool) -> void:
		var reach := 3 if glow else 2  # sinar matahari memanjang saat berdoa
		for i in range(1, reach + 1):
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				_hp(img, x + d.x * (i + 1), y + 2 + d.y * (i + 1), "fff6c0" if glow else "f0d070")
		_hrect(img, x - 1, y + 1, x + 1, y + 3, "f0d070")
		_hp(img, x, y + 2, "ffffff"))


## Kael, Pemanah: tudung hijau, baju kulit, busur di tangan, tabung panah di punggung.
## "windup": tali busur ditarik dengan anak panah terpasang; "strike": panah sudah lepas.
func _dress_kael(img: Image, front: bool, action: String) -> void:
	var hood_bottom := 3 if front else 9
	_hrect(img, 5, 1, 10, 1, "4a8a44")
	_hrect(img, 4, 2, 11, hood_bottom, "4a8a44")
	_hrect(img, 9, 2, 11, hood_bottom, "346a34")
	_hrect(img, 7, 0, 8, 0, "4a8a44")
	_hrect(img, 3, 3, 3, 9, "4a8a44")
	_hrect(img, 12, 3, 12, 9, "346a34")
	if front:
		for p: Vector2i in [Vector2i(10, 11), Vector2i(9, 11), Vector2i(8, 12), Vector2i(7, 12), Vector2i(6, 13), Vector2i(5, 14)]:
			_hp(img, p.x, p.y, "3a2c28")  # tali tabung panah
		_hrect(img, 1, 6, 2, 9, "6b4a2a")  # tabung panah di balik bahu
		_hrect(img, 1, 4, 2, 4, "c8503f")
		_hrect(img, 1, 5, 2, 5, "f0e6d0")
	else:
		for i in 7:  # tabung panah melintang di punggung
			_hrect(img, 4 + i, 9 + i, 6 + i, 9 + i, "86603a")
			_hp(img, 4 + i, 9 + i, "5f4326")
		_hrect(img, 2, 7, 4, 8, "f0e6d0")
		_hrect(img, 2, 6, 3, 6, "c8503f")
	# Busur di sisi kanan (arah musuh di layar battle).
	var bow := [[15, 5], [16, 6], [17, 7], [17, 8], [18, 9], [18, 10], [18, 11], [18, 12], [18, 13], [18, 14],
		[17, 15], [17, 16], [16, 17], [15, 18]]
	for p: Array in bow:
		_hp(img, p[0], p[1], "a8794a")
	if action == "windup":
		for p: Array in [[15, 6], [15, 7], [14, 8], [14, 9], [13, 10], [13, 11], [13, 12], [13, 13], [14, 14], [14, 15], [15, 16], [15, 17]]:
			_hp(img, p[0], p[1], "e8ecf2")  # tali tertarik
		_hrect(img, 12, 12, 19, 12, "f0e6d0")  # anak panah
		_hp(img, 19, 12, "9aa4b2")
		_hrect(img, 11, 11, 12, 13, "f0c9a0")  # tangan penarik
	else:
		_hrect(img, 15, 6, 15, 17, "e8ecf2")  # tali busur

# ---------------------------------------------------------------- ikon barang (16x16)

## Botol ramuan: gabus, leher kaca, badan bulat berisi cairan. band = cincin emas di leher (ramuan besar).
func _icon_bottle(sprite_name: String, liquid_hex: Array, radius: float, band: bool) -> void:
	var img := _new(16, 16)
	var glass := Color("d4e6f0")
	var cy := 14.0 - radius
	_blob(img, 8.0, cy, radius, radius, _pal(liquid_hex))
	for y in range(0, int(cy - radius * 0.35)):  # bagian atas badan botol masih kosong: kaca
		for x in 16:
			if img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, glass)
	var neck_top := int(cy - radius) - 3
	_rect(img, 7, neck_top, 8, int(cy - radius) + 1, glass)
	_rect(img, 7, neck_top - 1, 8, neck_top, Color("9a6a3a"))
	if band:
		_rect(img, 6, int(cy - radius) + 1, 9, int(cy - radius) + 1, Color("d9a441"))
	_px(img, int(8.0 - radius * 0.5), int(cy), Color.WHITE)
	_outline(img, Color("2a1f2e"))
	_save(img, sprite_name)


# ---------------------------------------------------------------- logo game

## Huruf piksel 5x7 untuk tulisan AVELORIA di layar pembuka.
const LOGO_FONT := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
}


## Lambang Aveloria (32x32): perisai biru berpinggir emas dengan huruf A.
func _emblem() -> Image:
	var img := _new(32, 32)
	_flat(img, [Vector2(4, 3), Vector2(28, 3), Vector2(28, 15), Vector2(25, 23), Vector2(16, 30), Vector2(7, 23), Vector2(4, 15)], Color("e8b84a"))
	_fill_poly(img, [Vector2(6, 5), Vector2(26, 5), Vector2(26, 15), Vector2(23, 22), Vector2(16, 27.5), Vector2(9, 22), Vector2(6, 15)],
		func(x: int, y: int) -> Color:
			var c := Color("4a7ad8") if x < 16 else Color("2f56a8")
			return c.lightened(0.18) if y < 8 else c)
	for x in range(4, 28):  # kilau di pinggir atas
		_px(img, x, 3, Color("ffe9a0"))
	_line(img, Vector2(15, 9), Vector2(10, 22), Color("fff2c0"), 2)  # huruf A
	_line(img, Vector2(16, 9), Vector2(20, 22), Color("fff2c0"), 2)
	_rect(img, 12, 17, 20, 18, Color("fff2c0"))
	_rect(img, 15, 8, 17, 9, Color("fff2c0"))
	_outline(img, Color("1a1420"))
	return img


## Ikon aplikasi (res://icon.png, 256x256) dan gambar layar pembuka (res://assets/logo.png).
## Ikon dipakai untuk jendela, taskbar, dan file .exe; layar pembuka menggantikan logo Godot.
func _logo() -> void:
	var emblem := _emblem()
	var icon := emblem.duplicate() as Image
	icon.resize(256, 256, Image.INTERPOLATE_NEAREST)
	icon.save_png("res://icon.png")

	var splash := _new(64, 50)
	splash.blend_rect(emblem, Rect2i(0, 0, 32, 32), Vector2i(16, 0))
	var text := "AVELORIA"
	for i in text.length():
		var glyph: Array = LOGO_FONT[text[i]]
		for y in 7:
			for x in 5:
				if (glyph[y] as String)[x] == "#":
					_px(splash, 9 + i * 6 + x, 40 + y, Color("1a1420"))  # bayangan
					_px(splash, 8 + i * 6 + x, 39 + y, Color("ffd866"))
	splash.resize(64 * 6, 50 * 6, Image.INTERPOLATE_NEAREST)
	splash.save_png("res://assets/logo.png")
	_made["logo_emblem"] = emblem


# ---------------------------------------------------------------- ikon efek status (12x12, tampil 2x)

## Sembilan ikon efek status. Pola: pedang = ATK, perisai = DEF, sepatu = SPD,
## dengan panah hijau naik (buff) atau merah turun (nerf); api = Terbakar, tetes hijau = Racun,
## perisai emas berpalang = Kebal.
func _status_icons() -> void:
	var sword := func(img: Image) -> void:
		for i in 6:  # bilah miring
			_px(img, 9 - i, 1 + i, Color("e8ecf2"))
			_px(img, 9 - i, 2 + i, Color("9aa4b2"))
		for p: Vector2i in [Vector2i(2, 5), Vector2i(3, 6), Vector2i(4, 7), Vector2i(5, 8)]:
			_px(img, p.x, p.y, Color("d9a441"))
		_px(img, 3, 8, Color("7a5028"))
		_px(img, 2, 9, Color("7a5028"))
		_px(img, 1, 10, Color("d9a441"))
	var shield := func(img: Image, light: String, dark: String) -> void:
		var spans := {1: [3, 8], 2: [2, 9], 3: [2, 9], 4: [2, 9], 5: [2, 9], 6: [3, 8], 7: [3, 8], 8: [4, 7], 9: [5, 6]}
		for y: int in spans:
			for x in range(spans[y][0], spans[y][1] + 1):
				_px(img, x, y, Color(light) if x < 6 else Color(dark))
		_rect(img, 3, 1, 8, 1, Color(light).lightened(0.35))
	var boot := func(img: Image) -> void:
		_rect(img, 3, 1, 5, 6, Color("a8794a"))
		_rect(img, 5, 1, 5, 6, Color("7a5028"))
		_rect(img, 3, 1, 5, 1, Color("d8b890"))
		_rect(img, 3, 7, 8, 8, Color("a8794a"))
		_rect(img, 8, 8, 9, 8, Color("7a5028"))
		_rect(img, 2, 9, 9, 9, Color("4a3018"))

	var icons := {
		"attack_up": [sword, 1], "attack_break": [sword, -1],
		"defense_up": [func(img: Image) -> void: shield.call(img, "6a8ac8", "46649c"), 1],
		"defense_break": [func(img: Image) -> void: shield.call(img, "6a8ac8", "46649c"), -1],
		"speed_up": [boot, 1], "slow": [boot, -1],
		"immunity": [func(img: Image) -> void:
			shield.call(img, "f0d070", "c8a040")
			_rect(img, 5, 3, 6, 7, Color.WHITE)
			_rect(img, 4, 4, 7, 5, Color.WHITE), 0],
		"burn": [func(img: Image) -> void:
			var spans := {1: [5, 5], 2: [5, 6], 3: [4, 6], 4: [3, 7], 5: [2, 8], 6: [2, 8], 7: [2, 8], 8: [3, 7], 9: [4, 6]}
			for y: int in spans:
				for x in range(spans[y][0], spans[y][1] + 1):
					_px(img, x, y, Color("ff8a2a"))
			_rect(img, 4, 6, 6, 8, Color("ffd23a"))
			_px(img, 5, 5, Color("ffd23a"))
			_px(img, 5, 8, Color("fff6c0")), 0],
		"poison": [func(img: Image) -> void:
			var spans := {1: [5, 6], 2: [5, 6], 3: [4, 7], 4: [3, 8], 5: [2, 9], 6: [2, 9], 7: [2, 9], 8: [3, 8], 9: [4, 7]}
			for y: int in spans:
				for x in range(spans[y][0], spans[y][1] + 1):
					_px(img, x, y, Color("7ad05a") if x < 6 else Color("4a9a3c"))
			_px(img, 4, 4, Color("d8ffc0"))
			_px(img, 4, 6, Color("1c4a1c"))  # wajah tengkorak kecil
			_px(img, 7, 6, Color("1c4a1c"))
			_rect(img, 5, 8, 6, 8, Color("1c4a1c")), 0],
	}
	for status_id: String in icons:
		var img := _new(12, 12)
		(icons[status_id][0] as Callable).call(img)
		_outline(img, Color("1a1420"))
		var direction: int = icons[status_id][1]
		if direction != 0:  # panah naik/turun di pojok kanan bawah, dengan garis tepi sendiri
			var arrow := _new(12, 12)
			var color := Color("6fe07a") if direction > 0 else Color("ff6a5a")
			var tip := 6 if direction > 0 else 10
			_px(arrow, 9, tip, color)
			_rect(arrow, 8, tip + direction, 10, tip + direction, color)
			_rect(arrow, 9, min(tip + 2 * direction, tip + 4 * direction), 9, max(tip + 2 * direction, tip + 4 * direction), color)
			_outline(arrow, Color("1a1420"))
			img.blend_rect(arrow, Rect2i(0, 0, 12, 12), Vector2i.ZERO)
		_save(img, "status_%s" % status_id)


## Tas kulit: tombol pintasan tas di peta dan kartu "Perbesar tas" di toko.
func _icon_bag(sprite_name: String) -> void:
	var img := _new(16, 16)
	var leather := _pal(["c08a52", "9a6a3a", "7a5028", "5a3a1c"])
	for x in range(5, 11):  # tali
		_px(img, x, 2, leather[2])
	_px(img, 4, 3, leather[2])
	_px(img, 11, 3, leather[2])
	_px(img, 4, 4, leather[2])
	_px(img, 11, 4, leather[2])
	_blob(img, 8.0, 10.0, 6.0, 5.0, leather)
	_rect(img, 3, 6, 12, 8, leather[1])  # tutup tas
	_rect(img, 3, 9, 12, 9, leather[3])
	_rect(img, 7, 8, 8, 10, Color("d9a441"))  # gesper
	_px(img, 4, 7, leather[0])
	_px(img, 5, 7, leather[0])
	_outline(img, Color("2a1f2e"))
	_save(img, sprite_name)


## Air Kehidupan: tetes air bercahaya dengan kilau.
func _icon_drop(sprite_name: String) -> void:
	var img := _new(16, 16)
	var water := _pal(["f0ffff", "a8e8f8", "6cc0e8", "4a94c8"])
	_blob(img, 8.0, 10.0, 4.5, 4.5, water)
	_fill_poly(img, [Vector2(8, 1), Vector2(12.2, 9), Vector2(3.8, 9)], func(x: int, _y: int) -> Color:
		return water[1] if x < 8 else water[2])
	_px(img, 6, 9, Color.WHITE)
	_px(img, 6, 10, Color.WHITE)
	_outline(img, Color("244a8a"))
	for p: Vector2i in [Vector2i(13, 3), Vector2i(2, 5), Vector2i(13, 13)]:  # kilau
		_px(img, p.x, p.y, Color("fff6c0"))
	_save(img, sprite_name)


# ---------------------------------------------------------------- monster (tampil 4x di layar battle)

func _pal(hexes: Array) -> Array:
	var out: Array = []
	for h: String in hexes:
		out.append(Color(h))
	return out


## Bentuk lonjong berbayang 4 tingkat (terang di kiri-atas). clip_y = baris terbawah yang digambar.
func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, pal: Array, clip_y: int = 9999) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0 or y > clip_y:
				continue
			var t := dx * 0.45 + dy * 0.75 + (_n(x / 2, y / 2, int(cx * 7 + cy)) - 0.5) * 0.3
			var shade := 3
			if t < -0.4:
				shade = 0
			elif t < 0.05:
				shade = 1
			elif t < 0.5:
				shade = 2
			_px(img, x, y, pal[shade])


func _flat(img: Image, pts: Array, c: Color) -> void:
	_fill_poly(img, pts, func(_x: int, _y: int) -> Color: return c)


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(img, x, y, c)


## Cerminkan titik-titik poligon terhadap lebar gambar.
func _mirror(pts: Array, width: int) -> Array:
	var out: Array = []
	for p: Vector2 in pts:
		out.append(Vector2(width - p.x, p.y))
	return out


## Beri pinggiran kosong 2 piksel, garis tepi, bayangan, lalu simpan.
func _finish(img: Image, sprite_name: String, outline_hex: String, shadow: Array) -> void:
	var out := _new(img.get_width() + 4, img.get_height() + 4)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(2, 2))
	_outline(out, Color(outline_hex))
	_shadow(out, shadow[0] + 2.0, shadow[1] + 2.0, shadow[2], shadow[3])
	_save(out, sprite_name)


func _monster_jamur() -> void:
	var img := _new(32, 32)
	var cap := _pal(["c79ae0", "9a67bd", "7a4a9e", "5c357a"])
	var stalk := _pal(["f5ecd6", "e0d2b0", "c2b08a", "a08f6c"])
	var spot := _pal(["f8ecff", "ead4f8", "d6b8ea", "c09cd6"])
	var dark := Color("3a2348")
	_blob(img, 16, 23, 6.5, 7.5, stalk)
	_blob(img, 16, 15, 13.5, 11, cap, 17)
	_rect(img, 4, 17, 27, 17, cap[3])
	_blob(img, 10, 10, 2.5, 2, spot)
	_blob(img, 19, 8, 3, 2.5, spot)
	_blob(img, 24.5, 13, 2, 1.5, spot)
	_rect(img, 12, 21, 13, 23, dark)
	_rect(img, 18, 21, 19, 23, dark)
	_px(img, 12, 21, Color.WHITE)
	_px(img, 18, 21, Color.WHITE)
	for p: Vector2i in [Vector2i(10, 19), Vector2i(11, 19), Vector2i(12, 20), Vector2i(21, 19), Vector2i(20, 19), Vector2i(19, 20)]:
		_px(img, p.x, p.y, dark)
	_rect(img, 14, 26, 17, 26, dark)
	_px(img, 13, 27, dark)
	_px(img, 18, 27, dark)
	_finish(img, "monster_jamur", "3a2348", [16, 30, 10, 2.5])


func _monster_kelelawar() -> void:
	var img := _new(40, 34)
	var body := _pal(["8a93b8", "5b6b8c", "434f6e", "2f3850"])
	var wing: Array = [Vector2(16, 13), Vector2(9, 5), Vector2(2, 3), Vector2(1, 13), Vector2(5, 11),
		Vector2(7, 17), Vector2(11, 13), Vector2(13, 19), Vector2(16, 16)]
	var membrane := func(x: int, y: int) -> Color:
		if (x + y) % 7 == 0:
			return Color("40335a")
		return Color("7a6498") if y < 9 else Color("5c4a78")
	_fill_poly(img, wing, membrane)
	_fill_poly(img, _mirror(wing, 40), membrane)
	_flat(img, [Vector2(15, 8), Vector2(15, 1), Vector2(19, 6)], body[1])
	_flat(img, [Vector2(25, 8), Vector2(25, 1), Vector2(21, 6)], body[2])
	_blob(img, 20, 16, 5, 7, body)
	_blob(img, 20, 9.5, 5.5, 4.5, body)
	_rect(img, 17, 9, 18, 10, Color("ffd23a"))
	_rect(img, 21, 9, 22, 10, Color("ffd23a"))
	_px(img, 18, 10, Color("1c2030"))
	_px(img, 21, 10, Color("1c2030"))
	_rect(img, 18, 12, 21, 12, Color("1c2030"))
	_px(img, 18, 13, Color.WHITE)
	_px(img, 21, 13, Color.WHITE)
	_rect(img, 17, 23, 18, 24, body[3])
	_rect(img, 21, 23, 22, 24, body[3])
	_finish(img, "monster_kelelawar", "1c2030", [20, 32, 8, 1.8])


func _monster_serigala() -> void:
	var img := _new(46, 32)
	var fur := _pal(["9090a2", "64647a", "484858", "30303c"])
	_flat(img, [Vector2(35, 14), Vector2(44, 6), Vector2(46, 11), Vector2(38, 19)], fur[1])
	_flat(img, [Vector2(42, 7), Vector2(44, 6), Vector2(46, 11), Vector2(43, 11)], fur[0])
	_rect(img, 15, 19, 17, 28, fur[3])
	_rect(img, 33, 19, 35, 28, fur[3])
	_blob(img, 25, 16, 12, 6.5, fur)
	_rect(img, 11, 19, 13, 29, fur[1])
	_rect(img, 29, 19, 31, 29, fur[1])
	_rect(img, 9, 29, 13, 30, fur[2])
	_rect(img, 27, 29, 31, 30, fur[2])
	_flat(img, [Vector2(14, 9), Vector2(17, 4), Vector2(20, 10)], fur[2])
	_flat(img, [Vector2(19, 10), Vector2(22, 6), Vector2(25, 11)], fur[2])
	_blob(img, 14, 14, 6.5, 7, fur)
	_flat(img, [Vector2(11, 7), Vector2(13, 1), Vector2(16, 7)], fur[2])
	_blob(img, 9, 10, 5.5, 4.5, fur)
	_flat(img, [Vector2(7, 7), Vector2(8, 1), Vector2(11, 6)], fur[1])
	_flat(img, [Vector2(0, 10), Vector2(6, 8), Vector2(6, 14), Vector2(1, 13)], fur[1])
	_rect(img, 0, 10, 1, 11, Color("18181e"))
	_rect(img, 6, 9, 7, 9, Color("ff5040"))
	_rect(img, 2, 13, 5, 13, Color("18181e"))
	_px(img, 2, 14, Color.WHITE)
	_px(img, 4, 14, Color.WHITE)
	_finish(img, "monster_serigala", "18181e", [24, 30, 17, 2.5])


func _monster_goblin() -> void:
	var img := _new(32, 40)
	var skin := _pal(["a8d070", "7fae4e", "5e8c3c", "446a2e"])
	var tunic := _pal(["a8794a", "86603a", "6b4a2a", "4d3320"])
	var dark := Color("1f2a18")
	_rect(img, 11, 30, 13, 36, skin[1])
	_rect(img, 18, 30, 20, 36, skin[2])
	_rect(img, 9, 36, 13, 37, skin[2])
	_rect(img, 18, 36, 22, 37, skin[3])
	_blob(img, 8, 25, 2.5, 5.5, skin)
	_rect(img, 25, 4, 26, 14, Color("d9dde3"))
	_px(img, 26, 3, Color("d9dde3"))
	_rect(img, 26, 5, 26, 14, Color("8f98a6"))
	_rect(img, 23, 14, 28, 14, Color("d9a441"))
	_blob(img, 24, 21, 2.5, 5, skin)
	_blob(img, 25.5, 16, 2.2, 2.2, skin)
	_blob(img, 16, 25, 7, 8, tunic)
	_rect(img, 10, 28, 22, 28, Color("3a2c28"))
	_rect(img, 15, 28, 16, 28, Color("d9a441"))
	_flat(img, [Vector2(10, 8), Vector2(2, 5), Vector2(9, 13)], skin[1])
	_flat(img, [Vector2(22, 8), Vector2(30, 5), Vector2(23, 13)], skin[2])
	_blob(img, 16, 11, 7.5, 6.5, skin)
	_rect(img, 9, 7, 23, 8, Color("c8503f"))
	_rect(img, 9, 8, 23, 8, Color("96392d"))
	_rect(img, 12, 10, 13, 11, Color("ffe14a"))
	_rect(img, 18, 10, 19, 11, Color("ffe14a"))
	_px(img, 13, 11, dark)
	_px(img, 18, 11, dark)
	_rect(img, 15, 12, 16, 12, skin[3])
	_rect(img, 12, 14, 20, 14, dark)
	for x: int in [13, 16, 19]:
		_px(img, x, 14, Color.WHITE)
	_finish(img, "monster_goblin", "1f2a18", [16, 38, 10, 2.5])


func _monster_ogre() -> void:
	var img := _new(64, 68)
	var skin := _pal(["e8a468", "c47a40", "a3562f", "7d3f22"])
	var belly := _pal(["f4c088", "e4a468", "cc8850", "b47040"])
	var ivory := Color("f0e6d0")
	var dark := Color("3a1c10")
	_flat(img, [Vector2(49, 50), Vector2(55, 50), Vector2(62, 13), Vector2(53, 11)], Color("86603a"))
	_flat(img, [Vector2(55, 50), Vector2(62, 13), Vector2(59, 13), Vector2(53, 50)], Color("5f4326"))
	_flat(img, [Vector2(54, 18), Vector2(49, 15), Vector2(53, 22)], ivory)
	_flat(img, [Vector2(60, 24), Vector2(63, 21), Vector2(60, 28)], ivory)
	_flat(img, [Vector2(56, 12), Vector2(58, 7), Vector2(60, 12)], ivory)
	_blob(img, 23, 56, 7, 7, skin)
	_blob(img, 41, 56, 7, 7, skin)
	_blob(img, 21, 62, 8, 3, skin)
	_blob(img, 43, 62, 8, 3, skin)
	_blob(img, 32, 40, 20, 17, skin)
	_blob(img, 31, 43, 12, 10, belly)
	_flat(img, [Vector2(17, 50), Vector2(47, 50), Vector2(43, 58), Vector2(32, 61), Vector2(21, 58)], Color("5a4030"))
	_rect(img, 15, 49, 48, 50, Color("3a2c28"))
	_rect(img, 30, 48, 34, 51, Color("d9a441"))
	_blob(img, 11, 40, 6, 13, skin)
	_blob(img, 10, 53, 5, 4, skin)
	_blob(img, 53, 38, 6, 12, skin)
	_blob(img, 54, 49, 5, 4, skin)
	_flat(img, [Vector2(24, 11), Vector2(21, 2), Vector2(29, 8)], ivory)
	_flat(img, [Vector2(40, 11), Vector2(43, 2), Vector2(35, 8)], ivory)
	_blob(img, 20, 17, 2.5, 3.5, skin)
	_blob(img, 44, 17, 2.5, 3.5, skin)
	_blob(img, 32, 17, 11, 9.5, skin)
	_rect(img, 25, 13, 30, 13, dark)
	_rect(img, 34, 13, 39, 13, dark)
	_rect(img, 26, 14, 29, 16, Color("ffe14a"))
	_rect(img, 35, 14, 38, 16, Color("ffe14a"))
	_rect(img, 28, 15, 29, 16, dark)
	_rect(img, 35, 15, 36, 16, dark)
	_rect(img, 31, 18, 33, 20, skin[2])
	_rect(img, 26, 23, 38, 23, dark)
	_flat(img, [Vector2(27, 24), Vector2(28, 19), Vector2(30, 24)], ivory)
	_flat(img, [Vector2(34, 24), Vector2(36, 19), Vector2(37, 24)], ivory)
	_finish(img, "monster_ogre", "3a1c10", [32, 64, 25, 3.5])


## Garis lurus setebal `thick` piksel (untuk kaki laba-laba).
func _line(img: Image, a: Vector2, b: Vector2, c: Color, thick: int) -> void:
	var steps: int = max(1, int(max(absf(b.x - a.x), absf(b.y - a.y))))
	for i in steps + 1:
		var point := a.lerp(b, float(i) / steps)
		_rect(img, int(point.x), int(point.y), int(point.x) + thick - 1, int(point.y) + thick - 1, c)


## Laba-laba menghadap kiri. s = skala (ratu lebih besar); queen menambah mahkota dan corak bercahaya.
## Titik kaki setelah pinggiran: (22*s + 2, 27*s + top + 2), top = 6 untuk ratu.
func _spider(sprite_name: String, s: float, body_hex: Array, queen: bool) -> void:
	var top := 6 if queen else 0
	var img := _new(int(44 * s) + 2, int(28 * s) + top + 2)
	var body := _pal(body_hex)
	var thick: int = max(1, int(round(s)))
	var at := func(x: float, y: float) -> Vector2: return Vector2(x * s, y * s + top)
	# Kaki jauh (gelap) dulu, lalu badan, lalu kaki dekat.
	for leg: Array in [[17, 13, 11, 5, 6, 22], [20, 13, 17, 4, 15, 22], [24, 13, 28, 4, 31, 22], [27, 13, 35, 5, 39, 22]]:
		_line(img, at.call(leg[0], leg[1]), at.call(leg[2], leg[3]), body[3], thick)
		_line(img, at.call(leg[2], leg[3]), at.call(leg[4], leg[5]), body[3], thick)
	_blob(img, 27 * s, 13 * s + top, 10 * s, 8.5 * s, body)
	_blob(img, 13 * s, 15 * s + top, 5.5 * s, 4.5 * s, body)
	var mark := _pal(["c8ffb0", "7fe060", "4aa840", "2e7a30"]) if queen else _pal(["a8e8e0", "6cc0b8", "4a9a94", "347670"])
	_blob(img, 28 * s, 11 * s + top, 3.2 * s, 2.6 * s, mark)
	if queen:
		_blob(img, 23 * s, 15 * s + top, 1.6 * s, 1.4 * s, mark)
		_blob(img, 33 * s, 14 * s + top, 1.6 * s, 1.4 * s, mark)
		for spike: Array in [[10, 11, 11, 5, 13, 11], [13, 10, 15, 3, 17, 11], [7, 13, 6, 7, 10, 12]]:  # mahkota
			_flat(img, [at.call(spike[0], spike[1]), at.call(spike[2], spike[3]), at.call(spike[4], spike[5])], Color("f0e6d0"))
	for leg: Array in [[16, 16, 8, 9, 3, 26], [19, 17, 14, 8, 11, 27], [23, 17, 30, 8, 34, 27], [26, 16, 37, 9, 42, 26]]:
		_line(img, at.call(leg[0], leg[1]), at.call(leg[2], leg[3]), body[1], thick)
		_line(img, at.call(leg[2], leg[3]), at.call(leg[4], leg[5]), body[1], thick)
	for eye: Array in [[10, 14], [12, 13], [14, 14]]:
		_rect(img, int(eye[0] * s), int(eye[1] * s) + top, int(eye[0] * s) + thick - 1, int(eye[1] * s) + top + thick - 1, Color("ff4a3a"))
	for fang: Array in [[9, 18], [11, 19]]:
		_rect(img, int(fang[0] * s), int(fang[1] * s) + top, int(fang[0] * s) + thick - 1, int(fang[1] * s) + top + thick, Color("f0e6d0"))
	_finish(img, sprite_name, "1c1630", [22 * s, 27 * s + top, 19 * s, 2.5 * s])


## Balok tembok kastil: kubus isometrik rendah (32x40, jangkar 16,31). Sengaja lebih pendek dari
## satu petak dan lebih gelap dari lantai, supaya ruangan di belakangnya tetap terlihat.
func _wall_block() -> void:
	var img := _new(32, 40)
	var rise := 11  # tinggi tembok dalam piksel
	var top := 31 - rise
	_fill_poly(img, [Vector2(16, top - 8), Vector2(32, top), Vector2(16, top + 8), Vector2(0, top)], func(x: int, y: int) -> Color:
		return Color("3e3c48") if _n(x / 3, y / 2, 5) > 0.2 else Color("36343f"))
	_fill_poly(img, [Vector2(0, top), Vector2(16, top + 8), Vector2(16, 39), Vector2(0, 31)], func(x: int, y: int) -> Color:
		var course := int(y - x * 0.5)
		var joint := posmod(course, 5) == 0 or posmod(x + (course / 5) * 4, 8) == 0
		return Color("24222c") if joint else Color("302e38"))
	_fill_poly(img, [Vector2(16, top + 8), Vector2(32, top), Vector2(32, 31), Vector2(16, 39)], func(x: int, y: int) -> Color:
		var course := int(y + x * 0.5)
		var joint := posmod(course, 5) == 0 or posmod(x + (course / 5) * 4, 8) == 0
		return Color("1c1a22") if joint else Color("26242e"))
	_save(img, "wall_block")

## Takhta Raja Monster (32x40, jangkar 16,34).
func _throne() -> void:
	var img := _new(32, 40)
	_rect(img, 10, 3, 21, 30, Color("3a2a54"))  # sandaran
	_rect(img, 18, 3, 21, 30, Color("2a1c40"))
	_rect(img, 12, 7, 19, 25, Color("8a2a34"))  # bantalan merah
	_rect(img, 10, 3, 21, 4, Color("d9a441"))
	for spike: Array in [[10, 3, 11, -1, 13, 3], [14, 3, 16, -2, 18, 3], [19, 3, 21, -1, 22, 3]]:
		_flat(img, [Vector2(spike[0], spike[1]), Vector2(spike[2], spike[3] + 2), Vector2(spike[4], spike[5])], Color("d9a441"))
	_rect(img, 7, 24, 24, 33, Color("4a3a64"))  # dudukan
	_rect(img, 20, 24, 24, 33, Color("362a4c"))
	_rect(img, 7, 20, 9, 26, Color("5a4a78"))  # sandaran tangan
	_rect(img, 22, 20, 24, 26, Color("3a2a54"))
	_outline(img, Color("140c20"))
	_shadow(img, 16, 34, 13, 4)
	_save(img, "throne")


## Peti harta (28x28, jangkar 14,24). open = tutupnya terangkat dan isinya berkilau.
func _chest(sprite_name: String, open: bool) -> void:
	var img := _new(28, 28)
	_rect(img, 5, 14, 22, 23, Color("8a5a2c"))  # badan
	_rect(img, 17, 14, 22, 23, Color("6a4220"))
	_rect(img, 5, 14, 22, 15, Color("d9a441"))  # pita emas atas
	_rect(img, 5, 22, 22, 23, Color("b5822e"))
	_rect(img, 5, 14, 6, 23, Color("d9a441"))
	_rect(img, 21, 14, 22, 23, Color("b5822e"))
	if open:
		_rect(img, 6, 3, 21, 9, Color("6a4220"))  # tutup terangkat, terlihat bagian dalamnya
		_rect(img, 6, 3, 21, 4, Color("d9a441"))
		_rect(img, 7, 10, 20, 13, Color("3a2412"))
		for p: Vector2i in [Vector2i(9, 11), Vector2i(12, 10), Vector2i(15, 11), Vector2i(18, 10), Vector2i(11, 12), Vector2i(17, 12)]:
			_px(img, p.x, p.y, Color("ffe14a"))
	else:
		_rect(img, 5, 8, 22, 13, Color("a06a34"))  # tutup
		_rect(img, 17, 8, 22, 13, Color("7c4f26"))
		_rect(img, 5, 8, 22, 9, Color("d9a441"))
		_rect(img, 12, 12, 15, 16, Color("ffe14a"))  # gembok
		_px(img, 13, 14, Color("6a4220"))
		_px(img, 14, 14, Color("6a4220"))
	_outline(img, Color("2a1808"))
	_shadow(img, 14, 24, 10, 3)
	_save(img, sprite_name)


## Altar Cahaya: tumpuan batu dengan kristal biru bercahaya (32x34, jangkar 16,30).
func _altar() -> void:
	var img := _new(32, 34)
	_rect(img, 11, 19, 20, 29, Color("8a8894"))
	_rect(img, 17, 19, 20, 29, Color("68667a"))
	_rect(img, 9, 16, 22, 18, Color("a8a6b4"))
	_rect(img, 9, 29, 22, 30, Color("68667a"))
	_fill_poly(img, [Vector2(16, 2), Vector2(21, 9), Vector2(16, 16), Vector2(11, 9)], func(x: int, _y: int) -> Color:
		return Color("bff4ff") if x < 16 else Color("6cc0e8"))
	_px(img, 14, 7, Color.WHITE)
	_px(img, 14, 8, Color.WHITE)
	_outline(img, Color("1c2840"))
	for p: Vector2i in [Vector2i(7, 6), Vector2i(25, 4), Vector2i(24, 13), Vector2i(8, 12)]:  # kilau
		_px(img, p.x, p.y, Color("e8fbff"))
	_shadow(img, 16, 30, 10, 3)
	_save(img, "altar")


## Pohon mati di lereng Pegunungan Abu (28x36, jangkar 14,32). mirror membalik arah dahan.
func _dead_tree(sprite_name: String, mirror: bool) -> void:
	var img := _new(28, 36)
	var bark := Color("5a4a40")
	var dark := Color("3e322c")
	_rect(img, 13, 12, 14, 32, bark)
	_rect(img, 14, 12, 14, 32, dark)
	for branch: Array in [[13, 18, 6, 9], [14, 15, 22, 7], [13, 23, 8, 18], [14, 25, 20, 20], [13, 12, 12, 4], [6, 9, 3, 10], [22, 7, 24, 3]]:
		var a := Vector2(branch[0], branch[1])
		var b := Vector2(branch[2], branch[3])
		if mirror:
			a.x = 27 - a.x
			b.x = 27 - b.x
		_line(img, a, b, bark, 1)
	_outline(img, Color("2a211c"))
	_shadow(img, 14, 32, 7, 3)
	_save(img, sprite_name)


## Kadal Bara: kadal menghadap kiri dengan duri punggung membara.
func _monster_kadal_bara() -> void:
	var img := _new(48, 26)
	var skin := _pal(["e88a5a", "c05a34", "94402a", "6a2c20"])
	_flat(img, [Vector2(33, 13), Vector2(46, 8), Vector2(47, 11), Vector2(36, 19)], skin[1])
	_flat(img, [Vector2(43, 9), Vector2(46, 8), Vector2(47, 11), Vector2(44, 12)], skin[0])
	_rect(img, 14, 16, 16, 22, skin[3])
	_rect(img, 30, 16, 32, 22, skin[3])
	_blob(img, 24, 14, 13, 5.5, skin)
	_rect(img, 11, 17, 13, 22, skin[1])
	_rect(img, 27, 17, 29, 22, skin[1])
	_rect(img, 9, 22, 13, 23, skin[2])
	_rect(img, 25, 22, 29, 23, skin[2])
	for spike: Array in [[14, 10, 16, 4, 18, 10], [20, 9, 22, 3, 24, 9], [26, 9, 28, 4, 30, 10]]:
		_flat(img, [Vector2(spike[0], spike[1]), Vector2(spike[2], spike[3]), Vector2(spike[4], spike[5])], Color("ffb040"))
	_blob(img, 9, 12, 5.5, 3.8, skin)
	_flat(img, [Vector2(0, 12), Vector2(5, 10), Vector2(5, 15), Vector2(1, 14)], skin[1])
	_rect(img, 6, 11, 7, 11, Color("ffe14a"))
	_px(img, 1, 12, Color("3a1810"))
	_px(img, 2, 15, Color.WHITE)
	_px(img, 4, 15, Color.WHITE)
	_finish(img, "monster_kadal_bara", "3a1810", [24, 24, 17, 2.2])


## Makhluk bersayap terbentang yang melayang (Elang Abu kelabu, Gargoyle batu gelap).
## wing_hex = [warna garis bulu, bagian atas sayap, bagian bawah sayap].
func _bird(sprite_name: String, body_hex: Array, wing_hex: Array, eye_hex: String) -> void:
	var img := _new(48, 34)
	var body := _pal(body_hex)
	var wing: Array = [Vector2(20, 14), Vector2(12, 6), Vector2(2, 3), Vector2(0, 8), Vector2(4, 9), Vector2(2, 13),
		Vector2(7, 13), Vector2(6, 17), Vector2(12, 16), Vector2(16, 19), Vector2(20, 17)]
	var feathers := func(x: int, y: int) -> Color:
		if x % 5 == 0:
			return Color(String(wing_hex[0]))
		return Color(String(wing_hex[1])) if y < 9 else Color(String(wing_hex[2]))
	_fill_poly(img, wing, feathers)
	_fill_poly(img, _mirror(wing, 48), feathers)
	_flat(img, [Vector2(21, 22), Vector2(27, 22), Vector2(28, 29), Vector2(20, 29)], body[2])
	_blob(img, 24, 17, 5, 7, body)
	_blob(img, 24, 9.5, 4.2, 4, body)
	_flat(img, [Vector2(22, 11), Vector2(26, 11), Vector2(24, 15)], Color("e0b040"))
	_rect(img, 21, 8, 22, 9, Color(eye_hex))
	_rect(img, 26, 8, 27, 9, Color(eye_hex))
	_px(img, 22, 9, Color("2a2420"))
	_px(img, 26, 9, Color("2a2420"))
	_rect(img, 21, 24, 22, 25, Color("e0b040"))
	_rect(img, 26, 24, 27, 25, Color("e0b040"))
	_finish(img, sprite_name, "2a2420", [24, 32, 9, 1.8])


## Golem: tumpukan bongkah berbentuk raksasa. s = skala; crack_hex = warna retakan/hiasan;
## eye_hex = warna mata; top = ruang kosong di atas (untuk mahkota); crown = mahkota bertanduk;
## sword = pedang besar di tangan kanan. Dipakai untuk Golem Batu, Raksasa Lahar, Ksatria Kelam, dan Raja Monster.
## Titik kaki setelah pinggiran: (20*s + 2, 42*s + top + 2).
func _golem(sprite_name: String, s: float, body_hex: Array, crack_hex: String, eye_hex: String,
		top: int = 0, crown: bool = false, sword: bool = false) -> void:
	var img := _new(int(40 * s) + 1, int(44 * s) + top + 1)
	var rock := _pal(body_hex)
	var thick: int = max(1, int(round(s)))
	var at := func(x: float, y: float) -> Vector2: return Vector2(x * s, y * s + top)
	if sword:  # di belakang kepalan tangan kanan
		_flat(img, [at.call(33.5, 33), at.call(36.5, 33), at.call(38.5, 5), at.call(37, 1), at.call(35, 5)], Color("c9d1dc"))
		_flat(img, [at.call(36, 33), at.call(36.5, 33), at.call(38.5, 5), at.call(37, 1)], Color("7a8494"))
	for part: Array in [[13, 36, 5, 6], [27, 36, 5, 6], [13, 41, 6, 2.2], [27, 41, 6, 2.2],  # kaki
			[5, 26, 4, 8], [35, 26, 4, 8], [5, 34, 4.6, 4], [35, 34, 4.6, 4],  # lengan dan kepalan
			[20, 22, 12, 11], [7, 16, 5.5, 5], [33, 16, 5.5, 5], [20, 8, 6.2, 5.6]]:  # badan, bahu, kepala
		_blob(img, part[0] * s, part[1] * s + top, part[2] * s, part[3] * s, rock)
	var crack := Color(crack_hex)
	for seg: Array in [[14, 17, 19, 23], [19, 23, 16, 30], [25, 15, 27, 23], [27, 23, 24, 28], [5, 22, 6, 30], [34, 21, 35, 29]]:
		_line(img, at.call(seg[0], seg[1]), at.call(seg[2], seg[3]), crack, thick)
	if sword:
		_rect(img, int(32 * s), int(32 * s) + top, int(38.5 * s), int(32 * s) + top + thick, Color("d9a441"))
	if crown:
		for spike: Array in [[14.5, 5, 15.5, -3.5, 17.5, 3.5], [18.5, 3, 20, -4.5, 21.5, 3], [22.5, 3.5, 24.5, -3.5, 25.5, 5]]:
			_flat(img, [at.call(spike[0], spike[1]), at.call(spike[2], spike[3]), at.call(spike[4], spike[5])], Color("ffd866"))
		_rect(img, int(15 * s), int(3.5 * s) + top, int(25 * s), int(3.5 * s) + top + thick - 1, Color("d9a441"))
	for eye: Array in [[17, 7], [22, 7]]:
		_rect(img, int(eye[0] * s), int(eye[1] * s) + top, int(eye[0] * s) + thick, int(eye[1] * s) + top + thick, Color(eye_hex))
	_finish(img, sprite_name, "1c1814", [20 * s, 42 * s + top, 14 * s, 2.5 * s])

## Roh melayang berbentuk nyala api (Roh Kabut biru pucat, Arwah Bayangan ungu gelap).
func _wisp(sprite_name: String, flame_hex: Array, core_hex: Array, eye_hex: String, outline_hex: String) -> void:
	var img := _new(28, 36)
	var flame := _pal(flame_hex)
	var core := _pal(core_hex)
	_flat(img, [Vector2(15, 1), Vector2(20, 12), Vector2(8, 12)], flame[1])
	_flat(img, [Vector2(15, 1), Vector2(17, 9), Vector2(12, 10)], flame[0])
	_blob(img, 14, 17, 8.5, 9, flame)
	_blob(img, 13.5, 18, 4.8, 5.2, core)
	_blob(img, 9, 27, 2.2, 2.2, flame)
	_blob(img, 18, 29, 1.6, 1.6, flame)
	_rect(img, 10, 15, 11, 17, Color(eye_hex))
	_rect(img, 16, 15, 17, 17, Color(eye_hex))
	_finish(img, sprite_name, outline_hex, [14, 33.5, 7, 1.8])


# ---------------------------------------------------------------- latar battle (320x180, tampil 4x)

## style: "" padang terbuka, "trees" deretan pohon di cakrawala, "cave" dinding gua.
func _backdrop(sprite_name: String, sky_hex: Array, far_hex: String, near_hex: String, ground_hex: Array, style: String) -> void:
	var img := _new(320, 180)
	var sky_top := Color(String(sky_hex[0]))
	var sky_low := Color(String(sky_hex[1]))
	var far := Color(far_hex)
	var near := Color(near_hex)
	var ground := _pal(ground_hex)
	var horizon := 80
	var salt := hash(sprite_name)
	rng.seed = salt
	for y in 180:
		for x in 320:
			var c: Color
			if y < horizon:
				c = sky_top.lerp(sky_low, floor(float(y) / horizon * 7.0) / 7.0)
				if style == "cave":
					var r := _n(x / 3, y / 2, salt)
					c = sky_top.lerp(sky_low, r)
					if y < 10.0 + 14.0 * abs(sin(x * 0.11)) * _n(x / 9, 0, salt):  # stalaktit
						c = sky_top.darkened(0.35)
				var far_y := 58.0 - 9.0 * sin(x * 0.031 + 1.0) - 5.0 * sin(x * 0.083)
				var near_y := 70.0 - 5.0 * sin(x * 0.047 + 2.0) - 3.0 * sin(x * 0.121)
				if y >= near_y:
					c = near
				elif y >= far_y:
					c = far
			else:
				var depth := float(y - horizon) / (180.0 - horizon)
				c = ground[0]
				var r := _n(x, y, salt)
				if r < 0.07:
					c = ground[1]
				elif r < 0.14:
					c = ground[2]
				if y < horizon + 3:
					c = ground[2]
				c = c.lightened(0.10 * (1.0 - depth))
			img.set_pixel(x, y, c)
	if style == "trees":
		var x := 4
		while x < 320:
			var h := rng.randi_range(16, 30)
			var r := rng.randi_range(6, 10)
			var leaf := near.darkened(rng.randf_range(0.15, 0.4))
			_rect(img, x - 1, horizon - h + r, x, horizon + 1, Color("3a2c22"))
			_blob(img, x, horizon - h, r, r, [leaf.lightened(0.15), leaf, leaf.darkened(0.15), leaf.darkened(0.3)])
			x += rng.randi_range(9, 17)
	_save(img, sprite_name)


# ---------------------------------------------------------------- lembar pratinjau

func _preview(path: String) -> void:
	var sheet := Image.create(240, 250, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("707a70"))
	var x := 2
	var y := 2
	var row_h := 0
	for sprite_name: String in _made:
		var wanted := false
		for prefix: String in ["gear_", "mat_", "icon_perlengkapan", "monster_lendir", "monster_mata", "monster_kura", "monster_peti", "npc_gatot_front_stand", "npc_sena_front_stand", "npc_rekso_front_stand"]:
			wanted = wanted or sprite_name.begins_with(prefix)
		if not wanted:
			continue
		var img: Image = _made[sprite_name]
		if x + img.get_width() > sheet.get_width() - 2:
			x = 2
			y += row_h + 2
			row_h = 0
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
		x += img.get_width() + 2
		row_h = max(row_h, img.get_height())
	sheet = sheet.get_region(Rect2i(0, 0, 240, 190))
	sheet.resize(sheet.get_width() * 5, sheet.get_height() * 5, Image.INTERPOLATE_NEAREST)
	sheet.save_png(path)


# ---------------------------------------------------------------- perlengkapan dan bahan (ikon 16x16)

## Pandai besi: ikat kepala merah, celemek kulit, palu di tangan.
func _dress_pandai(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 4, 2, 11, 3, "c8503f")
	if front:
		_hrect(img, 5, 12, 10, 19, "6b4a2a")
		_hrect(img, 5, 12, 10, 12, "86603a")
	_hrect(img, 14, 12, 14, 18, "86603a")
	_hrect(img, 13, 10, 15, 12, "9aa4b2")
	_hrect(img, 13, 10, 15, 10, "d0d8e0")


## Gambar ikon sebagai teks: 1/2/3 = bahan utama (terang/sedang/gelap), a/b = hiasan,
## w/W = kayu atau kulit, s = tali. Baris yang lebih pendek dari 16 dianggap kosong di kanannya.
const GEAR_ART := {
	"sword": ["..............12", ".............123", "............123", "...........123", "..........123", ".........123",
		"........123", "..a....123", "..ba..123", "...ba123", "....bab", "...wWbba", "..wW...b", ".wW", "aW"],
	"staff_holy": ["......aaaa", ".....a....a", ".....a.12.a", ".....a.23.a", "......aaaa", ".......ab", ".......wW", ".......wW",
		".......wW", ".......wW", ".......wW", ".......wW", ".......wW", ".......wW", ".......wW", ".......ab"],
	"staff_orb": ["..........aaa", ".........a112a", ".........a122a", ".........a223a", "..........aaa", ".........wW", "........wW",
		".......wW", "......wW", ".....wW", "....wW", "...wW", "..wW", ".wW", ".W"],
	"bow": [".....s11", ".....s.12", ".....s..12", ".....s...23", ".....s...23", ".....s....a", ".....s....w", ".....s....W",
		".....s....w", ".....s....a", ".....s...23", ".....s...23", ".....s..12", ".....s.12", ".....s11"],
	"helm": ["", ".....111111", "....11222221", "...1122222231", "...1222222231", "...1222222231", "...aaaaaaaaab", "...12b....b31",
		"...12b....b31", "...122b..b231", "...1222..2231", "...1222..2231", "....122..231", ".....33..33"],
	"hood": ["", "......1111", "....11222211", "...1122222231", "...1222222223", "..122233332223", "..1223kkkk3223", "..123kkkkkk323",
		"..123kkkkkk323", "..123kkkkkk323", "..1223kkkk3223", "..12223aa32223", "...12222a2223", "....33333333"],
	"hat": ["", ".........11", "........122", ".......1223", ".......1223", "......12223", "......12223", ".....122223", ".....aaaaab",
		"....1222223", "..11222222233", ".1122222222233", ".1222222222223", "..33333333333"],
	"plate": ["", "..11........11", ".1221......1221", ".12221aaaa12221", ".12222122122231", "..122212212223", "...1221221223",
		"...1222222223", "...1222aa2223", "...1222ab2223", "...1222222223", "...1222222223", "...aaaaaaaaab", "...1222222223", "....33333333"],
	"robe": ["", ".....11..11", "....122aa221", "...12222a2223", "..1222222a2223", ".12212222a22123", ".1231222a222123", ".33.1222a2223.33",
		"....1222a2223", "....aaaaaaaab", "...12222a22223", "...12222a22223", "..1222222a22223", "..1222222a22223", "..3333333333333"],
	"vest": ["", "....11....11", "...1221..1223", "...122....223", "...1222..2223", "...1222aa2223", "...1222ww2223", "...1222aa2223",
		"...1222ww2223", "...1222aa2223", "...aaaaaaaaab", "...1222222223", "....33333333"],
	"boot": ["", "", "....11111", "....12223", "....12223", "....12223", "....aaaab", "....12223", "....12223", "....122223",
		"....12222221", "....122222223", "....122222223", "....WWWWWWWWW"],
	"sandal": ["", "", "", "", "", "", ".......11", "......1221..1", ".....12..21.12", "....12....2112", "...1222222222a",
		"..wwwwwwwwwwwwW", "..WWWWWWWWWWWWW"],
	"shoe": ["", "", "", "", "", ".........111", "........12223", "........12223", ".......1aaab", ".1....122223", ".11.11222223",
		".12222222223", "..3333333333"],
}
const GEAR_ART_OF := {
	"arlen": {"weapon": "sword", "head": "helm", "body": "plate", "feet": "boot"},
	"mira": {"weapon": "staff_holy", "head": "hood", "body": "robe", "feet": "sandal"},
	"selene": {"weapon": "staff_orb", "head": "hat", "body": "robe", "feet": "shoe"},
	"kael": {"weapon": "bow", "head": "hood", "body": "vest", "feet": "boot"},
}
## Warna per tokoh dan tingkat: [utama terang, sedang, gelap, hiasan terang, hiasan gelap].
const GEAR_PALETTES := {
	"arlen": [["b8bcc4", "8a909c", "5e6470", "c8a040", "8a6a28"], ["e4eef8", "9ab4d0", "5e7a9c", "e0b040", "a87a28"],
		["d0fff0", "7fe0d0", "3a9aa0", "ffe14a", "d09a20"]],
	"mira": [["f0ece0", "c8c0ac", "968c78", "7fb7e0", "4a80b0"], ["f4f4ff", "c0c8ec", "8088c0", "f0d070", "c09a30"],
		["fffbe0", "ffe890", "d8b040", "ffffff", "9ad0ff"]],
	"selene": [["8a6ab8", "64489a", "42286e", "c8a040", "8a6a28"], ["7aa8f0", "4a70c8", "2c4690", "c0f0ff", "6ac0e8"],
		["5a4ab0", "34288a", "1c1458", "ffe14a", "ffb030"]],
	"kael": [["b08a5a", "86603a", "5e4024", "8a9a6a", "5a6a44"], ["6aa860", "468244", "2c5c2e", "c8a040", "8a6a28"],
		["9ab4c8", "6a88a4", "44607c", "ffe14a", "c89a20"]],
}
const MATERIAL_ART := {
	"common": ["", "", "....1.....1", "...12....12", "...123..123.1", "....123123.12", ".....1233.123", "....aaaaaaa3", "....abbbbbb",
		".....1233123", "....123.12.23", "...123..12..3", "...12...1", "...1"],
	"rare": ["", "", "......11111", ".....1222223", ".....1222223", ".....122223", "......12223", "......12223", ".......1223",
		".......1223", "........123", "........123", ".........13", ".........3"],
	"super": ["", "", ".....111111", "....11222223", "...1122222233", "..112222222233", "..122222222223", "...1222222223",
		"....12222223", ".....122223", "......1223", ".......13"],
	"ultra": ["", ".......1", ".......12", "......1123", ".a....1223....a", ".1b..112233..b3", "..1211222233123", "...12222222223",
		"....122222223", "...11222222233", "..112233.223233", ".1123.....32233", ".13.........33"],
}
const MATERIAL_PALETTES := {1: ["d8e8a0", "9ac060", "5e8a3a"], 2: ["d8f4f4", "7cc4c0", "4a8088"],
	3: ["ffd08a", "ff8a3a", "b04a1c"], 4: ["e0c0ff", "9a6ae0", "56308a"]}
const MATERIAL_IDS := {
	1: ["serat_liar", "taring_serigala", "lendir_emas", "tanduk_ogre"],
	2: ["benang_kabut", "bara_roh", "lensa_kabut", "taring_ratu"],
	3: ["sisik_bara", "inti_batu", "cangkang_magma", "jantung_lahar"],
	4: ["serpih_kelam", "jiwa_bayangan", "permata_terkutuk", "mahkota_kelam"],
}


func _art(rows: Array, colors: Dictionary, outline_hex: String) -> Image:
	var img := _new(16, 16)
	if rows.size() > 16:
		push_error("Gambar ikon lebih dari 16 baris")
	for y in min(16, rows.size()):
		var row: String = rows[y]
		if row.length() > 16:
			push_error("Baris ikon #%d panjangnya %d, maksimal 16" % [y, row.length()])
		for x in min(16, row.length()):
			if colors.has(row[x]):
				_px(img, x, y, Color(String(colors[row[x]])))
	_outline(img, Color(outline_hex))
	return img


func _gear_icons() -> void:
	for hero_id: String in GEAR_ART_OF:
		for slot: String in GEAR_ART_OF[hero_id]:
			for tier in 3:
				var pal: Array = GEAR_PALETTES[hero_id][tier]
				var colors := {"1": pal[0], "2": pal[1], "3": pal[2], "a": pal[3], "b": pal[4],
					"w": "a8794a", "W": "7a5028", "s": "e8ecf2", "k": "2a2434"}
				var img := _art(GEAR_ART[GEAR_ART_OF[hero_id][slot]], colors, "2a1f2e")
				_save(img, "gear_%s_%s_%d" % [hero_id, slot, tier + 1])
				if hero_id == "arlen" and slot == "body" and tier == 1:
					_save(img, "icon_perlengkapan")  # tombol pintasan layar Perlengkapan


func _material_icons() -> void:
	var kinds := ["common", "rare", "super", "ultra"]
	for region: int in MATERIAL_IDS:
		var pal: Array = MATERIAL_PALETTES[region]
		for i in kinds.size():
			var colors := {"1": pal[0], "2": pal[1], "3": pal[2], "a": "f0d070", "b": "a87a28"}
			var img := _art(MATERIAL_ART[kinds[i]], colors, "2a1f2e")
			if i >= 2:  # kilau untuk bahan langka
				for p: Vector2i in [Vector2i(13, 2), Vector2i(2, 12)] if i == 2 else [Vector2i(13, 1), Vector2i(1, 2), Vector2i(14, 13)]:
					_px(img, p.x, p.y, Color("fff6c0"))
			_save(img, "mat_%s" % MATERIAL_IDS[region][i])


# ---------------------------------------------------------------- monster super rare

## Lendir Emas: lendir keemasan bermahkota perak.
func _monster_lendir_emas() -> void:
	var img := _new(32, 28)
	var gold := _pal(["fff0a0", "f0c040", "c89020", "8a5e14"])
	var dark := Color("4a3010")
	var silver := Color("f0f4ff")
	_blob(img, 16, 19, 13, 10, gold, 25)
	_blob(img, 16, 12, 8, 7, gold)
	_rect(img, 5, 25, 26, 25, gold[3])
	_rect(img, 10, 11, 11, 12, Color.WHITE)
	_rect(img, 11, 17, 12, 19, dark)
	_rect(img, 19, 17, 20, 19, dark)
	_px(img, 11, 17, Color.WHITE)
	_px(img, 19, 17, Color.WHITE)
	_rect(img, 14, 22, 17, 22, dark)
	_px(img, 13, 21, dark)
	_px(img, 18, 21, dark)
	_rect(img, 12, 3, 19, 5, silver)
	for x: int in [12, 15, 16, 19]:
		_rect(img, x, 1, x, 2, silver)
	_rect(img, 15, 4, 16, 4, Color("e04848"))
	_finish(img, "monster_lendir_emas", "4a3010", [16, 26, 11, 2.5])


## Mata Kabut: bola mata raksasa melayang dengan sulur-sulur.
func _monster_mata_kabut() -> void:
	var img := _new(32, 38)
	var skin := _pal(["d8f4f0", "9cd0cc", "6aa0a8", "44707c"])
	var white := _pal(["ffffff", "f0f8ff", "d0e0f0", "a8bcd8"])
	var iris := _pal(["e0b0ff", "a060e0", "7038b0", "44207a"])
	for t: Array in [[9, 22, 6, 33], [14, 25, 13, 35], [19, 25, 20, 35], [24, 22, 27, 32]]:
		_line(img, Vector2(t[0], t[1]), Vector2(t[2], t[3]), skin[2], 2)
	_blob(img, 16, 14, 13, 13, skin)
	_blob(img, 15, 14, 9, 8, white)
	_blob(img, 13, 14, 5, 5, iris)
	_rect(img, 11, 12, 13, 15, Color("1c1030"))
	_px(img, 11, 12, Color.WHITE)
	_finish(img, "monster_mata_kabut", "244a58", [16, 36, 9, 2])


## Kura-kura Magma: tempurung batu dengan retakan lahar; menghadap kiri.
func _monster_kura_magma() -> void:
	var img := _new(46, 30)
	var shell := _pal(["8a6258", "5e4038", "44302a", "2c1e1a"])
	var skin := _pal(["d8a070", "b07a4a", "86562e", "5e3a1c"])
	var lava := Color("ff8a2a")
	for x: int in [14, 22, 32, 38]:
		_blob(img, x, 25, 3.5, 4, skin)
	_blob(img, 41, 21, 4, 2, skin)
	_blob(img, 7, 19, 6, 5, skin)
	_blob(img, 25, 14, 16, 12, shell, 21)
	_rect(img, 10, 21, 40, 22, shell[3])
	for seg: Array in [[14, 12, 22, 6], [22, 6, 30, 10], [30, 10, 37, 14], [22, 6, 24, 16], [30, 10, 28, 19], [14, 12, 17, 19]]:
		_line(img, Vector2(seg[0], seg[1]), Vector2(seg[2], seg[3]), lava, 1)
	for p: Vector2i in [Vector2i(22, 6), Vector2i(30, 10), Vector2i(14, 12)]:
		_px(img, p.x, p.y, Color("ffd23a"))
	_rect(img, 4, 17, 5, 18, Color("1c1030"))
	_px(img, 4, 17, Color("ffd23a"))
	_finish(img, "monster_kura_magma", "241814", [24, 28, 17, 2.5])


## Peti Terkutuk: peti harta yang ternyata hidup, bergigi dan berlidah.
func _monster_peti_terkutuk() -> void:
	var img := _new(34, 32)
	var wood := _pal(["b8824a", "8e5e30", "6a4220", "462a14"])
	var gold := Color("e0b040")
	var gold_dark := Color("a87a28")
	_rect(img, 3, 11, 30, 16, Color("1c1030"))  # rongga mulut
	for span: Array in [[3, 10], [17, 29]]:  # tutup dan badan peti
		for y in range(span[0], span[1] + 1):
			for x in range(3, 31):
				_px(img, x, y, wood[1] if x < 20 else wood[2])
		_rect(img, 3, span[0], 30, span[0], wood[0])
		_rect(img, 7, span[0], 8, span[1], gold_dark)
		_rect(img, 25, span[0], 26, span[1], gold_dark)
	_rect(img, 3, 9, 30, 10, gold)
	_rect(img, 3, 17, 30, 18, gold)
	_rect(img, 3, 29, 30, 29, wood[3])
	for x in range(5, 30, 4):
		_rect(img, x, 11, x + 1, 12, Color.WHITE)
	for x in range(7, 30, 4):
		_rect(img, x, 15, x + 1, 16, Color.WHITE)
	_rect(img, 10, 13, 11, 14, Color("ffe14a"))
	_rect(img, 21, 13, 22, 14, Color("ffe14a"))
	_blob(img, 16, 21, 3, 6, _pal(["ff9ab0", "e0607a", "b83e5a", "8a2a44"]))
	_finish(img, "monster_peti_terkutuk", "1c1030", [17, 30, 14, 2.5])