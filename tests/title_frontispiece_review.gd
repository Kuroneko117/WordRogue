extends "res://tests/ui_visual_pass.gd"
## A focused title pilot check, not another complete route simulation.

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
		directory = "res://.local_test/title_frontispiece/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		ui.show_title()
		await wait(0.3)
		var title: Control = ui.get_node("FrontispieceTitle")
		var start: Button = title.find_child("StartAdventure",true,false)
		var settings: Button = title.find_child("TitleSettings",true,false)
		check(start.has_focus(),"Start has native keyboard focus")
		visible_controls(title)
		await shot("title")
		await mouse_click(settings)
		await wait(0.12)
		check(paused and ui.pause_menu.overlay.visible,"Native settings click opens original pause settings")
		ui.pause_menu.resume()
		check(not paused,"Settings close restores title input")
		await mouse_click(start)
		check(ui.screen == "difficulty","Native start click opens existing difficulty screen")
		ui.show_title()
		await process_frame
		await key(KEY_ENTER)
		check(ui.screen == "difficulty","Native Enter activates the default start button")
		ui.show_title()
		await process_frame
		await key(KEY_ESCAPE)
		check(paused and ui.pause_menu.overlay.visible,"ESC remains available on title")
		ui.pause_menu.resume()
		ui.show_title()
		await process_frame
		var quit_button: Button = ui.find_child("TitleQuit",true,false)
		await mouse_click(quit_button)
		check(paused and ui.pause_menu.overlay.visible,"Quit opens existing confirmation before exit")
		ui.pause_menu.resume()
	# The view has a native matte fallback when its optional illustration is absent.
	ui.show_title()
	ui.get_node("FrontispieceTitle").queue_free()
	await process_frame
	var fallback: Control = load("res://scripts/ui/frontispiece_title.gd").new()
	fallback.host = ui
	fallback.illustration_path = "res://assets/backgrounds/missing_title_test.jpg"
	ui.add_child(fallback)
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	check(fallback.find_child("LibraryFrontispiece",true,false) == null,"Missing optional art uses matte fallback")
	check(fallback.find_child("StartAdventure",true,false) is Button,"Missing art retains native start button")
	audio.stop_all()
	print("TITLE FRONTISPIECE checks=",checks," failures=",failures.size()," screenshots=",captured.size())
	quit(0 if failures.is_empty() else 1)
