extends RefCounted

var value := 0
var threshold := 3
var cooldown := 0
var ultimate := "ink_surge"
var history: Array[String] = []

func reset(enemy: Dictionary) -> void:
	value = 0
	cooldown = 0
	threshold = int(enemy.get("threshold",3))
	ultimate = str(enemy.get("ultimate","ink_surge"))
	history.clear()

func ready() -> bool:
	return value >= threshold and cooldown == 0

func finish(intent: Dictionary, correct: bool) -> void:
	history.append(str(intent.id))
	if bool(intent.get("uninterruptible",false)):
		value = 0
		cooldown = 2
	else:
		if cooldown > 0: cooldown -= 1
		value = mini(threshold,value+1) if correct else 0
