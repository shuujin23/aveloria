class_name Story
extends RefCounted
## Cerita: daftar NPC per peta, dialog mereka, dan adegan (scene) yang dipicu peristiwa.
##
## Sebuah adegan adalah daftar langkah yang dijalankan berurutan oleh scene peta:
##   {"who": "Nama", "text": "..."}          dialog (who kosong = narasi); "args": [..] mengisi %d di teks
##   {"choice": [{"text": "...", "steps": [...]}, ...]}   pilihan pemain
##   {"do": "flag", "flag": "nama"}          catat penanda progres
##   {"do": "join", "id": "mira"}            tokoh bergabung ke party
##   {"do": "pay", "gold": 10}               bayar emas
##   {"do": "rest"}                          pulihkan party, simpan permainan, jadikan tempat ini titik kembali
##   {"do": "shop", "stock": [id barang], "name": "Nama toko"}   buka toko dengan daftar barang itu
##   {"do": "forge", "tier": 1, "name": "Nama bengkel"}   buka pandai besi yang menjual perlengkapan tingkat itu
##   {"do": "battle", "ids": [...], "backdrop": "hutan", "after": "kunci_adegan"}
##   {"do": "credits"}                       simpan permainan lalu buka layar penutup
##   {"do": "gold", "amount": 60}            party menerima emas
##   {"do": "reward_gear", "slot", "tier", "rarity"}   pemain memilih anggota party yang menerima perlengkapan itu
##   {"do": "quest_note", "title", "quest", "hint"}    pemberitahuan quest baru / quest selesai
##   {"do": "xp", "amount": 45}              tiap anggota party yang masih berdiri menerima XP

const INN_PRICE := 10
const DUSUN_INN_PRICE := 20
const POS_INN_PRICE := 30

## Adegan pembuka tiap wilayah: awalan nama zona -> adegan (dimainkan sekali; penandanya = nama adegan).
const ZONE_INTROS := {"Hutan Mistwood": "kabut_intro", "Pegunungan Ashfell": "abu_intro", "Kastil Dreadmoor": "kastil_intro"}

# hide_flag: NPC menghilang dari peta setelah penanda itu tercatat.  show_flag: baru muncul setelah penanda itu tercatat.
# prop: benda yang bisa diperiksa (nama sprite-nya), bukan orang.  tint: warna pengali sprite.
const NPCS := {
	"desa": [
		{"id": "tetua", "name": "Tetua Bram", "sprite": "npc_tetua", "tile": Vector2i(3, 2)},
		{"id": "sari", "name": "Marla", "sprite": "npc_sari", "tile": Vector2i(6, 10)},
		{"id": "dimas", "name": "Finn", "sprite": "npc_dimas", "tile": Vector2i(8, 5)},
		{"id": "joko", "name": "Doran", "sprite": "npc_joko", "tile": Vector2i(12, 6)},
		{"id": "gatot", "name": "Garrick", "sprite": "npc_gatot", "tile": Vector2i(13, 8)},
		{"id": "kurir_desa", "name": "Corin", "sprite": "npc_sabar", "tint": Color(0.78, 0.92, 1.0), "tile": Vector2i(9, 10), "show_flag": "kurir_safe"},
		{"id": "peti_kiriman", "name": "Peti Kiriman", "prop": "crate_stack", "tile": Vector2i(12, 5), "show_flag": "ogre"},
		{"id": "peti_kiriman2", "name": "Peti Kiriman", "prop": "crate_stack", "tile": Vector2i(10, 10), "show_flag": "ogre"},
	],
	"dusun": [
		{"id": "laras", "name": "Tetua Elowen", "sprite": "npc_laras", "tile": Vector2i(3, 2)},
		{"id": "wiryo", "name": "Osric", "sprite": "npc_wiryo", "tile": Vector2i(9, 3)},
		{"id": "rumi", "name": "Nessa", "sprite": "npc_rumi", "tile": Vector2i(11, 5)},
		{"id": "sena", "name": "Halvard", "sprite": "npc_sena", "tile": Vector2i(4, 5)},
	],
	"dunia": [
		{"id": "mira", "name": "Mira", "sprite": "mira", "tile": Vector2i(18, 3), "hide_flag": "mira_joined"},
		{"id": "selene", "name": "Selene", "sprite": "selene", "tile": Vector2i(51, 8), "hide_flag": "selene_joined"},
		{"id": "kurir", "name": "Corin", "sprite": "npc_sabar", "tint": Color(0.78, 0.92, 1.0), "tile": Vector2i(18, 2), "hide_flag": "kurir_safe"},
		{"id": "peti_obat", "name": "Peti Obat", "prop": "crate_medicine", "tile": Vector2i(20, 2), "hide_flag": "kurir_safe"},
		# Dua benda di sekitar Sarang Perampok untuk jalur tanpa bertarung quest Palu Warisan (lihat Quests).
		{"id": "gerobak", "name": "Gerobak Rampasan", "prop": "cart", "tile": Vector2i(13, 18), "show_flag": "q_perampok", "hide_flag": "q_perampok_done"},
		{"id": "kentungan", "name": "Gong Penjaga", "prop": "gong", "tile": Vector2i(5, 18), "show_flag": "q_perampok", "hide_flag": "q_perampok_done"},
	],
	"pos": [
		{"id": "darma", "name": "Tetua Aldric", "sprite": "npc_darma", "tile": Vector2i(3, 2)},
		{"id": "ningsih", "name": "Brenna", "sprite": "npc_ningsih", "tile": Vector2i(9, 3)},
		{"id": "sabar", "name": "Tobin", "sprite": "npc_sabar", "tile": Vector2i(11, 5)},
		{"id": "rekso", "name": "Varek", "sprite": "npc_rekso", "tile": Vector2i(4, 5)},
	],
	"abu": [
		{"id": "kael", "name": "Kael", "sprite": "kael", "tile": Vector2i(26, 5), "hide_flag": "kael_joined"},
	],
}

const SCENES := {
	"intro": [
		{"text": "Negeri Aveloria telah lama damai, sampai Raja Monster bangkit di Kastil Dreadmoor di ujung timur."},
		{"text": "Sejak itu monster berkeliaran di padang dan hutan, dan jalan antarwilayah dijaga anak buahnya."},
		{"text": "Di Desa Willowmere, kiriman obat dari timur sudah tiga hari terlambat. Pagi ini Tetua Bram memanggil Arlen, ksatria muda desa itu."},
		{"who": "Arlen", "text": "Tetua tidak pernah memanggil tanpa alasan. Rumahnya di barat laut desa."},
	],
	"mira_after": [
		{"do": "flag", "flag": "kurir_safe"},
		{"who": "Arlen", "text": "Kawanan itu datang dari arah gua di utara. Kalau kukejar sekarang, mereka tidak sempat berkumpul lagi."},
		{"who": "Mira", "text": "Dan Corin kau tinggal di sini dengan kaki terkilir? Obat ini harus sampai ke desa dulu, Arlen. Serigala bisa menunggu."},
		{"who": "Corin", "text": "Jangan bertengkar gara-gara aku. Kakiku sudah dibalut, dan jalan tanah aman. Peti ini kubawa pulang sendiri."},
		{"who": "Mira", "text": "...Baiklah. Tapi aku ikut denganmu, Arlen. Harus ada yang memastikan kau pulang utuh."},
		{"who": "Arlen", "text": "Lambang di peti itu sama dengan ukiran di pusaka desa. Tetua Bram pasti tahu sesuatu."},
		{"text": "Corin pulang ke Desa Willowmere membawa peti obat. Mira kini ikut bertarung; jurus Pulih miliknya memulihkan HP seorang rekan."},
	],
	"lair_alone": [
		{"who": "Arlen", "text": "Geraman dari dalam gua itu... Terlalu berbahaya kalau sendirian. Aku harus mencari rekan dulu."},
	],
	"ogre_defeated": [
		{"text": "Ogre Penjaga tumbang, dan gerbang timur pun terbuka."},
		{"text": "Di lehernya tergantung kepingan logam hangus. Di permukaannya terukir lingkaran bersayap, lambang yang sama dengan di peti obat."},
		{"who": "Mira", "text": "Ini bukan rampasan. Kepingan ini dipasangkan, seperti kalung pada anjing penjaga."},
		{"who": "Arlen", "text": "Berarti ada yang menaruhnya di sini. Dan Tetua Bram belum menceritakan semuanya."},
		{"who": "Mira", "text": "Kita tanyakan baik-baik. Ayo kabari desa sebelum menyeberang."},
	],
	"kabut_intro": [
		{"text": "Kabut tipis menyelimuti pepohonan. Udara di sini terasa lebih dingin."},
		{"who": "Mira", "text": "Hati-hati, Arlen. Monster di Hutan Mistwood jauh lebih kuat daripada di lembah."},
		{"who": "Mira", "text": "Kata Tetua ada dusun kecil di tepi jalan ini. Kita cari tempat berteduh dulu."},
		{"do": "flag", "flag": "kabut_intro"},
	],
	"selene_after": [
		{"who": "Selene", "text": "Lumayan juga kalian. Aku berutang satu."},
		{"who": "Selene", "text": "Sumber kabut ini adalah Ratu Laba-laba di rimba timur. Jaringnya menutup sarang, tapi apiku bisa membakarnya."},
		{"who": "Arlen", "text": "Kami sedang menuju Kastil Dreadmoor. Ikutlah dengan kami."},
		{"who": "Selene", "text": "Melawan Raja Monster? ...Baiklah. Aku ingin tahu sejauh apa sihirku bisa melangkah."},
		{"text": "Selene kini ikut bertarung. Bola Api membakar musuh, dan Lemahkan meruntuhkan DEF mereka."},
	],
	"nest_sealed": [
		{"text": "Jaring tebal menutup mulut sarang. Pedang Arlen terpental saat mencoba memotongnya."},
		{"who": "Arlen", "text": "Tidak mempan. Jaring seperti ini harus dibakar."},
	],
	"ratu_defeated": [
		{"text": "Ratu Laba-laba tumbang. Kabut yang menyelimuti hutan perlahan menipis."},
		{"who": "Selene", "text": "Akhirnya langit terlihat lagi. Sudah berbulan-bulan dusun ini tidak melihat matahari."},
		{"who": "Mira", "text": "Celah Ashfell di timur pasti sudah bisa dilewati. Dari sana jalan menuju Pegunungan Ashfell."},
	],
	"abu_intro": [
		{"text": "Udara panas dan berbau belerang. Abu halus turun dari langit seperti salju kelabu."},
		{"who": "Selene", "text": "Pegunungan Ashfell. Gunung api di timur itu tidak pernah benar-benar tidur."},
		{"who": "Mira", "text": "Para pemburu punya pos di tengah lembah ini. Kita ikuti jalan setapaknya."},
		{"do": "flag", "flag": "abu_intro"},
	],
	"kael_after": [
		{"who": "Kael", "text": "Bidikan kalian lumayan, untuk orang lembah."},
		{"who": "Kael", "text": "Raksasa Lahar itulah yang membuat gunung ini mengamuk. Selama dia hidup, jalan ke Kastil Dreadmoor tertutup lahar."},
		{"who": "Arlen", "text": "Kami memang menuju ke sana."},
		{"who": "Kael", "text": "Kalau begitu panahku ikut. Sudah lama aku ingin membidik sesuatu yang lebih besar dari elang."},
		{"text": "Kael kini ikut bertarung. Ia yang tercepat di party; Bidik Jitu dan Panah Racun adalah andalannya."},
	],
	"lahar_blocked": [
		{"text": "Jembatan batu menuju kawah runtuh. Di seberang jurang terlihat tuas pemberat jembatan cadangan."},
		{"who": "Selene", "text": "Terlalu jauh untuk sihirku, dan apiku hanya akan menghanguskan talinya. Kita butuh pemanah."},
	],
	"lahar_defeated": [
		{"text": "Raksasa Lahar runtuh menjadi bongkahan batu dingin. Aliran lahar di timur perlahan mengeras."},
		{"who": "Kael", "text": "Jalan ke timur terbuka. Di ujungnya, Kastil Dreadmoor."},
		{"who": "Arlen", "text": "Tinggal satu langkah lagi."},
	],
	"kastil_intro": [
		{"text": "Gerbang Kastil Dreadmoor terbuka sendiri. Di dalam, obor-obor biru menyala tanpa minyak."},
		{"who": "Kael", "text": "Sepi. Aku tidak suka tempat yang terlalu sepi."},
		{"who": "Selene", "text": "Karpet merah ini langsung menuju ruang takhta. Dia tidak merasa perlu bersembunyi."},
		{"who": "Mira", "text": "Aku merasakan cahaya di aula depan. Mungkin ada altar. Kita pulihkan diri dulu sebelum naik."},
		{"do": "flag", "flag": "kastil_intro"},
	],
	"altar": [
		{"text": "Sebuah altar tua memancarkan cahaya biru lembut. Entah bagaimana, kegelapan kastil tidak menyentuhnya."},
		{"choice": [
			{"text": "Berdoa di altar", "steps": [
				{"do": "rest"},
				{"text": "Cahaya menyelimuti party. HP dan MP pulih sepenuhnya. Permainan disimpan."},
			]},
			{"text": "Lewat saja", "steps": []},
		]},
	],
	# Adegan setelah penjaga tempat side quest kalah (lihat Quests).
	# Percakapan sekali jalan saat pertama kali menginap bersama Mira (lihat talk()).
	"inn_talk": [
		{"who": "Mira", "text": "Belum tidur? Kau memandangi pedangmu sejak tadi."},
		{"who": "Arlen", "text": "Semua orang menyebutku ksatria desa. Padahal yang kulakukan selama ini baru mengusir serigala dari kandang."},
		{"who": "Mira", "text": "Guruku pergi ke timur waktu kastil itu jatuh, dan tidak kembali. Aku jadi pendeta bukan karena siap, tapi karena tidak ada orang lain."},
		{"who": "Arlen", "text": "Jadi kita berdua sama-sama belum pantas."},
		{"who": "Mira", "text": "Kita berdua sama-sama sudah berangkat. Tidurlah, ksatria desa."},
		{"do": "flag", "flag": "talk_inn"},
	],
	# Jalur tanpa bertarung quest Palu Warisan: dimainkan di petak sarang setelah para goblin teralihkan.
	"q_perampok_sneak": [
		{"text": "Sarang itu lengang. Dari barat terdengar gong dipukul bertalu-talu dan goblin saling berebut tong madu."},
		{"choice": [
			{"text": "Menyelinap masuk dan mengambil palunya", "steps": [
				{"text": "Kalian menyelinap melewati tumpukan rampasan. Palu tempa tua itu tergeletak di samping tempat tidur Goblin Kepala."},
				{"who": "Mira", "text": "Dapat. Ayo pergi sebelum mereka sadar tongnya sudah kosong."},
				{"do": "flag", "flag": "q_perampok_got"},
				{"do": "xp", "amount": 45},
				{"text": "Palu Garrick sudah di tangan. Goblin Kepala masih hidup, dan sarangnya tetap berbahaya."},
			]},
			{"text": "Serang pemimpinnya selagi ia sendirian", "steps": [
				{"do": "battle", "ids": ["goblin_kepala"], "backdrop": "hutan", "after": "q_perampok_won"},
			]},
			{"text": "Mundur dulu", "steps": []},
		]},
	],
	"q_perampok_won": [
		{"text": "Goblin Kepala tumbang. Di antara barang rampasannya ada sebuah palu tempa tua."},
		{"who": "Mira", "text": "Itu pasti palu Garrick. Ayo kembalikan ke desa."},
	],
	"q_roh_tua_won": [
		{"text": "Roh Tua lenyap bersama kabut di sekitarnya. Sebuah lentera tua masih tergantung di altar."},
		{"who": "Selene", "text": "Lentera penuntun dusun. Osric pasti senang melihatnya lagi."},
	],
	"q_golem_purba_won": [
		{"text": "Golem Purba runtuh menjadi tumpukan batu. Jalan masuk tambang terbuka lagi."},
		{"who": "Kael", "text": "Tobin berutang satu pada kita. Ayo tagih di pos."},
	],
	"q_pedang_fajar_won": [
		{"text": "Panglima Kelam roboh. Di balik jubahnya tergantung sebilah pedang yang berpendar seperti fajar."},
		{"who": "Arlen", "text": "Pedang Fajar. Tetua Bram harus melihat ini."},
	],
	"q_tongkat_cahaya_won": [
		{"text": "Induk Pucat tumbang. Di altar kapel yang retak tergeletak sebatang tongkat yang masih bercahaya."},
		{"who": "Mira", "text": "Tongkat Guru... Marla benar. Ayo pulang ke desa."},
	],
	"q_tongkat_bintang_won": [
		{"text": "Penjaga Kristal retak lalu hancur berkeping-keping. Di tengah kawah tertancap tongkat yang berkilau seperti langit malam."},
		{"who": "Selene", "text": "Indah sekali... Tetua Elowen harus tahu."},
	],
	"q_busur_angin_won": [
		{"text": "Rajawali Badai jatuh ke lereng. Di sarangnya, di antara tulang-belulang, terselip sebuah busur tua yang masih kokoh."},
		{"who": "Kael", "text": "Busur Ayah. ...Ayo pulang ke pos."},
	],
	"q_naga_purba_won": [
		{"text": "Naga Purba roboh, dan gunung itu akhirnya benar-benar diam."},
		{"who": "Arlen", "text": "Sekarang Aveloria sungguh aman."},
	],
	"ending": [
		{"text": "Raja Monster roboh. Kegelapan yang menyelimuti Kastil Dreadmoor luruh seperti kabut pagi."},
		{"who": "Arlen", "text": "Sudah selesai."},
		{"who": "Mira", "text": "Tetua Bram pasti tidak percaya waktu kita ceritakan semua ini."},
		{"who": "Selene", "text": "Aku akan menuliskannya. Harus ada yang mencatat betapa cerobohnya kalian bertarung."},
		{"who": "Kael", "text": "Catat juga siapa yang paling sering mengenai sasaran."},
		{"text": "Monster-monster menghilang dari padang dan hutan. Jalan-jalan Aveloria kembali ramai."},
		{"text": "Dan empat sahabat itu pulang, melewati gunung, hutan, dan lembah yang kini damai."},
		{"do": "credits"},
	],
}


## Tujuan utama cerita untuk jurnal, diturunkan dari penanda progres (tidak disimpan tersendiri):
## {"goal": tindakan berikutnya beserta tempatnya, "recap": ringkasan kejadian terakhir}.
## Tujuan baru muncul setelah sebuah peristiwa berhasil, karena penandanya baru tercatat saat itu.
static func main_objective(flags: Dictionary) -> Dictionary:
	if flags.has("raja"):
		if flags.has("q_naga_purba_done"):
			return {"goal": "Tidak ada lagi yang mengancam Aveloria. Jelajahi sesukamu.",
				"recap": "Raja Monster dan Naga Purba sudah tumbang."}
		return {"goal": "Aveloria aman. Tuntaskan quest yang tersisa, atau cari kabar di Pos Hawkrest.",
			"recap": "Raja Monster tumbang di Kastil Dreadmoor."}
	if flags.has("lahar"):
		return {"goal": "Masuki Kastil Dreadmoor lewat Jalan Emberdeep di timur dan kalahkan Raja Monster.",
			"recap": "Raksasa Lahar tumbang dan aliran lahar di timur mengeras."}
	if flags.has("kael_joined"):
		return {"goal": "Kalahkan Raksasa Lahar di Kawah Emberdeep, timur laut Pegunungan Ashfell.",
			"recap": "Kael bergabung. Selama Raksasa Lahar hidup, jalan ke Kastil Dreadmoor tertutup lahar."}
	if flags.has("quest_kael"):
		return {"goal": "Cari Kael di punggung bukit utara Pegunungan Ashfell.",
			"recap": "Tetua Aldric di Pos Hawkrest belum mendapat kabar dari Kael selama tiga hari."}
	if flags.has("ratu"):
		return {"goal": "Lewati Celah Ashfell di timur dan cari Pos Hawkrest di Pegunungan Ashfell.",
			"recap": "Ratu Laba-laba tumbang dan kabut di Hutan Mistwood menipis."}
	if flags.has("selene_joined"):
		return {"goal": "Kalahkan Ratu Laba-laba di Sarang Silkmaw, rimba timur Hutan Mistwood.",
			"recap": "Selene bergabung. Apinya bisa membakar jaring yang menutup sarang."}
	if flags.has("quest_selene"):
		return {"goal": "Cari Selene di altar tua, rimba utara Hutan Mistwood.",
			"recap": "Tetua Elowen di Dusun Dewfall meminta kalian mencari Selene."}
	if flags.has("ogre"):
		return {"goal": "Seberangi Gerbang Eastwatch dan cari Dusun Dewfall di Hutan Mistwood.",
			"recap": "Ogre Penjaga tumbang dan Gerbang Eastwatch terbuka."}
	if flags.has("mira_joined"):
		if not flags.has("kurir_safe"):
			return {"goal": "Usir serigala yang mengepung peti obat di tepi hutan utara Lembah Verdane.",
				"recap": "Mira bergabung, tetapi kawanan serigala belum terusir dan Corin masih menunggu."}
		return {"goal": "Kalahkan Ogre Penjaga di Gua Grimhollow, ujung jalan utara Lembah Verdane.",
			"recap": "Corin dan obatnya selamat, dan Mira bergabung. Gerbang Eastwatch tetap tertutup selama Ogre Penjaga hidup."}
	if flags.has("kurir_met"):
		return {"goal": "Ambil peti obat di sebelah timur tempat Mira dan Corin, di tepi hutan utara.",
			"recap": "Mira menjaga Corin, kurir yang terluka. Peti obatnya terseret tidak jauh dari sana."}
	if flags.has("quest_mira"):
		return {"goal": "Cari Mira dan kurir yang hilang di tepi hutan utara Lembah Verdane.",
			"recap": "Kiriman obat terlambat tiga hari. Mira, pendeta desa, pergi mencari kurirnya dan belum kembali."}
	return {"goal": "Temui Tetua Bram di barat laut Desa Willowmere.",
		"recap": "Raja Monster bangkit di Kastil Dreadmoor, dan kiriman obat untuk desa tak kunjung tiba."}


static func scene(key: String) -> Array:
	return SCENES.get(key, [])


static func npc_visible(entry: Dictionary, flags: Dictionary) -> bool:
	if entry.has("show_flag") and not flags.has(entry.show_flag):
		return false
	return not (entry.has("hide_flag") and flags.has(entry.hide_flag))


static func npc(npc_id: String) -> Dictionary:
	for list: Array in NPCS.values():
		for entry: Dictionary in list:
			if entry.id == npc_id:
				return entry
	return {}


## Dialog seorang NPC, tergantung sejauh mana cerita sudah berjalan (flags) dan emas party.
## Keadaan permainan dikirim lewat parameter karena skrip ini tidak boleh bergantung pada autoload Game.
static func talk(npc_id: String, flags: Dictionary, gold: int) -> Array:
	# Dialog side quest (kalau NPC ini pemberi quest) diselipkan sebelum dialog biasanya.
	var steps: Array = Quests.steps_for(npc_id, npc(npc_id).get("name", ""), flags) + _talk_base(npc_id, flags, gold)
	if flags.has("mira_joined") and not flags.has("talk_inn"):
		steps = _with_inn_talk(steps)
	return steps


## Selipkan percakapan party "inn_talk" setelah langkah menginap (kalau dialog ini punya pilihan menginap).
## Mengembalikan salinan, supaya data dialog aslinya tidak berubah.
static func _with_inn_talk(steps: Array) -> Array:
	var out: Array = steps.duplicate(true)
	for step: Dictionary in out:
		for option: Dictionary in step.get("choice", []):
			var rests := false
			for inner: Dictionary in option.steps:
				rests = rests or inner.get("do", "") == "rest"
			if rests:
				option.steps = (option.steps as Array) + (SCENES["inn_talk"] as Array)
	return out


static func _talk_base(npc_id: String, flags: Dictionary, gold: int) -> Array:
	match npc_id:
		"tetua":
			if flags.has("ogre"):
				return [
					{"who": "Tetua Bram", "text": "Kalian mengalahkan Ogre Penjaga! Seluruh desa berutang budi pada kalian."},
					{"who": "Tetua Bram", "text": "Kepingan berlambang di leher Ogre itu... Dulu tiap permukiman menyimpan satu, dan para Penjaga Jalan memakainya untuk memanggil bantuan dari kastil."},
					{"who": "Tetua Bram", "text": "Generasiku membiarkan ikatan itu putus. Kini seseorang di kastil memakainya untuk memerintah, bukan menolong. Hanya itu yang berani kukatakan sekarang."},
					{"who": "Tetua Bram", "text": "Di seberang gerbang timur terbentang Hutan Mistwood. Konon seorang penyihir bernama Selene tinggal di sana."},
				]
			if flags.has("mira_joined"):
				return [
					{"who": "Tetua Bram", "text": "Syukurlah kalian selamat dan obatnya sampai. Berdua, kalian punya harapan."},
					{"who": "Tetua Bram", "text": "Lingkaran bersayap di peti itu? ...Itu lambang Penjaga Jalan, yang dulu menghubungkan desa-desa dengan kastil. Sudah lama tak ada yang memakainya."},
					{"who": "Tetua Bram", "text": "Ogre Penjaga bersarang di ujung jalan utara. Selama dia hidup, gerbang timur tetap tertutup."},
					{"who": "Tetua Bram", "text": "Jangan terburu-buru. Berlatihlah dulu di padang, dan beristirahatlah di penginapan Marla."},
					{"who": "Tetua Bram", "text": "Dan jangan menghadapinya dengan tangan kosong. Garrick, pandai besi di sisi timur desa, bisa membuatkan senjata dan zirah untuk kalian berdua."},
				]
			if flags.has("quest_mira"):
				return [{"who": "Tetua Bram", "text": "Mira menyusuri tepi hutan di utara mencari Corin. Keluar dari desa, lalu ikuti padang ke arah utara."}]
			return [
				{"who": "Tetua Bram", "text": "Arlen. Terima kasih sudah datang."},
				{"who": "Tetua Bram", "text": "Corin, kurir kita, menyelinap melewati gerbang timur sebelum Ogre menutupnya, membawa peti obat dari Dusun Dewfall. Seharusnya ia tiba tiga hari lalu."},
				{"who": "Tetua Bram", "text": "Mira, pendeta desa kita, tidak sabar menunggu dan pergi mencarinya ke tepi hutan utara pagi tadi. Ia juga belum kembali."},
				{"who": "Tetua Bram", "text": "Kau ingin membuktikan dirimu sebagai ksatria, bukan? Susul mereka. Jalan tanah aman dari monster; padang dan hutan tidak."},
				{"do": "flag", "flag": "quest_mira"},
			]
		"sari":
			var stay: Array = [
				{"do": "pay", "gold": INN_PRICE}, {"do": "rest"},
				{"who": "Marla", "text": "Selamat beristirahat. (HP dan MP seluruh party pulih. Permainan disimpan.)"},
			]
			if gold < INN_PRICE:
				stay = [
					{"who": "Marla", "text": "Emasmu belum cukup? Ah, untuk ksatria desa sendiri, malam ini gratis."},
					{"do": "rest"},
					{"text": "HP dan MP seluruh party pulih. Permainan disimpan."},
				]
			return [
				{"who": "Marla", "text": "Selamat datang di Penginapan Willowmere. Menginap semalam %d emas.", "args": [INN_PRICE]},
				{"choice": [
					{"text": "Menginap", "steps": stay},
					{"text": "Tidak sekarang", "steps": [{"who": "Marla", "text": "Mampirlah kalau lelah."}]},
				]},
			]
		"dimas":
			if flags.has("ogre"):
				return [
					{"who": "Finn", "text": "Kak Arlen! Gerobak dari timur datang lagi! Ada garam, kain, dan permen madu!"},
					{"who": "Finn", "text": "Kata Corin, Ogre itu sebesar rumah. Benar, ya?"},
				]
			if flags.has("mira_joined"):
				return [{"who": "Finn", "text": "Kak Mira hebat, ya! Lukaku waktu jatuh dulu langsung sembuh."}]
			return [
				{"who": "Finn", "text": "Kak Arlen! Kata Ayah, monster cuma muncul di rumput dan hutan. Di jalan tanah aman!"},
				{"who": "Finn", "text": "Tapi di hutan ada serigala. Jangan ke sana sendirian, ya."},
			]
		"joko":
			if flags.has("ogre"):
				return [
					{"who": "Doran", "text": "Gerbang terbuka, kiriman dari timur datang lagi! Silakan lihat daganganku."},
					{"do": "shop", "stock": ["ramuan", "penawar", "ramuan_besar", "eter", "air_kehidupan", "ramuan_kekuatan", "ramuan_pelindung", "ramuan_angin"]},
					{"who": "Doran", "text": "Hati-hati di Hutan Mistwood."},
				]
			return [
				{"who": "Doran", "text": "Kiriman dari timur tertahan sejak Ogre itu menutup gerbang. Tapi ramuan racikanku sendiri masih ada."},
				{"do": "shop", "name": "Toko Doran", "stock": ["ramuan", "penawar"]},
				{"who": "Doran", "text": "Kalau gerbangnya terbuka lagi, daganganku akan lebih lengkap."},
			]
		"gatot":
			return [
				{"who": "Garrick", "text": "Mau berangkat tanpa zirah? Sini, kubuatkan yang pas untuk tiap orang."},
				{"who": "Garrick", "text": "Bawakan juga bahan dari monster. Dengan itu perlengkapanmu bisa kutempa lebih kuat, dan kadang muncul sifat istimewa."},
				{"do": "forge", "tier": 1, "name": "Bengkel Garrick"},
				{"who": "Garrick", "text": "Jaga baik-baik barang buatanku."},
			]
		"sena":
			return [
				{"who": "Halvard", "text": "Baja dusun ini ditempa dengan embun pagi. Lebih kuat daripada besi lembah."},
				{"do": "forge", "tier": 2, "name": "Tungku Halvard"},
				{"who": "Halvard", "text": "Benang laba-laba dan bara roh kabut adalah bahan tempa yang bagus. Jangan dibuang."},
			]
		"rekso":
			return [
				{"who": "Varek", "text": "Mitril dari perut gunung. Mahal, tapi tidak ada yang lebih baik sebelum Kastil Dreadmoor."},
				{"do": "forge", "tier": 3, "name": "Tungku Varek"},
				{"who": "Varek", "text": "Kalau ketemu kura-kura magma, jangan lari. Cangkangnya bahan tempa langka."},
			]
		"mira":
			if flags.has("kurir_met"):
				return [{"who": "Mira", "text": "Peti obatnya di sebelah timur sini, Arlen. Aku tidak bisa meninggalkan Corin."}]
			return [
				{"who": "Mira", "text": "Arlen! Pelan-pelan, jangan menginjak balutannya."},
				{"who": "Mira", "text": "Ini Corin. Serigala menyergapnya di jalan, dan pergelangan kakinya terkilir parah. Aku belum bisa meninggalkannya."},
				{"who": "Corin", "text": "Peti obatnya terseret ke semak di sebelah timur waktu aku jatuh. Tolong, isinya untuk seluruh desa."},
				{"who": "Arlen", "text": "Serigalanya lari ke mana? Biar kukejar."},
				{"who": "Mira", "text": "Obatnya dulu, Arlen. Ambil petinya; aku menjaga Corin di sini."},
				{"do": "flag", "flag": "kurir_met"},
			]
		"kurir":
			if flags.has("mira_joined"):
				return [{"who": "Corin", "text": "Serigala-serigala itu masih mengitari petinya! Hati-hati!"}]
			if flags.has("kurir_met"):
				return [{"who": "Corin", "text": "Petinya di semak sebelah timur. Segel lilinnya masih utuh waktu terakhir kulihat."}]
			return [{"who": "Corin", "text": "Aduh... kakiku. Bicaralah dengan pendeta itu, ia yang menolongku."}]
		"peti_obat":
			if flags.has("mira_joined"):  # kalah dari serigala sebelumnya: Mira sudah di party, pertarungannya diulang
				return [
					{"text": "Kawanan serigala itu kembali mengendus-endus peti obat."},
					{"do": "battle", "ids": ["serigala", "kelelawar"], "backdrop": "hutan", "after": "mira_after"},
				]
			if not flags.has("kurir_met"):
				return [{"text": "Sebuah peti kayu bersegel lilin tergeletak di semak. Ada bekas cakaran di sekelilingnya."}]
			return [
				{"text": "Peti kayu bersegel lilin. Di tutupnya tercap lingkaran bersayap."},
				{"who": "Arlen", "text": "Lambang ini... sama dengan ukiran di pusaka desa."},
				{"who": "Mira", "text": "Arlen, di belakangmu! Mereka kembali!"},
				{"do": "join", "id": "mira"},
				{"do": "flag", "flag": "mira_joined"},
				{"text": "Mira bergabung dengan party!"},
				{"do": "battle", "ids": ["serigala", "kelelawar"], "backdrop": "hutan", "after": "mira_after"},
			]
		"kurir_desa":
			if flags.has("ogre"):
				return [
					{"who": "Corin", "text": "Gerbangnya terbuka! Besok aku berangkat lagi ke Dusun Dewfall, kali ini lewat jalan yang benar."},
					{"who": "Corin", "text": "Soal cap di peti itu: yang menyegelnya Tetua Elowen sendiri. Kalau kalian sampai di Dewfall, tanyakan padanya."},
				]
			return [{"who": "Corin", "text": "Obatnya sudah di tangan Marla. Kakiku? Masih nyeri, tapi kata Mira seminggu lagi bisa berlari."}]
		"peti_kiriman", "peti_kiriman2":
			return [{"text": "Peti-peti kiriman dari timur: garam, kain, dan obat. Sebagian bercap lingkaran bersayap."}]
		"gerobak":
			if flags.has("q_perampok_got") or flags.has("goblin_kepala"):
				return [{"text": "Gerobak rampasan yang ditinggalkan. Tidak ada lagi yang berguna di sini."}]
			if flags.has("q_perampok_bait"):
				return [{"text": "Gerobak rampasan. Tong madunya sudah kalian bawa."}]
			return [
				{"text": "Gerobak pedagang yang dirampas goblin. Di antara karung kosong ada satu tong madu yang masih penuh."},
				{"who": "Mira", "text": "Goblin tergila-gila pada madu. Kalau tong ini ada di tempat lain, mereka pasti meninggalkan sarangnya."},
				{"choice": [
					{"text": "Bawa tong madunya", "steps": [
						{"do": "flag", "flag": "q_perampok_bait"},
						{"text": "Kalian membawa tong madu itu. Sekarang tinggal cara memanggil para goblin menjauh dari sarang. Di sebelah barat sarang ada gong penjaga."},
					]},
					{"text": "Biarkan saja", "steps": []},
				]},
			]
		"kentungan":
			if flags.has("q_perampok_got") or flags.has("goblin_kepala"):
				return [{"text": "Gong penjaga itu kini diam."}]
			if flags.has("q_perampok_sneak"):
				return [{"text": "Para goblin masih berebut madu di sekitar gong. Sarangnya di timur sedang lengang."}]
			if not flags.has("q_perampok_bait"):
				return [
					{"text": "Gong penjaga gerombolan goblin. Kalau dipukul, seisi sarang akan berlari ke sini."},
					{"who": "Arlen", "text": "Memanggil mereka saja tidak cukup. Harus ada yang menahan mereka di sini. Mungkin ada sesuatu di gerobak rampasan di tepi jalan timur."},
				]
			return [
				{"text": "Gong penjaga gerombolan goblin. Kalau dipukul, seisi sarang akan berlari ke sini."},
				{"choice": [
					{"text": "Taruh tong madu, lalu pukul gongnya", "steps": [
						{"do": "flag", "flag": "q_perampok_sneak"},
						{"text": "Gong berdentang. Kalian bersembunyi, dan gerombolan goblin berhamburan keluar lalu berebut tong madu."},
						{"who": "Mira", "text": "Sekarang! Sarangnya di timur, selagi mereka sibuk."},
					]},
					{"text": "Jangan dulu", "steps": []},
				]},
			]
		"laras":
			if flags.has("ratu"):
				return [
					{"who": "Tetua Elowen", "text": "Kabutnya menipis! Sudah lama sekali aku tidak melihat cahaya sejernih ini."},
					{"who": "Tetua Elowen", "text": "Celah Ashfell di ujung timur kini terbuka. Di baliknya Pegunungan Ashfell, lalu Kastil Dreadmoor."},
				]
			if flags.has("selene_joined"):
				return [
					{"who": "Tetua Elowen", "text": "Selene selamat. Syukurlah."},
					{"who": "Tetua Elowen", "text": "Ratu Laba-laba bersarang di Sarang Silkmaw, rimba timur. Gigitannya beracun dan jaringnya melambatkan; bawalah Penawar."},
				]
			if flags.has("quest_selene"):
				return [{"who": "Tetua Elowen", "text": "Altar tua ada di rimba utara, di tengah pepohonan paling rapat."}]
			return [
				{"who": "Tetua Elowen", "text": "Pendatang dari lembah? Jarang ada yang sampai ke Dusun Dewfall sejak gerbang ditutup."},
				{"who": "Tetua Elowen", "text": "Kabut ini bukan kabut biasa. Ia datang sejak Ratu Laba-laba bersarang di rimba timur."},
				{"who": "Tetua Elowen", "text": "Selene, penyihir muda dusun ini, pergi ke altar tua di rimba utara mencari cara mengusirnya. Sudah tiga hari belum kembali."},
				{"who": "Tetua Elowen", "text": "Kalau kalian memang hendak ke timur, tolong cari dia."},
				{"do": "flag", "flag": "quest_selene"},
			]
		"wiryo":
			var night: Array = [
				{"do": "pay", "gold": DUSUN_INN_PRICE}, {"do": "rest"},
				{"who": "Osric", "text": "Tidurlah yang nyenyak. (HP dan MP seluruh party pulih. Permainan disimpan.)"},
			]
			if gold < DUSUN_INN_PRICE:
				night = [
					{"who": "Osric", "text": "Kurang emas? Bayar saja nanti kalau kabut ini sudah hilang."},
					{"do": "rest"},
					{"text": "HP dan MP seluruh party pulih. Permainan disimpan."},
				]
			return [
				{"who": "Osric", "text": "Penginapan Dewfall. Semalam %d emas, sudah termasuk bubur hangat.", "args": [DUSUN_INN_PRICE]},
				{"choice": [
					{"text": "Menginap", "steps": night},
					{"text": "Tidak sekarang", "steps": [{"who": "Osric", "text": "Pintu selalu terbuka."}]},
				]},
			]
		"rumi":
			return [
				{"who": "Nessa", "text": "Mau apa, Nak? Di hutan ini Penawar lebih berharga daripada emas."},
				{"do": "shop", "name": "Warung Nessa", "stock": ["ramuan", "penawar", "ramuan_besar", "eter", "air_kehidupan", "ramuan_kekuatan", "ramuan_pelindung", "ramuan_angin"]},
				{"who": "Nessa", "text": "Awas laba-laba. Racunnya menggerogoti pelan-pelan."},
			]
		"selene":
			return [
				{"who": "Selene", "text": "Jangan mendekat! ...Oh, manusia. Kukira laba-laba lagi."},
				{"who": "Selene", "text": "Aku Selene. Jaring-jaring ini mengepungku di altar sejak kemarin, dan sihirku hampir habis."},
				{"who": "Mira", "text": "Tetua Elowen meminta kami mencarimu."},
				{"who": "Selene", "text": "Kalau begitu bantu aku sekarang. Mereka datang!"},
				{"do": "join", "id": "selene"},
				{"do": "flag", "flag": "selene_joined"},
				{"text": "Selene bergabung dengan party!"},
				{"do": "battle", "ids": ["laba_laba", "roh_kabut", "laba_laba"], "backdrop": "kabut", "after": "selene_after"},
			]
		"darma":
			if flags.has("lahar"):
				return [
					{"who": "Tetua Aldric", "text": "Gunungnya tenang. Seumur hidupku belum pernah sesunyi ini."},
					{"who": "Tetua Aldric", "text": "Jalan lahar di timur sudah mengeras. Kastil Dreadmoor ada di ujungnya. Semoga langkah kalian ringan."},
				]
			if flags.has("kael_joined"):
				return [
					{"who": "Tetua Aldric", "text": "Kael ikut kalian? Anak itu memang tidak betah diam."},
					{"who": "Tetua Aldric", "text": "Raksasa Lahar berdiam di kawah timur laut. Semburannya membakar, dan hantamannya meruntuhkan pertahanan. Bawa Penawar yang banyak."},
				]
			if flags.has("quest_kael"):
				return [{"who": "Tetua Aldric", "text": "Punggung bukit utara, di antara dua lereng berbatu. Di situ Kael biasa mengintai."}]
			return [
				{"who": "Tetua Aldric", "text": "Orang lembah sampai ke sini? Kalian pasti yang mengusir kabut di barat."},
				{"who": "Tetua Aldric", "text": "Gunung ini mengamuk sejak Raksasa Lahar bangkit di kawah. Lahar menutup satu-satunya jalan ke timur."},
				{"who": "Tetua Aldric", "text": "Kael, pemanah terbaik kami, pergi mengintainya dari punggung bukit utara. Sudah tiga hari tidak ada kabar."},
				{"who": "Tetua Aldric", "text": "Kalau kalian bertemu dia, bilang pos ini masih menunggunya."},
				{"do": "flag", "flag": "quest_kael"},
			]
		"ningsih":
			var bed: Array = [
				{"do": "pay", "gold": POS_INN_PRICE}, {"do": "rest"},
				{"who": "Brenna", "text": "Selimutnya tebal, tidurlah. (HP dan MP seluruh party pulih. Permainan disimpan.)"},
			]
			if gold < POS_INN_PRICE:
				bed = [
					{"who": "Brenna", "text": "Tidak ada emas? Pemburu saling menolong. Masuklah."},
					{"do": "rest"},
					{"text": "HP dan MP seluruh party pulih. Permainan disimpan."},
				]
			return [
				{"who": "Brenna", "text": "Pondok singgah para pemburu. Semalam %d emas, sup daging rusa sepuasnya.", "args": [POS_INN_PRICE]},
				{"choice": [
					{"text": "Menginap", "steps": bed},
					{"text": "Tidak sekarang", "steps": [{"who": "Brenna", "text": "Apinya selalu menyala."}]},
				]},
			]
		"sabar":
			return [
				{"who": "Tobin", "text": "Bekal untuk naik gunung? Kadal bara menyulut, elang abu merobek zirah. Siapkan Penawar."},
				{"do": "shop", "name": "Lapak Tobin", "stock": ["ramuan", "penawar", "ramuan_besar", "eter", "air_kehidupan", "ramuan_kekuatan", "ramuan_pelindung", "ramuan_angin"]},
				{"who": "Tobin", "text": "Jangan dekat-dekat lahar."},
			]
		"kael":
			return [
				{"who": "Kael", "text": "Ssst. Merunduk."},
				{"who": "Kael", "text": "Aku Kael. Tiga hari aku mengintai Raksasa Lahar dari sini... dan baru saja elang-elang itu menemukanku."},
				{"who": "Arlen", "text": "Tetua Aldric mencarimu."},
				{"who": "Kael", "text": "Nanti saja ceritanya. Mereka menukik!"},
				{"do": "join", "id": "kael"},
				{"do": "flag", "flag": "kael_joined"},
				{"text": "Kael bergabung dengan party!"},
				{"do": "battle", "ids": ["elang_abu", "kadal_bara", "elang_abu"], "backdrop": "abu", "after": "kael_after"},
			]
	return []
