extends SceneTree
var ui: Control
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func wait(seconds: float) -> void: await create_timer(seconds,true).timeout
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at; event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event,true)
		await process_frame
func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui)
	var state := root.get_node("GameState")
	var save := root.get_node("SaveData")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		ui._begin_run("normal"); ui._enter_node("first")
		await wait(0.3)
		await click(ui.battle_view.spell_buttons.aegis)
		check(state.selected_spell == "aegis" and state.mana == 1,"Native mouse selects guard without spending mana")
		var correct: int = ui.current_question.correct_index
		var button: Button = ui.answer_buttons[correct]
		button.grab_focus()
		check(root.gui_get_focus_owner() == button,"Answer retains keyboard focus")
		var before: int = save.total_answers
		await click(button); await click(button)
		check(save.total_answers == before+1,"Native mouse double click settles once")
		check(button.get_meta("answer_visual_state") == "correct","Correct scroll state applied")
		ui.pause_menu.open_menu()
		var frozen: float = ui.player_avatar.pose.position.x
		await wait(0.3)
		check(is_equal_approx(frozen,ui.player_avatar.pose.position.x) and paused,"Native pause stops battle pose")
		ui.pause_menu.resume(); await wait(1.5)
		check(ui.accepting_answer and state.barrier == 8,"Guard animation completes and retains eight shield")
		var answer: Button = ui.answer_buttons[0]
		var move := InputEventMouseMotion.new()
		move.position = answer.get_global_rect().get_center(); move.global_position = move.position
		root.push_input(move,true)
		await wait(0.2); RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://.local_test/battle_grimoire/final/"+str(resolution.x)+"x"+str(resolution.y)+"/answer_hover.png")
		check(answer.is_hovered(),"Native scroll hover")
	root.get_node("AudioBus").stop_all()
	print("BATTLE INPUT: checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
