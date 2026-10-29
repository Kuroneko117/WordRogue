extends Control

const Kit = preload("res://scripts/ui/ui_kit.gd")
const Folio = preload("res://scripts/ui/flow_folio.gd")
var host: Control
var buttons: Array[Button] = []
var feedback: Label

func build(main: Control) -> void:
	host = main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var event: Dictionary = GameState.events.current
	var definition: Dictionary = GameState.Events.DEFINITIONS[event.id]
	var page := Kit.page(self,125)
	Folio.heading(page,"event","异闻录  /  未知的一页","书塔异闻")
	var body := Kit.row(page,30)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var narrative_page := Kit.folio(body,Kit.GOLD,true)
	# Native quiet manuscript surfaces share the approved title palette.
	Folio.inset(narrative_page,true)
	var narrative := Kit.column(narrative_page,20)
	narrative.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Kit.text(narrative,"遭遇记录  ·  %02d" % (int(GameState.route.NODES[GameState.route.current].layer)),22,Kit.GOLD)
	Kit.text(narrative,str(definition.name),48,Kit.PAPER)
	Folio.rule(narrative)
	Kit.text(narrative,str(definition.text),32)
	Kit.space(narrative)
	Kit.text(narrative,str(definition.hint),28,Kit.BLUE)
	Folio.rule(narrative,Kit.BLUE)
	Kit.text(narrative,"生命   %d / %d" % [GameState.hp,GameState.max_hp],25,Kit.MUTED)
	var panel := Kit.folio(body,Kit.BLUE,true)
	Folio.inset(panel,true)
	var box := Kit.column(panel,20)
	Kit.text(box,"你的选择" if event.stage == "choice" else ("记忆挑战" if event.stage == "questions" else "事件结果"),32,Kit.BLUE)
	Folio.rule(box,Kit.BLUE)
	if event.stage == "choice":
		match str(event.id):
			"pages","dictionary": action(box,"接受词汇挑战","review")
			"chest":
				var relics_left := GameState.rewards.size() < GameState.REWARDS.size()+GameState.Catalog.EXTRA.size()
				action(box,"支付10生命 · 打开书匣","open",GameState.hp <= 10 or not relics_left)
				if GameState.hp <= 10: label(box,"生命必须大于10，才能支付代价。",24,host.RED)
				if not relics_left: label(box,"你已拥有全部遗物，书匣不再索取代价。",22,host.MUTED)
			"scribe":
				action(box,"支付6生命 · 换取随机补给","trade",GameState.hp <= 6)
				if GameState.hp <= 6: label(box,"生命必须大于6，才能交易。",24,host.RED)
				action(box,"复习两个薄弱词","review")
			"ambush": action(box,"准备迎战","fight")
		if event.id != "ambush": action(box,"安全离开","leave")
	elif event.stage == "questions":
		var question: Dictionary = event.questions[event.index]
		label(box,"词汇挑战 %d / %d" % [int(event.index)+1,event.questions.size()],22,host.GOLD)
		label(box,str(question.entry.word),50,host.CREAM)
		label(box,str(question.entry.phonetic),25,host.MUTED)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation",14)
		grid.add_theme_constant_override("v_separation",14)
		box.add_child(grid)
		for i in 4:
			var button: Button = host._button(grid,["A","B","C","D"][i]+". "+str(question.options[i]),Vector2.ZERO,Vector2.ZERO,host._on_event_answer.bind(i))
			button.custom_minimum_size.y = 90
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.add_theme_font_size_override("font_size",25)
			Kit.dress_button(button,"choice")
			buttons.append(button)
		feedback = label(box,"请选择正确释义；答错没有额外战斗伤害。",22,host.MUTED)
	else:
		label(box,str(event.result),30,host.GREEN)
		action(box,"返回地图","complete")
	Kit.text(page,"选择之前请阅读收益与生命代价。词汇挑战没有战斗反击。",24,Kit.MUTED)

func label(parent: Node, value: String, size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node

func action(parent: Control, value: String, id: String, disabled: bool = false) -> void:
	var button: Button = host._button(parent,value,Vector2.ZERO,Vector2.ZERO,host._event_action.bind(id))
	button.custom_minimum_size.y = 90
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = disabled
	Kit.dress_button(button,"primary" if id in ["review","open","trade","fight","complete"] else "secondary")
