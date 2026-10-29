extends SceneTree
## Explicit authoring utility: resample new generated UI art, never character art.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: quit(2); return
	var path := ProjectSettings.globalize_path(args[0])
	var image := Image.load_from_file(path)
	if image == null: quit(2); return
	image = image.get_region(image.get_used_rect())
	image.resize(1024,roundi(float(image.get_height())/image.get_width()*1024),Image.INTERPOLATE_LANCZOS)
	quit(0 if image.save_png(path) == OK else 1)
