extends Control
## Title direction study: native typography over existing approved corridor art.
## This view owns presentation only; all actions use the existing main controller.

const QuietStyle = preload("res://scripts/ui/quiet_style.gd")
const INK := QuietStyle.INK
const IVORY := QuietStyle.PAPER
const COPPER := QuietStyle.COPPER
const QUIET := Color("#929f9f")
const CORRIDOR := "res://assets/backgrounds/library_corridor.jpg"
var host: Control
var illustration_path: String = CORRIDOR

class MenuEntry extends Button:
	func _ready() -> void:
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		pressed.connect(queue_redraw)

	func _draw() -> void:
		if disabled or not (has_focus() or is_hovered()): return
		var color := Color("#be9a74")
		var y := size.y * 0.5
		draw_polyline(PackedVector2Array([Vector2(5,y-6),Vector2(12,y),Vector2(5,y+6)]),color,1.6,true)
		draw_line(Vector2(38,size.y-5),Vector2(136,size.y-5),Color(color,0.6),1.0,true)

static func build(controller: Control) -> Control:
	var view := load("res://scripts/ui/frontispiece_title.gd").new() as Control
	view.host = controller
	view.name = "FrontispieceTitle"
	controller.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return view

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var matte := ColorRect.new()
	matte.color = INK
	matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(matte)
	matte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_illustration()
	_build_binding()
	_build_type()

func _build_illustration() -> void:
	# No new image or painting is generated: preserve the original source file.
	if illustration_path.is_empty() or not ResourceLoader.exists(illustration_path): return
	var illustration := TextureRect.new()
	illustration.name = "LibraryFrontispiece"
	illustration.texture = load(illustration_path)
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(illustration)
	illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	illustration.anchor_left = 0.32
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float grey = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 ink = mix(vec3(grey), source.rgb, 0.38);
    ink = mix(ink, vec3(0.07, 0.11, 0.13), 0.18) * 0.82;
    float edge = smoothstep(0.02, 0.46, UV.x);
    float top = smoothstep(0.0, 0.12, UV.y);
    float foot = 1.0 - smoothstep(0.80, 1.0, UV.y);
    COLOR = vec4(ink, source.a * edge * mix(0.55, 1.0, top) * mix(0.45, 1.0, foot));
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	illustration.material = material

func _build_type() -> void:
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["SimSun", "Noto Serif CJK SC", "Songti SC"])
	serif.fallbacks = [host.ui_font]
	var latin := SystemFont.new()
	latin.font_names = PackedStringArray(["Georgia", "Cambria", "Times New Roman"])
	latin.fallbacks = [host.ui_font]
	var margin := MarginContainer.new()
	margin.name = "TitleTypesetting"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.anchor_left = 0.095
	margin.anchor_right = 0.53
	margin.anchor_top = 0.14
	margin.anchor_bottom = 0.88
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	margin.add_child(column)
	var imprint_row := HBoxContainer.new()
	imprint_row.add_theme_constant_override("separation",20)
	column.add_child(imprint_row)
	var emblem_path := "res://assets/ui/frontispiece/tower_book.svg"
	if ResourceLoader.exists(emblem_path):
		var emblem := TextureRect.new()
		emblem.texture = load(emblem_path)
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.custom_minimum_size = Vector2(44,56)
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		imprint_row.add_child(emblem)
	var english_title := _text(imprint_row,"WORDROGUE",24,COPPER,latin)
	english_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gap(column,24)
	var heading := _text(column,"遗忘书塔",132,IVORY,serif)
	heading.name = "GameTitle"
	_gap(column,10)
	_text(column,"Words are your weapons.",30,QUIET,latin)
	_gap(column,36)
	_text(column,"你遗忘的词，\n将成为下一次冒险的敌人。",27,IVORY,host.ui_font)
	var breathing_room := Control.new()
	breathing_room.custom_minimum_size.y = 48
	breathing_room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(breathing_room)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	column.add_child(actions)
	var start := _menu(actions,"开始冒险",host._start_adventure,true)
	start.name = "StartAdventure"
	start.disabled = not WordBank.load_error.is_empty()
	_menu(actions,"声音设置",host.open_title_settings).name = "TitleSettings"
	_menu(actions,"离开书塔",host.request_quit).name = "TitleQuit"
	if not start.disabled: start.grab_focus()
	var footer := MarginContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.anchor_left = 0.095
	footer.anchor_top = 0.92
	footer.anchor_right = 0.78
	footer.anchor_bottom = 0.99
	var copy := "掌握度自动保存于本地"
	if not SaveData.load_warning.is_empty(): copy = SaveData.load_warning
	if not WordBank.load_error.is_empty(): copy = WordBank.load_error
	_text(footer,copy,21,QUIET,host.ui_font)
	var imprint := Label.new()
	imprint.text = "黑猫kuroneko  /  免费试玩版"
	imprint.add_theme_font_size_override("font_size",20)
	imprint.add_theme_color_override("font_color",QUIET)
	imprint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	imprint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	imprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(imprint)
	imprint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	imprint.anchor_left = 0.66
	imprint.anchor_right = 0.95
	imprint.anchor_top = 0.92
	imprint.anchor_bottom = 0.99

func _text(parent: Control, value: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _gap(parent: Control, height: float) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(gap)

func _menu(parent: Control, value: String, callback: Callable, primary: bool = false) -> Button:
	var button := MenuEntry.new()
	button.text = value
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0,68)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font",host.ui_font)
	button.add_theme_font_size_override("font_size",32 if primary else 27)
	button.add_theme_color_override("font_color",IVORY if primary else QUIET)
	button.add_theme_color_override("font_hover_color",Color.WHITE)
	button.add_theme_color_override("font_focus_color",IVORY)
	button.add_theme_color_override("font_pressed_color",COPPER)
	button.add_theme_color_override("font_disabled_color",Color("#616c70"))
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.content_margin_left = 38
		style.content_margin_right = 24
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(func() -> void:
		AudioBus.play_event("ui_click")
		callback.call())
	parent.add_child(button)
	return button

func _build_binding() -> void:
	# A single book-spine line is the shared ornament, not a frame around each item.
	var binding := Control.new()
	binding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(binding)
	binding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	binding.resized.connect(binding.queue_redraw)
	binding.draw.connect(func() -> void:
		var x := binding.size.x * 0.064
		binding.draw_line(Vector2(x,binding.size.y*0.14),Vector2(x,binding.size.y*0.88),Color(COPPER,0.28),1.0,true)
		binding.draw_line(Vector2(x,binding.size.y*0.14),Vector2(x,binding.size.y*0.14+44),COPPER,2.0,true))
