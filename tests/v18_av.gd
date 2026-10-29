extends SceneTree

const Enemies = preload("res://scripts/enemy_definitions.gd")
const Brain = preload("res://scripts/enemy_brain.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")
const Actor = preload("res://scripts/ui/actor_view.gd")
var ui: Control
var state: Node
var audio: Node
var save: Node
var failures: Array[String] = []
var checks := 0
var directory := "res://.local_test/v18"
var music_samples: Array[Dictionary] = []
var effect_samples: Array[Dictionary] = []
var tap: AudioEffectCapture
var sfx_tap: AudioEffectCapture

func _initialize() -> void:
	call_deferred("run")
	create_timer(90,true,false,true).timeout.connect(func() -> void: push_error("V18 timeout"); quit(3))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error("V18 FAIL: "+message)

func wait(seconds: float) -> void: await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	await process_frame; await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Capture "+name)

func fixture(id: String, attack_id: String = "") -> void:
	ui._begin_run("normal"); ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[id].duplicate(); state.battle_enemy.id = id
	state.battle_index = 3 if id == "librarian" else (2 if Enemies.ENEMIES[id].kind == "elite" else 0)
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	state.intent_consumed = true; state.enemy_intent = {}
	if not attack_id.is_empty():
		var intent: Dictionary = Brain.ATTACKS[attack_id].duplicate(); intent.id = attack_id
		intent.make_read_only(); state.enemy_intent = intent; state.intent_consumed = false
	ui.show_battle()

func layout(id: String) -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(1920,1080))
	check(ui.enemy_avatar.uses_texture and ui.player_avatar.uses_texture,"Formal portraits "+id)
	check(is_equal_approx(ui.enemy_avatar.art.scale.x,ui.enemy_avatar.art.scale.y),"Proportional portrait "+id)
	check(ui.battle_view.momentum_view.visible,"Momentum present "+id)
	for control in ui.answer_buttons+ui.battle_view.spell_buttons.values()+[ui.battle_view.spell_card,ui.enemy_bar,ui.enemy_hp_label,ui.battle_view.momentum_view]:
		check(viewport.encloses(control.get_global_rect()),"UI fits "+id)
		check(not ui.enemy_avatar.texture_bounds().intersects(control.get_global_rect()),"Portrait clear of UI "+id)
	if id == "dust_sentinel": check(ui.enemy_avatar.art.texture.resource_path.ends_with("ink_wraith.png"),"Missing dust_guard uses approved Ink Wraith")

func peak(source: AudioEffectCapture) -> float:
	var result := 0.0
	for frame in source.get_buffer(source.get_frames_available()): result = maxf(result,maxf(absf(frame.x),absf(frame.y)))
	return result

func music(key: String) -> void:
	await wait(0.68)
	check(audio.music_key == key and audio.music_player.playing,"Actual scene music "+key)
	check(audio.music_player.stream == audio.music_streams[key],"Correct stream "+key)
	var starts: int = audio.music_start_count
	audio.set_music(key,true); await wait(0.27)
	check(audio.music_start_count == starts,"Same track gain change does not restart "+key)
	# Real AudioStreamPlayer crosses the source's end with loop enabled.
	tap.clear_buffer()
	audio.music_player.play(audio.music_streams[key].get_length()-0.12)
	await wait(0.35)
	var mix := peak(tap)
	check(audio.music_player.playing and audio.music_player.get_playback_position() < 1.0,"Real playback loops "+key)
	check(mix > 0.0000001 and mix < 0.95,"Audible music bus without mix clipping "+key)
	music_samples.append({"track":key,"duration":audio.music_streams[key].get_length(),"peak":mix})

func enemy_attack(id: String, attack_id: String) -> void:
	fixture(id,attack_id); await wait(0.1)
	var promised: Dictionary = state.incoming_preview()
	var before: int = state.hp
	var total: int = save.total_answers
	var start: int = audio.event_log.size()
	var wrong := (int(ui.current_question.correct_index)+1)%4
	sfx_tap.clear_buffer()
	ui._on_answer(wrong); ui._on_answer(wrong)
	check(state.hp == before-int(promised.hp_damage) and save.total_answers == total+1,"Damage and Mastery settle once "+attack_id)
	for retry in 65:
		if ui.accepting_answer: break
		await wait(0.04)
	check(ui.accepting_answer,"Attack ends at next question "+attack_id)
	var profile := Profiles.attack(attack_id,id)
	var cast := 0; var hit := 0; var cast_time := 0; var hit_time := 0
	for event in audio.event_log.slice(start):
		if event.event == profile.cast_sfx: cast += 1; cast_time = int(event.time)
		if event.event == profile.hit_sfx: hit += 1; hit_time = int(event.time)
	check(cast == 1 and hit == 1 and hit_time > cast_time,"Existing cast/hit timing "+attack_id)
	var mix := peak(sfx_tap)
	check(mix > 0.00001 and mix < 0.95,"SFX mix without clipping "+attack_id)
	effect_samples.append({"attack":attack_id,"cast_file":audio.streams[profile.cast_sfx].resource_path,"hit_file":audio.streams[profile.hit_sfx].resource_path,"peak":mix})

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test") or DisplayServer.get_name() == "headless": quit(2); return
	state = root.get_node("GameState"); audio = root.get_node("AudioBus"); save = root.get_node("SaveData")
	DirAccess.make_dir_recursive_absolute(directory)
	tap = AudioEffectCapture.new(); tap.buffer_length = 4.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"),tap)
	sfx_tap = AudioEffectCapture.new(); sfx_tap.buffer_length = 4.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),sfx_tap)
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui); await process_frame
	for key in ["title_map","elite_battle","memory_rest","event_special"]:
		check(audio.music_streams.has(key) and audio.music_streams[key].loop,"New BGM loaded and loopable "+key)
	check(audio.MATERIAL_SOUNDS.size() == 55,"No extra fake sound event names")
	for event in audio.MATERIAL_SOUNDS: check(audio.streams.has(event),"Material SFX load "+str(event))
	await music("title_map"); await shot("title")
	ui._begin_run("normal"); await music("title_map"); await shot("map")
	ui._enter_node("first"); await music("normal_battle")
	check(ui.active_background_path.ends_with("library_corridor.jpg"),"12.jpg ordinary battle")
	await shot("normal_12")
	fixture("silent_archivist"); await music("elite_battle")
	check(ui.active_background_path.ends_with("library_elite.jpg"),"13.jpg elite")
	await shot("elite_13")
	fixture("librarian"); await music("boss_battle")
	check(ui.active_background_path.ends_with("library_battle.png"),"Boss approved old background")
	await shot("boss_old")
	ui.show_rest(); await music("memory_rest")
	check(ui.active_background_path.ends_with("memory_chamber.jpg"),"14.jpg rest")
	await shot("rest_14")
	state.review.build(root.get_node("WordBank"),save,state.wrong_words)
	ui.show_review(); await music("memory_rest"); await shot("memory_14")
	state.events.open("v18_visual",18); state.events.current.id = "chest"
	ui.show_event(); await music("event_special")
	check(ui.active_background_path.ends_with("event_ritual.jpg"),"Event retains approved altar")
	await shot("event_altar")
	ui.pause_menu.open_menu(); ui.pause_menu.open_settings()
	var position: float = audio.music_player.get_playback_position()
	await wait(0.25)
	check(audio.music_player.stream_paused and absf(audio.music_player.get_playback_position()-position) < 0.08,"ESC pauses music position")
	var old_music: float = audio.music_percent; var old_sfx: float = audio.sfx_percent
	ui.pause_menu.sliders.music.value = 0; ui.pause_menu.sliders.sfx.value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Independent mute")
	audio.load_settings(); check(audio.music_percent == 0 and audio.sfx_percent == 0,"Isolated settings persist")
	ui.pause_menu.sliders.music.value = old_music; ui.pause_menu.sliders.sfx.value = old_sfx
	ui.pause_menu.resume(); await wait(0.15)
	check(not audio.music_player.stream_paused,"ESC resumes music")
	# Both resolutions, all eight original/new enemies, approved portraits and UI.
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/v18/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		for id in Enemies.ENEMIES:
			fixture(str(id)); await wait(0.08); layout(str(id))
			if id in ["paper_golem","silent_archivist","librarian"]: await shot(str(id))
		ui.show_rest(); await wait(0.08); await shot("rest_14")
		state.events.open("v18_visual",18); state.events.current.id = "chest"; ui.show_event(); await wait(0.08); await shot("event_altar")
	# Six families and old elite, through actual answer callbacks.
	for pair in [["ink_wraith","ink_surge"],["paper_golem","paper_fist"],["grimoire_mimic","mimic_bite"],["lantern_wisp","wisp_flash"],["marginalia","paper_slash"],["silent_archivist","archive_chain"],["librarian","final_judgment"]]:
		await enemy_attack(str(pair[0]),str(pair[1]))
	fixture("paper_golem"); await wait(0.08)
	await ui._on_answer(int(ui.current_question.correct_index))
	check(state.momentum.value == 1 and ui.battle_view.momentum_view.displayed_value == 1,"Player spell and momentum retain behavior")
	# Controlled missing-resource fixtures; no disk assets are removed.
	var backup: Dictionary = audio.music_streams.duplicate()
	audio.music_streams.erase("elite_battle"); audio.set_scene_music("battle_elite"); await wait(0.7)
	check(audio.music_key == "normal_battle","Missing elite music fallback")
	audio.music_streams.erase("title_map"); audio.set_scene_music("title_map"); await wait(0.3)
	check(not audio.music_player.playing,"Missing title music fades to silence")
	audio.music_streams = backup
	var sounds: Dictionary = audio.streams.duplicate(); audio.streams.clear()
	audio.play_event("archive_chain_cast"); audio.streams = sounds
	ui.background_path = "res://assets/backgrounds/missing_v18.jpg"; ui.show_title()
	check(ui.active_background_path.is_empty(),"Missing background program fallback")
	var fallback := Actor.new(); ui.add_child(fallback); fallback.setup("normal","res://assets/enemies/missing_v18.png",Color.WHITE)
	check(not fallback.uses_texture,"Missing portrait fallback"); fallback.queue_free()
	check(audio.get_node("Music") == audio.music_player,"Original single Music player retained")
	var output := {"pass":failures.is_empty(),"checks":checks,"failures":failures,"music":music_samples,"sfx":effect_samples}
	var file := FileAccess.open("res://.local_test/v18/result.json",FileAccess.WRITE); file.store_string(JSON.stringify(output,"\t")); file.close()
	AudioServer.remove_bus_effect(AudioServer.get_bus_index("Master"),AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Master"))-1)
	AudioServer.remove_bus_effect(AudioServer.get_bus_index("SFX"),AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX"))-1)
	audio.stop_all(); ui.queue_free(); await wait(0.25)
	print("V18 AV: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	quit(0 if failures.is_empty() else 1)
