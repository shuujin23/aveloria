class_name Quests
extends RefCounted
## Side quest: tugas pilihan dari penduduk, berhadiah perlengkapan langka.
##
## Tiap quest punya pemberi (NPC), satu tempat di peta wilayah yang dijaga monster elite, dan hadiah.
## Jalannya: bicara dengan pemberi (quest diterima) -> kalahkan penjaga di tempat itu -> kembali ke pemberi.
## Penanda di Game.flags:  q_<id> = diterima,  <boss> = penjaganya kalah,  q_<id>_done = hadiah sudah diambil.
##
##   need     penanda cerita yang harus ada sebelum quest ditawarkan
##   giver    id NPC pemberi (lihat Story.NPCS); dialog quest diselipkan sebelum dialog biasanya
##   boss     id monster elite penjaganya (ada di Db.BOSSES dan Db.ENEMIES)
##   backdrop latar battle        place  nama tempatnya (untuk daftar quest)
##   goal     petunjuk selagi quest berjalan        back  petunjuk setelah penjaganya kalah
##   offer / remind / thanks   kalimat pemberi quest: menawarkan, mengingatkan, berterima kasih
##   reward   {"slot", "tier", "rarity", "gold"}: perlengkapan untuk satu anggota party pilihan pemain, plus emas;
##            "for" = tokoh penerimanya (tanpa pilihan); tanpa "slot" = hanya emas
##   hard     quest sulit (ditandai di daftar quest)

const LIST := {
	"perampok": {
		"name": "Palu Warisan", "need": "mira_joined", "giver": "gatot", "boss": "goblin_kepala", "backdrop": "hutan",
		"place": "Sarang Perampok",
		"goal": "Cari sarang perampok di hutan barat daya Lembah Hijau dan kalahkan pemimpinnya.",
		"back": "Kembalikan palu itu kepada Garrick di Desa Rindu.",
		"offer": [
			"Sebelum kalian pergi... Gerombolan goblin mencuri palu tempa warisan ayahku dan membawanya ke sarang mereka di hutan barat daya.",
			"Pemimpin mereka besar dan licik. Kalau kalian bisa merebutnya kembali, akan kutempa senjata terbaikku untuk salah satu dari kalian.",
		],
		"remind": "Sarang goblin itu di hutan barat daya lembah. Hati-hati dengan pemimpinnya.",
		"thanks": ["Palu ayahku! Kalian benar-benar merebutnya kembali.", "Janji adalah janji. Pilih siapa yang akan memakai senjata ini."],
		"reward": {"slot": "weapon", "tier": 1, "rarity": "ultra", "gold": 60},
	},
	"roh_tua": {
		"name": "Lentera Dusun", "need": "selene_joined", "giver": "wiryo", "boss": "roh_tua", "backdrop": "kabut",
		"place": "Altar Tua",
		"goal": "Cari altar tua di sudut barat laut Hutan Kabut dan usir roh yang bersemayam di sana.",
		"back": "Bawa lentera itu kepada Osric di Dusun Embun.",
		"offer": [
			"Kalian yang menolong Selene, ya? Aku punya permintaan.",
			"Lentera penuntun dusun ini dulu tergantung di altar tua di sudut barat laut hutan. Sejak sesosok roh tua bersemayam di sana, tak ada yang berani mengambilnya.",
			"Bawa pulang lentera itu, dan akan kuberikan senjata peninggalan seorang pengembara yang dulu menginap di sini.",
		],
		"remind": "Altar tua itu di sudut barat laut hutan. Roh di sana tidak suka diganggu.",
		"thanks": ["Lentera dusun! Malam ini jalan pulang akan terang lagi.", "Ini janjiku. Pilih siapa yang akan memakainya."],
		"reward": {"slot": "weapon", "tier": 2, "rarity": "ultra", "gold": 150},
	},
	"golem_purba": {
		"name": "Tambang yang Terkubur", "need": "kael_joined", "giver": "sabar", "boss": "golem_purba", "backdrop": "abu",
		"place": "Mulut Tambang",
		"goal": "Cari mulut tambang di sudut barat daya Pegunungan Abu dan singkirkan golem penjaganya.",
		"back": "Kabari Tobin di Pos Pemburu.",
		"offer": [
			"Kalian kelihatan tangguh. Mau dengar tawaran?",
			"Tambang mitril di sudut barat daya pegunungan ini dijaga golem purba sejak gunung mengamuk. Para penambang tak bisa masuk.",
			"Singkirkan dia, dan senjata mitril terbaik di pos ini jadi milik kalian.",
		],
		"remind": "Mulut tambang itu di sudut barat daya. Golemnya lambat, tapi pukulannya meruntuhkan zirah.",
		"thanks": ["Golem itu benar-benar hancur? Para penambang akan bersorak.", "Janji pedagang. Pilih siapa yang akan memakainya."],
		"reward": {"slot": "weapon", "tier": 3, "rarity": "ultra", "gold": 300},
	},
	# --- Quest sulit, satu per tokoh: terbuka setelah Raksasa Lahar kalah, berhadiah senjata Legend tokoh itu. ---
	"pedang_fajar": {
		"name": "Ujian Sang Ksatria", "need": "lahar", "giver": "tetua", "boss": "panglima_kelam", "backdrop": "kastil",
		"place": "Ruang Panglima", "hard": true,
		"goal": "Kalahkan Panglima Kelam di ruang dalam sebelah timur Kastil Kelam.",
		"back": "Bawa Pedang Fajar kepada Tetua Bram di Desa Rindu.",
		"offer": [
			"Arlen. Sebelum kau menantang Raja Monster, ada yang harus kau tahu.",
			"Pedang Fajar, pusaka ksatria desa ini, dirampas Panglima Kelam saat kastil itu jatuh. Ia menjaganya di ruang dalam sebelah timur Kastil Kelam.",
			"Rebut kembali pedang itu. Hanya ksatria yang mengalahkannya yang pantas memegangnya.",
		],
		"remind": "Panglima Kelam ada di ruang dalam sebelah timur Kastil Kelam. Jangan remehkan dia.",
		"thanks": ["Pedang Fajar... Sudah puluhan tahun aku tidak melihat cahayanya.", "Ia memilihmu, Arlen. Bawalah."],
		"reward": {"slot": "weapon", "tier": 3, "rarity": "legend", "for": "arlen", "gold": 400},
	},
	"tongkat_cahaya": {
		"name": "Doa yang Tertinggal", "need": "lahar", "giver": "sari", "boss": "induk_pucat", "backdrop": "lembah",
		"place": "Kapel Runtuh", "hard": true,
		"goal": "Kalahkan Induk Pucat di kapel runtuh, padang timur laut Lembah Hijau.",
		"back": "Tunjukkan tongkat itu kepada Marla di Desa Rindu.",
		"offer": [
			"Mira, ada yang ingin kusampaikan sejak dulu.",
			"Gurumu meninggalkan tongkatnya di kapel runtuh di padang timur laut lembah, dekat sungai. Sekarang seekor induk laba-laba pucat bersarang di sana.",
			"Kalau kalian sudah cukup kuat, ambillah. Tongkat itu memang untukmu.",
		],
		"remind": "Kapel runtuh itu di padang timur laut lembah, dekat sungai. Laba-laba di sana bukan laba-laba biasa.",
		"thanks": ["Tongkat gurumu... Ia pasti bangga melihatmu sekarang.", "Pakailah, Mira. Cahayanya tidak pernah padam."],
		"reward": {"slot": "weapon", "tier": 3, "rarity": "legend", "for": "mira", "gold": 400},
	},
	"tongkat_bintang": {
		"name": "Bintang yang Jatuh", "need": "lahar", "giver": "laras", "boss": "penjaga_kristal", "backdrop": "kabut",
		"place": "Kawah Bintang", "hard": true,
		"goal": "Kalahkan Penjaga Kristal di kawah bintang, ujung selatan Hutan Kabut.",
		"back": "Kabari Tetua Elowen di Dusun Embun.",
		"offer": [
			"Selene, kau ingat cahaya yang jatuh di selatan hutan waktu kau kecil?",
			"Itu pecahan bintang. Dari sanalah Tongkat Bintang Jatuh ditempa, lalu disegel di kawah itu oleh penjaga kristal supaya tidak jatuh ke tangan yang salah.",
			"Kau sudah siap sekarang. Buktikan pada penjaganya.",
		],
		"remind": "Kawah bintang ada di ujung selatan Hutan Kabut. Penjaganya keras seperti batu permata.",
		"thanks": ["Jadi penjaga itu mengakuimu. Aku tahu hari ini akan datang.", "Tongkat itu milikmu, Selene."],
		"reward": {"slot": "weapon", "tier": 3, "rarity": "legend", "for": "selene", "gold": 400},
	},
	"busur_angin": {
		"name": "Angin dari Timur", "need": "lahar", "giver": "darma", "boss": "rajawali_badai", "backdrop": "abu",
		"place": "Puncak Angin", "hard": true,
		"goal": "Kalahkan Rajawali Badai di puncak utara Pegunungan Abu.",
		"back": "Bawa busur itu kepada Tetua Aldric di Pos Pemburu.",
		"offer": [
			"Kael. Ayahmu dulu memburu Rajawali Badai di puncak utara, dan busurnya tertinggal di sarang burung itu.",
			"Tak ada pemburu yang berani ke sana sejak itu. Tapi kau bukan pemburu biasa lagi.",
			"Bawa pulang Busur Angin Timur.",
		],
		"remind": "Sarang Rajawali Badai di puncak utara pegunungan. Ia lebih cepat dari panah mana pun.",
		"thanks": ["Busur ayahmu. Talinya masih utuh setelah sekian lama.", "Ia akan senang kau yang memakainya."],
		"reward": {"slot": "weapon", "tier": 3, "rarity": "legend", "for": "kael", "gold": 400},
	},
	# --- Bos super: terbuka setelah Raja Monster kalah; disetel untuk party yang memegang senjata Legend. ---
	"naga_purba": {
		"name": "Naga Purba", "need": "raja", "giver": "rekso", "boss": "naga_purba", "backdrop": "kawah",
		"place": "Sarang Naga", "hard": true,
		"goal": "Kalahkan Naga Purba di sarangnya, timur laut Pegunungan Abu.",
		"back": "Kabari Varek di Pos Pemburu.",
		"offer": [
			"Raja Monster sudah tumbang, tapi gunung ini belum tenang.",
			"Di balik lahar timur laut ada naga yang lebih tua dari kastil itu. Selama ini ia tidur. Sekarang ia bangun.",
			"Hanya senjata pusaka yang sanggup melukainya dengan berarti. Kalau kalian memegang keempatnya, mungkin ada harapan.",
		],
		"remind": "Sarang naga di timur laut, di balik padang lahar. Jangan ke sana tanpa senjata pusaka.",
		"thanks": ["Naga itu benar-benar mati? Seumur hidupku belum pernah kudengar kabar sebaik ini.", "Tak ada lagi yang bisa kuajarkan pada kalian. Terimalah ini."],
		"reward": {"gold": 3000},
	},
}

## Keterangan singkat tiap keadaan quest di daftar quest.
const STATE_LABELS := {"active": "Berjalan", "won": "Kembali ke pemberi quest", "done": "Selesai"}


## Keadaan sebuah quest: locked (belum bisa ditawarkan), available (bisa diterima),
## active (diterima), won (penjaganya kalah, hadiah belum diambil), done.
static func state(id: String, flags: Dictionary) -> String:
	var q: Dictionary = LIST[id]
	if flags.has("q_%s_done" % id):
		return "done"
	if flags.has("q_" + id):
		return "won" if flags.has(q.boss) else "active"
	return "available" if flags.has(q.need) else "locked"


## Quest yang diberikan seorang NPC; kosong kalau tidak ada.
static func of_giver(npc_id: String) -> String:
	for id: String in LIST:
		if LIST[id].giver == npc_id:
			return id
	return ""


## Langkah dialog quest yang diselipkan sebelum dialog biasa seorang NPC (lihat Story.talk).
static func steps_for(npc_id: String, npc_name: String, flags: Dictionary) -> Array:
	var id := of_giver(npc_id)
	if id == "":
		return []
	var q: Dictionary = LIST[id]
	var steps: Array = []
	match state(id, flags):
		"available":
			for line: String in q.offer:
				steps.append({"who": npc_name, "text": line})
			steps.append({"do": "flag", "flag": "q_" + id})
			steps.append({"do": "quest_note", "title": "Quest baru: %s", "quest": id, "hint": q.goal})
		"active":
			steps.append({"who": npc_name, "text": q.remind})
		"won":
			for line: String in q.thanks:
				steps.append({"who": npc_name, "text": line})
			if q.reward.has("slot"):
				steps.append({"do": "reward_gear", "slot": q.reward.slot, "tier": q.reward.tier, "rarity": q.reward.rarity,
					"for": q.reward.get("for", "")})
			steps.append({"do": "gold", "amount": q.reward.gold})
			steps.append({"do": "flag", "flag": "q_%s_done" % id})
			steps.append({"do": "quest_note", "title": "Quest selesai: %s", "quest": id, "hint": ""})
	return steps


## Teks hadiah sebuah quest untuk daftar quest.
static func prize_text(id: String) -> String:
	var reward: Dictionary = LIST[id].reward
	if not reward.has("slot"):
		return Loc.t("Hadiah: %d emas.") % int(reward.gold)
	var rarity: String = Db.GEAR_RARITIES[reward.rarity].name
	if reward.has("for"):
		return Loc.t("Hadiah: %s, senjata %s untuk %s, dan %d emas.") % [Loc.t(Db.LEGEND_WEAPONS[reward["for"]].name), rarity,
			Loc.t(Db.CHARACTERS[reward["for"]].name), int(reward.gold)]
	return Loc.t("Hadiah: senjata %s untuk satu anggota party, %d emas.") % [rarity, int(reward.gold)]


## Quest yang sudah pernah diterima, untuk daftar quest: [{"id", "state"}], yang masih berjalan lebih dulu.
static func journal(flags: Dictionary) -> Array:
	var running: Array = []
	var finished: Array = []
	for id: String in LIST:
		var now := state(id, flags)
		if now == "done":
			finished.append({"id": id, "state": now})
		elif now == "active" or now == "won":
			running.append({"id": id, "state": now})
	return running + finished


## Jumlah quest yang bisa diterima sekarang tetapi belum diambil.
static func open_offers(flags: Dictionary) -> int:
	var count := 0
	for id: String in LIST:
		if state(id, flags) == "available":
			count += 1
	return count
