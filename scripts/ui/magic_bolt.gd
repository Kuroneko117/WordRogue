extends Node2D
var tint := Color("#8cdfea")
var direction := 1.0
var palette := "player"
var spell := "arcane"
var phase := 0.0
func _process(delta: float) -> void:
	phase += delta*8.0
	queue_redraw()
func _draw() -> void:
	var accent := Color("#efd296") if palette != "ink" else Color("#6c4b84")
	for i in 9:
		var p := Vector2(-direction*i*17,sin(phase-i*0.6)*5)
		draw_circle(p,18-i*1.6,Color(tint,0.45-i*0.045),true,-1,true)
		if i > 1 and i%2 == 0:
			draw_line(p+Vector2(-direction*10,0),p+Vector2(direction*8,0),Color(accent,0.7-i*0.06),2,true)
	draw_arc(Vector2.ZERO,25,phase,phase+TAU*0.75,32,Color(accent,0.75),2,true)
	draw_circle(Vector2.ZERO,30,Color(tint,0.14),true,-1,true)
	draw_circle(Vector2.ZERO,15,tint,true,-1,true)
	draw_circle(Vector2.ZERO,6,accent,true,-1,true)
	if spell == "memory":
		for i in 6:
			var angle := phase*0.5+i*TAU/6.0
			var p := Vector2(cos(angle),sin(angle))*32
			draw_line(p*0.7,p,accent,3,true)
		draw_arc(Vector2.ZERO,35,0,TAU,40,Color(tint,0.6),2,true)
	if palette == "boss":
		for i in 3:
			var angle := phase+i*TAU/3
			draw_set_transform(Vector2(cos(angle),sin(angle))*35,angle)
			draw_rect(Rect2(-4,-7,8,14),accent)
			draw_set_transform(Vector2.ZERO)
