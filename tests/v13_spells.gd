extends SceneTree

const BOLT = preload("res://scripts/ui/magic_bolt.gd")
const IMPACT = preload("res://scripts/ui/magic_burst.gd")
const EFFECT = preload("res://scripts/ui/spell_effect.gd")
const ENEMY_EFFECT = preload("res://scripts/ui/enemy_effect.gd")
const ENEMY_SPELL = preload("res://scripts/ui/enemy_spell.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")
var failures: Array[String] = []
var graphics := false
var video := false
var directory := "res://.local_test/v13_cn"
var ui: Control
var state: Node
var audio: Node
var save: Node
var tap: AudioEffectCapture
var mixer_peaks: Array[float] = []
var timing_samples: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func begin_battle() -> void:
	ui._start_adventure(true)
	ui._enter_node("first")

func check(ok: bool, description: String) -> void:
	if not ok:
		failures.append(description)
		push_error("V13 AV FAIL: "+description)

func wait(seconds: float) -> void:
	await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	if not graphics or video: return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Save screenshot "+name)

func transient_count() -> int:
	var total := 0
	for child in ui.get_children():
		if child.get_script() in [BOLT,IMPACT,EFFECT,ENEMY_EFFECT,ENEMY_SPELL]: total += 1
	return total

func current_bolt() -> Node2D:
	for child in ui.get_children():
		if child.get_script() == BOLT: return child
	return null

func current_charge() -> Node2D:
	for child in ui.get_children():
		if child.get_script() == EFFECT: return child
	return null

func count(event: String) -> int:
	return int(audio.event_counts.get(event,0))

func layout() -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(1920,1080))
	for id in ui.battle_view.spell_buttons:
		var button: Button = ui.battle_view.spell_buttons[id]
		check(viewport.encloses(button.get_global_rect()),"Skill fits viewport: "+str(id))
		for answer in ui.answer_buttons:
			check(not button.get_global_rect().intersects(answer.get_global_rect()),"Skill clear of answers")
	for actor in [ui.player_avatar,ui.enemy_avatar]:
		check(actor.uses_texture,"Formal PNG loaded")
		check(is_equal_approx(actor.art.scale.x,actor.art.scale.y),"PNG preserves aspect ratio")
		var bounds: Rect2 = actor.texture_bounds()
		check(not bounds.intersects(ui.battle_view.spell_card.get_global_rect()),"Art clear of spell card")
		for button in ui.answer_buttons+ui.battle_view.spell_buttons.values():
			check(not bounds.intersects(button.get_global_rect()),"Art clear of answer/skill buttons")
		for bar in [ui.player_bar,ui.enemy_bar]:
			check(not bounds.intersects(bar.get_global_rect()),"Art clear of HP bars")
	for button in ui.answer_buttons:
		check(viewport.encloses(button.get_global_rect()),"Chinese answers inside viewport")

func sample_mixer() -> void:
	if not graphics: return
	var buffer := tap.get_buffer(tap.get_frames_available())
	var peak := 0.0
	for frame in buffer: peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
	mixer_peaks.append(peak)
	check(peak > 0.00001 and peak < 0.9,"Actual mixed spell sound audible without clipping")

func cast(id: String, correct: bool, name: String = "") -> void:
	var attack_id := "arcane_tome" if state.battle_index == 3 else ("paper_slash" if state.battle_index == 2 else "ink_bolt")
	var intent: Dictionary = state.Brain.ATTACKS[attack_id].duplicate()
	intent["id"] = attack_id
	state.enemy_intent = intent
	state.intent_consumed = false
	ui._select_spell(id)
	check(state.selected_spell == id,"Spell selected: "+id)
	var before_answers: int = state.questions_answered()
	var before_total: int = int(save.total_answers)
	var event_start: int = audio.event_log.size()
	var present_start: int = ui.presentation_events.size()
	var index := int(ui.current_question.correct_index)
	if not correct: index = (index+1)%4
	if graphics: tap.clear_buffer()
	ui._on_answer(index)
	ui._on_answer(index)
	ui._select_spell("arcane" if id != "arcane" else "aegis")
	check(state.selected_spell == id,"Skill switching blocked during animation")
	check(state.questions_answered() == before_answers+1 and int(save.total_answers) == before_total+1,"Answer and Mastery settle once")
	for button in ui.battle_view.spell_buttons.values(): check(button.disabled,"Skill locked in animation")
	await wait(0.27)
	if id == "memory" and correct:
		check(is_instance_valid(current_charge()) and current_bolt() == null,"Memory gathers energy before release")
		await shot("memory_charge")
		await wait(0.17)
	var bolt := current_bolt()
	var paper := false
	for child in ui.get_children():
		if child.get_script() == ENEMY_SPELL and child.mode == Profiles.attack(attack_id).projectile: paper = true
	check(is_instance_valid(bolt) or not correct and paper,"Visible projectile in flight")
	if is_instance_valid(bolt):
		check(bolt.spell == (id if correct else "enemy"),"Distinct spell visual mode")
		check(is_equal_approx(bolt.scale.x,1.65 if id == "memory" and correct else (0.7 if id == "aegis" and correct else 1.0)),"Spell projectile size")
		if not correct: check(bolt.palette == ("boss" if state.battle_index == 3 else "ink"),"Enemy ink / Boss red palette")
	if id == "aegis" and correct: check(ui.shield_aura.visible and state.barrier > 0,"Visible rune barrier follows player pose")
	sample_mixer()
	if not name.is_empty(): await shot(name)
	await wait(0.32)
	if id == "memory" and correct:
		check(ui.battle_view.weak_label.text.contains("记忆共鸣 +5"),"True old-mistake bonus has separate feedback")
		await shot("memory_burst_hit")
	await wait(0.85 if correct else 1.45)
	if state.hp <= 0 or state.enemy_hp <= 0: await wait(0.8)
	check(state.questions_answered() == before_answers+1,"Delayed effects cannot resettle answer")
	check(transient_count() == 0,"Charge, projectile and hit effect cleaned up")
	var events: Array = audio.event_log.slice(event_start)
	var expected_release := ("memory_burst" if id == "memory" else ("aegis_activate" if id == "aegis" else "player_cast")) if correct else str(Profiles.attack(attack_id).cast_sfx)
	var expected_impact := ("burst_impact" if id == "memory" else "projectile_impact") if correct else str(Profiles.attack(attack_id).hit_sfx)
	var releases := 0
	var impacts := 0
	var release_time := 0
	var impact_time := 0
	for event in events:
		if event.event == expected_release:
			releases += 1
			release_time = int(event.time)
		if event.event == expected_impact:
			impacts += 1
			impact_time = int(event.time)
	check(releases == 1 and impacts == 1,"Release and collision sound each played once")
	check(impact_time >= release_time,"Release precedes impact")
	var presentations: Array = ui.presentation_events.slice(present_start)
	check(presentations.size() == 3,"One answer / release / impact presentation sequence")
	if presentations.size() == 3:
		check(abs(int(presentations[1].time)-release_time) <= 25 and abs(int(presentations[2].time)-impact_time) <= 25,"Sound and visible release/impact synchronized")
	if not video and not graphics: check(impact_time-release_time >= 280 and impact_time-release_time < 420,"Flight sound separation approximately 0.30s")
	timing_samples.append({"spell":id,"correct":correct,"release":release_time,"impact":impact_time,"gap_ms":impact_time-release_time})

func demonstrate() -> void:
	begin_battle()
	await wait(0.7)
	layout()
	check(state.mana == 1 and state.barrier == 0,"New battle resources")
	check(ui.battle_view.spell_buttons.memory.disabled,"Insufficient mana button disabled")
	ui._select_spell("memory")
	check(state.selected_spell == "arcane","Insufficient mana cannot select")
	ui._select_spell("aegis")
	ui._select_spell("arcane")
	check(state.mana == 1 and state.questions_answered() == 0,"Switching costs no mana or answers")
	var missed_entry: Dictionary = ui.current_question.entry.duplicate()
	await cast("arcane",false,"enemy_counterattack")
	await cast("arcane",true,"arcane_bolt")
	await cast("arcane",true)
	check(state.mana == 3,"Arcane builds mana")
	await cast("aegis",true,"aegis_seal")
	check(state.barrier == 8 and state.mana == 2,"Aegis grants barrier and spends one")
	var hp_before: int = state.hp
	var hurt_before := count("player_hit")
	await cast("arcane",false,"shield_absorption")
	check(state.hp == hp_before-2 and state.barrier == 0,"Eight barrier absorbs enemy's first eight damage")
	check(count("player_hit") == hurt_before+1,"Remaining HP damage produces player hurt once")
	# Demonstration fixture: re-present a genuinely missed entry to prove bonus.
	# Only test UI input is controlled; shipping question sampling is unchanged.
	var options: Array[String] = [str(missed_entry.meaning)]
	for entry in root.get_node("WordBank").entries:
		if not options.has(str(entry.meaning)): options.append(str(entry.meaning))
		if options.size() == 4: break
	ui.current_question = {"entry":missed_entry,"options":options,"correct_index":0,"missed_this_run":true,"weak_word":save.mastery_of(str(missed_entry.word)) < 50,"mastery":save.mastery_of(str(missed_entry.word))}
	ui._display_question()
	var enemy_before: int = state.enemy_hp
	await cast("memory",true,"memory_burst")
	check(state.enemy_hp == maxi(0,enemy_before-23) and state.mana == 0,"Memory actual old-run mistake deals 18+5")
	if ui.screen == "battle": await cast("arcane",true)
	check(ui.screen == "reward","Normal battle demo reaches victory and reward")
	await shot("reward_cn")

func safety() -> void:
	begin_battle()
	await wait(0.15)
	await cast("arcane",true)
	ui._select_spell("memory")
	ui._on_answer(int(ui.current_question.correct_index))
	await wait(0.08)
	var charge := current_charge()
	check(is_instance_valid(charge),"Charge present for pause test")
	ui.pause_menu.open_menu()
	await shot("pause_cn")
	var progress: float = charge.progress
	var phase: float = charge.phase
	var event_count: int = audio.event_log.size()
	var answer_count: int = state.questions_answered()
	await wait(0.45)
	ui._on_answer(int(ui.current_question.correct_index))
	ui._select_spell("aegis")
	check(is_equal_approx(charge.progress,progress) and is_equal_approx(charge.phase,phase),"Pause freezes charge tween and drawing")
	check(audio.event_log.size() == event_count and state.questions_answered() == answer_count,"Pause blocks sound advancement and duplicate settlement")
	ui.pause_menu.resume()
	await wait(1.3)
	check(ui.accepting_answer and state.questions_answered() == answer_count and transient_count() == 0,"Resume resolves once and removes effects")
	begin_battle()
	await wait(0.1)
	state.mana = 2 # Test fixture for interrupting the long spell.
	ui._select_spell("memory")
	ui._on_answer(int(ui.current_question.correct_index))
	await wait(0.08)
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("title")
	ui.pause_menu.confirm_action()
	var casts_before := count("memory_burst")
	await wait(1.4)
	check(ui.screen == "title" and transient_count() == 0 and count("memory_burst") == casts_before,"Return to title cancels pending charge / sound")
	begin_battle()
	await wait(0.15)
	state.mana = 2
	ui._select_spell("memory")
	ui._on_answer(int(ui.current_question.correct_index))
	await wait(0.08)
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("restart")
	ui.pause_menu.confirm_action()
	check(ui.screen == "difficulty", "Restart offers difficulty selection")
	ui._begin_run("normal",true)
	ui._enter_node("first")
	await wait(1.4)
	check(state.mana == 1 and state.barrier == 0 and state.rewards.is_empty() and state.questions_answered() == 0 and ui.accepting_answer and transient_count() == 0,"Restart clears temporary resources / old callbacks")
	for child in audio.get_children():
		if child is AudioStreamPlayer and child != audio.music_player:
			check(not child.playing,"Restart cancels previous combat sound")
	await cast("aegis",false)
	check(state.mana == 0 and state.barrier == 0 and state.hp == 93,"Wrong Aegis consumes mana, mitigates damage and grants no barrier")
	state.mana = 2
	var enemy_before: int = state.enemy_hp
	await cast("memory",false)
	check(state.mana == 0 and state.enemy_hp == enemy_before and state.hp == 83,"Wrong Memory consumes mana and does not attack")
	state.barrier = 16
	ui._sync_barrier()
	var hurt_before := count("player_hit")
	var shield_before := count("shield_hit")
	await cast("arcane",false)
	check(state.hp == 83 and state.barrier == 6 and count("player_hit") == hurt_before and count("shield_hit") == shield_before+1,"Full barrier absorbs damage with shield sound and no HP injury sound")
	begin_battle()
	await wait(0.15)
	state.hp = 5
	await cast("arcane",false)
	check(ui.screen == "report" and not ui.accepting_answer and state.hp == 0,"Death cannot create next question")
	await shot("report_cn")
	begin_battle()
	for stage in [2,3]:
		state.battle_index = stage
		state.start_battle()
		ui.show_battle()
		await wait(0.4)
		layout()
		await shot("elite_layout" if stage == 2 else "boss_layout")
		await cast("arcane",false,"elite_counterattack" if stage == 2 else "boss_counterattack")
	ui.show_title()

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	graphics = DisplayServer.get_name() != "headless"
	video = OS.get_cmdline_user_args().has("--video")
	if graphics and DisplayServer.window_get_size().x > 1500: directory += "/1920x1080"
	DirAccess.make_dir_recursive_absolute(directory)
	state = root.get_node("GameState")
	audio = root.get_node("AudioBus")
	save = root.get_node("SaveData")
	for event in ["player_cast","enemy_cast","projectile_impact","enemy_hurt","player_hit","aegis_activate","shield_hit","memory_charge","memory_burst","burst_impact"]:
		check(audio.streams.has(event),"Distinct event resource loaded: "+event)
		if not audio.streams.has(event): continue
		var stream: AudioStream = audio.streams[event]
		var playback := stream.instantiate_playback()
		playback.start()
		var frames := playback.mix_audio(1.0,ceili(stream.get_length()*AudioServer.get_mix_rate()))
		playback.stop()
		var peak := 0.0
		for frame in frames: peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		check(peak > 0.005 and peak < 0.7,"Decoded SFX has nonzero bounded peak: "+event)
	check(audio.streams.player_cast != audio.streams.enemy_cast,"Enemy cast does not reuse pitched player cast")
	check(audio.streams.projectile_impact != audio.streams.enemy_hurt,"Collision separate from creature injury")
	if graphics:
		tap = AudioEffectCapture.new()
		tap.buffer_length = 3.0
		AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),tap)
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	check(ui.screen == "title","Game launches at title")
	await shot("title_cn")
	await demonstrate()
	if not video: await safety()
	if graphics: AudioServer.remove_bus_effect(AudioServer.get_bus_index("SFX"),AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX"))-1)
	audio.stop_all()
	ui.queue_free()
	await process_frame
	await wait(0.2)
	var output := {"passed":failures.is_empty(),"failures":failures,"graphics":graphics,"video":video,"resolution":str(DisplayServer.window_get_size()) if graphics else "headless","mixed_sfx_peaks":mixer_peaks,"timing":timing_samples}
	FileAccess.open(directory+("/video_results.json" if video else ("/av_results.json" if graphics else "/headless_results.json")),FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("V13 AV RESULT: ","PASS" if failures.is_empty() else "FAIL"," | failures=",failures.size()," | graphics=",graphics," | video=",video," | mixer_peaks=",mixer_peaks)
	quit(0 if failures.is_empty() else 1)
