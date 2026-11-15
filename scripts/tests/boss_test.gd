extends SceneTree
## Uji pola bos (tanda serangan Ogre) dan "Coba lagi" setelah kalah dari bos, tanpa tampilan.
##   Godot_console.exe --headless --path . -s res://scripts/tests/boss_test.gd

var _failed := false


func _initialize() -> void:
	var game: Node = root.get_node("Game")
	game.save_path = "user://test_save.json"
	game.new_game()

	# --- pola Ogre: serangan biasa -> ancang-ancang -> menahan (hantaman lepas di akhir ronde) -> lengah ---
	var arlen := Battler.from_character("arlen", 12)
	var mira := Battler.from_character("mira", 12)
	var ogre := Battler.from_enemy("ogre")
	var eng := BattleEngine.new([arlen, mira], [ogre])
	var kinds: Array = []
	for i in 9:
		kinds.append(eng.enemy_command(ogre).kind)
	var free := ["attack", "skill"]
	_expect(free.has(kinds[0]) and kinds[1] == "windup" and kinds[2] == "hold" and kinds[3] == "rest" and free.has(kinds[4])
		and kinds[5] == "windup" and kinds[6] == "hold" and kinds[7] == "rest" and free.has(kinds[8]),
		"giliran Ogre berulang: bebas, ancang-ancang, menahan, lengah (%s)" % ", ".join(kinds.slice(0, 5)))
	_expect(not Db.ENEMIES["ogre"].skills.has("hantaman_bumi") and Db.STATUSES["charge"].get("internal", false),
		"serangan seluruh party Ogre kini hanya lewat pola bertanda")
	var wolf := Battler.from_enemy("serigala")
	var plain := BattleEngine.new([arlen], [wolf])
	var wolf_kinds := {}
	for i in 40:
		wolf_kinds[plain.enemy_command(wolf).kind] = true
	_expect(not wolf_kinds.has("windup") and not wolf_kinds.has("hold") and not wolf_kinds.has("rest"), "monster tanpa pola tetap memakai AI lama")

	# Satu siklus penuh, ronde demi ronde.
	eng = BattleEngine.new([arlen, mira], [ogre])
	arlen.full_restore()
	mira.full_restore()
	eng.round_order()  # ronde 1: Ogre bebas
	eng.end_round()
	_expect(eng.slam_incoming() == -1 and not ogre.has_status("charge"), "ronde 1: belum ada tanda serangan")
	eng.round_order()  # ronde 2: ancang-ancang
	var warn := eng.execute({"actor": ogre, "kind": "windup"})
	_expect(ogre.has_status("charge") and eng.slam_incoming() == 1 and warn.size() == 1, "ronde 2: Ogre ancang-ancang, tanda terpasang, hantaman dijadwalkan akhir ronde depan")
	var hp_before := [arlen.hp, mira.hp]
	var quiet := eng.end_round()
	_expect([arlen.hp, mira.hp] == hp_before and ogre.has_status("charge"), "akhir ronde 2: hantaman belum lepas dan tandanya tetap terlihat")
	_expect(not quiet.has(Loc.t("%s pada %s berakhir.") % [Loc.t("Ancang-ancang"), ogre.display_name]), "tanda ancang-ancang tidak hilang oleh waktu")
	var order := eng.round_order()  # ronde 3: menahan; semua tokoh bergerak dulu sebelum hantaman
	_expect(eng.slam_incoming() == 0 and order.has(arlen) and order.has(mira), "ronde 3: hantaman lepas di akhir ronde ini, dan tiap tokoh hidup mendapat giliran lebih dulu")
	eng.execute({"actor": arlen, "kind": "defend"})
	eng.execute({"actor": ogre, "kind": "hold"})
	_expect([arlen.hp, mira.hp] == hp_before, "giliran Ogre saat menahan tidak melukai siapa pun")
	eng.execute({"actor": mira, "kind": "attack", "target": ogre})  # Mira tidak bertahan
	var slam := eng.end_round()
	_expect(slam.has(Loc.t("%s melepaskan Hantaman Dahsyat!") % ogre.display_name) and arlen.hp < int(hp_before[0]) and mira.hp < int(hp_before[1]),
		"akhir ronde 3: Hantaman Dahsyat mengenai seluruh party")
	_expect(not ogre.has_status("charge") and eng.slam_incoming() == -1 and ogre.slam_round == -1, "setelah hantaman, tanda ancang-ancang hilang")

	# Bertahan mengurangi hantaman kira-kira separuh; urutan giliran tidak berpengaruh karena lepasnya di akhir ronde.
	var guarded := 0
	var open := 0
	for i in 200:
		var a := Battler.from_character("arlen", 12)
		var b := Battler.from_character("arlen", 12)
		var o := Battler.from_enemy("ogre")
		var duel := BattleEngine.new([a, b], [o])
		duel.round_order()
		duel.execute({"actor": o, "kind": "windup"})
		duel.end_round()
		duel.round_order()
		duel.execute({"actor": a, "kind": "defend"})
		duel.execute({"actor": o, "kind": "hold"})
		duel.end_round()
		guarded += a.max_hp - a.hp
		open += b.max_hp - b.hp
	_expect(float(guarded) / open > 0.4 and float(guarded) / open < 0.62, "Bertahan masih berlaku saat hantaman lepas: kerusakan sekitar separuh (%.2fx)" % (float(guarded) / open))
	var fresh := BattleEngine.new([arlen, mira], [Battler.from_enemy("ogre")])
	_expect(fresh.round_no == 0 and fresh.slam_incoming() == -1 and fresh.enemy_command(fresh.enemies[0]).kind in free,
		"pertarungan baru memulai pola dari awal, tanpa sisa keadaan pertarungan sebelumnya")
	var dying := BattleEngine.new([arlen, mira], [Battler.from_enemy("ogre")])
	dying.round_order()
	dying.execute({"actor": dying.enemies[0], "kind": "windup"})
	dying.end_round()
	dying.round_order()
	(dying.enemies[0] as Battler).hp = 0
	arlen.full_restore()
	dying.end_round()
	_expect(arlen.hp == arlen.max_hp, "Ogre yang tumbang saat ancang-ancang tidak melepaskan hantaman")

	# --- Coba lagi: keadaan sebelum bertarung dikembalikan persis ---
	game.new_game()
	game.party = [Battler.from_character("arlen", 5), Battler.from_character("mira", 5)]
	var hero: Battler = game.party[0]
	var priest: Battler = game.party[1]
	hero.hp = 40
	priest.mp = 9
	game.items = {"ramuan": 3, "eter": 1}
	game.gold = 77
	game.encounter = ["ogre"]
	game.set("_battle_snapshot", game.call("_take_snapshot"))
	_expect(game.can_retry(), "setelah pertarungan dimulai, tersedia snapshot untuk coba lagi")
	# Selama bertarung: barang terpakai, HP/MP berubah, lalu party kalah.
	(game.items as Dictionary)["ramuan"] = 1
	(game.items as Dictionary).erase("eter")
	hero.hp = 0
	priest.hp = 0
	priest.mp = 0
	hero.statuses["poison"] = 2
	var snapshot: Dictionary = game.get("_battle_snapshot")
	_expect(int(snapshot.items["ramuan"]) == 3 and int(snapshot.vitals[0].hp) == 40, "snapshot adalah salinan: tidak ikut berubah saat pertarungan mengubah tas dan HP")
	# retry_battle() juga memuat scene battle; di sini cukup bagian pemulihannya.
	for entry: Dictionary in snapshot.vitals:
		var m: Battler = game.member(entry.id)
		m.hp = int(entry.hp)
		m.mp = int(entry.mp)
		m.reset_battle_state()
	game.items = (snapshot.items as Dictionary).duplicate(true)
	_expect(hero.hp == 40 and priest.hp == priest.max_hp and priest.mp == 9 and hero.statuses.is_empty(), "coba lagi: HP dan MP kembali persis seperti sebelum bertarung, tidak lebih")
	_expect(game.items == {"ramuan": 3, "eter": 1} and game.gold == 77, "coba lagi: barang yang terpakai kembali, emas tidak berubah")
	(game.items as Dictionary)["ramuan"] = 0
	_expect(int((game.get("_battle_snapshot") as Dictionary).items["ramuan"]) == 3, "snapshot tetap utuh untuk percobaan berikutnya")
	game.encounter = []
	_expect(not game.can_retry(), "tanpa pertarungan yang sedang berjalan, tidak ada yang bisa diulang")

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
