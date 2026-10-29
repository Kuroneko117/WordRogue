extends "res://tests/whole_ui_visual.gd"
## Focused UI regression after the first all-page capture; no balance simulations.
func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	state = root.get_node("GameState")
	audio = root.get_node("AudioBus")
	save = root.get_node("SaveData")
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/quiet_flow/final/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		for id in ["ink_wraith","marginalia","librarian"]:
			fixture(id)
			await wait(0.12)
			visible_controls(ui)
			battle_layout(id)
			await shot("battle_"+id)
		state.momentum.value = state.momentum.threshold
		state.intent_consumed = true
		state.prepare_intent()
		ui.battle_view.update_spells(true)
		check(ui.battle_view.momentum_view.alert,"Momentum still warns on the original threshold")
		await shot("battle_ultimate_warning")
	DisplayServer.window_set_size(Vector2i(1280,720))
	directory = "res://.local_test/quiet_flow/final/1280x720"
	ui.show_title()
	await wait(0.15)
	await key(KEY_ENTER)
	check(ui.screen == "difficulty","Default title Enter enters original difficulty")
	await key(KEY_ENTER)
	check(ui.screen == "map","Recommended difficulty enters original route")
	await wait(0.15)
	await mouse_click(ui.route_view.nodes.first)
	check(ui.screen == "battle","Native map icon enters battle")
	await wait(0.15)
	await key(KEY_W)
	check(state.selected_spell == "aegis","W selects original Aegis")
	var before: int = save.total_answers
	var enemy_before: int = state.enemy_hp
	var correct: int = ui.current_question.correct_index
	await mouse_click(ui.answer_buttons[correct])
	await mouse_click(ui.answer_buttons[correct])
	check(save.total_answers == before+1 and state.combo == 1,"Double native correct click settles once and increases combo")
	check(state.enemy_hp < enemy_before and state.barrier > 0,"Original damage and guard effects remain")
	await shot("correct_feedback")
	await wait(1.2)
	check(ui.accepting_answer,"Attack animation returns to answer state")
	state.mana = 3
	await key(KEY_E)
	check(state.selected_spell == "memory","E selects original memory spell")
	await key(KEY_Q)
	check(state.selected_spell == "arcane","Q selects original arcane spell")
	state.barrier = 0
	var hp_before: int = state.hp
	before = save.total_answers
	var wrong: int = (int(ui.current_question.correct_index)+1)%4
	await mouse_click(ui.answer_buttons[wrong])
	await mouse_click(ui.answer_buttons[wrong])
	check(save.total_answers == before+1 and state.combo == 0,"Double native wrong click settles once and resets combo")
	await shot("wrong_feedback")
	await wait(1.8)
	check(state.hp < hp_before,"Original enemy counter damages player")
	await key(KEY_ESCAPE)
	check(paused,"ESC pauses the game")
	var snapshot := [state.hp,state.enemy_hp,save.total_answers,ui.screen_epoch]
	ui._on_answer(wrong)
	await wait(0.15)
	check(snapshot == [state.hp,state.enemy_hp,save.total_answers,ui.screen_epoch],"Paused answer cannot change state")
	ui.pause_menu.open_settings()
	var music_before: float = audio.music_percent
	var sfx_before: float = audio.sfx_percent
	ui.pause_menu.sliders.music.value = 0
	ui.pause_menu.sliders.sfx.value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Existing separate volume sliders mute both buses")
	audio.load_settings()
	check(audio.music_percent == 0 and audio.sfx_percent == 0,"Existing settings persist in isolated profile")
	ui.pause_menu.sliders.music.value = music_before
	ui.pause_menu.sliders.sfx.value = sfx_before
	ui.pause_menu.resume()
	check(not paused,"Resume restores the existing game tree")
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("title")
	check(paused and ui.pause_menu.pending_action == "title","Return to title requests confirmation")
	ui.pause_menu.confirm_action()
	check(not paused and ui.screen == "title","Confirmed return shows new title")
	ui._begin_run("normal")
	check(ui.screen == "map" and state.rewards.is_empty(),"Restart keeps route and clears temporary rewards")
	fixture()
	state.enemy_hp = 0
	state.finish_battle()
	ui.show_reward()
	await wait(0.15)
	var reward_id: String = str(ui.reward_cards.keys()[0])
	ui._choose_reward(reward_id)
	ui._choose_reward(reward_id)
	check(ui.reward_locked and state.reward_claims == 1,"Reward cannot be claimed twice")
	await wait(0.35)
	check(ui.screen == "map","Selected reward returns to route")
	ui.return_to_title()
	audio.stop_all()
	print("QUIET FLOW input/capture checks=",checks," failures=",failures.size()," screenshots=",captured.size())
	quit(0 if failures.is_empty() else 1)
