extends SceneTree
## Uji audio: setiap lagu dan efek suara yang dirujuk kode harus ada dan bisa dimuat.
##   Godot_console.exe --headless --path . -s res://scripts/tests/audio_test.gd

var _failed := false


func _initialize() -> void:
	var audio: Node = root.get_node("Audio")
	var dir: String = audio.DIR

	var missing: Array = []
	var count := 0
	for table: Dictionary in [audio.MUSIC, audio.JINGLES]:
		for key: String in table:
			count += 1
			if not (load(dir + String(table[key])) is AudioStream):
				missing.append("%s -> %s" % [key, table[key]])
	_expect(missing.is_empty(), "%d lagu dan jingle bisa dimuat %s" % [count, missing])

	missing = []
	count = 0
	for key: String in audio.SFX:
		for file: String in audio.SFX[key].files:
			count += 1
			if not (load(dir + file) is AudioStream):
				missing.append("%s -> %s" % [key, file])
	_expect(missing.is_empty(), "%d file efek suara bisa dimuat %s" % [count, missing])

	# Semua kunci suara yang dipakai skrip harus terdaftar.
	var used := {}
	var pattern := RegEx.new()
	pattern.compile("Audio\\.(sfx|play_music|play_jingle)\\(\"([a-z_]+)\"")
	for path: String in ["res://scripts/title.gd", "res://scripts/world/world.gd", "res://scripts/battle/battle_scene.gd"]:
		for found: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(path)):
			used["%s:%s" % [found.get_string(1), found.get_string(2)]] = true
	var battle_script: GDScript = load("res://scripts/battle/battle_scene.gd")
	var fx_sound: Dictionary = battle_script.get_script_constant_map()["FX_SOUND"]
	for sound: String in fx_sound.values():
		used["sfx:%s" % sound] = true
	var unknown: Array = []
	for entry: String in used:
		var kind := entry.get_slice(":", 0)
		var key := entry.get_slice(":", 1)
		var table: Dictionary = audio.SFX if kind == "sfx" else (audio.MUSIC if kind == "play_music" else audio.JINGLES)
		if not table.has(key):
			unknown.append(entry)
	_expect(unknown.is_empty(), "%d pemanggilan suara di kode merujuk kunci yang terdaftar %s" % [used.size(), unknown])

	# Semua jenis animasi jurus punya suara.
	var silent: Array = []
	for skill_id: String in Db.SKILL_FX:
		var fx: String = Db.SKILL_FX[skill_id]
		if fx != "buff_self" and not fx_sound.has(fx):
			silent.append("%s (%s)" % [skill_id, fx])
	_expect(silent.is_empty(), "semua %d jurus punya efek suara %s" % [Db.SKILL_FX.size(), silent])

	# Pemutaran tidak boleh error, termasuk kunci yang tidak dikenal.
	# (Tunggu satu frame: autoload baru selesai disiapkan setelah _initialize.)
	await process_frame
	audio.play_music("desa")
	audio.play_music("battle")
	audio.play_jingle("victory", false)
	audio.sfx("step")
	audio.sfx("tidak_ada")
	audio.play_music("tidak_ada")
	audio.stop_music()
	_expect(true, "memutar musik, jingle, dan efek suara tidak menimbulkan error")

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true
