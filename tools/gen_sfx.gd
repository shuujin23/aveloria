extends SceneTree
## Pembuat efek suara chiptune pendek (blip dialog dan suara menu). Hasilnya di assets/audio/sfx/.
##   Godot_console.exe --headless --path . -s res://tools/gen_sfx.gd
## Setelah itu jalankan "--import". Ubah angka di _init() untuk mengganti nada, panjang, atau volume.

const RATE := 22050
const OUT := "res://assets/audio/sfx/"


func _init() -> void:
	# Tiap suara: daftar [frekuensi Hz, lama detik], bentuk gelombang, volume 0..1.
	_save("text_blip", _tone([[760.0, 0.030]], "square", 0.22))  # "tet" per huruf dialog
	_save("ui_tick", _tone([[1320.0, 0.020]], "triangle", 0.30))  # menyorot tombol
	_save("ui_select", _tone([[990.0, 0.030], [1480.0, 0.050]], "triangle", 0.34))  # memilih: dua nada naik
	_save("ui_back", _tone([[880.0, 0.030], [590.0, 0.050]], "triangle", 0.34))  # batal: dua nada turun
	# Monster kecil (jamur, kelelawar): bunyi "puk" dan "pop" ringan, bukan geraman.
	_save("hit_soft", _tone([[440.0, 0.020], [340.0, 0.020], [260.0, 0.030]], "triangle", 0.42))
	_save("pop", _tone([[620.0, 0.030], [470.0, 0.030], [330.0, 0.045], [220.0, 0.060]], "triangle", 0.40))
	quit()


func _tone(notes: Array, wave: String, volume: float) -> PackedByteArray:
	var data := PackedByteArray()
	for note: Array in notes:
		var freq: float = note[0]
		var count := int(float(note[1]) * RATE)
		for i in count:
			var phase := fmod(float(i) / RATE * freq, 1.0)
			var sample: float = 4.0 * absf(phase - 0.5) - 1.0  # segitiga: lembut
			if wave == "square":
				sample = 1.0 if phase < 0.5 else -1.0  # kotak: khas chiptune
			# Naik cepat (2 ms) supaya tidak "klik", lalu meredup sampai habis.
			var attack: float = min(1.0, float(i) / (0.002 * RATE))
			var envelope := attack * pow(1.0 - float(i) / count, 1.5)
			var value := int(clampf(sample * envelope * volume, -1.0, 1.0) * 32767.0)
			data.append(value & 0xFF)
			data.append((value >> 8) & 0xFF)
	return data


func _save(sound_name: String, data: PackedByteArray) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	stream.save_to_wav(ProjectSettings.globalize_path(OUT + sound_name + ".wav"))
	print("%s: %.0f ms" % [sound_name, data.size() / 2.0 / RATE * 1000.0])
