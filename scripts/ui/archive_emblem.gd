extends Control
## Original vector book seal; no raster asset or continuously running particles.
var accent := Color("#bda578")
var symbol := "book"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var c := size/2
	var radius := minf(size.x,size.y)*0.42
	draw_set_transform(c,0,Vector2.ONE*(radius/43))
	preload("res://scripts/ui/map_icon.gd").draw_symbol(self,symbol,accent)
	draw_set_transform(Vector2.ZERO)
