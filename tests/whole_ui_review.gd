extends "res://tests/ui_visual_pass.gd"
## Focused recheck after the one full route run: affected pages and long lists.
func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	state = root.get_node("GameState"); audio = root.get_node("AudioBus"); save = root.get_node("SaveData")
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/whole_ui/final/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		ui.show_difficulty(); await wait(0.2); visible_controls(ui); await shot("difficulty")
		fixture(); state.enemy_hp = 0; state.finish_battle(); ui.show_reward()
		await wait(0.2); visible_controls(ui); await shot("reward")
		event_fixture("chest"); state.hp = 10; ui.show_event(); await wait(0.2); visible_controls(ui); await shot("event_disabled_cost")
		event_fixture("dictionary"); ui._event_action("review"); await wait(0.2); visible_controls(ui); await shot("event_quiz")
		fixture(); state.run_won = true
		# UI stress fixture: five long words in each column; not a second playthrough.
		for word in ["approximately","circumstance","distinguish","responsibility","independent"]:
			state.seen_words[word] = true
		ui.show_report()
		var lists := ui.find_children("*WordsScroll","ScrollContainer",true,false)
		for list in lists:
			var content: VBoxContainer = list.get_child(0)
			for child in content.get_children(): content.remove_child(child); child.queue_free()
			for i in 8:
				var label := Label.new(); label.text = "responsibility    35 → 70" if list.name == "ImprovedWordsScroll" else "approximately    掌握度 25"
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.add_theme_color_override("font_color",Color("#38291f")); label.add_theme_font_size_override("font_size",28)
				content.add_child(label)
		await wait(0.2); visible_controls(ui); await shot("report_long_lists")
		check(lists.size() == 2,"Two independent word scrolls")
		for list in lists:
			list.scroll_vertical = 100
			await process_frame
			check(list.scroll_vertical > 0,"Long list actually scrolls")
		await shot("report_scrolled")
		ui.pause_menu.open_menu(); ui.pause_menu.open_settings(); await wait(0.15); visible_controls(ui.pause_menu.overlay); await shot("settings")
		ui.pause_menu.resume()
	audio.stop_all()
	print("WHOLE UI focused: checks=",checks," failures=",failures.size()," captures=",captured.size())
	quit(0 if failures.is_empty() else 1)
