extends RefCounted

const Kit = preload("res://scripts/ui/ui_kit.gd")
const RewardStyle = preload("res://scripts/ui/archive_reward_style.gd")
const Vignette = preload("res://scripts/ui/journal_vignette.gd")
const IVORY := Color("#dfd8c8")
const COPPER := Color("#be9a74")
const QUIET := Color("#a5b0b0")
const BLUE := Color("#8caeb6")
const INK := Color("#10191d")

static func title(host: Control) -> void:
	preload("res://scripts/ui/frontispiece_title.gd").build(host)

static func hero_path(preferred: String = "res://assets/characters/word_mage_v2.png") -> String:
	return preferred if ResourceLoader.exists(preferred) else "res://assets/characters/word_mage.png"

static func difficulty(host: Control) -> void:
	var page := quiet_page(host,110)
	chapter(page,"卷一 / THE INITIATION","选择试炼","每局七层，长期掌握度保留。普通难度目标 7–10 分钟。")
	Kit.space(page)
	var columns := Kit.row(page,44)
	columns.custom_minimum_size.y = 460
	var index := 0
	for id in ["easy","normal","hard"]:
		index += 1
		var mode: Dictionary = GameState.Difficulty.get_mode(id)
		var panel := leaf(columns,id == "normal")
		var box := Kit.column(panel,16)
		Kit.text(box,"0%d   /   %s" % [index,"推荐试炼" if id == "normal" else ("初次入塔" if id == "easy" else "挑战记忆")],23,COPPER if id == "normal" else QUIET)
		seal(box,"memory" if id == "easy" else ("法力" if id == "normal" else "boss"),52,COPPER)
		Kit.text(box,str(mode.name),39,IVORY)
		Kit.text(box,str(mode.pool),25,QUIET)
		Kit.text(box,str(mode.hint),26,QUIET).custom_minimum_size.y = 105
		Kit.space(box)
		var button := Kit.button(host,box,"进入书塔",host._begin_run.bind(id),id == "normal")
		button.add_theme_font_size_override("font_size",28)
		if id == "normal": button.grab_focus()
	Kit.space(page)
	var actions := Kit.row(page)
	Kit.button(host,actions,"返回标题",host.show_title)
	Kit.text(actions,"选择一份适合此刻记忆的挑战。",23,QUIET)

static func reward(host: Control) -> void:
	var page := quiet_page(host,110)
	var treasure: bool = not GameState.route.active.is_empty() and GameState.route.NODES[GameState.route.active].kind == "treasure"
	chapter(page,"藏页 / RELIQUARY" if treasure else "凯旋 / VICTORY","藏宝书架" if treasure else "拾取一页力量","选择本局强化  ·  第 %d / %d 次" % [GameState.reward_batch-GameState.rewards_pending+1,GameState.reward_batch])
	Kit.text(page,"生命 %d/%d  ·  胜利恢复 %d  ·  已有遗物 %d" % [GameState.hp,GameState.max_hp,GameState.victory_healed,GameState.rewards.size()],24,QUIET)
	Kit.space(page)
	var columns := Kit.row(page,44)
	columns.custom_minimum_size.y = 410
	var index := 0
	for item in GameState.reward_choices():
		index += 1
		var category: String = GameState.Catalog.tag(item)
		var display: Dictionary = RewardStyle.describe(item)
		var panel := leaf(columns)
		host.reward_cards[str(item.id)] = panel
		var box := Kit.column(panel,16)
		Kit.text(box,"0%d   /   %s · %s" % [index,str(display.name),category],23,display.color)
		seal(box,category,52,COPPER)
		Kit.text(box,GameState.reward_name(str(item.id)),38,IVORY)
		Kit.text(box,"补给书签" if item.get("repeatable",false) else "遗物藏页",22,QUIET)
		var description := str(item.description).replace("Combo","连击").replace("Mastery","掌握度").replace("HP","生命")
		Kit.text(box,description,27,IVORY).custom_minimum_size.y = 114
		Kit.space(box)
		var select := Kit.button(host,box,"收入魔典",host._choose_reward.bind(str(item.id)),true)
		select.tooltip_text = description
	Kit.space(page)
	Kit.text(page,"普通战奖励一次，精英奖励两次。遗物只在本局生效。",24,QUIET)

static func rest(host: Control) -> void:
	var page := quiet_page(host,130)
	chapter(page,"间章 / A MOMENT OF RESPITE","休息书桌","安全房间")
	Kit.space(page)
	var row := Kit.row(page,88)
	var preface := Kit.column(row,18)
	preface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preface.size_flags_stretch_ratio = 0.65
	seal(preface,"rest",64,COPPER)
	Kit.text(preface,"灯火尚温，\n记忆尚在。",52,IVORY)
	Kit.text(preface,"在书塔深处，\n一盏灯便是一处归途。",26,QUIET)
	var panel := leaf(row)
	panel.size_flags_stretch_ratio = 1.35
	var box := Kit.column(panel,22)
	Kit.text(box,"放下魔法书休息片刻。\n不答题，不消耗法力。",30,IVORY)
	var heal := mini(GameState.max_hp-GameState.hp,ceili(float(GameState.max_hp)*0.2))
	Kit.text(box,"生命  %d / %d  →  %d / %d" % [GameState.hp,GameState.max_hp,GameState.hp+heal,GameState.max_hp],34,BLUE)
	Kit.text(box,"恢复最大生命的 20%%，本次实际恢复 %d。" % heal,26,QUIET)
	Kit.button(host,box,"休息并返回地图",host._rest_and_continue,true)
	Kit.text(box,"每个休息节点仅能使用一次。",23,QUIET)
	Kit.space(page)

static func report(host: Control) -> void:
	var data: Dictionary = host.report_snapshot
	var won: bool = GameState.run_won and GameState.hp > 0
	var page := quiet_page(host,105)
	Kit.text(page,"终卷 / ADVENTURE JOURNAL",22,COPPER)
	var heading := Kit.row(page)
	Kit.text(heading,"试炼完成 · 找回的记忆" if won else "试炼结束 · 记忆仍在",48,IVORY).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Kit.text(heading,"第 %d / %d 层" % [int(GameState.route.NODES[GameState.route.current].layer),GameState.route.depth],26,QUIET)
	Kit.text(page,str(data.difficulty)+" · "+str(data.word_pool)+(" · 你找回了遗忘的词。" if won else " · 游戏失败，学习收获依然保留。"),25,QUIET)
	var journal := leaf(page)
	journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := Kit.column(journal,14)
	var metrics := Kit.row(body,20)
	var names := ["正确率","答题总数","不同单词","答对","答错","最高连击"]
	var values := [str(data.accuracy)+"%",str(data.questions_answered),str(data.unique_words),str(data.correct),str(data.wrong),"×"+str(data.best_combo)]
	for i in 6:
		var box := Kit.column(metrics,5,true)
		Kit.text(box,str(names[i]),23,QUIET)
		Kit.text(box,str(values[i]),41,IVORY).theme_type_variation = "ArchiveNumber"
	Kit.text(body,"战斗 %d  ·  书房 %d  ·  事件 %d    /    答题总数 = 答对 + 答错" % [GameState.combat_answers,GameState.review_answers,GameState.event_answers],22,QUIET)
	var columns := Kit.row(body,48)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var improved := Kit.column(columns,12,true)
	var weak := Kit.column(columns,12,true)
	Kit.text(improved,"找回的记忆 / 本局提升",30,BLUE)
	var improved_list := word_list(improved,"ImprovedWordsScroll")
	Kit.text(weak,"下次的对手 / 需要复习",30,COPPER)
	var weak_list := word_list(weak,"ReviewWordsScroll")
	var gains: Array = GameState.improved_words()
	if gains.is_empty(): Kit.text(improved_list,"还没有提升词，下一次仍是新的机会。",26,QUIET)
	for item in gains: Kit.text(improved_list,"%s    %d → %d" % [str(item.word),int(item.before),int(item.after)],28,IVORY)
	var words: Array = GameState.weak_words()
	if words.is_empty(): Kit.text(weak_list,"本局没有作答记录。",26,QUIET)
	for item in words: Kit.text(weak_list,"%s    掌握度 %d" % [str(item.word),int(item.mastery)],28,IVORY)
	var actions := Kit.row(page,36)
	Kit.button(host,actions,"再来一局",host._start_adventure,true)
	Kit.button(host,actions,"返回标题",host.return_to_title)

static func quiet_page(host: Control, top: int) -> VBoxContainer:
	var page := Kit.page(host,top)
	var margin: MarginContainer = page.get_parent()
	margin.add_theme_constant_override("margin_left",125)
	margin.add_theme_constant_override("margin_right",125)
	margin.add_theme_constant_override("margin_bottom",58)
	page.add_theme_constant_override("separation",16)
	return page

static func chapter(parent: Node, caption: String, title_text: String, description: String) -> void:
	Kit.text(parent,caption,23,COPPER)
	Kit.text(parent,title_text,54,IVORY)
	Kit.text(parent,description,25,QUIET)

static func leaf(parent: Node, selected: bool = false) -> PanelContainer:
	# A single book-spine line supports the typography, without enclosing a card.
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color(INK,0.14)
	surface.border_color = Color(COPPER,0.66) if selected else Color(QUIET,0.22)
	surface.border_width_left = 1
	surface.content_margin_left = 30
	surface.content_margin_right = 14
	surface.content_margin_top = 12
	surface.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",surface)
	parent.add_child(panel)
	return panel

static func seal(parent: Node, symbol: String, height: float, color: Color) -> Control:
	var illustration := Vignette.new()
	illustration.symbol = symbol
	illustration.accent = color
	illustration.custom_minimum_size.y = height
	illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(illustration)
	return illustration

static func word_list(parent: Control, scroll_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = scroll_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 140
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	parent.add_child(scroll)
	var words := Kit.column(scroll,10)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return words
