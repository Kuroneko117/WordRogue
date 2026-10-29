extends SceneTree
const Presentation = preload("res://scripts/ui/archive_reward_style.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	var ui: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	ui._begin_run("normal"); ui._enter_node("first")
	var state := root.get_node("GameState")
	var before: Array = state.REWARDS.duplicate(true)+state.Catalog.EXTRA.duplicate(true)
	var tiers: Dictionary = {}
	for item in before:
		var data := Presentation.describe(item)
		tiers[str(data.name)] = true
	if tiers.size() != 4: push_error("Missing reward visual tier"); quit(1); return
	if before != state.REWARDS+state.Catalog.EXTRA: push_error("Presentation mutated gameplay catalog"); quit(1); return
	state.enemy_hp = 0; state.finish_battle(); ui.show_reward()
	await create_timer(0.35).timeout
	for panel in ui.reward_cards.values():
		if not Rect2(Vector2.ZERO,ui.size).encloses(panel.get_global_rect()): push_error("Reward outside viewport"); quit(1); return
	root.get_texture().get_image().save_png("res://.local_test/ui_pass/1280x720/reward.png")
	root.get_node("AudioBus").stop_all()
	print("Reward surfaces PASS: four display tiers; gameplay catalog unchanged; cards fit viewport")
	quit()
