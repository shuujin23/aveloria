class_name Db
extends RefCounted
## Semua data game: efek status, jurus, karakter, monster, dan kelompok musuh.
## Balancing cukup dilakukan dengan mengubah angka di file ini.

## Efek status. Berlaku untuk hero maupun monster.
##   kind    nerf (merugikan) atau buff (menguntungkan)
##   stat    stat yang dikali `mult` selama efek aktif
##   dot     kerusakan tiap akhir ronde, sebagai bagian dari HP maksimum
##   cancels efek lawan yang langsung dihapus saat efek ini masuk (mis. ATK naik menghapus ATK turun)
##   blocks_nerf  selama aktif, semua nerf baru ditolak
##   tag/color    label singkat di layar battle
const STATUSES := {
	# --- Nerf ---
	"burn": {"name": "Terbakar", "kind": "nerf", "dot": 0.08, "turns": 3, "tag": "BAKAR", "color": "ff8a4a"},
	"poison": {"name": "Racun", "kind": "nerf", "dot": 0.05, "turns": 4, "tag": "RACUN", "color": "8fd060"},
	"defense_break": {"name": "DEF Runtuh", "kind": "nerf", "stat": "defense", "mult": 0.6, "turns": 3,
		"cancels": "defense_up", "tag": "DEF-", "color": "e07070"},
	"slow": {"name": "Lambat", "kind": "nerf", "stat": "agi", "mult": 0.5, "turns": 3,
		"cancels": "speed_up", "tag": "LAMBAT", "color": "9a9ad0"},
	"attack_break": {"name": "ATK Runtuh", "kind": "nerf", "stat": "atk", "mult": 0.7, "turns": 3,
		"cancels": "attack_up", "tag": "ATK-", "color": "e07070"},
	# --- Buff ---
	"attack_up": {"name": "ATK Naik", "kind": "buff", "stat": "atk", "mult": 1.4, "turns": 3,
		"cancels": "attack_break", "tag": "ATK+", "color": "7fc8ff"},
	"defense_up": {"name": "DEF Naik", "kind": "buff", "stat": "defense", "mult": 1.5, "turns": 3,
		"cancels": "defense_break", "tag": "DEF+", "color": "7fc8ff"},
	"speed_up": {"name": "Cepat", "kind": "buff", "stat": "agi", "mult": 1.5, "turns": 3,
		"cancels": "slow", "tag": "CEPAT", "color": "7fc8ff"},
	"immunity": {"name": "Kebal", "kind": "buff", "blocks_nerf": true, "turns": 3, "tag": "KEBAL", "color": "ffe080"},
}

## Semi-bos dan bos hanya menerima separuh kerusakan dari terbakar/racun.
const BOSS_DOT_FACTOR := 0.5

# kind:    phys    -> power = pengali ATK
#          magic   -> power = kerusakan dasar (+ MAG)
#          heal    -> power = pemulihan dasar (+ MAG)
#          status  -> hanya memberi efek status (lihat `status`)
#          cleanse -> menghapus semua nerf dari sasaran, lalu memberi `status` kalau ada
# target:  enemy, all_enemies, ally, all_allies, self (relatif terhadap pemakai)
# status:  id efek status yang diberikan jurus bertipe status/cleanse
# inflict: efek status tambahan pada jurus serangan: {"status": id, "chance": 0..1}
const SKILLS := {
	# --- Arlen (Ksatria) ---
	"tebasan_kuat": {"name": "Tebasan Kuat", "mp": 3, "target": "enemy", "kind": "phys", "power": 1.6,
		"desc": "Tebasan sekuat tenaga ke satu musuh."},
	"pasang_badan": {"name": "Pasang Badan", "mp": 3, "target": "self", "kind": "status", "status": "defense_up",
		"desc": "DEF Naik untuk diri sendiri selama 3 ronde."},
	"pekik_perang": {"name": "Pekik Perang", "mp": 4, "target": "all_allies", "kind": "status", "status": "attack_up",
		"desc": "ATK Naik untuk seluruh party selama 3 ronde."},
	"tebasan_berputar": {"name": "Tebasan Berputar", "mp": 6, "target": "all_enemies", "kind": "phys", "power": 0.9,
		"desc": "Menebas semua musuh sekaligus."},
	# --- Selene (Penyihir) ---
	"bola_api": {"name": "Bola Api", "mp": 4, "target": "enemy", "kind": "magic", "power": 12,
		"inflict": {"status": "burn", "chance": 0.6},
		"desc": "Sihir api ke satu musuh. 60% membuat Terbakar."},
	"lemahkan": {"name": "Lemahkan", "mp": 3, "target": "enemy", "kind": "status", "status": "defense_break",
		"desc": "DEF Runtuh pada satu musuh selama 3 ronde."},
	"badai_es": {"name": "Badai Es", "mp": 8, "target": "all_enemies", "kind": "magic", "power": 9,
		"inflict": {"status": "slow", "chance": 0.5},
		"desc": "Sihir es ke semua musuh. 50% membuat Lambat."},
	# --- Mira (Pendeta) ---
	"pulih": {"name": "Pulih", "mp": 3, "target": "ally", "kind": "heal", "power": 22,
		"desc": "Memulihkan HP satu rekan."},
	"doa_pelindung": {"name": "Doa Pelindung", "mp": 5, "target": "all_allies", "kind": "status", "status": "defense_up",
		"desc": "DEF Naik untuk seluruh party selama 3 ronde."},
	"cahaya_suci": {"name": "Cahaya Suci", "mp": 4, "target": "enemy", "kind": "magic", "power": 10,
		"desc": "Sihir cahaya ke satu musuh."},
	"berkat_suci": {"name": "Berkat Suci", "mp": 6, "target": "all_allies", "kind": "cleanse", "status": "immunity",
		"desc": "Menghapus semua nerf dari party dan memberi Kebal selama 3 ronde."},
	"pulih_massal": {"name": "Pulih Massal", "mp": 9, "target": "all_allies", "kind": "heal", "power": 16,
		"desc": "Memulihkan HP seluruh party."},
	# --- Kael (Pemanah) ---
	"bidik_jitu": {"name": "Bidik Jitu", "mp": 3, "target": "enemy", "kind": "phys", "power": 1.3, "crit": 0.4,
		"desc": "Panah terarah, peluang kritikal tinggi."},
	"panah_racun": {"name": "Panah Racun", "mp": 3, "target": "enemy", "kind": "phys", "power": 1.0,
		"inflict": {"status": "poison", "chance": 0.8},
		"desc": "Panah beracun ke satu musuh. 80% membuat Racun."},
	"hujan_panah": {"name": "Hujan Panah", "mp": 5, "target": "all_enemies", "kind": "phys", "power": 0.7,
		"desc": "Menghujani semua musuh dengan panah."},
	"langkah_angin": {"name": "Langkah Angin", "mp": 4, "target": "all_allies", "kind": "status", "status": "speed_up",
		"desc": "Cepat untuk seluruh party selama 3 ronde."},
	"tipu_daya": {"name": "Tipu Daya", "mp": 3, "target": "enemy", "kind": "status", "status": "attack_break",
		"desc": "ATK Runtuh pada satu musuh selama 3 ronde."},
	# --- Monster ---
	"serangan_buas": {"name": "Serangan Buas", "mp": 2, "target": "enemy", "kind": "phys", "power": 1.4, "desc": ""},
	"spora": {"name": "Spora Beracun", "mp": 3, "target": "all_enemies", "kind": "magic", "power": 4,
		"inflict": {"status": "poison", "chance": 0.4}, "desc": ""},
	"jeritan": {"name": "Jeritan Nyaring", "mp": 2, "target": "enemy", "kind": "status", "status": "slow", "desc": ""},
	"raungan": {"name": "Raungan", "mp": 3, "target": "self", "kind": "status", "status": "attack_up", "desc": ""},
	"tipu_muslihat": {"name": "Tipu Muslihat", "mp": 3, "target": "enemy", "kind": "status", "status": "attack_break", "desc": ""},
	"hantaman_bumi": {"name": "Hantaman Bumi", "mp": 4, "target": "all_enemies", "kind": "phys", "power": 0.8,
		"inflict": {"status": "defense_break", "chance": 0.35}, "desc": ""},
	# --- Monster Hutan Kabut ---
	"gigitan_racun": {"name": "Gigitan Racun", "mp": 2, "target": "enemy", "kind": "phys", "power": 1.2,
		"inflict": {"status": "poison", "chance": 0.5}, "desc": ""},
	"jaring": {"name": "Jaring Lengket", "mp": 3, "target": "enemy", "kind": "status", "status": "slow", "desc": ""},
	"lidah_api": {"name": "Lidah Api Biru", "mp": 4, "target": "enemy", "kind": "magic", "power": 11,
		"inflict": {"status": "burn", "chance": 0.4}, "desc": ""},
	"jaring_raksasa": {"name": "Jaring Raksasa", "mp": 5, "target": "all_enemies", "kind": "status", "status": "slow", "desc": ""},
	"semburan_racun": {"name": "Semburan Racun", "mp": 5, "target": "all_enemies", "kind": "magic", "power": 9,
		"inflict": {"status": "poison", "chance": 0.5}, "desc": ""},
	# --- Monster Pegunungan Abu ---
	"gigitan_bara": {"name": "Gigitan Bara", "mp": 2, "target": "enemy", "kind": "phys", "power": 1.3,
		"inflict": {"status": "burn", "chance": 0.4}, "desc": ""},
	"cakar_tajam": {"name": "Cakar Tajam", "mp": 2, "target": "enemy", "kind": "phys", "power": 1.2,
		"inflict": {"status": "defense_break", "chance": 0.4}, "desc": ""},
	"hantaman_batu": {"name": "Hantaman Batu", "mp": 3, "target": "enemy", "kind": "phys", "power": 1.5, "desc": ""},
	"kulit_batu": {"name": "Kulit Batu", "mp": 3, "target": "self", "kind": "status", "status": "defense_up", "desc": ""},
	"semburan_lahar": {"name": "Semburan Lahar", "mp": 6, "target": "all_enemies", "kind": "magic", "power": 14,
		"inflict": {"status": "burn", "chance": 0.5}, "desc": ""},
	# --- Monster Kastil Kelam ---
	"tebasan_gelap": {"name": "Tebasan Gelap", "mp": 3, "target": "enemy", "kind": "phys", "power": 1.5, "desc": ""},
	"sumpah_perang": {"name": "Sumpah Perang", "mp": 3, "target": "self", "kind": "status", "status": "attack_up", "desc": ""},
	"kutukan": {"name": "Kutukan", "mp": 3, "target": "enemy", "kind": "status", "status": "attack_break", "desc": ""},
	"api_hitam": {"name": "Api Hitam", "mp": 4, "target": "enemy", "kind": "magic", "power": 16, "desc": ""},
	"cakar_batu": {"name": "Cakar Batu", "mp": 2, "target": "enemy", "kind": "phys", "power": 1.3,
		"inflict": {"status": "defense_break", "chance": 0.35}, "desc": ""},
	# --- Raja Monster ---
	"tebasan_kegelapan": {"name": "Tebasan Kegelapan", "mp": 4, "target": "enemy", "kind": "phys", "power": 1.7,
		"inflict": {"status": "defense_break", "chance": 0.4}, "desc": ""},
	"badai_kegelapan": {"name": "Badai Kegelapan", "mp": 8, "target": "all_enemies", "kind": "magic", "power": 22,
		"inflict": {"status": "attack_break", "chance": 0.35}, "desc": ""},
	"auman_raja": {"name": "Auman Raja", "mp": 4, "target": "self", "kind": "status", "status": "attack_up", "desc": ""},
	"rantai_bayangan": {"name": "Rantai Bayangan", "mp": 5, "target": "all_enemies", "kind": "status", "status": "slow", "desc": ""},
}

## Barang habis pakai. Dipakai dari menu Barang di battle; yang berjenis heal/mp juga bisa dari menu peta.
##   heal   memulihkan HP sebesar `power`      mp     memulihkan MP sebesar `power`
##   cure   menghapus semua nerf               revive membangkitkan rekan tumbang dengan `power` x HP maksimum
##   status memberi efek status `status` (buff) ke seorang rekan; hanya di pertarungan
const ITEMS := {
	"ramuan": {"name": "Ramuan", "price": 10, "kind": "heal", "power": 30,
		"desc": "Memulihkan 30 HP seorang rekan."},
	"penawar": {"name": "Penawar", "price": 8, "kind": "cure",
		"desc": "Menghapus semua nerf (racun, terbakar, dan lainnya) dari seorang rekan."},
	"ramuan_besar": {"name": "Ramuan Besar", "price": 30, "kind": "heal", "power": 80,
		"desc": "Memulihkan 80 HP seorang rekan."},
	"eter": {"name": "Eter", "price": 25, "kind": "mp", "power": 20,
		"desc": "Memulihkan 20 MP seorang rekan."},
	"air_kehidupan": {"name": "Air Kehidupan", "price": 60, "kind": "revive", "power": 0.5,
		"desc": "Membangkitkan rekan yang tumbang dengan separuh HP."},
	"ramuan_kekuatan": {"name": "Ramuan Kekuatan", "price": 20, "kind": "status", "status": "attack_up",
		"desc": "ATK Naik untuk seorang rekan selama 3 ronde."},
	"ramuan_pelindung": {"name": "Ramuan Pelindung", "price": 20, "kind": "status", "status": "defense_up",
		"desc": "DEF Naik untuk seorang rekan selama 3 ronde."},
	"ramuan_angin": {"name": "Ramuan Angin", "price": 20, "kind": "status", "status": "speed_up",
		"desc": "Cepat (SPD naik) untuk seorang rekan selama 3 ronde."},
}

## Isi tas di awal permainan.
const START_ITEMS := {"ramuan": 2}

## Kapasitas tas: jumlah slot; tiap slot memuat sampai STACK_MAX barang sejenis.
const STACK_MAX := 5
const BAG_START := 6
const BAG_STEP := 2  # tambahan slot tiap kali tas diperbesar
const BAG_MAX := 12
## Harga memperbesar tas di toko, berurutan (6 -> 8 -> 10 -> 12 slot).
const BAG_PRICES := [50, 100, 150]

# ---------------------------------------------------------------- kategori, bahan, perlengkapan

## Kategori monster dan bahan yang dijatuhkannya. Makin langka, makin jarang muncul dan makin bagus bahannya.
const RARITIES := {
	"common": {"name": "Common", "color": "d8dce4"},
	"rare": {"name": "Rare", "color": "6ab0ff"},
	"super": {"name": "Super Rare", "color": "c890ff"},
	"ultra": {"name": "Ultra Rare", "color": "ffb347"},
}
const REGION_NAMES := {1: "Lembah Hijau", 2: "Hutan Kabut", 3: "Pegunungan Abu", 4: "Kastil Kelam"}

## Bahan tempa hasil drop monster: satu per kategori di tiap wilayah. Disimpan di kantong bahan
## (Game.mats), terpisah dari tas. sell = harga jual ke pandai besi.
const MATERIALS := {
	"serat_liar": {"name": "Serat Liar", "rarity": "common", "region": 1, "sell": 3},
	"taring_serigala": {"name": "Taring Serigala", "rarity": "rare", "region": 1, "sell": 10},
	"lendir_emas": {"name": "Lendir Emas", "rarity": "super", "region": 1, "sell": 40},
	"tanduk_ogre": {"name": "Tanduk Ogre", "rarity": "ultra", "region": 1, "sell": 120},
	"benang_kabut": {"name": "Benang Kabut", "rarity": "common", "region": 2, "sell": 8},
	"bara_roh": {"name": "Bara Roh", "rarity": "rare", "region": 2, "sell": 24},
	"lensa_kabut": {"name": "Lensa Kabut", "rarity": "super", "region": 2, "sell": 90},
	"taring_ratu": {"name": "Taring Ratu", "rarity": "ultra", "region": 2, "sell": 260},
	"sisik_bara": {"name": "Sisik Bara", "rarity": "common", "region": 3, "sell": 14},
	"inti_batu": {"name": "Inti Batu", "rarity": "rare", "region": 3, "sell": 40},
	"cangkang_magma": {"name": "Cangkang Magma", "rarity": "super", "region": 3, "sell": 150},
	"jantung_lahar": {"name": "Jantung Lahar", "rarity": "ultra", "region": 3, "sell": 450},
	"serpih_kelam": {"name": "Serpih Kelam", "rarity": "common", "region": 4, "sell": 22},
	"jiwa_bayangan": {"name": "Jiwa Bayangan", "rarity": "rare", "region": 4, "sell": 60},
	"permata_terkutuk": {"name": "Permata Terkutuk", "rarity": "super", "region": 4, "sell": 220},
	"mahkota_kelam": {"name": "Mahkota Kelam", "rarity": "ultra", "region": 4, "sell": 800},
}

## Wilayah dan kategori tiap monster: id -> [wilayah, kategori]. Semi-bos dan bos = ultra.
const ENEMY_CLASS := {
	"jamur": [1, "common"], "kelelawar": [1, "common"], "serigala": [1, "rare"], "goblin": [1, "rare"],
	"lendir_emas": [1, "super"], "ogre": [1, "ultra"],
	"laba_laba": [2, "common"], "roh_kabut": [2, "rare"], "mata_kabut": [2, "super"], "ratu": [2, "ultra"],
	"kadal_bara": [3, "common"], "elang_abu": [3, "common"], "golem_batu": [3, "rare"],
	"kura_magma": [3, "super"], "lahar": [3, "ultra"],
	"ksatria_kelam": [4, "common"], "gargoyle": [4, "common"], "bayangan": [4, "rare"],
	"peti_terkutuk": [4, "super"], "raja": [4, "ultra"],
}
## Monster super rare tiap wilayah (awalan nama tabel pertemuan) dan peluangnya ikut muncul.
const SUPER_BY_TABLE := {"lembah": "lendir_emas", "kabut": "mata_kabut", "abu": "kura_magma", "kastil": "peti_terkutuk"}
const SUPER_CHANCE := 0.07

## Perlengkapan: 4 slot per tokoh, 3 tingkat (satu per pandai besi). Id = "<tokoh>_<slot>_<tingkat>".
## Tiap barang hanya bisa dipakai tokoh pemiliknya dan tidak memakan slot tas.
const GEAR_SLOTS := ["weapon", "head", "body", "feet"]
const GEAR_SLOT_NAMES := {"weapon": "Senjata", "head": "Kepala", "body": "Dada", "feet": "Kaki"}
const GEAR_TIERS := 3
const GEAR_NAMES := {
	"arlen": {"weapon": ["Pedang Besi", "Pedang Baja", "Pedang Mitril"], "head": ["Helm Besi", "Helm Baja", "Helm Mitril"],
		"body": ["Zirah Besi", "Zirah Baja", "Zirah Mitril"], "feet": ["Sepatu Besi", "Sepatu Baja", "Sepatu Mitril"]},
	"mira": {"weapon": ["Tongkat Doa", "Tongkat Berkat", "Tongkat Suci"], "head": ["Tudung Linen", "Tudung Sutra", "Tudung Cahaya"],
		"body": ["Jubah Linen", "Jubah Sutra", "Jubah Cahaya"], "feet": ["Sandal Linen", "Sandal Sutra", "Sandal Cahaya"]},
	"selene": {"weapon": ["Tongkat Ek", "Tongkat Kristal", "Tongkat Bintang"], "head": ["Topi Penyihir", "Topi Kristal", "Topi Bintang"],
		"body": ["Jubah Penyihir", "Jubah Kristal", "Jubah Bintang"], "feet": ["Sepatu Kain", "Sepatu Kristal", "Sepatu Bintang"]},
	"kael": {"weapon": ["Busur Pendek", "Busur Panjang", "Busur Elang"], "head": ["Tudung Kulit", "Tudung Pemburu", "Tudung Elang"],
		"body": ["Rompi Kulit", "Rompi Pemburu", "Rompi Elang"], "feet": ["Bot Kulit", "Bot Pemburu", "Bot Elang"]},
}
## Stat utama senjata tiap tokoh ("main" di GEAR_STATS).
const GEAR_MAIN_STAT := {"arlen": "atk", "kael": "atk", "mira": "mag", "selene": "mag"}
## Bonus stat per slot dan tingkat (sebelum tempa).
const GEAR_STATS := {
	"weapon": [{"main": 3}, {"main": 5}, {"main": 8}],
	"head": [{"max_hp": 4, "defense": 1}, {"max_hp": 7, "defense": 2}, {"max_hp": 11, "defense": 3}],
	"body": [{"defense": 2, "max_hp": 5}, {"defense": 3, "max_hp": 9}, {"defense": 5, "max_hp": 14}],
	"feet": [{"agi": 2, "defense": 1}, {"agi": 3, "defense": 1}, {"agi": 5, "defense": 2}],
}
const GEAR_PRICES := {"weapon": [40, 120, 300], "head": [25, 80, 200], "body": [45, 140, 340], "feet": [25, 80, 200]}
const STAT_LABELS := {"max_hp": "HP", "atk": "ATK", "defense": "DEF", "mag": "MAG", "agi": "SPD"}

## Stat andalan tiap slot: naik minimal 1 di tiap tingkat tempa; stat lainnya naik sebanding (bisa tertahan pembulatan).
const GEAR_PRIMARY := {"weapon": "main", "head": "max_hp", "body": "defense", "feet": "agi"}

## Tempa (enhance): +1 sampai +ENHANCE_MAX. Tiap tingkat menambah ENHANCE_STEP x bonus dasar,
## dan berpeluang memberi barang itu satu "sifat" (efek status) kalau belum punya.
const ENHANCE_MAX := 5
const ENHANCE_STEP := 0.15
## Bahan tiap tingkat tempa: [kategori, jumlah]; bahannya dari wilayah yang sama dengan tingkat barang.
const ENHANCE_RECIPES := [
	[["common", 2]], [["common", 4]], [["rare", 2], ["common", 2]],
	[["super", 1], ["rare", 2]], [["ultra", 1], ["super", 1]],
]
const ENHANCE_GOLD := 0.25  # x harga barang x tingkat tempa yang dituju
## Peluang mendapat sifat saat naik ke +1 .. +5.
const TRAIT_GAIN_CHANCE := [0.2, 0.2, 0.35, 0.5, 1.0]
## Peluang sifat aktif di battle: TRAIT_BASE + TRAIT_STEP x tingkat tempa (15% di +1, 35% di +5).
const TRAIT_BASE := 0.10
const TRAIT_STEP := 0.05
## Sifat yang mungkin. Senjata: tergantung tingkat (bahan wilayahnya); nerf mengenai musuh yang diserang,
## buff mengenai pemakainya. Kepala/kaki aktif di awal battle, dada aktif saat pemakainya terkena serangan.
const WEAPON_TRAITS := [
	["poison", "slow", "attack_break"],
	["poison", "burn", "slow", "attack_up"],
	["burn", "defense_break", "attack_break", "attack_up"],
]
const SLOT_TRAITS := {"head": ["immunity"], "body": ["defense_up"], "feet": ["speed_up"]}
const TRAIT_WHEN := {"weapon": "saat menyerang", "head": "di awal pertarungan", "body": "saat terkena serangan",
	"feet": "di awal pertarungan"}
const REFORGE_GOLD := 0.3  # tempa ulang: x harga barang, ditambah 1 bahan rare wilayahnya

## Animasi tiap jurus di layar battle (lihat _play_fx di battle_scene.gd).
## Jurus besar (spin, ice_storm, arrow_rain, heal_all, quake) juga mengubah suasana arena.
const SKILL_FX := {
	"tebasan_kuat": "heavy_slash", "pasang_badan": "buff_self", "pekik_perang": "rally", "tebasan_berputar": "spin",
	"bola_api": "fire", "lemahkan": "debuff", "badai_es": "ice_storm",
	"pulih": "heal", "doa_pelindung": "bless", "cahaya_suci": "light", "berkat_suci": "heal_all", "pulih_massal": "heal_all",
	"bidik_jitu": "arrow", "panah_racun": "arrow", "hujan_panah": "arrow_rain", "langkah_angin": "bless", "tipu_daya": "debuff",
	"serangan_buas": "bite", "spora": "spore", "jeritan": "debuff", "raungan": "buff_self", "tipu_muslihat": "debuff",
	"hantaman_bumi": "quake",
	"gigitan_racun": "bite", "jaring": "debuff", "lidah_api": "fire", "jaring_raksasa": "debuff", "semburan_racun": "spore",
	"gigitan_bara": "bite", "cakar_tajam": "bite", "hantaman_batu": "heavy_slash", "kulit_batu": "buff_self", "semburan_lahar": "lava",
	"tebasan_gelap": "heavy_slash", "sumpah_perang": "buff_self", "kutukan": "debuff", "api_hitam": "fire", "cakar_batu": "bite",
	"tebasan_kegelapan": "heavy_slash", "badai_kegelapan": "dark", "auman_raja": "buff_self", "rantai_bayangan": "debuff",
}

# base = stat di level 1, growth = tambahan per level, learn = level -> jurus baru
const CHARACTERS := {
	"arlen": {"name": "Arlen", "job": "Ksatria",
		"base": {"hp": 34, "mp": 6, "atk": 12, "defense": 8, "mag": 2, "agi": 6},
		"growth": {"hp": 7.0, "mp": 1.5, "atk": 2.6, "defense": 2.0, "mag": 0.4, "agi": 1.2},
		"learn": {1: ["tebasan_kuat"], 3: ["pasang_badan"], 4: ["pekik_perang"], 5: ["tebasan_berputar"]}},
	"selene": {"name": "Selene", "job": "Penyihir",
		"base": {"hp": 20, "mp": 16, "atk": 5, "defense": 4, "mag": 12, "agi": 7},
		"growth": {"hp": 4.0, "mp": 4.0, "atk": 1.0, "defense": 1.0, "mag": 2.8, "agi": 1.4},
		"learn": {1: ["bola_api"], 2: ["lemahkan"], 4: ["badai_es"]}},
	"mira": {"name": "Mira", "job": "Pendeta",
		"base": {"hp": 24, "mp": 14, "atk": 7, "defense": 6, "mag": 9, "agi": 5},
		"growth": {"hp": 5.0, "mp": 3.5, "atk": 1.4, "defense": 1.6, "mag": 2.2, "agi": 1.0},
		"learn": {1: ["pulih"], 3: ["doa_pelindung"], 4: ["cahaya_suci"], 5: ["berkat_suci"], 6: ["pulih_massal"]}},
	"kael": {"name": "Kael", "job": "Pemanah",
		"base": {"hp": 26, "mp": 8, "atk": 10, "defense": 5, "mag": 3, "agi": 12},
		"growth": {"hp": 5.5, "mp": 2.0, "atk": 2.3, "defense": 1.3, "mag": 0.5, "agi": 2.4},
		"learn": {1: ["bidik_jitu"], 2: ["panah_racun"], 3: ["hujan_panah"], 4: ["langkah_angin"], 5: ["tipu_daya"]}},
}

## Arlen memulai sendirian; rekan lain bergabung lewat cerita (lihat Story).
const START_PARTY := ["arlen"]

# Angka semi-bos dan bos disetel dengan anggapan party memakai perlengkapan wilayahnya (lihat sim.gd).
# Tiap jenis monster hanya memakai sebagian efek status (lewat `skills`),
# dan bisa kebal terhadap efek tertentu (`immune`).
# voice = "soft": suara terluka/kalah yang ringan (monster kecil); tanpa itu memakai geraman.
const ENEMIES := {
	"jamur": {"name": "Jamur Liar", "hp": 18, "mp": 6, "atk": 8, "defense": 3, "mag": 3, "agi": 3,
		"xp": 4, "gold": 3, "skills": ["spora"], "immune": ["poison"], "voice": "soft"},
	"kelelawar": {"name": "Kelelawar Gua", "hp": 14, "mp": 4, "atk": 9, "defense": 2, "mag": 0, "agi": 11,
		"xp": 4, "gold": 2, "skills": ["serangan_buas", "jeritan"], "immune": [], "voice": "soft"},
	"serigala": {"name": "Serigala Kelam", "hp": 34, "mp": 8, "atk": 14, "defense": 5, "mag": 0, "agi": 10,
		"xp": 9, "gold": 6, "skills": ["serangan_buas", "raungan"], "immune": []},
	"goblin": {"name": "Goblin Perampok", "hp": 42, "mp": 6, "atk": 16, "defense": 7, "mag": 0, "agi": 7,
		"xp": 12, "gold": 12, "skills": ["serangan_buas", "tipu_muslihat"], "immune": []},
	"ogre": {"name": "Ogre Penjaga", "hp": 266, "mp": 30, "atk": 28, "defense": 9, "mag": 0, "agi": 5,
		"xp": 80, "gold": 100, "skills": ["hantaman_bumi", "raungan", "serangan_buas"], "immune": ["slow"],
		"boss": true},
	"lendir_emas": {"name": "Lendir Emas", "hp": 70, "mp": 10, "atk": 15, "defense": 9, "mag": 0, "agi": 8,
		"xp": 30, "gold": 45, "skills": ["serangan_buas", "kulit_batu"], "immune": [], "voice": "soft"},
	"mata_kabut": {"name": "Mata Kabut", "hp": 150, "mp": 30, "atk": 14, "defense": 14, "mag": 24, "agi": 13,
		"xp": 60, "gold": 80, "skills": ["lidah_api", "kutukan"], "immune": ["slow"], "voice": "soft"},
	"kura_magma": {"name": "Kura-kura Magma", "hp": 300, "mp": 20, "atk": 36, "defense": 32, "mag": 0, "agi": 5,
		"xp": 110, "gold": 130, "skills": ["gigitan_bara", "kulit_batu"], "immune": ["burn"]},
	"peti_terkutuk": {"name": "Peti Terkutuk", "hp": 360, "mp": 30, "atk": 46, "defense": 28, "mag": 20, "agi": 14,
		"xp": 170, "gold": 200, "skills": ["serangan_buas", "kutukan", "api_hitam"], "immune": ["poison"]},
	# --- Hutan Kabut ---
	"laba_laba": {"name": "Laba-laba Kabut", "hp": 52, "mp": 8, "atk": 22, "defense": 8, "mag": 0, "agi": 12,
		"xp": 16, "gold": 10, "skills": ["gigitan_racun", "jaring"], "immune": ["poison"]},
	"roh_kabut": {"name": "Roh Kabut", "hp": 38, "mp": 20, "atk": 9, "defense": 14, "mag": 18, "agi": 9,
		"xp": 15, "gold": 12, "skills": ["lidah_api"], "immune": ["burn"], "voice": "soft"},
	"ratu": {"name": "Ratu Laba-laba", "hp": 608, "mp": 60, "atk": 37, "defense": 11, "mag": 17, "agi": 9,
		"xp": 180, "gold": 220, "skills": ["gigitan_racun", "jaring_raksasa", "semburan_racun"], "immune": ["poison", "slow"],
		"boss": true},
	# --- Pegunungan Abu ---
	"kadal_bara": {"name": "Kadal Bara", "hp": 74, "mp": 8, "atk": 30, "defense": 12, "mag": 0, "agi": 12,
		"xp": 26, "gold": 16, "skills": ["gigitan_bara"], "immune": ["burn"]},
	"elang_abu": {"name": "Elang Abu", "hp": 56, "mp": 8, "atk": 28, "defense": 8, "mag": 0, "agi": 21,
		"xp": 24, "gold": 14, "skills": ["cakar_tajam"], "immune": []},
	"golem_batu": {"name": "Golem Batu", "hp": 120, "mp": 12, "atk": 33, "defense": 22, "mag": 0, "agi": 4,
		"xp": 34, "gold": 24, "skills": ["hantaman_batu", "kulit_batu"], "immune": ["poison"]},
	"lahar": {"name": "Raksasa Lahar", "hp": 992, "mp": 80, "atk": 51, "defense": 17, "mag": 24, "agi": 7,
		"xp": 340, "gold": 420, "skills": ["semburan_lahar", "hantaman_bumi", "kulit_batu"], "immune": ["burn", "slow"],
		"boss": true},
	# --- Kastil Kelam ---
	"ksatria_kelam": {"name": "Ksatria Kelam", "hp": 140, "mp": 12, "atk": 40, "defense": 22, "mag": 0, "agi": 12,
		"xp": 48, "gold": 30, "skills": ["tebasan_gelap", "sumpah_perang"], "immune": []},
	"bayangan": {"name": "Arwah Bayangan", "hp": 86, "mp": 30, "atk": 14, "defense": 16, "mag": 26, "agi": 17,
		"xp": 44, "gold": 28, "skills": ["api_hitam", "kutukan"], "immune": ["poison"], "voice": "soft"},
	"gargoyle": {"name": "Gargoyle", "hp": 112, "mp": 10, "atk": 37, "defense": 26, "mag": 0, "agi": 15,
		"xp": 46, "gold": 30, "skills": ["cakar_batu", "kulit_batu"], "immune": ["poison"]},
	"raja": {"name": "Raja Monster", "hp": 1960, "mp": 200, "atk": 62, "defense": 21, "mag": 35, "agi": 12,
		"xp": 600, "gold": 0, "skills": ["tebasan_kegelapan", "badai_kegelapan", "auman_raja", "rantai_bayangan"], "immune": ["slow"],
		"boss": true},
}

# Tabel pertemuan acak; tiap jenis medan di peta menunjuk ke salah satu tabel ini.
const ENCOUNTER_TABLES := {
	"lembah_padang": [
		["jamur", "jamur", "kelelawar"], ["kelelawar", "kelelawar"],
		["jamur", "kelelawar", "kelelawar"], ["jamur", "jamur", "jamur"]],
	"lembah_hutan": [
		["serigala", "kelelawar", "kelelawar"], ["serigala", "jamur", "jamur"], ["serigala", "serigala"]],
	"kabut_padang": [
		["laba_laba", "serigala"], ["roh_kabut", "laba_laba"], ["goblin", "roh_kabut"], ["laba_laba", "laba_laba", "roh_kabut"]],
	"kabut_hutan": [
		["laba_laba", "laba_laba", "roh_kabut"], ["goblin", "goblin", "roh_kabut"], ["laba_laba", "goblin", "roh_kabut", "laba_laba"]],
	"abu_padang": [
		["kadal_bara", "elang_abu"], ["elang_abu", "elang_abu", "kadal_bara"], ["golem_batu", "kadal_bara"],
		["kadal_bara", "kadal_bara", "elang_abu"]],
	"abu_lereng": [
		["golem_batu", "elang_abu", "kadal_bara"], ["golem_batu", "golem_batu"], ["kadal_bara", "elang_abu", "golem_batu", "elang_abu"]],
	"kastil_aula": [
		["ksatria_kelam", "bayangan"], ["gargoyle", "gargoyle"], ["ksatria_kelam", "gargoyle", "bayangan"]],
	"kastil_dalam": [
		["ksatria_kelam", "ksatria_kelam", "bayangan"], ["gargoyle", "bayangan", "gargoyle", "ksatria_kelam"],
		["bayangan", "bayangan", "ksatria_kelam"]],
}

## Semi-bos di peta: id penanda (flag) -> kelompok musuh.
const BOSSES := {
	"ogre": ["ogre"],
	"ratu": ["laba_laba", "ratu", "laba_laba"],
	"lahar": ["kadal_bara", "lahar", "kadal_bara"],
	"raja": ["raja"],  # bos utama, sendirian
}

## Aturan tiap sarang semi-bos di peta:
##   need     penanda cerita yang harus ada sebelum bisa menantang (rekan yang dibutuhkan)
##   blocked  adegan yang dimainkan kalau syarat itu belum terpenuhi
##   after    adegan setelah semi-bos kalah
##   backdrop latar battle
const BOSS_RULES := {
	"ogre": {"need": "mira_joined", "blocked": "lair_alone", "after": "ogre_defeated", "backdrop": "gua"},
	"ratu": {"need": "selene_joined", "blocked": "nest_sealed", "after": "ratu_defeated", "backdrop": "kabut"},
	"lahar": {"need": "kael_joined", "blocked": "lahar_blocked", "after": "lahar_defeated", "backdrop": "kawah"},
	"raja": {"need": "kael_joined", "blocked": "lahar_blocked", "after": "ending", "backdrop": "takhta"},
}


## Pecah isi tas menjadi tumpukan per slot: [{"id", "count"}], maksimal STACK_MAX per slot.
static func stacks_of(counts: Dictionary) -> Array:
	var stacks: Array = []
	for item_id: String in ITEMS:
		var left := int(counts.get(item_id, 0))
		while left > 0:
			stacks.append({"id": item_id, "count": min(left, STACK_MAX)})
			left -= STACK_MAX
	return stacks


## Harga memperbesar tas dari jumlah slot saat ini; -1 kalau sudah maksimal.
static func bag_upgrade_price(slots: int) -> int:
	var index := (slots - BAG_START) / BAG_STEP
	if slots >= BAG_MAX or index < 0 or index >= BAG_PRICES.size():
		return -1
	return BAG_PRICES[index]


## Kelompok musuh acak dari sebuah tabel. allow_super = monster super rare wilayah itu boleh ikut muncul
## (menggantikan sebagian kelompok, berdiri paling depan).
static func random_group(table: String, allow_super: bool = false) -> Array:
	var groups: Array = ENCOUNTER_TABLES[table]
	var group: Array = groups[randi() % groups.size()]
	var super_id: String = SUPER_BY_TABLE.get(table.get_slice("_", 0), "")
	if allow_super and super_id != "" and randf() < SUPER_CHANCE:
		return [super_id] + group.slice(0, 2)
	return group


static func region_of(enemy_id: String) -> int:
	return ENEMY_CLASS[enemy_id][0]


static func rarity_of(enemy_id: String) -> String:
	return ENEMY_CLASS[enemy_id][1]


## Id bahan untuk sebuah wilayah dan kategori.
static func material_id(region: int, rarity: String) -> String:
	for mat_id: String in MATERIALS:
		if MATERIALS[mat_id].region == region and MATERIALS[mat_id].rarity == rarity:
			return mat_id
	return ""


## Bahan yang dijatuhkan seekor monster: id bahan -> jumlah. Bos selalu menjatuhkan banyak bahan
## sekaligus, termasuk bahan ultra rare yang tidak bisa didapat dari monster lain.
static func roll_drops(enemy_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var region := region_of(enemy_id)
	var wanted: Array = []  # [kategori, jumlah, peluang]
	match rarity_of(enemy_id):
		"common":
			wanted = [["common", 1, 0.6]]
		"rare":
			wanted = [["rare", 1, 0.6], ["common", 1, 0.4]]
		"super":
			wanted = [["super", 2, 1.0], ["rare", 1, 1.0]]
		"ultra":
			wanted = [["ultra", 3, 1.0], ["super", 2, 1.0], ["rare", 3, 1.0], ["common", 4, 1.0]]
	var drops := {}
	for entry: Array in wanted:
		if rng.randf() < float(entry[2]):
			drops[material_id(region, entry[0])] = int(entry[1])
	return drops


# ---------------------------------------------------------------- perlengkapan

static func gear_id(owner: String, slot: String, tier: int) -> String:
	return "%s_%s_%d" % [owner, slot, tier]


static func has_gear(id: String) -> bool:
	var parts := id.split("_")
	return parts.size() == 3 and GEAR_NAMES.has(parts[0]) and GEAR_SLOTS.has(parts[1]) \
		and parts[2].is_valid_int() and int(parts[2]) >= 1 and int(parts[2]) <= GEAR_TIERS


## Data sebuah perlengkapan: {"id", "owner", "slot", "tier", "name", "price"}.
static func gear(id: String) -> Dictionary:
	var parts := id.split("_")
	var tier := int(parts[2])
	return {"id": id, "owner": parts[0], "slot": parts[1], "tier": tier,
		"name": GEAR_NAMES[parts[0]][parts[1]][tier - 1], "price": GEAR_PRICES[parts[1]][tier - 1]}


## Bonus stat sebuah perlengkapan pada tingkat tempa `plus`: nama stat -> nilai.
static func gear_stats(id: String, plus: int) -> Dictionary:
	var g := gear(id)
	var out := {}
	var base: Dictionary = GEAR_STATS[g.slot][int(g.tier) - 1]
	for key: String in base:
		var stat_name: String = GEAR_MAIN_STAT[g.owner] if key == "main" else key
		var value := float(base[key])
		if key == GEAR_PRIMARY[g.slot]:
			value += max(1, roundi(value * ENHANCE_STEP)) * plus
		else:
			value *= 1.0 + ENHANCE_STEP * plus
		out[stat_name] = roundi(value)
	return out


## Teks bonus stat, mis. "DEF +3  HP +8".
static func gear_stat_text(id: String, plus: int) -> String:
	var parts: Array = []
	var stats := gear_stats(id, plus)
	for stat_name: String in stats:
		parts.append("%s +%d" % [STAT_LABELS[stat_name], stats[stat_name]])
	return "  ".join(parts)


## Nama lengkap barang yang dipakai, mis. "Pedang Besi +2".
static func gear_title(entry: Dictionary) -> String:
	var plus := int(entry.get("plus", 0))
	return gear(entry.id).name + ("" if plus == 0 else " +%d" % plus)


## Biaya menempa dari `plus` ke `plus + 1`: {"gold", "mats": {id bahan: jumlah}}; kosong kalau sudah maksimal.
static func enhance_cost(id: String, plus: int) -> Dictionary:
	if plus >= ENHANCE_MAX:
		return {}
	var g := gear(id)
	var mats := {}
	for entry: Array in ENHANCE_RECIPES[plus]:
		mats[material_id(g.tier, entry[0])] = int(entry[1])
	return {"gold": roundi(float(g.price) * ENHANCE_GOLD * (plus + 1)), "mats": mats}


static func reforge_cost(id: String) -> Dictionary:
	var g := gear(id)
	return {"gold": roundi(float(g.price) * REFORGE_GOLD), "mats": {material_id(g.tier, "rare"): 1}}


## Sifat yang mungkin didapat sebuah perlengkapan.
static func trait_pool(id: String) -> Array:
	var g := gear(id)
	return WEAPON_TRAITS[int(g.tier) - 1] if g.slot == "weapon" else SLOT_TRAITS[g.slot]


## Peluang sifat aktif di battle pada tingkat tempa `plus`.
static func trait_chance(plus: int) -> float:
	return TRAIT_BASE + TRAIT_STEP * plus


## Keterangan sifat, mis. "Terbakar 25% saat menyerang (ke musuh)".
static func trait_text(entry: Dictionary) -> String:
	var status_id: String = entry.get("trait", "")
	if status_id == "":
		return ""
	var slot: String = gear(entry.id).slot
	var who := ""
	if slot == "weapon":
		who = " (ke musuh)" if STATUSES[status_id].kind == "nerf" else " (ke diri sendiri)"
	return "%s %d%% %s%s" % [STATUSES[status_id].name, roundi(trait_chance(int(entry.plus)) * 100.0), TRAIT_WHEN[slot], who]


## Teks biaya bahan dengan jumlah yang dimiliki, mis. "Serat Liar 1/2, Taring Serigala 3/2".
static func mats_text(mats: Dictionary, owned: Dictionary) -> String:
	var parts: Array = []
	for mat_id: String in mats:
		parts.append("%s %d/%d" % [MATERIALS[mat_id].name, int(owned.get(mat_id, 0)), mats[mat_id]])
	return ", ".join(parts)


static func xp_to_next(level: int) -> int:
	return 5 * level * level + 5 * level


static func new_party() -> Array:
	var party: Array = []
	for char_id: String in START_PARTY:
		party.append(Battler.from_character(char_id, 1))
	return party
