extends RefCounted

const DEFINITIONS := {
	"pages":{"name":"遗失书页","text":"两枚黯淡词印正在消散。找回它们，让记忆化为暖光。","hint":"挑战两个薄弱词；全部答对恢复10生命。"},
	"chest":{"name":"诅咒书匣","text":"锁链之下藏着一件遗物。书匣索取血墨作为代价。","hint":"支付10生命获得一件未拥有遗物，或安全离开。"},
	"scribe":{"name":"流浪抄写员","text":"抄写员愿用补给交换血墨，也愿陪你重读旧词。","hint":"支付6生命换一次随机补给，或复习两词，每答对恢复3生命。"},
	"dictionary":{"name":"错乱词典","text":"倒置的书页等待三个正确的词义，才能恢复秩序。","hint":"三题全对获得一件未拥有遗物；部分答对每题恢复2生命。"},
	"ambush":{"name":"墨影伏击","text":"书架后的墨迹凝成魔物。握紧魔法书，准备迎战。","hint":"当前楼层普通战，胜利后一次常规强化选择。"}
}
var records: Dictionary = {}
var current: Dictionary = {}

func reset() -> void:
	records.clear()
	current = {}

func open(node_id: String, map_seed: int) -> Dictionary:
	if records.has(node_id):
		current = records[node_id]
		return current
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed ^ int(node_id.hash())
	var types := DEFINITIONS.keys()
	current = {"node":node_id,"id":str(types[rng.randi_range(0,types.size()-1)]),"stage":"choice","action":"","index":0,"correct":0,"wrong":0,"questions":[],"result":"","reward":"","cost":0}
	records[node_id] = current
	return current
