extends RefCounted

const MODES := {
	"easy":{"name":"简单 · 学徒","hp":0.9,"atk":0.8,"path":"res://data/words.json","count":120,"pool":"原版120词","hint":"熟悉法术与书塔探索；怪物生命90%，攻击80%。"},
	"normal":{"name":"普通 · 四级试炼","hp":1.0,"atk":1.0,"path":"res://data/cet4_core_1500.json","count":1500,"pool":"项目精选CET4核心1500词","hint":"推荐。学习四级核心词，标准战斗压力。"},
	"hard":{"name":"困难 · 深渊试炼","hp":1.15,"atk":1.1,"path":"res://data/cet4_core_1500.json","count":1500,"pool":"项目精选CET4核心1500词","hint":"怪物生命115%，攻击110%；同主题、同词性干扰优先，无限时。"}
}

static func get_mode(id: String) -> Dictionary:
	return MODES.get(id,MODES.normal)
