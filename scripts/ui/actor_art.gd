extends Node2D

var kind := "mage"
var texture: Texture2D
var tint := Color("#6bbdd1")

func texture_rect() -> Rect2:
	if texture == null:
		return Rect2()
	var dimensions := texture.get_size()
	var ratio := minf(390.0 / dimensions.x, 460.0 / dimensions.y)
	return Rect2(-dimensions * ratio / 2.0, dimensions * ratio)

func _draw() -> void:
	if texture != null:
		var rect := texture_rect()
		draw_set_transform(Vector2(0,rect.end.y-2),0,Vector2(1,0.18))
		draw_circle(Vector2.ZERO,rect.size.x*0.33,Color(0.01,0.02,0.04,0.45),true,-1,true)
		draw_arc(Vector2.ZERO,rect.size.x*0.34,0,TAU,64,Color(tint,0.25),2.5,true)
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(texture,rect,false)
		return
	# Original procedural silhouettes. No downloaded assets are used.
	draw_set_transform(Vector2(0, 190), 0, Vector2(1, 0.24))
	draw_arc(Vector2.ZERO, 142, 0, TAU, 80, Color(tint, 0.45), 3, true)
	draw_arc(Vector2.ZERO, 110, 0, TAU, 80, Color(tint, 0.2), 2, true)
	draw_set_transform(Vector2.ZERO)
	if kind == "mage":
		_mage()
	elif kind == "paper_golem": _golem()
	elif kind == "grimoire_mimic": _mimic()
	elif kind == "lantern_wisp": _wisp()
	elif kind == "silent_archivist": _archivist()
	else:
		_enemy()

func _golem() -> void:
	var paper := Color("#c6b798")
	for rect in [Rect2(-70,-110,140,210),Rect2(-52,-192,104,75),Rect2(-130,-70,55,150),Rect2(75,-70,55,150),Rect2(-65,108,55,85),Rect2(12,108,55,85)]:
		draw_rect(rect,paper)
		draw_rect(rect,Color("#6e5962"),false,4)
		for line in 4: draw_line(rect.position+Vector2(8,15+line*12),rect.position+Vector2(rect.size.x-8,15+line*12),Color("#88736b"),2)
	draw_line(Vector2(-32,-160),Vector2(-12,-156),Color("#f0bd72"),6)
	draw_line(Vector2(12,-156),Vector2(32,-160),Color("#f0bd72"),6)
	draw_line(Vector2(-2,-100),Vector2(-2,90),Color("#704859"),10)

func _mimic() -> void:
	draw_set_transform(Vector2(0,-30),-0.1)
	draw_rect(Rect2(-140,-95,280,210),Color("#55344c"))
	draw_rect(Rect2(-140,-95,280,210),Color("#bd9358"),false,7)
	draw_rect(Rect2(-110,-65,220,160),Color("#c1b391"))
	draw_line(Vector2(-125,20),Vector2(125,20),Color("#161725"),30)
	for i in 8:
		var x := -104+i*29
		draw_colored_polygon(PackedVector2Array([Vector2(x,5),Vector2(x+16,5),Vector2(x+8,31)]),Color("#ede3c2"))
	draw_circle(Vector2(-50,-32),14,Color("#be77cd"))
	draw_circle(Vector2(50,-32),14,Color("#be77cd"))
	draw_set_transform(Vector2.ZERO)
	for i in 5: draw_line(Vector2(-75+i*35,90),Vector2(-100+i*50,175),Color("#58395f"),8,true)

func _wisp() -> void:
	var light := Color("#81cebf")
	for i in range(4,0,-1): draw_circle(Vector2(0,-35),28+i*22,Color(light,0.08))
	draw_arc(Vector2(0,-170),38,PI,TAU,40,Color("#c6a572"),5,true)
	draw_line(Vector2(-38,-170),Vector2(-60,65),Color("#c6a572"),5,true)
	draw_line(Vector2(38,-170),Vector2(60,65),Color("#c6a572"),5,true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-137),Vector2(45,-45),Vector2(18,35),Vector2(-12,65),Vector2(-44,-25)]),Color(light,0.8))
	draw_circle(Vector2(0,-40),23,Color("#e4ecb3"))
	draw_line(Vector2(-66,68),Vector2(66,68),Color("#c6a572"),7,true)
	for i in 5: draw_circle(Vector2(-70+i*33,128+sin(i)*25),5,Color(light,0.6))

func _archivist() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-38,-135),Vector2(38,-135),Vector2(102,175),Vector2(-102,175)]),Color("#263747"))
	draw_rect(Rect2(-46,-210,92,72),Color("#c6b99e"))
	for y in [-192,-173,-154]: draw_line(Vector2(-31,y),Vector2(31,y),Color("#534256"),4)
	draw_line(Vector2(0,-126),Vector2(0,168),Color("#a78bbd"),6,true)
	for side in [-1,1]:
		for i in 6: draw_arc(Vector2(side*(45+i*14),-80+i*35),12,0,TAU,24,Color("#b29abb"),3,true)
	_book(Vector2(-129,15),0.1,Color("#aaa084"))

func _mage() -> void:
	draw_polygon(PackedVector2Array([Vector2(-60,-72),Vector2(28,-92),Vector2(103,172),Vector2(-112,172)]), PackedColorArray([Color("#24394f")]))
	draw_polygon(PackedVector2Array([Vector2(-28,-52),Vector2(18,-65),Vector2(48,169),Vector2(-41,169)]), PackedColorArray([Color("#375a73")]))
	draw_polyline(PackedVector2Array([Vector2(-60,-72),Vector2(-112,172),Vector2(103,172),Vector2(28,-92)]), Color("#c59b59"), 4, true)
	draw_circle(Vector2(-15,-106), 40, Color("#d4b89b"), true, -1, true)
	draw_polygon(PackedVector2Array([Vector2(-66,-117),Vector2(-14,-202),Vector2(42,-118)]), PackedColorArray([Color("#273f58")]))
	draw_line(Vector2(-65,-117),Vector2(48,-117),Color("#c59b59"),7,true)
	draw_circle(Vector2(13,-108), 4, Color("#e9dfb4"))
	draw_line(Vector2(4,-40),Vector2(88,-10),Color("#41677f"),29,true)
	draw_circle(Vector2(90,-8),12,Color("#d4b89b"))
	_book(Vector2(134,-36), 0.1, Color("#b69a6f"))
	for i in 7:
		var angle := float(i) * TAU / 7.0
		var point := Vector2(133,-44) + Vector2(cos(angle),sin(angle)) * 76
		draw_circle(point, 3, Color("#8ae5ea"))
	draw_arc(Vector2(133,-44),68,0,TAU,64,Color("#6cced8"),2,true)

func _enemy() -> void:
	var boss := kind == "boss"
	var elite := kind == "elite"
	var width := 98.0 if boss else 83.0
	draw_polygon(PackedVector2Array([Vector2(-42,-150),Vector2(50,-148),Vector2(width,135),Vector2(45,108),Vector2(2,178),Vector2(-50,130),Vector2(-width,156)]), PackedColorArray([Color("#342539") if boss else Color("#35313f")]))
	draw_polyline(PackedVector2Array([Vector2(-42,-150),Vector2(-width,156),Vector2(-50,130),Vector2(2,178),Vector2(45,108),Vector2(width,135),Vector2(50,-148)]), tint.darkened(0.15),3,true)
	draw_polygon(PackedVector2Array([Vector2(-50,-114),Vector2(0,-206),Vector2(56,-118),Vector2(26,-66),Vector2(-26,-66)]), PackedColorArray([Color("#1b1c29")]))
	draw_line(Vector2(-27,-117),Vector2(-9,-112),tint.lightened(0.6),5,true)
	draw_line(Vector2(10,-112),Vector2(28,-117),tint.lightened(0.6),5,true)
	for i in 5:
		draw_line(Vector2(-24, -37+i*30),Vector2(29,-49+i*30),Color(tint,0.45),3,true)
	if boss:
		_book(Vector2(-133,-24),-0.2,Color("#b79466"))
		_book(Vector2(124,-95),0.2,Color("#b79466"))
		draw_arc(Vector2(0,-128),119,PI,TAU,60,Color(tint,0.5),3,true)
	elif elite:
		for i in 6:
			var angle := float(i)*TAU/6.0
			var p := Vector2(cos(angle)*130,sin(angle)*149-17)
			draw_set_transform(p, angle*0.3)
			draw_rect(Rect2(-18,-27,36,54), Color("#baa790"))
			for line in 3:
				draw_line(Vector2(-12,-13+line*9),Vector2(11,-13+line*9),Color("#5c4655"),2)
			draw_set_transform(Vector2.ZERO)
	else:
		for i in 7:
			draw_circle(Vector2(-116+i*33,170+sin(i*2)*16), 8+i%3*3, Color(tint,0.4))

func _book(pos: Vector2, angle: float, color: Color) -> void:
	draw_set_transform(pos, angle)
	draw_polygon(PackedVector2Array([Vector2(-57,-26),Vector2(-2,-18),Vector2(0,34),Vector2(-57,22)]),PackedColorArray([color]))
	draw_polygon(PackedVector2Array([Vector2(0,-18),Vector2(58,-29),Vector2(57,22),Vector2(0,34)]),PackedColorArray([color.lightened(0.15)]))
	for line in 4:
		draw_line(Vector2(8,-9+line*8),Vector2(45,-15+line*8),Color("#665340"),2)
	draw_set_transform(Vector2.ZERO)
