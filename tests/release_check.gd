extends SceneTree

# External QA driver, excluded from every distributable. Runs against the PCK.
const Enemies = preload("res://scripts/enemy_definitions.gd")
const Actor = preload("res://scripts/ui/actor_view.gd")
var ui: Control
var state: Node
var audio: Node
var checks := 0
var failures: Array[String] = []
var directory := "D:/项目/1/.local_test/release/qa"

func _initialize() -> void:
	call_deferred("run")
	create_timer(50,true,false,true).timeout.connect(func() -> void: push_error("Release QA timeout"); quit(3))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("Release QA: "+message)

func wait(seconds: float) -> void:
	await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Screenshot "+name)

func fixture(id: String) -> void:
	ui._begin_run("normal")
	ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[id].duplicate()
	state.battle_enemy.id = id
	state.battle_index = 3 if id == "librarian" else (2 if Enemies.ENEMIES[id].kind == "elite" else 0)
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	state.intent_consumed = true
	state.enemy_intent = {}
	ui.show_battle()

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not ".local_test" in OS.get_user_data_dir(): quit(2); return
	DirAccess.make_dir_recursive_absolute(directory)
	state = root.get_node("GameState")
	audio = root.get_node("AudioBus")
	var bank := root.get_node("WordBank")
	check(bank.load_words("res://data/words.json",120),"120 words present in exported PCK")
	check(bank.load_words("res://data/cet4_core_1500.json",1500),"1500 words present in exported PCK")
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await wait(0.15)
	check(ui.screen == "title","Exported executable reaches title")
	check(ui.ui_font is FontFile,"Bundled licensed font loaded")
	var missing := ""
	var glyphs := {}
	# Validate actual learning text, not unused catalog icon metadata / regex bounds.
	for path in ["res://data/words.json","res://data/cet4_core_1500.json"]:
		var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(path))
		for entry in entries:
			for key in ["word","meaning","phonetic"]:
				for character in str(entry[key]): glyphs[character] = true
	for character in glyphs:
		if not character in ["\n","\r","\t"] and not ui.ui_font.has_char(str(character).unicode_at(0)): missing += character
	check(missing.is_empty(),"Both dictionaries' Chinese/Latin/IPA glyphs covered: "+missing)
	check(audio.music_streams.size() == 6,"Six real BGM resources loaded")
	check(audio.streams.size() >= 90,"Existing SFX mappings loaded")
	for key in audio.music_streams:
		check(audio.music_streams[key].get_length() > 10.0 and audio.music_streams[key].loop,"Looping BGM "+key)
	check(FileAccess.file_exists("res://assets/audio/v18_music_analysis.json"),"Music gain JSON included")
	check(not FileAccess.file_exists("res://tests/smoke.gd"),"Tests not shipped")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		fixture("paper_golem")
		await wait(0.12)
		check(ui.player_avatar.uses_texture and ui.enemy_avatar.uses_texture,"PNGs loaded "+str(resolution))
		check(is_equal_approx(ui.player_avatar.art.scale.x,ui.player_avatar.art.scale.y),"Portrait aspect preserved")
		for button in ui.answer_buttons:
			check(ui.get_global_rect().encloses(button.get_global_rect()),"Answer button inside viewport")
		check(ui.get_global_rect().encloses(ui.battle_view.intent_label.get_global_rect()),"Footer is fully inside viewport")
		await shot("battle_"+str(resolution.x))
	for id in Enemies.ENEMIES:
		fixture(str(id))
		await wait(0.05)
		check(ui.enemy_avatar.uses_texture,"Portrait/fallback "+str(id))
	fixture("paper_golem")
	await wait(0.12)
	state.enemy_hp = 1000
	for spell in ["arcane","aegis","memory"]:
		state.mana = 3
		ui._select_spell(spell)
		await ui._on_answer(int(ui.current_question.correct_index))
		check(ui.accepting_answer,"Cast returns to waiting "+spell)
	var before: int = state.correct_count + state.wrong_count
	ui.pause_menu.back()
	check(paused and ui.pause_menu.overlay.visible,"Back key enters native pause")
	ui._on_answer(int(ui.current_question.correct_index))
	await wait(0.15)
	check(before == state.correct_count + state.wrong_count,"Pause prevents answer settlement")
	ui.pause_menu.open_settings()
	ui.pause_menu.back()
	check(not ui.pause_menu.showing_settings and paused,"Back leaves settings without ending pause")
	ui.pause_menu.back()
	check(not paused,"Back resumes")
	ui._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(paused,"OS background notification saves and pauses")
	ui.pause_menu.resume()
	var fallback := Actor.new()
	ui.add_child(fallback)
	fallback.setup("normal","res://assets/enemies/absent.png",Color.WHITE)
	check(not fallback.uses_texture,"Missing art procedural fallback")
	fallback.queue_free()
	var saved_music: float = audio.music_percent
	audio.set_volume("music",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")),"Music mute works")
	audio.set_volume("music",saved_music)
	ui.show_title()
	await wait(0.1)
	await shot("title")
	ui._clear_screen()
	audio.stop_all()
	await wait(0.2)
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"exe":OS.get_executable_path(),"profile":OS.get_user_data_dir(),"touch_preview":ui.PlatformUI.touch_mode()}
	FileAccess.open(directory+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("RELEASE QA ","PASS" if failures.is_empty() else "FAIL"," checks=",checks)
	quit(0 if failures.is_empty() else 1)
