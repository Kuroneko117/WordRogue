extends SceneTree

const Enemies = preload("res://scripts/enemy_definitions.gd")
const Actor = preload("res://scripts/ui/actor_view.gd")
var ui: Control
var state: Node
var audio: Node
var failures: Array[String] = []
var checks := 0
var directory := "res://.local_test/v17_stage2"
var heights: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")
	create_timer(55,true,false,true).timeout.connect(func() -> void: push_error("Stage2 timeout"); quit(3))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error("Stage2 FAIL: "+message)

func wait(seconds: float) -> void: await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	await process_frame; await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Capture "+name)

func fixture(id: String) -> void:
	ui._begin_run("normal"); ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[id].duplicate(); state.battle_enemy.id = id
	state.battle_index = 3 if id == "librarian" else (2 if Enemies.ENEMIES[id].kind == "elite" else 0)
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	state.enemy_intent = {}; state.intent_consumed = true
	ui.show_battle()

func layout(id: String, resolution: Vector2i) -> void:
	var canvas := Rect2(Vector2.ZERO,Vector2(1920,1080))
	var meter: Control = ui.battle_view.momentum_view
	check(ui.enemy_avatar.uses_texture,"Portrait loaded "+id)
	check(ui.enemy_avatar.art.texture.resource_path.ends_with(id+".png"),"Correct portrait "+id)
	check(is_equal_approx(ui.enemy_avatar.art.scale.x,ui.enemy_avatar.art.scale.y),"Uniform portrait scale "+id)
	var art: Rect2 = ui.enemy_avatar.texture_bounds()
	for control in ui.answer_buttons+ui.battle_view.spell_buttons.values()+[ui.battle_view.spell_card,ui.enemy_hp_label,ui.enemy_bar,ui.battle_view.enemy_name,meter]:
		check(canvas.encloses(control.get_global_rect()),"UI stays onscreen "+id)
		check(not art.intersects(control.get_global_rect()),"Portrait clear of UI "+id)
	check(not meter.get_global_rect().intersects(ui.battle_view.enemy_name.get_global_rect()),"Meter clear of name "+id)
	check(not meter.get_global_rect().intersects(ui.enemy_hp_label.get_global_rect()),"Meter clear of HP "+id)
	var pixels := art.size.y*float(resolution.y)/1080.0
	heights.append({"enemy":id,"resolution":str(resolution),"height_px":snappedf(pixels,0.1)})

func cycle(id: String, resolution: Vector2i) -> void:
	fixture(id); await wait(0.3)
	layout(id,resolution)
	var meter: Control = ui.battle_view.momentum_view
	check(meter.visible and meter.displayed_value == 0 and not meter.alert,"Starts empty "+id)
	var threshold: int = state.momentum.threshold
	for n in threshold:
		await ui._on_answer(int(ui.current_question.correct_index))
		check(meter.displayed_value == n+1 and meter.segments.size() == threshold,"Growth matches original controller "+id)
	check(meter.alert and meter.warning_label.text == "不可打断","Full red warning "+id)
	check(bool(state.enemy_intent.get("uninterruptible",false)),"Actual next intent is uninterruptible "+id)
	await shot(id+"_full")
	await ui._on_answer(int(ui.current_question.correct_index))
	check(state.momentum.value == 0 and state.momentum.cooldown == 2,"Original trigger reset "+id)
	check(meter.displayed_value == 0 and not meter.alert and meter.warning_label.text == "冷却2题","Meter reset matches controller "+id)
	check(ui.accepting_answer and is_equal_approx(ui.enemy_avatar.pose.position.x,0),"Attack/hit returns to idle "+id)
	if id == "lantern_wisp": await shot("momentum_reset")

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	if DisplayServer.get_name() == "headless": quit(2); return
	state = root.get_node("GameState"); audio = root.get_node("AudioBus")
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui); await process_frame
	check(ui.screen == "title","Title starts")
	Engine.time_scale = 4.0
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/v17_stage2/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		for id in ["paper_golem","grimoire_mimic","lantern_wisp","silent_archivist","marginalia","librarian"]:
			await cycle(id,resolution)
	# Missing optional files use the same four program-art fallback identities.
	for id in ["paper_golem","grimoire_mimic","lantern_wisp","silent_archivist"]:
		var fallback := Actor.new(); ui.add_child(fallback)
		fallback.setup(str(Enemies.ENEMIES[id].kind),"res://assets/enemies/missing_stage2_"+id+".png",Color.WHITE)
		fallback.art.kind = id
		check(not fallback.uses_texture and fallback.art.kind == id,"Missing PNG fallback "+id)
		fallback.queue_free()
	fixture("paper_golem"); await wait(0.3)
	var initial_position: Vector2 = ui.enemy_avatar.visual.position
	await wait(0.4)
	check(ui.enemy_avatar.visual.position != initial_position,"Formal art idle continues")
	ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	await wait(0.2)
	ui.pause_menu.open_menu(); ui.pause_menu.open_settings()
	var pose: Vector2 = ui.enemy_avatar.pose.position
	var value: int = ui.battle_view.momentum_view.displayed_value
	var count: int = audio.event_log.size()
	await wait(0.6)
	check(paused and ui.enemy_avatar.pose.position == pose and ui.battle_view.momentum_view.displayed_value == value and audio.event_log.size() == count,"Pause freezes art, meter, audio")
	check(ui.pause_menu.sliders.has("music") and ui.pause_menu.sliders.has("sfx"),"ESC independent audio settings remain")
	ui.pause_menu.resume()
	for n in 50:
		if ui.accepting_answer: break
		await wait(0.1)
	check(ui.accepting_answer and audio.music_key == "normal_battle","Resume animation and normal BGM")
	check(ui.active_background_path.ends_with("library_battle.png"),"Original battle background remains")
	# One real portrait death and reward transition; fixture only, not gameplay tuning.
	state.enemy_hp = 1
	await ui._on_answer(int(ui.current_question.correct_index))
	check(ui.screen == "reward","Portrait death reaches reward")
	ui.show_title(); await wait(0.4)
	check(ui.screen == "title" and not ui.accepting_answer,"Screen change cleans combat")
	var file := FileAccess.open("res://.local_test/v17_stage2/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"heights":heights},"\t")); file.close()
	audio.stop_all(); ui.queue_free(); await wait(0.4)
	Engine.time_scale = 1.0
	print("V17 STAGE2: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	quit(0 if failures.is_empty() else 1)
