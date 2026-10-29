extends RefCounted

var questions: Array[Dictionary] = []
var index := 0

func build(bank: Node, save: Node, missed: Dictionary, count: int = 3) -> void:
	index = 0
	questions.clear()
	var entries: Array = bank.entries.duplicate()
	entries.shuffle()
	entries.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var sa: int = save.mastery_of(str(a.word)) - (200 if missed.has(str(a.word)) else 0)
		var sb: int = save.mastery_of(str(b.word)) - (200 if missed.has(str(b.word)) else 0)
		return sa < sb)
	for entry in entries.slice(0,mini(count,entries.size())):
		var question: Dictionary = bank.question_for(entry,missed)
		if not question.is_empty(): questions.append(question)
