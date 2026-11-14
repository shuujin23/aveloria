extends SceneTree
## Uji terjemahan: semua teks yang tampil punya padanan Inggris, dan penanda format (%s, %d) cocok.
##   Godot_console.exe --headless --path . -s res://scripts/tests/loc_test.gd

## Nama diri yang sama di kedua bahasa, jadi tidak perlu ada di kamus.
const SAME := ["", "Arlen", "Mira", "Selene", "Kael", "Marla", "Finn", "Doran", "Garrick", "Osric", "Nessa",
	"Halvard", "Brenna", "Tobin", "Varek", "Aveloria", "Gargoyle", "Common", "Rare", "Super Rare", "Ultra Rare"]
const SOURCES := ["battle/battle_engine.gd", "battle/battler.gd", "battle/battle_scene.gd", "world/world.gd", "game.gd",
	"title.gd", "ending.gd", "db.gd", "ui/bag_view.gd", "ui/stats_view.gd", "ui/quest_view.gd", "ui/forge_view.gd", "ui/gear_view.gd", "ui/shop_view.gd"]

var _failed := false
var _missing := {}


func _initialize() -> void:
	# --- Loc.t ---
	Loc.set_lang("id", false)
	_expect(Loc.t("Serang") == "Serang", "bahasa Indonesia: teks sumber dikembalikan apa adanya")
	Loc.set_lang("en", false)
	_expect(Loc.t("Serang") == "Attack", "bahasa Inggris: teks diterjemahkan")
	_expect(Loc.t("Arlen") == "Arlen", "teks di luar kamus dikembalikan apa adanya")
	_expect(Loc.label() == "Language: English", "tulisan tombol bahasa mengikuti bahasa aktif")
	Loc.toggle()
	_expect(Loc.lang() == "id" and Loc.label() == "Bahasa: Indonesia", "toggle: Inggris -> Indonesia")
	Loc.toggle()
	_expect(Loc.lang() == "en", "toggle: Indonesia -> Inggris")
	Loc.set_lang("xx", false)
	_expect(Loc.lang() == Loc.DEFAULT and Loc.DEFAULT == "en", "bahasa tak dikenal jatuh ke bawaan (Inggris)")
	_expect(Db.gear("arlen_weapon_1").name == "Iron Sword", "nama perlengkapan ikut diterjemahkan")
	_expect(Battler.from_enemy("jamur", " A").display_name == "Wild Mushroom A", "nama monster ikut diterjemahkan")
	Loc.set_lang("id", false)
	_expect(Db.gear("arlen_weapon_1").name == "Pedang Besi", "kembali ke Indonesia: nama perlengkapan asli")

	# --- data ---
	for id: String in Db.STATUSES:
		_need(Db.STATUSES[id].name, "status")
	for id: String in Db.SKILLS:
		_need(Db.SKILLS[id].name, "jurus")
		_need(Db.SKILLS[id].desc, "jurus")
	for id: String in Db.ITEMS:
		_need(Db.ITEMS[id].name, "barang")
		_need(Db.ITEMS[id].desc, "barang")
	for id: String in Db.MATERIALS:
		_need(Db.MATERIALS[id].name, "bahan")
	for id: String in Db.ENEMIES:
		_need(Db.ENEMIES[id].name, "monster")
	for id: String in Db.CHARACTERS:
		_need(Db.CHARACTERS[id].name, "tokoh")
		_need(Db.CHARACTERS[id].job, "tokoh")
	for text: String in Db.REGION_NAMES.values() + Db.GEAR_SLOT_NAMES.values() + Db.TRAIT_WHEN.values():
		_need(text, "db")
	for owner: String in Db.GEAR_NAMES:
		for slot: String in Db.GEAR_NAMES[owner]:
			for text: String in Db.GEAR_NAMES[owner][slot]:
				_need(text, "perlengkapan")
	for id: String in WorldMap.MAPS:
		_need(WorldMap.MAPS[id].name, "peta")
	for ch: String in WorldMap.TILES:
		_need(WorldMap.TILES[ch].zone, "zona")
		_need(WorldMap.TILES[ch].get("locked", ""), "zona")

	# --- cerita: semua adegan, dan dialog tiap NPC di tiap tahap cerita ---
	for key: String in Story.SCENES:
		_need_steps(Story.SCENES[key], "adegan " + key)
	var stages: Array = [{}]
	for flag: String in ["quest_mira", "mira_joined", "ogre", "quest_selene", "selene_joined", "ratu", "quest_kael", "kael_joined", "lahar"]:
		stages.append({flag: true})
	for map_id: String in Story.NPCS:
		for npc: Dictionary in Story.NPCS[map_id]:
			_need(npc.name, "npc")
			for flags: Dictionary in stages:
				for gold: int in [0, 999]:
					_need_steps(Story.talk(npc.id, flags, gold), "dialog " + npc.id)

	# --- side quest ---
	for id: String in Quests.LIST:
		var q: Dictionary = Quests.LIST[id]
		for text: String in [q.name, q.place, q.goal, q.back, q.remind] + (q.offer as Array) + (q.thanks as Array):
			_need(text, "quest " + id)
		_need_steps(Story.scene("q_%s_won" % id), "quest " + id)
		_expect(not Story.scene("q_%s_won" % id).is_empty() and Db.BOSSES.has(q.boss) and Story.npc(q.giver).has("name"),
			"quest %s punya adegan menang, penjaga, dan pemberi" % id)
	for text: String in Quests.STATE_LABELS.values() + ["Quest baru: %s", "Quest selesai: %s"]:
		_need(text, "quest")

	# --- konstanta teks di layar ---
	var forge: Dictionary = (load("res://scripts/ui/forge_view.gd") as GDScript).get_script_constant_map()
	for text: String in (forge.TABS as Array) + (forge.TAB_HINTS as Array):
		_need(text, "pandai besi")
	for text: String in ((load("res://scripts/ui/stats_view.gd") as GDScript).get_script_constant_map().HINTS as Dictionary).values():
		_need(text, "status")
	for text: String in (load("res://scripts/ending.gd") as GDScript).get_script_constant_map().CREDITS:
		_need(text, "penutup")

	# --- teks di kode: tiap Loc.t("...") harus ada di kamus ---
	var literal := RegEx.new()
	literal.compile("Loc\\.t\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	var wrapped := 0
	for path: String in SOURCES:
		var source := FileAccess.get_file_as_string("res://scripts/" + path)
		for found: RegExMatch in literal.search_all(source):
			wrapped += 1
			_need(found.get_string(1).c_unescape(), path)
	_expect(wrapped > 150, "teks di kode yang lewat Loc.t: %d" % wrapped)
	_expect(_missing.is_empty(), "semua teks punya terjemahan Inggris (%d belum)" % _missing.size())
	for text: String in _missing:
		print("      belum ada [%s]: %s" % [_missing[text], text.c_escape()])

	# --- penanda format harus sama urutannya, supaya "%" tidak gagal saat dijalankan ---
	var marker := RegEx.new()
	marker.compile("%[-0-9.]*[sdf%]")
	var bad := 0
	for source: String in LocEn.TEXT:
		var a: Array = []
		var b: Array = []
		for found: RegExMatch in marker.search_all(source):
			a.append(found.get_string())
		for found: RegExMatch in marker.search_all(LocEn.TEXT[source]):
			b.append(found.get_string())
		if a != b:
			bad += 1
			print("      penanda beda: %s  ->  %s" % [source.c_escape(), String(LocEn.TEXT[source]).c_escape()])
	_expect(bad == 0, "penanda format (%%s, %%d) sama di semua terjemahan")

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _need(text: String, where: String) -> void:
	if not SAME.has(text) and not LocEn.TEXT.has(text):
		_missing[text] = where


func _need_steps(steps: Array, where: String) -> void:
	for step: Dictionary in steps:
		_need(step.get("who", ""), where)
		_need(step.get("text", ""), where)
		_need(step.get("name", ""), where)
		for option: Dictionary in step.get("choice", []):
			_need(option.text, where)
			_need_steps(option.steps, where)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
