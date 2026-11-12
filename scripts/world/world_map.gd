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
# Peta desa/dusun/pos:
#   g tanah lapang (aman)  h rumah    I penginapan   Y pohon   X jalan keluar (ke peta "exit")
const MAPS := {
	"dunia": {
		"name": "Aveloria", "outside": "^",
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
			"^^^^^..ffff....^^^^^^^~~~~^^^,,,,FFFF,,,^^^^",
			"^^^...ffffff.....^^^^~~~~~^^,,,FFFFFF,,,,^^^",
			"^^....fffff.......^^^~~~~^^,,,,FFFFFFF,,,,^^",
			"^.....ffff....=====B^~~~~^,,,,,,FFFFF,,,,,^^",
			"^.........=====...^^~~~~^^,,,,,,,FFF,,,,,,,^",
			"^..T=======.......^^~~~~^^,,,,,,,,,,,,,,,,PE",
			"^..=S.....=........^~~~~^,,,,,,,,,,,,,,FF,,^",
			"^..=......=...ff...^~~~~^,,,,,,,,,,,,,FFFF,^",
			"^..=......=..ffff..~~~~~~,,,,,,,,,,,,,FFQF,^",
			"^.....ff..=..ffff..~~~~~~,,,,,,,,,,,,,,FF,,^",
			"^....ffff.=...ff...~~~~~~,,,,FF,,,,,,,,,,,,^",
			"^....ffff.=========G=======DFFFF,,,,,,,,,,^^",
			"^.....ff..=........~~~~~~,,,FFFF,,,,,,,,,^^^",
			"^.........=........~~~~~~,,,,FF,,,,,,,,,^^^^",
			"^^........=.......~~~~~~~~,,,,,,,,,,,,^^^^^^",
			"^^^......ff......~~~~~~~~~~,,,,,,,,,^^^^^^^^",
			"^^^^^...ffff...^^^~~~~~~~~^^^,,,,,^^^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
		],
	},
	"abu": {
		"name": "Pegunungan Abu", "outside": "^",
		"rows": [
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
			"^^^aaaacccc^^^^aaaaaaa^^^^LLLL^^^^^^",
			"^^aaaaccccccaaaaaaaaaaaa^^LLLLLaaa^^",
			"^aaaaaaccccaaaaaaccccaaaaaLLLaaaaaa^",
			"^aaaaaaaaaaaaaaaccccccaaaaaLaaaaNaa^",
			"W===aaaaaaaaaaaaaccccaaaaaaaaaaaaaa^",
			"^aa=aaaaaLLaaaaaaaaaaaaaaaccccaaaaa^",
			"^aa=====LLLLaaaaaaaaaaaaaccccccaaaRZ",
			"^aaaaaa=aLLaaaaaKaaaaaaaaaccccaaaaa^",
			"^aaaccc=aaaaaaa==aaaaaaaaaaaaaaaaa^^",
			"^^accccc========aaaaaccccaaaaaaaa^^^",
			"^^^acccaaaaaaaaaaaaccccccaaaaaa^^^^^",
			"^^^^^aaaaaaaa^^^^aaaccccaaaa^^^^^^^^",
			"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
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
# portal = pindah ke peta lain saat diinjak
# boss   = semi-bos yang bersarang di sini (lihat Db.BOSS_RULES)
# gate   = hanya bisa dilewati setelah penanda itu tercatat; locked = pesan saat masih terkunci
# scene  = adegan cerita yang dimainkan tiap kali petak ini diinjak
const TILES := {
	"^": {"walk": false, "zone": ""},
	"~": {"walk": false, "zone": ""},
	"=": {"walk": true, "zone": ""},
	"S": {"walk": true, "zone": ""},
	"T": {"walk": true, "zone": "Desa Rindu", "portal": "desa"},
	"D": {"walk": true, "zone": "Dusun Embun", "portal": "dusun"},
	".": {"walk": true, "zone": "Lembah Hijau", "rate": 0.08, "table": "lembah_padang"},
	"f": {"walk": true, "zone": "Lembah Hijau - hutan", "rate": 0.16, "table": "lembah_hutan"},
	",": {"walk": true, "zone": "Hutan Kabut", "rate": 0.09, "table": "kabut_padang"},
	"F": {"walk": true, "zone": "Hutan Kabut - rimba", "rate": 0.17, "table": "kabut_hutan"},
	"B": {"walk": true, "zone": "Sarang Ogre", "boss": "ogre"},
	"G": {"walk": true, "zone": "Gerbang Timur", "gate": "ogre",
		"locked": "Gerbang terkunci. Konon penjaganya bersarang di ujung jalan utara."},
	"Q": {"walk": true, "zone": "Sarang Ratu Laba-laba", "boss": "ratu"},
	"P": {"walk": true, "zone": "Celah Abu", "gate": "ratu",
		"locked": "Kabut pekat menutup celah gunung ini. Mustahil melihat jalan di depan."},
	"E": {"walk": true, "zone": "Jalan ke Pegunungan Abu", "portal": "abu"},
	"W": {"walk": true, "zone": "Celah Abu", "portal": "dunia"},
	"a": {"walk": true, "zone": "Pegunungan Abu", "rate": 0.09, "table": "abu_padang"},
	"c": {"walk": true, "zone": "Pegunungan Abu - lereng", "rate": 0.17, "table": "abu_lereng"},
	"L": {"walk": false, "zone": ""},
	"K": {"walk": true, "zone": "Pos Pemburu", "portal": "pos"},
	"N": {"walk": true, "zone": "Kawah Lahar", "boss": "lahar"},
	"R": {"walk": true, "zone": "Jalan Lahar", "gate": "lahar",
		"locked": "Aliran lahar menutup jalan ke timur. Mustahil diseberangi."},
	"Z": {"walk": true, "zone": "Jalan ke Kastil Kelam", "scene": "kastil_bersambung"},
	"g": {"walk": true, "zone": ""},
	"h": {"walk": false, "zone": ""},
	"I": {"walk": false, "zone": ""},
	"Y": {"walk": false, "zone": ""},
	"X": {"walk": true, "zone": "", "portal": "@exit"},  # tujuan = "exit" milik peta ini
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
	return MAPS[map_id].has("exit")


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
