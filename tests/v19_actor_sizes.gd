extends "res://tests/v19_ui.gd"

var measurements: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")
	create_timer(45,true,false,true).timeout.connect(func() -> void: push_error("Actor size check timeout"); quit(3))

func size_check(id: String, condition: String = "idle") -> void:
	visible_controls(ui)
	battle_layout(id)
	var player_rect: Rect2 = ui.player_avatar.texture_bounds()
	var enemy_rect: Rect2 = ui.enemy_avatar.texture_bounds()
	var ratio := enemy_rect.size.y/player_rect.size.y
	check(player_rect.size.y >= 360 and player_rect.size.y <= 480,"Player controlled display height")
	check(enemy_rect.size.y >= 380,"Enemy no longer squeezed to icon size "+id)
	check(ratio >= 0.9,"Enemy/player height ratio "+id+" "+str(ratio))
	check(absf(player_rect.end.y-enemy_rect.end.y) < 20,"Shared stage baseline "+id)
	check(Rect2(Vector2.ZERO,ui.size).encloses(enemy_rect),"Full enemy remains visible")
	for actor in [ui.player_avatar,ui.enemy_avatar]:
		for control in [ui.battle_view.intent_label,ui.battle_view.danger_label,ui.battle_view.resource_label,ui.battle_view.status_label]:
			check(not actor.texture_bounds().intersects(control.get_global_rect()),"Portrait does not cover tactical UI")
		check(is_equal_approx(actor.art.scale.x,actor.art.scale.y),"Uniform aspect ratio")
	measurements.append({"enemy":id,"condition":condition,"resolution":str(DisplayServer.window_get_size()),"player_height_design":player_rect.size.y,"enemy_height_design":enemy_rect.size.y,"ratio":ratio,"player_bottom":player_rect.end.y,"enemy_bottom":enemy_rect.end.y})

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test") or DisplayServer.get_name() == "headless": quit(2); return
	state = root.get_node("GameState"); audio = root.get_node("AudioBus"); save = root.get_node("SaveData")
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui)
	await wait(0.1)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/v19_size_fix/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		for id in Enemies.ENEMIES:
			fixture(str(id)); await wait(0.08)
			# Include the wrapped meaning from the user's screenshot.
			ui.answer_buttons[1].text = "B. n. 独立自主者；无党派者"
			await wait(0.06)
			size_check(str(id)); await shot(str(id))
		for id in ["paper_golem","silent_archivist","librarian"]:
			fixture(id)
			state.momentum.value = state.momentum.threshold
			state.intent_consumed = true; state.prepare_intent()
			state.boss_phase_two = id == "librarian"
			ui._select_spell("aegis")
			await wait(0.1)
			size_check(id,"charged_guard")
			check(ui.battle_view.momentum_view.alert,"Full momentum remains visible")
			await shot(id+"_charged")
	# Exercise only the existing animations affected by the changed actor frame.
	fixture("paper_golem"); await wait(0.1)
	for spell in ["arcane","aegis","memory"]:
		state.enemy_hp = 1000; state.mana = 3
		ui._select_spell(spell)
		await ui._on_answer(int(ui.current_question.correct_index))
		check(ui.accepting_answer and ui.player_avatar.pose.position.is_equal_approx(Vector2.ZERO),"Casting and return to idle "+spell)
		check(ui.player_avatar.texture_bounds().has_point(ui.player_avatar.spell_origin()),"Cast still originates from sprite")
	state.hp = 100; ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	await wait(0.55); await shot("paper_fist_hit")
	await wait(1.8)
	check(ui.accepting_answer and ui.enemy_avatar.pose.position.is_equal_approx(Vector2.ZERO),"Enemy attack/hit returns to stage")
	ui._clear_screen(); audio.stop_all(); await wait(0.15)
	FileAccess.open("res://.local_test/v19_size_fix/result.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"screenshots":captured,"profile":OS.get_user_data_dir()},"  "))
	print("ACTOR SIZE FIX: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
