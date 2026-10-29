extends RefCounted
## Presentation-only chapter furniture shared by map, manuscript and settings.
const Kit = preload("res://scripts/ui/ui_kit.gd")
const Grimoire = preload("res://scripts/ui/battle_theme.gd")

static func inset(panel: PanelContainer, compact: bool = false) -> void:
	var border := StyleBoxFlat.new()
	border.bg_color = Color("#10191d")
	border.border_color = Color("#514a40")
	border.border_width_left = 1
	border.set_content_margin_all(30 if compact else 42)
	panel.add_theme_stylebox_override("panel",border)

static func heading(parent: Node, symbol: String, chapter: String, title: String, accent: Color = Kit.GOLD) -> void:
	var row := Kit.row(parent,18)
	var words := Kit.column(row,4,true)
	Kit.text(words,chapter,20,Kit.MUTED)
	Kit.text(words,title,42,Kit.PAPER)

static func rule(parent: Node, accent: Color = Kit.GOLD) -> void:
	var row := Kit.row(parent,12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := HSeparator.new()
	line.custom_minimum_size.x = 84
	var ink := StyleBoxLine.new()
	ink.color = Color(accent,0.40)
	ink.thickness = 1
	line.add_theme_stylebox_override("separator",ink)
	row.add_child(line)

static func knob(highlight: bool = false) -> Texture2D:
	var image := Image.new()
	var fill := "#dfd8c8" if highlight else "#be9a74"
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="24"><path d="M5 4H11V20H5Z" fill="'+fill+'"/></svg>')
	return ImageTexture.create_from_image(image)
