extends Control
const Icon = preload("res://scripts/ui/map_icon.gd")
var category := "进攻"
var accent := Color("#be9a74")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_set_transform(Vector2(26,size.y/2.0),0,Vector2.ONE*0.62)
	Icon.draw_symbol(self,category,accent)
	draw_set_transform(Vector2.ZERO)
