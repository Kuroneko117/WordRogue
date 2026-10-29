extends Node2D

var mode := "ink_orb"
var family := "ink"
var progress := 0.0
var age := 0.0
var life := 0.65
var endpoint := Vector2.ZERO
var image: Texture2D
var image_size := Vector2(240,300)
const COLORS := {"ink":Color("#9a65bb"),"dust":Color("#a39aab"),"paper":Color("#c7b58f"),"mimic":Color("#aa63bd"),"wisp":Color("#669df5"),"margin":Color("#d35c9f"),"archive":Color("#b19acd"),"boss":Color("#d0757c")}

func _process(delta: float) -> void:
	age += delta
	if life > 0 and age >= life: queue_free()
	else: queue_redraw()

func _draw() -> void:
	var color: Color = COLORS.get(family,COLORS.ink)
	var gold := Color("#d6b574")
	var fade := clampf(1.0-age/maxf(life,0.01),0.0,1.0)
	if mode == "trail":
		for i in 5:
			var p := endpoint*clampf(progress-float(i)*0.055,0.0,1.0)
			if image != null: draw_texture_rect(image,Rect2(p-image_size/2.0,image_size),false,Color(color,0.14*(1.0-float(i)/6.0)))
			else:
				draw_set_transform(p)
				_flame(color,0.23) if family == "wisp" else draw_circle(Vector2.ZERO,24,Color(color,0.2))
			draw_set_transform(Vector2.ZERO)
	elif mode in ["ink_orb","ink_wave"]:
		var size_factor := 1.75 if mode == "ink_wave" else 1.0
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*size_factor)
		for i in 9:
			draw_circle(Vector2(i*16,sin(age*13-i)*8),maxf(2,15-i*1.4),Color(color,0.55-i*0.05))
		draw_circle(Vector2.ZERO,24,Color(color,0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-27,0),Vector2(0,-18),Vector2(19,-7),Vector2(21,10),Vector2(0,20)]),color)
		draw_set_transform(Vector2.ZERO)
	elif mode == "fist":
		draw_rect(Rect2(-35,-25,68,50),Color("#c7b58f"))
		draw_rect(Rect2(-35,-25,68,50),Color("#6c574d"),false,3)
		for i in 4:
			draw_rect(Rect2(-43+i*18,-33,16,20),Color("#e0ceb0"))
			draw_line(Vector2(-25,-10+i*10),Vector2(23,-10+i*10),Color("#857263"),2)
	elif mode in ["paper_blade","paper_wave","paper_storm"]:
		var count := 3 if mode == "paper_blade" else 7
		for i in count:
			var p := Vector2(i*20,(i-count/2.0)*19)
			if mode == "paper_storm": p = Vector2.from_angle(age*4+i*TAU/count)*(45+progress*45)
			draw_set_transform(p,0.2+float(i)*0.17)
			draw_colored_polygon(PackedVector2Array([Vector2(-27,-16),Vector2(25,-11),Vector2(20,17),Vector2(-20,12)]),Color("#cebea0"))
			draw_line(Vector2(-18,-5),Vector2(15,-2),color,3)
			draw_line(Vector2(-14,4),Vector2(10,7),color,2)
			draw_set_transform(Vector2.ZERO)
	elif mode == "book": _book(gold)
	elif mode == "mouth":
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*(0.8+progress*0.4))
		_book(gold)
		draw_rect(Rect2(-47,-14,94,35),Color("#1b1529"))
		for i in 6:
			var x := -42+i*16
			draw_colored_polygon(PackedVector2Array([Vector2(x,-14),Vector2(x+12,-14),Vector2(x+6,3)]),Color("#d9c9a7"))
			draw_colored_polygon(PackedVector2Array([Vector2(x,21),Vector2(x+12,21),Vector2(x+6,6)]),Color("#d9c9a7"))
		draw_circle(Vector2.ZERO,12,Color(color,0.5))
		draw_set_transform(Vector2.ZERO)
	elif mode in ["flame","flare","fire_hit"]:
		var factor := (0.8+progress*1.2) if mode == "flare" else (0.6+(1.0-fade)*1.7 if mode == "fire_hit" else 1.0)
		draw_set_transform(Vector2.ZERO,age*0.4,Vector2.ONE*factor)
		_flame(color,fade if mode == "fire_hit" else 0.9)
		if mode != "flame": draw_arc(Vector2.ZERO,55,0,TAU,48,Color(color,fade*0.6),3,true)
		draw_set_transform(Vector2.ZERO)
	elif mode in ["chain","siphon"]:
		var reach := endpoint*progress
		draw_line(Vector2.ZERO,reach,Color(color,0.35),5,true)
		for i in 13:
			var t := float(i)/12.0
			var p := reach*t+Vector2(0,sin(t*PI)*22)
			if mode == "chain":
				draw_set_transform(p,endpoint.angle(),Vector2(1.3,0.65))
				draw_arc(Vector2.ZERO,9,0,TAU,20,Color(gold,0.85),3,true)
				draw_set_transform(Vector2.ZERO)
			else: draw_circle(endpoint*fposmod(t+age*2.3,1.0),4+sin(t*PI)*3,color)
	elif mode in ["seal","curse","volume","judgment","charge"]:
		var radius := (105.0 if mode == "judgment" else 68.0)*(0.65+progress*0.35)
		if mode == "charge" and family == "wisp": _flame(color,0.65); return
		if mode == "charge" and family == "ink":
			for i in 8: draw_circle(Vector2.from_angle(age*2+i*TAU/8)*radius,5,Color(color,0.7))
			return
		draw_arc(Vector2.ZERO,radius,0,TAU,64,Color(color,0.75),3,true)
		draw_arc(Vector2.ZERO,radius*0.75,age,age+TAU,48,Color(gold,0.6),2,true)
		for i in 6:
			var p := Vector2.from_angle(i*TAU/6.0)*radius
			draw_line(p*0.55,p,color,3,true)
		if mode == "volume": _book(gold)
		if mode == "judgment":
			for x in [-45,0,45]: draw_line(Vector2(x,-115),Vector2(x,100),Color(gold,0.45+progress*0.35),4,true)
	elif mode in ["splash","claw","paper_hit"]:
		for i in 9:
			var p := Vector2.from_angle(i*TAU/9.0)*(18+(1-fade)*75)
			if mode == "paper_hit":
				draw_set_transform(p,age+i)
				draw_rect(Rect2(-7,-11,14,22),Color(Color("#cbb996"),fade))
				draw_set_transform(Vector2.ZERO)
			else: draw_circle(p,4+fade*5,Color(color,fade))
		if mode == "claw":
			for x in [-22,0,22]: draw_line(Vector2(x+12,-35),Vector2(x-12,35),Color(color,fade),4,true)
	else:
		draw_arc(Vector2.ZERO,25+(1-fade)*50,0,TAU,40,Color(color,fade),3,true)

func _flame(color: Color, alpha: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-35,13),Vector2(-12,-22),Vector2(5,-58),Vector2(24,-15),Vector2(39,14),Vector2(14,38),Vector2(-12,32)]),Color(color,alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-12,14),Vector2(5,-22),Vector2(18,12),Vector2(1,28)]),Color(Color("#c5d9ff"),alpha))
	for i in 5: draw_circle(Vector2(28+i*16,sin(age*9-i)*10),7-i,Color(color,alpha*(0.5-i*0.08)))

func _book(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(-48,-25),Vector2(-48,25),Vector2(0,43)]),Color("#453044"))
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(48,-25),Vector2(48,25),Vector2(0,43)]),Color("#ccbc9c"))
	draw_line(Vector2.ZERO,Vector2(0,43),color,4,true)
	for i in 3: draw_line(Vector2(7,7+i*9),Vector2(39,-7+i*9),Color("#6f5261"),2,true)
