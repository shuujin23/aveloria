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
		var known := true
		for skill_id: String in all:
			known = known and Db.SKILLS.has(skill_id) and Db.SKILLS[skill_id].desc != "" and (Db.is_passive(skill_id) or Db.SKILL_FX.has(skill_id))
		var shaped := true
		for branch: Dictionary in tree:
			var list: Array = branch.skills
			shaped = shaped and list.size() == 4 and Db.is_passive(list[3]) and not (Db.is_passive(list[0]) or Db.is_passive(list[1]) or Db.is_passive(list[2]))
		_expect(shaped, "%s: tiap cabang berisi tiga jurus aktif lalu satu jurus pasif" % char_id)
		var unique := all.size() == 12
		for skill_id: String in all:
			unique = unique and all.count(skill_id) == 1
		var pref: Array = Db.CHARACTERS[char_id].pref
		_expect(tree.size() == 3 and known and unique and pref.size() == 12 and all.all(func(skill_id: String) -> bool: return pref.has(skill_id)),
			"%s: tiga cabang, 12 jurus berbeda yang semuanya punya data, animasi (jurus aktif), dan urutan prioritas" % char_id)
		_expect(total_cost == 29, "%s: seluruh tree berharga 29 poin, jadi tidak semuanya bisa dibuka" % char_id)
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

	# --- tahap 2: mekanik baru ---
	var tank := Battler.from_character("arlen", 20)
	var healer := Battler.from_character("mira", 20)
	var wolves := [Battler.from_enemy("serigala", " A"), Battler.from_enemy("serigala", " B")]
	var field := BattleEngine.new([tank, healer], wolves)
	field.execute({"actor": tank, "kind": "skill", "skill": "tantang"})
	var drawn := 0
	for i in 60:
		if field.enemy_command(wolves[0]).target == tank:
			drawn += 1
	_expect(tank.has_status("taunt") and drawn == 60, "Tantang: selama aktif, semua serangan monster ke satu sasaran menuju Arlen")
	tank.statuses.erase("taunt")
	drawn = 0
	for i in 200:
		if field.enemy_command(wolves[0]).target == tank:
			drawn += 1
	_expect(drawn > 60 and drawn < 140, "tanpa Tantang, sasaran monster kembali acak (%d dari 200 ke Arlen)" % drawn)

	var caster := Battler.from_character("selene", 20)
	var stun_field := BattleEngine.new([caster], [Battler.from_enemy("golem_batu"), Battler.from_enemy("ogre")])
	var golem: Battler = stun_field.enemies[0]
	var ogre: Battler = stun_field.enemies[1]
	var log: Array = []
	stun_field.apply_status(golem, "stun", log)
	stun_field.apply_status(ogre, "stun", log)
	_expect(golem.has_status("stun") and not ogre.has_status("stun"), "Terpaku mengenai monster biasa, tetapi semi-bos kebal")
	stun_field.end_round()
	_expect(golem.has_status("stun"), "Terpaku tidak hilang oleh waktu")
	var caster_hp := caster.hp
	var skipped := stun_field.execute({"actor": golem, "kind": "attack", "target": caster})
	_expect(caster.hp == caster_hp and not golem.has_status("stun") and skipped.size() == 1, "monster yang Terpaku kehilangan satu giliran, lalu efeknya hilang")
	stun_field.execute({"actor": golem, "kind": "attack", "target": caster})
	_expect(caster.hp < caster_hp, "giliran berikutnya monster itu menyerang lagi")

	var archer := Battler.from_character("kael", 20)
	var range := BattleEngine.new([archer], [Battler.from_enemy("golem_batu")])
	var target: Battler = range.enemies[0]
	target.max_hp = 99999
	target.hp = 99999
	var volley := range.execute({"actor": archer, "kind": "skill", "skill": "panah_beruntun", "target": target})
	var hits := volley.filter(func(line: String) -> bool: return line.begins_with(target.display_name) and line.contains(" 1 ") == false and line.ends_with("."))
	_expect(hits.size() == 3, "Panah Beruntun mengenai tiga kali (%d pukulan)" % hits.size())

	healer.mp = healer.max_mp
	tank.hp = 0
	field.execute({"actor": healer, "kind": "skill", "skill": "kebangkitan", "target": tank})
	_expect(tank.hp == int(tank.max_hp * 0.4), "Kebangkitan membangkitkan rekan yang tumbang dengan 40%% HP (%d)" % tank.hp)
	var mp_before := healer.mp
	var nobody := field.execute({"actor": healer, "kind": "skill", "skill": "kebangkitan", "target": tank})
	_expect(tank.hp == int(tank.max_hp * 0.4) and nobody.has(Loc.t("Tidak ada rekan yang tumbang.")) and healer.mp < mp_before, "Kebangkitan tanpa rekan tumbang tidak berpengaruh")

	# --- tahap 2: jurus pasif ---
	var plain := Battler.from_character("arlen", 20)
	var bold := Battler.from_character("arlen", 20)
	bold.unlocked.append_array(["tebasan_berputar", "hantaman_penghancur", "haus_darah", "tebasan_pelumpuh", "tekad_baja", "kulit_baja"])
	bold.recalc()
	_expect(bold.passive("drain") > 0.0 and bold.passive("damage_cut") > 0.0 and plain.passive("drain") == 0.0 and not bold.skills.has("haus_darah"),
		"jurus pasif aktif begitu dibuka dan tidak masuk susunan jurus")
	_expect(not game.toggle_loadout(bold, "haus_darah"), "jurus pasif tidak bisa dibawa ke susunan")
	var rock := Battler.from_enemy("golem_batu")
	var duel_plain := BattleEngine.new([plain], [rock])
	var duel_bold := BattleEngine.new([bold], [Battler.from_enemy("golem_batu")])
	# Angka besar supaya pembulatan dan serangan kritikal tidak mengaburkan perbandingannya.
	rock.atk = 400
	(duel_bold.enemies[0] as Battler).atk = 400
	plain.max_hp = 99999
	bold.max_hp = 99999
	var taken_plain := 0
	var taken_bold := 0
	for i in 300:
		plain.hp = plain.max_hp
		bold.hp = bold.max_hp
		duel_plain.execute({"actor": rock, "kind": "attack", "target": plain})
		duel_bold.execute({"actor": duel_bold.enemies[0], "kind": "attack", "target": bold})
		taken_plain += plain.max_hp - plain.hp
		taken_bold += bold.max_hp - bold.hp
	_expect(float(taken_bold) / taken_plain > 0.8 and float(taken_bold) / taken_plain < 0.9, "Kulit Baja: kerusakan yang diterima berkurang sekitar 15%% (%.2fx)" % (float(taken_bold) / taken_plain))
	bold.hp = 10
	(duel_bold.enemies[0] as Battler).hp = 99999
	duel_bold.execute({"actor": bold, "kind": "attack", "target": duel_bold.enemies[0]})
	_expect(bold.hp > 10, "Haus Darah: serangan fisik memulihkan HP Arlen (+%d)" % (bold.hp - 10))

	var saint := Battler.from_character("mira", 20)
	saint.unlocked.append_array(["sinar_penghakiman", "kebangkitan", "cahaya_batin", "penyucian", "naungan_suci"])
	saint.recalc()
	var chapel := BattleEngine.new([saint, plain], [Battler.from_enemy("laba_laba")])
	_expect(saint.has_status("defense_up") and plain.has_status("defense_up") and not chapel.opening_lines.is_empty(), "Naungan Suci: seluruh party mendapat DEF Naik di awal pertarungan")
	log = []
	chapel.apply_status(saint, "poison", log)
	chapel.apply_status(saint, "burn", log)
	chapel.apply_status(saint, "slow", log)
	_expect(not saint.has_status("poison") and not saint.has_status("burn") and saint.has_status("slow"), "Cahaya Batin: Mira kebal Racun dan Terbakar, efek lain tetap mempan")

	var sage := Battler.from_character("selene", 20)
	sage.unlocked.append_array(["racun_jiwa", "kabut_pelemah", "aliran_mana", "badai_api", "meteor", "bara_abadi"])
	sage.recalc()
	var normal_mage := Battler.from_character("selene", 20)
	var tower := BattleEngine.new([sage, normal_mage], [Battler.from_enemy("golem_batu")])
	_expect(tower.mp_gain(sage) == roundi(sage.max_mp * Db.MP_REGEN * 2.0) and tower.mp_gain(sage) > tower.mp_gain(normal_mage), "Aliran Mana: pemulihan MP per ronde dua kali lipat (%d vs %d)" % [tower.mp_gain(sage), tower.mp_gain(normal_mage)])
	var boosted := 0
	var base := 0
	var wall: Battler = tower.enemies[0]
	for i in 200:
		wall.hp = 99999
		sage.mp = sage.max_mp
		normal_mage.mp = normal_mage.max_mp
		tower.execute({"actor": sage, "kind": "skill", "skill": "bola_api", "target": wall})
		boosted += 99999 - wall.hp
		wall.hp = 99999
		tower.execute({"actor": normal_mage, "kind": "skill", "skill": "bola_api", "target": wall})
		base += 99999 - wall.hp
		wall.statuses.clear()
	_expect(float(boosted) / base > 1.07 and float(boosted) / base < 1.17, "Bara Abadi: kerusakan sihir sekitar 12%% lebih besar (%.2fx)" % (float(boosted) / base))

	var scout := Battler.from_character("kael", 20)
	scout.unlocked.append_array(["panah_angin", "panah_beruntun", "langkah_ringan"])
	scout.recalc()
	var brute := Battler.from_enemy("golem_batu")
	var woods := BattleEngine.new([scout], [brute])
	var dodged := 0
	for i in 400:
		scout.hp = scout.max_hp
		if woods.execute({"actor": brute, "kind": "attack", "target": scout}).has(Loc.t("%s menghindar!") % scout.display_name):
			dodged += 1
	_expect(dodged > 50 and dodged < 115, "Langkah Ringan: sekitar 20%% serangan fisik dihindari (%d dari 400)" % dodged)

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
