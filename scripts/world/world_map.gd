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
#   Q sarang Ratu Laba-laba   P Celah Abu (terbuka setelah Ratu kalah)   E ujung jalan (bersambung)
# Peta desa/dusun:
#   g rumput (aman)  h rumah    I penginapan   Y pohon   X jalan keluar ke peta dunia
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
	"desa": {
		"name": "Desa Rindu", "outside": "Y", "spawn": Vector2i(7, 11),
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
	# mist = true: rumput dan pepohonan memakai warna Hutan Kabut.
	"dusun": {
		"name": "Dusun Embun", "outside": "Y", "spawn": Vector2i(7, 6), "mist": true,
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
	"E": {"walk": true, "zone": "Jalan ke Pegunungan Abu", "scene": "abu_bersambung"},
	"g": {"walk": true, "zone": ""},
	"h": {"walk": false, "zone": ""},
	"I": {"walk": false, "zone": ""},
	"Y": {"walk": false, "zone": ""},
	"X": {"walk": true, "zone": "", "portal": "dunia"},
}

## Peta yang sedang aktif; diatur scene peta dari Game.map_id.
static var current := "dunia"


static func rows() -> Array:
	return MAPS[current].rows


static func map_name() -> String:
	return MAPS[current].name


static func outside() -> String:
	return MAPS[current].outside


## Peta bernuansa Hutan Kabut (warna rumput dan pohon berbeda).
static func is_mist() -> bool:
	return MAPS[current].get("mist", false)


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
