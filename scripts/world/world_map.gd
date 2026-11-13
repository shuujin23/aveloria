class_name WorldMap
extends RefCounted
## Semua peta sebagai teks: satu karakter = satu petak. Ubah MAPS untuk mengubah dunia.
## Baris yang lebih pendek dan petak di luar peta dianggap berisi karakter "outside" peta itu.

# Peta dunia:
#   ^ gunung   ~ air      = jalan    S (tidak dipakai lagi, dianggap jalan)
#   . padang   f hutan    (Lembah Hijau)
#   , padang   F hutan    (Hutan Kabut)
#   T Desa Rindu          D Dusun Embun       (pintu masuk ke peta desa/dusun)
#   B sarang Ogre         G gerbang timur (terbuka setelah Ogre kalah)
#   Q sarang Ratu Laba-laba   P Celah Abu (terbuka setelah Ratu kalah)   E jalan ke Pegunungan Abu
# Peta Pegunungan Abu ("abu"):
#   a padang abu   c lereng berbatu   L lahar (tak bisa dilewati)   W jalan kembali ke Hutan Kabut
#   K Pos Pemburu  N kawah Raksasa Lahar   R jalan lahar (terbuka setelah Raksasa kalah)   Z ujung jalan (bersambung)
# Peta Kastil Kelam ("kastil"):
#   C karpet (aman)   o aula   d ruang dalam   w tembok   V gerbang (kembali ke Pegunungan Abu)
#   A Altar Cahaya (memulihkan party)   M takhta Raja Monster
# Peta desa/dusun/pos:
#   g tanah lapang (aman)  h rumah    I penginapan   Y pohon   X jalan keluar (ke peta "exit")
# Peta dungeon ("gua", "sarang", "kawah"): lorong berliku menuju semi-bos, dimasuki dari B / Q / N.
#   r lorong gua   s lorong sarang   k lorong kawah   (ada monster)
#   O Ogre Penjaga   U Ratu Laba-laba   J Raksasa Lahar   (petak semi-bos)
#   x peti harta (isinya di "chests" peta itu)   e jalan keluar (ke peta "exit")
# Peta dungeon bertanda "dungeon": true; "floor" = bahan tanah untuk petak peti dan jalan keluar.
const MAPS := {
	"dunia": {
		"name": "Aveloria", "outside": "^",
		"chests": {Vector2i(6, 1): {"item": "ramuan", "count": 2}, Vector2i(6, 27): {"gold": 40},
			Vector2i(61, 3): {"mats": {"benang_kabut": 3}}, Vector2i(50, 27): {"item": "ramuan_besar", "count": 1}},
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
			"^^^^^^x...ffffff.......^^^^^^^^^^~~~~~~^^^^,,,,,,,FFFFFF,,,,,^^^^^",
			"^^^^^^....ffffff.......^^^^^^^^^^~~~~~~^^^^,,,,,,,FFFFFF,,,,,^^^^^",
			"^^^^....ffffffffff........^^^^^~~~~~~~~^^,,,,,FFFFFFFFFF,,,,,x^^^^",
			"^^^^....ffffffffff........^^^^^~~~~~~~~^^,,,,,FFFFFFFFFF,,,,,,^^^^",
			"^^......ffffffff............^^^~~~~~~^^^,,,,,,FFFFFFFFFFFF,,,,,,^^",
			"^^......ffffffff............^^^~~~~~~^^^,,,,,,FFFFFFFFFFFF,,,,,,^^",
			"^.......fffffff.......=======B^~~~~~~^^,,,,,,,,,FFFFFFFF,,,,,,,,^^",
			"^..............========.....^^~~~~~~^^^,,,,,,,,,,,FFFFF,,,,,,,,,,^",
			"^...T===========............^^~~~~~~^^^,,,,,,,,,,,,,,,,,,,,,,,,,PE",
			"^...=..........=.............^~~~~~~^,,,,,,,,,,,,,,,,,,,,,,,FF,,,^",
			"^...=..........=.............^~~~~~~^,,,,,,,,,,,,,,,,,,,,,,,FF,,,^",
			"^...=..........=......fff....^~~~~~~^,,,,,,,,,,,,,,,,,,,,,FFFFFF,^",
			"^...=..........=......fff....^~~~~~~^,,,,,,,,,,,,,,,,,,,,,FFFFFF,^",
			"^...=..........=....ffffff...~~~~~~~~,,,,,,,,,,,,,,,,,,,,,FFFQFF,^",
			"^.......ffff...=....ffffff...~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,FF,,,^",
			"^.......ffff...=....ffffff...~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,FF,,,^",
			"^.....fffffff..=......fff....~~~~~~~~,,,,,,FFF,,,,,,,,,,,,,,,,,,,^",
			"^.....fffffff..=......fff....~~~~~~~~,,,,,,FFF,,,,,,,,,,,,,,,,,,,^",
			"^.....fffffff..==============G==========DFFFFFFF,,,,,,,,,,,,,,,,^^",
			"^.......ffff...=.............~~~~~~~~,,,,FFFFFFF,,,,,,,,,,,,,,^^^^",
			"^.......ffff...=.............~~~~~~~~,,,,FFFFFFF,,,,,,,,,,,,,,^^^^",
			"^..............=.............~~~~~~~~,,,,,,FFF,,,,,,,,,,,,,,,^^^^^",
			"^..............=.............~~~~~~~~,,,,,,FFF,,,,,,,,,,,,,,,^^^^^",
			"^^.............=............~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,^^^^^^^^",
			"^^.............=............~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,^^^^^^^^",
			"^^^^.........fff..........~~~~~~~~~~~~~~,,,,,,,,,,,,,,,^^^^^^^^^^^",
			"^^^^^^x.....ffffff.....^^^^^~~~~~~~~~~~^^^^,,,,,,,x^^^^^^^^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
		],
	},
	"abu": {
		"name": "Pegunungan Abu", "outside": "^",
		"chests": {Vector2i(4, 1): {"mats": {"sisik_bara": 3}}, Vector2i(51, 3): {"gold": 150}},
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
			"^^^^xaaaaccccc^^^^^^^aaaaaaaaaaa^^^^^^^^LLLLLLL^^^^^^^",
			"^^^^aaaaaccccc^^^^^^^aaaaaaaaaaa^^^^^^^^LLLLLLL^^^^^^^",
			"^^aaaaaaccccccccaaaaaaaaaaaaaaaaaaaa^^^^LLLLLLLLLaax^^",
			"^^aaaaaaccccccccaaaaaaaaaaaaaaaaaaaa^^^^LLLLLLLLLaaa^^",
			"^aaaaaaaacccccaaaaaaaaacccccccaaaaaaaaaaLLLLLaaaaaaaa^",
			"^aaaaaaaacccccaaaaaaaaacccccccaaaaaaaaaaLLLLLaaaaaaaa^",
			"^aaaaaaaaaaaaaaaaaaaaaccccccccccaaaaaaaaaLLaaaaaaaNaa^",
			"W====aaaaaaaaaaaaaaaaaacccccccaaaaaaaaaaaaaaaaaaaaaaa^",
			"^aaa=aaaaaaLLLaaaaaaaaaaaaaaaaaaaaaaaaaacccccccaaaaaa^",
			"^aaa=aaaaaaLLLaaaaaaaaaaaaaaaaaaaaaaaaaacccccccaaaaaa^",
			"^aaa======LLLLLLaaaaaaaaaaaaaaaaaaaaaacccccccccccaaaRZ",
			"^aaaaaaaa=aLLLaaaaaaaaKaaaaaaaaaaaaaaaaacccccccaaaaaa^",
			"^aaaacccc=aaaaaaaaaaa==aaaaaaaaaaaaaaaaaaaaaaaaaaaaa^^",
			"^^aacccccc============aaaaaaaaccccccccaaaaaaaaaaaaa^^^",
			"^^^^accccaaaaaaaaaaaaaaaaaccccccccccccaaaaaaaaaaa^^^^^",
			"^^^^accccaaaaaaaaaaaaaaaaaccccccccccccaaaaaaaaaaa^^^^^",
			"^^^^^^aaaaaaaaaaaa^^^^^aaaaaccccccccaaaaaaa^^^^^^^^^^^",
			"^^^^^^aaaaaaaaaaaa^^^^^aaaaaccccccccaaaaaaa^^^^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
		],
	},
	"kastil": {
		"name": "Kastil Kelam", "outside": "w", "theme": "castle", "floor": "floor_dark",
		"chests": {Vector2i(4, 6): {"gold": 300}, Vector2i(20, 7): {"item": "air_kehidupan", "count": 1}},
		"rows": [
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwMwwwwwwwwwwwwwwwww",
			"wwwwwwwwwdddCdddwwwwwwwwwwwwww",
			"wwwwwwwwwdddCdddwwwwwwwwwwwwww",
			"wwwwwwwwwwwwCwwwwwwwwwwwwwwwww",
			"wwwwddddddddCddddddddwwwwwwwww",
			"wwwwxddwwdddCdddwwdddwwwwwwwww",
			"wwwwdddwwdddCdddwwddxwwwwwwwww",
			"wwwwddddddddCddddddddwwwwwwwww",
			"wwwwwwwwwwwwCwwwwwwwwwwwwwwwww",
			"wwwwwwwoooooCooooowwwwwwwwwwww",
			"wwwwwwwooAooCooooowwwwwwwwwwww",
			"wwwwwwwoooooCooooowwwwwwwwwwww",
			"wwwwwwwwwwwwCwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwVwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
		],
	},
	"desa": {
		"name": "Desa Rindu", "outside": "Y", "spawn": Vector2i(7, 11), "exit": "dunia",
		"rows": [
			"YYYYYYYYYYYYYYYYYY",
			"YgggggggggggggggYY",
			"YghgggggggggghgggY",
			"Ygg=========gggggY",
			"Ygg=ggggggg=ggYggY",
			"Ygg=gg~~ggg=gggggY",
			"Ygg=gg~~ggg=ghgggY",
			"Ygg=ggggggg=gggggY",
			"Ygg=========gggggY",
			"YgggggI=ggggggggYY",
			"YgYgggg=gggggYgggY",
			"Ygggggg=gggggggggY",
			"YYYYYYYXYYYYYYYYYY",
		],
	},
	"gua": {
		"name": "Gua Ogre", "outside": "^", "dungeon": true, "exit": "dunia", "spawn": Vector2i(9, 11), "floor": "path",
		"chests": {Vector2i(1, 1): {"mats": {"taring_serigala": 2}}, Vector2i(15, 6): {"gold": 60}},
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^",
			"^xrr^^^^^^rrrrr^^^^^",
			"^^^r^^^^^^r^^^r^^^^^",
			"^^^rrrrr^^r^^^rrO^^^",
			"^^^^^^^r^^r^^^^^^^^^",
			"^rrrr^^rrrr^^^^^^^^^",
			"^r^^r^^r^^^^^rrx^^^^",
			"^r^^rrrrrrrrrr^^^^^^",
			"^r^^^^^^^r^^^^^^^^^^",
			"^rrrr^^^^r^^^^^^^^^^",
			"^^^^r^^^^r^^^^^^^^^^",
			"^^^^rrrrrr^^^^^^^^^^",
			"^^^^^^^^^e^^^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^",
		],
	},
	"sarang": {
		"name": "Sarang Ratu Laba-laba", "outside": "^", "theme": "mist", "dungeon": true, "exit": "dunia",
		"spawn": Vector2i(10, 10), "floor": "mist_floor",
		"chests": {Vector2i(16, 2): {"mats": {"bara_roh": 2}}, Vector2i(3, 7): {"item": "eter", "count": 2}},
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^",
			"^^^^^^sssU^^^^^^^^^^",
			"^^^^^^s^^^^^^sssx^^^",
			"^sss^^s^^^^^^s^^^^^^",
			"^s^sssssssssss^^^^^^",
			"^s^^^^^^^s^^^^^^^^^^",
			"^s^^^^^^^s^^^ssss^^^",
			"^ssx^^^^^s^^^s^^s^^^",
			"^^^^^^sssssss^^^s^^^",
			"^^^^^^s^^^^^^^^^s^^^",
			"^^^^^^sssssssssss^^^",
			"^^^^^^^^^^e^^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^",
		],
	},
	"kawah": {
		"name": "Kawah Lahar", "outside": "^", "theme": "ash", "dungeon": true, "exit": "abu",
		"spawn": Vector2i(8, 9), "floor": "cinder",
		"chests": {Vector2i(1, 2): {"mats": {"inti_batu": 2}}, Vector2i(17, 5): {"item": "air_kehidupan", "count": 1}},
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^",
			"^^^^^^^^^^^^kkJ^^^^^",
			"^xkkk^^LLL^^k^^^^^^^",
			"^^^^k^LLLLL^kkkk^^^^",
			"^kkkkkkLLLkkkk^k^^^^",
			"^k^^^^kkLkk^^^^kkx^^",
			"^k^^^^^kkk^^^^^^^^^^",
			"^kkkk^^^k^^^^^^^^^^^",
			"^^^^k^^^k^^^^^^^^^^^",
			"^^^^kkkkk^^^^^^^^^^^",
			"^^^^^^^^e^^^^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^",
		],
	},
	# theme: "mist" = warna Hutan Kabut; "ash" = tanah abu dan pohon mati.
	"dusun": {
		"name": "Dusun Embun", "outside": "Y", "spawn": Vector2i(7, 6), "exit": "dunia", "theme": "mist",
		"rows": [
			"YYYYYYYYYYYYYY",
			"YggggggggggggY",
			"YghggggggIgggY",
			"Ygg=======gggY",
			"Ygggggg=gggghY",
			"YgYgggg=gggggY",
			"Ygggggg=gggggY",
			"YYYYYggXggYYYY",
		],
	},
	"pos": {
		"name": "Pos Pemburu", "outside": "Y", "spawn": Vector2i(7, 6), "exit": "abu", "theme": "ash",
		"rows": [
			"YYYYYYYYYYYYYY",
			"YggggggggggggY",
			"YghggggggIgggY",
			"Ygg=======gggY",
			"Ygggggg=gggghY",
			"YgYgggg=gggggY",
			"Ygggggg=gggggY",
			"YYYYYggXggYYYY",
		],
	},
}

# walk   = bisa diinjak
# rate   = peluang pertemuan per langkah, table = tabel di Db.ENCOUNTER_TABLES
#          (peta wilayah diperbesar 1,5x di v1.6, jadi peluangnya diturunkan supaya jumlah pertarungan hanya naik sedikit)
# portal = pindah ke peta lain saat diinjak
# boss   = semi-bos yang bersarang di sini (lihat Db.BOSS_RULES)
# dungeon = pintu masuk dungeon semi-bos itu: hanya bisa dimasuki kalau syarat Db.BOSS_RULES terpenuhi
# chest  = peti harta; isinya ada di "chests" peta itu
# gate   = hanya bisa dilewati setelah penanda itu tercatat; locked = pesan saat masih terkunci
# scene  = adegan cerita yang dimainkan tiap kali petak ini diinjak
const TILES := {
	"^": {"walk": false, "zone": ""},
	"~": {"walk": false, "zone": ""},
	"=": {"walk": true, "zone": ""},
	"S": {"walk": true, "zone": ""},
	"T": {"walk": true, "zone": "Desa Rindu", "portal": "desa"},
	"D": {"walk": true, "zone": "Dusun Embun", "portal": "dusun"},
	".": {"walk": true, "zone": "Lembah Hijau", "rate": 0.065, "table": "lembah_padang"},
	"f": {"walk": true, "zone": "Lembah Hijau - hutan", "rate": 0.13, "table": "lembah_hutan"},
	",": {"walk": true, "zone": "Hutan Kabut", "rate": 0.075, "table": "kabut_padang"},
	"F": {"walk": true, "zone": "Hutan Kabut - rimba", "rate": 0.14, "table": "kabut_hutan"},
	"B": {"walk": true, "zone": "Sarang Ogre", "dungeon": "ogre", "portal": "gua"},
	"G": {"walk": true, "zone": "Gerbang Timur", "gate": "ogre",
		"locked": "Gerbang terkunci. Konon penjaganya bersarang di ujung jalan utara."},
	"Q": {"walk": true, "zone": "Sarang Ratu Laba-laba", "dungeon": "ratu", "portal": "sarang"},
	"P": {"walk": true, "zone": "Celah Abu", "gate": "ratu",
		"locked": "Kabut pekat menutup celah gunung ini. Mustahil melihat jalan di depan."},
	"E": {"walk": true, "zone": "Jalan ke Pegunungan Abu", "portal": "abu"},
	"W": {"walk": true, "zone": "Celah Abu", "portal": "dunia"},
	"a": {"walk": true, "zone": "Pegunungan Abu", "rate": 0.075, "table": "abu_padang"},
	"c": {"walk": true, "zone": "Pegunungan Abu - lereng", "rate": 0.14, "table": "abu_lereng"},
	"L": {"walk": false, "zone": ""},
	"K": {"walk": true, "zone": "Pos Pemburu", "portal": "pos"},
	"N": {"walk": true, "zone": "Kawah Lahar", "dungeon": "lahar", "portal": "kawah"},
	"R": {"walk": true, "zone": "Jalan Lahar", "gate": "lahar",
		"locked": "Aliran lahar menutup jalan ke timur. Mustahil diseberangi."},
	"Z": {"walk": true, "zone": "Jalan ke Kastil Kelam", "portal": "kastil"},
	"V": {"walk": true, "zone": "Gerbang Kastil", "portal": "abu"},
	"C": {"walk": true, "zone": "Kastil Kelam"},
	"o": {"walk": true, "zone": "Kastil Kelam - aula", "rate": 0.10, "table": "kastil_aula"},
	"d": {"walk": true, "zone": "Kastil Kelam - ruang dalam", "rate": 0.15, "table": "kastil_dalam"},
	"w": {"walk": false, "zone": ""},
	"A": {"walk": true, "zone": "Altar Cahaya", "scene": "altar"},
	"M": {"walk": true, "zone": "Ruang Takhta", "boss": "raja"},
	"g": {"walk": true, "zone": ""},
	"h": {"walk": false, "zone": ""},
	"I": {"walk": false, "zone": ""},
	"Y": {"walk": false, "zone": ""},
	"X": {"walk": true, "zone": "", "portal": "@exit"},  # tujuan = "exit" milik peta ini
	"r": {"walk": true, "zone": "Gua Ogre", "rate": 0.11, "table": "lembah_gua"},
	"s": {"walk": true, "zone": "Sarang Ratu Laba-laba", "rate": 0.11, "table": "kabut_sarang"},
	"k": {"walk": true, "zone": "Kawah Lahar", "rate": 0.11, "table": "abu_kawah"},
	"O": {"walk": true, "zone": "Sarang Ogre", "boss": "ogre"},
	"U": {"walk": true, "zone": "Sarang Ratu Laba-laba", "boss": "ratu"},
	"J": {"walk": true, "zone": "Kawah Lahar", "boss": "lahar"},
	"x": {"walk": true, "zone": "", "chest": true},
	"e": {"walk": true, "zone": "", "portal": "@exit"},
}

## Peta yang sedang aktif; diatur scene peta dari Game.map_id.
static var current := "dunia"


static func rows() -> Array:
	return MAPS[current].rows


static func map_name() -> String:
	return MAPS[current].name


static func outside() -> String:
	return MAPS[current].outside


## Nuansa peta: "" biasa, "mist" Hutan Kabut, "ash" Pegunungan Abu (warna tanah dan pohon berbeda).
static func theme() -> String:
	return MAPS[current].get("theme", "")


## Peta permukiman (desa, dusun, pos): aman dari monster dan punya jalan keluar.
static func is_settlement(map_id: String) -> bool:
	return MAPS[map_id].has("exit") and not is_dungeon(map_id)


## Peta dungeon: lorong menuju semi-bos, dimasuki dari peta wilayahnya.
static func is_dungeon(map_id: String) -> bool:
	return MAPS[map_id].get("dungeon", false)


## Bahan tanah untuk petak peti dan jalan keluar di peta ini; kosong = ikut petak di sebelahnya.
static func floor_material() -> String:
	return MAPS[current].get("floor", "")


## Isi peti di sebuah petak: {"gold"} / {"item", "count"} / {"mats": {id: jumlah}}; kosong kalau tidak ada.
static func chest_at(t: Vector2i) -> Dictionary:
	return MAPS[current].get("chests", {}).get(t, {})


## Penanda progres untuk peti yang sudah dibuka di peta aktif.
static func chest_flag(t: Vector2i) -> String:
	return "chest_%s_%d_%d" % [current, t.x, t.y]


## Peta tujuan sebuah petak portal.
static func portal_target(tile: Dictionary) -> String:
	var target: String = tile.portal
	return MAPS[current].get("exit", "dunia") if target == "@exit" else target


static func width() -> int:
	var w := 0
	for row: String in rows():
		w = max(w, row.length())
	return w


static func height() -> int:
	return rows().size()


static func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.y < height() and t.x < width()


static func char_at(t: Vector2i) -> String:
	var list := rows()
	if t.y < 0 or t.y >= list.size() or t.x < 0:
		return outside()
	var row: String = list[t.y]
	return row[t.x] if t.x < row.length() else outside()


static func tile_at(t: Vector2i) -> Dictionary:
	return TILES[char_at(t)]


## Gerbang hanya bisa dilewati kalau semi-bos penjaganya sudah kalah (ada di flags).
static func is_walkable(t: Vector2i, flags: Dictionary) -> bool:
	var tile := tile_at(t)
	if tile.has("gate") and not flags.has(tile.gate):
		return false
	return tile.walk


static func find(ch: String) -> Vector2i:
	return find_in(current, ch)


static func find_in(map_id: String, ch: String) -> Vector2i:
	var list: Array = MAPS[map_id].rows
	for y in list.size():
		var x := (list[y] as String).find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


## Petak tempat pemain muncul saat masuk ke `map_id` dari `from_map`:
## titik masuk peta itu, atau (di peta dunia) petak pintu menuju peta asal.
static func arrival(map_id: String, from_map: String) -> Vector2i:
	if MAPS[map_id].has("spawn"):
		return MAPS[map_id].spawn
	for ch: String in TILES:
		if TILES[ch].get("portal", "") == from_map:
			var found := find_in(map_id, ch)
			if found.x >= 0:
				return found
	return find_in(map_id, "T")
