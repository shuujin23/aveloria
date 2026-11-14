extends SceneTree
## Uji rarity perlengkapan dan aturan side quest tanpa tampilan.
##   Godot_console.exe --headless --path . -s res://scripts/tests/quest_test.gd

var _failed := false


func _initialize() -> void:
	var game: Node = root.get_node("Game")
	game.save_path = "user://test_save.json"
	game.new_game()
	var arlen: Battler = game.party[0]

	# --- rarity: stat, harga, peluang sifat ---
	_expect(Db.gear_stats("arlen_weapon_1", 0, "common") == {"atk": 3} and Db.gear_stats("arlen_weapon_1", 0, "rare") == {"atk": 4}
		and Db.gear_stats("arlen_weapon_1", 0, "ultra") == {"atk": 5}, "senjata tingkat 1: Common +3, Rare +4, Ultra Rare +5")
	var ordered := true
	for owner: String in Db.GEAR_NAMES:
		for slot: String in Db.GEAR_SLOTS:
			for tier in range(1, Db.GEAR_TIERS + 1):
				var id := Db.gear_id(owner, slot, tier)
				for plus in [0, 3, 5]:
					for stat_name: String in Db.gear_stats(id, plus, "common"):
						var common := int(Db.gear_stats(id, plus, "common")[stat_name])
						var rare := int(Db.gear_stats(id, plus, "rare")[stat_name])
						var ultra := int(Db.gear_stats(id, plus, "ultra")[stat_name])
						ordered = ordered and rare > common and ultra > rare
	_expect(ordered, "di semua barang dan tingkat tempa: Ultra Rare > Rare > Common untuk tiap stat")
	_expect(Db.gear_price("arlen_weapon_1", "common") == 40 and Db.gear_price("arlen_weapon_1", "rare") == 100, "Rare dijual 2,5x harga Common (40 -> 100)")
	_expect(Db.trait_gain_chance(1, "rare") > Db.trait_gain_chance(1, "common") and is_equal_approx(Db.trait_gain_chance(5, "rare"), 1.0),
		"Rare lebih berpeluang mendapat sifat saat ditempa")
	_expect(Db.SHOP_RARITIES == ["common", "rare"], "pandai besi hanya menjual Common dan Rare")

	# --- membeli ---
	game.gold = 500
	var base_atk := arlen.atk
	_expect(game.buy_gear("arlen_weapon_1") and arlen.atk == base_atk + 3 and game.gold == 460, "membeli Common")
	_expect(not game.buy_gear("arlen_weapon_1", "common"), "Common yang sama ditolak")
	_expect(game.buy_gear("arlen_weapon_1", "rare") and arlen.atk == base_atk + 4 and game.gold == 360 and Db.gear_rarity(arlen.equip["weapon"]) == "rare",
		"naik dari Common ke Rare di tingkat yang sama diizinkan")
	_expect(not game.buy_gear("arlen_weapon_1", "common") and not game.buy_gear("arlen_weapon_1", "rare"), "setelah memakai Rare, Common dan Rare yang sama ditolak")
	_expect(Db.gear_label(arlen.equip["weapon"]).contains("[Rare]") and not Db.gear_title(arlen.equip["weapon"]).contains("["), "label barang menyebut rarity-nya")

	# --- hadiah quest: tingkat tempa ikut pindah, Ultra Rare membawa sifat ---
	arlen.equip["weapon"]["plus"] = 2
	var entry: Dictionary = game.grant_gear(arlen, "weapon", 1, "ultra")
	_expect(entry.rarity == "ultra" and int(entry.plus) == 2 and Db.trait_pool(entry.id).has(entry["trait"]), "hadiah Ultra Rare: tingkat tempa lama ikut, langsung punya sifat")
	_expect(arlen.atk == base_atk + int(Db.gear_stats("arlen_weapon_1", 2, "ultra")["atk"]), "stat tokoh memakai angka Ultra Rare")
	_expect(game.gear_block("arlen_weapon_1", "rare") != "", "setelah memakai Ultra Rare, Rare tingkat yang sama ditolak")
	_expect(game.gear_block("arlen_weapon_2", "common") != Loc.t("Sudah memakai yang setara atau lebih baik."), "tingkat yang lebih tinggi tetap boleh dibeli")

	# --- simpan dan muat rarity ---
	game.save_game()
	game.new_game()
	_expect(game.load_game() and Db.gear_rarity(game.party[0].equip["weapon"]) == "ultra", "rarity ikut tersimpan")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 3, "party": [{"id": "arlen", "level": 3, "xp": 0, "hp": 20, "mp": 5,
		"equip": {"weapon": {"id": "arlen_weapon_1", "plus": 1, "trait": ""}, "body": {"id": "arlen_body_1", "plus": 0, "trait": "", "rarity": "palsu"}}}],
		"gold": 0, "wins": 0, "flags": [], "items": {}, "bag_slots": 6, "map": "desa", "tile": [7, 10], "respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	_expect(game.load_game() and Db.gear_rarity(game.party[0].equip["weapon"]) == "common" and Db.gear_rarity(game.party[0].equip["body"]) == "common",
		"barang lama tanpa rarity (atau rarity tak dikenal) dimuat sebagai Common")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))

	# --- keadaan quest ---
	var flags := {}
	_expect(Quests.state("perampok", flags) == "locked" and Quests.steps_for("gatot", "Garrick", flags).is_empty(), "sebelum Mira bergabung quest Garrick belum ditawarkan")
	flags["mira_joined"] = true
	_expect(Quests.state("perampok", flags) == "available" and Quests.open_offers(flags) == 1, "setelah Mira bergabung quest bisa diterima")
	var offer := Quests.steps_for("gatot", "Garrick", flags)
	_expect(offer.any(func(step: Dictionary) -> bool: return step.get("flag", "") == "q_perampok"), "bicara dengan Garrick menerima quest")
	_expect(Quests.steps_for("sari", "Marla", flags).is_empty(), "NPC lain tidak memberi quest")
	flags["q_perampok"] = true
	_expect(Quests.state("perampok", flags) == "active" and Quests.steps_for("gatot", "Garrick", flags).size() == 1, "quest berjalan: Garrick hanya mengingatkan")
	_expect(Quests.journal(flags) == [{"id": "perampok", "state": "active"}], "daftar quest memuat quest yang berjalan")
	flags["goblin_kepala"] = true
	var thanks := Quests.steps_for("gatot", "Garrick", flags)
	_expect(Quests.state("perampok", flags) == "won"
		and thanks.any(func(step: Dictionary) -> bool: return step.get("do", "") == "reward_gear" and step.rarity == "ultra" and int(step.tier) == 1)
		and thanks.any(func(step: Dictionary) -> bool: return step.get("do", "") == "gold" and int(step.amount) == 60), "penjaga kalah: Garrick memberi senjata Ultra Rare dan emas")
	flags["q_perampok_done"] = true
	_expect(Quests.state("perampok", flags) == "done" and Quests.steps_for("gatot", "Garrick", flags).is_empty(), "quest selesai: tidak ada dialog quest lagi")
	flags = {"mira_joined": true, "selene_joined": true, "kael_joined": true}
	_expect(Quests.open_offers(flags) == 3, "tiga quest tersedia setelah semua rekan bergabung")
	for id: String in Quests.LIST:
		var q: Dictionary = Quests.LIST[id]
		var group: Array = Db.BOSSES[q.boss]
		var elite: Dictionary = Db.ENEMIES[q.boss]
		_expect(group.has(q.boss) and elite.get("boss", false) and Db.rarity_of(q.boss) == "super" and Db.region_of(q.boss) == int(q.reward.tier),
			"%s: penjaga %s adalah elite wilayah %d yang tidak bisa ditinggal kabur" % [q.name, elite.name, int(q.reward.tier)])
	# Tempat quest ada di peta dan cocok dengan datanya.
	for spot: Array in [["dunia", "1", "perampok"], ["dunia", "2", "roh_tua"], ["abu", "3", "golem_purba"]]:
		_expect(WorldMap.find_in(spot[0], spot[1]).x >= 0 and WorldMap.TILES[spot[1]].quest == spot[2]
			and WorldMap.TILES[spot[1]].zone == Quests.LIST[spot[2]].place, "tempat quest %s ada di peta %s" % [spot[2], spot[0]])

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
