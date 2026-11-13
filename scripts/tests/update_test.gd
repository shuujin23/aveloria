extends SceneTree
## Uji pemeriksa versi tanpa jaringan dan tampilan tombolnya di layar judul.
##   Godot_console.exe --headless --path . -s res://scripts/tests/update_test.gd
## Tambahkan "-- C:/folder" (tanpa --headless) untuk menyimpan screenshot di folder itu.

var _failed := false


func _initialize() -> void:
	_expect(UpdateCheck.is_newer("v1.3", "1.2"), "v1.3 lebih baru dari 1.2")
	_expect(UpdateCheck.is_newer("1.10", "1.9"), "1.10 lebih baru dari 1.9 (dibandingkan sebagai angka)")
	_expect(UpdateCheck.is_newer("v1.2.1", "1.2"), "1.2.1 lebih baru dari 1.2")
	_expect(UpdateCheck.is_newer("2.0", "1.9.9"), "2.0 lebih baru dari 1.9.9")
	_expect(not UpdateCheck.is_newer("v1.2", "1.2"), "versi yang sama bukan versi baru")
	_expect(not UpdateCheck.is_newer("v1.2.0", "1.2"), "1.2.0 sama dengan 1.2")
	_expect(not UpdateCheck.is_newer("v1.1", "1.2"), "versi lama bukan versi baru")
	_expect(UpdateCheck.latest_tag('{"tag_name": "v1.3", "name": "Aveloria v1.3"}') == "v1.3", "tag dibaca dari jawaban GitHub")
	_expect(UpdateCheck.latest_tag("<html>rusak</html>") == "" and UpdateCheck.latest_tag("[]") == "", "jawaban yang tidak terbaca diabaikan")
	_expect(UpdateCheck.current_version() == "1.2.1", "versi game ini tercatat di project.godot (%s)" % UpdateCheck.current_version())

	AudioServer.set_bus_mute(0, true)
	change_scene_to_file("res://scenes/title.tscn")
	await create_timer(0.3).timeout
	current_scene.call("_offer_update", "v%s" % UpdateCheck.current_version())
	_expect(current_scene.get("_update_button") == null, "layar judul: tidak ada tombol kalau versinya sama")
	current_scene.call("_offer_update", "")
	_expect(current_scene.get("_update_button") == null, "layar judul: tidak ada tombol kalau pemeriksaan gagal")
	current_scene.call("_offer_update", "v9.9")
	var button: Button = current_scene.get("_update_button")
	_expect(button != null and button.text.contains("9.9"), "layar judul: tombol unduh muncul kalau ada versi baru")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		await create_timer(0.2).timeout
		root.get_texture().get_image().save_png(args[0].path_join("judul_versi_baru.png"))

	print("HASIL: %s" % ("ADA YANG GAGAL" if _failed else "SEMUA LOLOS"))
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "GAGAL", what])
	if not ok:
		_failed = true