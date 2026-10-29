extends Control
## Battle composition, 1920x1080 design canvas. Containers own all hit targets.
const Actor = preload("res://scripts/ui/actor_view.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")
const MomentumView = preload("res://scripts/ui/momentum_view.gd")
const Kit = preload("res://scripts/ui/ui_kit.gd")
const Journal = preload("res://scripts/ui/journal_screens.gd")
const Grimoire = preload("res://scripts/ui/battle_theme.gd")
const BattleButton = preload("res://scripts/ui/battle_button.gd")
const StageLight = preload("res://scripts/ui/battle_stage_light.gd")
var momentum_view: HBoxContainer
var player_avatar: Control
var enemy_avatar: Control
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var hp_label: Label
var enemy_hp_label: Label
var combo_label: Label
var word_label: Label
var phonetic_label: Label
var feedback_label: Label
var encounter_label: Label
var weak_label: Label
var spell_card: PanelContainer
var answer_buttons: Array[Button] = []
var spell_buttons: Dictionary = {}
var resource_label: Label
var intent_label: Label
var status_label: Label
var enemy_name: Label
var word_class: Label
var danger_label: Label
var host: Control

func build(main: Control) -> void:
	host = main
	z_index = 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The inherited screen watermark is replaced by the battle heading.
	for child in host.get_children():
		if child is Label and child.text.contains("遗忘书塔"): child.hide()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,38)
	margin.add_theme_constant_override("margin_top",22)
	margin.add_theme_constant_override("margin_bottom",28)
	add_child(margin)
	var page := Kit.column(margin,8)
	var enemy: Dictionary = GameState.current_enemy()
	var kind := str(enemy.kind)
	var layer := int(GameState.route.NODES[GameState.route.active].layer) if not GameState.route.active.is_empty() else GameState.battle_index+1
	var header := Kit.row(page,28)
	header.custom_minimum_size.y = 96
	var heading := Kit.column(header,2)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_stretch_ratio = 1.15
	Kit.text(heading,"第 %d / %d 层 · %s" % [layer,GameState.route.depth,"最终首领" if kind == "boss" else ("精英遭遇" if kind == "elite" else ("入口遭遇" if layer == 1 else "藏书回廊"))],31,Grimoire.GOLD)
	Kit.text(heading,"遗忘书塔  ·  WordRogue",21,Kit.MUTED)
	var difficulty := _panel(header,16)
	difficulty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty.size_flags_stretch_ratio = 1.0
	difficulty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Kit.text(difficulty,str(GameState.Difficulty.get_mode(GameState.difficulty_id).name),28,Grimoire.PALE,true)
	var header_space := Control.new()
	header_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_space.size_flags_stretch_ratio = 0.55
	header.add_child(header_space)
	var settings := _button(header,"暂停" if host.PlatformUI.touch_mode() else "ESC 暂停",host.pause_menu.open_menu)
	settings.custom_minimum_size = Vector2(218,68)
	settings.size_flags_horizontal = Control.SIZE_FILL
	settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Kit.dress_button(settings)
	settings.icon = load("res://assets/ui/archive/icons/settings.svg")
	settings.expand_icon = true
	settings.add_theme_constant_override("icon_max_width",28)
	var arena := Kit.row(page,24)
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := _column(arena,1.18)
	var middle := _column(arena,2.04)
	var right := _column(arena,1.18)
	# Root battle projectiles are drawn after this view; do not lift the word
	# column above those effects. Actor bounds already keep artwork clear.
	middle.z_index = 0
	var player_panel := _panel(left,24)
	var player_stats := Kit.column(player_panel,6)
	var player_heading := Kit.row(player_stats,6)
	Kit.text(player_heading,"单词法师",32,Color("#9ddbec"))
	combo_label = Kit.text(player_heading,"连击 ×0",28,Grimoire.GOLD)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label = Kit.text(player_stats,"生命 %d / %d" % [GameState.hp,GameState.max_hp],26,Grimoire.PALE)
	player_bar = _health_bar(player_stats,GameState.max_hp,GameState.hp,Kit.BLUE,18)
	var resources := Kit.row(player_stats,8)
	resource_label = Kit.text(resources,"",25,Color("#a9e4ef"))
	status_label = Kit.text(player_stats,"",20,Color("#bfb29b"))
	# Status notes share one reserved line; changing a spell must not reflow actors.
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.mouse_filter = Control.MOUSE_FILTER_PASS
	player_avatar = Actor.new()
	player_avatar.custom_minimum_size.y = 420
	player_avatar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(player_avatar)
	var hero := Journal.hero_path()
	player_avatar.setup("mage",hero,Kit.BLUE)
	player_avatar.texture_height = 650
	player_avatar.texture_padding = Vector2(14,26)
	player_avatar.floor_padding = 18
	if hero.ends_with("word_mage_v2.png"): player_avatar.cast_uv = Vector2(0.84,0.205)
	_light(player_avatar,Color("#7dceed"))
	spell_card = _panel(middle,28)
	spell_card.add_theme_stylebox_override("panel",Grimoire.parchment())
	var spell := Kit.column(spell_card,0)
	word_class = Kit.text(spell,"单词法术",24,Kit.GOLD,true)
	word_label = Kit.text(spell,"",64,Grimoire.PAPER_INK,true)
	word_label.theme_type_variation = "ArchiveNumber"
	# Latin word typography must not inherit the CJK fallback's tall metrics.
	var latin := SystemFont.new()
	latin.font_names = PackedStringArray(["Georgia","Cambria","Times New Roman"])
	word_label.add_theme_font_override("font",latin)
	word_label.custom_minimum_size.y = 82
	phonetic_label = Kit.text(spell,"",29,Kit.MUTED,true)
	weak_label = Kit.text(middle,"",22,Color("#e0a7e3"),true)
	weak_label.custom_minimum_size.y = 27
	var spells := Kit.row(middle,7)
	for id in ["arcane","aegis","memory"]:
		var button := _button(spells,"",host._select_spell.bind(str(id)))
		button.spell_id = str(id)
		button.custom_minimum_size.y = 128
		button.add_theme_font_size_override("font_size",21)
		spell_buttons[str(id)] = button
	var feedback_panel := _panel(middle,13)
	feedback_label = Kit.text(feedback_panel,"请选择正确释义",24,Grimoire.GOLD,true)
	feedback_label.custom_minimum_size.y = 70
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",12)
	middle.add_child(grid)
	for i in 4:
		var button := _button(grid,"",host._on_answer.bind(i))
		button.answer_index = i
		button.custom_minimum_size.y = 112
		button.add_theme_font_size_override("font_size",27)
		Grimoire.style_answer(button)
		answer_buttons.append(button)
	Kit.text(middle,"点击法术与正确释义" if host.PlatformUI.touch_mode() else "1–4 作答 · Q/W/E 选择法术 · Tab / 方向键导航",20,Color("#a7b9cc"),true)
	var enemy_panel := _panel(right,24)
	var enemy_stats := Kit.column(enemy_panel,5)
	enemy_name = Kit.text(enemy_stats,str(enemy.subtitle),31,Color("#c1a1af") if kind != "boss" else Kit.RED)
	Kit.text(enemy_stats,"最终首领" if kind == "boss" else ("精英敌人" if kind == "elite" else "普通敌人"),20,Color("#c2b0bd"))
	enemy_hp_label = Kit.text(enemy_stats,"生命 %d / %d" % [GameState.enemy_hp,int(enemy.hp)],26,Grimoire.PALE)
	enemy_bar = _health_bar(enemy_stats,int(enemy.hp),GameState.enemy_hp,Color("#b88699") if kind != "boss" else Kit.RED,18)
	momentum_view = MomentumView.new()
	enemy_stats.add_child(momentum_view)
	intent_label = Kit.text(enemy_stats,"",22,Color("#e2cbb3"))
	intent_label.custom_minimum_size.y = 86
	enemy_avatar = Actor.new()
	enemy_avatar.custom_minimum_size.y = 360
	enemy_avatar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(enemy_avatar)
	var image := str(enemy.get("art","librarian" if kind == "boss" else ("marginalia" if kind == "elite" else "ink_wraith")))
	var portrait: Dictionary = Profiles.PORTRAITS.get(str(enemy.get("id","")),{})
	if not portrait.is_empty(): image = str(portrait.art)
	if not ResourceLoader.exists("res://assets/enemies/%s.png" % image) and not str(portrait.get("fallback","")).is_empty(): image = str(portrait.fallback)
	enemy_avatar.setup(kind,"res://assets/enemies/%s.png" % image if not image.is_empty() else "",Kit.RED)
	if not enemy_avatar.uses_texture and enemy.has("id"):
		enemy_avatar.art.kind = str(enemy.id)
		enemy_avatar.art.queue_redraw()
	enemy_avatar.texture_padding = Vector2(20,26)
	enemy_avatar.floor_padding = 18
	enemy_avatar.texture_height = 680 if kind == "boss" else (610 if kind == "elite" else 570)
	_light(enemy_avatar,Color("#be8bdf") if kind != "boss" else Color("#e18c88"))
	var footer_panel := _panel(page,12)
	var footer := Kit.row(footer_panel,24)
	Kit.text(footer,"攻击 %d" % GameState.base_attack,25,Grimoire.GOLD).custom_minimum_size.x = 140
	encounter_label = Kit.text(footer,"本局已答题 %d" % GameState.questions_answered(),23,Color("#c2b9aa"))
	encounter_label.size_flags_stretch_ratio = 0.5
	danger_label = Kit.text(footer,"",23,Grimoire.PALE,true)
	danger_label.custom_minimum_size.y = 48
	danger_label.size_flags_stretch_ratio = 1.8
	update_spells(true)

func _button(parent: Control, caption: String, callback: Callable) -> BattleButton:
	var button := BattleButton.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: AudioBus.play_event("ui_click"); callback.call())
	parent.add_child(button)
	return button

func _panel(parent: Control, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	# Open HUD typography shares the title's breathing room. Word/answer sheets
	# add a local reading surface only where the texture needs separating.
	var surface := Kit.Quiet.sheet(padding)
	surface.bg_color = Color.TRANSPARENT
	surface.border_color = Color(Kit.GOLD,0.18)
	panel.add_theme_stylebox_override("panel",surface)
	parent.add_child(panel)
	return panel

func _light(actor: Control, color: Color) -> void:
	var light := StageLight.new()
	light.accent = color
	actor.add_child(light)
	actor.move_child(light,0)

func set_word_state(weak: bool) -> void:
	spell_card.add_theme_stylebox_override("panel",Grimoire.parchment("weak" if weak else "normal"))

func reset_answer(index: int, meaning: String) -> void:
	var button: Button = answer_buttons[index]
	button.text = meaning
	button.disabled = false
	Grimoire.style_answer(button)

func answer_feedback(index: int, correct: bool) -> void:
	Grimoire.style_answer(answer_buttons[index],"correct" if correct else "wrong")

func update_spells(waiting: bool) -> void:
	resource_label.text = "法力 %d / %d  ·  护盾 %d" % [GameState.mana,GameState.max_mana,GameState.barrier]
	for id in spell_buttons:
		var button: Button = spell_buttons[id]
		var selected: bool = id == GameState.selected_spell
		button.disabled = not waiting or not GameState.can_cast(str(id))
		var key: String = {"arcane":"Q","aegis":"W","memory":"E"}[id]
		var prefix := "" if host.PlatformUI.touch_mode() else "[%s] " % key
		var effect: String = {"arcane":"答对 +1法力","aegis":"护盾 +%d" % (10 if GameState.rewards.has("aegis_edge") else 8),"memory":"旧错词 +%d" % (10 if GameState.rewards.has("resonance") else 5)}[id]
		var cost := "%d法力 · %s" % [int(GameState.SPELLS[id].cost),"180%" if id == "memory" else "全伤"]
		button.text = "%s%s\n%s\n%s" % [prefix,str(GameState.SPELLS[id].name),cost,effect if GameState.can_cast(str(id)) else "法力不足"]
		button.tooltip_text = {"arcane":"答对造成完整普通伤害，获得1法力。", "aegis":"答对造成完整普通伤害并获得护盾；答错减伤30%。护盾优先吸收伤害。", "memory":"答对造成普通伤害180%；本局之前答错的词额外加伤。"}[id]
		Grimoire.style_spell(button,str(id),selected)
	if waiting: update_intent()
	update_status()

func update_intent() -> void:
	if GameState.enemy_intent.is_empty(): return
	var intent: Dictionary = GameState.enemy_intent
	var preview: Dictionary = GameState.incoming_preview()
	var rider := " · 附墨蚀" if intent.effect == "ink" else (" · 封印1法力" if intent.effect == "seal" else "")
	intent_label.text = "意图 · %s\n%d伤害 · 预计扣血%d%s" % [str(intent.name),int(preview.reduced),int(preview.hp_damage),rider]
	danger_label.text = "答对打断攻击  ·  答错受到反击"
	danger_label.add_theme_color_override("font_color",Grimoire.PALE)
	if bool(intent.get("uninterruptible",false)) and not GameState.classic_fixture:
		danger_label.text = "不可打断！答对仍有反击；击杀可打断。"
		danger_label.add_theme_color_override("font_color",Color("#ffaf9a"))
		var right: Dictionary = GameState.incoming_preview("arcane",true)
		intent_label.tooltip_text = "答对预计受到%d伤害；守护先加盾再承受反击；击杀可取消反击。" % int(right.typed)
	else: intent_label.tooltip_text = "答对打断普通攻击；守护答错减伤30%；护盾优先吸收伤害。"
	if preview.immune: intent_label.text += "\n学者之盾可免疫答错"
	update_status()

func update_status() -> void:
	var notes: PackedStringArray = []
	var explanations: PackedStringArray = []
	if GameState.ink_active:
		notes.append("墨蚀：答错+3")
		explanations.append("墨蚀：下一题答错额外受到3点伤害。")
	if GameState.selected_spell == "aegis":
		notes.append("守护：减伤30%")
		explanations.append("守护咒文：答错时受到的伤害减少30%；答对仍造成完整伤害并获得护盾。")
	status_label.text = " · ".join(notes) if not notes.is_empty() else "状态正常"
	status_label.tooltip_text = "\n".join(explanations)
	if GameState.boss_phase_two: enemy_name.text = "遗忘图书管理员 · 第二阶段"
	if is_instance_valid(momentum_view):
		momentum_view.visible = not GameState.classic_fixture
		var pending := not GameState.intent_consumed and bool(GameState.enemy_intent.get("uninterruptible",false))
		momentum_view.display(GameState.momentum.value,GameState.momentum.threshold,not GameState.classic_fixture and (GameState.momentum.ready() or pending),GameState.momentum.cooldown)

func _column(parent: HBoxContainer, ratio: float) -> VBoxContainer:
	var column := Kit.column(parent,4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = ratio
	return column

func _health_bar(parent: Control, maximum: int, value: int, color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#080e17")
	background.border_color = Grimoire.GOLD.darkened(0.3)
	background.border_width_bottom = 1
	bar.add_theme_stylebox_override("background",background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.border_color = color
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	return bar
