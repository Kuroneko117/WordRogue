extends SceneTree

const Enemies = preload("res://scripts/enemy_definitions.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")
const Kit = preload("res://scripts/ui/ui_kit.gd")
var ui: Control
var state: Node
var audio: Node
var save: Node
var failures: Array[String] = []
var checks := 0
var directory := "res://.local_test/v19/1280x720"
var captured: Array[String] = []
var route_summary: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")
	create_timer(120,true,false,true).timeout.connect(func() -> void: push_error("V19 UI timeout"); quit(3))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error("V19 UI FAIL: "+message)

func wait(seconds: float) -> void: await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	await process_frame; await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Screenshot "+name)
	captured.append(directory+"/"+name+".png")

func visible_controls(node: Node) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and (child is Button or child is Label or child is ProgressBar):
			# Inventory may scroll; skip only contents of native scrolling panels.
			var in_scroll := false
			var ancestor: Node = child.get_parent()
			while ancestor != ui and ancestor != null:
				if ancestor is ScrollContainer: in_scroll = true
				ancestor = ancestor.get_parent()
			if not in_scroll:
				check(Rect2(Vector2.ZERO,ui.size).encloses(child.get_global_rect()),"Control fits viewport: "+str(child.name)+" "+str(child.get_global_rect()))
				if child is Label and not child.text.is_empty(): check(child.size.y+2 >= child.get_minimum_size().y,"Label has enough height: "+child.text)
		visible_controls(child)

func fixture(id: String = "ink_wraith") -> void:
	ui._begin_run("normal"); ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[id].duplicate(); state.battle_enemy.id = id
	state.battle_index = 3 if id == "librarian" else (2 if Enemies.ENEMIES[id].kind == "elite" else 0)
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	state.intent_consumed = true; state.enemy_intent = {}
	ui.show_battle()

func battle_layout(id: String) -> void:
	check(ui.player_avatar.uses_texture and ui.player_avatar.art.texture.resource_path.ends_with("word_mage_v2.png"),"New transparent hero loaded")
	check(ui.enemy_avatar.uses_texture,"Existing approved enemy "+id)
	check(is_equal_approx(ui.player_avatar.art.scale.x,ui.player_avatar.art.scale.y),"Uniform hero aspect")
	check(Rect2(Vector2.ZERO,ui.size).encloses(ui.player_avatar.texture_bounds()),"Hero full body in viewport")
	for control in ui.answer_buttons+ui.battle_view.spell_buttons.values()+[ui.battle_view.spell_card,ui.player_bar,ui.enemy_bar,ui.enemy_hp_label,ui.battle_view.momentum_view]:
		check(not ui.player_avatar.texture_bounds().intersects(control.get_global_rect()),"Hero clear of key UI "+str(control.name))
		check(not ui.enemy_avatar.texture_bounds().intersects(control.get_global_rect()),"Enemy clear of key UI "+str(control.name))
	var origin: Vector2 = ui.player_avatar.spell_origin()
	check(ui.player_avatar.texture_bounds().has_point(origin),"Casting origin belongs to new hero")
	check(origin.x > ui.player_avatar.texture_bounds().get_center().x,"Cast from right hand")

func event_fixture(id: String) -> void:
	ui._begin_run("normal")
	var node := ""
	for candidate in state.route.NODES:
		if state.route.NODES[candidate].kind == "event": node = str(candidate); break
	state.route.current = "first"; state.route.NODES.first.next = [node]
	state.enter_node(node); state.events.current.id = id
	ui.show_event()

func key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new(); event.keycode = code; event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func mouse_click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at; event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event,true)
		await process_frame

func complete_short_run() -> void:
	# Accelerate only this legal UI route. It is not a human timing test.
	Engine.time_scale = 4.0
	save.words.clear()
	ui._begin_run("normal")
	state.route.reset(true,401)
	state.rng.seed = 7401
	ui.show_map()
	var entered := 0
	var phase_count := 0
	while ui.screen != "report" and entered < 8:
		entered += 1
		var paths: Array = state.route.NODES[state.route.current].next
		var next := str(paths[401%paths.size()])
		var kind := str(state.route.NODES[next].kind)
		ui._enter_node(next)
		while ui.screen == "intro": await wait(0.1)
		if ui.screen == "review":
			for i in 3:
				var q: Dictionary = state.review.questions[state.review.index]
				await ui._on_review_answer(int(q.correct_index))
		elif ui.screen == "rest": ui._rest_and_continue()
		elif ui.screen == "event":
			var id := str(state.events.current.id)
			ui._event_action("fight" if id == "ambush" else ("review" if id in ["pages","dictionary","scribe"] else "leave"))
			while ui.screen == "event" and state.events.current.stage == "questions":
				var q: Dictionary = state.events.current.questions[state.events.current.index]
				await ui._on_event_answer(int(q.correct_index))
			if ui.screen == "event": ui._event_action("complete")
		if ui.screen == "battle":
			var answers := 0
			while ui.screen == "battle" and state.hp > 0 and answers < 25:
				answers += 1
				ui._select_spell("aegis" if state.momentum.ready() and state.mana >= 1 else ("memory" if state.mana >= 2 else "arcane"))
				await ui._on_answer(int(ui.current_question.correct_index))
			check(answers < 25,"Native short battle finite "+kind)
			phase_count += state.phase_transitions
		if ui.screen == "reward":
			var batch: int = state.rewards_pending
			check(batch == (2 if kind == "elite" else 1),"Normal/elite/treasure reward batches")
			for claim in batch:
				var id := str(ui.reward_cards.keys()[0])
				var before: int = state.reward_claims
				ui._choose_reward(id); ui._choose_reward(id)
				await wait(0.3)
				check(state.reward_claims == before+1,"Native reward double click once")
	Engine.time_scale = 1.0
	check(ui.screen == "report" and state.run_won and state.route.current == "boss" and entered == 7,"Native seven-floor full UI flow wins")
	check(phase_count > 0,"Native Boss second phase retained")
	check(ui.report_snapshot.questions_answered == state.correct_count+state.wrong_count,"Native final journal stats consistent")
	route_summary = state.report_stats()
	await wait(0.1)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/v19/"+str(resolution.x)+"x"+str(resolution.y)
		await wait(0.08); visible_controls(ui); await shot("report_win")

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test") or DisplayServer.get_name() == "headless": quit(2); return
	state = root.get_node("GameState"); audio = root.get_node("AudioBus"); save = root.get_node("SaveData")
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui)
	await wait(0.1)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/v19/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		ui.show_title(); await wait(0.08); visible_controls(ui); await shot("title")
		ui.show_difficulty(); await wait(0.08); visible_controls(ui); await shot("difficulty")
		ui._begin_run("normal"); await wait(0.08); visible_controls(ui); await shot("map")
		check(ui.route_view.scroll.scroll_vertical == 0,"Seven-floor map fits without scrolling")
		for id in ui.route_view.nodes: check(ui.route_view.canvas.get_rect().encloses(Rect2(ui.route_view.nodes[id].position,ui.route_view.nodes[id].size)),"Map node visible "+str(id))
		fixture(); await wait(0.08); visible_controls(ui); battle_layout("ink_wraith"); await shot("battle_hero_v2")
		state.momentum.value = state.momentum.threshold; state.intent_consumed = true; state.prepare_intent(); ui.battle_view.update_spells(true)
		check(ui.battle_view.momentum_view.alert and ui.battle_view.danger_label.text.contains("不可打断"),"Full momentum warning explains retaliation")
		await shot("battle_ultimate_warning")
		state.enemy_hp = 0; state.finish_battle(); ui.show_reward(); await wait(0.08); visible_controls(ui); await shot("reward")
		event_fixture("chest"); state.hp = 10; ui.show_event(); await wait(0.08); visible_controls(ui); await shot("event_disabled_cost")
		event_fixture("dictionary"); ui._event_action("review"); await wait(0.08); visible_controls(ui); await shot("event_quiz")
		state.review.build(root.get_node("WordBank"),save,state.wrong_words); ui.show_review(); await wait(0.08); visible_controls(ui); await shot("memory")
		ui.show_rest(); await wait(0.08); visible_controls(ui); await shot("rest")
		ui.show_report(); await wait(0.08); visible_controls(ui); await shot("report")
		ui.pause_menu.open_menu(); ui.pause_menu.open_settings(); await wait(0.08); visible_controls(ui.pause_menu.overlay); await shot("settings"); ui.pause_menu.resume()
	# Visual integration of all eight approved enemy assets.
	for id in Enemies.ENEMIES:
		fixture(str(id)); await wait(0.08); battle_layout(str(id)); visible_controls(ui); await shot("enemy_"+str(id))
	# Native keyboard and mouse enter through actual viewport input.
	ui.show_title(); await key(KEY_ENTER); check(ui.screen == "difficulty","Keyboard Enter on focused Start")
	await key(KEY_ENTER); check(ui.screen == "map","Keyboard Enter picks recommended difficulty")
	await wait(0.1); await mouse_click(ui.route_view.nodes.first); check(ui.screen == "battle","Mouse route icon enters battle")
	await key(KEY_W); check(state.selected_spell == "aegis","W selects guard")
	var before: int = save.total_answers
	await key(KEY_1); await key(KEY_1)
	check(save.total_answers == before+1,"Repeated keyboard cannot settle twice")
	await wait(2.0)
	fixture(); await wait(0.08)
	for spell in ["arcane","aegis","memory"]:
		state.enemy_hp = 1000; state.hp = 100; state.mana = 3
		ui._select_spell(spell)
		var answer: int = ui.current_question.correct_index
		before = save.total_answers
		var event_start: int = audio.event_log.size()
		ui._on_answer(answer); ui._on_answer(answer)
		check(save.total_answers == before+1,"Native correct once "+spell)
		await wait(0.25 if spell != "memory" else 0.40); await shot("hero_cast_"+spell)
		await wait(0.95)
		check(ui.accepting_answer,"Animation returns to question "+spell)
		var releases := 0
		var impacts := 0
		var cast_time := 0
		var hit_time := 0
		for event in audio.event_log.slice(event_start):
			if event.event == {"arcane":"player_cast","aegis":"aegis_activate","memory":"memory_burst"}[spell]: releases += 1; cast_time = int(event.time)
			if event.event == ("burst_impact" if spell == "memory" else "projectile_impact"): impacts += 1; hit_time = int(event.time)
		check(releases == 1 and impacts == 1 and hit_time > cast_time,"Cast/impact audio once and ordered "+spell)
	fixture(); await wait(0.08)
	before = save.total_answers
	var wrong := (int(ui.current_question.correct_index)+1)%4
	ui._on_answer(wrong); ui._on_answer(wrong)
	await wait(0.6); await shot("hero_hit")
	check(save.total_answers == before+1 and state.hp < 100,"Native wrong once and player hit")
	ui.pause_menu.open_menu()
	var snapshot := [state.hp,state.enemy_hp,state.questions_answered(),ui.screen_epoch]
	await wait(0.3); ui._on_answer(wrong)
	check(snapshot == [state.hp,state.enemy_hp,state.questions_answered(),ui.screen_epoch],"Pause freezes state and duplicate input")
	ui.pause_menu.open_settings()
	var music_before: float = audio.music_percent; var sfx_before: float = audio.sfx_percent
	ui.pause_menu.sliders.music.value = 0; ui.pause_menu.sliders.sfx.value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Settings independently mute")
	audio.load_settings(); check(audio.music_percent == 0 and audio.sfx_percent == 0,"Settings save")
	ui.pause_menu.sliders.music.value = music_before; ui.pause_menu.sliders.sfx.value = sfx_before
	ui.pause_menu.resume(); await wait(1.1)
	await key(KEY_ESCAPE); check(paused,"Actual ESC opens pause")
	await key(KEY_ESCAPE); check(not paused,"Actual ESC resumes")
	fixture(); await wait(0.08)
	state.hp = 1; ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	await wait(2.05); await shot("hero_death")
	for attempt in 60:
		if ui.screen == "report": break
		await wait(0.05)
	check(ui.screen == "report" and not ui.accepting_answer,"Death stops questions and shows journal")
	ui.return_to_title(); ui._begin_run("normal"); check(ui.screen == "map" and state.rewards.is_empty(),"Return and restart clears transient build")
	# Resource fallback tested without changing any user files.
	var actor: Control = load("res://scripts/ui/actor_view.gd").new(); ui.add_child(actor)
	actor.setup("mage","res://assets/characters/missing_for_test.png",Kit.BLUE)
	check(not actor.uses_texture,"Missing art uses native program fallback"); actor.queue_free()
	check(load("res://scripts/ui/journal_screens.gd").hero_path("res://assets/characters/missing_for_test.png").ends_with("word_mage.png"),"Missing V2 uses approved old hero")
	ui.background_path = "res://assets/backgrounds/missing_for_test.png"; ui.show_title()
	check(ui.active_background_path.is_empty(),"Missing background uses procedural fallback")
	ui.background_path = "res://assets/backgrounds/library_battle.png"
	for key in ["title_map","battle_normal","battle_elite","battle_boss","memory_rest","event_special","optional_victory"]:
		audio.set_scene_music(key); await wait(0.65)
		check(audio.music_player.playing,"V18 scene music retained "+key)
	var starts: int = audio.music_start_count; audio.set_scene_music("optional_victory"); await wait(0.12)
	check(audio.music_start_count == starts,"Same track does not stack/restart")
	audio.play_event("nonexistent_test_event")
	await complete_short_run()
	ui._clear_screen(); await wait(0.1)
	FileAccess.open("res://.local_test/v19/ui.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"screenshots":captured,"native_seven_floor_report":route_summary,"profile":OS.get_user_data_dir()},"  "))
	print("V19 UI: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks," failures=",failures.size())
	audio.stop_all(); await wait(0.15)
	quit(0 if failures.is_empty() else 1)
