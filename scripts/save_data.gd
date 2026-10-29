extends Node

const SAVE_PATH := "user://wordrogue_save.json"
var words: Dictionary = {}
var run_count := 0
var total_answers := 0
var highest_combo := 0
var load_warning := ""

func _ready() -> void:
	load_game()

func load_game() -> void:
	words.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		load_warning = "Save could not be read; a fresh profile was started."
		push_warning(load_warning)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		load_warning = "Save JSON was invalid; a fresh profile was started."
		push_warning(load_warning)
		return
	var data: Dictionary = parsed
	if typeof(data.get("words")) == TYPE_DICTIONARY:
		for key in data["words"]:
			var item: Variant = data["words"][key]
			if typeof(item) == TYPE_DICTIONARY:
				words[str(key)] = {
					"mastery": clampi(int(item.get("mastery", 50)), 0, 100),
					"correct_count": maxi(0, int(item.get("correct_count", 0))),
					"wrong_count": maxi(0, int(item.get("wrong_count", 0))),
					"encounter_count": maxi(0, int(item.get("encounter_count", 0)))
				}
	run_count = maxi(0, int(data.get("run_count", 0)))
	total_answers = maxi(0, int(data.get("total_answers", 0)))
	highest_combo = maxi(0, int(data.get("highest_combo", 0)))

func record_answer(word: String, correct: bool) -> void:
	var item: Dictionary = words.get(word, {"mastery": 50, "correct_count": 0, "wrong_count": 0, "encounter_count": 0})
	item["mastery"] = clampi(int(item["mastery"]) + (5 if correct else -10), 0, 100)
	item["correct_count"] = int(item["correct_count"]) + int(correct)
	item["wrong_count"] = int(item["wrong_count"]) + int(not correct)
	item["encounter_count"] = int(item["encounter_count"]) + 1
	words[word] = item
	total_answers += 1
	save_game()

func mastery_of(word: String) -> int:
	return int(words.get(word, {}).get("mastery", 50))

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save learning data: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"words": words,
		"run_count": run_count,
		"total_answers": total_answers,
		"highest_combo": highest_combo
	}, "  "))

