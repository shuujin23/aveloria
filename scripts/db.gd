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
	"ogre": {"name": "Ogre Penjaga", "hp": 190, "mp": 30, "atk": 23, "defense": 9, "mag": 0, "agi": 5,
		"xp": 80, "gold": 100, "skills": ["hantaman_bumi", "raungan", "serangan_buas"], "immune": ["slow"],
		"boss": true},
	# --- Hutan Kabut ---
	"laba_laba": {"name": "Laba-laba Kabut", "hp": 52, "mp": 8, "atk": 22, "defense": 8, "mag": 0, "agi": 12,
		"xp": 16, "gold": 10, "skills": ["gigitan_racun", "jaring"], "immune": ["poison"]},
	"roh_kabut": {"name": "Roh Kabut", "hp": 38, "mp": 20, "atk": 9, "defense": 14, "mag": 18, "agi": 9,
		"xp": 15, "gold": 12, "skills": ["lidah_api"], "immune": ["burn"], "voice": "soft"},
	"ratu": {"name": "Ratu Laba-laba", "hp": 380, "mp": 60, "atk": 28, "defense": 11, "mag": 13, "agi": 9,
		"xp": 180, "gold": 220, "skills": ["gigitan_racun", "jaring_raksasa", "semburan_racun"], "immune": ["poison", "slow"],
		"boss": true},
	# --- Pegunungan Abu ---
	"kadal_bara": {"name": "Kadal Bara", "hp": 74, "mp": 8, "atk": 30, "defense": 12, "mag": 0, "agi": 12,
		"xp": 26, "gold": 16, "skills": ["gigitan_bara"], "immune": ["burn"]},
	"elang_abu": {"name": "Elang Abu", "hp": 56, "mp": 8, "atk": 28, "defense": 8, "mag": 0, "agi": 21,
		"xp": 24, "gold": 14, "skills": ["cakar_tajam"], "immune": []},
	"golem_batu": {"name": "Golem Batu", "hp": 120, "mp": 12, "atk": 33, "defense": 22, "mag": 0, "agi": 4,
		"xp": 34, "gold": 24, "skills": ["hantaman_batu", "kulit_batu"], "immune": ["poison"]},
	"lahar": {"name": "Raksasa Lahar", "hp": 640, "mp": 80, "atk": 38, "defense": 17, "mag": 18, "agi": 7,
		"xp": 340, "gold": 420, "skills": ["semburan_lahar", "hantaman_bumi", "kulit_batu"], "immune": ["burn", "slow"],
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
}

## Semi-bos di peta: id penanda (flag) -> kelompok musuh.
const BOSSES := {
	"ogre": ["ogre"],
	"ratu": ["laba_laba", "ratu", "laba_laba"],
	"lahar": ["kadal_bara", "lahar", "kadal_bara"],
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


static func random_group(table: String) -> Array:
	var groups: Array = ENCOUNTER_TABLES[table]
	return groups[randi() % groups.size()]


static func xp_to_next(level: int) -> int:
	return 5 * level * level + 5 * level


static func new_party() -> Array:
	var party: Array = []
	for char_id: String in START_PARTY:
		party.append(Battler.from_character(char_id, 1))
	return party
