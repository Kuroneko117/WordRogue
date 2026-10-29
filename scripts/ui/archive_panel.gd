extends PanelContainer
## Quiet folio furniture. The StyleBox owns the matte surface and content inset.
var accent := Color("#b79a62")
var surface_kind := "cover"
const Grimoire = preload("res://scripts/ui/battle_theme.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 40 or size.y < 40: return
	if surface_kind == "folio":
		draw_line(Vector2(0,24),Vector2(0,66),Color(accent,0.75),2,true)
