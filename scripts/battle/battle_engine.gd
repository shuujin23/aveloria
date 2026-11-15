class_name BattleEngine
extends RefCounted
## Aturan pertarungan tanpa tampilan: urutan giliran, kerusakan, jurus, AI musuh, hadiah.
## Layar battle dan simulasi balancing sama-sama memakai kelas ini.

const CRIT_CHANCE := 1.0 / 24.0
const ENEMY_SKILL_CHANCE := 0.35
const FLEE_CHANCE := 0.5

var party: Array = []
var enemies: Array = []
var rng := RandomNumberGenerator.new()
## Isi tas party (id barang -> jumlah). Layar battle mengisinya dengan Game.items, jadi barang
## yang terpakai langsung berkurang dari tas yang sebenarnya.
var items := {}
## Pesan pembuka: sifat perlengkapan (kepala, kaki) yang aktif di awal pertarungan.
var opening_lines: Array = []
## Bagian MP maksimum yang pulih tiap akhir ronde (lihat Db.MP_REGEN); simulasi bisa mengubahnya.
var mp_regen := Db.MP_REGEN


func _init(p_party: Array, p_enemies: Array) -> void:
	party = p_party
	enemies = p_enemies
	for b: Battler in party + enemies:
		b.reset_battle_state()
	for m: Battler in party:
		for slot: String in ["head", "feet"]:
			_gear_buff(m, slot, opening_lines)
	# Jurus pasif pembuka: seluruh party mendapat buff di awal pertarungan.
	for pair: Array in [["open_attack_up", "attack_up"], ["open_defense_up", "defense_up"]]:
		for m: Battler in party:
			if m.is_alive() and m.passive(pair[0]) > 0.0:
				for ally: Battler in living(party):
					if not ally.has_status(pair[1]):
						apply_status(ally, pair[1], opening_lines)
				break


## Sifat buff sebuah perlengkapan: berpeluang memberi efeknya ke pemakainya sendiri.
func _gear_buff(b: Battler, slot: String, lines: Array) -> void:
	var gear_trait := b.gear_trait(slot)
	if gear_trait.is_empty() or not b.is_alive() or Db.STATUSES[gear_trait.status].kind != "buff":
		return
	if b.has_status(gear_trait.status) or rng.randf() >= float(gear_trait.chance):
		return
	lines.append(Loc.t("Sifat %s milik %s aktif!") % [Db.gear_title(b.equip[slot]), b.display_name])
	apply_status(b, gear_trait.status, lines)


## Sifat nerf senjata: berpeluang mengenai musuh yang baru saja diserang pemakainya.
func _weapon_nerf(actor: Battler, target: Battler, lines: Array) -> void:
	var gear_trait := actor.gear_trait("weapon")
	if gear_trait.is_empty() or not target.is_alive() or Db.STATUSES[gear_trait.status].kind != "nerf":
		return
	if target.immune.has(gear_trait.status) or target.blocks_nerf() or rng.randf() >= float(gear_trait.chance):
		return
	lines.append(Loc.t("Sifat %s milik %s aktif!") % [Db.gear_title(actor.equip["weapon"]), actor.display_name])
	apply_status(target, gear_trait.status, lines)


## Buat petarung musuh dari daftar id monster; yang kembar diberi akhiran A, B, C.
static func make_encounter(ids: Array) -> Array:
	var total := {}
	for enemy_id: String in ids:
		total[enemy_id] = total.get(enemy_id, 0) + 1
	var seen := {}
	var result: Array = []
	for enemy_id: String in ids:
		var suffix := ""
		if total[enemy_id] > 1:
			suffix = " " + char(65 + seen.get(enemy_id, 0))
			seen[enemy_id] = seen.get(enemy_id, 0) + 1
		result.append(Battler.from_enemy(enemy_id, suffix))
	return result


func living(list: Array) -> Array:
	var out: Array = []
	for b: Battler in list:
		if b.is_alive():
			out.append(b)
	return out


func is_victory() -> bool:
	return living(enemies).is_empty()


func is_defeat() -> bool:
	return living(party).is_empty()


func can_flee() -> bool:
	for e: Battler in enemies:
		if e.is_boss:
			return false
	return true


func try_flee() -> bool:
	return can_flee() and rng.randf() < FLEE_CHANCE


func enemy_command(e: Battler) -> Dictionary:
	var usable: Array = []
	for s: String in e.skills:
		var sk: Dictionary = Db.SKILLS[s]
		if sk.mp > e.mp:
			continue
		if sk.kind == "status" and sk.target == "self" and e.has_status(sk.status):
			continue  # jangan mengulang buff diri yang masih aktif
		usable.append(s)
	if not usable.is_empty() and rng.randf() < ENEMY_SKILL_CHANCE:
		return {"actor": e, "kind": "skill", "skill": usable[rng.randi() % usable.size()],
			"target": _enemy_target()}
	return {"actor": e, "kind": "attack", "target": _enemy_target()}


## Sasaran serangan monster: tokoh yang sedang memancing (efek Pancing) kalau ada, selain itu acak.
func _enemy_target() -> Battler:
	var taunting := living(party).filter(func(m: Battler) -> bool: return m.has_status("taunt"))
	return _random_living(party) if taunting.is_empty() else taunting[rng.randi() % taunting.size()]


## Urutan giliran satu ronde: semua petarung yang masih hidup, SPD tertinggi lebih dulu dengan sedikit
## unsur acak. Diundi sekali di awal ronde; tiap petarung lalu beraksi saat gilirannya tiba.
func round_order() -> Array:
	var keyed: Array = []
	for b: Battler in living(party + enemies):
		var key := b.stat("agi") * rng.randf_range(0.75, 1.25)
		if b.legend_effect() == "first_strike":  # Busur Angin Timur: selalu paling dulu
			key += 100000.0
		keyed.append({"who": b, "key": key})
	keyed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.key > b.key)
	var out: Array = []
	for k: Dictionary in keyed:
		out.append(k.who)
	return out

## Tentukan sasaran akhir sebuah aksi sebelum dijalankan (untuk animasi), dan kunci
## sasaran itu di dalam cmd supaya execute() mengenai petarung yang sama.
func resolve_targets(cmd: Dictionary) -> Array:
	var actor: Battler = cmd.actor
	var mode := "self"
	if cmd.kind == "item":  # sasaran barang dipilih pemain dan tidak dialihkan (bisa rekan yang tumbang)
		return [cmd.target]
	if cmd.kind == "skill" and Db.SKILLS[cmd.skill].kind == "revive":
		var fallen := _fallen_target(cmd.get("target"), actor)
		cmd["target"] = fallen
		return [fallen] if fallen != null else []
	if cmd.kind == "attack":
		mode = "enemy"
	elif cmd.kind == "skill":
		mode = Db.SKILLS[cmd.skill].target
	match mode:
		"enemy", "ally":
			var pool: Array = _foes(actor) if mode == "enemy" else _allies(actor)
			if cmd.kind == "skill" and Db.SKILLS[cmd.skill].kind == "mp":
				pool = others(actor)
			var target := _retarget(cmd.get("target"), pool)
			cmd["target"] = target
			return [target] if target != null else []
		"all_enemies":
			return living(_foes(actor))
		"all_allies":
			return living(_allies(actor))
	return [actor]


## Jalankan giliran seorang petarung; mengembalikan baris pesan untuk ditampilkan.
func execute(cmd: Dictionary) -> Array:
	var lines: Array = []
	var actor: Battler = cmd.actor
	if not actor.is_alive():
		return lines
	actor.defending = false  # bertahan berlaku sampai giliran berikutnya petarung itu
	if actor.has_status("stun"):  # Terpaku: kehilangan giliran ini, lalu efeknya hilang
		actor.statuses.erase("stun")
		lines.append(Loc.t("%s terpaku dan kehilangan gilirannya!") % actor.display_name)
		return lines
	match cmd.kind:
		"defend":
			actor.defending = true
			lines.append(Loc.t("%s bersiaga menahan serangan.") % actor.display_name)
		"attack":
			var target := _retarget(cmd.get("target"), _foes(actor))
			if target != null:
				lines.append(Loc.t("%s menyerang %s!") % [actor.display_name, target.display_name])
				_phys_hit(actor, target, 1.0, 0.0, lines)
				_second_strike(actor, target, 1.0, lines)
				_weapon_nerf(actor, target, lines)
				_gear_buff(actor, "weapon", lines)
		"skill":
			_use_skill(actor, cmd.skill, cmd.get("target"), lines)
		"item":
			var item: Dictionary = Db.ITEMS[cmd.item]
			lines.append(Loc.t("%s memakai %s!") % [actor.display_name, Loc.t(item.name)])
			if int(items.get(cmd.item, 0)) <= 0:
				lines.append(Loc.t("Tetapi %s sudah habis!") % Loc.t(item.name))
			elif apply_item(cmd.item, cmd.target, lines):
				items[cmd.item] -= 1
				if items[cmd.item] <= 0:
					items.erase(cmd.item)
	return lines


## Terapkan khasiat sebuah barang ke sasaran. Mengembalikan false kalau tidak berpengaruh
## (barangnya tidak terpakai). Dipakai juga oleh menu Barang di peta.
static func apply_item(item_id: String, target: Battler, lines: Array) -> bool:
	var item: Dictionary = Db.ITEMS[item_id]
	match item.kind:
		"heal":
			if target.is_alive() and target.hp < target.max_hp:
				var amount: int = min(int(item.power), target.max_hp - target.hp)
				target.hp += amount
				lines.append(Loc.t("HP %s pulih %d.") % [target.display_name, amount])
				return true
		"mp":
			if target.is_alive() and target.mp < target.max_mp:
				var amount: int = min(int(item.power), target.max_mp - target.mp)
				target.mp += amount
				lines.append(Loc.t("MP %s pulih %d.") % [target.display_name, amount])
				return true
		"cure":
			var removed := false
			for status_id: String in target.statuses.keys():
				if Db.STATUSES[status_id].kind == "nerf":
					target.statuses.erase(status_id)
					removed = true
			if removed:
				lines.append(Loc.t("Semua nerf pada %s hilang.") % target.display_name)
				return true
		"status":
			if target.is_alive():
				var st: Dictionary = Db.STATUSES[item.status]
				if st.has("cancels"):
					target.statuses.erase(st.cancels)
				target.statuses[item.status] = max(int(target.statuses.get(item.status, 0)), int(st.turns))
				lines.append(Loc.t("%s mendapat %s!") % [target.display_name, Loc.t(st.name)])
				return true
		"revive":
			if not target.is_alive():
				target.hp = max(1, int(target.max_hp * float(item.power)))
				lines.append(Loc.t("%s bangkit kembali!") % target.display_name)
				return true
	lines.append(Loc.t("Tidak berpengaruh pada %s.") % target.display_name)
	return false


## Dipanggil di akhir ronde: terbakar/racun melukai, lalu durasi semua efek berkurang.
## Bisa menumbangkan petarung, jadi pemanggil perlu memeriksa menang/kalah sesudahnya.
func end_round() -> Array:
	var lines: Array = []
	for m: Battler in party:  # MP pulih sedikit tiap ronde; lebih banyak untuk yang bertahan
		if m.is_alive():
			m.mp = min(m.max_mp, m.mp + mp_gain(m))
	for b: Battler in party + enemies:
		for status_id: String in b.statuses.keys():
			var st: Dictionary = Db.STATUSES[status_id]
			if st.has("dot") and b.is_alive():
				var dmg := float(b.max_hp) * float(st.dot) * (Db.BOSS_DOT_FACTOR if b.is_boss else 1.0)
				var dealt: int = max(1, int(round(dmg)))
				b.hp = max(0, b.hp - dealt)
				lines.append(Loc.t("%s menderita %s: %d kerusakan.") % [b.display_name, Loc.t(st.name), dealt])
				if not b.is_alive():
					lines.append((Loc.t("%s dikalahkan!") if b.is_enemy else Loc.t("%s tumbang!")) % b.display_name)
			if st.get("no_decay", false):  # efek yang hilang saat terpakai, bukan oleh waktu
				continue
			b.statuses[status_id] -= 1
			if b.statuses[status_id] <= 0:
				b.statuses.erase(status_id)
				if b.is_alive():
					lines.append(Loc.t("%s pada %s berakhir.") % [Loc.t(st.name), b.display_name])
		if not b.is_alive():
			b.statuses.clear()
	return lines


## MP yang pulih untuk seorang anggota party di akhir ronde ini.
func mp_gain(m: Battler) -> int:
	var gain: int = max(1, roundi(m.max_mp * mp_regen * (1.0 + m.passive("mp_regen_boost")))) if mp_regen > 0.0 else 0
	return roundi(gain * Db.MP_REGEN_DEFEND) if m.defending else gain


## Beri efek status ke sasaran. Nerf bisa ditolak oleh kekebalan bawaan atau efek Kebal.
func apply_status(target: Battler, status_id: String, lines: Array) -> void:
	if not target.is_alive():
		return
	var st: Dictionary = Db.STATUSES[status_id]
	var boss_proof: bool = target.is_boss and st.get("no_boss", false)  # semi-bos dan bos kebal Terpaku
	if st.kind == "nerf" and (target.immune.has(status_id) or target.blocks_nerf() or boss_proof):
		lines.append(Loc.t("%s kebal terhadap %s.") % [target.display_name, Loc.t(st.name)])
		return
	if st.has("cancels"):
		target.statuses.erase(st.cancels)
	target.statuses[status_id] = max(int(target.statuses.get(status_id, 0)), int(st.turns))
	lines.append((Loc.t("%s terkena %s!") if st.kind == "nerf" else Loc.t("%s mendapat %s!")) % [target.display_name, Loc.t(st.name)])


## Bagikan XP dan emas setelah menang. Anggota yang tumbang tidak dapat XP, lalu bangkit dengan 1 HP.
func grant_rewards() -> Dictionary:
	var xp := 0
	var gold := 0
	for e: Battler in enemies:
		xp += e.xp_reward
		gold += e.gold_reward
	var drops := {}  # bahan yang dijatuhkan monster: id -> jumlah
	for e: Battler in enemies:
		var dropped := Db.roll_drops(e.id, rng)
		for mat_id: String in dropped:
			drops[mat_id] = int(drops.get(mat_id, 0)) + int(dropped[mat_id])
	var lines: Array = [Loc.t("Party mendapat %d XP dan %d emas.") % [xp, gold]]
	for m: Battler in party:
		if m.is_alive():
			lines.append_array(m.gain_xp(xp))
		else:
			m.hp = 1
		m.reset_battle_state()
	return {"xp": xp, "gold": gold, "lines": lines, "drops": drops}


## Rekan-rekan seorang petarung, tanpa dirinya sendiri.
func others(actor: Battler) -> Array:
	return _allies(actor).filter(func(b: Battler) -> bool: return b != actor)


func _foes(actor: Battler) -> Array:
	return party if actor.is_enemy else enemies


func _allies(actor: Battler) -> Array:
	return enemies if actor.is_enemy else party


func _random_living(list: Array) -> Battler:
	var alive := living(list)
	if alive.is_empty():
		return null
	return alive[rng.randi() % alive.size()]


## Kalau target sudah tumbang (atau bukan bagian dari pool), pindah ke target hidup lain di pool itu.
func _retarget(target: Variant, pool: Array) -> Battler:
	if target != null and (target as Battler).is_alive() and pool.has(target):
		return target
	return _random_living(pool)


func _use_skill(actor: Battler, skill_id: String, wanted: Variant, lines: Array) -> void:
	var sk: Dictionary = Db.SKILLS[skill_id]
	lines.append(Loc.t("%s menggunakan %s!") % [actor.display_name, Loc.t(sk.name)])
	var cost := actor.skill_cost(skill_id)
	if actor.mp < cost:
		lines.append(Loc.t("Tetapi MP tidak cukup!"))
		return
	actor.mp -= cost

	var targets: Array = []
	match sk.target:
		"enemy":
			targets = [_retarget(wanted, _foes(actor))]
		"ally":
			if sk.kind == "revive":  # hanya rekan yang tumbang
				targets = [_fallen_target(wanted, actor)]
			else:
				targets = [_retarget(wanted, others(actor) if sk.kind == "mp" else _allies(actor))]
		"all_enemies":
			targets = living(_foes(actor))
		"all_allies":
			targets = living(_allies(actor))
		"self":
			targets = [actor]

	for t: Battler in targets:
		if t == null:
			if sk.kind == "revive":
				lines.append(Loc.t("Tidak ada rekan yang tumbang."))
			continue
		match sk.kind:
			"phys":
				for hit in int(sk.get("hits", 1)):  # jurus beruntun mengenai beberapa kali
					if t.is_alive():
						_phys_hit(actor, t, sk.power, sk.get("crit", 0.0), lines)
				_second_strike(actor, t, sk.power, lines)
				_inflict(sk, t, lines, actor)
				_weapon_nerf(actor, t, lines)
			"magic":
				var dmg := (float(sk.power) + actor.stat("mag") * 0.5) * rng.randf_range(0.85, 1.15)
				dmg *= 1.0 + actor.passive("magic_boost")
				_apply_damage(t, dmg, lines)
				_inflict(sk, t, lines, actor)
				_weapon_nerf(actor, t, lines)
			"heal":
				var amount := int((float(sk.power) + actor.stat("mag") * 0.5) * rng.randf_range(0.9, 1.1))
				if actor.legend_effect() == "heal_boost":  # Tongkat Cahaya Abadi
					amount = int(amount * Db.LEGEND_HEAL_BOOST)
				amount = int(amount * (1.0 + actor.passive("heal_boost")))
				amount = min(amount, t.max_hp - t.hp)
				t.hp += amount
				lines.append(Loc.t("HP %s pulih %d.") % [t.display_name, amount])
			"revive":
				t.hp = max(1, int(t.max_hp * float(sk.power)))
				lines.append(Loc.t("%s bangkit kembali!") % t.display_name)
			"mp":  # memulihkan MP rekan lain; tidak berlaku untuk pemakainya sendiri
				if t == actor or t.mp >= t.max_mp:
					lines.append(Loc.t("Tidak berpengaruh pada %s.") % t.display_name)
				else:
					var restored: int = min(int(float(sk.power) + actor.stat("mag") * 0.25), t.max_mp - t.mp)
					t.mp += restored
					lines.append(Loc.t("MP %s pulih %d.") % [t.display_name, restored])
			"status":
				apply_status(t, sk.status, lines)
			"cleanse":
				var removed := 0
				for status_id: String in t.statuses.keys():
					if Db.STATUSES[status_id].kind == "nerf":
						t.statuses.erase(status_id)
						removed += 1
				if removed > 0:
					lines.append(Loc.t("Semua nerf pada %s hilang.") % t.display_name)
				if sk.has("status"):
					apply_status(t, sk.status, lines)
	if sk.kind in ["phys", "magic"]:
		_gear_buff(actor, "weapon", lines)


## Sasaran jurus pembangkit: rekan tumbang yang diminta, atau rekan tumbang lain; null kalau tidak ada.
func _fallen_target(wanted: Variant, actor: Battler) -> Battler:
	var fallen := _allies(actor).filter(func(b: Battler) -> bool: return not b.is_alive())
	if wanted != null and fallen.has(wanted):
		return wanted
	return null if fallen.is_empty() else fallen[0]


## Efek status tambahan dari jurus serangan, dengan peluang tertentu (ditambah bonus pasif pemakainya).
func _inflict(sk: Dictionary, target: Battler, lines: Array, actor: Battler = null) -> void:
	if not sk.has("inflict") or not target.is_alive():
		return
	var chance := float(sk.inflict.chance) + (actor.passive("inflict_bonus") if actor != null else 0.0)
	if rng.randf() < chance:
		apply_status(target, sk.inflict.status, lines)


func _phys_hit(actor: Battler, target: Battler, power: float, crit_bonus: float, lines: Array) -> void:
	if rng.randf() < target.passive("dodge"):  # pasif Langkah Ringan
		lines.append(Loc.t("%s menghindar!") % target.display_name)
		return
	var raw := actor.stat("atk") * power
	var dmg: float
	if actor.legend_effect() == "first_strike":
		crit_bonus += Db.LEGEND_CRIT_BONUS
	crit_bonus += actor.passive("crit_bonus")
	if rng.randf() < CRIT_CHANCE + crit_bonus:
		lines.append(Loc.t("Serangan kritikal!"))
		dmg = raw * 1.5
	else:
		dmg = raw - target.stat("defense") * 0.5
	if actor.passive("exploit") > 0.0 and _has_nerf(target):  # pasif Oportunis
		dmg *= 1.0 + actor.passive("exploit")
	var dealt := _apply_damage(target, dmg * rng.randf_range(0.85, 1.15), lines)
	var drain := actor.passive("drain")  # pasif Haus Darah
	if drain > 0.0 and actor.is_alive() and actor.hp < actor.max_hp:
		var healed: int = min(max(1, int(dealt * drain)), actor.max_hp - actor.hp)
		actor.hp += healed
		lines.append(Loc.t("%s menyerap %d HP.") % [actor.display_name, healed])


func _has_nerf(b: Battler) -> bool:
	for status_id: String in b.statuses:
		if Db.STATUSES[status_id].kind == "nerf":
			return true
	return false


## Pedang Fajar: serangan fisik berpeluang menebas sekali lagi dengan separuh kekuatan.
func _second_strike(actor: Battler, target: Battler, power: float, lines: Array) -> void:
	if actor.legend_effect() != "double_strike" or not target.is_alive() or rng.randf() >= Db.LEGEND_DOUBLE_CHANCE:
		return
	lines.append(Loc.t("%s menebas sekali lagi!") % actor.display_name)
	_phys_hit(actor, target, power * 0.5, 0.0, lines)


## Kurangi HP sasaran; mengembalikan kerusakan yang benar-benar diterima.
func _apply_damage(target: Battler, amount: float, lines: Array) -> int:
	if target.defending:
		amount *= 0.5
	amount *= 1.0 - target.passive("damage_cut")  # pasif Kulit Baja
	var dmg: int = max(1, int(round(amount)))
	target.hp = max(0, target.hp - dmg)
	lines.append(Loc.t("%s menerima %d kerusakan.") % [target.display_name, dmg])
	if not target.is_alive():
		lines.append((Loc.t("%s dikalahkan!") if target.is_enemy else Loc.t("%s tumbang!")) % target.display_name)
	else:
		_gear_buff(target, "body", lines)
	return dmg
