extends RefCounted

static func touch_mode() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or "--touch-ui" in OS.get_cmdline_user_args()

static func font() -> Font:
	var manifest_path := "res://assets/fonts/manifest.json"
	if FileAccess.file_exists(manifest_path):
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if manifest is Dictionary:
			var fonts: Array[Font] = []
			for entry in manifest.get("files", []):
				var path := "res://assets/fonts/" + str(entry.file)
				if ResourceLoader.exists(path):
					var item: Font = load(path)
					if item != null: fonts.append(item)
			if not fonts.is_empty():
				var primary := fonts.pop_front() as Font
				primary.fallbacks = fonts
				return primary
	var fallback := SystemFont.new()
	fallback.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Arial"])
	return fallback
