extends SceneTree
## Uji aturan efek status tanpa tampilan.
##   Godot_console.exe --headless --path . -s res://scripts/tests/status_test.gd

var _failed := false


func _init() -> void:
	var hero := Battler.from_character("arlen", 5)
	var wolf := Battler.from_enemy("serigala")
	var ogre := Battler.from_enemy("ogre")
	var mushroom := Battler.from_enemy("jamur")
	var eng := BattleEngine.new([hero], [wolf, ogre, mushroom])
	var lines: Array = []

	# Pengali stat
	var base_atk := hero.stat("atk")
	eng.apply_status(hero, "attack_up", lines)
	_expect(is_equal_approx(hero.stat("atk"), base_atk * 1.4), "ATK Naik mengalikan ATK 1,4")
	eng.apply_status(hero, "attack_break", lines)
	_expect(not hero.has_status("attack_up") and is_equal_approx(hero.stat("atk"), base_atk * 0.7), "ATK Runtuh menghapus ATK Naik")
	var base_def := wolf.stat("defense")
	eng.apply_status(wolf, "defense_break", lines)
	_expect(is_equal_approx(wolf.stat("defense"), base_def * 0.6), "DEF Runtuh mengalikan DEF 0,6")
	var base_agi := wolf.stat("agi")
	eng.apply_status(wolf, "slow", lines)
	_expect(is_equal_approx(wolf.stat("agi"), base_agi * 0.5), "Lambat mengalikan AGI 0,5")
	eng.apply_status(wolf, "speed_up", lines)
	_expect(not wolf.has_status("slow") and is_equal_approx(wolf.stat("agi"), base_agi * 1.5), "Cepat menghapus Lambat")

	# Kerusakan per ronde dan masa berlaku
	hero.statuses.clear()
	eng.apply_status(hero, "burn", lines)
	var hp_before := hero.hp
	eng.end_round()
	_expect(hero.hp == hp_before - max(1, int(round(hero.max_hp * 0.08))), "Terbakar: 8%% HP maksimum per ronde (-%d)" % (hp_before - hero.hp))
	eng.end_round()
	eng.end_round()
	_expect(not hero.has_status("burn"), "Terbakar berakhir setelah 3 ronde")
	eng.apply_status(wolf, "poison", lines)
	hp_before = wolf.hp
	eng.end_round()
	_expect(wolf.hp == hp_before - max(1, int(round(wolf.max_hp * 0.05))), "Racun: 5%% HP maksimum per ronde (-%d)" % (hp_before - wolf.hp))
	eng.apply_status(ogre, "burn", lines)
	hp_before = ogre.hp
	eng.end_round()
	_expect(hp_before - ogre.hp == int(round(ogre.max_hp * 0.08 * 0.5)), "Semi-bos hanya menerima separuh kerusakan Terbakar (-%d)" % (hp_before - ogre.hp))

	# Kekebalan
	eng.apply_status(ogre, "slow", lines)
	_expect(not ogre.has_status("slow"), "Ogre kebal Lambat")
	eng.apply_status(mushroom, "poison", lines)
	_expect(not mushroom.has_status("poison"), "Jamur kebal Racun")
	hero.statuses.clear()
	eng.apply_status(hero, "immunity", lines)
	eng.apply_status(hero, "poison", lines)
	eng.apply_status(hero, "defense_up", lines)
	_expect(not hero.has_status("poison") and hero.has_status("defense_up"), "Kebal menolak nerf tetapi tetap menerima buff")

	# Jurus pembersih
	var mira := Battler.from_character("mira", 6)
	var eng2 := BattleEngine.new([hero, mira], [Battler.from_enemy("goblin")])
	eng2.apply_status(hero, "poison", lines)
	eng2.apply_status(hero, "slow", lines)
	eng2.apply_status(hero, "attack_up", lines)
	eng2.execute({"actor": mira, "kind": "skill", "skill": "berkat_suci"})
	_expect(not hero.has_status("poison") and not hero.has_status("slow"), "Berkat Suci menghapus semua nerf")
	_expect(hero.has_status("attack_up") and hero.has_status("immunity") and mira.has_status("immunity"), "Berkat Suci mempertahankan buff dan memberi Kebal ke seluruh party")

	# Racun bisa menumbangkan
	var bat := Battler.from_enemy("kelelawar")
	var eng3 := BattleEngine.new([hero], [bat])
	bat.hp = 1
	eng3.apply_status(bat, "poison", lines)
	eng3.end_round()
	_expect(not bat.is_alive() and eng3.is_victory(), "Racun bisa menumbangkan musuh di akhir ronde")

	# Tiap jenis monster hanya memakai sebagian efek status
	var all_ids: Array = Db.STATUSES.keys()
	for enemy_id: String in Db.ENEMIES:
		var used := {}
		for skill_id: String in Db.ENEMIES[enemy_id].skills:
			var sk: Dictionary = Db.SKILLS[skill_id]
			if sk.has("status"):
				used[sk.status] = true
			if sk.has("inflict"):
				used[sk.inflict.status] = true
		var names: Array = []
		for status_id: String in used:
			names.append(Db.STATUSES[status_id].name)
		_expect(used.size() < all_ids.size(), "%s memakai %d dari %d efek: %s" % [Db.ENEMIES[enemy_id].name, used.size(), all_ids.size(), ", ".join(names)])
	for status_id: String in all_ids:
		var st: Dictionary = Db.STATUSES[status_id]
		var users: Array = []
		for skill_id: String in Db.SKILLS:
			var sk: Dictionary = Db.SKILLS[skill_id]
			if sk.get("status", "") == status_id or (sk.has("inflict") and sk.inflict.status == status_id):
				users.append(sk.name)
		_expect(not users.is_empty(), "%s (%s) dipakai oleh: %s" % [st.name, st.kind, ", ".join(users)])

	# Pemulihan MP tiap akhir ronde (hanya anggota party)
	var mage := Battler.from_character("selene", 5)  # MP maksimum 32 -> pulih 3 per ronde
	var knight := Battler.from_character("arlen", 1)  # MP maksimum 6 -> pulih minimal 1
	var regen_bat := Battler.from_enemy("kelelawar")
	var regen := BattleEngine.new([mage, knight], [regen_bat])
	mage.mp = 10
	knight.mp = 0
	regen_bat.mp = 0
	regen.end_round()
	_expect(mage.mp == 10 + roundi(mage.max_mp * Db.MP_REGEN), "MP pulih %d%% MP maksimum tiap ronde (+%d)" % [roundi(Db.MP_REGEN * 100), mage.mp - 10])
	_expect(knight.mp == 1, "MP pulih minimal 1 tiap ronde")
	_expect(regen_bat.mp == 0, "MP monster tidak pulih")
	mage.mp = 10
	regen.execute({"actor": mage, "kind": "defend"})
	regen.end_round()
	_expect(mage.mp == 10 + roundi(roundi(mage.max_mp * Db.MP_REGEN) * Db.MP_REGEN_DEFEND), "Bertahan melipatgandakan pemulihan MP (+%d)" % (mage.mp - 10))
	_expect(mage.defending, "Bertahan tetap berlaku melewati akhir ronde, sampai giliran berikutnya")
	regen.execute({"actor": mage, "kind": "attack", "target": regen_bat})
	_expect(not mage.defending, "Bertahan berakhir saat tokoh itu mendapat giliran lagi")
	var order := regen.round_order()
	_expect(order.size() == 3 and order.has(mage) and order.has(knight) and order.has(regen_bat), "urutan ronde memuat semua petarung yang masih hidup")
	mage.mp = mage.max_mp - 1
	regen.end_round()
	_expect(mage.mp == mage.max_mp, "MP tidak melebihi maksimum")
	mage.hp = 0
	mage.mp = 5
	regen.end_round()
	_expect(mage.mp == 5, "anggota yang tumbang tidak memulihkan MP")

	# Salur Jiwa (Mira): memulihkan MP rekan lain, tidak untuk diri sendiri
	_expect(not Battler.from_character("mira", 6).skills.has("salur_jiwa") and Battler.from_character("mira", 7).skills.has("salur_jiwa"), "Mira mempelajari Salur Jiwa di level 7")
	var priest := Battler.from_character("mira", 7)
	var caster := Battler.from_character("selene", 7)
	var channel := BattleEngine.new([priest, caster], [Battler.from_enemy("kelelawar")])
	caster.mp = 0
	var priest_mp := priest.mp
	var gain := int(12.0 + priest.mag * 0.25)
	channel.execute({"actor": priest, "kind": "skill", "skill": "salur_jiwa", "target": caster})
	_expect(caster.mp == gain and priest.mp == priest_mp - 6, "Salur Jiwa: MP rekan pulih %d, MP Mira berkurang 6" % caster.mp)
	_expect(gain > 6, "Salur Jiwa memulihkan lebih banyak daripada biayanya (%d > 6)" % gain)
	var self_cmd := {"actor": priest, "kind": "skill", "skill": "salur_jiwa", "target": priest}
	_expect(channel.resolve_targets(self_cmd) == [caster], "Salur Jiwa yang diarahkan ke diri sendiri dialihkan ke rekan lain")
	caster.hp = 0
	priest.mp = 10
	channel.execute({"actor": priest, "kind": "skill", "skill": "salur_jiwa", "target": priest})
	_expect(priest.mp == 4, "tanpa rekan lain, Salur Jiwa tidak memulihkan MP Mira sendiri (MP %d)" % priest.mp)

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
