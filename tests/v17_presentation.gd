extends SceneTree

const Profiles = preload("res://scripts/presentation_profiles.gd")
const Enemies = preload("res://scripts/enemy_definitions.gd")
const Brain = preload("res://scripts/enemy_brain.gd")
const Spell = preload("res://scripts/ui/enemy_spell.gd")
var ui: Control
var state: Node
var audio: Node
var save: Node
var failures: Array[String] = []
var graphics := false
var directory := "res://.local_test/v17"
var checks := 0
var samples: Array[Dictionary] = []
var tap: AudioEffectCapture

func _initialize() -> void:
	call_deferred("run")
	create_timer(55,true,false,true).timeout.connect(func() -> void: push_error("V17 timeout"); quit(3))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error("V17 FAIL: "+message)

func wait(seconds: float) -> void: await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	if not graphics: return
	await process_frame; await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Viewport capture "+name)

func fixture(enemy_id: String, attack_id: String) -> void:
	ui._begin_run("normal")
	ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[enemy_id].duplicate()
	state.battle_enemy.id = enemy_id
	state.battle_index = 3 if enemy_id == "librarian" else (2 if enemy_id in ["marginalia","silent_archivist"] else 0)
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	var intent: Dictionary = Brain.ATTACKS[attack_id].duplicate()
	intent.id = attack_id
	intent.make_read_only()
	state.enemy_intent = intent
	state.intent_consumed = false
	ui.show_battle()

func layout() -> void:
	var bounds := Rect2(Vector2.ZERO,Vector2(1920,1080))
	for button in ui.answer_buttons+ui.battle_view.spell_buttons.values():
		check(bounds.encloses(button.get_global_rect()),"Answers and spells fit")
	for actor in [ui.player_avatar,ui.enemy_avatar]:
		if not actor.uses_texture: continue
		check(is_equal_approx(actor.art.scale.x,actor.art.scale.y),"Portrait keeps aspect ratio")
		check(not actor.texture_bounds().intersects(ui.battle_view.spell_card.get_global_rect()),"Portrait clear of spell card")
		for button in ui.answer_buttons: check(not actor.texture_bounds().intersects(button.get_global_rect()),"Portrait clear of answers")

func demo(enemy_id: String, attack_id: String, freeze: bool = false) -> void:
	fixture(enemy_id,attack_id)
	await wait(0.08)
	layout()
	var profile := Profiles.attack(attack_id,enemy_id)
	var before: int = state.hp
	var promised: Dictionary = state.incoming_preview()
	var total: int = save.total_answers
	var log_start: int = audio.event_log.size()
	var wrong := (int(ui.current_question.correct_index)+1)%4
	if graphics: tap.clear_buffer()
	ui._on_answer(wrong); ui._on_answer(wrong)
	check(state.questions_answered() == 1 and save.total_answers == total+1,"Single answer and Mastery update "+attack_id)
	check(state.hp == before-int(promised.hp_damage),"Unchanged damage "+attack_id)
	await wait(0.32)
	var visible_effect: Node2D
	for child in ui.get_children():
		if child.get_script() == Spell and child.mode == profile.projectile: visible_effect = child
	check(is_instance_valid(visible_effect),"Identity-specific visual "+attack_id)
	if freeze and is_instance_valid(visible_effect):
		ui.pause_menu.open_menu()
		var age: float = visible_effect.age
		var position: Vector2 = visible_effect.position
		var events: int = audio.event_log.size()
		await wait(0.15)
		ui._on_answer(wrong)
		check(visible_effect.age == age and visible_effect.position == position and audio.event_log.size() == events,"Pause freezes effect and audio")
		ui.pause_menu.resume()
	await shot(attack_id)
	for retry in 65:
		if ui.accepting_answer: break
		await wait(0.04)
	check(ui.accepting_answer and state.questions_answered() == 1,"Next question without duplicate settlement "+attack_id)
	var release := 0
	var impact := 0
	var hurt := 0
	var release_time := 0
	var impact_time := 0
	for event in audio.event_log.slice(log_start):
		if event.event == profile.cast_sfx: release += 1; release_time = int(event.time)
		if event.event == profile.hit_sfx: impact += 1; impact_time = int(event.time)
		if event.event == "player_hit": hurt += 1
	check(release == 1 and impact == 1 and hurt == 1 and impact_time > release_time,"One ordered cast, hit and injury "+attack_id)
	for child in ui.get_children(): check(child.get_script() != Spell,"Temporary effects cleaned "+attack_id)
	var peak := 0.0
	if graphics:
		for frame in tap.get_buffer(tap.get_frames_available()): peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		check(peak > 0.00001 and peak < 0.95,"SFX mix present without clipping "+attack_id)
	samples.append({"attack":attack_id,"cast":profile.cast_sfx,"hit":profile.hit_sfx,"peak":peak})

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	state = root.get_node("GameState"); audio = root.get_node("AudioBus"); save = root.get_node("SaveData")
	graphics = DisplayServer.get_name() != "headless"
	if graphics and DisplayServer.window_get_size().x > 1500: directory += "/1920x1080"
	DirAccess.make_dir_recursive_absolute(directory)
	if graphics:
		tap = AudioEffectCapture.new(); tap.buffer_length = 4.0
		AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),tap)
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui)
	await process_frame
	check(ui.screen == "title","Title starts")
	await shot("title")
	for id in Brain.ATTACKS:
		check(Profiles.ATTACKS.has(id),"Explicit profile "+str(id))
		var profile := Profiles.attack(str(id))
		check(audio.MATERIAL_SOUNDS.has(profile.cast_sfx) and audio.MATERIAL_SOUNDS.has(profile.hit_sfx),"Audio mapping "+str(id))
	check(Profiles.attack("ink_surge").projectile == "ink_wave","Ink does not throw pages")
	check(Profiles.attack("wisp_flash").hit == "fire_hit","Wisp impact remains blue fire")
	check(Profiles.attack("archive_chain").projectile == "chain","Archivist chain")
	check(Profiles.attack("unknown").projectile == "ink_orb","Unknown safe fallback")
	# Draw every program-art mode once through the native renderer.
	var drawn: Dictionary = {}
	for id in Profiles.ATTACKS:
		var p := Profiles.attack(str(id))
		for mode in [p.projectile,p.hit,"charge","trail"]:
			var key := str(p.family)+str(mode)
			if drawn.has(key): continue
			drawn[key] = true
			var fx := Spell.new(); fx.mode = str(mode); fx.family = str(p.family)
			fx.position = Vector2(-500,-500); fx.endpoint = Vector2(-200,0); fx.life = 0.12
			ui.add_child(fx)
	await wait(0.18)
	for pair in [["ink_wraith","ink_surge"],["paper_golem","paper_fist"],["grimoire_mimic","arcane_theft"],["lantern_wisp","wisp_flash"],["silent_archivist","archive_chain"],["silent_archivist","archive_judgment"],["librarian","final_judgment"]]:
		await demo(str(pair[0]),str(pair[1]),pair[1] == "ink_surge")
	# Optional portrait lookup keeps each new monster's program-art fallback.
	for id in Profiles.PORTRAITS:
		fixture(str(id),"ink_bolt")
		var portrait: Dictionary = Profiles.PORTRAITS[id]
		if not str(portrait.get("fallback","")).is_empty():
			check(ui.enemy_avatar.uses_texture,"Approved missing-portrait fallback "+str(id))
		elif not ResourceLoader.exists("res://assets/enemies/"+str(portrait.art)+".png"):
			check(not ui.enemy_avatar.uses_texture and ui.enemy_avatar.art.kind == id,"Missing portrait fallback "+str(id))
	fixture("ink_wraith","ink_bolt")
	await wait(0.65)
	var starts: int = audio.music_start_count
	audio.set_scene_music("battle_elite",true); await wait(0.7)
	if audio.music_streams.has("elite_battle"):
		check(audio.music_key == "elite_battle","Dedicated elite music")
	else: check(audio.music_key == "normal_battle" and audio.music_start_count == starts,"Elite fallback does not restart normal music")
	ui.show_rest(); await wait(0.7)
	check(ui.active_background_path.ends_with("memory_chamber.jpg") if ResourceLoader.exists("res://assets/backgrounds/memory_chamber.jpg") else ui.active_background_path.ends_with("memory_rest.jpg"),"Rest background")
	if audio.music_streams.has("memory_rest"):
		check(audio.music_key == "memory_rest" and audio.music_player.playing,"Dedicated rest music")
	else: check(not audio.music_player.playing and audio.scene_music_key == "memory_rest","Missing rest music fades to silence")
	await shot("memory_rest")
	state.events.open("v17_fixture",17); state.events.current.id = "chest"
	ui.show_event(); await wait(0.12)
	check(ui.active_background_path.ends_with("event_ritual.jpg"),"Event background")
	await shot("event_ritual")
	ui.pause_menu.open_menu(); ui.pause_menu.open_settings()
	var old_music: float = audio.music_percent
	var old_sfx: float = audio.sfx_percent
	audio.set_volume("music",0); audio.set_volume("sfx",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Independent mute settings")
	audio.load_settings()
	check(audio.music_percent == 0 and audio.sfx_percent == 0,"Settings persist in isolated profile")
	audio.set_volume("music",old_music); audio.set_volume("sfx",old_sfx)
	ui.pause_menu.resume()
	if graphics:
		DisplayServer.window_set_size(Vector2i(1920,1080))
		fixture("ink_wraith","ink_bolt"); await wait(0.12)
		layout(); await shot("battle_1920x1080")
		ui.show_rest(); await wait(0.12); await shot("rest_1920x1080")
	fixture("ink_wraith","ink_bolt")
	ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	await wait(0.20)
	ui.show_title()
	var after: int = audio.event_log.size()
	await wait(0.85)
	check(ui.screen == "title" and audio.event_log.size() == after,"Screen change cancels delayed attack and sound")
	for child in ui.get_children(): check(child.get_script() != Spell,"Screen change clears effects")
	check(audio.get_node("Music") == audio.music_player,"Single BGM player")
	ui.background_path = "res://assets/backgrounds/missing.png"
	ui.show_title()
	check(ui.active_background_path.is_empty(),"Missing background fallback")
	var result := {"pass":failures.is_empty(),"checks":checks,"failures":failures,"graphics":graphics,"resolution":DisplayServer.window_get_size(),"samples":samples}
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")); file.close()
	if graphics: AudioServer.remove_bus_effect(AudioServer.get_bus_index("SFX"),AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX"))-1)
	audio.stop_all(); ui.queue_free(); await wait(0.2)
	print("V17 PRESENTATION: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks," | graphics=",graphics)
	quit(0 if failures.is_empty() else 1)
