extends SceneTree

const Brain = preload("res://scripts/enemy_brain.gd")
var failures: Array[String] = []
var state: Node
var save: Node
var samples := {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("V14 MODEL FAIL: "+message)

func force(id: String) -> void:
	var intent: Dictionary = Brain.ATTACKS[id].duplicate()
	intent.id = id
	intent.make_read_only()
	state.enemy_intent = intent
	state.intent_consumed = false

func fresh(stage: int = 0) -> void:
	state.start_run(true)
	state.battle_index = stage
	state.start_battle()
	state.enemy_hp = 1000

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	state = root.get_node("GameState")
	save = root.get_node("SaveData")
	save.words.clear() # Guard above guarantees this is the isolated test profile.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261009
	for kind in ["normal","elite","boss"]:
		var brain := Brain.new()
		var counts := {}
		var previous_strong := false
		for i in 1500:
			var intent: Dictionary = brain.choose(str(kind),false,rng)
			counts[intent.id] = int(counts.get(intent.id,0))+1
			check(not (previous_strong and bool(intent.strong)),"No consecutive heavy intent")
			previous_strong = bool(intent.strong)
		for id in brain.allowed(str(kind)): check(int(counts.get(id,0)) > 100,"Every attack selected: "+str(id))
		samples[str(kind)] = counts
	var phase_counts: Array[int] = []
	for phase in [false,true]:
		var brain := Brain.new()
		rng.seed = 20261009
		var special := 0
		for i in 2000:
			if brain.choose("boss",phase,rng).id in ["judgment","sealed_pages"]: special += 1
		phase_counts.append(special)
	check(phase_counts[1] > phase_counts[0]+300,"Phase II raises Judgment and Sealed Pages frequency")
	for stage in [0,2,3]:
		for id in Brain.new().allowed(str(state.BATTLES[stage].kind)):
			fresh(stage)
			force(str(id))
			var promised: Dictionary = state.enemy_intent
			state.select_spell("aegis")
			state.select_spell("arcane")
			check(state.prepare_intent() == promised,"Selection cannot reroll intent")
			var expected := ceili(float(state.current_enemy().atk)*float(promised.multiplier))
			var result: Dictionary = state.resolve_answer("maintain",false)
			check(result.intent.id == id and result.damage == expected and state.hp == 100-expected,"Announced attack and multiplier: "+str(id))
			fresh(stage)
			force(str(id))
			result = state.resolve_answer("maintain",true)
			check(state.hp == 100 and not state.ink_active and result.mana_sealed == 0,"Correct interrupts "+str(id))
	fresh(2)
	force("ink_mark")
	state.resolve_answer("maintain",false)
	check(state.ink_active and state.hp == 91,"Mark applied after actual HP damage")
	force("paper_slash")
	var result: Dictionary = state.resolve_answer("maintain",false)
	check(result.damage == 15 and result.ink_bonus == 3 and not state.ink_active,"Ink bonus consumed by exactly next wrong answer")
	force("paper_slash")
	check(state.resolve_answer("maintain",false).damage == 12,"Ink does not persist beyond next question")
	fresh(2)
	force("ink_mark")
	state.resolve_answer("maintain",false)
	force("paper_slash")
	state.resolve_answer("maintain",true)
	check(not state.ink_active,"Correct clears ink")
	for immunity in [false,true]:
		fresh(2)
		if immunity: state.take_reward("shield")
		else: state.barrier = 16
		force("ink_mark")
		state.resolve_answer("maintain",false)
		check(state.hp == 100 and not state.ink_active,"Fully absorbed or immune mark cannot attach ink")
	fresh(0)
	force("shadow_lunge")
	result = state.resolve_answer("maintain",false,"aegis")
	check(result.raw_incoming == 13 and result.reduced_incoming == 10 and state.hp == 90 and state.mana == 0 and state.barrier == 0,"Aegis wrong: cost, 30% reduction, no shield gain")
	fresh(2)
	state.ink_active = true
	state.barrier = 4
	force("torn_page")
	result = state.resolve_answer("maintain",false,"aegis")
	check(result.raw_incoming == 21 and result.reduced_incoming == 15 and result.barrier_absorbed == 4 and result.damage == 11,"Multiplier, status, reduction, barrier, HP in order")
	fresh(3)
	state.mana = 1
	force("sealed_pages")
	state.resolve_answer("maintain",false,"aegis")
	check(state.mana == 0,"Seal after spell cost never negative")
	fresh(3)
	state.mana = 2
	state.barrier = 16
	force("sealed_pages")
	state.resolve_answer("maintain",false)
	check(state.mana == 2,"Full shield prevents mana rider")
	fresh(3)
	state.enemy_hp = 60
	state.resolve_answer("maintain",true)
	check(state.enemy_hp == 50 and state.boss_phase_two and state.phase_transitions == 1,"Boss threshold triggers once without healing")
	state.resolve_answer("maintain",true)
	check(state.phase_transitions == 1 and state.current_enemy().atk == 15,"Phase II retains original ATK and one transition")
	fresh()
	state.resolve_answer("maintain",false)
	save.words["abandon"] = {"mastery":0,"correct_count":0,"wrong_count":1,"encounter_count":1}
	state.review.build(root.get_node("WordBank"),save,state.wrong_words)
	var review_words: Array[String] = []
	for q in state.review.questions: review_words.append(str(q.entry.word))
	check(review_words.has("maintain") and review_words.has("abandon"),"Chamber prioritizes true run mistakes and lowest long-term mastery")
	var completed_paths := 0
	for second in ["stacks","memory"]:
		for third in ["elite","upper"]:
			state.start_run(true)
			check(not state.enter_node("boss") and not state.enter_node(second),"Disconnected node locked")
			for id in ["first",second,third,"boss"]:
				check(state.enter_node(str(id)),"Enter connected node: "+str(id))
				check(not state.enter_node(str(id)),"Double node click rejected")
				if id == "memory":
					state.hp = 93
					var before_combo: int = state.combo
					var before_mana: int = state.mana
					var before_combat: int = state.combat_answers
					var unique := {}
					for i in 3:
						var q: Dictionary = state.review.questions[i]
						unique[q.entry.word] = true
						var mastery: int = save.mastery_of(str(q.entry.word))
						var right := int(q.correct_index)
						var answer := right if i != 1 else (right+1)%4
						result = state.resolve_review(answer,i)
						check(save.mastery_of(str(q.entry.word)) == clampi(mastery+(5 if i != 1 else -10),0,100),"Review uses same mastery rule")
						check(state.resolve_review(answer,i).is_empty(),"Review ticket cannot settle twice")
					check(unique.size() == 3 and state.hp == 100,"Three distinct review words and capped healing")
					check(state.combo == before_combo and state.mana == before_mana and state.combat_answers == before_combat and state.review_answers == 3,"Review not counted as combat or resource gain")
					check(state.complete_review() and not state.complete_review(),"Chamber only completed once")
				else:
					var guard := 0
					while state.enemy_hp > 0 and guard < 30:
						guard += 1
						state.resolve_answer("maintain",true)
					check(state.enemy_hp == 0,"Battle can be won")
					state.finish_battle()
					var expected_rewards := 0 if id == "boss" else (2 if id == "elite" else 1)
					check(state.rewards_pending == expected_rewards,"Correct reward batch")
					var before_hp: int = state.hp
					state.finish_battle()
					check(state.hp == before_hp,"Battle completion idempotent")
					for i in expected_rewards:
						var choices: Array = state.reward_choices()
						check(choices.size() == 3,"Three legal distinct relic choices")
						for candidate in state.REWARDS:
							if not state.rewards.has(str(candidate.id)) and not state.offered_rewards.has(str(candidate.id)):
								check(not state.claim_reward(str(candidate.id)),"Unoffered relic cannot bypass three-choice hand")
						var reward_id := str(choices[0].id)
						check(state.claim_reward(reward_id) and not state.claim_reward(reward_id),"Reward cannot be claimed twice")
						if id == "elite" and i == 0: check(not state.route.active.is_empty(),"Elite remains until second reward")
				check(not state.enter_node(str(id)),"Completed node cannot be revisited")
			check(state.run_won and not state.run_active and state.route.current == "boss","Each route finishes at victorious Boss report")
			check(state.questions_answered() == state.combat_answers+state.review_answers,"Report covers combat and review once")
			completed_paths += 1
	state.start_run(true)
	state.enter_node("first")
	state.hp = 1
	force("ink_bolt")
	state.resolve_answer("maintain",false)
	check(not state.enter_node("stacks") and not state.run_active,"Death stops exploration")
	state.start_run(true)
	check(state.route.current == "entry" and state.route.completed == ["entry"] and state.route.skipped.is_empty() and state.rewards.is_empty(),"Restart resets full map and relics")
	var original: Script = load("res://backups/v13_before_v14_20261009_144914/scripts/game_state.gd")
	check(state.BATTLES == original.get_script_constant_map().BATTLES and state.REWARDS == original.get_script_constant_map().REWARDS,"Original stats and six relic definitions untouched")
	FileAccess.open("res://.local_test/v14/models.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"failures":failures,"paths":completed_paths,"attack_samples":samples,"boss_special_samples":phase_counts},"  "))
	print("V14 MODELS: ","PASS" if failures.is_empty() else "FAIL"," | paths=",completed_paths," | failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
