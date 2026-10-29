extends RefCounted

const LEGACY_NODES := {
	"entry":{"title":"书塔入口","kind":"entry","layer":0,"icon":"◇","next":["first"]},
	"first":{"title":"入口遭遇","kind":"normal","layer":1,"icon":"✦","next":["stacks","memory"],"battle":0},
	"stacks":{"title":"尘页回廊","kind":"normal","layer":2,"icon":"✦","next":["elite","upper"],"battle":1},
	"memory":{"title":"回忆书房","kind":"memory","layer":2,"icon":"▤","next":["elite","upper"]},
	"elite":{"title":"边注之灵","kind":"elite","layer":3,"icon":"✧","next":["boss"],"battle":2},
	"upper":{"title":"上层藏书区","kind":"normal","layer":3,"icon":"✦","next":["boss"],"battle":1},
	"boss":{"title":"遗忘图书管理员","kind":"boss","layer":4,"icon":"◆","next":["report"],"battle":3},
	"report":{"title":"学习报告","kind":"report","layer":5,"icon":"▤","next":[]}
}
var NODES: Dictionary = {}
var extended := true
var depth := 7
var map_seed := 0
var events_enabled := true
var rng := RandomNumberGenerator.new()
var completed: Array[String] = []
var skipped: Array[String] = []
var current := "entry"
var active := ""

func reset(use_extended: bool = true, seed_value: int = -1, with_events: bool = true) -> void:
	extended = use_extended
	events_enabled = with_events and extended
	depth = 7 if extended else 4
	if extended:
		if seed_value < 0: rng.randomize()
		else: rng.seed = seed_value
		map_seed = rng.seed
		_generate()
	else:
		NODES = LEGACY_NODES.duplicate(true)
		for id in NODES:
			NODES[id]["col"] = 0 if id in ["stacks","elite"] else (2 if id in ["memory","upper"] else 1)
	completed = ["entry"]
	skipped.clear()
	current = "entry"
	active = ""

func _generate() -> void:
	NODES = {"entry":{"title":"书塔入口","kind":"entry","layer":0,"col":1,"next":["first"]},"first":{"title":"入口遭遇","kind":"normal","layer":1,"col":1,"battle":0,"next":[]}}
	var rows: Array = [["first"]]
	var patterns := {2:["normal","memory","treasure"],3:["normal","normal","rest"],4:["elite","normal","memory"],5:["normal","treasure","rest"],6:["elite","normal","normal"]}
	var names := {"normal":"遗忘藏书区","elite":"边注禁区","memory":"回忆书房","rest":"休息书桌","treasure":"藏宝书架"}
	for layer in range(2,depth):
		var kinds: Array = patterns[layer].duplicate()
		# A local RNG makes a map reproducible without affecting question sampling.
		for i in range(kinds.size()-1,0,-1):
			var j := rng.randi_range(0,i)
			var value: Variant = kinds[i]
			kinds[i] = kinds[j]
			kinds[j] = value
		var row: Array[String] = []
		for col in 3:
			var id := "floor_%d_%d" % [layer,col]
			var kind := str(kinds[col])
			NODES[id] = {"title":str(names[kind]),"kind":kind,"layer":layer,"col":col,"next":[],"battle":2 if kind == "elite" else rng.randi_range(0,1)}
			row.append(id)
		rows.append(row)
	NODES.first.next = rows[1].duplicate()
	for row_index in range(1,rows.size()-1):
		var direction := 1 if rng.randf() < 0.5 else -1
		for col in 3:
			var id := str(rows[row_index][col])
			NODES[id].next.append(rows[row_index+1][col])
			var neighbor := col+direction
			if neighbor >= 0 and neighbor < 3: NODES[id].next.append(rows[row_index+1][neighbor])
	# An edge lane must still offer a route around every elite.
	for row_index in range(1,rows.size()-1):
		for id in rows[row_index]:
			var avoidable := false
			for next in NODES[id].next:
				if NODES[next].kind != "elite": avoidable = true
			if not avoidable:
				for next in rows[row_index+1]:
					if NODES[next].kind != "elite":
						NODES[id].next.append(next)
						break
	NODES["boss"] = {"title":"遗忘图书管理员","kind":"boss","layer":depth,"col":1,"battle":3,"next":["report"]}
	NODES["report"] = {"title":"学习报告","kind":"report","layer":depth+1,"col":1,"next":[]}
	for id in rows.back(): NODES[id].next = ["boss"]
	if events_enabled:
		var candidates: Array[String] = []
		for id in NODES:
			if int(NODES[id].layer) in [3,5,6] and NODES[id].kind == "normal": candidates.append(str(id))
		var count := rng.randi_range(1,2)
		var used_layers := {}
		while count > 0 and not candidates.is_empty():
			var index := rng.randi_range(0,candidates.size()-1)
			var id := candidates[index]
			candidates.remove_at(index)
			if used_layers.has(int(NODES[id].layer)): continue
			NODES[id].kind = "event"
			NODES[id].title = "未知事件"
			used_layers[int(NODES[id].layer)] = true
			count -= 1

func status(id: String) -> String:
	if not NODES.has(id): return "locked"
	if completed.has(id): return "complete"
	if skipped.has(id): return "skipped"
	if id == active: return "active"
	if active.is_empty() and NODES[current].next.has(id): return "available"
	return "locked"

func enter(id: String) -> bool:
	if status(id) != "available" or id == "report": return false
	active = id
	for sibling in NODES:
		if sibling != id and int(NODES[sibling].layer) == int(NODES[id].layer): skipped.append(str(sibling))
	return true

func complete() -> bool:
	if active.is_empty() or completed.has(active): return false
	completed.append(active)
	current = active
	active = ""
	return true
