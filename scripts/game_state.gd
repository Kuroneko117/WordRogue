extends Node

const Route = preload("res://scripts/route_state.gd")
const Brain = preload("res://scripts/enemy_brain.gd")
const Review = preload("res://scripts/review_session.gd")
const Catalog = preload("res://scripts/reward_catalog.gd")
const Difficulty = preload("res://scripts/difficulty_config.gd")
const Enemies = preload("res://scripts/enemy_definitions.gd")
const Momentum = preload("res://scripts/momentum_controller.gd")
const ShortBalance = preload("res://scripts/short_run_balance.gd")
const Events = preload("res://scripts/event_session.gd")
var momentum := Momentum.new()
var events := Events.new()
var difficulty_id := "normal"
var classic_fixture := false
var battle_enemy: Dictionary = {}
var normal_history: Array[String] = []
var event_answers := 0
var route := Route.new()
var enemy_brain := Brain.new()
var review := Review.new()
var enemy_intent: Dictionary = {}
var intent_consumed := true
var ink_active := false
var boss_phase_two := false
var phase_transitions := 0
var rewards_pending := 0
var reward_batch := 0
var offered_rewards: Array[String] = []
var battle_finished := false
var combat_answers := 0
var review_answers := 0
var battles_entered := 0
var reward_claims := 0
var victory_healed := 0
var next_barrier_bonus := 0
var next_opening_bonus := 0
var opening_bonus := 0
var opening_available := true
var renewal_available := true

const BATTLES := [
	{"name": "INK WRAITH", "subtitle": "墨影", "hp": 50, "atk": 10, "kind": "normal"},
	{"name": "DUST SENTINEL", "subtitle": "尘页守卫", "hp": 50, "atk": 10, "kind": "normal"},
	{"name": "THE MARGINALIA", "subtitle": "边注之灵", "hp": 70, "atk": 12, "kind": "elite"},
	{"name": "THE LIBRARIAN", "subtitle": "遗忘图书管理员", "hp": 100, "atk": 15, "kind": "boss"}
]
const REWARDS := [
	{"id": "blade", "name": "WORD BLADE", "description": "基础攻击 +3"},
	{"id": "crystal", "name": "MEMORY CRYSTAL", "description": "每达成连续答对 3 次的里程碑，恢复 3 HP"},
	{"id": "flame", "name": "COMBO FLAME", "description": "Combo ≥ 5 时，最终伤害 +30%"},
	{"id": "shield", "name": "SCHOLAR SHIELD", "description": "每场战斗首次答错时免疫伤害"},
	{"id": "tome", "name": "BEGINNER'S TOME", "description": "答对 Mastery < 30 的词，额外造成 5 伤害"},
	{"id": "quill", "name": "HEALING QUILL", "description": "每场战斗结束恢复 10 HP；获取时立即生效"}
]

var rng := RandomNumberGenerator.new()
var battle_index := 0
var hp := 100
var max_hp := 100
var base_attack := 10
var enemy_hp := 0
var combo := 0
var best_combo := 0
var correct_count := 0
var wrong_count := 0
var seen_words: Dictionary = {}
var wrong_words: Dictionary = {}
var starting_mastery: Dictionary = {}
var rewards: Array[String] = []
var shield_available := true
var current_crystal_milestone := 0
var run_active := false
var run_won := false
const SPELLS := {
	"arcane": {"name":"奥术飞弹","cost":0},
	"aegis": {"name":"守护咒文","cost":1},
	"memory": {"name":"记忆爆发","cost":2}
}
const REWARD_NAMES_ZH := {"blade":"词锋之刃","crystal":"记忆水晶","flame":"连击之焰","shield":"学者之盾","tome":"学徒之书","quill":"治愈羽笔"}
var mana := 1
var max_mana := 3
var barrier := 0
var selected_spell := "arcane"

func _ready() -> void:
	rng.randomize()

func start_run(legacy_route: bool = false, mode_id: String = "normal", classic: bool = false) -> bool:
	classic_fixture = legacy_route or classic
	difficulty_id = mode_id if Difficulty.MODES.has(mode_id) else "normal"
	var mode := Difficulty.get_mode(difficulty_id)
	if not WordBank.load_words("res://data/words.json" if classic_fixture else str(mode.path),120 if classic_fixture else int(mode.count),difficulty_id == "hard" and not classic_fixture): return false
	route.reset(not legacy_route,-1,not classic_fixture)
	events.reset()
	normal_history.clear()
	battle_enemy.clear()
	event_answers = 0
	max_hp = 100
	max_mana = 3
	next_barrier_bonus = 0
	next_opening_bonus = 0
	reward_claims = 0
	rewards_pending = 0
	reward_batch = 0
	offered_rewards.clear()
	combat_answers = 0
	review_answers = 0
	battles_entered = 0
	review.questions.clear()
	review.index = 0
	battle_index = 0
	hp = max_hp
	base_attack = 10
	combo = 0
	best_combo = 0
	correct_count = 0
	wrong_count = 0
	seen_words.clear()
	wrong_words.clear()
	starting_mastery.clear()
	rewards.clear()
	run_active = true
	run_won = false
	SaveData.run_count += 1
	SaveData.save_game()
	start_battle()
	return true

func start_battle() -> void:
	if not classic_fixture:
		var layer := int(route.NODES[route.active].layer) if not route.active.is_empty() else 1
		var kind := str(BATTLES[battle_index].kind)
		var id := Enemies.pick(layer,kind,normal_history,rng)
		battle_enemy = Enemies.ENEMIES[id].duplicate()
		battle_enemy.id = id
		var mode := Difficulty.get_mode(difficulty_id)
		battle_enemy.hp = ceili(float(ShortBalance.BASE_HP.get(id,battle_enemy.hp))*float(mode.hp))
		battle_enemy.atk = maxi(1,ceili(float(battle_enemy.atk)*float(mode.atk)))
		if kind == "normal" and not route.active.is_empty(): normal_history.append(id)
		momentum.reset(battle_enemy)
	enemy_brain.reset()
	enemy_intent = {}
	intent_consumed = true
	ink_active = false
	boss_phase_two = false
	phase_transitions = 0
	battle_finished = false
	mana = 2 if rewards.has("spring") else 1
	barrier = mini(barrier_cap(),(6 if rewards.has("bulwark") else 0)+next_barrier_bonus)
	opening_bonus = next_opening_bonus
	next_barrier_bonus = 0
	next_opening_bonus = 0
	opening_available = true
	renewal_available = true
	victory_healed = 0
	selected_spell = "arcane"
	combo = 0
	shield_available = true
	current_crystal_milestone = 0
	enemy_hp = int(current_enemy().hp)

func current_enemy() -> Dictionary:
	var enemy: Dictionary = BATTLES[battle_index].duplicate() if classic_fixture or battle_enemy.is_empty() else battle_enemy.duplicate()
	if route.extended and not route.active.is_empty() and route.NODES[route.active].kind in ["normal","elite","boss","event"]:
		enemy.hp = int(enemy.hp)+maxi(0,int(route.NODES[route.active].layer)-1)*(14 if classic_fixture else ShortBalance.growth(str(enemy.kind)))
	return enemy

func barrier_cap() -> int:
	return 20 if rewards.has("aegis_edge") else 16

func review_healing() -> int:
	return 7 if rewards.has("restoration") else 5

func reward_name(id: String) -> String:
	return str(REWARD_NAMES_ZH[id]) if REWARD_NAMES_ZH.has(id) else str(Catalog.find(id,REWARDS).get("name",id))

func can_cast(spell: String) -> bool:
	return SPELLS.has(spell) and mana >= int(SPELLS[spell]["cost"])

func select_spell(spell: String) -> bool:
	if not can_cast(spell): return false
	selected_spell = spell
	return true

func enter_node(id: String) -> bool:
	if not run_active or hp <= 0 or not route.enter(id): return false
	var node: Dictionary = route.NODES[id]
	if node.kind == "memory":
		review.build(WordBank,SaveData,wrong_words)
	elif node.kind == "treasure":
		battle_finished = true
		reward_batch = 1
		rewards_pending = 1
		victory_healed = 0
	elif node.kind == "rest":
		pass
	elif node.kind == "event":
		events.open(id,route.map_seed)
	else:
		battle_index = int(node.battle)
		battles_entered += 1
		start_battle()
	return true

func complete_rest() -> Dictionary:
	if not run_active or hp <= 0 or route.active.is_empty() or route.NODES[route.active].kind != "rest": return {}
	var before := hp
	hp = mini(max_hp,hp+ceili(float(max_hp)*0.2))
	route.complete()
	return {"healed":hp-before}

func event_active() -> bool:
	return run_active and hp > 0 and not route.active.is_empty() and route.NODES[route.active].kind == "event" and not events.current.is_empty() and str(events.current.node) == route.active

func event_relic() -> String:
	var pool: Array[String] = []
	for item in REWARDS+Catalog.EXTRA:
		if not rewards.has(str(item.id)): pool.append(str(item.id))
	return "" if pool.is_empty() else pool[rng.randi_range(0,pool.size()-1)]

func event_action(action: String) -> bool:
	if not event_active() or events.current.stage != "choice": return false
	var event := events.current
	var id := str(event.id)
	if action == "leave" and id != "ambush":
		event.action = action
		event.stage = "result"
		event.result = "你安全离开，没有支付代价。"
		return true
	if id == "ambush" and action == "fight":
		event.action = action
		event.stage = "battle"
		battle_index = 0
		battles_entered += 1
		start_battle()
		return true
	if id == "chest" and action == "open":
		if hp <= 10: return false
		var relic := event_relic()
		if relic.is_empty(): return false
		event.action = action
		event.cost = 10
		hp -= 10
		take_reward(relic)
		event.reward = relic
		event.stage = "result"
		event.result = "支付10生命，获得「"+reward_name(relic)+"」。"
		return true
	if id == "scribe" and action == "trade":
		if hp <= 6: return false
		var item: Dictionary = Catalog.SUPPLIES[rng.randi_range(0,Catalog.SUPPLIES.size()-1)]
		event.action = action
		event.cost = 6
		hp -= 6
		take_reward(str(item.id))
		event.reward = str(item.id)
		event.stage = "result"
		event.result = "支付6生命，获得「"+str(item.name)+"」。"
		return true
	if action == "review" and id in ["pages","scribe","dictionary"]:
		event.action = action
		var session := Review.new()
		session.build(WordBank,SaveData,wrong_words,3 if id == "dictionary" else 2)
		event.questions = session.questions
		event.stage = "questions"
		return true
	return false

func resolve_event_answer(option: int, ticket: int) -> Dictionary:
	if not event_active() or events.current.stage != "questions" or ticket != int(events.current.index) or option < 0 or option >= 4: return {}
	var event := events.current
	if ticket >= event.questions.size(): return {}
	var question: Dictionary = event.questions[ticket]
	var word := str(question.entry.word)
	var correct := option == int(question.correct_index)
	if not starting_mastery.has(word): starting_mastery[word] = SaveData.mastery_of(word)
	seen_words[word] = true
	SaveData.record_answer(word,correct)
	event_answers += 1
	if correct:
		correct_count += 1
		event.correct += 1
	else:
		wrong_count += 1
		event.wrong += 1
		wrong_words[word] = int(wrong_words.get(word,0))+1
	event.index += 1
	var healed := 0
	if int(event.index) == event.questions.size():
		var before := hp
		match str(event.id):
			"pages":
				if int(event.wrong) == 0: hp = mini(max_hp,hp+10)
			"scribe": hp = mini(max_hp,hp+int(event.correct)*3)
			"dictionary":
				if int(event.wrong) == 0:
					var relic := event_relic()
					if not relic.is_empty():
						take_reward(relic)
						event.reward = relic
					else: hp = mini(max_hp,hp+6)
				else: hp = mini(max_hp,hp+int(event.correct)*2)
		healed = hp-before
		event.stage = "result"
		event.result = "答对 %d/%d · 恢复%d生命" % [int(event.correct),event.questions.size(),healed]
		if not str(event.reward).is_empty(): event.result += "\n获得「"+reward_name(str(event.reward))+"」。"
	SaveData.save_game()
	return {"correct":correct,"complete":event.stage == "result","healed":healed}

func complete_event() -> bool:
	if not event_active() or events.current.stage != "result": return false
	events.current.stage = "done"
	return route.complete()

func prepare_intent() -> Dictionary:
	if not intent_consumed and not enemy_intent.is_empty(): return enemy_intent
	if not classic_fixture and momentum.ready():
		enemy_intent = Brain.ATTACKS[momentum.ultimate].duplicate()
		enemy_intent.id = momentum.ultimate
		enemy_intent.uninterruptible = true
		enemy_brain.previous = momentum.ultimate
		enemy_intent.make_read_only()
	else:
		enemy_intent = enemy_brain.choose(str(current_enemy().kind),boss_phase_two,rng,str(current_enemy().get("id","")))
	intent_consumed = false
	return enemy_intent

func incoming_preview(spell: String = "", correct: bool = false) -> Dictionary:
	if spell.is_empty(): spell = selected_spell
	var intent: Dictionary = enemy_intent if not enemy_intent.is_empty() else Brain.ATTACKS["ink_bolt"]
	var typed := ceili(float(current_enemy().atk)*(0.6 if correct else float(intent.multiplier)))
	var marked := 3 if ink_active and not correct else 0
	var raw := typed+marked
	var reduced := ceili(float(raw)*0.7) if spell == "aegis" else raw
	var immune := not correct and rewards.has("shield") and shield_available
	var absorbed := 0 if immune else mini(barrier,reduced)
	return {"typed":typed,"ink_bonus":marked,"raw":raw,"reduced":reduced,"immune":immune,"absorbed":absorbed,"hp_damage":0 if immune else maxi(0,reduced-absorbed)}

func _apply_incoming(intent: Dictionary, spell: String, correct: bool, preview: Dictionary) -> Dictionary:
	var result := {"intent":intent,"damage":0,"shielded":false,"barrier_absorbed":0,"reflected":0,"ink_applied":false,"mana_sealed":0,"scholar_blocked":false}
	if not correct and rewards.has("shield") and shield_available:
		shield_available = false
		result.shielded = true
		result.scholar_blocked = true
		return result
	var damage := int(preview.reduced)
	var absorbed := mini(barrier,damage)
	barrier -= absorbed
	damage -= absorbed
	result.barrier_absorbed = absorbed
	result.shielded = damage == 0 and absorbed > 0
	hp = maxi(0,hp-damage)
	result.damage = damage
	if damage > 0 and not correct:
		if intent.effect == "ink":
			ink_active = true
			result.ink_applied = true
		elif intent.effect == "seal":
			var before_mana := mana
			mana = maxi(0,mana-1)
			result.mana_sealed = before_mana-mana
	if absorbed > 0 and hp > 0 and rewards.has("thorns"):
		enemy_hp = maxi(0,enemy_hp-4)
		result.reflected = 4
	return result

func resolve_review(option: int, ticket: int) -> Dictionary:
	if not run_active or hp <= 0 or route.active.is_empty() or route.NODES[route.active].kind != "memory" or ticket != review.index or ticket >= review.questions.size() or option < 0 or option >= 4: return {}
	var question: Dictionary = review.questions[ticket]
	var word := str(question.entry.word)
	var correct := option == int(question.correct_index)
	var old_mastery := SaveData.mastery_of(word)
	if not starting_mastery.has(word): starting_mastery[word] = old_mastery
	seen_words[word] = true
	SaveData.record_answer(word,correct)
	review_answers += 1
	var before := hp
	if correct:
		correct_count += 1
		hp = mini(max_hp,hp+review_healing())
	else:
		wrong_count += 1
		wrong_words[word] = int(wrong_words.get(word,0))+1
	review.index += 1
	SaveData.save_game()
	return {"correct":correct,"healed":hp-before,"complete":review.index == review.questions.size()}

func complete_review() -> bool:
	if route.active.is_empty() or route.NODES[route.active].kind != "memory" or review.index != review.questions.size() or not run_active: return false
	return route.complete()

func claim_reward(id: String) -> bool:
	if rewards_pending <= 0 or not run_active or hp <= 0 or not battle_finished or route.active.is_empty(): return false
	if not offered_rewards.has(id): return false
	if not take_reward(id): return false
	reward_claims += 1
	offered_rewards.clear()
	rewards_pending -= 1
	if rewards_pending == 0:
		if route.NODES[route.active].kind == "event" and not events.current.is_empty():
			events.current.stage = "done"
			events.current.result = "伏击战胜利，已领取一次常规强化。"
		route.complete()
	return true

func resolve_answer(word: String, correct: bool, spell: String = "") -> Dictionary:
	if not run_active or hp <= 0 or enemy_hp <= 0:
		return {}
	if spell.is_empty(): spell = selected_spell
	if not can_cast(spell): return {}
	prepare_intent()
	var intent := enemy_intent
	var incoming := incoming_preview(spell)
	intent_consumed = true
	combat_answers += 1
	var cost := int(SPELLS[spell]["cost"])
	var missed_before := wrong_words.has(word)
	mana -= cost
	var old_mastery := SaveData.mastery_of(word)
	if not starting_mastery.has(word):
		starting_mastery[word] = old_mastery
	seen_words[word] = true
	SaveData.record_answer(word, correct)
	var result := {"correct":correct,"damage":0,"healed":0,"shielded":false,"old_mastery":old_mastery,"spell":spell,"mana_cost":cost,"normal_damage":0,"barrier_gained":0,"barrier_absorbed":0,"memory_bonus":0,"scholar_blocked":false,"intent":intent,"ink_bonus":int(incoming.ink_bonus),"raw_incoming":int(incoming.raw),"reduced_incoming":int(incoming.reduced),"ink_applied":false,"mana_sealed":0,"phase_changed":false,"reflected":0,"counter":{},"hp_before_counter":hp,"enemy_before_counter":enemy_hp,"barrier_before_counter":barrier}
	# An existing mark is consumed by precisely this question, right or wrong.
	ink_active = false
	if correct:
		correct_count += 1
		combo += 1
		best_combo = maxi(best_combo, combo)
		SaveData.highest_combo = maxi(SaveData.highest_combo, best_combo)
		var damage := 10 if combo <= 2 else (12 if combo <= 4 else 15)
		damage += base_attack - 10
		if rewards.has("tome") and old_mastery < 30:
			damage += 5
		if rewards.has("focus") and combo >= 3: damage += 2
		if opening_available:
			damage += (6 if rewards.has("opening") else 0)+opening_bonus
			opening_available = false
		if rewards.has("flame") and combo >= 5:
			damage = ceili(float(damage) * 1.3)
		# V1 normal damage, including all relics and Combo, is calculated once.
		result["normal_damage"] = damage
		match spell:
			"arcane":
				mana = mini(max_mana,mana+1)
				if rewards.has("echo"): damage += 3
			"aegis":
				# Playtest adjustment: retain full normal damage and grant barrier.
				var previous_barrier := barrier
				barrier = mini(barrier_cap(),barrier+(10 if rewards.has("aegis_edge") else 8))
				result["barrier_gained"] = barrier-previous_barrier
			"memory":
				damage = ceili(float(damage)*1.8)
				if missed_before:
					var extra := 10 if rewards.has("resonance") else 5
					damage += extra
					result["memory_bonus"] = extra
		enemy_hp = maxi(0, enemy_hp - damage)
		result["damage"] = damage
		if rewards.has("renewal") and combo >= 5 and renewal_available:
			renewal_available = false
			var before := hp
			hp = mini(max_hp,hp+8)
			result["healed"] += hp-before
		if rewards.has("crystal"):
			var milestone := floori(float(combo) / 3.0)
			if milestone > current_crystal_milestone:
				current_crystal_milestone = milestone
				var before := hp
				hp = mini(max_hp, hp + 3)
				result["healed"] += hp - before
		if bool(intent.get("uninterruptible",false)) and enemy_hp > 0:
			result.hp_before_counter = hp
			result.enemy_before_counter = enemy_hp
			result.barrier_before_counter = barrier
			result.counter = _apply_incoming(intent,spell,true,incoming_preview(spell,true))
	else:
		wrong_count += 1
		wrong_words[word] = int(wrong_words.get(word, 0)) + 1
		combo = 0
		current_crystal_milestone = 0
		result.merge(_apply_incoming(intent,spell,false,incoming),true)
	if not classic_fixture: momentum.finish(intent,correct)
	if battle_index == 3 and hp > 0 and enemy_hp > 0 and enemy_hp <= float(current_enemy().hp)*0.5 and not boss_phase_two:
		boss_phase_two = true
		phase_transitions += 1
		result["phase_changed"] = true
	if hp <= 0:
		run_active = false
	if enemy_hp <= 0:
		run_won = battle_index == 3
		if run_won:
			run_active = false
	SaveData.save_game()
	return result

func finish_battle() -> void:
	if battle_finished: return
	battle_finished = true
	var before := hp
	if rewards.has("quill"):
		hp = mini(max_hp, hp + 10)
	if route.extended and hp > 0: hp = mini(max_hp,hp+(8 if current_enemy().kind == "elite" else 5))
	victory_healed = hp-before
	if not route.active.is_empty() and enemy_hp <= 0:
		if battle_index == 3:
			route.complete()
		else:
			reward_batch = 2 if current_enemy().kind == "elite" else 1
			rewards_pending = reward_batch

func reward_choices() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var source: Array = REWARDS+Catalog.EXTRA if route.extended else REWARDS
	for item in source:
		if not rewards.has(str(item["id"])):
			pool.append(item)
	pool.shuffle()
	var offered: Array[Dictionary] = pool.slice(0, mini(3, pool.size()))
	if route.extended:
		var supplies: Array = Catalog.SUPPLIES.duplicate()
		supplies.shuffle()
		# Keep at least two permanent choices when possible; one slot may be a supply.
		if offered.size() == 3 and rng.randf() < 0.35: offered[2] = supplies.pop_back()
		while offered.size() < 3: offered.append(supplies.pop_back())
	offered_rewards.clear()
	for item in offered: offered_rewards.append(str(item.id))
	return offered

func take_reward(id: String) -> bool:
	var item := Catalog.find(id,REWARDS)
	if item.is_empty(): return false
	var repeatable := bool(item.get("repeatable",false))
	if rewards.has(id) and not repeatable:
		return false
	if not repeatable: rewards.append(id)
	match id:
		"blade": base_attack += 3
		"quill": hp = mini(max_hp, hp + 10)
		"lifebond":
			max_hp += 15
			hp = mini(max_hp,hp+15)
		"mana_ring": max_mana += 1
		"recover": hp = mini(max_hp,hp+20)
		"ward": next_barrier_bonus = mini(barrier_cap(),next_barrier_bonus+8)
		"insight": next_opening_bonus = mini(16,next_opening_bonus+8)
	return true

func advance_battle() -> void:
	battle_index += 1
	start_battle()

func accuracy() -> int:
	var total := correct_count + wrong_count
	return roundi(100.0 * float(correct_count) / float(total)) if total > 0 else 0

func questions_answered() -> int:
	return correct_count + wrong_count

func report_stats() -> Dictionary:
	return {"questions_answered": questions_answered(), "unique_words": seen_words.size(), "correct": correct_count, "wrong": wrong_count, "accuracy": accuracy(), "best_combo": best_combo,"difficulty":Difficulty.get_mode(difficulty_id).name,"word_pool":"原版120词" if classic_fixture else Difficulty.get_mode(difficulty_id).pool,"pool_size":WordBank.entries.size(),"event_answers":event_answers}

func improved_words() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for word in starting_mastery:
		var before := int(starting_mastery[word])
		var after := SaveData.mastery_of(str(word))
		if after > before:
			result.append({"word": word, "before": before, "after": after})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (int(a["after"]) - int(a["before"])) > (int(b["after"]) - int(b["before"])))
	return result.slice(0, mini(5, result.size()))

func weak_words() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for word in seen_words:
		result.append({"word": word, "mastery": SaveData.mastery_of(str(word))})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["mastery"]) < int(b["mastery"]))
	return result.slice(0, mini(5, result.size()))
