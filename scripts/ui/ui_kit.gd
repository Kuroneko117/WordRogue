extends RefCounted

const Quiet = preload("res://scripts/ui/quiet_style.gd")
const INK := Quiet.INK
const CARD := Quiet.SURFACE
const GOLD := Quiet.COPPER
const PAPER := Quiet.PAPER
const MUTED := Quiet.MUTED
const BLUE := Quiet.BLUE
const RED := Quiet.RED
const PanelSurface = preload("res://scripts/ui/archive_panel.gd")
const GameButton = preload("res://scripts/ui/archive_button.gd")
const Emblem = preload("res://scripts/ui/archive_emblem.gd")
const Grimoire = preload("res://scripts/ui/battle_theme.gd")

static func title_font(fallback: Font) -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["SimSun","Noto Serif CJK SC","Georgia","Times New Roman"])
	font.fallbacks = [fallback]
	return font

static func style(fill: Color, edge: Color = Color("#43536b"), padding: int = 24) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = edge
	result.border_width_bottom = 1 if edge.a > 0.0 else 0
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = padding
	result.content_margin_bottom = padding
	return result

static func make_theme(font: Font) -> Theme:
	var result := Theme.new()
	result.default_font = font
	result.default_font_size = 28
	result.set_font("font","ArchiveTitle",title_font(font))
	result.set_type_variation("ArchiveTitle","Label")
	result.set_type_variation("ArchiveNumber","Label")
	var digits := SystemFont.new()
	digits.font_names = PackedStringArray(["Georgia","Cambria","Times New Roman"])
	digits.fallbacks = [font]
	result.set_font("font","ArchiveNumber",digits)
	result.set_stylebox("panel","PanelContainer",style(CARD))
	result.set_stylebox("normal","Button",Quiet.entry("normal"))
	result.set_stylebox("hover","Button",Quiet.entry("hover"))
	result.set_stylebox("pressed","Button",Quiet.entry("pressed",BLUE))
	result.set_stylebox("disabled","Button",Quiet.entry("disabled"))
	result.set_stylebox("focus","Button",StyleBoxEmpty.new())
	result.set_color("font_color","Button",PAPER)
	result.set_color("font_disabled_color","Button",MUTED)
	result.set_color("font_color","Label",PAPER)
	result.set_stylebox("panel","TooltipPanel",Grimoire.frame(18))
	result.set_color("font_color","TooltipLabel",PAPER)
	result.set_font_size("font_size","TooltipLabel",24)
	result.set_stylebox("background","ProgressBar",style(INK,GOLD.darkened(0.5),2))
	result.set_stylebox("fill","ProgressBar",style(BLUE,Color.TRANSPARENT,0))
	result.set_constant("separation","VBoxContainer",16)
	result.set_constant("separation","HBoxContainer",20)
	var rule := StyleBoxLine.new()
	rule.color = Color(GOLD,0.32)
	rule.thickness = 1
	result.set_stylebox("separator","HSeparator",rule)
	for bar in ["VScrollBar","HScrollBar"]:
		result.set_stylebox("scroll",bar,style(INK,Color("#3e3529"),4))
		result.set_stylebox("grabber",bar,style(Color("#88734c"),GOLD.darkened(0.35),4))
		result.set_stylebox("grabber_highlight",bar,style(GOLD,BLUE,4))
		result.set_stylebox("grabber_pressed",bar,style(BLUE,GOLD,4))
	return result

static func page(parent: Control, top: int = 100) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair in [["left",64],["right",64],["top",top],["bottom",42]]:
		margin.add_theme_constant_override("margin_"+str(pair[0]),int(pair[1]))
	parent.add_child(margin)
	var page := column(margin,20)
	page.modulate.a = 0.0
	var enter := page.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	enter.tween_property(page,"modulate:a",1.0,0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return page

static func column(parent: Node, gap: int = 16, expand: bool = false) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",gap)
	if expand:
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

static func row(parent: Node, gap: int = 20) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

static func card(parent: Node, edge: Color = Color("#43536b"), expand: bool = false) -> PanelContainer:
	var panel := PanelSurface.new()
	panel.accent = edge
	panel.add_theme_stylebox_override("panel",style(CARD,edge))
	if expand: panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	return panel

static func folio(parent: Node, edge: Color = GOLD, expand: bool = false) -> PanelContainer:
	var panel := card(parent,edge,expand)
	panel.surface_kind = "folio"
	panel.add_theme_stylebox_override("panel",style(Color("#24272a"),edge,30))
	return panel

static func emblem(parent: Node, kind: String = "book", height: float = 96, color: Color = GOLD) -> Control:
	var seal := Emblem.new()
	seal.symbol = kind
	seal.accent = color
	seal.custom_minimum_size = Vector2(height,height)
	parent.add_child(seal)
	return seal

static func text(parent: Node, value: String, size: int = 28, color: Color = PAPER, center: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if size >= 36: label.theme_type_variation = "ArchiveTitle"
	parent.add_child(label)
	return label

static func section(parent: Node, number: String, heading: String, caption: String = "") -> Label:
	text(parent,number,22,GOLD)
	var title := text(parent,heading,48,PAPER)
	if not caption.is_empty(): text(parent,caption,25,MUTED)
	return title

static func dress_button(item: Button, role: String = "secondary") -> void:
	if item is GameButton: item.role = role
	item.set_meta("archive_role",role)
	item.add_theme_color_override("font_color",PAPER)
	item.add_theme_color_override("font_hover_color",Color.WHITE)
	item.add_theme_color_override("font_focus_color",PAPER)
	item.add_theme_color_override("font_pressed_color",GOLD)
	item.add_theme_color_override("font_disabled_color",Color("#728083"))
	var icon_id := ""
	if role == "primary": icon_id = "book"
	elif item.text.contains("设置"): icon_id = "settings"
	elif item.text.contains("退出"): icon_id = "close"
	elif item.text.contains("返回"): icon_id = "back"
	elif item.text.contains("继续"): icon_id = "confirm"
	var path := "res://assets/ui/archive/icons/"+icon_id+".svg"
	if not icon_id.is_empty() and ResourceLoader.exists(path):
		item.icon = load(path)
		item.add_theme_constant_override("icon_max_width",24)
	var fill := Color("#25282c") if role == "choice" else CARD
	var edge := Color("#736853")
	if role == "primary": fill = Color("#493c28"); edge = GOLD
	elif role == "danger": fill = Color("#342327"); edge = RED.darkened(0.25)
	item.add_theme_stylebox_override("normal",button_style(fill,edge))
	item.add_theme_stylebox_override("hover",button_style(fill.lightened(0.10),GOLD))
	item.add_theme_stylebox_override("pressed",button_style(fill.darkened(0.10),BLUE))
	item.add_theme_stylebox_override("disabled",button_style(INK,Color("#44464a")))
	# Native focus/hover is a short rule and arrow, shared with the title.
	item.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	item.queue_redraw()

static func button_style(fill: Color, edge: Color) -> StyleBox:
	var box := Quiet.entry("normal",edge,18)
	if edge == GOLD: box = Quiet.entry("hover",edge,18)
	elif edge == BLUE: box = Quiet.entry("pressed",edge,18)
	elif edge == Color("#44464a"): box = Quiet.entry("disabled",edge,18)
	box.content_margin_left = 38
	box.content_margin_right = 28
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

static func button(host: Control, parent: Control, caption: String, callback: Callable, primary: bool = false) -> Button:
	var item: Button = host._button(parent,caption,Vector2.ZERO,Vector2.ZERO,callback,Color("#665138") if primary else CARD)
	item.custom_minimum_size.y = 72
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dress_button(item,"primary" if primary else ("danger" if caption in ["退出游戏","确认"] else "secondary"))
	if host.get_viewport().gui_get_focus_owner() == null: item.grab_focus()
	return item

static func space(parent: Node) -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	return spacer

static func disable_buttons(node: Node) -> void:
	if node is BaseButton: node.disabled = true
	for child in node.get_children(): disable_buttons(child)
