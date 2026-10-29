extends RefCounted
## Shared presentation vocabulary established by the approved frontispiece.
const INK := Color("#10191d")
const SURFACE := Color("#152024")
const PAPER := Color("#dfd8c8")
const COPPER := Color("#be9a74")
const MUTED := Color("#a5b0b0")
const BLUE := Color("#8caeb6")
const RED := Color("#cb8b89")
static var backdrop_shader: Shader

static func sheet(padding: int = 24, accent: Color = COPPER, spine: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(SURFACE,0.94)
	box.border_color = Color(accent,0.28)
	box.border_width_left = 1 if spine else 0
	box.border_width_bottom = 0 if spine else 1
	box.set_content_margin_all(padding)
	return box

static func entry(state: String, accent: Color = COPPER, padding: int = 18, ruled: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var active := state in ["hover","pressed","selected"]
	box.bg_color = Color(SURFACE,0.94) if ruled else Color.TRANSPARENT
	if active: box.bg_color = Color("#263439") if state != "pressed" else Color("#10191d")
	box.border_color = Color(accent,0.9 if active else (0.30 if state != "disabled" else 0.12))
	box.border_width_bottom = 2 if active else (1 if ruled else 0)
	box.set_content_margin_all(padding)
	return box

static func backdrop_material() -> ShaderMaterial:
	if backdrop_shader == null:
		backdrop_shader = Shader.new()
		backdrop_shader.code = """shader_type canvas_item;
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float grey = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 ink = mix(vec3(grey), source.rgb, 0.38);
    ink = mix(ink, vec3(0.07, 0.11, 0.13), 0.18) * 0.82;
    vec2 p = (UV - vec2(0.5)) * vec2(1.15, 0.8);
    float vignette = 1.0 - 0.40 * smoothstep(0.25, 0.68, length(p));
    COLOR = vec4(ink * vignette, source.a);
}"""
	var material := ShaderMaterial.new()
	material.shader = backdrop_shader
	return material
