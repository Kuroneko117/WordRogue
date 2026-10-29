extends Control
## Decorative layer only; actor pose and attack origins remain untouched.
const Grimoire = preload("res://scripts/ui/battle_theme.gd")
var accent := Color("#76c7ed")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var floor_at := Vector2(size.x/2,size.y-12)
	draw_set_transform(floor_at,0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,size.x*0.35,Color(accent,0.045),true,-1,true)
	draw_arc(Vector2.ZERO,size.x*0.35,0,TAU,96,Color(accent,0.26),1.2,true)
	draw_set_transform(Vector2.ZERO)
