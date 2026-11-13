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
var statuses := {}  # id efek status (lihat Db.STATUSES) -> sisa ronde
var immune: Array = []  # id efek status yang tidak mempan pada petarung ini

## Perlengkapan yang dipakai (khusus anggota party): slot -> {"id", "plus", "trait"}.
## plus = tingkat tempa; trait = id efek status sifatnya ("" kalau belum punya).
var equip := {}

var xp_reward := 0
var gold_reward := 0


static func from_character(char_id: String, at_level: int) -> Battler:
	var b := Battler.new()
	var c: Dictionary = Db.CHARACTERS[char_id]
	b.id = char_id
	b.display_name = c.name
	b.job = c.job
	b.level = at_level
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
	b.display_name = String(e.name) + suffix
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
	for slot: String in equip:
		var bonus := Db.gear_stats(equip[slot].id, int(equip[slot].plus))
		for stat_name: String in bonus:
			set(stat_name, int(get(stat_name)) + int(bonus[stat_name]))
	hp = min(hp, max_hp)
	skills.clear()
	var learn: Dictionary = c.learn
	var levels: Array = learn.keys()
	levels.sort()
	for lv: int in levels:
		if lv <= level:
			skills.append_array(learn[lv])


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
		lines.append("%s naik ke Level %d!" % [display_name, level])
		for s: String in skills:
			if not old_skills.has(s):
				lines.append("%s mempelajari jurus %s!" % [display_name, Db.SKILLS[s].name])
	return lines
