extends Button
## Native Button retains keyboard focus, accessibility and its pressed signal.
const Grimoire = preload("res://scripts/ui/battle_theme.gd")
var spell_id := ""
var answer_index := -1
var motion: Tween

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(func() -> void: pivot_offset = size/2; queue_redraw())
	mouse_entered.connect(_emphasis.bind(true))
	mouse_exited.connect(_emphasis.bind(false))
	focus_entered.connect(_emphasis.bind(true))
	focus_exited.connect(_emphasis.bind(false))
	button_down.connect(func() -> void:
		if not disabled: scale = Vector2.ONE*0.985)
	button_up.connect(func() -> void: _emphasis(is_hovered() or has_focus()))

func _emphasis(active: bool) -> void:
	if motion and motion.is_valid(): motion.kill()
	motion = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	motion.tween_property(self,"scale",Vector2.ONE,0.12)
	queue_redraw()

func _draw() -> void:
	if not spell_id.is_empty():
		_spell_glyph(Vector2(35,size.y/2),Color("#748082") if disabled else Grimoire.COLORS[spell_id])
		if bool(get_meta("spell_selected",false)):
			var color: Color = Grimoire.COLORS[spell_id]
			draw_line(Vector2(28,size.y-10),Vector2(size.x-28,size.y-10),Color(color,0.85),2,true)
	elif answer_index >= 0:
		var center := Vector2(35,size.y/2)
		draw_line(center+Vector2(20,-14),center+Vector2(20,14),Color(Grimoire.GOLD,0.35),1,true)
		var font := get_theme_font("font")
		var letter: String = ["A","B","C","D"][answer_index]
		draw_string(font,center+Vector2(-9,9),letter,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Grimoire.GOLD)

func _spell_glyph(center: Vector2, color: Color) -> void:
	draw_set_transform(center)
	if spell_id == "arcane":
		draw_polyline(PackedVector2Array([Vector2(4,-21),Vector2(-13,3),Vector2(2,3),Vector2(-4,22),Vector2(15,-4),Vector2(0,-4),Vector2(4,-21)]),color,1.8,true)
	elif spell_id == "aegis":
		draw_polyline(PackedVector2Array([Vector2(0,-22),Vector2(19,-13),Vector2(16,8),Vector2(0,23),Vector2(-16,8),Vector2(-19,-13),Vector2(0,-22)]),color,1.8,true)
		draw_line(Vector2(0,-11),Vector2(0,11),Color(color,0.55),1,true)
	else:
		draw_polyline(PackedVector2Array([Vector2(-20,-12),Vector2(0,-6),Vector2(20,-12),Vector2(20,17),Vector2(0,23),Vector2(-20,17),Vector2(-20,-12)]),color,1.6,true)
		draw_line(Vector2(0,-6),Vector2(0,23),color,1,true)
		for side in [-1,1]:
			draw_line(Vector2(side*10,-22),Vector2(side*10,-16),color,1.4,true)
		draw_line(Vector2(0,-28),Vector2(0,-18),color,1.4,true)
	draw_set_transform(Vector2.ZERO)
