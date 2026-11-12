extends Node
## Autoload "Audio": musik latar, jingle pendek, dan efek suara.
## Untuk mengganti suara, cukup ubah nama file di MUSIC atau SFX (file ada di assets/audio/).
## Sumber dan lisensi tiap file tercatat di assets/audio/KREDIT.md.

const DIR := "res://assets/audio/"
const MUSIC_DB := -10.0
const SFX_DB := -5.0

## Lagu yang berulang terus.
const MUSIC := {
	"title": "music/opening.ogg",
	"desa": "music/town.ogg",
	"dunia": "music/overworld.ogg",
	"battle": "music/danger.ogg",
	"boss": "music/barbarian_king.ogg",
	"kastil": "music/dungeon.ogg",
	"raja": "music/enter_the_emperor.ogg",
	"ending": "music/finale.ogg",
}

## Lagu pendek sekali putar; musik latar berhenti selama jingle berbunyi.
const JINGLES := {
	"victory": "music/victory.ogg",
	"game_over": "music/game_over.ogg",
	"inn": "music/inn.ogg",
	"join": "music/new_comrade.ogg",
	"fanfare": "music/fanfare.ogg",
}

## Efek suara. Kalau berisi beberapa file, satu dipilih acak tiap kali dimainkan.
## vol = tambahan volume dalam dB, pitch = besar variasi nada acak.
const SFX := {
	# antarmuka dan dialog
	# (keempat suara ini dibuat tools/gen_sfx.gd: nada chiptune pendek dan ringan)
	"ui_move": {"files": ["sfx/ui_tick.wav"], "vol": -6.0},
	"ui_ok": {"files": ["sfx/ui_select.wav"], "vol": -4.0},
	"ui_cancel": {"files": ["sfx/ui_back.wav"], "vol": -4.0},
	"text": {"files": ["sfx/text_blip.wav"], "vol": -6.0, "pitch": 0.05},  # "tetetet" saat teks dialog muncul
	"coin": {"files": ["sfx/coin.wav", "sfx/handlecoins.ogg"]},
	"save": {"files": ["sfx/metallatch.ogg"]},
	"potion": {"files": ["sfx/bottle.wav", "sfx/bubble.wav"]},
	# peta
	"step": {"files": ["sfx/footstep00.ogg", "sfx/footstep01.ogg", "sfx/footstep02.ogg", "sfx/footstep03.ogg", "sfx/footstep04.ogg"],
		"vol": -10.0, "pitch": 0.1},
	"door": {"files": ["sfx/dooropen_1.ogg"]},
	"encounter": {"files": ["sfx/sword_unsheathe.wav"], "vol": 2.0},
	# pertarungan
	"swing": {"files": ["sfx/swing.wav", "sfx/swing2.wav", "sfx/swing3.wav"], "vol": 2.0, "pitch": 0.1},
	"slash": {"files": ["sfx/blade_01.ogg", "sfx/blade_02.ogg", "sfx/blade_03.ogg"], "pitch": 0.08},
	"heavy_slash": {"files": ["sfx/knifeslice.ogg", "sfx/knifeslice2.ogg"], "vol": 3.0, "pitch": 0.06},
	"arrow": {"files": ["sfx/drawknife1.ogg"], "pitch": 0.1},
	"bite": {"files": ["sfx/bite_small.wav", "sfx/wolfman.wav"], "vol": 2.0},
	"fire": {"files": ["sfx/spell_fire_01.ogg", "sfx/spell_fire_02.ogg"]},
	"ice": {"files": ["sfx/spell.wav"], "vol": -3.0},
	"magic": {"files": ["sfx/magic1.wav"]},
	"heal": {"files": ["sfx/spell_01.ogg"]},
	"buff": {"files": ["sfx/item_gem_01.ogg", "sfx/spell_02.ogg"]},
	"debuff": {"files": ["sfx/misc_01.ogg"]},
	"roar": {"files": ["sfx/ogre1.wav", "sfx/creature_roar_01.ogg", "sfx/giant1.wav"], "vol": 2.0},
	"slime": {"files": ["sfx/creature_slime_01.ogg", "sfx/slime1.wav"]},
	"quake": {"files": ["sfx/stones_01.ogg"], "vol": 4.0},
	"guard": {"files": ["sfx/metalclick.ogg"]},
	"enemy_hurt": {"files": ["sfx/creature_hurt_01.ogg", "sfx/creature_hurt_02.ogg"], "pitch": 0.1},
	"enemy_die": {"files": ["sfx/creature_die_01.ogg"]},
	# monster kecil (voice = "soft" di Db.ENEMIES): suara ringan buatan tools/gen_sfx.gd
	"soft_hurt": {"files": ["sfx/hit_soft.wav"], "vol": -2.0, "pitch": 0.12},
	"soft_die": {"files": ["sfx/pop.wav"], "vol": -2.0},
	"hero_hurt": {"files": ["sfx/chop.ogg"], "vol": 2.0, "pitch": 0.1},
	"flee": {"files": ["sfx/cloth1.ogg"]},
}

var _music: AudioStreamPlayer
var _jingle: AudioStreamPlayer
var _pool: Array = []  # beberapa pemutar supaya efek suara bisa bertumpuk
var _next := 0
var _current := ""  # kunci musik yang sedang (atau akan kembali) dimainkan
var _streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	_jingle = AudioStreamPlayer.new()
	_jingle.volume_db = MUSIC_DB
	_jingle.finished.connect(_resume_music)
	add_child(_jingle)
	for i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)


## Ganti musik latar. Tidak melakukan apa-apa kalau lagu itu sudah berjalan.
func play_music(key: String) -> void:
	if key == _current and (_music.playing or _jingle.playing):
		return
	_current = key
	_jingle.stop()
	_start_music()


## Mainkan jingle sekali; musik latar berhenti dulu dan lanjut lagi setelah jingle selesai.
## resume = false: musik tidak dilanjutkan (dipakai untuk menang/kalah, sampai scene berganti).
func play_jingle(key: String, resume: bool = true) -> void:
	var stream := _load(JINGLES.get(key, ""))
	if stream == null:
		return
	_set_loop(stream, false)
	_music.stop()
	if not resume:
		_current = ""
	_jingle.stream = stream
	_jingle.play()


func stop_music() -> void:
	_current = ""
	_music.stop()
	_jingle.stop()


func sfx(key: String) -> void:
	if not SFX.has(key):
		return
	var entry: Dictionary = SFX[key]
	var files: Array = entry.files
	var stream := _load(files[randi() % files.size()])
	if stream == null:
		return
	var player: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = stream
	player.volume_db = SFX_DB + float(entry.get("vol", 0.0))
	var spread := float(entry.get("pitch", 0.0))
	player.pitch_scale = 1.0 + randf_range(-spread, spread)
	player.play()


func _resume_music() -> void:
	if _current != "":
		_start_music()


func _start_music() -> void:
	var stream := _load(MUSIC.get(_current, ""))
	if stream == null:
		_music.stop()
		return
	_set_loop(stream, true)
	_music.stream = stream
	_music.play()


func _load(path: String) -> AudioStream:
	if path == "":
		return null
	if not _streams.has(path):
		_streams[path] = load(DIR + path) if ResourceLoader.exists(DIR + path) else null
	return _streams[path]


func _set_loop(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
