extends Node2D

var mode := "paper"
var progress := 0.0
var life := 0.65
var age := 0.0
var red := false
var endpoint := Vector2.ZERO
var image: Texture2D
var image_size := Vector2(240,300)

func _process(delta: float) -> void:
	age += delta
	if life > 0 and age >= life: queue_free()
	else: queue_redraw()

func _draw() -> void:
	var ink := Color("#c271bd") if not red else Color("#d26670")
	var gold := Color("#f4d397")
	var paper := Color("#ece0c0") if not red else Color("#ce7375")
	if mode == "lunge":
		for i in 5:
			var t := clampf(progress-float(i)*0.055,0.0,1.0)
			var p := endpoint*t
			if image != null: draw_texture_rect(image,Rect2(p-image_size/2.0,image_size),false,Color(0.5,0.25,0.65,0.12*(1.0-float(i)/6.0)))
			else: draw_circle(p,25,Color(ink,0.2))
	elif mode in ["curse","judgment","phase","charge"]:
		var radius := 150.0 if mode == "judgment" else (145.0 if mode == "phase" else 65.0)
		var alpha := 0.65 if mode == "phase" else clampf(1.0-age/maxf(life,0.01)*0.45,0.0,1.0)
		var grow := 0.6+progress*0.4
		draw_circle(Vector2.ZERO,radius*grow,Color(ink,0.055))
		draw_arc(Vector2.ZERO,radius*grow,0,TAU,64,Color(ink,alpha),3.5,true)
		draw_arc(Vector2.ZERO,radius*grow*0.78,age,age+TAU,64,Color(gold if red else ink,alpha),2,true)
		for i in 8:
			var angle := float(i)*TAU/8.0+age*0.7
			var p := Vector2.from_angle(angle)*radius*grow
			if mode == "phase":
				draw_set_transform(p,angle,Vector2(0.65,0.65))
				_book(gold)
				draw_set_transform(Vector2.ZERO)
			else:
				draw_line(Vector2.from_angle(angle)*radius*0.25,p,Color(ink,alpha*0.5),2,true)
				draw_line(p-Vector2(5,5),p+Vector2(5,5),Color(gold if red else ink,alpha),3,true)
		if mode == "judgment":
			if progress > 0.6:
				draw_line(Vector2.ZERO,endpoint,Color(ink,alpha*0.35),15,true)
				draw_line(Vector2.ZERO,endpoint,Color(gold,alpha*0.7),4,true)
			for i in 3: draw_line(Vector2(-70+float(i)*70,-120),Vector2(-70+float(i)*70,110),Color(gold,0.45*(1.0-age/life)),5,true)
	elif mode == "book": _book(gold)
	elif mode == "seal":
		for i in 5:
			var p := Vector2(-float(i)*28,sin(age*12+float(i))*12)
			draw_line(p,p+Vector2(-28,0),Color("#6b344b"),6,true)
			draw_set_transform(p,0.35+sin(age*7+float(i))*0.2)
			draw_rect(Rect2(-10,-15,20,30),Color("#3a172e"))
			draw_rect(Rect2(-10,-15,20,30),ink,false,2)
			draw_line(Vector2(-6,0),Vector2(6,0),gold,1.5,true)
			draw_set_transform(Vector2.ZERO)
	else:
		var heavy := mode == "torn"
		for i in (6 if heavy else 3):
			var p := Vector2(-float(i)*22,float(i-1)*18)
			draw_set_transform(p,(-0.45 if heavy else 0.4)+float(i)*0.16,Vector2.ONE*(2.1 if heavy and i == 0 else 1.0))
			var shape := PackedVector2Array([Vector2(-18,-25),Vector2(28,-16),Vector2(16,22),Vector2(-24,16)])
			draw_colored_polygon(shape,paper)
			draw_polyline(PackedVector2Array([shape[0],shape[1],shape[2],shape[3],shape[0]]),gold if heavy else ink,2,true)
			draw_line(Vector2(-12,-6),Vector2(14,-3),Color("#614e57"),2,true)
			draw_set_transform(Vector2.ZERO)

func _book(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(-35,-18),Vector2(-35,28),Vector2(0,43)]),Color("#47242f"))
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(35,-18),Vector2(35,28),Vector2(0,43)]),color)
	draw_line(Vector2.ZERO,Vector2(0,43),Color("#f1dbaa"),3,true)
	for i in 3: draw_line(Vector2(5,8+float(i)*9),Vector2(28,float(i)*9),Color("#7c424a"),2,true)
