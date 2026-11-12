class_name Story
extends RefCounted
## Cerita: daftar NPC per peta, dialog mereka, dan adegan (scene) yang dipicu peristiwa.
##
## Sebuah adegan adalah daftar langkah yang dijalankan berurutan oleh scene peta:
##   {"who": "Nama", "text": "..."}          dialog (who kosong = narasi)
##   {"choice": [{"text": "...", "steps": [...]}, ...]}   pilihan pemain
##   {"do": "flag", "flag": "nama"}          catat penanda progres
##   {"do": "join", "id": "mira"}            tokoh bergabung ke party
##   {"do": "pay", "gold": 10}               bayar emas
##   {"do": "rest"}                          pulihkan party, simpan permainan, jadikan tempat ini titik kembali
##   {"do": "shop", "stock": [id barang], "name": "Nama toko"}   buka toko dengan daftar barang itu
##   {"do": "battle", "ids": [...], "backdrop": "hutan", "after": "kunci_adegan"}
##   {"do": "credits"}                       simpan permainan lalu buka layar penutup

const INN_PRICE := 10
const DUSUN_INN_PRICE := 20
const POS_INN_PRICE := 30

## Adegan pembuka tiap wilayah: awalan nama zona -> adegan (dimainkan sekali; penandanya = nama adegan).
const ZONE_INTROS := {"Hutan Kabut": "kabut_intro", "Pegunungan Abu": "abu_intro", "Kastil Kelam": "kastil_intro"}

# hide_flag: NPC menghilang dari peta setelah penanda itu tercatat.
const NPCS := {
	"desa": [
		{"id": "tetua", "name": "Tetua Bram", "sprite": "npc_tetua", "tile": Vector2i(3, 2)},
		{"id": "sari", "name": "Bu Sari", "sprite": "npc_sari", "tile": Vector2i(6, 10)},
		{"id": "dimas", "name": "Dimas", "sprite": "npc_dimas", "tile": Vector2i(8, 5)},
		{"id": "joko", "name": "Pak Joko", "sprite": "npc_joko", "tile": Vector2i(12, 6)},
	],
	"dusun": [
		{"id": "laras", "name": "Nyi Laras", "sprite": "npc_laras", "tile": Vector2i(3, 2)},
		{"id": "wiryo", "name": "Pak Wiryo", "sprite": "npc_wiryo", "tile": Vector2i(9, 3)},
		{"id": "rumi", "name": "Mbok Rumi", "sprite": "npc_rumi", "tile": Vector2i(11, 5)},
	],
	"dunia": [
		{"id": "mira", "name": "Mira", "sprite": "mira", "tile": Vector2i(12, 2), "hide_flag": "mira_joined"},
		{"id": "selene", "name": "Selene", "sprite": "selene", "tile": Vector2i(34, 5), "hide_flag": "selene_joined"},
	],
	"pos": [
		{"id": "darma", "name": "Ki Darma", "sprite": "npc_darma", "tile": Vector2i(3, 2)},
		{"id": "ningsih", "name": "Bu Ningsih", "sprite": "npc_ningsih", "tile": Vector2i(9, 3)},
		{"id": "sabar", "name": "Pak Sabar", "sprite": "npc_sabar", "tile": Vector2i(11, 5)},
	],
	"abu": [
		{"id": "kael", "name": "Kael", "sprite": "kael", "tile": Vector2i(19, 3), "hide_flag": "kael_joined"},
	],
}

const SCENES := {
	"intro": [
		{"text": "Negeri Aveloria telah lama damai, sampai Raja Monster bangkit di Kastil Kelam di ujung timur."},
		{"text": "Sejak itu monster berkeliaran di padang dan hutan, dan jalan antarwilayah dijaga anak buahnya."},
		{"text": "Di Desa Rindu, seorang ksatria muda bernama Arlen bersiap memulai perjalanannya."},
		{"who": "Arlen", "text": "Sebelum berangkat, aku harus pamit dulu pada Tetua Bram. Rumahnya di barat laut desa."},
	],
	"mira_after": [
		{"who": "Mira", "text": "Terima kasih, Arlen. Kalau sendirian, aku pasti sudah celaka."},
		{"who": "Mira", "text": "Tetua pasti cemas... tapi aku tidak mau pulang hanya untuk menunggu. Izinkan aku ikut perjalananmu."},
		{"who": "Arlen", "text": "Dengan senang hati. Penyembuh sepertimu sangat kubutuhkan."},
		{"text": "Mira kini ikut bertarung. Jurus Pulih miliknya memulihkan HP seorang rekan."},
	],
	"lair_alone": [
		{"who": "Arlen", "text": "Geraman dari dalam gua itu... Terlalu berbahaya kalau sendirian. Aku harus mencari rekan dulu."},
	],
	"ogre_defeated": [
		{"text": "Ogre Penjaga tumbang, dan gerbang timur pun terbuka."},
		{"who": "Mira", "text": "Kita berhasil! Ayo kabari Tetua Bram sebelum menyeberang."},
	],
	"kabut_intro": [
		{"text": "Kabut tipis menyelimuti pepohonan. Udara di sini terasa lebih dingin."},
		{"who": "Mira", "text": "Hati-hati, Arlen. Monster di Hutan Kabut jauh lebih kuat daripada di lembah."},
		{"who": "Mira", "text": "Kata Tetua ada dusun kecil di tepi jalan ini. Kita cari tempat berteduh dulu."},
		{"do": "flag", "flag": "kabut_intro"},
	],
	"selene_after": [
		{"who": "Selene", "text": "Lumayan juga kalian. Aku berutang satu."},
		{"who": "Selene", "text": "Sumber kabut ini adalah Ratu Laba-laba di rimba timur. Jaringnya menutup sarang, tapi apiku bisa membakarnya."},
		{"who": "Arlen", "text": "Kami sedang menuju Kastil Kelam. Ikutlah dengan kami."},
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
		{"who": "Mira", "text": "Celah Abu di timur pasti sudah bisa dilewati. Dari sana jalan menuju Pegunungan Abu."},
	],
	"abu_intro": [
		{"text": "Udara panas dan berbau belerang. Abu halus turun dari langit seperti salju kelabu."},
		{"who": "Selene", "text": "Pegunungan Abu. Gunung api di timur itu tidak pernah benar-benar tidur."},
		{"who": "Mira", "text": "Para pemburu punya pos di tengah lembah ini. Kita ikuti jalan setapaknya."},
		{"do": "flag", "flag": "abu_intro"},
	],
	"kael_after": [
		{"who": "Kael", "text": "Bidikan kalian lumayan, untuk orang lembah."},
		{"who": "Kael", "text": "Raksasa Lahar itulah yang membuat gunung ini mengamuk. Selama dia hidup, jalan ke Kastil Kelam tertutup lahar."},
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
		{"who": "Kael", "text": "Jalan ke timur terbuka. Di ujungnya, Kastil Kelam."},
		{"who": "Arlen", "text": "Tinggal satu langkah lagi."},
	],
	"kastil_intro": [
		{"text": "Gerbang Kastil Kelam terbuka sendiri. Di dalam, obor-obor biru menyala tanpa minyak."},
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
	"ending": [
		{"text": "Raja Monster roboh. Kegelapan yang menyelimuti Kastil Kelam luruh seperti kabut pagi."},
		{"who": "Arlen", "text": "Sudah selesai."},
		{"who": "Mira", "text": "Tetua Bram pasti tidak percaya waktu kita ceritakan semua ini."},
		{"who": "Selene", "text": "Aku akan menuliskannya. Harus ada yang mencatat betapa cerobohnya kalian bertarung."},
		{"who": "Kael", "text": "Catat juga siapa yang paling sering mengenai sasaran."},
		{"text": "Monster-monster menghilang dari padang dan hutan. Jalan-jalan Aveloria kembali ramai."},
		{"text": "Dan empat sahabat itu pulang, melewati gunung, hutan, dan lembah yang kini damai."},
		{"do": "credits"},
	],
}


static func scene(key: String) -> Array:
	return SCENES.get(key, [])


static func npc_visible(entry: Dictionary, flags: Dictionary) -> bool:
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
	match npc_id:
		"tetua":
			if flags.has("ogre"):
				return [
					{"who": "Tetua Bram", "text": "Kalian mengalahkan Ogre Penjaga! Seluruh desa berutang budi pada kalian."},
					{"who": "Tetua Bram", "text": "Di seberang gerbang timur terbentang Hutan Kabut. Konon seorang penyihir bernama Selene tinggal di sana."},
				]
			if flags.has("mira_joined"):
				return [
					{"who": "Tetua Bram", "text": "Syukurlah Mira selamat. Berdua, kalian punya harapan."},
					{"who": "Tetua Bram", "text": "Ogre Penjaga bersarang di ujung jalan utara. Selama dia hidup, gerbang timur tetap tertutup."},
					{"who": "Tetua Bram", "text": "Jangan terburu-buru. Berlatihlah dulu di padang, dan beristirahatlah di penginapan Bu Sari."},
				]
			if flags.has("quest_mira"):
				return [{"who": "Tetua Bram", "text": "Mira pergi ke tepi hutan di utara. Keluar dari desa, lalu ikuti padang ke arah utara."}]
			return [
				{"who": "Tetua Bram", "text": "Arlen. Jadi hari ini kau berangkat."},
				{"who": "Tetua Bram", "text": "Gerbang timur dijaga Ogre, anak buah Raja Monster. Sendirian, kau tak akan sanggup melawannya."},
				{"who": "Tetua Bram", "text": "Mira, pendeta desa kita, pergi mencari daun penawar ke tepi hutan utara dan belum kembali. Aku cemas."},
				{"who": "Tetua Bram", "text": "Tolong cari dia. Jalan tanah aman dari monster; padang dan hutan tidak."},
				{"do": "flag", "flag": "quest_mira"},
			]
		"sari":
			var stay: Array = [
				{"do": "pay", "gold": INN_PRICE}, {"do": "rest"},
				{"who": "Bu Sari", "text": "Selamat beristirahat. (HP dan MP seluruh party pulih. Permainan disimpan.)"},
			]
			if gold < INN_PRICE:
				stay = [
					{"who": "Bu Sari", "text": "Emasmu belum cukup? Ah, untuk ksatria desa sendiri, malam ini gratis."},
					{"do": "rest"},
					{"text": "HP dan MP seluruh party pulih. Permainan disimpan."},
				]
			return [
				{"who": "Bu Sari", "text": "Selamat datang di Penginapan Rindu. Menginap semalam %d emas." % INN_PRICE},
				{"choice": [
					{"text": "Menginap", "steps": stay},
					{"text": "Tidak sekarang", "steps": [{"who": "Bu Sari", "text": "Mampirlah kalau lelah."}]},
				]},
			]
		"dimas":
			if flags.has("mira_joined"):
				return [{"who": "Dimas", "text": "Kak Mira hebat, ya! Lukaku waktu jatuh dulu langsung sembuh."}]
			return [
				{"who": "Dimas", "text": "Kak Arlen! Kata Ayah, monster cuma muncul di rumput dan hutan. Di jalan tanah aman!"},
				{"who": "Dimas", "text": "Tapi di hutan ada serigala. Jangan ke sana sendirian, ya."},
			]
		"joko":
			if flags.has("ogre"):
				return [
					{"who": "Pak Joko", "text": "Gerbang terbuka, kiriman dari timur datang lagi! Silakan lihat daganganku."},
					{"do": "shop", "stock": ["ramuan", "penawar", "ramuan_besar", "eter", "air_kehidupan", "ramuan_kekuatan", "ramuan_pelindung", "ramuan_angin"]},
					{"who": "Pak Joko", "text": "Hati-hati di Hutan Kabut."},
				]
			return [
				{"who": "Pak Joko", "text": "Kiriman dari timur tertahan sejak Ogre itu menutup gerbang. Tapi ramuan racikanku sendiri masih ada."},
				{"do": "shop", "name": "Toko Pak Joko", "stock": ["ramuan", "penawar"]},
				{"who": "Pak Joko", "text": "Kalau gerbangnya terbuka lagi, daganganku akan lebih lengkap."},
			]
		"mira":
			return [
				{"who": "Mira", "text": "Arlen! Syukurlah kau datang. Aku sedang mencari daun penawar, tapi..."},
				{"who": "Mira", "text": "Awas, di belakangmu! Serigala!"},
				{"do": "join", "id": "mira"},
				{"do": "flag", "flag": "mira_joined"},
				{"text": "Mira bergabung dengan party!"},
				{"do": "battle", "ids": ["serigala", "kelelawar"], "backdrop": "hutan", "after": "mira_after"},
			]
		"laras":
			if flags.has("ratu"):
				return [
					{"who": "Nyi Laras", "text": "Kabutnya menipis! Sudah lama sekali aku tidak melihat cahaya sejernih ini."},
					{"who": "Nyi Laras", "text": "Celah Abu di ujung timur kini terbuka. Di baliknya Pegunungan Abu, lalu Kastil Kelam."},
				]
			if flags.has("selene_joined"):
				return [
					{"who": "Nyi Laras", "text": "Selene selamat. Syukurlah."},
					{"who": "Nyi Laras", "text": "Sarang Ratu Laba-laba ada di rimba timur. Gigitannya beracun dan jaringnya melambatkan; bawalah Penawar."},
				]
			if flags.has("quest_selene"):
				return [{"who": "Nyi Laras", "text": "Altar tua ada di rimba utara, di tengah pepohonan paling rapat."}]
			return [
				{"who": "Nyi Laras", "text": "Pendatang dari lembah? Jarang ada yang sampai ke Dusun Embun sejak gerbang ditutup."},
				{"who": "Nyi Laras", "text": "Kabut ini bukan kabut biasa. Ia datang sejak Ratu Laba-laba bersarang di rimba timur."},
				{"who": "Nyi Laras", "text": "Selene, penyihir muda dusun ini, pergi ke altar tua di rimba utara mencari cara mengusirnya. Sudah tiga hari belum kembali."},
				{"who": "Nyi Laras", "text": "Kalau kalian memang hendak ke timur, tolong cari dia."},
				{"do": "flag", "flag": "quest_selene"},
			]
		"wiryo":
			var night: Array = [
				{"do": "pay", "gold": DUSUN_INN_PRICE}, {"do": "rest"},
				{"who": "Pak Wiryo", "text": "Tidurlah yang nyenyak. (HP dan MP seluruh party pulih. Permainan disimpan.)"},
			]
			if gold < DUSUN_INN_PRICE:
				night = [
					{"who": "Pak Wiryo", "text": "Kurang emas? Bayar saja nanti kalau kabut ini sudah hilang."},
					{"do": "rest"},
					{"text": "HP dan MP seluruh party pulih. Permainan disimpan."},
				]
			return [
				{"who": "Pak Wiryo", "text": "Penginapan Embun. Semalam %d emas, sudah termasuk bubur hangat." % DUSUN_INN_PRICE},
				{"choice": [
					{"text": "Menginap", "steps": night},
					{"text": "Tidak sekarang", "steps": [{"who": "Pak Wiryo", "text": "Pintu selalu terbuka."}]},
				]},
			]
		"rumi":
			return [
				{"who": "Mbok Rumi", "text": "Mau apa, Nak? Di hutan ini Penawar lebih berharga daripada emas."},
				{"do": "shop", "name": "Warung Mbok Rumi", "stock": ["ramuan", "penawar", "ramuan_besar", "eter", "air_kehidupan", "ramuan_kekuatan", "ramuan_pelindung", "ramuan_angin"]},
				{"who": "Mbok Rumi", "text": "Awas laba-laba. Racunnya menggerogoti pelan-pelan."},
			]
		"selene":
			return [
				{"who": "Selene", "text": "Jangan mendekat! ...Oh, manusia. Kukira laba-laba lagi."},
				{"who": "Selene", "text": "Aku Selene. Jaring-jaring ini mengepungku di altar sejak kemarin, dan sihirku hampir habis."},
				{"who": "Mira", "text": "Nyi Laras meminta kami mencarimu."},
				{"who": "Selene", "text": "Kalau begitu bantu aku sekarang. Mereka datang!"},
				{"do": "join", "id": "selene"},
				{"do": "flag", "flag": "selene_joined"},
				{"text": "Selene bergabung dengan party!"},
				{"do": "battle", "ids": ["laba_laba", "roh_kabut", "laba_laba"], "backdrop": "kabut", "after": "selene_after"},
			]
		"darma":
			if flags.has("lahar"):
				return [
					{"who": "Ki Darma", "text": "Gunungnya tenang. Seumur hidupku belum pernah sesunyi ini."},
					{"who": "Ki Darma", "text": "Jalan lahar di timur sudah mengeras. Kastil Kelam ada di ujungnya. Semoga langkah kalian ringan."},
				]
			if flags.has("kael_joined"):
				return [
					{"who": "Ki Darma", "text": "Kael ikut kalian? Anak itu memang tidak betah diam."},
					{"who": "Ki Darma", "text": "Raksasa Lahar berdiam di kawah timur laut. Semburannya membakar, dan hantamannya meruntuhkan pertahanan. Bawa Penawar yang banyak."},
				]
			if flags.has("quest_kael"):
				return [{"who": "Ki Darma", "text": "Punggung bukit utara, di antara dua lereng berbatu. Di situ Kael biasa mengintai."}]
			return [
				{"who": "Ki Darma", "text": "Orang lembah sampai ke sini? Kalian pasti yang mengusir kabut di barat."},
				{"who": "Ki Darma", "text": "Gunung ini mengamuk sejak Raksasa Lahar bangkit di kawah. Lahar menutup satu-satunya jalan ke timur."},
				{"who": "Ki Darma", "text": "Kael, pemanah terbaik kami, pergi mengintainya dari punggung bukit utara. Sudah tiga hari tidak ada kabar."},
				{"who": "Ki Darma", "text": "Kalau kalian bertemu dia, bilang pos ini masih menunggunya."},
				{"do": "flag", "flag": "quest_kael"},
			]
		"ningsih":
			var bed: Array = [
				{"do": "pay", "gold": POS_INN_PRICE}, {"do": "rest"},
				{"who": "Bu Ningsih", "text": "Selimutnya tebal, tidurlah. (HP dan MP seluruh party pulih. Permainan disimpan.)"},
			]
			if gold < POS_INN_PRICE:
				bed = [
					{"who": "Bu Ningsih", "text": "Tidak ada emas? Pemburu saling menolong. Masuklah."},
					{"do": "rest"},
					{"text": "HP dan MP seluruh party pulih. Permainan disimpan."},
				]
			return [
				{"who": "Bu Ningsih", "text": "Pondok singgah para pemburu. Semalam %d emas, sup daging rusa sepuasnya." % POS_INN_PRICE},
				{"choice": [
					{"text": "Menginap", "steps": bed},
					{"text": "Tidak sekarang", "steps": [{"who": "Bu Ningsih", "text": "Apinya selalu menyala."}]},
				]},
			]
		"sabar":
			return [
				{"who": "Pak Sabar", "text": "Bekal untuk naik gunung? Kadal bara menyulut, elang abu merobek zirah. Siapkan Penawar."},
				{"do": "shop", "name": "Lapak Pak Sabar", "stock": ["ramuan", "penawar", "ramuan_besar", "eter", "air_kehidupan", "ramuan_kekuatan", "ramuan_pelindung", "ramuan_angin"]},
				{"who": "Pak Sabar", "text": "Jangan dekat-dekat lahar."},
			]
		"kael":
			return [
				{"who": "Kael", "text": "Ssst. Merunduk."},
				{"who": "Kael", "text": "Aku Kael. Tiga hari aku mengintai Raksasa Lahar dari sini... dan baru saja elang-elang itu menemukanku."},
				{"who": "Arlen", "text": "Ki Darma mencarimu."},
				{"who": "Kael", "text": "Nanti saja ceritanya. Mereka menukik!"},
				{"do": "join", "id": "kael"},
				{"do": "flag", "flag": "kael_joined"},
				{"text": "Kael bergabung dengan party!"},
				{"do": "battle", "ids": ["elang_abu", "kadal_bara", "elang_abu"], "backdrop": "abu", "after": "kael_after"},
			]
	return []
