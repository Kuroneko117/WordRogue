extends SceneTree

const Route = preload("res://scripts/route_state.gd")
var state: Node
var save: Node
var audio: Node
var failures: Array[String] = []
var campaigns := 0
var answer_counts: Array[int] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("V15 MODEL FAIL: "+message)

func fresh() -> void:
	state.start_run(true)
	state.enemy_hp = 1000

func bolt() -> void:
	var intent: Dictionary = state.Brain.ATTACKS.ink_bolt.duplicate()
	intent.id = "ink_bolt"
	state.enemy_intent = intent
	state.intent_consumed = false

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	state = root.get_node("GameState")
	save = root.get_node("SaveData")
	audio = root.get_node("AudioBus")
	save.words.clear()
	var signatures := {}
	for seed_value in 100:
		var map := Route.new()
		map.reset(true,seed_value,false)
		var twin := Route.new()
		twin.reset(true,seed_value,false)
		check(map.NODES == twin.NODES,"Map seed reproducible")
		check(map.NODES.size() == 34 and map.depth == 12,"Twelve layers and 34 nodes")
		var reached := {"entry":true}
		for layer in range(0,13):
			for id in map.NODES:
				if int(map.NODES[id].layer) != layer: continue
				check(reached.has(id),"No unreachable nodes")
				check(not map.NODES[id].next.is_empty(),"No dead-end before report")
				for next in map.NODES[id].next:
					check(map.NODES.has(next) and int(map.NODES[next].layer) == layer+1,"Edges advance one layer")
					reached[next] = true
			signatures[JSON.stringify(map.NODES)] = true
	check(signatures.size() > 90,"Map types and paths vary across runs")
	var ids := {}
	for item in state.REWARDS+state.Catalog.EXTRA+state.Catalog.SUPPLIES:
		check(not ids.has(item.id),"Reward identifiers unique")
		ids[item.id] = true
	check(ids.size() == 21,"18 relics plus 3 supplies")
	fresh()
	state.take_reward("mana_ring")
	state.take_reward("spring")
	state.take_reward("bulwark")
	state.start_battle()
	check(state.max_mana == 4 and state.mana == 2 and state.barrier == 6,"Mana and starting shield build")
	state.resolve_answer("maintain",true,"memory")
	check(state.mana == 0,"Immediate opening Memory affordable")
	fresh()
	state.take_reward("echo")
	check(state.resolve_answer("maintain",true,"arcane").damage == 13,"Arcane-only bonus")
	state.enemy_hp = 1000
	state.mana = 1
	check(state.resolve_answer("maintain",true,"aegis").damage == 10,"Aegis retains normal damage without Arcane-only bonus")
	fresh()
	state.take_reward("aegis_edge")
	state.mana = 3
	state.resolve_answer("maintain",true,"aegis")
	state.resolve_answer("maintain",true,"aegis")
	check(state.barrier == 20 and state.barrier_cap() == 20,"Upgraded shield gain and cap")
	fresh()
	state.take_reward("thorns")
	state.barrier = 8
	bolt()
	var result: Dictionary = state.resolve_answer("maintain",false)
	check(state.hp == 98 and state.barrier == 0 and state.enemy_hp == 996 and result.reflected == 4,"Barrier reflection once")
	state.enemy_hp = 2
	state.barrier = 16
	bolt()
	state.resolve_answer("maintain",false)
	check(state.enemy_hp == 0 and state.hp == 98,"Reflection can safely win combat")
	fresh()
	state.take_reward("thorns")
	state.hp = 1
	state.barrier = 2
	bolt()
	state.resolve_answer("maintain",false)
	check(state.hp == 0 and state.enemy_hp == 1000,"No reflection after death")
	fresh()
	state.resolve_answer("maintain",false)
	state.take_reward("resonance")
	state.mana = 2
	result = state.resolve_answer("maintain",true,"memory")
	check(result.damage == 28 and result.memory_bonus == 10,"True run mistake resonance")
	fresh()
	state.take_reward("blade")
	state.take_reward("tome")
	state.take_reward("focus")
	state.take_reward("opening")
	state.take_reward("flame")
	state.take_reward("resonance")
	state.combo = 4
	state.mana = 3
	state.wrong_words["maintain"] = 1
	save.words["maintain"] = {"mastery":20,"correct_count":0,"wrong_count":1,"encounter_count":1}
	result = state.resolve_answer("maintain",true,"memory")
	check(result.normal_damage == 41 and result.damage == 84,"All damage bonuses once before Memory multiplier and resonance")
	fresh()
	state.take_reward("opening")
	bolt()
	state.resolve_answer("maintain",false)
	check(state.resolve_answer("maintain",true).damage == 16,"Mistake does not consume first-correct bonus")
	check(state.resolve_answer("maintain",true).damage == 10,"Opening bonus one use per combat")
	fresh()
	state.take_reward("renewal")
	state.take_reward("crystal")
	state.hp = 60
	state.combo = 4
	result = state.resolve_answer("maintain",true)
	check(state.hp == 71 and result.healed == 11,"Renewal and Crystal healing accumulated correctly")
	state.enemy_hp = 1000
	state.combo = 4
	state.resolve_answer("maintain",true)
	check(state.hp == 71,"Renewal cannot repeat within a battle")
	fresh()
	state.hp = 70
	check(state.take_reward("lifebond") and not state.take_reward("lifebond"),"Permanent relic not duplicated")
	check(state.max_hp == 115 and state.hp == 85,"Max HP and immediate healing")
	state.take_reward("recover")
	state.take_reward("recover")
	check(state.hp == 115,"Supply repeatable and healing capped")
	state.take_reward("ward")
	state.take_reward("insight")
	state.start_battle()
	check(state.barrier == 8 and state.next_barrier_bonus == 0,"One-shot shield consumed at next battle")
	check(state.resolve_answer("maintain",true).damage == 18,"Next battle first-hit supply")
	state.start_battle()
	check(state.barrier == 0 and state.opening_bonus == 0,"Supplies do not recur")
	state.start_run(false,"normal",true)
	check(state.max_hp == 100 and state.max_mana == 3 and state.rewards.is_empty(),"Restart clears build attributes")
	fresh()
	state.take_reward("restoration")
	state.route.current = "first" # Deterministic learning-room fixture.
	state.enter_node("memory")
	state.hp = 80
	var prior_total: int = save.total_answers
	var prior_mana: int = state.mana
	var question: Dictionary = state.review.questions[0]
	state.resolve_review(int(question.correct_index),0)
	check(state.hp == 87 and state.combo == 0 and state.mana == prior_mana and save.total_answers == prior_total+1,"Restoration changes healing only, not learning/combat resources")
	for policy in 8:
		state.start_run(false,"normal",true)
		state.route.reset(true,policy+100,false)
		while state.run_active:
			var available: Array = state.route.NODES[state.route.current].next
			var id := str(available[policy%available.size()])
			var kind := str(state.route.NODES[id].kind)
			check(state.enter_node(id) and not state.enter_node(id),"Only one connected node entered")
			if kind == "memory":
				var before: int = state.questions_answered()
				for i in 3: state.resolve_review(int(state.review.questions[i].correct_index),i)
				check(state.questions_answered() == before+3,"Memory still counts once")
				check(state.complete_review(),"Generated memory node completes")
			elif kind == "rest":
				var before: int = state.questions_answered()
				state.hp = 80
				var expected_heal: int = mini(state.max_hp-80,ceili(float(state.max_hp)*0.2))
				check(state.complete_rest().healed == expected_heal and state.complete_rest().is_empty(),"Rest once, capped healing")
				check(state.questions_answered() == before,"Rest does not generate learning record")
			else:
				if kind != "treasure":
					var guard := 0
					while state.enemy_hp > 0 and guard < 60:
						guard += 1
						state.resolve_answer("maintain",true,"arcane")
					check(state.enemy_hp == 0,"Scaled encounter winnable")
					state.finish_battle()
				while state.rewards_pending > 0:
					var choices: Array = state.reward_choices()
					check(choices.size() == 3,"Always three choices")
					var unique := {}
					for item in choices: unique[item.id] = true
					check(unique.size() == 3,"Three distinct choices")
					var before: int = state.reward_claims
					check(state.claim_reward(str(choices[0].id)) and state.reward_claims == before+1,"Legal claim consumed once")
					check(not state.claim_reward(str(choices[0].id)),"Same offered hand cannot be claimed twice")
			check(not state.enter_node(id),"Completed node cannot repeat")
		check(state.run_won and state.route.current == "boss","Expanded campaign reaches report")
		check(state.questions_answered() == state.combat_answers+state.review_answers,"Learning report consistent")
		answer_counts.append(state.questions_answered())
		campaigns += 1
	fresh()
	for item in state.REWARDS+state.Catalog.EXTRA: state.take_reward(str(item.id))
	state.route.extended = true
	check(state.reward_choices().size() == 3,"Exhausted relic pool falls back to three supplies")
	audio.set_volume("music",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")),"Zero music mutes")
	audio.set_volume("music",27)
	audio.set_volume("sfx",61)
	audio.music_percent = 99
	audio.sfx_percent = 99
	audio.load_settings()
	check(audio.music_percent == 27 and audio.sfx_percent == 61,"Settings saved and reloaded separately from learning")
	audio.set_volume("sfx",150)
	check(audio.sfx_percent == 100,"Volume clamped")
	var config := ConfigFile.new()
	config.set_value("audio","music","invalid")
	config.set_value("audio","sfx",-15)
	config.save(audio.SETTINGS_PATH)
	audio.load_settings()
	check(audio.music_percent == 50 and audio.sfx_percent == 0,"Invalid settings values recover safely")
	audio.reset_settings()
	FileAccess.open("res://.local_test/v15/models.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"failures":failures,"maps_checked":100,"campaigns":campaigns,"answer_counts":answer_counts,"relics":18,"supplies":3},"  "))
	print("V15 MODELS: ","PASS" if failures.is_empty() else "FAIL"," | campaigns=",campaigns," | failures=",failures.size()," | answers=",answer_counts)
	quit(0 if failures.is_empty() else 1)
