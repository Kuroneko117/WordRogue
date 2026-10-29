extends "res://scripts/ui/screen_base.gd"

const BattleView = preload("res://scripts/ui/battle_view.gd")
const PauseView = preload("res://scripts/ui/pause_menu.gd")
const Backdrop = preload("res://scripts/ui/library_backdrop.gd")
const Bolt = preload("res://scripts/ui/magic_bolt.gd")
const Burst = preload("res://scripts/ui/magic_burst.gd")
const SpellEffect = preload("res://scripts/ui/spell_effect.gd")
const RouteView = preload("res://scripts/ui/route_view.gd")
const ReviewView = preload("res://scripts/ui/review_view.gd")
const EnemyPresentation = preload("res://scripts/enemy_presentation.gd")
const EnemyEffect = preload("res://scripts/ui/enemy_effect.gd")
const EventView = preload("res://scripts/ui/event_view.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")
const PlatformUI = preload("res://scripts/ui/platform_ui.gd")
const QuietStyle = preload("res://scripts/ui/quiet_style.gd")
var visual_profile_key := "title_map"
var active_background_path := ""
var event_view: Control
@export_range(0.0,0.6) var background_shade := 0.30
@export_file("*.png","*.jpg","*.jpeg") var background_path := "res://assets/backgrounds/library_battle.png"
enum CombatPhase { INACTIVE, WAITING, RESOLVING, ANIMATING, ENEMY_DEAD, PLAYER_DEAD, FINISHED }

var screen := "title"
var combat_phase := CombatPhase.INACTIVE
var screen_epoch := 0
var active_tweens: Array[Tween] = []
var pause_menu: CanvasLayer
var battle_view: Control
var report_snapshot: Dictionary = {}
var shield_aura: Node2D
var presentation_events: Array[Dictionary] = []
var route_view: Control
var review_view: Control
var phase_aura: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_window().title = "遗忘书塔 · WordRogue"
	ui_font = PlatformUI.font()
	get_tree().quit_on_go_back = false
	theme = Kit.make_theme(ui_font)
	pause_menu = PauseView.new()
	add_child(pause_menu)
	pause_menu.setup(self)
	show_title()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(pause_menu):
		pause_menu.back()
	elif what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(pause_menu):
		SaveData.save_game()
		AudioBus.save_settings()
		if not pause_menu.overlay.visible: pause_menu.open_menu()

func _clear_screen() -> void:
	screen_epoch += 1
	AudioBus.stop_effects()
	accepting_answer = false
	combat_phase = CombatPhase.INACTIVE
	for tween in active_tweens:
		if tween.is_valid(): tween.kill()
	active_tweens.clear()
	for child in get_children():
		if child == pause_menu: continue
		remove_child(child)
		child.queue_free()
	_background()

func _prepare_scene(key: String, quiet: bool = false) -> void:
	visual_profile_key = key
	AudioBus.set_scene_music(str(Profiles.scene(key).music),quiet)

func _background() -> void:
	var background: Control
	var profile := Profiles.scene(visual_profile_key)
	active_background_path = ""
	if background_path != "res://assets/backgrounds/library_battle.png":
		if ResourceLoader.exists(background_path): active_background_path = background_path
	else:
		for filename in profile.backgrounds:
			var path := "res://assets/backgrounds/"+str(filename)
			if ResourceLoader.exists(path):
				active_background_path = path
				break
	if not active_background_path.is_empty():
		var image := TextureRect.new()
		image.texture = load(active_background_path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.material = QuietStyle.backdrop_material()
		background = image
	else:
		background = Backdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.03,0.06,clampf(background_shade+float(profile.shade)-0.30,0.0,0.65))
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var chrome := preload("res://scripts/ui/library_chrome.gd").new()
	add_child(chrome)
	_label(self,"遗忘书塔  /  WORDROGUE",Vector2(84,24),Vector2(1750,40),18,QuietStyle.MUTED,HORIZONTAL_ALIGNMENT_LEFT)

func _fx() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	active_tweens.append(tween)
	return tween

func _wait(seconds: float, epoch: int) -> bool:
	await get_tree().create_timer(seconds,false).timeout
	return epoch == screen_epoch

func show_title() -> void:
	_prepare_scene("title_map",true)
	super.show_title()
	screen = "title"

func _start_adventure(legacy_route: bool = false) -> void:
	if get_tree().paused: return
	if not legacy_route:
		show_difficulty()
		return
	_begin_run("normal",true)

func _begin_run(mode_id: String, legacy_route: bool = false, classic: bool = false) -> void:
	if get_tree().paused or not GameState.start_run(legacy_route,mode_id,classic):
		if not get_tree().paused: _label(self,WordBank.load_error,Vector2(450,890),Vector2(1020,60),23,RED,HORIZONTAL_ALIGNMENT_CENTER)
		return
	recent_words.clear()
	show_map()

func show_difficulty() -> void:
	_prepare_scene("title_map",true)
	_clear_screen()
	screen = "difficulty"
	GameState.run_active = false
	Journal.difficulty(self)

func show_map() -> void:
	_prepare_scene("title_map",true)
	_clear_screen()
	screen = "map"
	route_view = RouteView.new()
	add_child(route_view)
	route_view.build(self)

func _enter_node(id: String) -> void:
	if screen != "map" or get_tree().paused or not GameState.enter_node(id): return
	recent_words.clear()
	if GameState.route.NODES[id].kind == "memory":
		show_review()
	elif GameState.route.NODES[id].kind == "rest":
		show_rest()
	elif GameState.route.NODES[id].kind == "treasure":
		show_reward()
	elif GameState.route.NODES[id].kind == "event":
		show_event()
	elif GameState.battle_index >= 2:
		show_encounter_intro()
	else:
		show_battle()

func show_rest() -> void:
	_prepare_scene("memory_rest",true)
	_clear_screen()
	screen = "rest"
	Journal.rest(self)

func show_event() -> void:
	_prepare_scene("memory_rest" if str(GameState.events.current.get("id","")) in ["pages","scribe"] else "event_special",true)
	_clear_screen()
	screen = "event"
	event_view = EventView.new()
	add_child(event_view)
	event_view.build(self)
	accepting_answer = GameState.events.current.stage == "questions"

func _event_action(action: String) -> void:
	if screen != "event" or get_tree().paused: return
	if action == "complete":
		if GameState.complete_event(): show_map()
	elif GameState.event_action(action):
		if action == "fight": show_battle()
		else: show_event()

func _on_event_answer(index: int) -> void:
	if screen != "event" or get_tree().paused or not accepting_answer or index < 0 or index >= 4: return
	accepting_answer = false
	var epoch := screen_epoch
	var event: Dictionary = GameState.events.current
	var question: Dictionary = event.questions[event.index]
	var result: Dictionary = GameState.resolve_event_answer(index,int(event.index))
	if result.is_empty(): return
	for button in event_view.buttons: button.disabled = true
	event_view.buttons[question.correct_index].add_theme_stylebox_override("disabled",_style(GREEN.darkened(0.46),GREEN))
	if not result.correct: event_view.buttons[index].add_theme_stylebox_override("disabled",_style(RED.darkened(0.45),RED))
	event_view.feedback.text = "答对了！" if result.correct else "正确释义："+str(question.entry.meaning)
	AudioBus.play_event("correct" if result.correct else "wrong")
	if not await _wait(0.8 if result.correct else 1.8,epoch): return
	show_event()

func _rest_and_continue() -> void:
	if screen != "rest" or get_tree().paused: return
	if GameState.complete_rest().is_empty(): return
	show_map()

func show_review() -> void:
	_prepare_scene("memory_rest",true)
	_clear_screen()
	screen = "review"
	review_view = ReviewView.new()
	add_child(review_view)
	review_view.build(self)
	review_view.display()
	accepting_answer = true

func _on_review_answer(index: int) -> void:
	if screen != "review" or get_tree().paused or not accepting_answer or index < 0 or index >= 4: return
	accepting_answer = false
	var epoch := screen_epoch
	var question: Dictionary = GameState.review.questions[GameState.review.index]
	var result: Dictionary = GameState.resolve_review(index,GameState.review.index)
	if result.is_empty(): return
	for button in review_view.buttons: button.disabled = true
	var right := int(question.correct_index)
	review_view.buttons[right].add_theme_stylebox_override("disabled",_style(GREEN.darkened(0.46),GREEN))
	if not result.correct: review_view.buttons[index].add_theme_stylebox_override("disabled",_style(RED.darkened(0.45),RED))
	review_view.feedback.text = "答对了 · 生命 +%d" % int(result.healed) if result.correct else "正确释义："+str(question.entry.meaning)
	review_view.feedback.add_theme_color_override("font_color",GREEN if result.correct else RED)
	review_view.life.text = "生命 %d / %d" % [GameState.hp,GameState.max_hp]
	AudioBus.play_event("correct" if result.correct else "wrong")
	if not await _wait(0.8 if result.correct else 1.8,epoch): return
	if result.complete:
		GameState.complete_review()
		show_map()
	else:
		review_view.display()
		accepting_answer = true

func show_battle() -> void:
	_prepare_scene(Profiles.battle_scene(str(GameState.current_enemy().kind)))
	_clear_screen()
	screen = "battle"
	battle_view = BattleView.new()
	add_child(battle_view)
	battle_view.build(self)
	player_avatar = battle_view.player_avatar
	enemy_avatar = battle_view.enemy_avatar
	player_bar = battle_view.player_bar
	enemy_bar = battle_view.enemy_bar
	hp_label = battle_view.hp_label
	enemy_hp_label = battle_view.enemy_hp_label
	combo_label = battle_view.combo_label
	word_label = battle_view.word_label
	phonetic_label = battle_view.phonetic_label
	feedback_label = battle_view.feedback_label
	encounter_label = battle_view.encounter_label
	answer_buttons = battle_view.answer_buttons
	shield_aura = SpellEffect.new()
	shield_aura.actor = player_avatar
	player_avatar.pose.add_child(shield_aura)
	shield_aura.z_index = 1
	_sync_barrier()
	_next_question()

func _next_question() -> void:
	if screen != "battle" or GameState.hp <= 0 or GameState.enemy_hp <= 0: return
	current_question = WordBank.make_question(GameState.battle_index,recent_words,GameState.seen_words,GameState.wrong_words)
	if current_question.is_empty(): return
	_display_question()

func _display_question() -> void:
	GameState.prepare_intent()
	GameState.select_spell("arcane")
	var entry: Dictionary = current_question["entry"]
	recent_words.append(str(entry["word"]))
	if recent_words.size() > 3: recent_words.pop_front()
	word_label.text = str(entry["word"])
	battle_view.word_class.text = "单词法术"+(" · "+str(entry.pos) if entry.has("pos") and not str(entry.pos).is_empty() else "")
	phonetic_label.text = str(entry["phonetic"])
	feedback_label.text = "请选择正确释义"
	feedback_label.add_theme_color_override("font_color",GOLD)
	var missed := bool(current_question["missed_this_run"])
	var weak := bool(current_question["weak_word"])
	battle_view.weak_label.add_theme_color_override("font_color",Color("#d992b2"))
	battle_view.weak_label.text = ("本局曾答错  ·  再次挑战" if missed else "薄弱词汇  ·  掌握度 %d" % int(current_question["mastery"])) if GameState.battle_index >= 2 and (missed or weak) else ""
	battle_view.set_word_state(GameState.battle_index >= 2 and (missed or weak))
	for i in 4:
		battle_view.reset_answer(i,str(current_question["options"][i]))
	combat_phase = CombatPhase.WAITING
	accepting_answer = true
	battle_view.update_spells(true)
	_sync_barrier()

func _select_spell(id: String) -> void:
	if screen != "battle" or get_tree().paused or combat_phase != CombatPhase.WAITING: return
	if GameState.select_spell(id): battle_view.update_spells(true)

func _sync_barrier(pulse: bool = false, display_value: int = -1) -> void:
	if not is_instance_valid(shield_aura): return
	var value := GameState.barrier if display_value < 0 else display_value
	shield_aura.visible = value > 0
	shield_aura.progress = 0.55+float(value)/float(GameState.barrier_cap())*0.45
	if pulse and shield_aura.visible:
		var tween := _fx()
		shield_aura.scale = Vector2(0.75,0.75)
		tween.tween_property(shield_aura,"scale",Vector2(1.06,1.06),0.18)
		tween.tween_property(shield_aura,"scale",Vector2.ONE,0.18)

func _present(event: String, spell: String) -> void:
	presentation_events.append({"event":event,"spell":spell,"time":Time.get_ticks_msec()})
	if presentation_events.size() > 64: presentation_events.pop_front()

func _on_answer(index: int) -> void:
	if get_tree().paused or screen != "battle" or combat_phase != CombatPhase.WAITING or not accepting_answer or index < 0 or index >= 4: return
	if not GameState.can_cast(GameState.selected_spell): return
	accepting_answer = false
	combat_phase = CombatPhase.RESOLVING
	var epoch := screen_epoch
	for button in answer_buttons: button.disabled = true
	var right_index := int(current_question["correct_index"])
	var correct := index == right_index
	var previous_combo := GameState.combo
	var entry: Dictionary = current_question["entry"]
	var result: Dictionary = GameState.resolve_answer(str(entry["word"]),correct)
	if result.is_empty(): return
	var spell := str(result["spell"])
	_present("answer",spell)
	battle_view.update_spells(false)
	if not result.counter.is_empty(): battle_view.resource_label.text = "法力 %d/%d · 护盾%d" % [GameState.mana,GameState.max_mana,int(result.barrier_before_counter)]
	AudioBus.play_event("correct" if correct else "wrong")
	battle_view.answer_feedback(right_index,true)
	if not correct:
		battle_view.answer_feedback(index,false)
	feedback_label.text = ("答对了！· 蓄势反击即将到来" if not result.counter.is_empty() else "答对了！· 敌方攻击已打断") if correct else "答错了  ·  正确释义："+str(entry["meaning"])
	if correct and bool(result.intent.get("uninterruptible",false)) and result.counter.is_empty(): feedback_label.text = "答对了！· 击杀取消蓄势反击"
	feedback_label.add_theme_color_override("font_color",GREEN if correct else RED)
	encounter_label.text = "已答题  %d" % GameState.questions_answered()
	_combo_feedback(previous_combo,correct)
	combat_phase = CombatPhase.ANIMATING
	if not correct:
		if not await EnemyPresentation.play(self,result,epoch): return
		await _after_answer(false,result,epoch)
		return
	# Resolve once, then reveal the new HP when the projectile hits.
	var caster: Control = player_avatar if correct else enemy_avatar
	var target: Control = enemy_avatar if correct else player_avatar
	var pose: Node2D = caster.pose
	var cast := _fx()
	cast.tween_property(pose,"position:x",(15.0 if spell == "aegis" else 30.0) if correct else -30.0,0.16)
	cast.tween_property(pose,"position:x",0.0,0.24)
	if correct:
		var glow := _fx()
		glow.tween_property(battle_view.spell_card,"modulate",Color(1.3,1.45,1.5),0.14)
		glow.tween_property(battle_view.spell_card,"modulate",Color.WHITE,0.25)
	var charge: Node2D
	if correct and spell == "memory":
		charge = SpellEffect.new()
		charge.mode = "charge"
		charge.progress = 0.0
		charge.position = caster.spell_origin()
		add_child(charge)
		var gather := _fx()
		gather.tween_property(charge,"progress",1.0,0.28)
		AudioBus.play_event("memory_charge")
	if not await _wait(0.30 if correct and spell == "memory" else 0.15,epoch): return
	if is_instance_valid(charge): charge.queue_free()
	if correct and spell == "aegis":
		_sync_barrier(true,int(result.barrier_before_counter) if not result.counter.is_empty() else -1)
		_damage_number(player_avatar,"护盾 +%d" % int(result["barrier_gained"]),Color("#8de5ed"))
	if correct and int(result["memory_bonus"]) > 0:
		battle_view.weak_label.text = "记忆共鸣 +%d · 本局曾答错" % int(result.memory_bonus)
		battle_view.weak_label.add_theme_color_override("font_color",GOLD)
	var bolt := Bolt.new()
	var palette := "player" if correct else ("boss" if GameState.battle_index == 3 else "ink")
	bolt.palette = palette
	bolt.spell = spell if correct else "enemy"
	if correct: bolt.scale = Vector2.ONE*(1.65 if spell == "memory" else (0.7 if spell == "aegis" else 1.0))
	bolt.tint = Color("#84dce9") if correct else (Color("#ca5968") if palette == "boss" else Color("#ae6eac"))
	bolt.direction = 1.0 if correct else -1.0
	add_child(bolt)
	bolt.position = caster.spell_origin()
	AudioBus.play_event(("memory_burst" if spell == "memory" else ("aegis_activate" if spell == "aegis" else "player_cast")) if correct else "enemy_cast")
	_present("release",spell if correct else "enemy")
	var flight := _fx()
	flight.tween_property(bolt,"position",target.spell_origin(),0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not await _wait(0.30,epoch): return
	bolt.queue_free()
	var shielded := bool(result["shielded"])
	AudioBus.play_event("burst_impact" if correct and spell == "memory" else "projectile_impact")
	if correct: AudioBus.play_event("enemy_hurt")
	elif int(result["damage"]) > 0: AudioBus.play_event("player_hit")
	if not correct and (shielded or int(result["barrier_absorbed"]) > 0): AudioBus.play_event("shield_hit")
	_present("impact",spell if correct else "enemy")
	var impact := Burst.new()
	impact.palette = palette
	if correct: impact.scale = Vector2.ONE*(1.5 if spell == "memory" else (0.65 if spell == "aegis" else 1.0))
	impact.position = target.spell_origin()
	add_child(impact)
	_hit(target,correct)
	_damage_number(target,"格挡" if shielded else "-%d" % int(result["damage"]),GREEN if shielded else (GOLD if correct else RED))
	_sync_health(int(result.hp_before_counter),int(result.enemy_before_counter)) if not result.counter.is_empty() else _sync_health()
	if not correct:
		_sync_barrier(true)
		if int(result["barrier_absorbed"]) > 0:
			var absorbed := _label(self,"护盾 -%d" % int(result["barrier_absorbed"]),player_avatar.global_position+Vector2(0,player_avatar.size.y*0.65),Vector2(player_avatar.size.x,50),25,Color("#8de5ed"),HORIZONTAL_ALIGNMENT_CENTER)
			var fade := _fx()
			fade.tween_property(absorbed,"modulate:a",0.0,0.65)
			fade.tween_callback(absorbed.queue_free)
	if int(result["healed"]) > 0:
		_damage_number(player_avatar,"+%d" % int(result["healed"]),GREEN)
	if not result.counter.is_empty():
		if not await _wait(0.12,epoch): return
		if not await EnemyPresentation.play(self,result.counter,epoch): return
	await _after_answer(true,result,epoch)

func _enemy_impact(result: Dictionary) -> void:
	_hit(player_avatar,false)
	_damage_number(player_avatar,"格挡" if result.shielded else "-%d" % int(result.damage),GREEN if result.shielded else RED)
	_sync_health()
	if int(result.reflected) > 0:
		_hit(enemy_avatar,true)
		_damage_number(enemy_avatar,"反伤 -%d" % int(result.reflected),GOLD)
		AudioBus.play_event("enemy_hurt")
	_sync_barrier(true)
	battle_view.update_spells(false)
	if int(result.barrier_absorbed) > 0: _damage_number(player_avatar,"护盾 -%d" % int(result.barrier_absorbed),Color("#8de5ed"))
	if result.ink_applied: feedback_label.text += "\n墨蚀：下一题答错额外受到3伤害"
	if int(result.mana_sealed) > 0: feedback_label.text += "\n封印：法力 -1"

func _after_answer(correct: bool, result: Dictionary, epoch: int) -> void:
	# Correct meanings remain readable even after short enemy animations.
	if not await _wait(0.45 if correct else 1.15,epoch): return
	if bool(result.phase_changed):
		phase_aura = EnemyPresentation.effect(self,"phase",Vector2.ZERO,true,0.0)
		remove_child(phase_aura)
		enemy_avatar.pose.add_child(phase_aura)
		phase_aura.progress = 1.0
		var banner := _label(self,"遗忘图书管理员 · 第二阶段",Vector2(520,80),Vector2(880,60),35,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
		banner.z_index = 10
		AudioBus.play_event("boss_intro")
		battle_view.update_status()
		if not await _wait(0.85,epoch): return
		banner.queue_free()
	if GameState.hp <= 0:
		combat_phase = CombatPhase.PLAYER_DEAD
		await _death_transition(false,epoch)
	elif GameState.enemy_hp <= 0:
		combat_phase = CombatPhase.ENEMY_DEAD
		await _death_transition(true,epoch)
	else:
		_next_question()

func _hit(target: Control, correct: bool) -> void:
	var pose: Node2D = target.pose
	var tween := _fx()
	tween.tween_property(pose,"modulate",Color(1.8,1.4,1.4),0.06)
	tween.tween_property(pose,"position:x",18.0 if correct else -18.0,0.06)
	tween.tween_property(pose,"position:x",-9.0 if correct else 9.0,0.06)
	tween.tween_property(pose,"position:x",0.0,0.14)
	tween.tween_property(pose,"modulate",Color.WHITE,0.12)

func _sync_health(player_display: int = -1, enemy_display: int = -1) -> void:
	var player_value := GameState.hp if player_display < 0 else player_display
	var enemy_value := GameState.enemy_hp if enemy_display < 0 else enemy_display
	hp_label.text = "生命  %d / %d" % [player_value,GameState.max_hp]
	enemy_hp_label.text = "生命  %d / %d" % [enemy_value,int(GameState.current_enemy()["hp"])]
	for pair in [[player_bar,player_value],[enemy_bar,enemy_value]]:
		var tween := _fx()
		tween.tween_property(pair[0],"value",pair[1],0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _damage_number(target: Control, value: String, color: Color) -> void:
	var node := _label(self,value,target.global_position+target.size*Vector2(0.25,0.18),Vector2(240,70),42,color,HORIZONTAL_ALIGNMENT_CENTER)
	var tween := _fx()
	tween.set_parallel(true)
	tween.tween_property(node,"position:y",node.position.y-100,0.65)
	tween.tween_property(node,"modulate:a",0.0,0.65)
	tween.chain().tween_callback(node.queue_free)

func _combo_feedback(previous: int, correct: bool) -> void:
	combo_label.text = "连击 ×%d" % GameState.combo
	combo_label.pivot_offset = combo_label.size / 2.0
	if not correct and previous > 0:
		var broken := _fx()
		broken.tween_property(combo_label,"scale",Vector2(0.75,0.75),0.1)
		broken.tween_property(combo_label,"scale",Vector2.ONE,0.2)
		combo_label.add_theme_color_override("font_color",RED)
	elif correct:
		combo_label.add_theme_color_override("font_color",Color("#94e6df") if GameState.combo >= 5 else CREAM)
		if GameState.combo in [3,5,8] or GameState.combo > 8 and GameState.combo % 4 == 0:
			AudioBus.play_event("combo_trigger")
			var pulse := _fx()
			pulse.tween_property(combo_label,"scale",Vector2(1.18,1.18),0.12)
			pulse.tween_property(combo_label,"scale",Vector2.ONE,0.25)
			if GameState.combo >= 8: _damage_number(player_avatar,"势不可挡",GOLD)

func _death_transition(enemy_died: bool, epoch: int) -> void:
	if not enemy_died and is_instance_valid(shield_aura): shield_aura.hide()
	var actor: Control = enemy_avatar if enemy_died else player_avatar
	actor.idle_enabled = false
	AudioBus.play_event("enemy_death" if enemy_died else "defeat")
	var fade := _fx()
	fade.set_parallel(true)
	fade.tween_property(actor,"modulate:a",0.0,0.55)
	fade.tween_property(actor.pose,"scale",Vector2(0.85,0.85),0.55)
	feedback_label.text = "战斗胜利" if enemy_died else "冒险失败"
	feedback_label.add_theme_color_override("font_color",GOLD if enemy_died else RED)
	if enemy_died and GameState.battle_index == 3: AudioBus.play_event("victory")
	if not await _wait(0.75,epoch): return
	combat_phase = CombatPhase.FINISHED
	if enemy_died:
		GameState.finish_battle()
		if GameState.rewards_pending > 0:
			show_reward()
			return
	show_report()

func show_reward() -> void:
	var treasure := not GameState.route.active.is_empty() and str(GameState.route.NODES[GameState.route.active].kind) == "treasure"
	_prepare_scene("event_special" if treasure else Profiles.battle_scene(str(GameState.current_enemy().kind)),true)
	super.show_reward()
	screen = "reward"

func _choose_reward(id: String) -> void:
	if get_tree().paused or reward_locked or screen != "reward" or not reward_cards.has(id): return
	reward_locked = true
	if not GameState.claim_reward(id):
		reward_locked = false
		return
	AudioBus.play_event("reward_select")
	var epoch := screen_epoch
	for child in get_children():
		if child != pause_menu: Kit.disable_buttons(child)
	if reward_cards.has(id):
		reward_cards[id].modulate = Color(1.08,1.06,1.02)
		reward_cards[id].queue_redraw()
	if not await _wait(0.25,epoch): return
	if GameState.rewards_pending > 0: show_reward()
	else: show_map()

func show_boss_intro() -> void:
	show_encounter_intro()

func show_encounter_intro() -> void:
	_prepare_scene(Profiles.battle_scene(str(GameState.current_enemy().kind)),true)
	_clear_screen()
	screen = "intro"
	var epoch := screen_epoch
	var boss := GameState.battle_index == 3
	var intro_panel := Kit.PanelSurface.new()
	intro_panel.accent = RED if boss else Color("#b778a7")
	intro_panel.position = Vector2(300,220)
	intro_panel.size = Vector2(1320,625)
	intro_panel.add_theme_stylebox_override("panel",preload("res://scripts/ui/battle_theme.gd").cover(40))
	add_child(intro_panel)
	_label(self,"最终首领" if boss else "精英遭遇",Vector2(440,278),Vector2(1040,80),43,RED if boss else Color("#ce93bb"),HORIZONTAL_ALIGNMENT_CENTER)
	var title := _label(self,str(GameState.current_enemy()["subtitle"]),Vector2(350,395),Vector2(1220,100),70,GOLD if boss else CREAM,HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font",Kit.title_font(ui_font))
	var pulse := _fx()
	pulse.tween_property(title,"modulate",Color(1.4,1.15,1.0),0.3)
	pulse.tween_property(title,"modulate",Color.WHITE,0.6)
	_label(self,"图书管理员记得你遗忘的每一个词。" if boss else "被遗忘的批注，正在聚集。",Vector2(430,535),Vector2(1060,55),26,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	var note := "遗忘的词汇，将再次成为你的考验。" if boss else "薄弱词汇更容易化为精英的武器。"
	if boss and not GameState.wrong_words.is_empty():
		var missed: Array = GameState.wrong_words.keys()
		note += "\n本局错词："+", ".join(missed.slice(0,mini(4,missed.size())))
	_label(self,note,Vector2(460,610),Vector2(1000,100),25,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	if boss: AudioBus.play_event("boss_intro")
	var dim := _panel(self,Vector2.ZERO,Vector2(1920,1080),Color(0,0,0,0.5),Color.TRANSPARENT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reveal := _fx()
	reveal.tween_property(dim,"modulate:a",0.0,0.5)
	if not await _wait(1.9,epoch): return
	show_battle()

func show_report() -> void:
	_prepare_scene("report_win" if GameState.run_won and GameState.hp > 0 else "report_fail",true)
	_clear_screen()
	screen = "report"
	report_snapshot = GameState.report_stats()
	Journal.report(self)

func return_to_title() -> void:
	GameState.run_active = false
	show_title()

func open_title_settings() -> void:
	pause_menu.open_menu()
	pause_menu.open_settings()

func request_quit() -> void:
	pause_menu.open_menu()
	pause_menu.request_action("quit")

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or not event is InputEventKey or not event.pressed or event.echo: return
	var code: int = event.keycode
	if code in [KEY_1,KEY_2,KEY_3,KEY_4] and accepting_answer:
		var index := code-KEY_1
		if screen == "battle": _on_answer(index)
		elif screen == "review": _on_review_answer(index)
		elif screen == "event": _on_event_answer(index)
		get_viewport().set_input_as_handled()
	elif screen == "battle" and code in [KEY_Q,KEY_W,KEY_E]:
		_select_spell(["arcane","aegis","memory"][[KEY_Q,KEY_W,KEY_E].find(code)])
		get_viewport().set_input_as_handled()
