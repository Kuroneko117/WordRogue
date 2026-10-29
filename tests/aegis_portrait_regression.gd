extends "res://tests/whole_ui_visual.gd"
## Regression: spell selection and intent notes must not resize combat portraits.
func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	state = root.get_node("GameState")
	audio = root.get_node("AudioBus")
	save = root.get_node("SaveData")
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	var pass_name := "before" if "--before-fix" in OS.get_cmdline_user_args() else "after"
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/aegis_portrait/"+pass_name+"/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		for id in ["ink_wraith","marginalia","librarian"]:
			fixture(id)
			state.mana = 3
			ui.battle_view.update_spells(true)
			ui.enemy_avatar.idle_enabled = false
			ui.player_avatar.idle_enabled = false
			await wait(0.15)
			var size_before: Vector2 = ui.enemy_avatar.size
			var scale_before: float = ui.enemy_avatar._base_scale()
			var note_before: Vector2 = ui.battle_view.intent_label.size
			if id == "ink_wraith": await shot("arcane_selected")
			await key(KEY_W)
			await wait(0.15)
			print("AEGIS SCALE ",resolution," ",id," actor=",size_before," -> ",ui.enemy_avatar.size," base=",scale_before," -> ",ui.enemy_avatar._base_scale()," intent=",note_before," -> ",ui.battle_view.intent_label.size)
			check(state.selected_spell == "aegis","Native W selects guard "+id)
			check(ui.enemy_avatar.size.is_equal_approx(size_before),"Guard keeps enemy layout size "+id)
			check(is_equal_approx(ui.enemy_avatar._base_scale(),scale_before),"Guard keeps enemy portrait scale "+id)
			check(ui.battle_view.status_label.text.contains("减伤30%"),"Guard explanation remains visible in player status "+id)
			if id == "ink_wraith": await shot("aegis_selected")
			await key(KEY_Q)
			await wait(0.1)
			check(ui.enemy_avatar.size.is_equal_approx(size_before),"Switch back keeps enemy size "+id)
			check(ui.enemy_avatar.pose.scale.is_equal_approx(Vector2.ONE),"Selection never shrinks the animated pose "+id)
			if id == "ink_wraith" and resolution.x == 1280 and pass_name == "after":
				for cast_index in 2:
					# Each new question intentionally resets spell selection to Arcane.
					await key(KEY_W)
					var mana_before: int = state.mana
					ui._on_answer(int(ui.current_question.correct_index))
					await wait(1.4)
					check(ui.accepting_answer and state.barrier > 0,"Guard cast completes with shield")
					check(state.mana == mana_before-1,"Repeated cast actually uses guard mana")
					check(ui.enemy_avatar.size.is_equal_approx(size_before) and is_equal_approx(ui.enemy_avatar._base_scale(),scale_before),"Repeated guard casts keep original enemy scale")
				state.ink_active = true
				await key(KEY_W)
				await wait(0.12)
				check(ui.battle_view.status_label.text.contains("墨蚀") and ui.battle_view.status_label.text.contains("减伤30%"),"Combined ink and guard status stays visible")
				check(ui.enemy_avatar.size.is_equal_approx(size_before),"Combined status does not reflow enemy")
	audio.stop_all()
	print("AEGIS PORTRAIT checks=",checks," failures=",failures.size()," screenshots=",captured.size())
	quit(0 if failures.is_empty() else 1)
