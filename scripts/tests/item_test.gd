extends SceneTree
## Uji aturan barang tanpa tampilan.
##   Godot_console.exe --headless --path . -s res://scripts/tests/item_test.gd

var _failed := false


func _init() -> void:
	var arlen := Battler.from_character("arlen", 5)
	var mira := Battler.from_character("mira", 5)
	var bag := {"ramuan": 2, "penawar": 1, "eter": 1, "air_kehidupan": 1}
	var eng := BattleEngine.new([arlen, mira], [Battler.from_enemy("goblin")])
	eng.items = bag

	# Ramuan
	arlen.hp = 10
	var lines := eng.execute({"actor": mira, "kind": "item", "item": "ramuan", "target": arlen})
	_expect(arlen.hp == 40 and bag["ramuan"] == 1, "Ramuan memulihkan 30 HP dan berkurang satu (%s)" % " / ".join(lines))
	arlen.hp = arlen.max_hp
	eng.execute({"actor": mira, "kind": "item", "item": "ramuan", "target": arlen})
	_expect(bag["ramuan"] == 1, "Ramuan tidak terpakai kalau HP sudah penuh")
	arlen.hp = arlen.max_hp - 5
	eng.execute({"actor": mira, "kind": "item", "item": "ramuan", "target": arlen})
	_expect(arlen.hp == arlen.max_hp and not bag.has("ramuan"), "Ramuan tidak melebihi HP maksimum; barang habis hilang dari tas")
	arlen.hp = 10
	lines = eng.execute({"actor": mira, "kind": "item", "item": "ramuan", "target": arlen})
	_expect(arlen.hp == 10 and lines.size() == 2, "Barang yang sudah habis tidak berpengaruh (%s)" % lines[1])

	# Eter
	mira.mp = 3
	eng.execute({"actor": arlen, "kind": "item", "item": "eter", "target": mira})
	_expect(mira.mp == 23 and not bag.has("eter"), "Eter memulihkan 20 MP")

	# Penawar
	var log: Array = []
	eng.apply_status(arlen, "poison", log)
	eng.apply_status(arlen, "slow", log)
	eng.apply_status(arlen, "attack_up", log)
	eng.execute({"actor": mira, "kind": "item", "item": "penawar", "target": arlen})
	_expect(not arlen.has_status("poison") and not arlen.has_status("slow") and arlen.has_status("attack_up"), "Penawar menghapus nerf dan mempertahankan buff")
	_expect(not bag.has("penawar"), "Penawar terpakai")

	# Air Kehidupan
	eng.execute({"actor": mira, "kind": "item", "item": "air_kehidupan", "target": arlen})
	_expect(bag["air_kehidupan"] == 1, "Air Kehidupan tidak terpakai pada rekan yang masih berdiri")
	arlen.hp = 0
	var targets := eng.resolve_targets({"actor": mira, "kind": "item", "item": "air_kehidupan", "target": arlen})
	_expect(targets == [arlen], "sasaran barang tidak dialihkan dari rekan yang tumbang")
	eng.execute({"actor": mira, "kind": "item", "item": "air_kehidupan", "target": arlen})
	_expect(arlen.hp == arlen.max_hp / 2 and not bag.has("air_kehidupan"), "Air Kehidupan membangkitkan dengan separuh HP (%d)" % arlen.hp)

	# Ramuan buff: memberi efek status ke rekan, dan menghapus nerf lawannya
	var buffs := {"ramuan_kekuatan": 1, "ramuan_pelindung": 1, "ramuan_angin": 1}
	eng.items = buffs
	arlen.statuses.clear()
	eng.apply_status(arlen, "slow", log)
	var base_atk := arlen.stat("atk")
	eng.execute({"actor": mira, "kind": "item", "item": "ramuan_kekuatan", "target": arlen})
	eng.execute({"actor": mira, "kind": "item", "item": "ramuan_pelindung", "target": arlen})
	eng.execute({"actor": mira, "kind": "item", "item": "ramuan_angin", "target": arlen})
	_expect(arlen.has_status("attack_up") and is_equal_approx(arlen.stat("atk"), base_atk * 1.4), "Ramuan Kekuatan memberi ATK Naik")
	_expect(arlen.has_status("defense_up"), "Ramuan Pelindung memberi DEF Naik")
	_expect(arlen.has_status("speed_up") and not arlen.has_status("slow"), "Ramuan Angin memberi Cepat dan menghapus Lambat")
	_expect(buffs.is_empty(), "ketiga ramuan buff terpakai")

	# Tas awal dan dagangan Doran
	_expect(Db.START_ITEMS == {"ramuan": 2}, "permainan baru dimulai dengan 2 Ramuan")
	_expect(_stock({}) == ["ramuan", "penawar"], "sebelum Ogre kalah: toko menjual Ramuan dan Penawar")
	_expect(_stock({"ogre": true}).size() == Db.ITEMS.size(), "setelah Ogre kalah: toko menjual semua barang")
	for item_id: String in Db.ITEMS:
		var item: Dictionary = Db.ITEMS[item_id]
		_expect(int(item.price) > 0 and String(item.desc) != "", "%s: %d emas" % [item.name, item.price])

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _stock(flags: Dictionary) -> Array:
	for step: Dictionary in Story.talk("joko", flags, 0):
		if step.get("do", "") == "shop":
			return step.stock
	return []


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
