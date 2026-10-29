extends SceneTree

var failures: Array[String] = []
var state: Node
var save: Node

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("SPELL FAIL: "+message)

func fresh() -> void:
	state.start_run(true)
	state.enemy_hp = 1000
	bolt()

func bolt() -> void:
	var intent: Dictionary = state.Brain.ATTACKS["ink_bolt"].duplicate()
	intent["id"] = "ink_bolt"
	state.enemy_intent = intent
	state.intent_consumed = false

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	state = root.get_node("GameState")
	save = root.get_node("SaveData")
	var original: Script = load("res://backups/v12_before_v13_20261009/scripts/game_state.gd")
	check(state.BATTLES == original.get_script_constant_map()["BATTLES"],"Enemy names and combat values preserved")
	check(state.REWARDS == original.get_script_constant_map()["REWARDS"],"Six relic definitions preserved")
	fresh()
	check(state.mana==1 and state.barrier==0 and not state.can_cast("memory"),"Battle starts at 1 mana and no barrier")
	var before: int = save.total_answers
	state.select_spell("aegis")
	state.select_spell("arcane")
	state.select_spell("aegis")
	check(state.mana==1 and save.total_answers==before,"Switching spells costs nothing and does not update learning")
	check(not state.select_spell("memory") and state.selected_spell=="aegis","Insufficient mana cannot select Burst")
	var result: Dictionary = state.resolve_answer("maintain",true,"arcane")
	check(result.damage==10 and state.mana==2,"Arcane normal damage and +1 mana")
	for i in 5: state.resolve_answer("maintain",true,"arcane")
	check(state.mana==3,"Mana capped at 3")
	fresh()
	result = state.resolve_answer("maintain",false,"arcane")
	check(state.mana==1 and state.hp==90 and result.damage==10,"Wrong Arcane gives no mana and normal retaliation")
	fresh()
	result = state.resolve_answer("maintain",true,"aegis")
	check(result.damage==10 and result.normal_damage==10 and state.barrier==8 and state.mana==0,"Aegis retains full final normal damage and gives 8 barrier")
	bolt()
	result = state.resolve_answer("maintain",false,"arcane")
	check(result.barrier_absorbed==8 and result.damage==2 and state.hp==98 and state.barrier==0,"Barrier absorbs first, then HP")
	fresh()
	state.mana=3
	for i in 3: state.resolve_answer("maintain",true,"aegis")
	check(state.barrier==16 and state.mana==0,"Aegis barrier caps at 16")
	before = save.total_answers
	check(state.resolve_answer("maintain",true,"aegis").is_empty() and save.total_answers==before,"Insufficient mana cannot settle or update Mastery")
	fresh()
	result = state.resolve_answer("maintain",false,"aegis")
	check(state.mana==0 and state.barrier==0 and state.hp==93,"Wrong Aegis spends mana, mitigates 30%, gives no barrier")
	fresh()
	state.mana=2
	result = state.resolve_answer("maintain",true,"memory")
	check(result.damage==18 and result.memory_bonus==0 and state.mana==0,"Burst deals 180%, spends 2")
	fresh()
	state.mana=2
	result = state.resolve_answer("maintain",false,"memory")
	check(state.mana==0 and state.enemy_hp==1000 and state.hp==90,"Wrong Burst spends mana, no attack")
	fresh()
	state.resolve_answer("maintain",false,"arcane")
	state.mana=2
	result = state.resolve_answer("maintain",true,"memory")
	check(result.damage==23 and result.memory_bonus==5,"Burst adds 5 only for a previous run mistake")
	fresh()
	save.words["maintain"]={"mastery":20,"correct_count":0,"wrong_count":10,"encounter_count":10}
	state.mana=2
	result=state.resolve_answer("maintain",true,"memory")
	check(result.memory_bonus==0,"Long-term wrong count alone is not a run mistake")
	for spell in ["arcane","aegis","memory"]:
		fresh()
		state.take_reward("blade")
		state.take_reward("flame")
		state.take_reward("tome")
		state.combo=4
		state.mana=3
		save.words["maintain"]["mastery"]=20
		result=state.resolve_answer("maintain",true,str(spell))
		# (15 Combo + 3 Blade + 5 Tome) * 1.3 Flame = ceil(29.9) = 30.
		check(result.normal_damage==30,"Relics applied once before spell: "+str(spell))
		var expected := 54 if spell=="memory" else 30
		check(result.damage==expected,"Spell multiplier after normal final damage: "+str(spell))
	fresh()
	state.take_reward("crystal")
	state.hp=80
	state.mana=3
	for i in 3: state.resolve_answer("maintain",true,"aegis")
	check(state.hp==83 and state.combo==3,"Crystal milestones work with Aegis")
	state.resolve_answer("maintain",true,"arcane")
	check(state.hp==83,"Crystal does not repeat at combo 4")
	fresh()
	state.take_reward("shield")
	state.barrier=8
	result=state.resolve_answer("maintain",false,"aegis")
	check(result.scholar_blocked and state.barrier==8 and state.hp==100,"Scholar Shield protects before consuming barrier")
	bolt()
	result=state.resolve_answer("maintain",false,"arcane")
	check(state.barrier==0 and state.hp==98,"Next mistake consumes barrier normally")
	state.take_reward("quill")
	state.hp=95
	state.finish_battle()
	check(state.hp==100,"Quill healing remains capped")
	state.barrier=16
	state.mana=3
	state.advance_battle()
	check(state.mana==1 and state.barrier==0 and state.shield_available and state.hp==100,"Next battle resets mana/barrier/Scholar while carrying HP")
	fresh()
	state.hp=3
	state.barrier=2
	state.resolve_answer("maintain",false,"arcane")
	before=save.total_answers
	check(state.hp==0 and not state.run_active,"Death after remaining damage")
	check(state.resolve_answer("maintain",true,"arcane").is_empty() and save.total_answers==before,"Dead run cannot settle or gain mana")
	fresh()
	state.enemy_hp=1
	state.resolve_answer("maintain",true,"arcane")
	before=save.total_answers
	check(state.resolve_answer("maintain",true,"arcane").is_empty() and save.total_answers==before,"Dead enemy cannot be hit twice")
	print("SPELL MODEL RESULT: ","PASS" if failures.is_empty() else "FAIL"," | failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
