extends SceneTree

const Enemies = preload("res://scripts/enemy_definitions.gd")
var ui: Control
var state: Node
var bank: Node
var save: Node
var audio: Node
var failures: Array[String] = []
var graphics := false
var video := false
var directory := "res://.local_test/v16"
var completed_modes: Array[String] = []

func _initialize() -> void:
	call_deferred("run")
	create_timer(600,true,false,true).timeout.connect(func() -> void: push_error("V16 UI watchdog: screen="+str(ui.screen)); quit(3))

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error("V16 UI FAIL: "+message)

func wait(seconds: float) -> void: await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	if not graphics or video: return
	await process_frame; await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Actual viewport capture "+name)

func layout() -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(1920,1080))
	if ui.screen == "battle":
		for button in ui.answer_buttons: check(viewport.encloses(button.get_global_rect()),"Answer stays onscreen")
		check(viewport.encloses(ui.battle_view.intent_label.get_global_rect()),"Momentum preview stays onscreen")
		check(viewport.encloses(ui.battle_view.resource_label.get_global_rect()),"Resource bar stays onscreen")
	elif ui.screen == "event":
		for button in ui.event_view.buttons: check(viewport.encloses(button.get_global_rect()),"Event options fit")
	elif ui.screen == "map": check(viewport.encloses(ui.route_view.scroll.get_global_rect()),"Question-map fits viewport")

func answer(correct: bool = true, spell: String = "arcane") -> void:
	check(ui.accepting_answer,"Ready for next battle answer")
	ui._select_spell(spell)
	var index := int(ui.current_question.correct_index)
	if not correct: index = (index+1)%4
	await ui._on_answer(index)

func rewards() -> void:
	while ui.screen == "reward":
		var id := str(ui.reward_cards.keys()[0])
		for preferred in ["quill","shield","blade","crystal","bulwark","flame"]:
			if ui.reward_cards.has(preferred): id = preferred; break
		ui._choose_reward(id); ui._choose_reward(id)
		await wait(0.32)

func win() -> void:
	var guard := 0
	while ui.screen == "battle" and state.hp > 0 and state.enemy_hp > 0 and guard < 90:
		guard += 1
		var spell := "arcane"
		if bool(state.enemy_intent.get("uninterruptible",false)) and state.mana >= 1: spell = "aegis"
		elif state.mana >= 2: spell = "memory"
		await answer(true,spell)
	check(state.hp > 0 and state.enemy_hp == 0,"Actual combat survived")
	await rewards()

func event_answers() -> void:
	while ui.screen == "event" and state.events.current.stage == "questions":
		var event: Dictionary = state.events.current
		var question: Dictionary = event.questions[event.index]
		var total: int = save.total_answers
		ui._on_event_answer(int(question.correct_index)); ui._on_event_answer(int(question.correct_index))
		await wait(0.9)
		check(save.total_answers == total+1,"Event question settles exactly once")

func event_demo(id: String) -> void:
	print("V16 UI event: ",id," FPS=",Engine.get_frames_per_second())
	ui._begin_run("normal")
	var target := ""
	for node in state.route.NODES:
		if state.route.NODES[node].kind == "event": target = str(node); break
	# Isolated branch fixture: same UI/actions as production, no real save changes.
	state.route.current = "first"; state.route.NODES.first.next = [target]
	ui.show_map(); await wait(0.1)
	ui.route_view.nodes[target].pressed.emit()
	state.events.current.id = id
	ui.show_event(); await wait(0.1)
	layout(); await shot("event_"+id)
	if video: await wait(1.0)
	if id in ["pages","scribe","dictionary"]:
		ui._event_action("review")
		await wait(0.08)
		layout(); await shot("event_questions")
		await event_answers()
		check(state.events.current.stage == "result","Event challenge result page")
		await shot("event_result_"+id)
		ui._event_action("complete")
	elif id == "chest":
		ui._event_action("open")
		check(state.events.current.cost == 10 and state.events.current.stage == "result","Chest price and result displayed")
		ui._event_action("complete")
	else:
		ui._event_action("fight")
		await win()
	check(ui.screen == "map","Every event returns to map")

func enemy_demo(id: String) -> void:
	print("V16 UI enemy: ",id," FPS=",Engine.get_frames_per_second())
	ui._begin_run("normal")
	ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[id].duplicate(); state.battle_enemy.id = id
	state.battle_index = 2 if id == "silent_archivist" else 0
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	state.momentum.value = state.momentum.threshold
	state.enemy_intent = {}; state.intent_consumed = true
	ui.show_battle(); await wait(0.1)
	if ResourceLoader.exists("res://assets/enemies/"+id+".png"):
		check(ui.enemy_avatar.uses_texture and ui.enemy_avatar.art.texture.resource_path.ends_with(id+".png"),"Formal enemy portrait")
	else:
		check(not ui.enemy_avatar.uses_texture and ui.enemy_avatar.art.kind == id,"Distinct procedural enemy art")
	layout(); await shot("enemy_"+id)
	if video: await wait(0.8)
	var before: int = state.hp
	var answers_before: int = state.questions_answered()
	var log_before: int = ui.presentation_events.size()
	ui._on_answer(int(ui.current_question.correct_index)); ui._on_answer(int(ui.current_question.correct_index))
	await wait(0.08)
	ui.pause_menu.open_menu()
	var pose: Vector2 = ui.player_avatar.pose.position
	await wait(0.25)
	check(paused and pose == ui.player_avatar.pose.position and state.questions_answered() == answers_before+1,"Pause freezes correct-counter sequence and duplicate answers")
	ui.pause_menu.resume()
	for retry in 100:
		if ui.accepting_answer: break
		await wait(0.05)
	check(state.hp == before-ceili(float(state.current_enemy().atk)*0.6),"Correct ultimate deals60%: "+id)
	check(ui.accepting_answer,"Correct ultimate ends in next question: "+id)
	var events: Array = ui.presentation_events.slice(log_before)
	check(events.size() == 5 and events[1].event == "release" and events[2].event == "impact" and events[3].event == "release" and events[4].event == "impact","Player impact precedes one enemy counter release and impact")
	# Guard next ultimate, then test a scene change during its pending animation.
	state.momentum.value = state.momentum.threshold; state.momentum.cooldown = 0; state.intent_consumed = true; state.enemy_intent = {}; state.mana = 1
	ui._display_question()
	await answer(true,"aegis")
	check(state.hp == before-ceili(float(state.current_enemy().atk)*0.6),"Aegis shield obtained before ultimate")
	state.momentum.value = state.momentum.threshold; state.momentum.cooldown = 0; state.intent_consumed = true; state.enemy_intent = {}
	ui._display_question(); ui._on_answer(int(ui.current_question.correct_index))
	await wait(0.07)
	ui.pause_menu.open_menu(); ui.pause_menu.request_action("title"); ui.pause_menu.confirm_action()
	await wait(1.0)
	check(ui.screen == "title" and not ui.accepting_answer,"Leaving correct-counter animation cancels old callbacks")

func campaign(mode: String) -> void:
	print("V16 UI campaign: ",mode)
	Engine.time_scale = 1.0 if video and mode == "normal" else 16.0
	ui._start_adventure()
	check(ui.screen == "difficulty","Start first opens difficulty screen")
	ui._begin_run(mode)
	state.rng.seed = 401+7000
	state.route.reset(true,401)
	ui.show_map()
	var guard := 0
	while state.run_active and guard < 14:
		guard += 1
		var target := str(state.route.NODES[state.route.current].next[0])
		var kind := str(state.route.NODES[target].kind)
		check(not ui.route_view.nodes[target].disabled,"Legal connected node enabled")
		ui.route_view.nodes[target].pressed.emit()
		await wait(2.0 if kind in ["elite","boss"] else 0.12)
		if kind == "memory":
			for i in 3: await ui._on_review_answer(int(state.review.questions[state.review.index].correct_index))
		elif kind == "rest": ui._rest_and_continue()
		elif kind == "treasure": await rewards()
		elif kind == "event":
			var id := str(state.events.current.id)
			if id == "ambush": ui._event_action("fight"); await win()
			elif id in ["pages","dictionary","scribe"]:
				ui._event_action("review"); await event_answers(); ui._event_action("complete")
			else: ui._event_action("leave"); ui._event_action("complete")
		else: await win()
		if state.run_active: check(ui.screen == "map","Completed node returns map"); await wait(0.1)
	check(ui.screen == "report" and state.run_won and state.route.completed.size() == 13,"Twelve-layer actual UI campaign complete "+mode)
	check(ui.report_snapshot.difficulty == state.Difficulty.get_mode(mode).name and ui.report_snapshot.pool_size == (120 if mode == "easy" else 1500),"Report shows actual difficulty and pool")
	await shot("report_"+mode)
	completed_modes.append(mode)
	Engine.time_scale = 1.0

func correct_counter_defeat() -> void:
	ui._begin_run("normal"); ui._enter_node("first")
	state.hp = 1
	state.momentum.value = state.momentum.threshold
	state.momentum.cooldown = 0
	state.intent_consumed = true; state.enemy_intent = {}
	ui._display_question()
	await ui._on_answer(int(ui.current_question.correct_index))
	check(ui.screen == "report" and state.hp == 0 and ui.report_snapshot.correct == 1 and ui.report_snapshot.wrong == 0,"Correct-counter defeat has accurate learning journal")
	ui._on_answer(0)
	check(state.questions_answered() == 1,"Cannot answer after correct-counter death")
	await shot("correct_counter_defeat")

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	state = root.get_node("GameState"); bank = root.get_node("WordBank"); save = root.get_node("SaveData"); audio = root.get_node("AudioBus")
	graphics = DisplayServer.get_name() != "headless"
	video = OS.get_cmdline_user_args().has("--video")
	if graphics and DisplayServer.window_get_size().x > 1500: directory += "/1920x1080"
	if graphics and DisplayServer.window_get_size().x > 1500: Engine.time_scale = 2.0
	DirAccess.make_dir_recursive_absolute(directory)
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui); await process_frame
	ui._start_adventure(); await wait(0.1); await shot("difficulty_selection")
	ui._begin_run("normal"); await wait(0.12); layout(); await shot("question_mark_map")
	ui._enter_node("first"); await wait(0.12); layout(); await shot("core_1500_battle")
	if video: await wait(1.2)
	for id in ["paper_golem","grimoire_mimic","lantern_wisp","silent_archivist"]: await enemy_demo(id)
	await correct_counter_defeat()
	for id in ["pages","chest","scribe","dictionary","ambush"]: await event_demo(id)
	for mode in ["easy","normal","hard"]: await campaign(mode)
	ui._start_adventure(); check(ui.screen == "difficulty","New run may choose difficulty again")
	ui._begin_run("easy"); check(state.rewards.is_empty() and state.events.records.is_empty() and state.momentum.value == 0,"Restart clears temporary events and build")
	audio.stop_all(); ui.queue_free(); await process_frame; await wait(0.1)
	var output := {"passed":failures.is_empty(),"failures":failures,"graphics":graphics,"video":video,"completed_difficulties":completed_modes,"new_enemies":4,"events":5}
	FileAccess.open(directory+("/video.json" if video else ("/graphics.json" if graphics else "/headless.json")),FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("V16 UI: ","PASS" if failures.is_empty() else "FAIL"," | modes=",completed_modes," | failures=",failures.size()," | graphics=",graphics)
	quit(0 if failures.is_empty() else 1)
