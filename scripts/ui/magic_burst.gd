extends Node2D

var palette := "player"
var time := 0.0
var life := 0.42

func _process(delta: float) -> void:
	time += delta
	if time >= life:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var t := time/life
	var primary := Color("#85e9f2") if palette == "player" else (Color("#d76c76") if palette == "boss" else Color("#c280bd"))
	var accent := Color("#f4d08a") if palette != "ink" else Color("#685284")
	var alpha := 1.0-t
	var radius := 20.0+t*65.0
	draw_arc(Vector2.ZERO,radius,0,TAU,48,Color(primary,alpha*0.7),2.5,true)
	for i in 8:
		var angle := i*TAU/8.0
		var direction := Vector2(cos(angle),sin(angle))
		draw_line(direction*(radius*0.4),direction*(radius+14),Color(accent,alpha),3,true)
		var p := direction*(25.0+t*85.0)
		if palette == "player":
			draw_circle(p,3.5,Color(primary,alpha),true,-1,true)
		else:
			draw_set_transform(p,angle+t)
			draw_rect(Rect2(-4,-7,8,14),Color(accent,alpha*0.8))
			draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO,20*(1.0-t),Color(primary,alpha*0.4),true,-1,true)
