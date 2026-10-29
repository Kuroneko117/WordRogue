extends CanvasLayer

const Kit = preload("res://scripts/ui/ui_kit.gd")
const Folio = preload("res://scripts/ui/flow_folio.gd")

var host: Control
var overlay: Control
var panel: PanelContainer
var pending_action := ""
var showing_settings := false
var previous_focus: Control
var sliders: Dictionary = {}

func setup(main: Control) -> void:
	host = main
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025,0.04,0.045,0.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	panel = Kit.PanelSurface.new()
	panel.accent = Kit.GOLD
	panel.surface_kind = "folio"
	panel.custom_minimum_size = Vector2(810,740)
	panel.theme = host.theme
	var cover := StyleBoxFlat.new()
	cover.bg_color = Color("#10191d")
	cover.border_color = Color("#514a40")
	cover.border_width_left = 1
	cover.set_content_margin_all(54)
	panel.add_theme_stylebox_override("panel",cover)
	center.add_child(panel)
	overlay.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		back()

func back() -> void:
	if overlay.visible:
		if showing_settings:
			_build_menu()
		elif pending_action.is_empty():
			resume()
		else:
			pending_action = ""
			_build_menu()
	else:
		open_menu()

func open_menu() -> void:
	previous_focus = get_viewport().gui_get_focus_owner()
	pending_action = ""
	_build_menu()
	overlay.show()
	AudioBus.set_paused(true)
	get_tree().paused = true

func resume() -> void:
	pending_action = ""
	showing_settings = false
	overlay.hide()
	if is_instance_valid(previous_focus): previous_focus.grab_focus()
	AudioBus.set_paused(false)
	get_tree().paused = false

func _contents(title: String) -> VBoxContainer:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	panel.add_child(column)
	var title_box := Kit.column(column,4,true)
	Kit.text(title_box,"书塔手记  /  旅途书签",20,Kit.MUTED)
	var label := Label.new()
	label.text = title
	label.theme_type_variation = "ArchiveTitle"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size.y = 60
	label.add_theme_font_size_override("font_size",38)
	label.add_theme_color_override("font_color",Kit.PAPER)
	title_box.add_child(label)
	Folio.rule(column)
	return column

func _menu_button(parent: Control, text: String, callback: Callable) -> void:
	var button: Button = host._button(parent,text,Vector2.ZERO,Vector2.ZERO,callback)
	Kit.dress_button(button,"primary" if text in ["继续冒险","确认"] else ("danger" if text == "退出游戏" else "secondary"))
	button.custom_minimum_size = Vector2(650,72)
	if text in ["继续冒险","确认"]: button.grab_focus()

func _build_menu() -> void:
	showing_settings = false
	var column := _contents("冒险暂停" if host.screen not in ["title","report","difficulty"] else "游戏菜单")
	_menu_button(column,"继续冒险",resume)
	_menu_button(column,"声音设置",open_settings)
	_menu_button(column,"重新开始",request_action.bind("restart"))
	_menu_button(column,"返回标题",request_action.bind("title"))
	_menu_button(column,"退出游戏",request_action.bind("quit"))

func open_settings() -> void:
	showing_settings = true
	pending_action = ""
	sliders.clear()
	var column := _contents("声音设置")
	for pair in [["music","背景音乐",AudioBus.music_percent],["sfx","战斗与界面音效",AudioBus.sfx_percent]]:
		_volume_row(column,str(pair[0]),str(pair[1]),float(pair[2]))
	var note := Label.new()
	note.text = "音量即时生效并自动保存，0% 为静音。\n恢复冒险后，音乐从暂停处继续播放。"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size",22)
	note.add_theme_color_override("font_color",host.MUTED)
	column.add_child(note)
	# The common button helper already plays exactly one UI sound.
	_menu_button(column,"试听音效",func() -> void: pass)
	_menu_button(column,"恢复默认音量",func() -> void:
		AudioBus.reset_settings()
		open_settings())
	_menu_button(column,"返回暂停菜单",_build_menu)

func _volume_row(parent: Control, channel: String, caption: String, value: float) -> void:
	var frame := Kit.card(parent,Kit.BLUE)
	var border := StyleBoxEmpty.new()
	border.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel",border)
	var group := Kit.column(frame,6)
	var label := Label.new()
	label.text = "%s    %s" % [caption,"已静音" if value == 0 else "%d%%" % roundi(value)]
	label.add_theme_font_size_override("font_size",26)
	label.add_theme_color_override("font_color",Kit.PAPER)
	group.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size = Vector2(630,38)
	slider.tick_count = 0
	slider.add_theme_icon_override("grabber",Folio.knob())
	slider.add_theme_icon_override("grabber_highlight",Folio.knob(true))
	slider.add_theme_icon_override("grabber_disabled",Folio.knob())
	for key in ["slider","grabber_area","grabber_area_highlight"]:
		var rail := StyleBoxFlat.new()
		rail.bg_color = Color("#384448") if key == "slider" else Kit.GOLD
		rail.content_margin_top = 2
		rail.content_margin_bottom = 2
		slider.add_theme_stylebox_override(key,rail)
	group.add_child(slider)
	var ticks := Kit.row(group,12)
	Kit.text(ticks,"静音",18,Kit.MUTED)
	Kit.text(ticks,"50%",18,Kit.MUTED,true)
	Kit.text(ticks,"100%",18,Kit.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(func(percent: float) -> void:
		AudioBus.set_volume(channel,percent)
		label.text = "%s    %s" % [caption,"已静音" if percent == 0 else "%d%%" % roundi(percent)])
	sliders[channel] = slider

func request_action(action: String) -> void:
	pending_action = action
	var column := _contents("确认操作？")
	var label := Label.new()
	label.text = "确定退出游戏？\n学习记录和声音设置已保存。" if action == "quit" else "当前冒险将结束。\n长期词汇掌握度与学习记录会保留。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 100
	label.add_theme_font_size_override("font_size",26)
	column.add_child(label)
	_menu_button(column,"确认",confirm_action)
	_menu_button(column,"取消",_cancel)

func _cancel() -> void:
	pending_action = ""
	_build_menu()

func confirm_action() -> void:
	var action := pending_action
	if action.is_empty():
		return
	resume()
	match action:
		"restart": host._start_adventure()
		"title":
			GameState.run_active = false
			host.show_title()
		"quit":
			SaveData.save_game()
			AudioBus.stop_all()
			get_tree().paused = true
			await get_tree().create_timer(0.12,true,false,true).timeout
			get_tree().quit()
