extends SceneTree

const Route = preload("res://scripts/route_state.gd")
var ui: Control
var state: Node
var save: Node
var audio: Node
var failures: Array[String] = []
var graphics := false
var video := false
var directory := "res://.local_test/v15"
var visited: Array[String] = []
var chosen: Array[String] = []
var map_seed := 0

func _initialize() -> void:
	call_deferred("_run")
	create_timer(240.0,true,false,true).timeout.connect(func() -> void:
		push_error("V15 UI watchdog: test exceeded time limit")
		quit(3))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("V15 UI FAIL: "+message)

func wait(seconds: float) -> void:
	await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	if not graphics or video: return
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Save real viewport: "+name)

func choose_node(map: RefCounted, seen: Array[String]) -> String:
	var selected := ""
	var best := -1
	for id in map.NODES[map.current].next:
		var kind := str(map.NODES[id].kind)
		var score: int = int({"boss":200,"memory":100,"treasure":95,"rest":90,"elite":85,"normal":50}[kind])
		if seen.has(kind): score = int({"boss":200,"elite":70,"normal":50,"treasure":40,"memory":30,"rest":20}[kind])
		if score > best:
			best = score
			selected = str(id)
	return selected

func select_seed() -> int:
	for value in 100:
		var map := Route.new()
		map.reset(true,value,false)
		var seen: Array[String] = []
		while map.current != "boss":
			var id := choose_node(map,seen)
			seen.append(str(map.NODES[id].kind))
			map.enter(id)
			map.complete()
		if seen.has("memory") and seen.has("rest") and seen.has("treasure") and seen.has("elite"): return value
	return 0

func map_layout() -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(1920,1080))
	check(viewport.encloses(ui.route_view.scroll.get_global_rect()),"Scroll viewport fits screen")
	check(ui.route_view.canvas.size.y > ui.route_view.scroll.size.y*2,"Map genuinely larger than viewport")
	check(ui.route_view.nodes.size() == 34,"All icon nodes built")
	for id in ui.route_view.nodes:
		var button: Button = ui.route_view.nodes[id]
		check(button.text.is_empty(),"Map uses icons rather than rectangular text cards")
		check(Rect2(Vector2.ZERO,ui.route_view.canvas.size).encloses(Rect2(button.position,button.size)),"Icons inside scroll canvas")
		check(button.disabled == (state.route.status(str(id)) != "available"),"Only available connected icons enabled")

func settings_test() -> void:
	var right := int(ui.current_question.correct_index)
	var before: int = state.questions_answered()
	ui._select_spell("aegis")
	ui._on_answer(right)
	await wait(0.07)
	ui.pause_menu.open_menu()
	ui.pause_menu.open_settings()
	var frozen_pose: Vector2 = ui.player_avatar.pose.position
	var music_starts: int = audio.music_start_count
	ui.pause_menu.sliders.music.value = 25
	ui.pause_menu.sliders.sfx.value = 0
	check(audio.music_percent == 25 and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Actual sliders control independent buses and mute")
	ui.pause_menu.sliders.sfx.value = 48
	await wait(0.3)
	check(paused and ui.player_avatar.pose.position == frozen_pose and state.questions_answered() == before+1,"Settings keep combat and duplicate answers paused")
	var viewport := Rect2(Vector2.ZERO,Vector2(1920,1080))
	check(viewport.encloses(ui.pause_menu.panel.get_global_rect()),"Settings panel fits viewport")
	for slider in ui.pause_menu.sliders.values(): check(viewport.encloses(slider.get_global_rect()),"Volume sliders fit viewport")
	await shot("audio_settings")
	audio.music_percent = 99
	audio.sfx_percent = 99
	audio.load_settings()
	check(audio.music_percent == 25 and audio.sfx_percent == 48,"Settings persisted to separate file")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	ui.pause_menu._unhandled_input(escape)
	check(paused and not ui.pause_menu.showing_settings,"ESC settings returns to pause menu")
	ui.pause_menu._unhandled_input(escape)
	await wait(1.3)
	check(not paused and ui.accepting_answer and state.questions_answered() == before+1,"ESC resumes spell exactly once")
	check(audio.music_start_count == music_starts,"Volume changes do not restart BGM")
	audio.reset_settings()

func rewards() -> void:
	while state.rewards_pending > 0:
		check(ui.screen == "reward" and ui.reward_cards.size() == 3,"Three expanded choices visible")
		await shot("rewards_"+str(state.reward_claims))
		var preference := ["mana_ring","spring","aegis_edge","thorns","resonance","echo","lifebond","focus","opening","renewal","blade","quill"]
		var id := str(ui.reward_cards.keys()[0])
		for preferred in preference:
			if ui.reward_cards.has(preferred):
				id = str(preferred)
				break
		var before: int = state.reward_claims
		ui._choose_reward(id)
		ui._choose_reward(id)
		await wait(0.4)
		check(state.reward_claims == before+1,"Relic or supply claimed exactly once")
		chosen.append(id)

func win() -> void:
	var attempts := 0
	while ui.screen == "battle" and state.enemy_hp > 0 and attempts < 60:
		attempts += 1
		ui._select_spell("memory" if state.mana >= 2 else "arcane")
		await ui._on_answer(int(ui.current_question.correct_index))
	check(state.enemy_hp == 0,"Scaled combat won through real spells")

func reflection_transitions() -> void:
	# Targeted HP fixtures for the newly introduced wrong-answer victory path.
	for fatal in [false,true]:
		ui._start_adventure(true)
		await wait(0.05)
		ui._enter_node("first")
		state.take_reward("thorns")
		state.enemy_hp = 4
		state.barrier = 2 if fatal else 8
		state.hp = 1 if fatal else 100
		var intent: Dictionary = state.Brain.ATTACKS.ink_bolt.duplicate()
		intent.id = "ink_bolt"
		state.enemy_intent = intent
		state.intent_consumed = false
		var wrong := (int(ui.current_question.correct_index)+1)%4
		ui._on_answer(wrong)
		ui._on_answer(wrong)
		await wait(3.4)
		check(state.questions_answered() == 1,"Reflection result cannot settle twice")
		if fatal:
			check(state.hp == 0 and state.enemy_hp == 4 and ui.screen == "report","Fatal hit suppresses reflection and reaches failure journal")
		else:
			check(state.hp == 98 and state.enemy_hp == 0 and ui.screen == "reward" and state.rewards_pending == 1,"Wrong-answer reflection victory reaches one reward")
			await rewards()
			check(ui.screen == "map","Reflection victory returns to map")

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	graphics = DisplayServer.get_name() != "headless"
	video = OS.get_cmdline_user_args().has("--video")
	if graphics and DisplayServer.window_get_size().x > 1500: directory += "/1920x1080"
	DirAccess.make_dir_recursive_absolute(directory)
	state = root.get_node("GameState")
	save = root.get_node("SaveData")
	audio = root.get_node("AudioBus")
	audio.reset_settings()
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	check(ui.has_method("_start_adventure"),"Main script compiled")
	ui._begin_run("normal",false,true)
	map_seed = select_seed()
	state.route.reset(true,map_seed,false)
	ui.show_map()
	await wait(0.15)
	map_layout()
	await shot("icon_map_start")
	ui.route_view.scroll.scroll_vertical = 0
	await wait(0.15)
	await shot("icon_map_top")
	ui.route_view.focus_current()
	await wait(0.1)
	while state.run_active:
		var id := choose_node(state.route,visited)
		var kind := str(state.route.NODES[id].kind)
		var layer := int(state.route.NODES[id].layer)
		print("V15 journey: layer=",layer," node=",kind," HP=",state.hp," relics=",state.rewards.size())
		check(not ui.route_view.nodes[id].disabled,"Chosen icon is clickable")
		ui.route_view.nodes[id].pressed.emit()
		await wait(2.1 if kind in ["elite","boss"] else 0.15)
		visited.append(kind)
		if kind == "memory":
			await shot("memory_chamber")
			for i in 3:
				var question: Dictionary = state.review.questions[state.review.index]
				await ui._on_review_answer(int(question.correct_index))
		elif kind == "rest":
			await shot("rest_node")
			ui._rest_and_continue()
		elif kind == "treasure":
			await shot("treasure_node")
			await rewards()
		else:
			check(ui.screen == "battle","Combat opens")
			if layer == 1: await settings_test()
			if layer >= 9: await shot("late_combat")
			await win()
			await rewards()
		if state.run_active:
			check(ui.screen == "map","Node returns to expanded map")
			await wait(0.12)
			map_layout()
			await shot("map_after_"+str(layer))
	check(ui.screen == "report" and state.run_won,"Twelve-layer journey reaches report")
	check(ui.report_snapshot.questions_answered == state.combat_answers+state.review_answers,"Report remains consistent")
	await shot("adventure_report")
	check(visited.has("rest") and visited.has("treasure") and visited.has("memory") and visited.has("elite"),"All new and existing node types exercised")
	if not graphics: await reflection_transitions()
	var totals: int = save.total_answers
	ui._begin_run("normal",false,true)
	await wait(0.1)
	check(state.rewards.is_empty() and state.max_hp == 100 and state.max_mana == 3 and state.route.current == "entry" and save.total_answers == totals,"New run clears build and retains learning")
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("title")
	ui.pause_menu.confirm_action()
	await wait(0.1)
	check(ui.screen == "title","Pause return to title remains safe")
	audio.stop_all()
	ui.queue_free()
	await process_frame
	await wait(0.2)
	var output := {"passed":failures.is_empty(),"failures":failures,"graphics":graphics,"video":video,"map_seed":map_seed,"visited":visited,"selected_rewards":chosen,"layers":12}
	FileAccess.open(directory+("/video.json" if video else ("/graphics.json" if graphics else "/headless.json")),FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("V15 UI: ","PASS" if failures.is_empty() else "FAIL"," | layers=12 | nodes=",visited.size()," | failures=",failures.size()," | graphics=",graphics," | video=",video)
	quit(0 if failures.is_empty() else 1)
