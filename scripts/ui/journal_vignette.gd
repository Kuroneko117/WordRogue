extends Control
## Small original ink-print symbols; no halos, circles, seals or continuous animation.
var accent := Color("#be9a74")
var symbol := "book"
var large := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var radius := minf(23.0,size.y*0.4)
	var center := Vector2(radius+1,size.y*0.5)
	draw_set_transform(center,0,Vector2.ONE*radius/35.0)
	preload("res://scripts/ui/map_icon.gd").draw_symbol(self,symbol,accent)
	draw_set_transform(Vector2.ZERO)
