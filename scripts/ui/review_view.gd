extends Control

const Kit = preload("res://scripts/ui/ui_kit.gd")
const Folio = preload("res://scripts/ui/flow_folio.gd")
var buttons: Array[Button] = []
var feedback: Label
var word: Label
var phonetic: Label
var progress: Label
var life: Label
var owner_ui: Control

func build(host: Control) -> void:
	owner_ui = host
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page := Kit.page(self,125)
	Folio.heading(page,"memory","回忆录  /  安静的一章","回忆书房")
	var spread := Kit.row(page,24)
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var note_page := Kit.folio(spread,Kit.GOLD)
	Folio.inset(note_page,true)
	note_page.custom_minimum_size.x = 400
	var notes := Kit.column(note_page,24)
	Kit.text(notes,"重拾遗忘之词",34,Kit.PAPER)
	Folio.rule(notes)
	Kit.text(notes,"答对恢复 %d 生命\n答错没有伤害\n不消耗法力" % GameState.review_healing(),28,Kit.MUTED)
	Kit.space(notes)
	progress = Kit.text(notes,"",27,Kit.BLUE)
	life = Kit.text(notes,"",28,Kit.PAPER)
	var question_page := Kit.folio(spread,Kit.BLUE,true)
	Folio.inset(question_page)
	var box := Kit.column(question_page,14)
	Kit.text(box,"记忆书页  /  选择正确释义",22,Kit.GOLD,true)
	word = Kit.text(box,"",60,Kit.PAPER,true)
	word.theme_type_variation = "ArchiveNumber"
	phonetic = Kit.text(box,"",30,Kit.MUTED,true)
	Folio.rule(box,Kit.BLUE)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",20)
	grid.add_theme_constant_override("v_separation",20)
	box.add_child(grid)
	for i in 4:
		var button := Kit.button(host,grid,"",host._on_review_answer.bind(i))
		button.custom_minimum_size.y = 100
		Kit.dress_button(button,"choice")
		buttons.append(button)
	feedback = Kit.text(box,"",28,Kit.GOLD,true)
	feedback.custom_minimum_size.y = 56
	Kit.text(page,"点击选择正确释义。三题结束自动返回地图。" if host.PlatformUI.touch_mode() else "1–4 选择释义 · Tab/方向键与 Enter 也可作答。三题结束自动返回地图。",24,Kit.MUTED)

func display() -> void:
	var question: Dictionary = GameState.review.questions[GameState.review.index]
	word.text = str(question.entry.word)
	phonetic.text = str(question.entry.phonetic)
	progress.text = "复习 %d / 3 · 掌握度 %d" % [GameState.review.index+1,SaveData.mastery_of(str(question.entry.word))]
	feedback.text = "请选择正确释义"
	feedback.add_theme_color_override("font_color",Kit.GOLD)
	life.text = "生命 %d / %d" % [GameState.hp,GameState.max_hp]
	for i in 4:
		buttons[i].text = ["A","B","C","D"][i]+".  "+str(question.options[i])
		buttons[i].disabled = false
		buttons[i].add_theme_stylebox_override("disabled",owner_ui._style(owner_ui.PANEL_ALT.darkened(0.15),Color("#494944")))
