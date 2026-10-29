extends Control

const Kit = preload("res://scripts/ui/ui_kit.gd")
const Icon = preload("res://scripts/ui/map_icon.gd")
const Folio = preload("res://scripts/ui/flow_folio.gd")
var host: Control
var nodes: Dictionary = {}
var canvas: Control
var scroll: ScrollContainer
var info_label: Label
var content_height := 2100.0
const ROW_GAP := 145.0
const TYPES := {"entry":"入口","normal":"普通战斗","elite":"精英战斗","memory":"回忆书房","rest":"休息书桌","treasure":"藏宝书架","boss":"最终首领","report":"学习报告","event":"未知事件"}
const STATES := {"available":"可进入","complete":"已完成","skipped":"已跳过","locked":"未解锁","active":"进行中"}

func build(main: Control) -> void:
	host = main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page := Kit.page(self,100)
	var header := Kit.row(page)
	var layer: int = maxi(1,int(GameState.route.NODES[GameState.route.current].layer))
	var heading := Kit.column(header,2,true)
	Kit.text(heading,"旅途手记  /  THE FORGOTTEN TOWER",20,Kit.MUTED)
	Kit.text(heading,"探索书塔  /  第 %d · 共 %d 层" % [layer,GameState.route.depth],38,Kit.PAPER)
	var menu := Kit.button(host,header,"设置" if host.PlatformUI.touch_mode() else "ESC 设置",host.pause_menu.open_menu)
	menu.size_flags_horizontal = Control.SIZE_FILL
	menu.custom_minimum_size = Vector2(220,58)
	var row := Kit.row(page,28)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := Kit.folio(row,Color("#847253"),true)
	Folio.inset(paper)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(scroll)
	canvas = Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(canvas)
	canvas.draw.connect(_connections)
	canvas.resized.connect(_position_nodes)
	scroll.resized.connect(func() -> void:
		content_height = scroll.size.y
		_position_nodes())
	for id in GameState.route.NODES:
		var item: Dictionary = GameState.route.NODES[id]
		if item.kind in ["entry","report"]: continue
		var state: String = GameState.route.status(str(id))
		var button := Icon.new()
		button.kind = str(item.kind)
		button.state = state
		button.current = GameState.route.current == id
		button.size = Vector2(84,84) if item.kind == "boss" else Vector2(64,64)
		button.disabled = state != "available" or not GameState.run_active
		button.tooltip_text = "%s · 第%d层\n%s\n%s" % [str(TYPES[item.kind]),int(item.layer),str(STATES[state]),_benefit(item)]
		canvas.add_child(button)
		button.pressed.connect(func() -> void: AudioBus.play_event("ui_click"); host._enter_node(str(id)))
		button.mouse_entered.connect(_inspect.bind(str(id)))
		button.focus_entered.connect(_inspect.bind(str(id)))
		nodes[str(id)] = button
	var sidebar := Kit.folio(row,Kit.GOLD)
	Folio.inset(sidebar,true)
	sidebar.custom_minimum_size.x = 425
	var side := Kit.column(sidebar,8)
	var bag_header := Kit.row(side,12)
	Kit.text(bag_header,"本局行囊",34,Kit.PAPER)
	Folio.rule(side)
	Kit.text(side,"生命 %d / %d" % [GameState.hp,GameState.max_hp],28,Kit.BLUE)
	Kit.text(side,str(GameState.Difficulty.get_mode(GameState.difficulty_id).name),23,Kit.MUTED)
	var legend := GridContainer.new()
	legend.columns = 2
	legend.add_theme_constant_override("v_separation",2)
	side.add_child(legend)
	for kind in ["normal","elite","memory","rest","treasure","boss","event"]:
		var cell := Kit.row(legend,8)
		cell.custom_minimum_size = Vector2(150,36)
		var symbol := Icon.new()
		symbol.kind = kind
		symbol.state = "available"
		symbol.disabled = true
		symbol.custom_minimum_size = Vector2(36,36)
		cell.add_child(symbol)
		Kit.text(cell,str(TYPES[kind]),22)
	info_label = Kit.text(side,"选择铜色节点开始。\n悬停或聚焦查看收益与风险。",24,Kit.PAPER)
	info_label.custom_minimum_size.y = 100
	Kit.text(side,"遗物 %d / 18 · 悬停查看完整效果" % GameState.rewards.size(),23,Kit.MUTED)
	var bag := ScrollContainer.new()
	bag.custom_minimum_size.y = 90
	bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(bag)
	var inventory := Kit.column(bag,12)
	inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if GameState.rewards.is_empty(): Kit.text(inventory,"首战胜利后，选择第一件遗物。",24,Kit.MUTED)
	for id in GameState.rewards:
		var item: Dictionary = GameState.Catalog.find(str(id),GameState.REWARDS)
		var label := Kit.text(inventory,"[%s] %s" % [GameState.Catalog.tag(item),GameState.reward_name(str(id))],24,GameState.Catalog.COLORS[GameState.Catalog.tag(item)])
		label.tooltip_text = str(item.description).replace("Combo","连击").replace("Mastery","掌握度")
		label.mouse_filter = Control.MOUSE_FILTER_STOP
	if GameState.next_barrier_bonus > 0 or GameState.next_opening_bonus > 0:
		Kit.text(side,"下场：护盾+%d / 首击+%d" % [GameState.next_barrier_bonus,GameState.next_opening_bonus],23,Kit.BLUE)
	Kit.text(page,"向上探索 · 铜色可进入 · ✓ 已完成 · 划线已错过 · 灰色未到达" if host.PlatformUI.touch_mode() else "向上探索 · 铜色可进入 · ✓ 已完成 · 划线已错过 · 灰色未到达   /   Tab、方向键、Enter 选择路线",23,Kit.MUTED,true)
	call_deferred("_initial_focus")

func _text(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func _benefit(item: Dictionary) -> String:
	match str(item.kind):
		"event": return "未知事件：可能获得奖励，也可能遭遇危险。"
		"normal": return "胜利恢复5生命，选择1次强化"
		"elite": return "高风险，胜利恢复8生命，选择2次强化"
		"memory": return "复习3词，每次答对恢复%d生命" % GameState.review_healing()
		"rest": return "恢复最大生命20%，不产生答题记录"
		"treasure": return "直接从3件遗物/补给中选择1件"
		"boss": return "挑战本局弱词与首领二阶段"
		_: return "通向书塔的终点"

func _inspect(id: String) -> void:
	var item: Dictionary = GameState.route.NODES[id]
	info_label.text = "%s · 第%d层\n%s\n%s" % [str(TYPES[item.kind]),int(item.layer),str(STATES[GameState.route.status(id)]),_benefit(item)]

func node_center(id: String) -> Vector2:
	var item: Dictionary = GameState.route.NODES[id]
	var x := float([0.25,0.5,0.75][int(item.col)])
	var gap := maxf(1.0,(canvas.size.y-152.0)/float(maxi(1,GameState.route.depth-1)))
	return Vector2(x*canvas.size.x,canvas.size.y-76.0-float(int(item.layer)-1)*gap)

func _position_nodes() -> void:
	if not is_instance_valid(canvas): return
	for id in nodes: nodes[id].position = node_center(str(id))-nodes[id].size/2.0
	canvas.queue_redraw()

func _initial_focus() -> void:
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree(): return
	_position_nodes()
	focus_current()

func focus_current() -> void:
	for id in nodes:
		if GameState.route.status(str(id)) == "available":
			nodes[id].grab_focus()
			return

func _connections() -> void:
	var font: Font = get_theme_default_font()
	# One faint spine line, keeping the route itself as the primary illustration.
	canvas.draw_line(Vector2(40,20),Vector2(40,canvas.size.y-20),Color(Kit.GOLD,0.15),1,true)
	for layer in range(1,GameState.route.depth+1):
		var sample := "boss" if layer == GameState.route.depth else ("first" if layer == 1 else "floor_%d_0" % layer)
		if not GameState.route.NODES.has(sample): continue
		canvas.draw_string(font,Vector2(8,node_center(sample).y+7),"%02d" % layer,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Kit.MUTED)
		var y := node_center(sample).y
		canvas.draw_line(Vector2(50,y),Vector2(canvas.size.x-20,y),Color(Kit.GOLD,0.045),1,true)
	for id in nodes:
		var from := node_center(str(id))
		var item: Dictionary = GameState.route.NODES[id]
		for next in item.next:
			if not nodes.has(str(next)): continue
			var to := node_center(str(next))
			var walked: bool = GameState.route.completed.has(str(id)) and GameState.route.completed.has(str(next))
			var accessible: bool = id == GameState.route.current and GameState.route.status(str(next)) == "available"
			var color := Color("#8caeb6") if walked else (Kit.GOLD if accessible else Color("#4c575a"))
			canvas.draw_dashed_line(from,to,color,2 if walked or accessible else 1.2,9,true)
		var label: String = "入口战斗" if id == "first" else str(TYPES[item.kind])
		canvas.draw_string(font,from+Vector2(-72,57),label,HORIZONTAL_ALIGNMENT_CENTER,144,21,Kit.GOLD if GameState.route.status(str(id)) == "available" else Kit.MUTED)
