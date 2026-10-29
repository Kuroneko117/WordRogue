extends Control
## One quiet binding line shared with the frontispiece; no ornamental frame.
const Grimoire = preload("res://scripts/ui/battle_theme.gd")
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var copper := Color("#be9a74")
	draw_line(Vector2(24,96),Vector2(24,size.y-44),Color(copper,0.18),1,true)
	draw_line(Vector2(24,96),Vector2(24,138),Color(copper,0.7),2,true)
