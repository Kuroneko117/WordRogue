extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"):
		quit(2)
		return
	var ui: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	ui._start_adventure()
	await create_timer(0.7).timeout
	ui.pause_menu.open_menu()
	ui.pause_menu.request_action("quit")
	if not paused or ui.pause_menu.pending_action != "quit":
		quit(1)
		return
	print("QUIT MENU: confirmation shown; confirming normal shutdown")
	ui.pause_menu.confirm_action()
