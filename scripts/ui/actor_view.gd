extends Control

const Art = preload("res://scripts/ui/actor_art.gd")
var pose := Node2D.new()
var visual := Node2D.new()
var art: Node2D
var kind := "mage"
var phase := 0.0
@export var art_scale := 1.0
@export var art_offset := Vector2.ZERO
@export var texture_height := 0.0
@export var texture_padding := Vector2(72.0,56.0)
@export var cast_uv := Vector2(-1,-1)
@export var floor_padding := -1.0
var uses_texture := false
var idle_enabled := true

func setup(actor_kind: String, path: String, color: Color) -> void:
	kind = actor_kind
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	visual.add_child(pose)
	art = Art.new()
	art.kind = kind
	art.tint = color
	if not path.is_empty() and ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is Texture2D:
			art.texture = resource
			uses_texture = true
	pose.add_child(art)
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	if art == null:
		return
	art.scale = Vector2.ONE * _base_scale()
	visual.position = _rest_position()

func _process(delta: float) -> void:
	if not idle_enabled:
		return
	phase += delta * (1.2 if kind == "boss" else 1.8)
	visual.position = _rest_position() + Vector2(0, sin(phase) * (8 if kind == "elite" else 5))
	art.rotation = sin(phase * 0.7) * (0.014 if kind != "mage" else 0.005)
	art.scale = Vector2.ONE * _base_scale() * (1.0 + sin(phase)*0.008)

func _rest_position() -> Vector2:
	if uses_texture and floor_padding >= 0.0:
		return Vector2(size.x*0.5,size.y-floor_padding-art.texture_rect().end.y*_base_scale())+art_offset
	return size*Vector2(0.5,0.54)+art_offset

func _base_scale() -> float:
	if uses_texture and texture_height > 0.0:
		var image_size: Vector2 = art.texture_rect().size
		# Keep room inside the role's column for idle rotation and attack/hit
		# offsets. A uniform scale preserves the original PNG aspect ratio.
		var safe_size := Vector2(maxf(1.0,size.x-texture_padding.x),maxf(1.0,size.y-texture_padding.y))
		return minf(texture_height/image_size.y,minf(safe_size.x/image_size.x,safe_size.y/image_size.y))*art_scale
	return minf(size.x/410.0,size.y/480.0)*art_scale

func texture_bounds() -> Rect2:
	return art.get_global_transform()*art.texture_rect() if uses_texture else Rect2()

func spell_origin() -> Vector2:
	if uses_texture and cast_uv.x >= 0:
		var bounds: Rect2 = art.texture_rect()
		return art.get_global_transform() * (bounds.position+bounds.size*cast_uv)
	if uses_texture and floor_padding >= 0.0:
		var bounds: Rect2 = art.texture_rect()
		return art.get_global_transform() * (bounds.position+bounds.size*Vector2(0.3,0.4))
	return global_position + size * Vector2(0.72 if kind == "mage" else 0.3, 0.4) + pose.position
