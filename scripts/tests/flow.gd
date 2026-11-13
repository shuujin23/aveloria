extends SceneTree
## Uji alur lengkap tanpa pemain: cek peta, lalu mainkan cerita Wilayah 1 dari awal
## (dialog, penginapan, keluar desa, menolong Mira, Ogre, gerbang) dengan menekan tombol otomatis.
##   Godot_console.exe --headless --path . -s res://scripts/tests/flow.gd
## Tambahkan "-- C:/folder" (tanpa --headless) untuk menyimpan screenshot di folder itu.

var _failed := false
var _game: Node
var _shot_dir := ""
var _battle_log := ""  # isi kotak pesan battle terakhir, untuk diagnosis


func _initialize() -> void:
	Engine.time_scale = 4.0  # percepat animasi dan jeda supaya uji tidak lama
	AudioServer.set_bus_mute(0, true)  # uji berjalan senyap
	_game = root.get_node("Game")
	var args := OS.get_cmdline_user_args()
	_shot_dir = args[0] if args.size() > 0 else ""

	# Uji memakai file simpanan sendiri supaya simpanan pemain tidak tersentuh.
	_game.save_path = "user://test_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_game.save_path))

	_check_maps()

	# --- Layar judul tanpa simpanan ---
	change_scene_to_file("res://scenes/title.tscn")
	await create_timer(0.3).timeout
	_expect(current_scene.name == "Title" and (current_scene.get("_continue") as Button).disabled, "layar judul: Lanjutkan mati kalau belum ada simpanan")
	await _shot("judul.png")
	current_scene.call("_on_new_game")

	# --- Awal permainan: di desa, sendirian, dengan cerita pembuka ---
	await create_timer(0.5).timeout
	_expect(current_scene != null and current_scene.name == "World", "Permainan Baru membuka peta")
	_expect(_game.map_id == "desa" and _game.party.size() == 1, "mulai di desa dengan Arlen sendirian")
	_expect(current_scene.get("_dialog_open"), "cerita pembuka tampil")
	await _shot("desa_dialog.png")
	await _skip_dialog()
	_expect(not current_scene.get("_busy"), "pemain bisa bergerak setelah cerita pembuka")
	await _shot("desa.png")

	var probe := Vector2i(9, 3)
	_expect(current_scene.call("_tile_at", current_scene.call("_iso", probe)) == probe, "posisi klik diterjemahkan ke petak yang benar")

	# --- NPC desa ---
	current_scene.call("_talk", "tetua")
	await _skip_dialog()
	_expect(_game.flags.has("quest_mira"), "Tetua memberi tugas mencari Mira")

	var arlen: Battler = _game.party[0]
	arlen.hp = 5
	_game.gold = 0
	current_scene.call("_talk", "sari")
	await _skip_dialog()
	_expect(arlen.hp == arlen.max_hp and _game.gold == 0, "penginapan gratis saat emas kurang, HP pulih")
	arlen.hp = 5
	_game.gold = 25
	current_scene.call("_talk", "sari")
	await _skip_dialog()
	_expect(arlen.hp == arlen.max_hp and _game.gold == 15, "penginapan memotong 10 emas (emas=%d)" % _game.gold)

	current_scene.call("_walk_to_npc", Vector2i(8, 5))
	await _wait_until(func() -> bool: return current_scene.get("_dialog_open"))
	_expect(current_scene.get("_dialog_open"), "klik NPC: Arlen menghampiri lalu dialog terbuka")
	await _skip_dialog()

	# --- Toko Doran ---
	_game.gold = 30
	current_scene.call("_talk", "joko")
	await _skip_dialog()
	_expect(current_scene.get("_shop_open"), "toko terbuka setelah dialog Doran")
	_expect(current_scene.get("_shop_stock") == ["ramuan", "penawar"], "sebelum Ogre kalah toko hanya menjual Ramuan dan Penawar")
	_expect((current_scene.get("_shop_view") as Control).visible, "toko tampil sebagai kartu berikon")
	await _shot("toko.png")
	current_scene.call("_shop_buy", "ramuan")
	current_scene.call("_shop_buy", "penawar")
	_expect(_game.gold == 12 and _game.items.get("ramuan") == 3 and _game.items.get("penawar") == 1, "membeli memotong emas dan menambah isi tas (emas=%d)" % _game.gold)
	current_scene.call("_shop_buy", "ramuan")
	current_scene.call("_shop_buy", "ramuan")
	_expect(_game.gold == 2 and _game.items.get("ramuan") == 4, "tidak bisa membeli kalau emas kurang (emas=%d)" % _game.gold)
	# Kapasitas tas: 6 slot, tiap slot 5 barang sejenis.
	_expect(_game.slots_used() == 2 and _game.bag_slots == 6, "4 Ramuan + 1 Penawar memakai 2 dari 6 slot")
	_game.gold = 500
	_game.items = {"ramuan": 30}
	_expect(_game.slots_used() == 6 and not _game.can_add("ramuan") and not _game.can_add("penawar"), "30 Ramuan memenuhi 6 slot; tidak ada yang muat lagi")
	current_scene.call("_shop_buy", "penawar")
	_expect(_game.gold == 500 and not _game.items.has("penawar"), "toko menolak pembelian saat tas penuh")
	_game.items = {"ramuan": 29}
	_expect(_game.can_add("ramuan") and not _game.can_add("penawar"), "slot yang belum penuh hanya menerima barang sejenis")
	_game.items = {"ramuan": 30}
	current_scene.call("_shop_upgrade")
	_expect(_game.bag_slots == 8 and _game.gold == 450, "memperbesar tas: 8 slot, emas berkurang 50 (emas=%d)" % _game.gold)
	current_scene.call("_shop_buy", "penawar")
	_expect(_game.items.get("penawar") == 1 and _game.slots_used() == 7, "setelah diperbesar, barang baru muat")
	current_scene.call("_shop_upgrade")
	current_scene.call("_shop_upgrade")
	_expect(_game.bag_slots == 12 and _game.gold == 450 - 8 - 100 - 150, "tas maksimal 12 slot (emas=%d)" % _game.gold)
	current_scene.call("_shop_upgrade")
	_expect(_game.bag_slots == 12 and Db.bag_upgrade_price(12) == -1, "tas tidak bisa diperbesar melebihi maksimal")
	_game.items = {"ramuan": 4, "penawar": 1}
	_game.gold = 2
	_game.bag_slots = 8

	current_scene.emit_signal("shop_closed")
	await _skip_dialog()
	_expect(not current_scene.get("_busy") and not current_scene.get("_shop_open"), "toko tertutup dan pemain bisa bergerak lagi")

	# --- Pandai besi dan layar Perlengkapan ---
	_game.gold = 200
	_game.mats = {"serat_liar": 6, "taring_serigala": 2, "lendir_emas": 1}
	current_scene.call("_talk", "gatot")
	await _skip_dialog()
	var forge: Control = current_scene.get("_forge_view")
	_expect(current_scene.get("_forge_open") and forge.visible, "pandai besi terbuka setelah dialog Garrick")
	await create_timer(0.1).timeout
	await _shot("pandai_beli.png")
	_expect(_game.buy_gear("arlen_weapon_1") and _game.buy_gear("arlen_body_1") and _game.gold == 115, "membeli pedang dan zirah untuk Arlen (emas=%d)" % _game.gold)
	_expect(_game.enhance(arlen, "weapon").ok and int(arlen.equip["weapon"].plus) == 1, "menempa pedang ke +1")
	arlen.equip["weapon"]["trait"] = "poison"
	forge.set("_tab", 1)
	forge.call("_rebuild")
	await create_timer(0.1).timeout
	await _shot("pandai_tempa.png")
	forge.set("_tab", 3)
	forge.call("_rebuild")
	await create_timer(0.1).timeout
	await _shot("pandai_jual.png")
	current_scene.emit_signal("forge_closed")
	await _skip_dialog()
	_expect(not current_scene.get("_busy") and not current_scene.get("_forge_open"), "pandai besi tertutup dan pemain bisa bergerak lagi")
	current_scene.call("_toggle_gear")
	_expect(current_scene.get("_gear_open") and current_scene.get("_busy"), "pintasan membuka layar Perlengkapan")
	await create_timer(0.1).timeout
	await _shot("perlengkapan.png")
	current_scene.call("_toggle_gear")
	_expect(not current_scene.get("_gear_open") and not current_scene.get("_busy"), "pintasan sekali lagi menutup layar Perlengkapan")
	arlen.equip.clear()  # sisa uji memakai stat dasar
	arlen.recalc()
	arlen.hp = arlen.max_hp
	_game.mats = {}
	_game.gold = 2

	# --- Pintasan tas: tombol ikon / tombol I membuka tas langsung dari peta ---
	current_scene.call("_toggle_bag")
	_expect(current_scene.get("_bag_open") and current_scene.get("_busy") and not current_scene.get("_menu_open"), "pintasan membuka tas tanpa lewat menu Esc")
	await create_timer(0.1).timeout
	await _shot("tas_pintasan.png")
	current_scene.call("_toggle_bag")
	_expect(not current_scene.get("_bag_open") and not current_scene.get("_busy") and not current_scene.get("_menu_open"), "pintasan sekali lagi menutup tas dan kembali ke peta")
	var press_i := InputEventKey.new()
	press_i.keycode = KEY_I
	press_i.pressed = true
	Input.parse_input_event(press_i)
	await create_timer(0.1).timeout
	_expect(current_scene.get("_bag_open"), "tombol I di keyboard membuka tas")
	current_scene.call("_close_bag")
	_expect(not current_scene.get("_busy"), "menutup tas dari pintasan mengembalikan kendali")

	# --- Barang dipakai dari menu peta ---
	arlen.hp = 10
	current_scene.call("_open_menu")
	current_scene.set("_bag_from_menu", true)
	current_scene.call("_open_bag")
	_expect(current_scene.get("_bag_open") and (current_scene.get("_bag") as Control).visible, "menu Barang membuka tampilan tas")
	_game.items = {"ramuan": 7, "penawar": 1, "eter": 2, "air_kehidupan": 1}
	current_scene.call("_open_bag")
	await create_timer(0.1).timeout
	await _shot("tas.png")
	_game.items = {"ramuan": 4, "penawar": 1}
	current_scene.call("_menu_use_item", "ramuan", arlen)
	_expect(arlen.hp == min(40, arlen.max_hp) and _game.items.get("ramuan") == 3, "Ramuan dari menu peta memulihkan HP (HP %d/%d)" % [arlen.hp, arlen.max_hp])
	current_scene.call("_menu_use_item", "penawar", arlen)
	_expect(_game.items.get("penawar") == 1, "Penawar tidak terpakai di peta kalau tidak ada nerf")
	current_scene.call("_menu_discard", "penawar")
	_expect(not _game.items.has("penawar"), "Buang 1 mengurangi barang dari tas")
	_game.items["penawar"] = 1
	current_scene.call("_close_bag")
	_expect(not current_scene.get("_bag_open") and current_scene.get("_menu_open"), "menutup tas kembali ke menu")
	current_scene.call("_close_menu")
	arlen.hp = arlen.max_hp

	# --- Keluar desa ke peta dunia ---
	_expect(current_scene.call("_walk_to", WorldMap.find("X")), "klik jalan keluar desa menghasilkan rute")
	await _wait_until(func() -> bool: return _game.map_id == "dunia" and current_scene != null and not current_scene.get("_busy"))
	_expect(_game.map_id == "dunia" and _game.player_tile == WorldMap.find_in("dunia", "T"), "keluar desa -> muncul di petak desa pada peta dunia")
	_expect(not current_scene.call("_walk_to", Vector2i(30, 6)), "klik ke Hutan Kabut ditolak selama gerbang terkunci")
	_expect(not current_scene.call("_walk_to", WorldMap.find("G")), "klik ke gerbang terkunci ditolak")

	# --- Keyboard (level dinaikkan supaya pertemuan acak di tengah uji tidak mengalahkan Arlen) ---
	_set_levels(6)
	var start: Vector2i = _game.player_tile
	Input.action_press("ui_right")
	await create_timer(0.3).timeout
	Input.action_release("ui_right")
	await create_timer(0.3).timeout
	_expect(_game.player_tile.x > start.x and _game.player_tile.y < start.y, "tombol kanan = ke kanan layar (%s -> %s)" % [start, _game.player_tile])
	var before: Vector2i = _game.player_tile
	Input.action_press("ui_down")
	Input.action_press("ui_right")
	await create_timer(0.3).timeout
	Input.action_release("ui_down")
	Input.action_release("ui_right")
	await create_timer(0.3).timeout
	_expect(_game.player_tile.x > before.x and _game.player_tile.y == before.y, "bawah+kanan = miring searah sisi petak (%s -> %s)" % [before, _game.player_tile])
	Input.action_press("ui_left")
	await create_timer(2.5).timeout
	Input.action_release("ui_left")
	await create_timer(0.4).timeout
	if current_scene.name == "Battle":
		await _play_battle()
	_expect(current_scene.name == "World" and WorldMap.is_walkable(_game.player_tile, _game.flags), "pemain tidak menembus petak terlarang (posisi %s)" % _game.player_tile)

	# --- Sarang Ogre menolak Arlen yang masih sendirian ---
	await _open_world("dunia", WorldMap.find_in("dunia", "B") + Vector2i(-1, 0))
	current_scene.call("_walk_to", WorldMap.find("B"))
	await _wait_until(func() -> bool: return current_scene.name == "Battle" or current_scene.get("_dialog_open"))
	_expect(current_scene.name == "World" and not _game.flags.has("ogre"), "sendirian: sarang Ogre hanya memunculkan dialog, bukan battle")
	await _skip_dialog()

	# --- Menolong Mira ---
	_set_levels(3)
	await _open_world("dunia", Vector2i(13, 2))
	await _shot("peta_mira.png")
	current_scene.call("_talk", "mira")
	await _skip_dialog()
	await _play_battle()
	_expect(current_scene.name == "World" and current_scene.get("_dialog_open"), "setelah menang, adegan lanjutan Mira tampil")
	await _skip_dialog()
	_expect(_game.party.size() == 2 and (_game.party[1] as Battler).id == "mira", "Mira masuk party")
	_expect((_game.party[1] as Battler).level == 3 or (_game.party[1] as Battler).level == 4, "Mira bergabung setingkat Arlen (Lv %d)" % (_game.party[1] as Battler).level)
	_expect(not (current_scene.get("_npc_at") as Dictionary).has(Vector2i(12, 2)), "Mira hilang dari peta setelah bergabung")

	# --- Ogre Penjaga dan gerbang ---
	_set_levels(16)  # sejak Ogre diperkuat (v1.2), level 8 tanpa perlengkapan kadang kalah
	await _open_world("dunia", WorldMap.find_in("dunia", "B") + Vector2i(-1, 0))
	_expect(not WorldMap.is_walkable(WorldMap.find("G"), _game.flags), "gerbang tertutup sebelum Ogre kalah")
	current_scene.call("_walk_to", WorldMap.find("B"))
	await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "Battle")
	await _play_battle()
	_expect(_game.flags.has("ogre"), "penanda Ogre tercatat")
	_expect(current_scene.get("_dialog_open"), "adegan kemenangan atas Ogre tampil")
	await _skip_dialog()
	_expect(WorldMap.is_walkable(WorldMap.find("G"), _game.flags), "gerbang terbuka setelah Ogre kalah")

	# --- Masuk Hutan Kabut pertama kali ---
	await _open_world("dunia", WorldMap.find_in("dunia", "G") + Vector2i(5, 0))
	await _shot("peta_gerbang.png")
	current_scene.call("_walk_to", WorldMap.find("G") + Vector2i(6, -1))
	await _wait_until(func() -> bool: return current_scene.get("_dialog_open"))
	_expect(current_scene.get("_dialog_open"), "adegan pembuka Hutan Kabut tampil")
	await _skip_dialog()
	_expect(_game.flags.has("kabut_intro"), "adegan Hutan Kabut hanya sekali")

	# --- Simpan dan muat ---
	current_scene.call("_open_menu")
	_expect(current_scene.get("_menu_open") and current_scene.get("_busy"), "menu Esc terbuka dan menghentikan gerak")
	await _shot("menu.png")
	var saved_tile: Vector2i = _game.player_tile
	var saved_xp: int = (_game.party[0] as Battler).xp
	var saved_level: int = (_game.party[0] as Battler).level
	(_game.party[1] as Battler).hp = 7
	_game.gold = 123
	_game.items = {"ramuan": 3, "eter": 1}
	_game.bag_slots = 10
	current_scene.call("_menu_save")
	_expect(_game.has_save() and not current_scene.get("_menu_open"), "menu Simpan menulis file dan menutup menu")
	_game.new_game()
	_expect(_game.party.size() == 1 and _game.gold == 0 and _game.flags.is_empty(), "keadaan direset sebelum dimuat")
	_expect(_game.load_game(), "simpanan bisa dimuat")
	_expect(_game.party.size() == 2 and (_game.party[0] as Battler).level == saved_level and (_game.party[1] as Battler).id == "mira", "party dan level kembali seperti saat disimpan")
	_expect((_game.party[1] as Battler).hp == 7 and (_game.party[0] as Battler).xp == saved_xp, "HP dan XP ikut tersimpan")
	_expect(_game.items == {"ramuan": 3, "eter": 1} and _game.bag_slots == 10, "isi dan kapasitas tas ikut tersimpan")
	_expect(_game.gold == 123 and _game.flags.has("ogre") and _game.flags.has("mira_joined") and _game.flags.has("kabut_intro"), "emas dan kemajuan cerita kembali")
	_expect(_game.map_id == "dunia" and _game.player_tile == saved_tile and _game.pending_scene == "", "posisi kembali, cerita pembuka tidak terulang")
	change_scene_to_file("res://scenes/title.tscn")
	await create_timer(0.3).timeout
	_expect(not (current_scene.get("_continue") as Button).disabled, "layar judul: Lanjutkan aktif setelah ada simpanan")
	await _shot("judul_lanjut.png")
	current_scene.call("_on_continue")
	await create_timer(0.5).timeout
	_expect(current_scene.name == "World" and not current_scene.get("_busy") and not (current_scene.get("_npc_at") as Dictionary).has(Vector2i(12, 2)), "Lanjutkan membuka peta tanpa Mira di tepi hutan")

	var file := FileAccess.open(_game.save_path, FileAccess.WRITE)
	file.store_string("{ rusak")
	file.close()
	_expect(not _game.load_game() and _game.party.size() == 2, "simpanan rusak ditolak tanpa mengubah keadaan")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_game.save_path))

	# ================= Wilayah 2: Hutan Kabut =================
	# --- Dusun Embun ---
	var dusun_door := WorldMap.find_in("dunia", "D")
	await _open_world("dunia", dusun_door + Vector2i(-2, 0))
	current_scene.call("_walk_to", dusun_door)
	await _wait_until(func() -> bool: return _game.map_id == "dusun" and not current_scene.get("_busy"))
	_expect(_game.map_id == "dusun" and _game.player_tile == WorldMap.MAPS["dusun"].spawn, "masuk Dusun Embun dari peta dunia")
	await _shot("dusun.png")
	current_scene.call("_talk", "laras")
	await _skip_dialog()
	_expect(_game.flags.has("quest_selene"), "Tetua Elowen memberi tugas mencari Selene")
	_game.gold = 100
	(_game.party[0] as Battler).hp = 3
	current_scene.call("_talk", "wiryo")
	await _skip_dialog()
	_expect(_game.gold == 80 and (_game.party[0] as Battler).hp == (_game.party[0] as Battler).max_hp, "penginapan dusun: 20 emas, HP pulih (emas=%d)" % _game.gold)
	_expect(_game.respawn_map == "dusun", "menginap di dusun menjadikannya titik kembali")
	current_scene.call("_talk", "rumi")
	await _skip_dialog()
	_expect(current_scene.get("_shop_open") and (current_scene.get("_shop_stock") as Array).size() == Db.ITEMS.size(), "warung Nessa menjual semua barang")
	current_scene.emit_signal("shop_closed")
	await _skip_dialog()
	current_scene.call("_walk_to", WorldMap.find("X"))
	await _wait_until(func() -> bool: return _game.map_id == "dunia" and not current_scene.get("_busy"))
	_expect(_game.map_id == "dunia" and _game.player_tile == dusun_door, "keluar dusun -> muncul di petak dusun, bukan di Desa Rindu")

	# --- Sarang Ratu tertutup jaring sebelum ada Selene ---
	var nest := WorldMap.find_in("dunia", "Q")
	await _open_world("dunia", nest + Vector2i(-1, 0))
	current_scene.call("_walk_to", nest)
	await _wait_until(func() -> bool: return current_scene.name == "Battle" or current_scene.get("_dialog_open"))
	_expect(current_scene.name == "World" and not _game.flags.has("ratu"), "tanpa Selene: sarang Ratu hanya memunculkan dialog")
	await _skip_dialog()

	# --- Menolong Selene ---
	_set_levels(10)
	await _open_world("dunia", Vector2i(34, 6))
	await _shot("peta_selene.png")
	current_scene.call("_talk", "selene")
	await _skip_dialog()
	await _play_battle()
	_expect(current_scene.name == "World" and current_scene.get("_dialog_open"), "setelah menang, adegan lanjutan Selene tampil")
	await _skip_dialog()
	_expect(_game.party.size() == 3 and (_game.party[2] as Battler).id == "selene", "Selene masuk party")
	_expect((current_scene.get("_npc_at") as Dictionary).is_empty(), "Selene hilang dari peta setelah bergabung")

	# --- Ratu Laba-laba dan Celah Abu ---
	_set_levels(30)  # cukup tinggi supaya menang pasti walau uji hanya menekan Serang
	var pass_tile := WorldMap.find_in("dunia", "P")
	await _open_world("dunia", nest + Vector2i(-1, 0))
	_expect(not WorldMap.is_walkable(pass_tile, _game.flags), "Celah Abu tertutup sebelum Ratu kalah")
	current_scene.call("_walk_to", nest)
	await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "Battle")
	await _shot("battle_ratu.png")
	await _play_battle()
	_expect(_game.flags.has("ratu"), "penanda Ratu tercatat")
	_expect(current_scene.get("_dialog_open"), "adegan kemenangan atas Ratu tampil")
	await _skip_dialog()
	_expect(WorldMap.is_walkable(pass_tile, _game.flags), "Celah Abu terbuka setelah Ratu kalah")
	await _open_world("dunia", pass_tile + Vector2i(-1, 0))
	current_scene.call("_walk_to", WorldMap.find("E"))
	await _wait_until(func() -> bool: return _game.map_id == "abu" and not current_scene.get("_busy"))
	_expect(_game.map_id == "abu" and _game.player_tile == WorldMap.find_in("abu", "W"), "melewati Celah Abu -> tiba di Pegunungan Abu")

	# --- Kalah di Wilayah 2: kembali ke penginapan dusun ---
	_set_levels(1)
	_game.gold = 40
	await _open_world("dunia", Vector2i(30, 6))
	current_scene.call("_start_battle", ["goblin", "goblin", "goblin", "goblin"])
	await _play_battle()
	_expect(_game.map_id == "dusun" and _game.gold == 20, "kalah setelah menginap di dusun -> siuman di dusun (peta=%s, emas=%d)" % [_game.map_id, _game.gold])

	# ================= Wilayah 3: Pegunungan Abu =================
	_set_levels(12)
	var west := WorldMap.find_in("abu", "W")
	await _open_world("abu", west + Vector2i(3, 0))
	await _shot("abu.png")
	current_scene.call("_walk_to", west + Vector2i(4, 0))
	await _wait_until(func() -> bool: return current_scene.get("_dialog_open"))
	_expect(current_scene.get("_dialog_open"), "adegan pembuka Pegunungan Abu tampil")
	await _skip_dialog()
	_expect(_game.flags.has("abu_intro"), "adegan Pegunungan Abu hanya sekali")
	current_scene.call("_walk_to", west)
	await _wait_until(func() -> bool: return _game.map_id == "dunia" and not current_scene.get("_busy"))
	_expect(_game.map_id == "dunia" and _game.player_tile == WorldMap.find_in("dunia", "E"), "jalan barat Pegunungan Abu kembali ke Celah Abu")

	# --- Pos Pemburu ---
	var camp := WorldMap.find_in("abu", "K")
	await _open_world("abu", camp + Vector2i(0, 1))
	current_scene.call("_walk_to", camp)
	await _wait_until(func() -> bool: return _game.map_id == "pos" and not current_scene.get("_busy"))
	_expect(_game.map_id == "pos" and _game.player_tile == WorldMap.MAPS["pos"].spawn, "masuk Pos Pemburu dari Pegunungan Abu")
	await _shot("pos.png")
	current_scene.call("_talk", "darma")
	await _skip_dialog()
	_expect(_game.flags.has("quest_kael"), "Tetua Aldric memberi tugas mencari Kael")
	_game.gold = 100
	current_scene.call("_talk", "ningsih")
	await _skip_dialog()
	_expect(_game.gold == 70 and _game.respawn_map == "pos", "pondok singgah: 30 emas dan menjadi titik kembali (emas=%d)" % _game.gold)
	current_scene.call("_talk", "sabar")
	await _skip_dialog()
	_expect(current_scene.get("_shop_open"), "lapak Tobin terbuka")
	current_scene.emit_signal("shop_closed")
	await _skip_dialog()
	current_scene.call("_walk_to", WorldMap.find("X"))
	await _wait_until(func() -> bool: return _game.map_id == "abu" and not current_scene.get("_busy"))
	_expect(_game.map_id == "abu" and _game.player_tile == camp, "keluar pos -> kembali ke Pegunungan Abu, bukan ke peta dunia")

	# --- Kawah tertutup sebelum ada Kael ---
	var crater := WorldMap.find_in("abu", "N")
	await _open_world("abu", crater + Vector2i(-1, 0))
	current_scene.call("_walk_to", crater)
	await _wait_until(func() -> bool: return current_scene.name == "Battle" or current_scene.get("_dialog_open"))
	_expect(current_scene.name == "World" and not _game.flags.has("lahar"), "tanpa Kael: kawah hanya memunculkan dialog")
	await _skip_dialog()

	# --- Menolong Kael ---
	await _open_world("abu", Vector2i(19, 4))
	await _shot("peta_kael.png")
	current_scene.call("_talk", "kael")
	await _skip_dialog()
	await _play_battle()
	_expect(current_scene.name == "World" and current_scene.get("_dialog_open"), "setelah menang, adegan lanjutan Kael tampil")
	await _skip_dialog()
	_expect(_game.party.size() == 4 and (_game.party[3] as Battler).id == "kael", "Kael masuk party: lengkap berempat")
	_expect((current_scene.get("_npc_at") as Dictionary).is_empty(), "Kael hilang dari peta setelah bergabung")

	# --- Raksasa Lahar dan jalan ke Kastil Kelam ---
	_set_levels(38)  # sejak bos diperkuat (v1.2), level 26 tanpa perlengkapan kadang kalah
	var lava_gate := WorldMap.find_in("abu", "R")
	await _open_world("abu", crater + Vector2i(-1, 0))
	_expect(not WorldMap.is_walkable(lava_gate, _game.flags), "jalan lahar tertutup sebelum Raksasa kalah")
	current_scene.call("_walk_to", crater)
	await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "Battle")
	await _shot("battle_lahar.png")
	await _play_battle()
	_expect(_game.flags.has("lahar"), "penanda Raksasa Lahar tercatat")
	if not _game.flags.has("lahar"):
		_print_battle_log()
		print("      | party: ", _game.party.map(func(m: Battler) -> String: return "%s Lv%d HP%d/%d" % [m.id, m.level, m.hp, m.max_hp]))
	_expect(current_scene.get("_dialog_open"), "adegan kemenangan atas Raksasa Lahar tampil")
	await _skip_dialog()
	_expect(WorldMap.is_walkable(lava_gate, _game.flags), "jalan lahar terbuka setelah Raksasa kalah")
	await _open_world("abu", lava_gate + Vector2i(-1, 0))
	current_scene.call("_walk_to", WorldMap.find("Z"))
	await _wait_until(func() -> bool: return _game.map_id == "kastil" and not current_scene.get("_busy"))
	_expect(_game.map_id == "kastil" and _game.player_tile == WorldMap.find_in("kastil", "V"), "jalan lahar -> tiba di gerbang Kastil Kelam")

	# --- Kalah di Wilayah 3: kembali ke Pos Pemburu ---
	_set_levels(1)
	_game.gold = 60
	await _open_world("abu", Vector2i(10, 4))
	current_scene.call("_start_battle", ["golem_batu", "golem_batu", "golem_batu", "golem_batu"])
	await _play_battle()
	_expect(_game.map_id == "pos" and _game.gold == 30, "kalah setelah menginap di pos -> siuman di pos (peta=%s, emas=%d)" % [_game.map_id, _game.gold])

	# ================= Wilayah 4: Kastil Kelam =================
	_set_levels(20)
	var castle_gate := WorldMap.find_in("kastil", "V")
	await _open_world("kastil", castle_gate)
	await _shot("kastil.png")
	current_scene.call("_walk_to", castle_gate + Vector2i(0, -1))
	await _wait_until(func() -> bool: return current_scene.get("_dialog_open"))
	_expect(current_scene.get("_dialog_open"), "adegan pembuka Kastil Kelam tampil")
	await _skip_dialog()
	_expect(_game.flags.has("kastil_intro"), "adegan Kastil Kelam hanya sekali")
	current_scene.call("_walk_to", castle_gate)
	await _wait_until(func() -> bool: return _game.map_id == "abu" and not current_scene.get("_busy"))
	_expect(_game.map_id == "abu" and _game.player_tile == WorldMap.find_in("abu", "Z"), "gerbang kastil kembali ke Pegunungan Abu")

	# --- Altar Cahaya ---
	var altar := WorldMap.find_in("kastil", "A")
	await _open_world("kastil", altar + Vector2i(1, 0))
	(_game.party[0] as Battler).hp = 4
	current_scene.call("_walk_to", altar)
	await _wait_until(func() -> bool: return current_scene.get("_dialog_open"))
	await _shot("altar.png")
	await _skip_dialog()
	_expect((_game.party[0] as Battler).hp == (_game.party[0] as Battler).max_hp and _game.respawn_map == "kastil", "berdoa di altar memulihkan party dan menjadi titik kembali")

	# --- Raja Monster, adegan penutup, layar tamat ---
	_set_levels(55)
	var throne := WorldMap.find_in("kastil", "M")
	await _open_world("kastil", throne + Vector2i(0, 1))
	current_scene.call("_walk_to", throne)
	await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "Battle")
	await _shot("battle_raja.png")
	await _play_battle()
	_expect(_game.flags.has("raja"), "penanda Raja Monster tercatat")
	if not _game.flags.has("raja"):
		_print_battle_log()
	_expect(current_scene.name == "World" and current_scene.get("_dialog_open"), "adegan penutup tampil setelah Raja Monster kalah")
	await _skip_dialog()
	await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "Ending", 100)
	_expect(current_scene.name == "Ending", "setelah adegan penutup, layar tamat terbuka")
	await create_timer(0.3).timeout
	await _shot("tamat.png")
	_expect(_game.has_save(), "permainan disimpan saat tamat")
	(root.gui_get_focus_owner() as Button).pressed.emit()
	await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "Title", 100)
	_expect(current_scene.name == "Title" and not (current_scene.get("_continue") as Button).disabled, "dari layar tamat kembali ke judul, Lanjutkan aktif")
	current_scene.call("_on_continue")
	await create_timer(0.5).timeout
	_expect(current_scene.name == "World" and _game.map_id == "kastil" and _game.flags.has("raja") and not current_scene.get("_busy"),
		"Lanjutkan setelah tamat: kembali di kastil, Raja sudah kalah, tanpa adegan terulang")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_game.save_path))

	# --- Kalah: kembali ke penginapan desa, emas tinggal setengah ---
	_game.new_game()
	_game.pending_scene = ""
	_game.gold = 100
	await _open_world("dunia", Vector2i(13, 4))
	current_scene.call("_start_battle", ["goblin", "goblin", "goblin", "goblin"])
	await _play_battle()
	_expect(_game.map_id == "desa" and _game.player_tile == _game.START_TILE, "kalah -> kembali ke penginapan desa")
	_expect(_game.gold == 50, "kalah -> emas tinggal setengah (emas=%d)" % _game.gold)

	if _shot_dir != "":
		Engine.time_scale = 1.0
		_game.party = [Battler.from_character("arlen", 5), Battler.from_character("selene", 5),
			Battler.from_character("mira", 5), Battler.from_character("kael", 5)]
		# [file, monster, latar, jurus yang dipratinjau ("-" = tidak ada, "" = serangan biasa), jeda sebelum memotret]
		for case: Array in [
			["battle_hutan.png", ["jamur", "kelelawar", "serigala", "goblin"], "hutan", "-", 0.0],
			["battle_ancang.png", ["jamur", "jamur", "kelelawar"], "lembah", "", 0.08],
			["battle_serang.png", ["jamur", "jamur", "kelelawar"], "lembah", "", 0.36],
			["battle_bidik.png", ["jamur", "jamur", "kelelawar"], "lembah", "bidik_jitu", 0.1],
			["battle_api.png", ["goblin", "goblin"], "kabut", "bola_api", 0.36],
			["battle_es.png", ["serigala", "kelelawar", "kelelawar"], "lembah", "badai_es", 0.8],
			["battle_panah.png", ["serigala", "serigala"], "hutan", "hujan_panah", 0.6],
			["battle_gua.png", ["ogre"], "gua", "hantaman_bumi", 0.45],
		]:
			_game.encounter = case[1]
			_game.backdrop = case[2]
			change_scene_to_file("res://scenes/battle.tscn")
			await create_timer(1.2).timeout
			if case[3] != "-":
				current_scene.call("_preview_fx", case[3])
				await create_timer(case[4]).timeout
			await _shot(case[0])

		# Tampilan efek status: beberapa efek dipasang langsung, lalu layar diperbarui.
		_game.encounter = ["jamur", "serigala", "kelelawar"]
		_game.backdrop = "lembah"
		change_scene_to_file("res://scenes/battle.tscn")
		await create_timer(1.2).timeout
		var eng: BattleEngine = current_scene.get("engine")
		var log: Array = []
		for pair: Array in [[eng.enemies[0], "burn"], [eng.enemies[1], "attack_up"], [eng.enemies[1], "poison"],
				[eng.enemies[2], "slow"], [eng.party[0], "attack_up"], [eng.party[1], "burn"],
				[eng.party[2], "poison"], [eng.party[2], "defense_up"], [eng.party[3], "immunity"]]:
			eng.apply_status(pair[0], pair[1], log)
		current_scene.call("_refresh")
		await create_timer(0.2).timeout
		await _shot("battle_status.png")

		# Menu Barang di battle: pilih Ramuan untuk Selene, lalu pastikan perintahnya tercatat.
		_game.items = {"ramuan": 1, "air_kehidupan": 1}
		(eng.party[1] as Battler).hp = 5
		current_scene.call("_start_round")
		current_scene.call("_item_menu", eng.party[0])
		await create_timer(0.2).timeout
		await _shot("battle_barang.png")
		var bag: Control = current_scene.get("_bag")
		_expect(bag.visible, "battle: perintah Barang membuka tampilan tas")
		bag.emit_signal("picked", "ramuan")
		await create_timer(0.1).timeout
		_expect(not bag.visible, "battle: tas tertutup setelah barang dipilih")
		(root.gui_get_focus_owner() as Button).pressed.emit()  # sasaran pertama: Arlen
		var queued: Array = current_scene.get("_commands")
		_expect(queued.size() == 1 and queued[0].kind == "item" and queued[0].item == "ramuan", "battle: memilih barang mencatat perintah item")
		_expect(current_scene.call("_available", "ramuan") == 0, "battle: Ramuan terakhir tidak bisa dipesan dua kali dalam satu ronde")

		# Memilih sasaran dengan mouse: klik monster kedua untuk Serang, lalu klik rekan untuk Pulih.
		current_scene.call("_start_round")
		_expect((current_scene.get("_banner") as Label).text.begins_with("Pilih perintah untuk Arlen"), "banner menyebut giliran siapa yang memilih perintah")
		_expect((current_scene.get("_active_ring") as Node2D).visible, "lingkaran penanda ada di kaki tokoh yang sedang memilih")
		(root.gui_get_focus_owner() as Button).pressed.emit()  # Serang
		await create_timer(0.1).timeout
		var foe: Battler = eng.enemies[1]
		var foe_rect: Rect2 = (current_scene.get("_units") as Dictionary)[foe].rect
		_expect(current_scene.call("_unit_at", foe_rect.get_center()) == foe, "titik di atas monster dikenali sebagai sasaran")
		await _mouse(foe_rect.get_center(), false)
		await _shot("battle_sasaran.png")
		await _mouse(foe_rect.get_center(), true)
		queued = current_scene.get("_commands")
		_expect(queued.size() == 1 and queued[0].kind == "attack" and queued[0].target == foe, "klik monster di arena memilihnya sebagai sasaran Serang")
		_expect(((current_scene.get("_units") as Dictionary)[eng.party[0]].plan as Label).text == "Serang > %s" % foe.display_name, "perintah yang dipilih tampil di atas kepala tokoh")
		current_scene.call("_choose_skill", eng.party[2], "pulih")
		var ally: Battler = eng.party[1]
		var ally_rect: Rect2 = (current_scene.get("_units") as Dictionary)[ally].rect
		await _mouse(ally_rect.get_center(), true)
		queued = current_scene.get("_commands")
		_expect(queued.size() == 2 and queued[1].kind == "skill" and queued[1].target == ally, "klik rekan di arena memilihnya sebagai sasaran Pulih")
		await _shot("battle_rencana.png")
		var stat_row: Dictionary = (current_scene.get("_party_rows") as Array)[0]
		_expect((stat_row["atk"] as Label).text.begins_with("ATK ") and (stat_row["defense"] as Label).text.begins_with("DEF ") and (stat_row["agi"] as Label).text.begins_with("SPD "), "panel party menampilkan ATK, DEF, dan SPD")

		# Layar hasil pertarungan: Arlen diturunkan ke level 1 supaya naik level, Kael dibuat tumbang.
		var hero: Battler = eng.party[0]
		hero.level = 1
		hero.recalc()
		hero.xp = 4
		(eng.party[3] as Battler).hp = 0
		var gold_before: int = _game.gold
		for e: Battler in eng.enemies:
			e.hp = 0
		current_scene.call("_victory")
		await _wait_until(func() -> bool: return current_scene.get("_results") != null and not current_scene.get("_results_running"), 200)
		await create_timer(0.3).timeout
		await _shot("battle_hasil.png")
		_expect((current_scene.get("_results") as Control).visible and not current_scene.get("_results_running"), "menang: layar hasil pertarungan tampil sampai selesai menghitung")
		_expect(hero.level == 2 and hero.xp == 4 + 17 - Db.xp_to_next(1), "hasil: Arlen naik ke Lv 2, sisa XP benar (Lv %d, XP %d)" % [hero.level, hero.xp])
		_expect((eng.party[3] as Battler).xp == 0 and (eng.party[3] as Battler).hp == 1, "hasil: anggota yang tumbang tidak mendapat XP dan bangkit dengan 1 HP")
		_expect(_game.gold == gold_before + 11, "hasil: emas bertambah (+%d)" % (_game.gold - gold_before))
		current_scene.emit_signal("results_closed")
		await _wait_until(func() -> bool: return current_scene != null and current_scene.name == "World", 100)
		_expect(current_scene.name == "World", "hasil: Lanjut mengembalikan ke peta")

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


# ---------------------------------------------------------------- alat bantu

func _open_world(map_id: String, tile: Vector2i) -> void:
	_game.map_id = map_id
	_game.player_tile = tile
	change_scene_to_file("res://scenes/world.tscn")
	await create_timer(0.5).timeout


func _set_levels(level: int) -> void:
	for m: Battler in _game.party:
		m.level = level
		m.recalc()
		m.full_restore()


func _wait_until(condition: Callable, tries: int = 400) -> void:
	for i in tries:
		await create_timer(0.05).timeout
		if current_scene != null and condition.call():
			return


## Lewati dialog: tekan "lanjut", dan pilih pilihan pertama kalau ada. Berhenti saat dialog
## selesai atau saat scene berganti ke battle.
func _skip_dialog() -> void:
	for i in 600:
		await create_timer(0.05).timeout
		if current_scene == null:
			continue
		if current_scene.name != "World" or not current_scene.get("_busy") or current_scene.get("_shop_open") or current_scene.get("_forge_open"):
			return
		var focus := root.gui_get_focus_owner()
		if focus is Button and focus.is_visible_in_tree():
			(focus as Button).pressed.emit()
		elif current_scene.get("_dialog_open"):
			current_scene.set("_skip_typing", true)  # jangan menunggu teks selesai mengetik
			if not current_scene.get("_typing"):
				current_scene.emit_signal("advance")
	_expect(false, "dialog selesai dalam batas waktu")


## Tekan tombol yang sedang fokus berulang-ulang sampai kembali ke peta.
func _play_battle() -> void:
	await _wait_until(func() -> bool: return current_scene.name == "Battle", 100)
	_expect(current_scene.name == "Battle", "masuk layar battle")
	for i in 6000:
		await create_timer(0.05).timeout
		if current_scene == null:
			continue
		if current_scene.name == "World":
			await create_timer(0.3).timeout
			return
		_battle_log = (current_scene.get("_log") as RichTextLabel).get_parsed_text()
		var focus := root.gui_get_focus_owner()
		if focus is Button and not (focus as Button).disabled:
			(focus as Button).pressed.emit()
	_expect(false, "battle selesai dalam batas waktu")


## Cetak akhir jalannya battle terakhir (dipakai saat sebuah harapan tentang hasil battle gagal).
func _print_battle_log() -> void:
	var lines := _battle_log.split("\n")
	for line: String in lines.slice(max(0, lines.size() - 14)):
		print("      | ", line)


func _check_maps() -> void:
	for map_id: String in WorldMap.MAPS:
		WorldMap.current = map_id
		for y in WorldMap.height():
			for ch in (WorldMap.rows()[y] as String):
				if not WorldMap.TILES.has(ch):
					_expect(false, "karakter peta dikenal: '%s' di %s baris %d" % [ch, map_id, y])

	WorldMap.current = "desa"
	var village := _reachable(_game.START_TILE, {})
	_expect(village.has(WorldMap.find("X")), "jalan keluar desa terjangkau dari titik mulai")
	for npc: Dictionary in Story.NPCS["desa"]:
		var near := false
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			near = near or village.has(npc.tile + d)
		_expect(near and WorldMap.is_walkable(npc.tile, {}), "%s berdiri di petak yang bisa dihampiri" % npc.name)

	WorldMap.current = "dusun"
	var hamlet := _reachable(WorldMap.MAPS["dusun"].spawn, {})
	_expect(hamlet.has(WorldMap.find("X")), "jalan keluar dusun terjangkau dari titik masuk")
	for npc: Dictionary in Story.NPCS["dusun"]:
		var near := false
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			near = near or hamlet.has(npc.tile + d)
		_expect(near and WorldMap.is_walkable(npc.tile, {}), "%s berdiri di petak yang bisa dihampiri" % npc.name)

	WorldMap.current = "pos"
	var camp_tiles := _reachable(WorldMap.MAPS["pos"].spawn, {})
	_expect(camp_tiles.has(WorldMap.find("X")), "jalan keluar pos terjangkau dari titik masuk")
	for npc: Dictionary in Story.NPCS["pos"]:
		var near := false
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			near = near or camp_tiles.has(npc.tile + d)
		_expect(near and WorldMap.is_walkable(npc.tile, {}), "%s berdiri di petak yang bisa dihampiri" % npc.name)

	WorldMap.current = "abu"
	var ash := _reachable(WorldMap.find("W"), {})
	_expect(ash.has(WorldMap.find("K")) and ash.has(Vector2i(19, 4)) and ash.has(WorldMap.find("N")), "pos, tempat Kael, dan kawah terjangkau dari jalan masuk Pegunungan Abu")
	_expect(not ash.has(WorldMap.find("Z")), "jalan ke Kastil Kelam tertutup sebelum Raksasa kalah")
	_expect(_reachable(WorldMap.find("W"), {"lahar": true}).has(WorldMap.find("Z")), "jalan ke Kastil Kelam terjangkau setelah Raksasa kalah")

	WorldMap.current = "kastil"
	var castle := _reachable(WorldMap.find("V"), {})
	_expect(castle.has(WorldMap.find("A")) and castle.has(WorldMap.find("M")), "altar dan takhta terjangkau dari gerbang kastil")
	var sealed := 0
	for y in WorldMap.height():
		for x in WorldMap.width():
			if WorldMap.char_at(Vector2i(x, y)) in ["o", "d", "C"] and not castle.has(Vector2i(x, y)):
				sealed += 1
	_expect(sealed == 0, "semua ruang kastil terjangkau (terisolasi: %d petak)" % sealed)

	WorldMap.current = "dunia"
	var start := WorldMap.find("T")
	var closed := _reachable(start, {})
	var opened := _reachable(start, {"ogre": true})
	_expect(closed.has(WorldMap.find("B")), "sarang semi-bos terjangkau dari desa")
	_expect(closed.has(Vector2i(13, 2)), "tempat Mira terjangkau dari desa")
	var leak := 0
	var region2 := 0
	var region2_open := 0
	for y in WorldMap.height():
		for x in WorldMap.width():
			var t := Vector2i(x, y)
			if WorldMap.char_at(t) in [",", "F"]:
				region2 += 1
				if closed.has(t):
					leak += 1
				if opened.has(t):
					region2_open += 1
	_expect(leak == 0, "Hutan Kabut tertutup selama gerbang terkunci (bocor: %d petak)" % leak)
	_expect(opened.has(WorldMap.find("D")) and opened.has(Vector2i(34, 6)) and opened.has(WorldMap.find("Q")), "dusun, tempat Selene, dan sarang Ratu terjangkau setelah gerbang terbuka")
	_expect(not opened.has(WorldMap.find("E")), "ujung jalan tertutup sebelum Ratu kalah")
	_expect(_reachable(start, {"ogre": true, "ratu": true}).has(WorldMap.find("E")), "ujung jalan terjangkau setelah Ratu kalah")
	_expect(region2_open == region2, "seluruh Hutan Kabut terjangkau setelah gerbang terbuka (%d/%d)" % [region2_open, region2])


func _reachable(start: Vector2i, flags: Dictionary) -> Dictionary:
	var seen := {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var t: Vector2i = queue.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := t + d
			if not seen.has(n) and WorldMap.is_walkable(n, flags):
				seen[n] = true
				queue.append(n)
	return seen


## Gerakkan mouse ke sebuah titik layar; click = tekan tombol kiri di sana.
func _mouse(at: Vector2, click: bool) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	Input.parse_input_event(move)
	await create_timer(0.1).timeout
	if click:
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = at
		press.global_position = at
		Input.parse_input_event(press)
		await create_timer(0.1).timeout


func _shot(file_name: String) -> void:
	if _shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_shot_dir.path_join(file_name))


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
