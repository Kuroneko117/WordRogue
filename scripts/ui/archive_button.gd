extends Button
## Native menu entry, using the same small arrow and short rule as the title.
var role := "secondary"
var motion: Tween

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(func() -> void: pivot_offset = size/2; queue_redraw())
	mouse_entered.connect(_emphasize.bind(true))
	mouse_exited.connect(_emphasize.bind(false))
	focus_entered.connect(_emphasize.bind(true))
	focus_exited.connect(_emphasize.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)

func _emphasize(entering: bool) -> void:
	queue_redraw()
	if disabled:
		scale = Vector2.ONE
		return
	if motion and motion.is_valid(): motion.kill()
	motion = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	motion.tween_property(self,"scale",Vector2.ONE,0.10)

func _press() -> void:
	if disabled: return
	if motion and motion.is_valid(): motion.kill()
	scale = Vector2.ONE*0.995

func _release() -> void:
	if not is_inside_tree(): return
	_emphasize(is_hovered() or has_focus())

func _draw() -> void:
	var accent := Color("#be9a74") if role != "danger" else Color("#cb8b89")
	if disabled: accent.a = 0.28
	elif is_hovered() or has_focus(): accent = Color("#dfd8c8")
	if (has_focus() or is_hovered()) and not disabled:
		var y := size.y/2
		draw_polyline(PackedVector2Array([Vector2(10,y-5),Vector2(16,y),Vector2(10,y+5)]),accent,1.4,true)
		draw_line(Vector2(size.x/2-45,size.y-7),Vector2(size.x/2+45,size.y-7),Color(accent,0.7),1,true)
