extends SceneTree

const Brain = preload("res://scripts/enemy_brain.gd")
const Effect = preload("res://scripts/ui/enemy_effect.gd")
const EnemySpell = preload("res://scripts/ui/enemy_spell.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")
var ui: Control
var state: Node
var save: Node
var audio: Node
var graphics := false
var video := false
var directory := "res://.local_test/v14"
var failures: Array[String] = []
var visuals: Array[String] = []
var routes := 0
var tap: AudioEffectCapture
var peaks: Array[float] = []

func _initialize() -> void:
	call_deferred("_run")
	create_timer(95.0,true,false,true).timeout.connect(func() -> void:
		if is_instance_valid(ui):
			push_error("V14 watchdog: screen=%s paused=%s phase=%s accepting=%s hp=%d enemy=%d mana=%d selected=%s" % [ui.screen,paused,ui.combat_phase,ui.accepting_answer,state.hp,state.enemy_hp,state.mana,state.selected_spell])
		quit(3))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("V14 UI FAIL: "+message)

func wait(seconds: float) -> void:
	await create_timer(seconds,true).timeout

func shot(name: String) -> void:
	if not graphics or video: return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(directory+"/"+name+".png") == OK,"Save screenshot "+name)

func force(id: String) -> void:
	var intent: Dictionary = Brain.ATTACKS[id].duplicate()
	intent.id = id
	intent.make_read_only()
	state.enemy_intent = intent
	state.intent_consumed = false
	ui.battle_view.update_intent()

func layout() -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(1920,1080))
	if ui.screen == "map":
		check(viewport.encloses(ui.route_view.scroll.get_global_rect()),"Scrollable map fits viewport")
		for button in ui.route_view.nodes.values(): check(Rect2(Vector2.ZERO,ui.route_view.canvas.size).encloses(Rect2(button.position,button.size)),"Map node inside scroll canvas")
	elif ui.screen == "review":
		for button in ui.review_view.buttons: check(viewport.encloses(button.get_global_rect()),"Review answer inside viewport")
	elif ui.screen == "battle":
		for actor in [ui.player_avatar,ui.enemy_avatar]:
			check(actor.uses_texture and is_equal_approx(actor.art.scale.x,actor.art.scale.y),"Formal proportional art")
			var bounds: Rect2 = actor.texture_bounds()
			check(not bounds.intersects(ui.battle_view.spell_card.get_global_rect()),"PNG does not cover word")
			for button in ui.answer_buttons+ui.battle_view.spell_buttons.values(): check(not bounds.intersects(button.get_global_rect()),"PNG clear of answers and skills")
		for control in ui.answer_buttons+[ui.battle_view.intent_label,ui.battle_view.status_label]: check(viewport.encloses(control.get_global_rect()),"Intent, status and answers fit viewport")
		check(ui.battle_view.spell_card.get_parent().z_index > 2,"Word and answer layer protected from attack effects")

func reward(id: String = "") -> void:
	check(ui.screen == "reward","Reward opened")
	var chosen := id if ui.reward_cards.has(id) else str(ui.reward_cards.keys()[0])
	var before: int = state.rewards.size()
	ui._choose_reward(chosen)
	ui._choose_reward(chosen)
	await wait(0.32)
	check(state.rewards.size() == before+1,"Reward double click resolves once")

func enter(id: String) -> void:
	check(ui.screen == "map","Enter from map")
	ui._enter_node(id)
	ui._enter_node(id)
	await wait(2.1 if id in ["elite","boss"] else 0.15)
	check(ui.screen == ("review" if id == "memory" else "battle"),"Node loads correct scene")
	layout()

func attack(id: String, capture_name: String, spell: String = "arcane") -> void:
	force(id)
	ui._select_spell(spell)
	check(state.selected_spell == spell,"Defensive spell is affordable")
	check(ui.battle_view.intent_label.text.contains(str(state.enemy_intent.name)),"UI announces actual attack")
	var promised: Dictionary = state.incoming_preview()
	var announced_text: String = ui.battle_view.intent_label.text
	var before: int = state.questions_answered()
	var before_hp: int = state.hp
	var before_save: int = save.total_answers
	var before_events: int = audio.event_log.size()
	var wrong := (int(ui.current_question.correct_index)+1)%4
	if graphics: tap.clear_buffer()
	ui._on_answer(wrong)
	ui._on_answer(wrong)
	check(ui.battle_view.intent_label.text == announced_text,"Damage preview remains frozen throughout settlement")
	check(state.questions_answered() == before+1 and save.total_answers == before_save+1,"One answer and one Mastery update")
	check(state.hp == maxi(0,before_hp-int(promised.hp_damage)),"Execution equals shown incoming preview")
	await wait(0.46 if id == "shadow_lunge" else (0.58 if id == "judgment" else 0.30))
	if graphics:
		var frames := tap.get_buffer(tap.get_frames_available())
		var peak := 0.0
		for frame in frames: peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		peaks.append(peak)
		check(peak > 0.00001 and peak < 0.95,"Actual enemy audio mix present without clipping")
	var represented := false
	for child in ui.get_children():
		if child.get_script() in [Effect,EnemySpell,ui.Bolt]: represented = true
	check(represented,"Visible attack effect: "+id)
	await shot(capture_name)
	await wait(1.9)
	check(ui.accepting_answer and state.questions_answered() == before+1,"Attack finishes exactly once")
	var events: Array = audio.event_log.slice(before_events)
	var releases := 0
	var impacts := 0
	var hurt := 0
	for event in events:
		if event.event == Profiles.attack(id).cast_sfx: releases += 1
		if event.event == Profiles.attack(id).hit_sfx: impacts += 1
		if event.event == "player_hit": hurt += 1
	check(releases == 1 and impacts == 1 and hurt == (1 if int(promised.hp_damage) > 0 else 0),"Single synchronized release/impact/injury events")
	visuals.append(id)

func win() -> void:
	print("V14 win: ",ui.screen," HP=",state.hp," enemy=",state.enemy_hp," mana=",state.mana," ready=",ui.accepting_answer)
	var guard := 0
	while ui.screen == "battle" and state.enemy_hp > 0 and guard < 25:
		guard += 1
		await ui._on_answer(int(ui.current_question.correct_index))
	check(state.enemy_hp == 0,"Battle won")

func demo() -> void:
	print("V14 demo start")
	ui._start_adventure(true)
	await wait(0.3)
	check(ui.screen == "map","Start Adventure opens map")
	layout()
	await shot("route_map")
	await enter("first")
	await attack("ink_bolt","ink_bolt")
	await attack("shadow_lunge","shadow_lunge","aegis")
	await win()
	await reward("blade")
	check(ui.screen == "map" and state.route.status("memory") == "available" and state.route.status("stacks") == "available","First victory unlocks choice")
	await shot("route_choice")
	await enter("memory")
	await shot("memory_chamber")
	for i in 3:
		var q: Dictionary = state.review.questions[state.review.index]
		await ui._on_review_answer(int(q.correct_index))
	check(state.review_answers == 3 and ui.screen == "map","Review returns to map")
	await enter("elite")
	await attack("paper_slash","paper_slash")
	await attack("ink_mark","ink_mark")
	await shot("ink_status")
	await attack("torn_page","torn_page","aegis")
	print("V14 elite player spells: HP=",state.hp," ready=",ui.accepting_answer)
	# Show all three player spells against the same enemy, with real mana.
	await ui._on_answer(int(ui.current_question.correct_index))
	print("V14 elite Arcane complete: mana=",state.mana," ready=",ui.accepting_answer)
	ui._select_spell("aegis")
	await ui._on_answer(int(ui.current_question.correct_index))
	print("V14 elite Aegis complete: mana=",state.mana," ready=",ui.accepting_answer)
	check(state.barrier == 8,"Aegis full attack and barrier coexist")
	await win()
	await shot("elite_reward_one")
	check(state.rewards_pending == 2,"Elite has two rewards")
	await reward("quill")
	check(ui.screen == "reward" and state.rewards_pending == 1,"Elite second reward shown")
	await shot("elite_reward_two")
	await reward("shield")
	await enter("boss")
	await attack("arcane_tome","arcane_tome")
	await attack("oblivion_mark","oblivion_mark")
	await attack("judgment","judgment","aegis")
	await attack("sealed_pages","sealed_pages")
	var phase_before: int = state.phase_transitions
	while state.enemy_hp > 50:
		ui._select_spell("memory" if state.mana >= 2 else "arcane")
		var right := int(ui.current_question.correct_index)
		ui._on_answer(right)
		await wait(2.1)
	check(state.boss_phase_two and state.phase_transitions == phase_before+1,"Boss Phase II actual threshold")
	await shot("boss_phase_two")
	await win()
	check(ui.screen == "report" and state.run_won,"Demo reaches complete report")
	check(ui.report_snapshot.questions_answered == state.combat_answers+3 and ui.report_snapshot.questions_answered == state.correct_count+state.wrong_count,"Report includes chamber and combat once")
	await shot("adventure_report")

func regression() -> void:
	Engine.time_scale = 20.0
	for second in ["stacks","memory"]:
		for third in ["elite","upper"]:
			ui._start_adventure(true)
			for id in ["first",second,third,"boss"]:
				await enter(str(id))
				if id == "memory":
					for i in 3:
						var before: int = state.questions_answered()
						var q: Dictionary = state.review.questions[state.review.index]
						ui._on_review_answer(int(q.correct_index))
						ui._on_review_answer(int(q.correct_index))
						await wait(1.0)
						check(state.questions_answered() == before+1,"Review duplicate UI click rejected")
				else:
					await win()
					while state.rewards_pending > 0: await reward()
			check(ui.screen == "report" and state.run_won,"UI route reaches final report: "+str(second)+" / "+str(third))
			routes += 1
	ui._start_adventure(true)
	await enter("first")
	force("shadow_lunge")
	ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	await wait(0.18)
	ui.pause_menu.open_menu()
	var frozen: Vector2 = ui.enemy_avatar.pose.position
	var sounds: int = audio.event_log.size()
	var answers: int = state.questions_answered()
	await wait(1.0)
	ui._on_answer(int(ui.current_question.correct_index))
	check(ui.enemy_avatar.pose.position == frozen and audio.event_log.size() == sounds and state.questions_answered() == answers,"Pause freezes lunge, sounds and answer")
	ui.pause_menu.resume()
	await wait(2.0)
	check(ui.accepting_answer and state.questions_answered() == answers,"Resume exactly once")
	force("shadow_lunge")
	ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("title")
	ui.pause_menu.confirm_action()
	await wait(2.5)
	check(ui.screen == "title" and not ui.accepting_answer,"Old attack cannot reopen title")
	ui._start_adventure(true)
	await enter("first")
	state.hp = 1
	force("ink_bolt")
	await ui._on_answer((int(ui.current_question.correct_index)+1)%4)
	check(ui.screen == "report" and not state.run_active and not state.enter_node("memory"),"Death prevents exploration")
	var word := str(ui.current_question.entry.word)
	var mastery: int = save.mastery_of(word)
	save.save_game()
	save.words.clear()
	save.load_game()
	check(save.mastery_of(word) == mastery,"Long-term save reload unchanged")
	ui._start_adventure(true)
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("restart")
	ui.pause_menu.confirm_action()
	check(ui.screen == "difficulty","Restart opens difficulty selection")
	ui._begin_run("normal",true)
	check(ui.screen == "map" and state.route.completed == ["entry"] and state.rewards.is_empty(),"Restart clears map / relics")
	var streams: Dictionary = audio.streams.duplicate()
	audio.streams.clear()
	audio.play_event("judgment_cast")
	audio.streams = streams
	var fallback: Control = load("res://scripts/ui/actor_view.gd").new()
	ui.add_child(fallback)
	fallback.setup("mage","res://assets/characters/missing_v14_test.png",Color.WHITE)
	check(not fallback.uses_texture,"Missing PNG remains procedural fallback")
	fallback.queue_free()
	Engine.time_scale = 1.0

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
	for event in audio.ATTACK_SOUNDS:
		check(audio.streams.has(event),"Optional attack sound loaded: "+str(event))
	if graphics:
		tap = AudioEffectCapture.new()
		tap.buffer_length = 3.0
		AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),tap)
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	check(ui.screen == "title","Title opens normally")
	await demo()
	if not video: await regression()
	audio.stop_all()
	if graphics: AudioServer.remove_bus_effect(AudioServer.get_bus_index("SFX"),AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX"))-1)
	ui.queue_free()
	await process_frame
	await wait(0.2)
	var output := {"passed":failures.is_empty(),"failures":failures,"routes":routes,"attacks":visuals,"graphics":graphics,"video":video,"mixed_peaks":peaks}
	FileAccess.open(directory+("/video.json" if video else ("/graphics.json" if graphics else "/headless.json")),FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("V14 UI: ","PASS" if failures.is_empty() else "FAIL"," | routes=",routes," | attacks=",visuals.size()," | failures=",failures.size()," | graphics=",graphics," | video=",video)
	quit(0 if failures.is_empty() else 1)
