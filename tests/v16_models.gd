extends SceneTree

const Route = preload("res://scripts/route_state.gd")
const Enemies = preload("res://scripts/enemy_definitions.gd")
const Events = preload("res://scripts/event_session.gd")
var state: Node
var bank: Node
var save: Node
var failures: Array[String] = []
var simulations: Array[Dictionary] = []
var ecological_seen: Dictionary = {}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error("V16 MODEL FAIL: "+message)

func fresh(mode: String = "normal", enemy: String = "paper_golem") -> void:
	check(state.start_run(false,mode),"Difficulty bank loaded")
	state.enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[enemy].duplicate()
	state.battle_enemy.id = enemy
	state.momentum.reset(state.battle_enemy)
	state.enemy_hp = 1000
	state.hp = 100
	state.enemy_intent = {}
	state.intent_consumed = true

func event_fixture(id: String) -> void:
	state.start_run()
	var target := ""
	for node in state.route.NODES:
		if state.route.NODES[node].kind == "event": target = str(node); break
	state.route.current = "first"
	state.route.NODES.first.next = [target]
	state.enter_node(target)
	state.events.current.id = id # Branch fixture; production remains seed-based.
	state.hp = 50

func answer_event(all_right: bool) -> void:
	while state.events.current.stage == "questions":
		var ticket: int = state.events.current.index
		var question: Dictionary = state.events.current.questions[ticket]
		var index := int(question.correct_index)
		if not all_right and ticket == 0: index = (index+1)%4
		var total: int = save.total_answers
		check(not state.resolve_event_answer(index,ticket).is_empty(),"Event answer accepted")
		check(state.resolve_event_answer(index,ticket).is_empty() and save.total_answers == total+1,"Event answer cannot repeat")

func travel(mode: String, accuracy: float, seed_value: int) -> Dictionary:
	state.start_run(false,mode)
	state.rng.seed = seed_value+7000
	state.route.reset(true,seed_value)
	var rolls := RandomNumberGenerator.new()
	rolls.seed = seed_value+8000
	var nodes := 0
	while state.run_active and nodes < 14:
		nodes += 1
		var candidates: Array = state.route.NODES[state.route.current].next
		var target := str(candidates[seed_value%candidates.size()])
		var kind := str(state.route.NODES[target].kind)
		check(state.enter_node(target),"Connected travel node enters")
		if kind == "memory":
			for i in 3: state.resolve_review(int(state.review.questions[i].correct_index),i)
			state.complete_review()
		elif kind == "rest": state.complete_rest()
		elif kind == "event":
			var id := str(state.events.current.id)
			if id == "ambush": state.event_action("fight")
			elif id in ["pages","dictionary","scribe"]:
				state.event_action("review")
				answer_event(true)
				state.complete_event()
				continue
			else:
				state.event_action("leave")
				state.complete_event()
				continue
		if kind in ["normal","elite","boss"] or (kind == "event" and state.events.current.stage == "battle"):
			ecological_seen[str(state.current_enemy().id)] = true
			var guard := 0
			while state.run_active and state.enemy_hp > 0 and guard < 100:
				guard += 1
				var intent: Dictionary = state.prepare_intent()
				var spell := "arcane"
				if bool(intent.get("uninterruptible",false)) and state.mana >= 1: spell = "aegis"
				elif state.mana >= 2: spell = "memory"
				state.resolve_answer("maintain",rolls.randf() < accuracy,spell)
			check(guard < 100,"No stuck combat")
			if state.hp == 0: break
			state.finish_battle()
		while state.rewards_pending > 0:
			var choices: Array = state.reward_choices()
			var selected := str(choices[0].id)
			for preferred in ["quill","blade","crystal","shield","bulwark","spring","flame"]:
				for item in choices:
					if item.id == preferred: selected = preferred; break
			state.claim_reward(selected)
	check(state.questions_answered() == state.combat_answers+state.review_answers+state.event_answers,"All learning contexts counted consistently")
	return {"difficulty":mode,"accuracy_target":accuracy,"seed":seed_value,"won":state.run_won and state.hp>0,"hp":state.hp,"answers":state.questions_answered(),"layers_completed":state.route.completed.size()-1,"relics":state.rewards.size()}

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	state = root.get_node("GameState"); bank = root.get_node("WordBank"); save = root.get_node("SaveData")
	for seed_value in 100:
		var map := Route.new(); map.reset(true,seed_value)
		var twin := Route.new(); twin.reset(true,seed_value)
		check(map.NODES == twin.NODES and map.map_seed == twin.map_seed,"Map seed reproducible")
		var count := 0
		var reachable := {"entry":true}
		for layer in range(14):
			for id in map.NODES:
				var item: Dictionary = map.NODES[id]
				if int(item.layer) != layer: continue
				check(reachable.has(id),"Every node reachable")
				if item.kind == "event": count += 1; check(layer in [3,5,7,9],"Events only in middle layers")
				for next in item.next: check(int(map.NODES[next].layer) == layer+1,"Edges always forward"); reachable[next] = true
		check(count >= 2 and count <= 4 and map.NODES.first.kind == "normal" and map.NODES.boss.kind == "boss","2-4 events preserve endpoints")
	var event_types := {}
	for seed_value in 100:
		var event := Events.new()
		var record: Dictionary = event.open("floor_5_1",seed_value)
		event_types[record.id] = true
		record.stage = "result"
		check(event.open("floor_5_1",seed_value+1).stage == "result","Entering again cannot reroll event")
	check(event_types.size() == 5,"Seeds expose all five events")
	for mode in ["easy","normal","hard"]:
		state.start_run(false,mode)
		check(bank.entries.size() == (120 if mode == "easy" else 1500),"Exact pool size")
		state.enter_node("first")
		var enemy: Dictionary = state.current_enemy()
		var base: Dictionary = Enemies.ENEMIES[enemy.id]
		check(int(enemy.hp) == ceili(float(base.hp)*float(state.Difficulty.get_mode(mode).hp)) and int(enemy.atk) == ceili(float(base.atk)*float(state.Difficulty.get_mode(mode).atk)),"Difficulty scaling applied once")
		check(state.current_enemy() == enemy,"Reading enemy cannot rescale or reroll")
	var stored: int = save.mastery_of("maintain")
	state.start_run(false,"easy"); check(save.mastery_of("maintain") == stored,"Difficulty switch preserves Mastery")
	state.start_run(false,"normal")
	for i in bank.entries.size():
		var question: Dictionary = bank.question_for(bank.entries[i])
		check(not question.is_empty() and question.options.size() == 4 and question.options.has(question.entry.meaning),"All 1500 entries produce a valid question")
		var options_set := {}
		for option in question.options: options_set[option] = true
		check(options_set.size() == 4 and int(question.correct_index) >= 0 and int(question.correct_index) < 4 and question.options[question.correct_index] == question.entry.meaning,"Unique options and stable correct index")
		if i%300 == 0: print("V16 validated questions: ",i)
	state.start_run(false,"hard")
	for i in range(0,1500,15): check(not bank.question_for(bank.entries[i]).is_empty(),"Hard non-equivalent choices")
	var enemies_seen := {}
	var history: Array[String] = []
	var rng := RandomNumberGenerator.new(); rng.seed = 45
	for i in 200:
		var id := Enemies.pick(10,"normal",history,rng)
		history.append(id); enemies_seen[id] = true
		if history.size() >= 3: check(not (history[-1] == history[-2] and history[-2] == history[-3]),"No triple repeated normal enemy")
	check(enemies_seen.size() == 5 and Enemies.pool(1,"normal").size() == 3 and Enemies.pool(5,"normal").has("grimoire_mimic"),"Tiered enemy ecology")
	for id in Enemies.ENEMIES:
		if id == "librarian": continue
		fresh("normal",str(id))
		for move in state.enemy_brain.allowed(str(state.current_enemy().kind),str(id)):
			var intent: Dictionary = state.Brain.ATTACKS[move].duplicate()
			intent.id = move
			state.enemy_intent = intent; state.intent_consumed = false; state.hp = 100; state.barrier = 0; state.mana = 2; state.ink_active = false
			var expected := ceili(float(state.current_enemy().atk)*float(intent.multiplier))
			var attack: Dictionary = state.resolve_answer("maintain",false)
			check(attack.damage == expected,"Each monster uses its own legal damage: "+str(move))
			if intent.effect == "seal": check(state.mana == 1,"New seal attacks require real HP damage")
	fresh()
	for i in 3:
		check(not bool(state.prepare_intent().get("uninterruptible",false)),"Threshold attack not immediate")
		state.resolve_answer("maintain",true)
	check(state.momentum.value == 3 and bool(state.prepare_intent().get("uninterruptible",false)),"Next question previews ultimate")
	var total: int = save.total_answers
	var result: Dictionary = state.resolve_answer("maintain",true)
	check(result.counter.damage == 6 and state.hp == 94 and save.total_answers == total+1 and state.combo == 4,"Correct still attacks then takes60%, Mastery once")
	check(not state.ink_active and state.momentum.value == 0 and state.momentum.cooldown == 2,"Ultimate resets and cools down")
	for i in 2:
		check(not bool(state.prepare_intent().get("uninterruptible",false)),"At least two cooldown questions")
		state.resolve_answer("maintain",true)
	fresh(); state.momentum.value = 3; state.mana = 1; state.prepare_intent()
	result = state.resolve_answer("maintain",true,"aegis")
	check(state.hp == 100 and state.barrier == 3 and result.counter.barrier_absorbed == 5,"Aegis grants8 then reduces6 to5 before absorption")
	fresh(); state.momentum.value = 3; state.mana = 2; state.enemy_hp = 10; state.prepare_intent()
	result = state.resolve_answer("maintain",true,"memory")
	check(state.enemy_hp == 0 and state.hp == 100 and result.counter.is_empty(),"Killed enemy cannot counter")
	fresh(); state.momentum.value = 3; state.prepare_intent(); result = state.resolve_answer("maintain",false)
	check(result.damage == 14 and state.hp == 86 and state.momentum.cooldown == 2,"Wrong ultimate uses140%")
	fresh(); state.resolve_answer("maintain",true); state.resolve_answer("maintain",false)
	check(state.momentum.value == 0,"Executed normal attack resets chain")
	fresh("normal","silent_archivist"); state.momentum.value = 3; state.prepare_intent(); state.mana = 2
	result = state.resolve_answer("maintain",true,"arcane")
	check(result.counter.damage == 8 and state.mana == 3 and not state.ink_active,"Correct ultimate no seal rider")
	fresh("normal","silent_archivist"); state.momentum.value = 3; state.prepare_intent(); state.mana = 2
	result = state.resolve_answer("maintain",false)
	check(result.damage == 18 and state.mana == 1 and result.mana_sealed == 1,"Wrong archive ultimate applies legal seal")
	fresh(); state.take_reward("shield"); state.momentum.value = 3; state.prepare_intent(); state.resolve_answer("maintain",true)
	check(state.shield_available and state.hp == 94,"Scholar retains first-wrong rule")
	fresh(); state.momentum.value = 3; state.hp = 1; state.prepare_intent(); state.resolve_answer("maintain",true)
	check(state.hp == 0 and not state.run_active,"Correct retaliation may end adventure safely")
	for id in ["pages","chest","scribe","dictionary","ambush"]:
		event_fixture(id)
		if id in ["pages","scribe","dictionary"]:
			check(state.event_action("review") and not state.event_action("review"),"Quiz event action once")
			answer_event(true)
			check(state.events.current.stage == "result","Quiz event reaches result")
			if id == "pages": check(state.hp == 60,"Pages perfect heal10")
			if id == "scribe": check(state.hp == 56,"Scribe heal3 per correct")
			if id == "dictionary": check(state.rewards.size() == 1,"Dictionary grants legal relic")
			check(state.complete_event() and not state.complete_event(),"Event completes once")
		elif id == "chest":
			state.hp = 10; check(not state.event_action("open"),"Payment cannot be fatal")
			state.hp = 50; check(state.event_action("open") and state.events.current.cost == 10 and state.rewards.size() == 1,"Chest unique relic with price")
			check(not state.event_action("open"),"Chest cannot repeat")
		else:
			check(state.event_action("fight"),"Ambush opens current-layer normal battle")
			while state.enemy_hp > 0 and state.run_active: state.resolve_answer("maintain",true,"aegis" if state.mana>=1 and state.momentum.ready() else "arcane")
			state.finish_battle(); check(state.rewards_pending == 1,"Ambush one reward")
			state.claim_reward(str(state.reward_choices()[0].id)); check(state.route.active.is_empty() and state.events.current.stage == "done","Ambush returns map")
	event_fixture("pages"); state.event_action("review"); answer_event(false); check(state.hp == 50,"Pages imperfect no heal")
	event_fixture("dictionary"); state.event_action("review"); answer_event(false); check(state.hp == 54 and state.rewards.is_empty(),"Dictionary partial recovery only")
	event_fixture("scribe"); check(state.event_action("trade") and state.events.current.cost == 6 and not state.event_action("trade"),"Trade one legal supply, cannot repeat")
	for mode in ["easy","normal","hard"]:
		var complete: Dictionary = travel(mode,1.0,401)
		check(complete.won and complete.layers_completed == 12,"Each difficulty has a complete normal route")
		for accuracy in [0.95,0.80,0.60]:
			for seed_value in 10: simulations.append(travel(mode,accuracy,seed_value+400))
	check(simulations.size() == 90,"90 seeded balance runs")
	check(ecological_seen.size() == 8,"Complete simulations generate all eight enemies")
	var output := {"passed":failures.is_empty(),"failures":failures,"maps":100,"questions_validated":1500,"simulations":simulations,"enemies_encountered":ecological_seen.keys()}
	FileAccess.open("res://.local_test/v16/models.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("V16 MODELS: ","PASS" if failures.is_empty() else "FAIL"," | failures=",failures.size()," | simulations=",simulations.size())
	quit(0 if failures.is_empty() else 1)
