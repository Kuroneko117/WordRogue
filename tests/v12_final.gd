extends SceneTree

var failures: Array[String] = []
var capture := false
var capture_directory := "res://.local_test/v12_final"

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, text: String) -> void:
	if not condition:
		failures.append(text)
		push_error("V12 FAIL: "+text)

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_directory+"/"+name+".png")

func check_actor(actor: Control, ui: Control, minimum: float, maximum: float, description: String) -> void:
	check(actor.uses_texture,description+" PNG loaded")
	if not actor.uses_texture: return
	check(is_equal_approx(actor.art.scale.x,actor.art.scale.y),description+" uniform scale")
	var bounds: Rect2 = actor.texture_bounds()
	var height := bounds.size.y*2.0/3.0
	print(description," height at 720p=",snappedf(height,0.1)," width=",snappedf(bounds.size.x*2.0/3.0,0.1))
	check(height >= minimum and height <= maximum,description+" reasonable display height")
	check(not bounds.intersects(ui.battle_view.spell_card.get_global_rect()),description+" clear of Word Spell")
	for button in ui.answer_buttons:
		check(not bounds.intersects(button.get_global_rect()),description+" clear of answers")
	for bar in [ui.player_bar,ui.enemy_bar]:
		check(not bounds.intersects(bar.get_global_rect()),description+" clear of HP")

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	capture = DisplayServer.get_name() != "headless"
	if not capture: Engine.time_scale = 3.0
	if capture and DisplayServer.window_get_size().x > 1500:
		capture_directory += "/1920x1080"
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var inspected: Dictionary = {}
	for path in ["characters/word_mage.png","enemies/ink_wraith.png","enemies/marginalia.png","enemies/librarian.png","backgrounds/library_battle.png"]:
		var image := Image.new()
		var error := image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/"+path))
		check(error == OK and not image.is_empty(),path+" decodes")
		if error != OK: continue
		var transparent := 0
		var visible := 0
		for y in range(0,image.get_height(),8):
			for x in range(0,image.get_width(),8):
				var alpha := image.get_pixel(x,y).a
				if alpha < 0.01: transparent += 1
				if alpha > 0.5: visible += 1
		if not path.begins_with("backgrounds"):
			check(image.detect_alpha() != Image.ALPHA_NONE and transparent > 0 and visible > 0,path+" effective alpha")
		check(ResourceLoader.exists("res://assets/"+path),path+" imported")
		inspected[path] = {"width":image.get_width(),"height":image.get_height(),"alpha_mode":image.detect_alpha(),"transparent_samples":transparent,"visible_samples":visible}
	var inspection_file := FileAccess.open(capture_directory+"/asset_inspection.json",FileAccess.WRITE)
	inspection_file.store_string(JSON.stringify(inspected,"  "))
	var audio: Node = root.get_node("AudioBus")
	var bank: Node = root.get_node("WordBank")
	var state: Node = root.get_node("GameState")
	for event in ["ui_click","correct","wrong","player_cast","magic_hit","player_hurt","enemy_death","combo","reward_select","boss_intro","victory","defeat"]:
		check(audio.streams.has(event),event+" sound loaded")
		if not audio.streams.has(event): continue
		var stream: AudioStream = audio.streams[event]
		check(stream.get_length() > 0.04 and stream.get_length() <= 1.6,event+" short duration")
		var playback := stream.instantiate_playback()
		playback.start()
		var frames := playback.mix_audio(1.0,ceili(minf(1.6,stream.get_length())*AudioServer.get_mix_rate()))
		playback.stop()
		var peak := 0.0
		for frame in frames:
			peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		check(peak > 0.005 and peak < 0.7,event+" decodes audible non-clipping samples")
		print(event," seconds=",snappedf(stream.get_length(),0.01)," peak=",snappedf(peak,0.01))
	for key in ["normal_battle","boss_battle"]:
		check(audio.music_streams.has(key),key+" music loaded")
		if audio.music_streams.has(key):
			check(audio.music_streams[key].loop,key+" loops")
			print(key," duration=",audio.music_streams[key].get_length())
	var bus := AudioServer.get_bus_index("SFX")
	var tap := AudioEffectCapture.new()
	tap.buffer_length = 3.0
	AudioServer.add_bus_effect(bus,tap)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame
	check(ui.screen == "title" and (audio.music_key == "title_map" if audio.music_streams.has("title_map") else audio.music_key.is_empty()),"Title uses its own music or silence")
	ui._start_adventure(true)
	ui._enter_node("first")
	bank.rng.seed = 20261009
	var names := ["normal_battle","normal_battle_2","elite_battle","boss_battle"]
	var sources := ["ink_wraith","ink_wraith","marginalia","librarian"]
	var music_starts := 0
	for stage in 4:
		if stage > 0:
			state.battle_index = stage
			state.start_battle()
			ui.recent_words.clear()
			if stage >= 2:
				ui.show_encounter_intro()
				await create_timer(2.1).timeout
			else: ui.show_battle()
		await process_frame
		await process_frame
		await create_timer(0.65).timeout
		check(ui.screen == "battle",str(stage)+" battle opens")
		check(ui.encounter_label.text == "已答题  %d" % state.questions_answered(),"Battle footer shows current run question total")
		check_actor(ui.player_avatar,ui,245,305,"Word Mage stage "+str(stage))
		check_actor(ui.enemy_avatar,ui,310 if stage == 3 else (270 if stage == 2 else 225),355 if stage == 3 else (310 if stage == 2 else 275),str(sources[stage]))
		check(ui.enemy_avatar.art.texture.resource_path.ends_with(str(sources[stage])+".png"),"Correct enemy for stage "+str(stage))
		var backgrounds := 0
		var old_backgrounds := 0
		for child in ui.get_children():
			if child is TextureRect and child.texture.resource_path == ui.active_background_path:
				backgrounds += 1
			if child.get_script() == load("res://scripts/ui/library_backdrop.gd"):
				old_backgrounds += 1
		check(backgrounds == 1 and old_backgrounds == 0,"Formal background without duplicated procedural shelves")
		check(audio.music_key == ("boss_battle" if stage == 3 else ("elite_battle" if stage == 2 and audio.music_streams.has("elite_battle") else "normal_battle")) and audio.music_player.playing,"Correct battle music")
		if stage == 0: music_starts = audio.music_start_count
		if stage == 1 or stage == 2 and not audio.music_streams.has("elite_battle"): check(audio.music_start_count == music_starts,"Same normal track persists between battles")
		await shot(str(names[stage]))
		var before_answers: int = state.questions_answered()
		var before_enemy: int = state.enemy_hp
		var before_cast: int = int(audio.event_counts.get("player_cast",0))
		var right := int(ui.current_question["correct_index"])
		if stage == 0 and capture: tap.clear_buffer()
		ui._on_answer(right)
		ui._on_answer(right)
		await create_timer(0.30).timeout
		if stage == 0 and capture:
			# Read before PNG compression: long screenshot work can fill an
			# AudioEffectCapture buffer with pre-attack silence at high resolution.
			var buffer := tap.get_buffer(tap.get_frames_available())
			var peak := 0.0
			for frame in buffer: peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
			check(peak > 0.00001,"Actual SFX bus contains audible playback")
			print("SFX mixer capture peak=",peak)
		await shot(str(names[stage])+"_cast")
		await create_timer(0.25).timeout
		await shot(str(names[stage])+"_hit")
		await create_timer(0.65).timeout
		check(state.questions_answered() == before_answers+1 and state.enemy_hp < before_enemy and ui.accepting_answer,"Correct answer resolves once through FX")
		check(int(audio.event_counts.get("player_cast",0)) == before_cast+1,"Cast sound occurs once at release")
		var before_hp: int = state.hp
		var wrong := (int(ui.current_question["correct_index"])+1)%4
		ui._on_answer(wrong)
		await create_timer(0.30).timeout
		await shot(str(names[stage])+"_counterattack")
		await create_timer(1.9).timeout
		check(state.hp < before_hp and state.combo == 0 and ui.accepting_answer,"Enemy counterattack preserves learning time and HP rules")
		if stage == 0:
			check(audio.music_start_count == music_starts,"Questions do not restart music")
		await create_timer(0.25).timeout
		var remnants := 0
		for child in ui.get_children():
			if child.get_script() in [load("res://scripts/ui/magic_bolt.gd"),load("res://scripts/ui/magic_burst.gd")]: remnants += 1
		check(remnants == 0,"Transient battle effects cleaned up")
	ui._on_answer(int(ui.current_question["correct_index"]))
	ui.pause_menu.open_menu()
	var stopped_pose: Vector2 = ui.player_avatar.pose.position
	var paused_position: float = audio.music_player.get_playback_position()
	await create_timer(0.35,true).timeout
	check(audio.music_player.stream_paused and ui.player_avatar.pose.position == stopped_pose,"Pause stops music and animations")
	check(absf(audio.music_player.get_playback_position()-paused_position) < 0.08,"Paused music position does not advance")
	ui.pause_menu.resume()
	await create_timer(1.2,true).timeout
	check(not audio.music_player.stream_paused and ui.accepting_answer,"Resume continues music and answer once")
	ui.show_title()
	await create_timer(0.65).timeout
	check(audio.music_key == "title_map" if audio.music_streams.has("title_map") else not audio.music_player.playing and audio.music_key.is_empty(),"Return to title leaves battle music")
	var backup_streams: Dictionary = audio.streams.duplicate()
	audio.streams.clear()
	var count_before := audio.get_child_count()
	audio.play_event("correct")
	check(audio.get_child_count() == count_before,"Missing SFX skips playback safely")
	audio.streams = backup_streams
	var backup_music: Dictionary = audio.music_streams.duplicate()
	audio.music_streams.clear()
	audio.set_music("boss_battle")
	check(audio.music_key.is_empty(),"Missing music is safe")
	audio.music_streams = backup_music
	ui.background_path = "res://assets/backgrounds/missing_test.png"
	ui.show_title()
	var has_fallback := false
	for child in ui.get_children():
		if child.get_script() == load("res://scripts/ui/library_backdrop.gd"): has_fallback = true
	check(has_fallback,"Missing background uses procedural fallback")
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	audio.stop_all()
	ui.queue_free()
	await process_frame
	# Let the audio thread release stopped playbacks before closing the runner.
	await create_timer(0.20,true,false,true).timeout
	print("V12 FINAL RESULT: ","PASS" if failures.is_empty() else "FAIL"," | failures=",failures.size()," | graphics=",capture)
	quit(0 if failures.is_empty() else 1)
