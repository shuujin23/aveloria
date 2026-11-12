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
	_icon_bag("icon_tas")

	_monster_jamur()
	_monster_kelelawar()
	_monster_serigala()
	_monster_goblin()
	_monster_ogre()
	# Hutan Kabut
	_spider("monster_laba_laba", 1.0, ["8a7ab8", "5e4e8c", "44386a", "2c2448"], false)
	_spider("monster_ratu", 1.75, ["a05a9a", "7a3a78", "5a2a5c", "3a1a40"], true)
	_monster_roh_kabut()

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


## Bu Sari, pemilik penginapan: gaun hijau dengan celemek putih, rambut disanggul.
func _dress_sari(img: Image, front: bool, _action: String) -> void:
	_robe(img, "4a8a6a", "346a50", "f0f0f8")
	_hrect(img, 6, -1, 9, 0, "6a4028")
	if front:
		_hrect(img, 5, 12, 10, 20, "f0f0f8")
		_hrect(img, 5, 12, 5, 20, "c8ccdc")


## Dimas, anak desa: topi merah.
func _dress_dimas(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 5, 1, 10, 1, "c8503f")
	_hrect(img, 4, 2, 11, 3, "c8503f")
	if front:
		_hrect(img, 8, 4, 13, 4, "96392d")


## Pak Joko, pedagang: sorban kuning, kumis, tas selempang.
func _dress_joko(img: Image, front: bool, _action: String) -> void:
	_hrect(img, 5, 0, 10, 0, "e0b040")
	_hrect(img, 4, 1, 11, 3, "e0b040")
	_hrect(img, 9, 1, 11, 3, "b88a28")
	if front:
		_hrect(img, 6, 8, 9, 8, "3a2c28")
		for i in 5:
			_hp(img, 5 + i, 11 + i * 3 / 5, "5f4326")
		_hrect(img, 10, 14, 12, 16, "86603a")


## Nyi Laras, tetua dusun: jubah hijau-biru, rambut putih disanggul, tongkat jalan.
func _dress_laras(img: Image, _front: bool, _action: String) -> void:
	_robe(img, "3a7a78", "2a5a5c", "c8a040")
	_hrect(img, 6, -1, 9, 0, "d8d8e0")
	_hrect(img, 15, 11, 15, 22, "6b4a2a")
	_hrect(img, 14, 10, 15, 10, "6b4a2a")


## Pak Wiryo, pemilik penginapan dusun: rompi cokelat, celemek, kumis.
func _dress_wiryo(img: Image, front: bool, _action: String) -> void:
	if front:
		_hrect(img, 6, 12, 9, 17, "e8e0d0")
		_hrect(img, 6, 8, 9, 8, "3a2818")


## Mbok Rumi, penjaga warung: kerudung kuning, gaun ungu panjang.
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


## Roh Kabut: nyala api biru pucat yang melayang.
func _monster_roh_kabut() -> void:
	var img := _new(28, 36)
	var flame := _pal(["f0ffff", "b0ecf8", "6cc0e8", "4a8ad0"])
	var core := _pal(["ffffff", "f0ffff", "d0f4fc", "b0ecf8"])
	_flat(img, [Vector2(15, 1), Vector2(20, 12), Vector2(8, 12)], flame[1])
	_flat(img, [Vector2(15, 1), Vector2(17, 9), Vector2(12, 10)], flame[0])
	_blob(img, 14, 17, 8.5, 9, flame)
	_blob(img, 13.5, 18, 4.8, 5.2, core)
	_blob(img, 9, 27, 2.2, 2.2, flame)
	_blob(img, 18, 29, 1.6, 1.6, flame)
	_rect(img, 10, 15, 11, 17, Color("244a8a"))
	_rect(img, 16, 15, 17, 17, Color("244a8a"))
	_finish(img, "monster_roh_kabut", "244a8a", [14, 33.5, 7, 1.8])


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
		if not (sprite_name in ["monster_laba_laba", "monster_ratu", "monster_roh_kabut", "npc_laras_front_stand", "npc_wiryo_front_stand", "npc_rumi_front_stand"]):
			continue
		var img: Image = _made[sprite_name]
		if x + img.get_width() > sheet.get_width() - 2:
			x = 2
			y += row_h + 2
			row_h = 0
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
		x += img.get_width() + 2
		row_h = max(row_h, img.get_height())
	sheet = sheet.get_region(Rect2i(0, 0, 240, 66))
	sheet.resize(sheet.get_width() * 5, sheet.get_height() * 5, Image.INTERPOLATE_NEAREST)
	sheet.save_png(path)
