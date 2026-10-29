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
	if not ok: failures.append(message); push_error("V19 MODEL FAIL: "+message)

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
		check(map.depth == 7 and map.NODES.size() == 19,"Seven playable floors and separate report")
		var count := 0
		var reachable := {"entry":true}
		for layer in range(9):
			for id in map.NODES:
				var item: Dictionary = map.NODES[id]
				if int(item.layer) != layer: continue
				check(reachable.has(id),"Every node reachable")
				if layer < 6 and not item.next.is_empty():
					var avoid_elite := false
					for next in item.next:
						if map.NODES[next].kind != "elite": avoid_elite = true
					check(avoid_elite,"Elite optional from every predecessor")
				if item.kind == "event": count += 1; check(layer in [3,5,6],"Events only in middle layers")
				for next in item.next: check(int(map.NODES[next].layer) == layer+1,"Edges always forward"); reachable[next] = true
		check(count >= 1 and count <= 2 and map.NODES.first.kind == "normal" and map.NODES.boss.kind == "boss","1-2 events preserve endpoints")
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
		check(int(enemy.hp) == ceili(float(state.ShortBalance.BASE_HP[enemy.id])*float(state.Difficulty.get_mode(mode).hp)) and int(enemy.atk) == ceili(float(base.atk)*float(state.Difficulty.get_mode(mode).atk)),"Difficulty scaling applied once")
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
		if i%300 == 0: print("V19 validated questions: ",i)
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
		check(complete.won and complete.layers_completed == 7,"Each difficulty has a complete normal route")
		simulations.append(complete)
		simulations.append(travel(mode,0.8,402))
	# Coverage uses real map floor numbers and the real ecology/event samplers,
	# without running an unrelated 90-run balance matrix.
	var room_kinds := {}
	var coverage_rng := RandomNumberGenerator.new()
	coverage_rng.seed = 170019
	for seed_value in 100:
		var map := Route.new(); map.reset(true,seed_value)
		for node in map.NODES:
			var item: Dictionary = map.NODES[node]
			room_kinds[str(item.kind)] = true
			if item.kind in ["normal","elite","boss"]:
				var picked := Enemies.pick(int(item.layer),str(item.kind),[],coverage_rng)
				ecological_seen[picked] = true
	check(ecological_seen.size() == 8,"Seven floors still expose all eight enemies")
	check(room_kinds.size() == 9,"All room kinds including entry/report retained")
	check(simulations.size() == 6,"Three perfect completions plus three focused 80% answer runs")
	var battle_lengths := []
	for id in Enemies.ENEMIES:
		fresh("normal",str(id))
		state.battle_index = 3 if id == "librarian" else (2 if Enemies.ENEMIES[id].kind == "elite" else 0)
		state.battle_enemy.hp = state.ShortBalance.BASE_HP[id]
		state.route.NODES.first.layer = 7 if id == "librarian" else (4 if Enemies.ENEMIES[id].kind == "elite" else 6)
		state.enemy_hp = int(state.current_enemy().hp)
		var answers := 0
		while state.enemy_hp > 0 and state.hp > 0 and answers < 20:
			answers += 1
			state.resolve_answer("maintain",true,"arcane")
		battle_lengths.append({"enemy":id,"answers":answers,"hp":state.current_enemy().hp})
		check(state.enemy_hp == 0 and answers <= 8,"Short no-relic arcane fight finishes "+str(id))
	var output := {"passed":failures.is_empty(),"failures":failures,"maps":100,"questions_validated":1500,"profile":OS.get_user_data_dir(),"simulations":simulations,"enemies_encountered":ecological_seen.keys(),"room_kinds":room_kinds.keys(),"battle_lengths":battle_lengths}
	FileAccess.open("res://.local_test/v19/models.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("V19 MODELS: ","PASS" if failures.is_empty() else "FAIL"," | failures=",failures.size()," | simulations=",simulations.size())
	quit(0 if failures.is_empty() else 1)
