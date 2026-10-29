extends RefCounted
## Existing presentation API, unified with the quiet title. No combat rules.
const Quiet = preload("res://scripts/ui/quiet_style.gd")
const ROOT := "res://assets/ui/grimoire/"
const GOLD := Quiet.COPPER
const PAPER_INK := Quiet.PAPER
const PALE := Quiet.PAPER
const COLORS := {"arcane":Quiet.COPPER,"aegis":Quiet.BLUE,"memory":Color("#b6a1bd")}
static var textures: Dictionary = {}

static func cover(padding: int = 28) -> StyleBox:
	return Quiet.sheet(padding,Quiet.COPPER,true)

static func texture(file: String) -> Texture2D:
	var path := ROOT+file
	if not textures.has(path): textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return textures[path]

static func frame(padding: int = 22, tint: Color = Color.WHITE, _file: String = "") -> StyleBox:
	return Quiet.sheet(padding,Quiet.COPPER if tint == Color.WHITE else tint)

static func parchment(state: String = "normal", answer: bool = false) -> StyleBox:
	# Legacy method name retained for original battle and feedback callers.
	var accent := Quiet.COPPER
	if state == "correct": accent = Color("#97b99a")
	elif state == "wrong": accent = Quiet.RED
	elif state == "weak": accent = Color("#c4a0bc")
	var box := Quiet.entry(state,accent,18 if answer else 40,true)
	if answer:
		box.content_margin_left = 70
		box.content_margin_right = 28
	else:
		box.content_margin_left = 48
		box.content_margin_right = 48
		box.bg_color = Color(Quiet.INK,0.36)
	if state in ["correct","wrong"]:
		box.border_width_bottom = 3
		box.border_color = accent
		box.bg_color = Color("#21332d") if state == "correct" else Color("#392729")
	return box

static func style_answer(button: Button, state: String = "normal") -> void:
	for key in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(key,parchment(state if state != "normal" else key,true))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Quiet.PAPER
	focus.border_width_bottom = 2
	button.add_theme_stylebox_override("focus",focus)
	for key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:
		button.add_theme_color_override(key,Quiet.PAPER if state != "normal" or not button.disabled else Quiet.MUTED)
	button.set_meta("answer_visual_state",state)
	button.queue_redraw()

static func style_spell(button: Button, id: String, selected: bool) -> void:
	var accent: Color = COLORS[id]
	for key in ["normal","hover","pressed","disabled"]:
		var box := Quiet.entry("selected" if selected and key == "normal" else key,accent,17,true)
		if key == "normal" and not selected: box.bg_color = Color(Quiet.INK,0.28)
		box.content_margin_left = 70
		box.content_margin_right = 12
		button.add_theme_stylebox_override(key,box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Quiet.PAPER
	focus.border_width_bottom = 2
	button.add_theme_stylebox_override("focus",focus)
	button.add_theme_color_override("font_color",accent if selected else PALE)
	button.add_theme_color_override("font_disabled_color",Color("#859092"))
	button.set_meta("spell_selected",selected)
	button.queue_redraw()
