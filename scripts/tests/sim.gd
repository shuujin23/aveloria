extends SceneTree
## Simulasi balancing tanpa tampilan. Jalankan:
##   Godot_console.exe --headless --path . -s res://scripts/tests/sim.gd
## Party dimainkan AI sederhana mengikuti alur cerita:
## Wilayah 1: Arlen sendirian di padang -> menolong Mira -> berdua berlatih -> Ogre Penjaga.
## Wilayah 2: berdua di Hutan Kabut -> menolong Selene -> bertiga berlatih -> Ratu Laba-laba.

const RUNS := 400
# Tiap tahap: tabel pertemuan, "event:mira" (Mira bergabung lalu battle cerita), atau "boss:<id>".
const ROUTE := [
	"lembah_padang", "lembah_padang", "lembah_padang", "lembah_padang",
	"event:mira",
	"lembah_padang", "lembah_padang", "lembah_padang", "lembah_hutan", "lembah_hutan", "lembah_hutan", "lembah_hutan",
	"boss:ogre",
	"kabut_padang", "kabut_padang", "kabut_padang",
	"event:selene",
	"kabut_padang", "kabut_padang", "kabut_hutan", "kabut_hutan", "kabut_hutan", "kabut_hutan",
	"boss:ratu",
]
# Battle cerita: tokoh yang bergabung dan kelompok musuhnya.
const EVENTS := {
	"event:mira": {"join": "mira", "ids": ["serigala", "kelelawar"]},
	"event:selene": {"join": "selene", "ids": ["laba_laba", "roh_kabut", "laba_laba"]},
}


func _init() -> void:
	for rest_every: int in [1, 2]:
		_run(rest_every)
	quit()


## rest_every = menginap di desa setiap N pertarungan (selalu sebelum battle cerita dan semi-bos).
func _run(rest_every: int) -> void:
	var cleared := 0
	var rounds_sum := 0
	var battles := 0
	var tries := {}
	var won := {}
	var level_at := {}
	for i in RUNS:
		var party := Db.new_party()
		var step := 0
		while step < ROUTE.size():
			var stage: String = ROUTE[step]
			var ids: Array
			if EVENTS.has(stage):
				party.append(Battler.from_character(EVENTS[stage].join, (party[0] as Battler).level))
				ids = EVENTS[stage].ids
			elif stage.begins_with("boss:"):
				ids = Db.BOSSES[stage.trim_prefix("boss:")]
			else:
				ids = Db.random_group(stage).slice(0, party.size() + 1)
			var eng := BattleEngine.new(party, BattleEngine.make_encounter(ids))
			level_at[stage] = level_at.get(stage, 0.0) + (party[0] as Battler).level
			var rounds := _fight(eng)
			battles += 1
			rounds_sum += abs(rounds)
			tries[stage] = tries.get(stage, 0) + 1
			if rounds < 0:
				break
			won[stage] = won.get(stage, 0) + 1
			eng.grant_rewards()
			step += 1
			if step % rest_every == 0 or (step < ROUTE.size() and (ROUTE[step] as String).contains(":")):
				for m: Battler in party:
					m.full_restore()
		if step == ROUTE.size():
			cleared += 1

	print("=== Menginap tiap %d battle ===" % rest_every)
	print("  tamat sampai Ratu         : %.0f%%" % (100.0 * cleared / RUNS))
	print("  rata-rata ronde per battle: %.1f" % (float(rounds_sum) / battles))
	for stage: String in tries:
		print("  %-14s menang %4d/%4d (%3.0f%%)   level Arlen rata-rata %.1f" % [stage, won.get(stage, 0), tries[stage],
			100.0 * won.get(stage, 0) / tries[stage], level_at[stage] / tries[stage]])


## Mengembalikan jumlah ronde; negatif kalau party kalah.
func _fight(eng: BattleEngine) -> int:
	for r in range(1, 200):
		var cmds: Array = []
		for m: Battler in eng.living(eng.party):
			cmds.append(_policy(eng, m))
		for e: Battler in eng.living(eng.enemies):
			cmds.append(eng.enemy_command(e))
		eng.begin_round(cmds)
		for cmd: Dictionary in eng.turn_order(cmds):
			eng.execute(cmd)
			if eng.is_victory():
				return r
			if eng.is_defeat():
				return -r
		eng.end_round()  # terbakar/racun bisa menumbangkan petarung
		if eng.is_victory():
			return r
		if eng.is_defeat():
			return -r
	return -200


func _policy(eng: BattleEngine, a: Battler) -> Dictionary:
	var allies := eng.living(eng.party)
	var foes := eng.living(eng.enemies)
	var hurt: Battler = allies[0]
	for m: Battler in allies:
		if float(m.hp) / m.max_hp < float(hurt.hp) / hurt.max_hp:
			hurt = m
	var weakest: Battler = foes[0]
	for f: Battler in foes:
		if f.hp < weakest.hp:
			weakest = f

	var offensive: Array = []
	for s: String in a.skills:
		var sk: Dictionary = Db.SKILLS[s]
		if a.mp < sk.mp:
			continue
		if sk.kind == "heal" and float(hurt.hp) / hurt.max_hp < 0.5:
			return {"actor": a, "kind": "skill", "skill": s, "target": hurt}
		if sk.kind in ["phys", "magic"] and not (sk.target == "all_enemies" and foes.size() < 2):
			offensive.append(s)
	if not offensive.is_empty() and randf() < 0.6:
		return {"actor": a, "kind": "skill", "skill": offensive[randi() % offensive.size()], "target": weakest}
	return {"actor": a, "kind": "attack", "target": weakest}
