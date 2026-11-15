class_name Battler
extends RefCounted
## Satu petarung (anggota party atau monster) beserta stat dan kondisinya.

var id := ""
var display_name := ""
var job := ""
var is_enemy := false
var is_boss := false
var level := 1
var xp := 0  # progres menuju level berikutnya

var max_hp := 1
var hp := 1
var max_mp := 0
var mp := 0
var atk := 1
var defense := 0
var mag := 0
var agi := 1

var skills: Array = []
var defending := false
var slam_round := -1  # bos berpola: nomor ronde saat serangan besarnya lepas (-1 = tidak sedang ancang-ancang)
var statuses := {}  # id efek status (lihat Db.STATUSES) -> sisa ronde
var immune: Array = []  # id efek status yang tidak mempan pada petarung ini

## Perlengkapan yang dipakai (khusus anggota party): slot -> {"id", "plus", "trait"}.
## plus = tingkat tempa; trait = id efek status sifatnya ("" kalau belum punya).
var equip := {}

## Poin stat yang sudah dibagi pemain (khusus anggota party): nama stat -> jumlah poin.
var alloc := {}
## Skill tree (khusus anggota party): jurus yang sudah dibuka, dan yang dibawa ke pertarungan
## (paling banyak Db.SKILL_SLOTS; `skills` selalu sama dengan loadout).
var unlocked: Array = []
var loadout: Array = []

var xp_reward := 0
var gold_reward := 0


static func from_character(char_id: String, at_level: int) -> Battler:
	var b := Battler.new()
	var c: Dictionary = Db.CHARACTERS[char_id]
	b.id = char_id
	b.display_name = c.name
	b.job = c.job
	b.level = at_level
	b.default_build()
	b.recalc()
	b.hp = b.max_hp
	b.mp = b.max_mp
	return b


static func from_enemy(enemy_id: String, suffix: String = "") -> Battler:
	var b := Battler.new()
	var e: Dictionary = Db.ENEMIES[enemy_id]
	b.id = enemy_id
	b.is_enemy = true
	b.is_boss = e.get("boss", false)
	b.display_name = Loc.t(String(e.name)) + suffix
	b.max_hp = e.hp
	b.hp = e.hp
	b.max_mp = e.mp
	b.mp = e.mp
	b.atk = e.atk
	b.defense = e.defense
	b.mag = e.mag
	b.agi = e.agi
	b.skills = (e.skills as Array).duplicate()
	b.xp_reward = e.xp
	b.gold_reward = e.gold
	b.immune = (e.get("immune", []) as Array).duplicate()
	return b


## Hitung ulang stat maksimum dan daftar jurus dari level saat ini (khusus anggota party).
func recalc() -> void:
	var c: Dictionary = Db.CHARACTERS[id]
	var base: Dictionary = c.base
	var growth: Dictionary = c.growth
	var n := level - 1
	max_hp = int(base.hp + growth.hp * n)
	max_mp = int(base.mp + growth.mp * n)
	atk = int(base.atk + growth.atk * n)
	defense = int(base.defense + growth.defense * n)
	mag = int(base.mag + growth.mag * n)
	agi = int(base.agi + growth.agi * n)
	for stat_name: String in alloc:  # poin stat yang dibagi pemain
		set(stat_name, int(get(stat_name)) + int(alloc[stat_name]) * int(Db.STAT_POINT_VALUE[stat_name]))
	for slot: String in equip:
		var bonus := Db.entry_stats(equip[slot])
		for stat_name: String in bonus:
			set(stat_name, int(get(stat_name)) + int(bonus[stat_name]))
	hp = min(hp, max_hp)
	mp = min(mp, max_mp)
	skills = loadout.duplicate()  # yang dibawa ke pertarungan
	immune = []  # kekebalan dari jurus pasif
	for skill_id: String in unlocked:
		immune.append_array(Db.SKILLS[skill_id].get("immune", []))


## Nilai sebuah efek pasif dari jurus pasif yang sudah dibuka (0 kalau tidak punya). Monster selalu 0.
func passive(effect: String) -> float:
	var total := 0.0
	for skill_id: String in unlocked:
		var sk: Dictionary = Db.SKILLS[skill_id]
		if sk.kind == "passive" and sk.effect == effect:
			total += float(sk.value)
	return total


## Poin jurus: yang didapat sampai level ini, yang terpakai untuk membuka jurus, dan sisanya.
func skill_points_total() -> int:
	return (level - 1) * Db.SKILL_POINTS_PER_LEVEL


func skill_points_spent() -> int:
	var spent := 0
	for skill_id: String in unlocked:
		spent += Db.unlock_cost(id, skill_id)
	return spent


func skill_points_left() -> int:
	return skill_points_total() - skill_points_spent()


## Apakah sebuah jurus bisa dibuka sekarang: belum terbuka, jurus sebelumnya di cabang itu sudah, poin cukup.
func can_unlock(skill_id: String) -> bool:
	if unlocked.has(skill_id) or int(Db.skill_slot(id, skill_id)[0]) < 0:
		return false
	var prereq := Db.skill_prereq(id, skill_id)
	return (prereq == "" or unlocked.has(prereq)) and Db.unlock_cost(id, skill_id) <= skill_points_left()


## Buka sebuah jurus; kalau susunan jurus belum penuh, jurus itu langsung dibawa.
func unlock(skill_id: String) -> bool:
	if not can_unlock(skill_id):
		return false
	unlocked.append(skill_id)
	if not Db.is_passive(skill_id) and loadout.size() < Db.SKILL_SLOTS:
		loadout.append(skill_id)
	recalc()  # jurus pasif bisa mengubah kekebalan; sekaligus menyamakan skills dengan loadout
	return true


## Susunan awal seorang tokoh: jurus awal, lalu jurus di `learn` sampai level ini selama poinnya cukup.
## Dipakai saat tokoh baru bergabung dan saat memuat simpanan lama yang belum punya skill tree.
func default_build() -> void:
	var c: Dictionary = Db.CHARACTERS[id]
	unlocked = [Db.starter_skill(id)]
	loadout = []
	var learn: Dictionary = c.learn
	var levels: Array = learn.keys()
	levels.sort()
	for lv: int in levels:
		if lv <= level:
			for skill_id: String in learn[lv]:
				if can_unlock(skill_id):
					unlocked.append(skill_id)
	auto_loadout()


## Isi susunan jurus dari yang sudah terbuka, mengikuti urutan `pref` tokoh itu.
func auto_loadout() -> void:
	loadout = []
	for skill_id: String in Db.CHARACTERS[id].pref:
		if unlocked.has(skill_id) and not Db.is_passive(skill_id) and loadout.size() < Db.SKILL_SLOTS:
			loadout.append(skill_id)
	skills = loadout.duplicate()


## Poin stat yang sudah didapat sampai level ini, yang sudah dibagi, dan yang masih tersisa.
func points_total() -> int:
	return (level - 1) * Db.STAT_POINTS_PER_LEVEL


func points_spent() -> int:
	var spent := 0
	for stat_name: String in alloc:
		spent += int(alloc[stat_name])
	return spent


func points_left() -> int:
	return points_total() - points_spent()


## Efek unik senjata Legend yang sedang dipakai (lihat Db.LEGEND_WEAPONS); kosong kalau tidak ada.
func legend_effect() -> String:
	var legend := Db.legend_of(equip.get("weapon", {}))
	return "" if legend.is_empty() else String(legend.effect)


## MP yang dipakai sebuah jurus oleh petarung ini.
func skill_cost(skill_id: String) -> int:
	var cost := int(Db.SKILLS[skill_id].mp)
	if legend_effect() == "mp_saver":
		cost = max(1, roundi(cost * Db.LEGEND_MP_FACTOR))
	return cost


## Sifat perlengkapan di sebuah slot: {"status", "chance"}; kosong kalau tidak ada.
func gear_trait(slot: String) -> Dictionary:
	var entry: Dictionary = equip.get(slot, {})
	var status_id: String = entry.get("trait", "")
	if status_id == "":
		return {}
	return {"status": status_id, "chance": Db.trait_chance(int(entry.plus))}


func is_alive() -> bool:
	return hp > 0


## Nilai stat setelah semua efek status yang sedang aktif.
func stat(stat_name: String) -> float:
	var value := float(get(stat_name))
	for status_id: String in statuses:
		var st: Dictionary = Db.STATUSES[status_id]
		if st.get("stat", "") == stat_name:
			value *= float(st.mult)
	return value


func has_status(status_id: String) -> bool:
	return statuses.has(status_id)


## Selama efek seperti Kebal aktif, nerf baru ditolak.
func blocks_nerf() -> bool:
	for status_id: String in statuses:
		if Db.STATUSES[status_id].get("blocks_nerf", false):
			return true
	return false


func reset_battle_state() -> void:
	defending = false
	slam_round = -1
	statuses.clear()


func full_restore() -> void:
	hp = max_hp
	mp = max_mp


## Tambah XP; mengembalikan baris pesan (naik level, jurus baru).
func gain_xp(amount: int) -> Array:
	var lines: Array = []
	xp += amount
	while xp >= Db.xp_to_next(level):
		xp -= Db.xp_to_next(level)
		var old_skills := skills.duplicate()
		var old_hp := max_hp
		var old_mp := max_mp
		level += 1
		recalc()
		hp += max_hp - old_hp
		mp += max_mp - old_mp
		lines.append(Loc.t("%s naik ke Level %d!") % [display_name, level])
		for s: String in skills:
			if not old_skills.has(s):
				lines.append(Loc.t("%s mempelajari jurus %s!") % [display_name, Loc.t(Db.SKILLS[s].name)])
	return lines
