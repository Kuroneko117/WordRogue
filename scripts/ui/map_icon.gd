extends Button

var kind := "normal"
var state := "locked"
var current := false

func _ready() -> void:
	text = ""
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not disabled else Control.CURSOR_ARROW
	for style in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(style,StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	var center := size/2.0
	var radius := minf(size.x,size.y)*0.43
	var accent := Color("#be9a74") if state == "available" or current else (Color("#8caeb6") if state == "complete" else Color("#7e898b"))
	if kind == "boss" and state not in ["complete","skipped"]: accent = Color("#b28682")
	if state == "skipped": accent = Color("#535d5f")
	if is_hovered() and not disabled: accent = accent.lightened(0.25)
	draw_circle(center,radius,Color("#10191d"))
	draw_arc(center,radius,0,TAU,64,accent,2 if state == "available" or current else 1,true)
	if state == "available":
		draw_polyline(PackedVector2Array([center+Vector2(-radius-11,-5),center+Vector2(-radius-5,0),center+Vector2(-radius-11,5)]),accent,1.5,true)
	if has_focus(): draw_arc(center,radius+6,0,TAU,64,Color("#dfd8c8"),1.2,true)
	draw_set_transform(center,0,Vector2.ONE*(radius/43.0))
	draw_symbol(self,kind,accent)
	if state == "complete":
		draw_circle(Vector2(31,30),10,Color("#10191d"))
		draw_polyline(PackedVector2Array([Vector2(25,30),Vector2(30,35),Vector2(38,25)]),accent,3,true)
	elif state == "skipped":
		draw_line(Vector2(-28,-28),Vector2(28,28),Color("#6c616a"),2,true)
	draw_set_transform(Vector2.ZERO)

static func draw_symbol(node: CanvasItem, type: String, color: Color) -> void:
	match type:
		"event": node.draw_string(ThemeDB.fallback_font,Vector2(-14,16),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,48,color)
		"normal","进攻":
			for direction in [-1.0,1.0]:
				node.draw_line(Vector2(-21*direction,22),Vector2(19*direction,-20),color,5,true)
				node.draw_line(Vector2(-24*direction,9),Vector2(-9*direction,22),color,3,true)
				node.draw_colored_polygon(PackedVector2Array([Vector2(19*direction,-20),Vector2(13*direction,-13),Vector2(17*direction,-24)]),color)
		"elite","boss":
			node.draw_arc(Vector2(0,-5),19,PI,TAU+PI*0.2,32,color,3,true)
			node.draw_polyline(PackedVector2Array([Vector2(-18,-3),Vector2(-12,17),Vector2(12,17),Vector2(18,-3)]),color,3,true)
			node.draw_circle(Vector2(-7,-3),3.5,color)
			node.draw_circle(Vector2(7,-3),3.5,color)
			for x in [-6,0,6]: node.draw_line(Vector2(x,12),Vector2(x,22),color,2,true)
			if type == "boss":
				node.draw_polyline(PackedVector2Array([Vector2(-23,-20),Vector2(-27,-35),Vector2(-10,-25),Vector2(0,-39),Vector2(10,-25),Vector2(27,-35),Vector2(23,-20)]),color,3,true)
			else: node.draw_line(Vector2(-25,25),Vector2(25,-25),Color(color,0.65),2,true)
		"memory","记忆":
			node.draw_polyline(PackedVector2Array([Vector2(0,-14),Vector2(-25,-22),Vector2(-25,17),Vector2(0,25),Vector2(25,17),Vector2(25,-22),Vector2(0,-14),Vector2(0,25)]),color,3,true)
			for y in [-8,1,10]:
				node.draw_line(Vector2(-20,y-5),Vector2(-6,y),color,2,true)
				node.draw_line(Vector2(6,y),Vector2(20,y-5),color,2,true)
		"rest","续航":
			node.draw_colored_polygon(PackedVector2Array([Vector2(0,-32),Vector2(17,-8),Vector2(20,9),Vector2(0,20),Vector2(-20,9),Vector2(-13,-13),Vector2(-4,-5)]),Color(color,0.28))
			node.draw_polyline(PackedVector2Array([Vector2(0,-32),Vector2(17,-8),Vector2(20,9),Vector2(0,20),Vector2(-20,9),Vector2(-13,-13),Vector2(-4,-5)]),color,2.5,true)
			node.draw_line(Vector2(-25,27),Vector2(25,19),color,4,true)
			node.draw_line(Vector2(-25,19),Vector2(25,27),color,4,true)
		"treasure","补给":
			node.draw_rect(Rect2(-26,-10,52,35),Color(color,0.18))
			node.draw_rect(Rect2(-26,-10,52,35),color,false,3)
			node.draw_arc(Vector2(0,-8),26,PI,TAU,32,color,3,true)
			node.draw_rect(Rect2(-5,-5,10,17),color,false,2)
		"防御":
			node.draw_polyline(PackedVector2Array([Vector2(0,-29),Vector2(24,-19),Vector2(20,8),Vector2(0,31),Vector2(-20,8),Vector2(-24,-19),Vector2(0,-29)]),color,3,true)
			node.draw_line(Vector2(0,-20),Vector2(0,20),color,2,true)
		"法力":
			node.draw_colored_polygon(PackedVector2Array([Vector2(0,-29),Vector2(18,0),Vector2(0,29),Vector2(-18,0)]),Color(color,0.25))
			node.draw_polyline(PackedVector2Array([Vector2(0,-29),Vector2(18,0),Vector2(0,29),Vector2(-18,0),Vector2(0,-29)]),color,3,true)
		"report":
			node.draw_rect(Rect2(-19,-28,38,55),color,false,3)
			for y in [-15,-3,9]: node.draw_line(Vector2(-11,y),Vector2(11,y),color,2,true)
		_:
			node.draw_polyline(PackedVector2Array([Vector2(-18,19),Vector2(0,-21),Vector2(18,19)]),color,4,true)
			node.draw_line(Vector2(-16,9),Vector2(16,9),color,3,true)
