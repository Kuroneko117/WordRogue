extends SceneTree

# One actual engine run for store footage; normal stats and damage, isolated save.
var ui: Control
var state: Node
var events: Array[Dictionary] = []
var out := "D:/项目/1/.local_test/taptap_submission_capture"

func _initialize() -> void:
	call_deferred("record_demo")
	create_timer(50,true,false,true).timeout.connect(func() -> void: push_error("Store recording timeout"); quit(2))

func wait(seconds: float) -> void:
	await create_timer(seconds,false).timeout

func record_demo() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not ".local_test" in OS.get_user_data_dir(): quit(3); return
	state = root.get_node("GameState")
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await wait(0.2)
	ui._begin_run("normal")
	ui._enter_node("first")
	await wait(0.5)
	for instruction in [["arcane",true],["arcane",false],["aegis",true],["arcane",true],["memory",true]]:
		if ui.screen != "battle" or not ui.accepting_answer: break
		var spell: String = instruction[0]
		if not state.can_cast(spell): spell = "arcane"
		ui._select_spell(spell)
		await wait(2.0)
		var correct := int(ui.current_question.correct_index)
		var index := correct if instruction[1] else (correct+1)%4
		events.append({"word":str(ui.current_question.entry.word),"spell":spell,"correct":bool(instruction[1]),"enemy_before":state.enemy_hp,"player_before":state.hp,"mana_before":state.mana})
		await ui._on_answer(index)
		await wait(0.6)
	if ui.screen == "reward":
		await wait(2.0)
		var choices: Array = state.reward_choices()
		if not choices.is_empty(): await ui._choose_reward(str(choices[0].id))
		await wait(3.0)
	else: await wait(2.0)
	FileAccess.open(out+"/recording.json",FileAccess.WRITE).store_string(JSON.stringify({"source":"Actual Godot V1.9 staged build; scripted input, not manual playthrough","changed_combat_stats":false,"profile":OS.get_user_data_dir(),"events":events},"  "))
	root.get_node("AudioBus").stop_all()
	quit()
