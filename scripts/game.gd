extends Node
## Autoload "Game": keadaan permainan yang bertahan antar-scene (party, emas, progres, posisi),
## serta simpan/muat ke file.

const TITLE_SCENE := "res://scenes/title.tscn"
const WORLD_SCENE := "res://scenes/world.tscn"
const BATTLE_SCENE := "res://scenes/battle.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"
const START_MAP := "desa"
const START_TILE := Vector2i(7, 10)  # di depan penginapan; juga titik kembali setelah kalah
const SAVE_VERSION := 2  # versi 1 (sebelum perlengkapan) tetap bisa dimuat

var party: Array = []
var gold := 0
var wins := 0
var flags := {}  # penanda progres, mis. {"ogre": true} setelah semi-bos kalah
var items := {}  # isi tas: id barang (lihat Db.ITEMS) -> jumlah
var bag_slots := Db.BAG_START  # kapasitas tas; bisa diperbesar di toko
var mats := {}  # kantong bahan tempa: id bahan (lihat Db.MATERIALS) -> jumlah; tanpa batas

var map_id := START_MAP
var player_tile := START_TILE
var respawn_map := START_MAP  # tempat kembali setelah kalah: penginapan terakhir yang diinapi
var respawn_tile := START_TILE
var encounter: Array = []  # id monster untuk battle berikutnya
var backdrop := "lembah"  # latar battle berikutnya: lembah, hutan, kabut, gua
var after_battle_scene := ""  # adegan cerita yang dimainkan kalau battle itu dimenangkan
var pending_scene := ""  # adegan cerita yang dimainkan begitu peta terbuka
var world_message := ""  # pesan singkat yang ditampilkan saat kembali ke peta

## Lokasi file simpanan (satu slot). Di Windows: %APPDATA%\Godot\app_userdata\Aveloria\save.json.
## Uji otomatis menggantinya supaya tidak menimpa simpanan pemain.
var save_path := "user://save.json"


func _ready() -> void:
	new_game()


func new_game() -> void:
	party = Db.new_party()
	gold = 0
	wins = 0
	flags = {}
	items = Db.START_ITEMS.duplicate()
	bag_slots = Db.BAG_START
	mats = {}
	map_id = START_MAP
	player_tile = START_TILE
	respawn_map = START_MAP
	respawn_tile = START_TILE
	encounter = []
	after_battle_scene = ""
	pending_scene = "intro"
	world_message = ""


func avg_level() -> float:
	var total := 0
	for m: Battler in party:
		total += m.level
	return float(total) / max(1, party.size())


func rest() -> void:
	for m: Battler in party:
		m.full_restore()


## Menginap: pulihkan party dan jadikan tempat ini titik kembali setelah kalah.
func rest_at_inn() -> void:
	rest()
	respawn_map = map_id
	respawn_tile = player_tile


## Tokoh baru masuk party pada level yang sama dengan anggota pertama.
func join(char_id: String) -> void:
	for m: Battler in party:
		if m.id == char_id:
			return
	party.append(Battler.from_character(char_id, (party[0] as Battler).level))


func start_battle(enemy_ids: Array, battle_backdrop: String = "lembah", after_scene: String = "") -> void:
	encounter = enemy_ids
	backdrop = battle_backdrop
	after_battle_scene = after_scene
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Kembali ke peta. won = battle dimenangkan, sehingga adegan lanjutannya (kalau ada) dimainkan.
func return_to_world(message: String = "", won: bool = false) -> void:
	encounter = []
	world_message = message
	pending_scene = after_battle_scene if won else ""
	after_battle_scene = ""
	get_tree().change_scene_to_file(WORLD_SCENE)


## Kalah: party dipulihkan, kembali ke penginapan terakhir, emas tinggal setengah.
func defeat_to_respawn() -> void:
	rest()
	gold = gold / 2
	map_id = respawn_map
	player_tile = respawn_tile
	return_to_world(Loc.t("Party siuman di penginapan. Separuh emas hilang di perjalanan..."))


# ---------------------------------------------------------------- tas

func slots_used() -> int:
	return Db.stacks_of(items).size()


## Apakah satu barang lagi masih muat (di slot sejenis yang belum penuh, atau di slot kosong).
func can_add(item_id: String) -> bool:
	var after := items.duplicate()
	after[item_id] = int(after.get(item_id, 0)) + 1
	return Db.stacks_of(after).size() <= bag_slots


func add_item(item_id: String) -> bool:
	if not can_add(item_id):
		return false
	items[item_id] = int(items.get(item_id, 0)) + 1
	return true


func remove_item(item_id: String) -> void:
	items[item_id] = int(items.get(item_id, 0)) - 1
	if items[item_id] <= 0:
		items.erase(item_id)


## Perbesar tas kalau emas cukup dan belum maksimal.
func upgrade_bag() -> bool:
	var price := Db.bag_upgrade_price(bag_slots)
	if price < 0 or gold < price:
		return false
	gold -= price
	bag_slots = min(Db.BAG_MAX, bag_slots + Db.BAG_STEP)
	return true


# ---------------------------------------------------------------- perlengkapan dan bahan

func member(char_id: String) -> Battler:
	for m: Battler in party:
		if m.id == char_id:
			return m
	return null


func add_mats(drops: Dictionary) -> void:
	for mat_id: String in drops:
		mats[mat_id] = int(mats.get(mat_id, 0)) + int(drops[mat_id])


## Apakah emas dan bahan cukup untuk sebuah biaya {"gold", "mats"}.
func can_pay(cost: Dictionary) -> bool:
	if cost.is_empty() or gold < int(cost.gold):
		return false
	for mat_id: String in cost.mats:
		if int(mats.get(mat_id, 0)) < int(cost.mats[mat_id]):
			return false
	return true


func _pay(cost: Dictionary) -> void:
	gold -= int(cost.gold)
	for mat_id: String in cost.mats:
		mats[mat_id] = int(mats.get(mat_id, 0)) - int(cost.mats[mat_id])
		if mats[mat_id] <= 0:
			mats.erase(mat_id)


## Alasan sebuah perlengkapan tidak bisa dibeli; kosong kalau bisa.
func gear_block(gear_id: String) -> String:
	var g := Db.gear(gear_id)
	var m := member(g.owner)
	if m == null:
		return Loc.t("%s belum bergabung.") % Loc.t(Db.CHARACTERS[g.owner].name)
	if m.equip.has(g.slot) and int(Db.gear(m.equip[g.slot].id).tier) >= int(g.tier):
		return Loc.t("Sudah memakai yang setara atau lebih baik.")
	if gold < int(g.price):
		return Loc.t("Emas belum cukup.")
	return ""


## Beli perlengkapan dan langsung pakai; barang lama di slot itu tergantikan.
func buy_gear(gear_id: String) -> bool:
	if gear_block(gear_id) != "":
		return false
	var g := Db.gear(gear_id)
	var m := member(g.owner)
	gold -= int(g.price)
	m.equip[g.slot] = {"id": gear_id, "plus": 0, "trait": ""}
	m.recalc()
	return true


## Tempa satu tingkat. Mengembalikan {"ok", "trait"}: trait = sifat yang baru didapat ("" kalau tidak dapat).
func enhance(m: Battler, slot: String) -> Dictionary:
	if not m.equip.has(slot):
		return {"ok": false, "trait": ""}
	var entry: Dictionary = m.equip[slot]
	var cost := Db.enhance_cost(entry.id, int(entry.plus))
	if not can_pay(cost):
		return {"ok": false, "trait": ""}
	_pay(cost)
	entry.plus = int(entry.plus) + 1
	var gained := ""
	if entry["trait"] == "" and randf() < float(Db.TRAIT_GAIN_CHANCE[int(entry.plus) - 1]):
		var pool := Db.trait_pool(entry.id)
		gained = pool[randi() % pool.size()]
		entry["trait"] = gained
	m.recalc()
	return {"ok": true, "trait": gained}


## Alasan sebuah perlengkapan tidak bisa ditempa ulang; kosong kalau bisa.
func reforge_block(m: Battler, slot: String) -> String:
	if not m.equip.has(slot):
		return Loc.t("Slot ini kosong.")
	var entry: Dictionary = m.equip[slot]
	if entry["trait"] == "":
		return Loc.t("Belum punya sifat. Sifat didapat saat menempa.")
	if Db.trait_pool(entry.id).size() < 2:
		return Loc.t("Perlengkapan ini hanya punya satu macam sifat.")
	if not can_pay(Db.reforge_cost(entry.id)):
		return Loc.t("Emas atau bahan belum cukup.")
	return ""


## Tempa ulang: acak sifat menjadi sifat lain; tingkat tempa tetap. Mengembalikan sifat barunya ("" kalau gagal).
func reforge(m: Battler, slot: String) -> String:
	if reforge_block(m, slot) != "":
		return ""
	var entry: Dictionary = m.equip[slot]
	_pay(Db.reforge_cost(entry.id))
	var pool := Db.trait_pool(entry.id).duplicate()
	pool.erase(entry["trait"])
	entry["trait"] = pool[randi() % pool.size()]
	return entry["trait"]


## Jual satu bahan ke pandai besi.
func sell_mat(mat_id: String) -> bool:
	if int(mats.get(mat_id, 0)) <= 0:
		return false
	mats[mat_id] -= 1
	if mats[mat_id] <= 0:
		mats.erase(mat_id)
	gold += int(Db.MATERIALS[mat_id].sell)
	return true


# ---------------------------------------------------------------- simpan dan muat

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Simpan keadaan saat ini ke file. Mengembalikan false kalau file tidak bisa ditulis.
func save_game() -> bool:
	var members: Array = []
	for m: Battler in party:
		members.append({"id": m.id, "level": m.level, "xp": m.xp, "hp": m.hp, "mp": m.mp, "equip": m.equip})
	var data := {
		"version": SAVE_VERSION,
		"party": members,
		"gold": gold,
		"wins": wins,
		"flags": flags.keys(),
		"items": items,
		"bag_slots": bag_slots,
		"mats": mats,
		"map": map_id,
		"tile": [player_tile.x, player_tile.y],
		"respawn_map": respawn_map,
		"respawn_tile": [respawn_tile.x, respawn_tile.y],
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Gagal menulis simpanan: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


## Ringkasan simpanan untuk layar judul, mis. "Arlen Lv 4 · Lembah Hijau". Kosong kalau tidak ada.
func save_summary() -> String:
	var data := _read_save()
	if data.is_empty():
		return ""
	var members: Array = data.get("party", [])
	if members.is_empty():
		return ""
	var lead: Dictionary = members[0]
	var place: String = WorldMap.MAPS.get(data.get("map", ""), {}).get("name", "?")
	return Loc.t("%s Lv %d  ·  %d anggota  ·  %s") % [Db.CHARACTERS[lead.id].name, int(lead.level), members.size(), Loc.t(place)]


## Muat simpanan. Mengembalikan false (dan tidak mengubah apa pun) kalau file tidak ada atau rusak.
func load_game() -> bool:
	var data := _read_save()
	if data.is_empty():
		return false
	var loaded: Array = []
	for entry: Variant in data.get("party", []):
		if not (entry is Dictionary) or not Db.CHARACTERS.has(entry.get("id", "")):
			continue
		var m := Battler.from_character(entry.id, max(1, int(entry.get("level", 1))))
		var saved_equip: Variant = entry.get("equip", {})
		if saved_equip is Dictionary:
			for slot: Variant in saved_equip:
				var piece: Variant = saved_equip[slot]
				if not (piece is Dictionary) or not Db.GEAR_SLOTS.has(slot) or not Db.has_gear(str(piece.get("id", ""))):
					continue
				var g := Db.gear(piece.id)
				if g.owner != m.id or g.slot != slot:
					continue
				var status_id := str(piece.get("trait", ""))
				m.equip[slot] = {"id": String(piece.id), "plus": clampi(int(piece.get("plus", 0)), 0, Db.ENHANCE_MAX),
					"trait": status_id if Db.trait_pool(piece.id).has(status_id) else ""}
			m.recalc()
		m.xp = max(0, int(entry.get("xp", 0)))
		m.hp = clampi(int(entry.get("hp", m.max_hp)), 1, m.max_hp)
		m.mp = clampi(int(entry.get("mp", m.max_mp)), 0, m.max_mp)
		loaded.append(m)
	if loaded.is_empty():
		return false

	party = loaded
	gold = max(0, int(data.get("gold", 0)))
	wins = max(0, int(data.get("wins", 0)))
	flags = {}
	for flag: Variant in data.get("flags", []):
		flags[String(flag)] = true
	bag_slots = clampi(int(data.get("bag_slots", Db.BAG_START)), Db.BAG_START, Db.BAG_MAX)
	items = {}
	var saved_items: Variant = data.get("items", {})
	if saved_items is Dictionary:
		for item_id: Variant in saved_items:
			if Db.ITEMS.has(item_id) and int(saved_items[item_id]) > 0:
				items[String(item_id)] = int(saved_items[item_id])
	mats = {}
	var saved_mats: Variant = data.get("mats", {})
	if saved_mats is Dictionary:
		for mat_id: Variant in saved_mats:
			if Db.MATERIALS.has(mat_id) and int(saved_mats[mat_id]) > 0:
				mats[String(mat_id)] = int(saved_mats[mat_id])
	map_id = data.get("map", START_MAP)
	var tile: Array = data.get("tile", [])
	player_tile = Vector2i(int(tile[0]), int(tile[1])) if tile.size() == 2 else START_TILE
	# Simpanan dari versi peta yang berbeda bisa menunjuk ke tempat yang sudah tidak ada.
	if not WorldMap.MAPS.has(map_id):
		map_id = START_MAP
		player_tile = START_TILE
	WorldMap.current = map_id
	if not WorldMap.is_walkable(player_tile, flags):
		map_id = START_MAP
		player_tile = START_TILE
	respawn_map = data.get("respawn_map", START_MAP)
	var saved_respawn: Array = data.get("respawn_tile", [])
	respawn_tile = Vector2i(int(saved_respawn[0]), int(saved_respawn[1])) if saved_respawn.size() == 2 else START_TILE
	if not WorldMap.MAPS.has(respawn_map):
		respawn_map = START_MAP
		respawn_tile = START_TILE
	encounter = []
	after_battle_scene = ""
	pending_scene = ""
	world_message = Loc.t("Permainan dimuat.")
	return true


func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var json := JSON.new()  # parse() mengembalikan kode error, tanpa mencetak error ke konsol
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return {}
	var parsed: Variant = json.data
	if not (parsed is Dictionary) or not (int(parsed.get("version", 0)) in [1, SAVE_VERSION]):
		return {}
	return parsed
