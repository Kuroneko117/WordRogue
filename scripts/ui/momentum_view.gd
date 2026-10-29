extends HBoxContainer

# Read-only presentation. The combat controller owns all momentum rules.
var caption := Label.new()
var warning_label := Label.new()
var cells := HBoxContainer.new()
var segments: Array[Panel] = []
var displayed_value := 0
var displayed_threshold := 0
var alert := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 36
	add_theme_constant_override("separation",10)
	caption.add_theme_font_size_override("font_size",20)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	cells.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cells.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cells.add_theme_constant_override("separation",7)
	cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cells)
	warning_label.custom_minimum_size.x = 90
	warning_label.add_theme_font_size_override("font_size",20)
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warning_label)
	tooltip_text = "连续答对积累敌人蓄势；满格后的攻击不可打断。\n查看上方攻击预告，选择守护或爆发应对。"

func display(value: int, threshold: int, warning: bool, cooldown: int) -> void:
	displayed_threshold = maxi(1,threshold)
	displayed_value = clampi(value,0,displayed_threshold)
	alert = warning
	if segments.size() != displayed_threshold:
		for segment in segments:
			cells.remove_child(segment)
			segment.queue_free()
		segments.clear()
		for i in displayed_threshold:
			var segment := Panel.new()
			segment.custom_minimum_size = Vector2(18,18)
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cells.add_child(segment)
			segments.append(segment)
	var color := Color("#ef7b83") if alert else Color("#e1b466")
	caption.text = "蓄势 %d/%d" % [displayed_value,displayed_threshold]
	caption.add_theme_color_override("font_color",color)
	warning_label.text = "不可打断" if alert else ("冷却%d题" % cooldown if cooldown > 0 else "积蓄中")
	warning_label.add_theme_color_override("font_color",color if alert else Color("#b8a99a"))
	for i in segments.size():
		var style := StyleBoxFlat.new()
		style.bg_color = color if i < displayed_value else Color("#302e33")
		style.border_color = Color("#ffc2a0") if alert else Color("#74604a")
		style.set_border_width_all(2 if alert else 1)
		style.set_corner_radius_all(4)
		segments[i].add_theme_stylebox_override("panel",style)
