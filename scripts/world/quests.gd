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
##   reward   {"slot", "tier", "rarity", "gold"}: perlengkapan untuk satu anggota party pilihan pemain, plus emas

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
			steps.append({"do": "reward_gear", "slot": q.reward.slot, "tier": q.reward.tier, "rarity": q.reward.rarity})
			steps.append({"do": "gold", "amount": q.reward.gold})
			steps.append({"do": "flag", "flag": "q_%s_done" % id})
			steps.append({"do": "quest_note", "title": "Quest selesai: %s", "quest": id, "hint": ""})
	return steps


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
