extends SceneTree
## Focused, real renderer fixture. Uses a sandboxed learning profile only.
const Enemies = preload("res://scripts/enemy_definitions.gd")
var ui: Control
var state: Node
var checks := 0
var failures: Array[String] = []
var directory := ""
var captured: Array[String] = []

func _initialize() -> void: call_deferred("run")
func wait(seconds: float) -> void: await create_timer(seconds,true).timeout
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func fixture(id: String) -> void:
	ui._begin_run("normal"); ui._enter_node("first")
	state.battle_enemy = Enemies.ENEMIES[id].duplicate(); state.battle_enemy.id = id
	state.battle_index = 3 if id == "librarian" else (2 if Enemies.ENEMIES[id].kind == "elite" else 0)
	state.enemy_hp = int(state.current_enemy().hp)
	state.momentum.reset(state.battle_enemy)
	state.intent_consumed = true; state.enemy_intent = {}
	ui.show_battle()

func shot(name: String) -> void:
	await wait(0.28); await process_frame; await process_frame
	RenderingServer.force_draw(false)
	var file := directory+"/"+name+".png"
	check(root.get_texture().get_image().save_png(file) == OK,"Capture "+file)
	captured.append(file)

func layout(node: Node) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree():
			if child is Label or child is Button or child is ProgressBar or child is PanelContainer:
				check(Rect2(Vector2.ZERO,ui.size).encloses(child.get_global_rect()),"Fits viewport "+str(child.name)+" "+str(child.get_global_rect()))
				if child is Label: check(child.size.y+2 >= child.get_minimum_size().y,"Text height "+child.text)
			layout(child)

func actor_layout() -> void:
	for actor in [ui.player_avatar,ui.enemy_avatar]:
		check(actor.uses_texture,"Approved artwork loaded")
		check(is_equal_approx(actor.art.scale.x,actor.art.scale.y),"Artwork aspect preserved")
		check(Rect2(Vector2.ZERO,ui.size).encloses(actor.texture_bounds()),"Full artwork in viewport")
		for control in ui.answer_buttons+ui.battle_view.spell_buttons.values()+[ui.battle_view.spell_card,ui.player_bar,ui.enemy_bar,ui.battle_view.intent_label,ui.battle_view.momentum_view]:
			check(not actor.texture_bounds().intersects(control.get_global_rect()),"Artwork clear of "+str(control.name))

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test") or DisplayServer.get_name() == "headless": quit(2); return
	state = root.get_node("GameState")
	ui = load("res://scenes/main.tscn").instantiate(); root.add_child(ui)
	var pass_id := "pilot" if "--pilot" in OS.get_cmdline_user_args() else "final"
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		directory = "res://.local_test/battle_grimoire/"+pass_id+"/"+str(resolution.x)+"x"+str(resolution.y)
		DirAccess.make_dir_recursive_absolute(directory)
		fixture("lantern_wisp")
		await wait(0.3); layout(ui.battle_view); actor_layout(); await shot("battle")
		state.momentum.value = state.momentum.threshold; state.intent_consumed = true; state.prepare_intent()
		state.mana = 3; ui._select_spell("aegis"); ui.battle_view.update_spells(true)
		await wait(0.1); layout(ui.battle_view); actor_layout(); await shot("charge_guard")
		check(ui.battle_view.momentum_view.alert and ui.battle_view.danger_label.text.contains("不可打断"),"Charge warning preserved")
		if pass_id == "pilot": continue
		for id in ["marginalia","silent_archivist","librarian"]:
			fixture(id); await wait(0.25); layout(ui.battle_view); actor_layout(); await shot(id)
		state.boss_phase_two = true
		ui.battle_view.update_status()
		ui.battle_view.reset_answer(0,"n. 独立自主者；无党派者；独立支持者")
		ui.battle_view.reset_answer(1,"vt. 区分；辨别；使具有某种特色")
		ui.feedback_label.text = "答错了 · 正确释义：n. 独立自主者；无党派者"
		await wait(0.15); layout(ui.battle_view); actor_layout(); await shot("long_text_phase_two")
		fixture("ink_wraith"); state.mana = 3
		var wrong: int = (int(ui.current_question.correct_index)+1)%4
		ui._on_answer(wrong); ui._on_answer(wrong)
		await shot("wrong_answer"); layout(ui.battle_view)
		await wait(1.8)
		check(ui.accepting_answer,"Wrong feedback recovers to next question")
	# Explicit missing image fallback on a separate actor, no asset deletion.
	var actor = load("res://scripts/ui/actor_view.gd").new()
	root.add_child(actor); actor.setup("paper_golem","res://assets/enemies/missing_for_test.png",Color.WHITE)
	check(not actor.uses_texture,"Procedural actor fallback remains")
	actor.queue_free()
	var skin = load("res://scripts/ui/battle_theme.gd")
	for file in ["parchment_scroll.png","answer_scroll.png","gothic_frame.svg"]:
		var path: String = skin.ROOT+file
		var original: Variant = skin.textures.get(path)
		skin.textures[path] = null
		check(skin.parchment("normal",file == "answer_scroll.png") != null if file != "gothic_frame.svg" else skin.frame() != null,"Missing UI texture falls back: "+file)
		skin.textures[path] = original
	root.get_node("AudioBus").stop_all()
	print("BATTLE GRIMOIRE ",pass_id,": checks=",checks," failures=",failures.size()," captures=",captured.size())
	quit(0 if failures.is_empty() else 1)
