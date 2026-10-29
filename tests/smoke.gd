extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("SMOKE FAIL: " + description)

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		push_error("Set WORDROGUE_TEST_PROFILE=1 and isolate APPDATA before running this smoke test.")
		quit(2)
		return
	Engine.time_scale = 20.0
	# Headless accelerated gameplay is separate from native audio validation.
	# --with-music retains the diagnostic case for the known exit warning.
	if DisplayServer.get_name() == "headless" and not OS.get_cmdline_user_args().has("--with-music"):
		root.get_node("AudioBus").music_streams.clear()
	var save: Node = root.get_node("SaveData")
	var bank: Node = root.get_node("WordBank")
	var state: Node = root.get_node("GameState")
	save.words.clear()
	save.save_game()
	_check(bank.entries.size() >= 100, "At least 100 valid words load")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame
	_check(ui.get_child_count() > 0, "Title UI loads")
	ui._start_adventure(true)
	_check(ui.screen == "map", "Adventure starts at route map")
	ui._enter_node("first")
	_check(state.battle_index == 0 and state.enemy_hp == 50 and state.hp == 100, "First battle starts")
	var first_word: String = str(ui.current_question["entry"]["word"])
	var wrong_index: int = (int(ui.current_question["correct_index"]) + 1) % 4
	var expected_first_hp: int = 100-int(state.incoming_preview().hp_damage)
	await ui._on_answer(wrong_index)
	_check(state.hp == expected_first_hp and state.combo == 0, "Wrong answer follows intent and resets combo")
	_check(save.mastery_of(first_word) == 40, "Wrong answer lowers Mastery")
	var route := ["blade", "shield", "quill"]
	for battle in 4:
		_check(state.battle_index == battle, "Battle index %d" % battle)
		var guard := 0
		while state.enemy_hp > 0 and state.hp > 0 and guard < 30:
			guard += 1
			var q: Dictionary = ui.current_question
			var options: Array = q["options"]
			_check(options.size() == 4, "Four options")
			var unique := {}
			for option in options:
				unique[option] = true
			_check(unique.size() == 4 and options[int(q["correct_index"])] == q["entry"]["meaning"], "Unique options with correct meaning")
			await ui._on_answer(int(q["correct_index"]))
		_check(state.enemy_hp == 0, "Battle %d can be won" % battle)
		if battle < 3:
			_check(ui.reward_locked == false, "Reward screen appears")
			var chosen: String = str(route[battle]) if ui.reward_cards.has(route[battle]) else str(ui.reward_cards.keys()[0])
			await ui._choose_reward(chosen)
			if battle == 2: await ui._choose_reward(str(ui.reward_cards.keys()[0]))
			_check(ui.screen == "map", "Reward returns to map")
			ui._enter_node(["stacks","elite","boss"][battle])
			if battle >= 1:
				await create_timer(2.0).timeout
			_check(state.battle_index == battle + 1, "Reward advances battle")
			if battle == 2:
				var weak_hits := 0
				var no_recent: Array[String] = []
				for sample in 150:
					var boss_question: Dictionary = bank.make_question(3, no_recent, state.seen_words)
					_check(state.seen_words.has(str(boss_question["entry"]["word"])), "Boss samples encountered words")
					if str(boss_question["entry"]["word"]) == first_word:
						weak_hits += 1
				_check(weak_hits > 0, "Previously missed word recurs in Boss sample")
	_check(state.run_won and not state.run_active, "Boss victory finishes run")
	_check(ui.report_snapshot["questions_answered"] == state.correct_count + state.wrong_count, "Victory report counts answered questions")
	_check(ui.report_snapshot["unique_words"] == state.seen_words.size(), "Victory report counts unique words")
	_check(state.seen_words.has(first_word), "Wrong word recorded for Boss pool")
	_check(save.words.has(first_word), "Learning data persisted in memory")
	_check(ui.get_child_count() > 0, "Report UI loads")
	var previous_mastery: int = save.mastery_of(first_word)
	ui._start_adventure(true)
	ui._enter_node("first")
	_check(state.battle_index == 0 and state.hp == 100 and state.combo == 0 and state.rewards.is_empty(), "Play Again resets run state")
	_check(save.mastery_of(first_word) == previous_mastery, "Play Again retains Mastery")
	state.hp = 5
	wrong_index = (int(ui.current_question["correct_index"]) + 1) % 4
	await ui._on_answer(wrong_index)
	_check(state.hp == 0 and not state.run_active and not ui.accepting_answer, "Death ends battle and locks answering")
	_check(ui.screen == "report" and ui.report_snapshot["wrong"] == 1, "Failure report uses run counts")
	ui.pause_menu.open_menu()
	ui.pause_menu.resume()
	_check(ui.screen == "report", "ESC on report preserves report")
	# Duplicate clicks and paused animations must never resolve twice.
	ui._start_adventure(true)
	ui._enter_node("first")
	await process_frame
	await process_frame
	for button in ui.answer_buttons:
		_check(button.get_global_rect().end.y <= 1080 and button.get_global_rect().end.x <= 1920, "Answers remain inside design viewport")
	var fallback: Control = load("res://scripts/ui/actor_view.gd").new()
	ui.add_child(fallback)
	fallback.setup("mage","res://assets/characters/intentionally_missing_test.png",Color.WHITE)
	_check(not fallback.uses_texture, "Missing PNG uses procedural actor fallback")
	fallback.queue_free()
	var audio: Node = root.get_node("AudioBus")
	var saved_streams: Dictionary = audio.streams.duplicate()
	audio.streams.erase("correct")
	var before_missing: int = int(audio.event_counts.get("correct",0))
	audio.play_event("correct")
	_check(int(audio.event_counts.get("correct",0)) == before_missing + 1, "Missing audio is silently skipped")
	audio.streams = saved_streams
	var correct_index: int = int(ui.current_question["correct_index"])
	var sound_before: int = int(audio.event_counts.get("correct",0))
	ui._on_answer(correct_index)
	ui._on_answer(correct_index)
	_check(state.correct_count == 1 and state.combo == 1, "Correct result settles once")
	_check(int(audio.event_counts.get("correct",0)) == sound_before + 1, "Correct sound event emitted once")
	ui.pause_menu.open_menu()
	var frozen_pose: Vector2 = ui.player_avatar.pose.position
	var frozen_question: String = str(ui.current_question["entry"]["word"])
	await create_timer(1.5,true).timeout
	ui._on_answer(correct_index)
	_check(state.correct_count == 1 and ui.player_avatar.pose.position == frozen_pose, "Pause freezes answer and animation")
	_check(str(ui.current_question["entry"]["word"]) == frozen_question, "Paused delay cannot advance question")
	ui.pause_menu.resume()
	await create_timer(2.0,true).timeout
	_check(ui.accepting_answer and state.correct_count == 1, "Continue resumes animation exactly once")
	wrong_index = (int(ui.current_question["correct_index"]) + 1) % 4
	var expected_duplicate_hp: int = state.hp-int(state.incoming_preview().hp_damage)
	ui._on_answer(wrong_index)
	ui._on_answer(wrong_index)
	_check(state.wrong_count == 1 and state.hp == expected_duplicate_hp and state.combo == 0, "Wrong result settles once")
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("restart")
	_check(state.wrong_count == 1 and paused, "Restart requires confirmation")
	ui.pause_menu.confirm_action()
	_check(ui.screen == "difficulty", "Restart offers a fresh difficulty choice")
	ui._begin_run("normal",true)
	await create_timer(3.0,true).timeout
	_check(state.questions_answered() == 0 and state.hp == 100 and ui.screen == "map", "Restart cancels old delayed callbacks")
	ui._enter_node("first")
	ui._on_answer(int(ui.current_question["correct_index"]))
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("title")
	ui.pause_menu.confirm_action()
	await create_timer(3.0,true).timeout
	_check(ui.screen == "title" and not ui.accepting_answer, "Return to title cancels pending combat")
	ui.pause_menu.open_menu()
	ui.pause_menu.resume()
	ui._start_adventure(true)
	ui._enter_node("first")
	_check(ui.screen == "battle" and state.questions_answered() == 0, "Title can start again after pause and return")
	state.battle_index = 3
	state.start_battle()
	ui.show_encounter_intro()
	var fabricated_hint := false
	for child in ui.get_children():
		if child is Label and child.text.contains("本局错词"):
			fabricated_hint = true
	_check(not fabricated_hint, "Perfect run does not fabricate Boss mistake list")
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("title")
	ui.pause_menu.confirm_action()
	await create_timer(2.5,true).timeout
	_check(ui.screen == "title", "Old Boss intro cannot reopen battle after return")
	# A deterministic missed-word example verifies targeting and truthful tags.
	var no_recent_words: Array[String] = []
	var excluded: Array[String] = ["maintain"]
	save.words["maintain"] = {"mastery": 85, "correct_count": 8, "wrong_count": 1, "encounter_count": 9}
	bank.rng.seed = 20261008
	var targeted := 0
	for sample in 200:
		var q: Dictionary = bank.make_question(3,no_recent_words,{"maintain":true},{"maintain":1})
		if q["entry"]["word"] == "maintain":
			targeted += 1
			_check(q["missed_this_run"] and not q["weak_word"], "Missed label is separate from low Mastery label")
		var excluded_q: Dictionary = bank.make_question(3,excluded,{"maintain":true},{"maintain":1})
		_check(excluded_q["entry"]["word"] != "maintain", "Boss excludes recent word even if missed")
	_check(targeted >= 120, "Boss strongly prefers true run mistakes")
	var ordinary: Dictionary = bank.make_question(2,no_recent_words,{},{})
	_check(ordinary["weak_word"] == (save.mastery_of(str(ordinary["entry"]["word"])) < 50), "Elite weak marker agrees with Mastery")
	# Directly verify each relic's effect with controlled state.
	state.start_run(true)
	state.take_reward("crystal")
	state.hp = 80
	for i in 3:
		state.enemy_hp = 100
		state.resolve_answer("maintain", true)
	_check(state.hp == 83, "Memory Crystal heals once at combo 3")
	state.enemy_hp = 100
	state.resolve_answer("maintain", true)
	_check(state.hp == 83, "Memory Crystal does not heal again at combo 4")
	state.take_reward("flame")
	state.enemy_hp = 100
	var flame: Dictionary = state.resolve_answer("maintain", true)
	_check(int(flame["damage"]) == 20, "Combo Flame boosts combo 5 damage")
	state.take_reward("tome")
	save.words["abandon"] = {"mastery": 20, "correct_count": 0, "wrong_count": 1, "encounter_count": 1}
	state.enemy_hp = 100
	var tome: Dictionary = state.resolve_answer("abandon", true)
	_check(int(tome["damage"]) == 26, "Beginner's Tome adds damage before flame")
	state.take_reward("shield")
	state.hp = 80
	state.enemy_hp = 100
	var shielded: Dictionary = state.resolve_answer("abandon", false)
	_check(bool(shielded["shielded"]) and state.hp == 80, "Scholar Shield blocks first mistake")
	state.enemy_hp = 100
	state.prepare_intent()
	var expected_after_shield: int = state.hp-int(state.incoming_preview().hp_damage)
	state.resolve_answer("abandon", false)
	_check(state.hp == expected_after_shield, "Scholar Shield only blocks once")
	state.take_reward("quill")
	state.hp = 95
	state.finish_battle()
	_check(state.hp == 100, "Healing Quill caps at max HP")
	_check(state.base_attack == 10, "Fresh run base attack reset")
	state.take_reward("blade")
	_check(state.base_attack == 13, "Word Blade increases base attack")
	save.words["maintain"]["mastery"] = 99
	save.record_answer("maintain", true)
	_check(save.mastery_of("maintain") == 100, "Mastery upper bound")
	save.words["maintain"]["mastery"] = 1
	save.record_answer("maintain", false)
	_check(save.mastery_of("maintain") == 0, "Mastery lower bound")
	save.save_game()
	save.words.clear()
	save.load_game()
	_check(save.words.has(first_word), "Save can be reloaded from disk")
	print("SMOKE RESULT: ", "PASS" if failures.is_empty() else "FAIL", " | words=", bank.entries.size(), " | failures=", failures.size())
	Engine.time_scale = 1.0
	# Match the real quit menu's audio grace period after accelerated tests.
	audio.stop_all()
	ui.queue_free()
	audio.music_player.queue_free()
	await create_timer(0.25,true,false,true).timeout
	quit(0 if failures.is_empty() else 1)
