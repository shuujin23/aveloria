extends SceneTree
## Uji poin stat: jumlah per level, pengaruh tiap poin, atur ulang, dan simpan/muat.
##   Godot_console.exe --headless --path . -s res://scripts/tests/stat_test.gd

var _failed := false


func _initialize() -> void:
	var game: Node = root.get_node("Game")
	game.save_path = "user://test_save.json"
	game.new_game()
	var arlen: Battler = game.party[0]
	var per_level: int = Db.STAT_POINTS_PER_LEVEL

	# --- jumlah poin ---
	_expect(arlen.points_total() == 0 and arlen.points_left() == 0, "level 1 belum punya poin stat")
	_expect(not game.spend_point(arlen, "atk"), "tanpa poin, stat tidak bisa dinaikkan")
	arlen.gain_xp(Db.xp_to_next(1))
	_expect(arlen.level == 2 and arlen.points_left() == per_level, "naik level memberi %d poin" % per_level)
	arlen.level = 11
	arlen.recalc()
	arlen.full_restore()
	_expect(arlen.points_total() == 10 * per_level, "level 11: %d poin sejak awal" % arlen.points_total())
	_expect(Battler.from_character("selene", 8).points_left() == 7 * per_level, "tokoh yang bergabung di level 8 membawa poin yang belum dibagi")

	# --- pengaruh tiap poin ---
	var before := {"max_hp": arlen.max_hp, "max_mp": arlen.max_mp, "atk": arlen.atk, "defense": arlen.defense, "mag": arlen.mag, "agi": arlen.agi}
	var all_right := true
	for stat_name: String in Db.STAT_POINT_VALUE:
		all_right = all_right and game.spend_point(arlen, stat_name) and int(arlen.get(stat_name)) == int(before[stat_name]) + int(Db.STAT_POINT_VALUE[stat_name])
	_expect(all_right, "tiap poin menaikkan statnya sesuai Db.STAT_POINT_VALUE")
	_expect(arlen.points_spent() == 6 and arlen.points_left() == 10 * per_level - 6, "poin terpakai dan tersisa terhitung benar")
	_expect(not game.spend_point(arlen, "level"), "nama stat yang tidak dikenal ditolak")
	arlen.hp = 10
	arlen.mp = 1
	game.spend_point(arlen, "max_hp")
	game.spend_point(arlen, "max_mp")
	_expect(arlen.hp == 10 + int(Db.STAT_POINT_VALUE["max_hp"]) and arlen.mp == 1 + int(Db.STAT_POINT_VALUE["max_mp"]), "poin HP/MP juga menaikkan HP/MP saat ini")
	while arlen.points_left() > 0:
		game.spend_point(arlen, "atk")
	_expect(arlen.points_left() == 0 and not game.spend_point(arlen, "atk"), "poin tidak bisa dipakai melebihi jatah")
	var boosted_atk := arlen.atk
	arlen.gain_xp(Db.xp_to_next(11))
	_expect(arlen.level == 12 and arlen.atk > boosted_atk and arlen.points_left() == per_level, "naik level: stat dasar tetap naik sendiri dan poin lama tetap berlaku")

	# --- perlengkapan dan poin sama-sama dihitung ---
	var plain := Battler.from_character("arlen", 12).atk
	arlen.equip["weapon"] = {"id": "arlen_weapon_1", "plus": 0, "trait": ""}
	arlen.recalc()
	_expect(arlen.atk == plain + int(arlen.alloc["atk"]) + int(Db.gear_stats("arlen_weapon_1", 0)["atk"]), "ATK = dasar + poin + perlengkapan")

	# --- simpan dan muat ---
	var snapshot := JSON.stringify(arlen.alloc)
	var stats := [arlen.max_hp, arlen.max_mp, arlen.atk, arlen.defense, arlen.mag, arlen.agi]
	game.save_game()
	game.new_game()
	_expect(game.load_game(), "simpanan dengan poin stat bisa dimuat")
	arlen = game.party[0]
	_expect(JSON.stringify(arlen.alloc) == snapshot and [arlen.max_hp, arlen.max_mp, arlen.atk, arlen.defense, arlen.mag, arlen.agi] == stats,
		"pembagian poin dan stat kembali seperti saat disimpan")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 3, "party": [{"id": "arlen", "level": 3, "xp": 0, "hp": 20, "mp": 5, "alloc": {"atk": 99, "curang": 5}}],
		"gold": 0, "wins": 0, "flags": [], "items": {}, "bag_slots": 6, "map": "desa", "tile": [7, 10], "respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	_expect(game.load_game() and (game.party[0] as Battler).alloc.is_empty() and (game.party[0] as Battler).points_left() == 2 * per_level,
		"simpanan dengan poin berlebih: poin dikembalikan, bukan dipakai")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 3, "party": [{"id": "arlen", "level": 5, "xp": 0, "hp": 20, "mp": 5}],
		"gold": 0, "wins": 0, "flags": [], "items": {}, "bag_slots": 6, "map": "desa", "tile": [7, 10], "respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	_expect(game.load_game() and (game.party[0] as Battler).points_left() == 4 * per_level, "simpanan lama tanpa poin: semua poin sejak level 1 siap dibagi")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))

	# --- atur ulang ---
	arlen = game.party[0]
	_expect(game.respec_block(arlen) != "", "atur ulang ditolak kalau belum ada poin yang dibagi")
	game.spend_point(arlen, "agi")
	game.spend_point(arlen, "max_hp")
	arlen.full_restore()
	game.gold = 0
	game.map_id = "desa"
	_expect(game.respec_block(arlen) != "" and not game.respec(arlen), "atur ulang ditolak kalau emas kurang")
	game.gold = 500
	game.map_id = "dunia"
	_expect(game.respec_block(arlen) != "" and not game.respec(arlen), "atur ulang ditolak di luar permukiman")
	game.map_id = "desa"
	var price: int = game.respec_price(arlen)
	_expect(price == Db.RESPEC_GOLD * arlen.level and game.respec(arlen), "atur ulang di desa berhasil (harga %d emas)" % price)
	var fresh := Battler.from_character("arlen", 5)
	_expect(game.gold == 500 - price and arlen.alloc.is_empty() and arlen.points_left() == 4 * per_level
		and arlen.agi == fresh.agi and arlen.max_hp == fresh.max_hp and arlen.hp <= arlen.max_hp, "setelah atur ulang: emas terpotong, poin kembali, stat kembali ke dasar")

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
