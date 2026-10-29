extends Control
const Kit = preload("res://scripts/ui/ui_kit.gd")
const Journal = preload("res://scripts/ui/journal_screens.gd")
const RewardBadge = preload("res://scripts/ui/reward_badge.gd")

const BG := Kit.INK
const PANEL := Kit.CARD
const PANEL_ALT := Color("#263439")
const GOLD := Kit.GOLD
const CREAM := Kit.PAPER
const MUTED := Kit.MUTED
const GREEN := Color("#91bd9f")
const RED := Kit.RED

var ui_font: Font
var current_question: Dictionary = {}
var recent_words: Array[String] = []
var answer_buttons: Array[Button] = []
var accepting_answer := false
var reward_locked := false
var reward_cards: Dictionary = {}
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

func _ready() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Arial"])
	var ui_theme := Theme.new()
	ui_theme.default_font = ui_font
	ui_theme.default_font_size = 24
	theme = ui_theme
	show_title()

func _clear_screen() -> void:
	accepting_answer = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_background()

func _background() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	for i in 14:
		var shelf := ColorRect.new()
		shelf.color = Color("#263039") if i % 2 == 0 else Color("#1b252e")
		shelf.position = Vector2(72 + i * 132, 0)
		shelf.size = Vector2(4, 1080)
		shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shelf)
	for y in [106.0, 922.0]:
		var line := ColorRect.new()
		line.color = Color("#574936")
		line.position = Vector2(0, y)
		line.size = Vector2(1920, 3)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)
	_label(self, "✦  遗忘书塔  ✦", Vector2(60, 38), Vector2(1800, 50), 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

func _style(fill: Color, border: Color = Color.TRANSPARENT, radius: int = 18) -> StyleBoxFlat:
	var box := Kit.style(fill,border,16)
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _panel(parent: Control, pos: Vector2, dim: Vector2, fill: Color = PANEL, border: Color = Color("#594b39")) -> Panel:
	var node := Panel.new()
	node.position = pos
	node.size = dim
	node.add_theme_stylebox_override("panel", _style(fill, border))
	parent.add_child(node)
	return node

func _label(parent: Control, value: String, pos: Vector2, dim: Vector2, font_size: int = 28, color: Color = CREAM, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.size = dim
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_override("font", ui_font)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func _button(parent: Control, value: String, pos: Vector2, dim: Vector2, callback: Callable, fill: Color = PANEL_ALT) -> Button:
	var node := Kit.GameButton.new()
	node.text = value
	node.position = pos
	node.size = dim
	node.add_theme_font_override("font", ui_font)
	node.add_theme_font_size_override("font_size", 28)
	node.add_theme_color_override("font_color", CREAM)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_disabled_color", CREAM)
	Kit.dress_button(node,"danger" if value == "退出游戏" else "secondary")
	node.pressed.connect(func() -> void: AudioBus.play_event("ui_click"); callback.call())
	parent.add_child(node)
	return node

func _bar(parent: Control, pos: Vector2, dim: Vector2, fill: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.position = pos
	node.size = dim
	node.max_value = 100
	node.value = 100
	node.show_percentage = false
	node.add_theme_stylebox_override("background", _style(Color("#11171b"), Color("#514b40"), 10))
	node.add_theme_stylebox_override("fill", _style(fill, Color.TRANSPARENT, 10))
	parent.add_child(node)
	return node

func show_title() -> void:
	_clear_screen()
	Journal.title(self)

func _start_adventure() -> void:
	if not WordBank.load_error.is_empty():
		return
	GameState.start_run()
	recent_words.clear()
	show_battle()

func show_battle() -> void:
	pass

func show_boss_intro() -> void:
	pass

func show_reward() -> void:
	_clear_screen()
	reward_locked = false
	reward_cards.clear()
	Journal.reward(self)

func _choose_reward(id: String) -> void:
	if reward_locked:
		return
	reward_locked = true
	if not GameState.take_reward(id):
		reward_locked = false
		return
	GameState.advance_battle()
	recent_words.clear()
	if GameState.battle_index == 3:
		show_boss_intro()
	else:
		show_battle()

func show_report() -> void:
	_clear_screen()
	var won := GameState.run_won and GameState.hp > 0
	_panel(self, Vector2(245, 156), Vector2(1430, 770), Color("#1d252d"), GOLD if won else RED)
	_label(self, "冒险完成" if won else "冒险失败", Vector2(350, 184), Vector2(1220,88), 62, GOLD if won else RED, HORIZONTAL_ALIGNMENT_CENTER)
	_label(self, "游戏失败 ≠ 学习失败" if not won else "单词就是你的武器。", Vector2(570, 277), Vector2(780, 50), 25, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var metrics := "答题次数  %d     不同单词数  %d     答对  %d     答错  %d     正确率  %d%%     最高连击  ×%d" % [GameState.questions_answered(), GameState.seen_words.size(), GameState.correct_count, GameState.wrong_count, GameState.accuracy(), GameState.best_combo]
	_label(self, metrics, Vector2(302, 358), Vector2(1316, 60), 23, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(self, Vector2(315, 465), Vector2(615, 305), PANEL_ALT, Color("#5c684f"))
	_panel(self, Vector2(990, 465), Vector2(615, 305), PANEL_ALT, Color("#75574f"))
	_label(self, "本局提升", Vector2(350, 480), Vector2(545, 55), 30, GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	_label(self, "需要复习", Vector2(1025, 480), Vector2(545, 55), 30, RED, HORIZONTAL_ALIGNMENT_CENTER)
	var improved := GameState.improved_words()
	if improved.is_empty():
		_label(self, "本局还没有提升的词。", Vector2(360, 555), Vector2(530, 55), 23, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	for i in improved.size():
		var item: Dictionary = improved[i]
		_label(self, "%s    %d → %d" % [str(item["word"]), int(item["before"]), int(item["after"])], Vector2(370, 542 + i * 42), Vector2(510, 41), 24)
	var weak := GameState.weak_words()
	for i in weak.size():
		var item: Dictionary = weak[i]
		_label(self, "%s    %d" % [str(item["word"]), int(item["mastery"])], Vector2(1045, 542 + i * 42), Vector2(510, 41), 24)
	_button(self, "再来一局  ↻", Vector2(740, 812), Vector2(440, 75), _start_adventure, Color("#765633"))

