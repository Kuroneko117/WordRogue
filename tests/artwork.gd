extends SceneTree

var failures: Array[String] = []
var capture := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("ARTWORK FAIL: "+message)

func screenshot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var directory := "res://.local_test/artwork"
	DirAccess.make_dir_recursive_absolute(directory)
	var image := root.get_texture().get_image()
	image.save_png(directory+"/"+name+".png")

func inspect_actor(actor: Control, ui: Control, expected_min: float, expected_max: float, title: String) -> void:
	check(actor.uses_texture,title+" loads imported PNG")
	if not actor.uses_texture: return
	check(is_equal_approx(actor.art.scale.x,actor.art.scale.y),title+" has uniform scale")
	var bounds: Rect2 = actor.texture_bounds()
	var height_at_720 := bounds.size.y*2.0/3.0
	print(title," rendered canvas height at 720p: ",snappedf(height_at_720,0.1),"px")
	check(height_at_720 >= expected_min and height_at_720 <= expected_max,title+" is in target height range")
	check(not bounds.intersects(ui.battle_view.spell_card.get_global_rect()),title+" does not cover spell card")
	check(not bounds.intersects(ui.player_bar.get_global_rect()) and not bounds.intersects(ui.enemy_bar.get_global_rect()),title+" does not cover HP bars")
	for button in ui.answer_buttons:
		check(not bounds.intersects(button.get_global_rect()),title+" does not cover answers")

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	capture = DisplayServer.get_name() != "headless"
	var paths := ["res://assets/characters/word_mage.png","res://assets/enemies/marginalia.png"]
	for path in paths:
		var image := Image.new()
		var decode_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		check(decode_error == OK and not image.is_empty(),path+" decodes")
		if decode_error != OK or image.is_empty(): continue
		var alpha := image.detect_alpha()
		var transparent := 0
		var visible := 0
		for y in range(0,image.get_height(),4):
			for x in range(0,image.get_width(),4):
				var a := image.get_pixel(x,y).a
				if a < 0.01: transparent += 1
				if a > 0.5: visible += 1
		print(path," size=",image.get_size()," alpha_mode=",alpha," used_rect=",image.get_used_rect()," transparent_samples=",transparent," visible_samples=",visible)
		check(alpha != Image.ALPHA_NONE and transparent > 0 and visible > 0,path+" has effective transparency")
		check(ResourceLoader.exists(path),path+" is imported")
	var ui: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	await screenshot("title")
	ui._start_adventure(true)
	ui._enter_node("first")
	await process_frame
	await process_frame
	inspect_actor(ui.player_avatar,ui,250,305,"Word Mage")
	check(ui.enemy_avatar.uses_texture,"Normal enemy loads supplied Ink Wraith")
	await screenshot("normal_idle")
	var state: Node = root.get_node("GameState")
	var before: int = state.enemy_hp
	ui._on_answer(int(ui.current_question["correct_index"]))
	await create_timer(0.32).timeout
	check(ui.player_avatar.pose.position.x != 0,"PNG follows attack pose")
	await screenshot("normal_cast")
	await create_timer(0.85).timeout
	check(state.enemy_hp < before and ui.accepting_answer,"Player attack completes and next question opens")
	state.battle_index = 2
	state.start_battle()
	ui.show_encounter_intro()
	await create_timer(2.05).timeout
	await process_frame
	inspect_actor(ui.enemy_avatar,ui,270,310,"The Marginalia")
	await screenshot("elite_idle")
	var original_position: Vector2 = ui.enemy_avatar.visual.position
	await create_timer(0.25).timeout
	check(ui.enemy_avatar.visual.position != original_position,"Elite PNG follows idle float")
	var old_hp: int = state.hp
	ui._on_answer((int(ui.current_question["correct_index"])+1)%4)
	await create_timer(0.23).timeout
	await screenshot("elite_counterattack")
	await create_timer(1.8).timeout
	check(state.hp < old_hp and ui.accepting_answer,"Elite counterattack finishes")
	state.enemy_hp = 1
	ui._on_answer(int(ui.current_question["correct_index"]))
	await create_timer(1.1).timeout
	check(ui.enemy_avatar.modulate.a < 1.0,"Elite PNG follows death fade")
	await screenshot("elite_death")
	await create_timer(0.9).timeout
	check(ui.screen == "reward","Elite death reaches reward")
	root.get_node("AudioBus").stop_all()
	ui.queue_free()
	await process_frame
	await create_timer(0.20,true,false,true).timeout
	print("ARTWORK RESULT: ","PASS" if failures.is_empty() else "FAIL"," | failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
