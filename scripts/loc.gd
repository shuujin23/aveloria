class_name Loc
extends RefCounted
## Bahasa tampilan. Teks sumber di seluruh kode dan data ditulis dalam bahasa Indonesia;
## Loc.t() mengembalikannya apa adanya ("id") atau padanan Inggrisnya dari LocEn.TEXT ("en").
## Teks yang tidak ada di kamus dikembalikan apa adanya, jadi nama diri tidak perlu didaftarkan.
##
## Pilihan bahasa disimpan di user://settings.json. Uji otomatis (dijalankan dengan "-s") selalu
## memakai bahasa Indonesia dan tidak menyentuh file itu, kecuali diberi "-- --lang=en".

const LANGS := ["en", "id"]
const DEFAULT := "en"
const SETTINGS_PATH := "user://settings.json"

static var _lang := ""  # kosong = belum dimuat


static func lang() -> String:
	if _lang == "":
		_lang = _initial()
	return _lang


## Ganti bahasa. save = simpan pilihannya ke file pengaturan.
static func set_lang(code: String, save: bool = true) -> void:
	_lang = code if LANGS.has(code) else DEFAULT
	if save and not _is_test():
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"lang": _lang}))
			file.close()


## Pindah ke bahasa berikutnya.
static func toggle() -> void:
	set_lang(LANGS[(LANGS.find(lang()) + 1) % LANGS.size()])


## Tulisan tombol pilihan bahasa, dalam bahasa yang sedang dipakai.
static func label() -> String:
	return "Language: English" if lang() == "en" else "Bahasa: Indonesia"


static func t(text: String) -> String:
	if lang() == "id":
		return text
	return LocEn.TEXT.get(text, text)


static func _is_test() -> bool:
	return OS.get_cmdline_args().has("-s")


static func _initial() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--lang=") and LANGS.has(arg.trim_prefix("--lang=")):
			return arg.trim_prefix("--lang=")
	if _is_test():
		return "id"
	if FileAccess.file_exists(SETTINGS_PATH):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(SETTINGS_PATH)) == OK and json.data is Dictionary:
			var saved := str((json.data as Dictionary).get("lang", ""))
			if LANGS.has(saved):
				return saved
	return DEFAULT
