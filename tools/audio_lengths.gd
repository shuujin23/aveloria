extends SceneTree
## Cetak durasi semua file audio di assets/audio (alat bantu memilih suara).
func _init() -> void:
	for sub: String in ["music", "sfx"]:
		var dir := "res://assets/audio/%s/" % sub
		var names: Array = []
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".ogg") or f.ends_with(".wav"):
				names.append(f)
		names.sort()
		var parts: Array = []
		for f: String in names:
			var stream: AudioStream = load(dir + f)
			parts.append("%s=%.1fs" % [f.get_basename(), stream.get_length()])
		print("%s: %s" % [sub, ", ".join(parts)])
	quit()
