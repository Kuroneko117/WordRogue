extends SceneTree

# Store layouts rendered by Godot using existing assets. No game resources modified.
const PlatformUI = preload("res://scripts/ui/platform_ui.gd")
const GOLD := Color("#e9c587")
var destination := "D:/项目/1/releases/taptap_pc/branding"
var font: Font

func _initialize() -> void:
	call_deferred("render_materials")

func label(parent: Control, text: String, rect: Rect2, size: int, color: Color) -> void:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_override("font",font)
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",color)
	item.add_theme_color_override("font_shadow_color",Color("#0a1425"))
	item.add_theme_constant_override("shadow_offset_x",3)
	item.add_theme_constant_override("shadow_offset_y",4)
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(item)

func texture(parent: Control, path: String, rect: Rect2, covered: bool = false) -> void:
	var item := TextureRect.new()
	item.texture = load(path)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.position = rect.position
	item.size = rect.size
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if covered else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(item)

func shade(parent: Control, dimensions: Vector2, opacity: float) -> void:
	var item := ColorRect.new()
	item.size = dimensions
	item.color = Color(0.025,0.04,0.07,opacity)
	parent.add_child(item)

func layout(dimensions: Vector2i, kind: String) -> SubViewport:
	var view := SubViewport.new()
	view.size = dimensions
	view.transparent_bg = kind == "logo"
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var canvas := Control.new()
	canvas.size = dimensions
	view.add_child(canvas)
	if kind != "logo":
		texture(canvas,"res://assets/backgrounds/library_battle.png",Rect2(Vector2.ZERO,dimensions),true)
		shade(canvas,dimensions,0.46 if kind != "wallpaper" else 0.20)
	if kind == "hero":
		texture(canvas,"res://assets/characters/word_mage_v2.png",Rect2(dimensions.x*0.53,dimensions.y*0.06,dimensions.x*0.46,dimensions.y*0.90))
		label(canvas,"遗忘书塔",Rect2(dimensions.x*.075,dimensions.y*.28,dimensions.x*.48,dimensions.y*.22),int(dimensions.y*.105),GOLD)
		label(canvas,"WORDROGUE",Rect2(dimensions.x*.077,dimensions.y*.52,dimensions.x*.42,dimensions.y*.13),int(dimensions.y*.052),Color("#94d2e5"))
	elif kind == "portrait":
		texture(canvas,"res://assets/characters/word_mage_v2.png",Rect2(10,210,580,675))
		label(canvas,"遗忘书塔",Rect2(48,36,530,120),84,GOLD)
		label(canvas,"WORDROGUE",Rect2(52,155,490,54),38,Color("#94d2e5"))
	elif kind == "logo":
		label(canvas,"遗忘书塔",Rect2(46,95,1180,310),220,GOLD)
		label(canvas,"WORDROGUE",Rect2(53,430,1170,165),108,Color("#94d2e5"))
	return view

func render_materials() -> void:
	font = PlatformUI.font()
	DirAccess.make_dir_recursive_absolute(destination)
	var source_svg := "D:/项目/1/releases/taptap_pc/branding/icon.svg"
	var icon := Image.new()
	if icon.load_svg_from_string(FileAccess.get_file_as_string(source_svg)) != OK:
		push_error("Icon SVG could not render"); quit(1); return
	if icon.save_png(destination+"/icon_512.png") != OK:
		push_error("Icon PNG could not save"); quit(1); return
	for item in [
		[Vector2i(1920,1080),"hero","promotion_1920x1080.png"],
		[Vector2i(460,215),"hero","pc_cover_460x215.png"],
		[Vector2i(600,900),"portrait","portrait_cover_600x900.png"],
		[Vector2i(1280,720),"logo","logo_1280x720.png"],
		[Vector2i(3840,1240),"wallpaper","wallpaper_3840x1240.png"]
	]:
		var view := layout(item[0],item[1])
		for frame in 4: await process_frame
		RenderingServer.force_draw(false)
		var output := view.get_texture().get_image()
		if output.save_png(destination+"/"+str(item[2])) != OK:
			push_error("Store image could not save"); quit(1); return
		print("STORE IMAGE ",item[2]," ",output.get_size())
		view.queue_free()
		await process_frame
	root.get_node("AudioBus").stop_all()
	quit()
