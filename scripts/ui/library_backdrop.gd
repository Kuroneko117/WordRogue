extends Control
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(1920,1080))
	draw_rect(Rect2(0,0,1920,1080),Color("#101923"))
	for bay in 6:
		var x := float(bay)*340.0-55
		draw_rect(Rect2(x,130,300,680),Color("#16232e"))
		for shelf in 5:
			var y := 180.0+shelf*130
			for book in 11:
				var h := 54.0+float((book*17+bay*19+shelf*23)%45)
				var color: Color = [Color("#23333f"),Color("#302b31"),Color("#293a42"),Color("#3c3431")][(book+bay+shelf)%4]
				draw_rect(Rect2(x+8+book*26,y+105-h,19,h),color)
				draw_line(Vector2(x+8+book*26,y+96-h),Vector2(x+25+book*26,y+96-h),Color("#5d5140"),2)
			draw_rect(Rect2(x,y+108,300,7),Color("#524434"))
		draw_rect(Rect2(x+299,122,16,731),Color("#3a3835"))
	for x in [330.0,1590.0]:
		for ring in 6:
			draw_circle(Vector2(x,195),95-ring*12,Color(0.8,0.55,0.24,0.012))
		draw_line(Vector2(x,80),Vector2(x,195),Color("#6f5940"),3)
		draw_circle(Vector2(x,195),12,Color("#d0a467"))
	draw_rect(Rect2(0,825,1920,255),Color("#141c25"))
	for i in 6:
		draw_line(Vector2(960,810),Vector2(-400+i*550,1080),Color("#243039"),2)
