extends SceneTree
## Uji perlengkapan, tempa, sifat, drop, dan simpanan versi 2 tanpa tampilan.
##   Godot_console.exe --headless --path . -s res://scripts/tests/gear_test.gd

var _failed := false


func _initialize() -> void:
	await process_frame  # tunggu autoload siap
	var game: Node = root.get_node("Game")
	game.save_path = "user://test_save.json"
	game.new_game()
	game.join("mira")
	var arlen: Battler = game.member("arlen")
	var mira: Battler = game.member("mira")

	# --- Data ---
	var count := 0
	for hero_id: String in Db.GEAR_NAMES:
		for slot: String in Db.GEAR_SLOTS:
			for tier in range(1, Db.GEAR_TIERS + 1):
				var id := Db.gear_id(hero_id, slot, tier)
				var ok := Db.has_gear(id) and ResourceLoader.exists("res://assets/sprites/gear_%s.png" % id) \
					and not Db.gear_stats(id, 0).is_empty() and int(Db.gear(id).price) > 0
				if not ok:
					_expect(false, "perlengkapan %s lengkap (data, harga, ikon)" % id)
				count += 1
	_expect(count == 48, "48 perlengkapan: 4 tokoh x 4 slot x 3 tingkat")
	_expect(Db.gear_stats("arlen_weapon_1", 0) == {"atk": 3} and Db.gear_stats("mira_weapon_1", 0) == {"mag": 3},
		"senjata Arlen menambah ATK, senjata Mira menambah MAG")
	for mat_id: String in Db.MATERIALS:
		if not ResourceLoader.exists("res://assets/sprites/mat_%s.png" % mat_id):
			_expect(false, "ikon bahan %s ada" % mat_id)
	for enemy_id: String in Db.ENEMIES:
		var known := Db.ENEMY_CLASS.has(enemy_id) and ResourceLoader.exists("res://assets/sprites/monster_%s.png" % Db.ENEMIES[enemy_id].get("sprite", enemy_id))
		if not known:
			_expect(false, "monster %s punya kategori dan sprite" % enemy_id)
		elif Db.rarity_of(enemy_id) == "ultra" and not Db.ENEMIES[enemy_id].get("boss", false):
			_expect(false, "%s: hanya bos yang ultra rare" % enemy_id)
		elif Db.ENEMIES[enemy_id].get("boss", false) and not Db.rarity_of(enemy_id) in ["ultra", "super"]:
			_expect(false, "%s: bos dan penjaga quest berkategori ultra atau super rare" % enemy_id)
	for region in range(1, 5):
		for rarity: String in Db.RARITIES:
			if Db.material_id(region, rarity) == "":
				_expect(false, "bahan %s wilayah %d ada" % [rarity, region])
	_expect(Db.ENEMY_CLASS.size() == Db.ENEMIES.size(), "semua monster punya kategori (%d)" % Db.ENEMIES.size())

	# --- Beli ---
	game.gold = 30
	_expect(not game.buy_gear("arlen_weapon_1") and game.gold == 30, "tidak bisa membeli kalau emas kurang")
	game.gold = 1000
	var atk_before := arlen.atk
	_expect(game.buy_gear("arlen_weapon_1") and arlen.atk == atk_before + 3 and game.gold == 960,
		"membeli Pedang Besi: ATK +3, emas berkurang 40")
	_expect(not game.buy_gear("arlen_weapon_1"), "tidak bisa membeli barang yang setara dengan yang dipakai")
	_expect(not game.buy_gear("kael_weapon_1"), "tidak bisa membeli untuk tokoh yang belum bergabung")
	var hp_before := arlen.max_hp
	game.buy_gear("arlen_body_1")
	_expect(arlen.max_hp == hp_before + 5 and arlen.hp <= arlen.max_hp, "Zirah Besi menambah HP maksimum")

	# --- Tempa ---
	_expect(not game.enhance(arlen, "weapon").ok, "tidak bisa menempa tanpa bahan")
	game.mats = {"serat_liar": 50, "taring_serigala": 50, "lendir_emas": 50, "tanduk_ogre": 50}
	var gold_before: int = game.gold
	var result: Dictionary = game.enhance(arlen, "weapon")
	_expect(result.ok and int(arlen.equip["weapon"].plus) == 1 and game.gold == gold_before - 10 and game.mats["serat_liar"] == 48,
		"tempa ke +1: 10 emas dan 2 Serat Liar")
	for i in 4:
		game.enhance(arlen, "weapon")
	var sword: Dictionary = arlen.equip["weapon"]
	_expect(int(sword.plus) == 5 and arlen.atk == atk_before + 8, "+5: bonus ATK 3 menjadi 8 (%d)" % (arlen.atk - atk_before))
	for plus in range(1, 6):
		for id: String in ["arlen_weapon_1", "mira_head_1", "kael_body_2", "selene_feet_3"]:
			var key: String = Db.GEAR_PRIMARY[Db.gear(id).slot]
			var primary: String = Db.GEAR_MAIN_STAT[Db.gear(id).owner] if key == "main" else key
			if int(Db.gear_stats(id, plus)[primary]) <= int(Db.gear_stats(id, plus - 1)[primary]):
				_expect(false, "%s: stat andalan naik di +%d" % [id, plus])
	_expect(sword["trait"] != "" and Db.trait_pool(sword.id).has(sword["trait"]), "di +5 senjata pasti punya sifat (%s)" % Db.trait_text(sword))
	_expect(not game.enhance(arlen, "weapon").ok, "tidak bisa menempa melewati +5")
	_expect(game.mats["tanduk_ogre"] == 49 and game.mats["lendir_emas"] == 48, "+4 dan +5 memakai bahan super rare dan ultra rare")

	# --- Tempa ulang ---
	var old_trait: String = sword["trait"]
	var rerolled: String = game.reforge(arlen, "weapon")
	_expect(rerolled != "" and rerolled != old_trait and int(sword.plus) == 5, "tempa ulang mengganti sifat, tingkat tempa tetap")
	for i in 5:
		game.enhance(arlen, "body")
	_expect(arlen.equip["body"]["trait"] == "defense_up" and game.reforge_block(arlen, "body") != "",
		"zirah +5 bersifat DEF Naik dan tidak bisa ditempa ulang")

	# --- Jual bahan ---
	gold_before = game.gold
	_expect(game.sell_mat("taring_serigala") and game.gold == gold_before + 10, "menjual Taring Serigala: +10 emas")
	_expect(not game.sell_mat("benang_kabut"), "tidak bisa menjual bahan yang tidak dimiliki")

	# --- Sifat di battle ---
	sword["trait"] = "poison"
	var procs := 0
	for i in 400:
		var foe := Battler.from_enemy("goblin")
		var eng := BattleEngine.new([arlen], [foe])
		eng.execute({"actor": arlen, "kind": "attack", "target": foe})
		if foe.has_status("poison"):
			procs += 1
	_expect(procs > 90 and procs < 190, "sifat Racun +5 aktif sekitar 35%% serangan (%d/400)" % procs)
	procs = 0
	for i in 200:
		var foe := Battler.from_enemy("jamur")  # kebal racun
		var eng := BattleEngine.new([arlen], [foe])
		eng.execute({"actor": arlen, "kind": "attack", "target": foe})
		if foe.has_status("poison"):
			procs += 1
	_expect(procs == 0, "sifat senjata tidak menembus kekebalan monster")
	sword["trait"] = "attack_up"
	procs = 0
	for i in 400:
		var foe := Battler.from_enemy("goblin")
		var eng := BattleEngine.new([arlen], [foe])
		eng.execute({"actor": arlen, "kind": "attack", "target": foe})
		if arlen.has_status("attack_up") and not foe.has_status("attack_up"):
			procs += 1
	_expect(procs > 90 and procs < 190, "sifat ATK Naik mengenai pemakainya (%d/400)" % procs)
	procs = 0
	for i in 400:
		var foe := Battler.from_enemy("goblin")
		var eng := BattleEngine.new([arlen], [foe])
		arlen.hp = arlen.max_hp
		eng.execute({"actor": foe, "kind": "attack", "target": arlen})
		if arlen.has_status("defense_up"):
			procs += 1
	_expect(procs > 90 and procs < 190, "sifat zirah aktif saat terkena serangan (%d/400)" % procs)
	game.buy_gear("mira_feet_1")
	mira.equip["feet"]["trait"] = "speed_up"
	mira.equip["feet"].plus = 5
	procs = 0
	for i in 400:
		var eng := BattleEngine.new([mira], [Battler.from_enemy("goblin")])
		if mira.has_status("speed_up") and eng.opening_lines.size() == 2:
			procs += 1
	_expect(procs > 90 and procs < 190, "sifat sepatu aktif di awal pertarungan (%d/400)" % procs)
	arlen.reset_battle_state()
	mira.reset_battle_state()
	arlen.hp = arlen.max_hp

	# --- Drop ---
	var rng := RandomNumberGenerator.new()
	var boss_drop := Db.roll_drops("ogre", rng)
	_expect(boss_drop == {"tanduk_ogre": 3, "lendir_emas": 2, "taring_serigala": 3, "serat_liar": 4}, "Ogre menjatuhkan banyak bahan, termasuk ultra rare")
	_expect(Db.roll_drops("mata_kabut", rng) == {"lensa_kabut": 2, "bara_roh": 1}, "monster super rare pasti menjatuhkan bahan super rare")
	var got := 0
	for i in 1000:
		var drop := Db.roll_drops("jamur", rng)
		got += int(drop.get("serat_liar", 0))
		if drop.size() > 1 or (drop.size() == 1 and not drop.has("serat_liar")):
			_expect(false, "monster common hanya menjatuhkan bahan common")
	_expect(got > 520 and got < 680, "monster common menjatuhkan bahan sekitar 60%% (%d/1000)" % got)
	var eng2 := BattleEngine.new([arlen], [Battler.from_enemy("ogre")])
	_expect(eng2.grant_rewards().drops.has("tanduk_ogre"), "hadiah pertarungan memuat bahan")
	var supers := 0
	for i in 4000:
		var group := Db.random_group("lembah_padang", true)
		if group[0] == "lendir_emas":
			supers += 1
			if group.size() > 3:
				_expect(false, "kelompok dengan monster super rare paling banyak 3")
	_expect(supers > 200 and supers < 370, "monster super rare muncul sekitar 7%% (%d/4000)" % supers)
	_expect(not Db.random_group("lembah_padang").has("lendir_emas"), "tanpa izin, monster super rare tidak muncul")

	# --- Simpan dan muat ---
	sword["trait"] = "slow"  # sifat di luar daftar tingkatnya (dipasang paksa di atas) dibuang saat dimuat
	var snapshot := JSON.stringify([arlen.equip, mira.equip, game.mats])
	var stats := [arlen.max_hp, arlen.atk, arlen.defense]
	_expect(game.save_game(), "menyimpan")
	game.new_game()
	_expect(game.load_game(), "memuat")
	arlen = game.member("arlen")
	mira = game.member("mira")
	_expect(JSON.stringify([arlen.equip, mira.equip, game.mats]) == snapshot, "perlengkapan, tingkat tempa, sifat, dan bahan ikut tersimpan")
	_expect([arlen.max_hp, arlen.atk, arlen.defense] == stats, "stat setelah dimuat sama dengan sebelumnya")
	# Simpanan versi 1 (sebelum ada perlengkapan) tetap bisa dimuat.
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "party": [{"id": "arlen", "level": 7, "xp": 3, "hp": 20, "mp": 5}],
		"gold": 55, "wins": 9, "flags": ["quest_mira"], "items": {"ramuan": 3}, "bag_slots": 8, "map": "desa", "tile": [7, 10],
		"respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	_expect(game.load_game() and game.member("arlen").level == 7 and game.member("arlen").equip.is_empty() and game.mats.is_empty()
		and game.gold == 55, "simpanan versi 1 dimuat dengan perlengkapan dan kantong bahan kosong")
	# Simpanan versi 2 di peta wilayah (kini lebih luas): posisi lama tidak berlaku, kembali ke penginapan terakhir.
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 2, "party": [{"id": "arlen", "level": 9, "xp": 0, "hp": 30, "mp": 5}],
		"gold": 80, "wins": 20, "flags": ["quest_mira", "mira_joined", "ogre"], "items": {}, "bag_slots": 6, "map": "dunia", "tile": [30, 6],
		"respawn_map": "dusun", "respawn_tile": [8, 3]}))
	file.close()
	_expect(game.load_game() and game.map_id == "dusun" and game.player_tile == Vector2i(8, 3) and game.flags.has("ogre") and game.gold == 80,
		"simpanan versi 2 di peta wilayah: kembali ke penginapan terakhir, progres tetap")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 2, "party": [{"id": "arlen", "level": 9, "xp": 0, "hp": 30, "mp": 5}],
		"gold": 80, "wins": 20, "flags": ["mira_joined"], "items": {}, "bag_slots": 6, "map": "gua", "tile": [9, 11],
		"respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	_expect(game.load_game() and game.map_id == "gua" and game.player_tile == Vector2i(9, 11), "simpanan versi 2 di dalam dungeon: posisi tetap")
	game.save_game()
	_expect(game.load_game() and game.map_id == "gua", "simpanan versi 3 dimuat seperti biasa")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))

	# --- Pandai besi di tiap permukiman ---
	for pair: Array in [["gatot", 1], ["sena", 2], ["rekso", 3]]:
		var tier := 0
		for step: Dictionary in Story.talk(pair[0], {}, 0):
			if step.get("do", "") == "forge":
				tier = int(step.tier)
		_expect(tier == pair[1] and not Story.npc(pair[0]).is_empty(), "pandai besi %s menjual tingkat %d" % [pair[0], pair[1]])

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
