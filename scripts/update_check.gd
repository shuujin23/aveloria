class_name UpdateCheck
extends RefCounted
## Pemeriksa versi baru: membandingkan versi game ini (application/config/version di project.godot)
## dengan rilis terbaru di GitHub. Hanya memberi tahu; pemain mengunduh sendiri dari halaman rilis.

const API_URL := "https://api.github.com/repos/shuujin23/aveloria/releases/latest"
const PAGE_URL := "https://github.com/shuujin23/aveloria/releases/latest"
const TIMEOUT := 8.0


static func current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0"))


## Apakah versi `remote` (mis. "v1.3" atau "1.3.1") lebih baru daripada `local`.
static func is_newer(remote: String, local: String) -> bool:
	var a := _parts(remote)
	var b := _parts(local)
	for i in max(a.size(), b.size()):
		var x: int = a[i] if i < a.size() else 0
		var y: int = b[i] if i < b.size() else 0
		if x != y:
			return x > y
	return false


## Nama tag rilis terbaru dari jawaban GitHub; kosong kalau jawabannya tidak bisa dibaca.
static func latest_tag(body: String) -> String:
	var json := JSON.new()
	if json.parse(body) != OK or not (json.data is Dictionary):
		return ""
	return str((json.data as Dictionary).get("tag_name", ""))


static func _parts(version: String) -> Array:
	var out: Array = []
	for piece: String in version.strip_edges().trim_prefix("v").trim_prefix("V").split("."):
		out.append(int(piece))
	return out
