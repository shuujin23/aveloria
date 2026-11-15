extends SceneTree
## Uji skill tree: data cabang, poin jurus, membuka jurus, susunan 4 jurus, atur ulang, dan simpan/muat.
##   Godot_console.exe --headless --path . -s res://scripts/tests/skill_test.gd

var _failed := false


func _initialize() -> void:
	var game: Node = root.get_node("Game")
	game.save_path = "user://test_save.json"
	game.new_game()

	# --- data skill tree ---
	for char_id: String in Db.CHARACTERS:
		var tree: Array = Db.SKILL_TREES[char_id]
		var all: Array = []
		var total_cost := 0
		for branch: Dictionary in tree:
			all.append_array(branch.skills)
		for skill_id: String in all:
			total_cost += Db.unlock_cost(char_id, skill_id)
		var known := all.all(func(skill_id: String) -> bool: return Db.SKILLS.has(skill_id) and Db.SKILL_FX.has(skill_id) and Db.SKILLS[skill_id].desc != "")
		var unique := all.size() == 8
		for skill_id: String in all:
			unique = unique and all.count(skill_id) == 1
		var pref: Array = Db.CHARACTERS[char_id].pref
		_expect(tree.size() == 3 and known and unique and pref.size() == 8 and all.all(func(skill_id: String) -> bool: return pref.has(skill_id)),
			"%s: tiga cabang, 8 jurus berbeda yang semuanya punya data, animasi, dan urutan prioritas" % char_id)
		_expect(total_cost == 14, "%s: seluruh tree berharga 14 poin (terbuka semua di level 15)" % char_id)
	var owners := {}
	for char_id: String in Db.SKILL_TREES:
		for branch: Dictionary in Db.SKILL_TREES[char_id]:
			for skill_id: String in branch.skills:
				owners[skill_id] = owners.get(skill_id, 0) + 1
	_expect(owners.values().all(func(count: int) -> bool: return count == 1), "tidak ada jurus yang dimiliki dua tokoh")
	_expect(Db.unlock_cost("arlen", "tebasan_kuat") == 0 and Db.unlock_cost("arlen", "tebasan_berputar") == 2
		and Db.unlock_cost("arlen", "hantaman_penghancur") == 3 and Db.unlock_cost("arlen", "pasang_badan") == 1, "biaya = urutan di cabang; jurus awal gratis")
	_expect(Db.skill_prereq("arlen", "hantaman_penghancur") == "tebasan_berputar" and Db.skill_prereq("arlen", "pekik_perang") == "", "jurus dibuka berurutan dalam cabangnya")

	# --- tokoh baru ---
	var arlen: Battler = game.party[0]
	_expect(arlen.unlocked == ["tebasan_kuat"] and arlen.skills == ["tebasan_kuat"] and arlen.skill_points_left() == 0, "Arlen level 1: hanya jurus awal, belum ada poin jurus")
	_expect(not arlen.can_unlock("pasang_badan") and game.skill_block(arlen, "pasang_badan") != "", "tanpa poin, jurus tidak bisa dibuka")
	arlen.gain_xp(Db.xp_to_next(1))
	_expect(arlen.level == 2 and arlen.skill_points_left() == 1 and arlen.skills == ["tebasan_kuat"], "naik level memberi 1 poin jurus, tetapi tidak membuka jurus sendiri")
	_expect(game.skill_block(arlen, "tebasan_berputar") != "" and not arlen.unlock("tebasan_berputar"), "jurus berharga 2 poin belum terjangkau dengan 1 poin")
	_expect(game.skill_block(arlen, "tebasan_pelumpuh") != "", "jurus kedua di cabang ditolak kalau jurus pertamanya belum dibuka")
	_expect(arlen.unlock("pasang_badan") and arlen.skill_points_left() == 0 and arlen.skills == ["tebasan_kuat", "pasang_badan"],
		"membuka jurus memakai poin dan langsung membawanya kalau susunan belum penuh")
	_expect(not arlen.unlock("pasang_badan") and not arlen.unlock("bola_api"), "jurus yang sudah terbuka atau milik tokoh lain ditolak")

	# --- susunan paling banyak 4 ---
	var mira := Battler.from_character("mira", 15)
	_expect(mira.skill_points_total() == 14 and mira.unlocked.size() == 6 and mira.skills.size() == Db.SKILL_SLOTS,
		"Mira bergabung di level 15: enam jurus bawaan terbuka, empat yang dibawa")
	_expect(mira.skills == ["pulih", "pulih_massal", "berkat_suci", "cahaya_suci"], "susunan otomatis mengikuti urutan prioritas tokoh")
	_expect(mira.unlock("sinar_penghakiman") and not mira.skills.has("sinar_penghakiman"), "jurus yang dibuka saat susunan penuh tidak langsung dibawa")
	_expect(not game.toggle_loadout(mira, "sinar_penghakiman"), "susunan penuh: jurus kelima ditolak")
	_expect(game.toggle_loadout(mira, "cahaya_suci") and mira.skills.size() == 3 and game.toggle_loadout(mira, "sinar_penghakiman")
		and mira.skills == ["pulih", "pulih_massal", "berkat_suci", "sinar_penghakiman"], "melepas satu jurus lalu membawa jurus lain (swap)")
	_expect(not game.toggle_loadout(mira, "penyucian"), "jurus yang belum terbuka tidak bisa dibawa")
	for skill_id: String in ["pulih_massal", "berkat_suci", "sinar_penghakiman"]:
		game.toggle_loadout(mira, skill_id)
	_expect(mira.skills == ["pulih"] and not game.toggle_loadout(mira, "pulih"), "minimal satu jurus harus tetap dibawa")
	var joiner := Battler.from_character("kael", 10)
	_expect(joiner.unlocked.size() == 5 and joiner.skill_points_left() == 3, "Kael bergabung di level 10: lima jurus bawaan, tiga poin tersisa untuk dipilih pemain")

	# --- jurus baru bekerja di mesin battle ---
	var knight := Battler.from_character("arlen", 15)
	var dummy := Battler.from_enemy("golem_batu")
	var eng := BattleEngine.new([knight], [dummy])
	knight.statuses["slow"] = 3
	knight.statuses["poison"] = 3
	eng.execute({"actor": knight, "kind": "skill", "skill": "tekad_baja"})
	_expect(not knight.has_status("slow") and not knight.has_status("poison") and knight.has_status("immunity"), "Tekad Baja: nerf hilang dan Arlen menjadi Kebal")
	var bats := [Battler.from_enemy("kelelawar", " A"), Battler.from_enemy("kelelawar", " B")]
	var crowd := BattleEngine.new([knight], bats)
	crowd.execute({"actor": knight, "kind": "skill", "skill": "pekik_gentar"})
	_expect((bats[0] as Battler).has_status("attack_break") and (bats[1] as Battler).has_status("attack_break"), "Pekik Gentar: ATK Runtuh pada semua musuh")
	var priest := Battler.from_character("mira", 15)
	var cleanse := BattleEngine.new([priest, knight], [dummy])
	knight.statuses.clear()
	knight.statuses["burn"] = 3
	cleanse.execute({"actor": priest, "kind": "skill", "skill": "penyucian", "target": knight})
	_expect(knight.statuses.is_empty(), "Penyucian: nerf rekan hilang tanpa memberi efek lain")
	var mage := Battler.from_character("selene", 15)
	var duel := BattleEngine.new([mage], [dummy])
	dummy.hp = dummy.max_hp
	duel.execute({"actor": mage, "kind": "skill", "skill": "meteor", "target": dummy})
	var meteor_damage := dummy.max_hp - dummy.hp
	dummy.hp = dummy.max_hp
	duel.execute({"actor": mage, "kind": "skill", "skill": "bola_api", "target": dummy})
	_expect(meteor_damage > dummy.max_hp - dummy.hp, "Meteor lebih kuat daripada Bola Api (%d > %d)" % [meteor_damage, dummy.max_hp - dummy.hp])

	# --- atur ulang ---
	game.gold = 0
	game.map_id = "desa"
	_expect(game.skill_respec_block(arlen) != "" and not game.respec_skills(arlen), "atur ulang jurus ditolak kalau emas kurang")
	game.gold = 500
	game.map_id = "gua"
	_expect(not game.respec_skills(arlen), "atur ulang jurus ditolak di luar permukiman")
	game.map_id = "desa"
	_expect(game.respec_skills(arlen) and arlen.unlocked == ["tebasan_kuat"] and arlen.skills == ["tebasan_kuat"] and arlen.skill_points_left() == 1
		and game.gold == 500 - Db.RESPEC_GOLD * arlen.level, "atur ulang jurus: poin kembali, hanya jurus awal yang tersisa, emas terpotong")
	_expect(game.skill_respec_block(arlen) != "", "tidak ada yang bisa diatur ulang kalau hanya jurus awal yang terbuka")

	# --- simpan dan muat ---
	arlen.unlock("pekik_perang")
	game.party.append(mira)
	mira.loadout = ["salur_jiwa", "pulih"]
	mira.skills = mira.loadout.duplicate()
	game.save_game()
	game.new_game()
	_expect(game.load_game(), "simpanan dengan skill tree bisa dimuat")
	_expect((game.party[0] as Battler).unlocked == ["tebasan_kuat", "pekik_perang"] and (game.party[0] as Battler).skills == ["tebasan_kuat", "pekik_perang"],
		"jurus yang dibuka Arlen kembali seperti saat disimpan")
	_expect((game.party[1] as Battler).unlocked.size() == 7 and (game.party[1] as Battler).skills == ["salur_jiwa", "pulih"], "susunan jurus Mira kembali, termasuk urutannya")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 3, "party": [{"id": "arlen", "level": 2, "xp": 0, "hp": 20, "mp": 5,
		"unlocked": ["hantaman_penghancur", "tebasan_berputar", "pasang_badan", "bola_api"], "loadout": ["hantaman_penghancur", "bola_api", "pasang_badan"]}],
		"gold": 0, "wins": 0, "flags": [], "items": {}, "bag_slots": 6, "map": "desa", "tile": [7, 10], "respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	var cheat: Battler = null
	if game.load_game():
		cheat = game.party[0]
	_expect(cheat != null and cheat.skill_points_left() >= 0 and not cheat.unlocked.has("hantaman_penghancur") and not cheat.unlocked.has("bola_api")
		and cheat.skills.all(func(skill_id: String) -> bool: return cheat.unlocked.has(skill_id)), "simpanan dengan jurus berlebih: yang tidak terjangkau poin dibuang")
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 3, "party": [{"id": "mira", "level": 7, "xp": 0, "hp": 20, "mp": 5}],
		"gold": 0, "wins": 0, "flags": [], "items": {}, "bag_slots": 6, "map": "desa", "tile": [7, 10], "respawn_map": "desa", "respawn_tile": [7, 10]}))
	file.close()
	_expect(game.load_game() and (game.party[0] as Battler).unlocked == ["pulih", "doa_pelindung", "cahaya_suci", "berkat_suci", "pulih_massal"]
		and (game.party[0] as Battler).skills.size() == 4, "simpanan lama tanpa skill tree: jurus yang dulu dipelajari lewat level tetap terbuka")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
