extends Node2D

var mode := "aegis"
var progress := 1.0
var phase := 0.0
var actor: Control

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var gold := Color("#ecd08b")
	var blue := Color("#79dce9")
	if mode == "aegis":
		var radius := Vector2(160,220) if actor == null else Vector2(actor.size.x*0.43,minf(235.0,actor.size.y*0.44))
		draw_set_transform(Vector2.ZERO,0,Vector2(1,radius.y/radius.x))
		draw_circle(Vector2.ZERO,radius.x,Color(0.20,0.63,0.8,0.08*progress),true,-1,true)
		draw_arc(Vector2.ZERO,radius.x,0,TAU,80,Color(blue,0.7*progress),3,true)
		draw_arc(Vector2.ZERO,radius.x-10,phase*0.2,phase*0.2+TAU*0.8,64,Color(gold,0.75*progress),2,true)
		for i in 8:
			var angle := i*TAU/8.0
			var point := Vector2(cos(angle),sin(angle))*(radius.x-5)
			draw_line(point+Vector2(-5,-6),point+Vector2(5,6),Color(gold,progress),2,true)
			draw_line(point+Vector2(-5,6),point+Vector2(5,-6),Color(gold,progress),2,true)
		draw_set_transform(Vector2.ZERO)
	else:
		var radius := 20.0+progress*45.0
		for ring in 2:
			draw_arc(Vector2.ZERO,radius+ring*12,phase*(1 if ring==0 else -1),phase*(1 if ring==0 else -1)+TAU*0.85,64,gold if ring==0 else blue,3,true)
		for i in 6:
			var angle := i*TAU/6.0-phase*1.3
			var p := Vector2(cos(angle),sin(angle))*(radius+8)
			draw_line(p*0.6,p,gold,3,true)
		draw_circle(Vector2.ZERO,12+progress*10,Color(blue,0.35),true,-1,true)
