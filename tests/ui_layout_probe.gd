extends SceneTree

func _initialize() -> void: call_deferred("run")

func dump(node: Node, indent: String = "") -> void:
	if node is Control:
		print(indent,node.get_class()," ",node.get_script().resource_path if node.get_script() else ""," rect=",node.get_rect()," min=",node.get_combined_minimum_size())
	if indent.length() < 8:
		for child in node.get_children(): dump(child,indent+" ")

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	var ui: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	ui._begin_run("normal"); ui._enter_node("first")
	await create_timer(0.5).timeout
	dump(ui.battle_view)
	root.get_texture().get_image().save_png("res://.local_test/ui_pass/layout_probe.png")
	root.get_node("AudioBus").stop_all()
	quit()
