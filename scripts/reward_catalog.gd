extends RefCounted

const EXTRA := [
	{"id":"mana_ring","name":"聚能指环","description":"本局法力上限 +1，让爆发与守护有更大余地。","tag":"法力","icon":"◎"},
	{"id":"spring","name":"法力泉瓶","description":"每场起始法力改为 2，可直接使用记忆爆发。","tag":"法力","icon":"⌁"},
	{"id":"echo","name":"余响铭文","description":"奥术飞弹在正常伤害之外，额外造成 3 伤害。","tag":"进攻","icon":"✦"},
	{"id":"aegis_edge","name":"符文护页","description":"守护答对获得 10 护盾；本局护盾上限提高到 20。","tag":"防御","icon":"◇"},
	{"id":"bulwark","name":"青金壁垒","description":"每场战斗开始获得 6 护盾，不跨战斗累积。","tag":"防御","icon":"▱"},
	{"id":"thorns","name":"反击墨镜","description":"护盾实际吸收伤害且你存活时，反伤敌人 4 点。","tag":"防御","icon":"◈"},
	{"id":"resonance","name":"共鸣书签","description":"记忆爆发针对本局旧错词的追加伤害由 5 提高到 10。","tag":"记忆","icon":"▤"},
	{"id":"focus","name":"专注透镜","description":"连续答对达到 3 次后，正常攻击伤害 +2。","tag":"进攻","icon":"◉"},
	{"id":"lifebond","name":"生命书签","description":"本局最大生命 +15，并立即恢复 15 生命。","tag":"续航","icon":"♡"},
	{"id":"renewal","name":"复苏墨水","description":"每场首次达到 5 连击时恢复 8 生命，只触发一次。","tag":"续航","icon":"✧"},
	{"id":"restoration","name":"温习手稿","description":"回忆书房每题答对的恢复量由 5 提高到 7。","tag":"记忆","icon":"▤"},
	{"id":"opening","name":"战前筹谋","description":"每场首次答对的正常伤害 +6，错误不会消耗这个机会。","tag":"进攻","icon":"⚑"}
]
const SUPPLIES := [
	{"id":"recover","name":"生命药剂","description":"立即恢复 20 生命，不超过上限。可重复获得。","tag":"补给","icon":"✚","repeatable":true},
	{"id":"ward","name":"应急护符","description":"下一场额外获得 8 起始护盾，受护盾上限约束。可重复获得。","tag":"补给","icon":"◇","repeatable":true},
	{"id":"insight","name":"灵感墨滴","description":"下一场首次答对的正常伤害额外 +8，可累积至 16。可重复获得。","tag":"补给","icon":"✦","repeatable":true}
]
const BASE_TAGS := {"blade":"进攻","crystal":"续航","flame":"进攻","shield":"防御","tome":"记忆","quill":"续航"}
const COLORS := {"进攻":Color("#d89275"),"防御":Color("#87becd"),"法力":Color("#b39ed9"),"记忆":Color("#d3b37a"),"续航":Color("#8bbb93"),"补给":Color("#aba89d")}

static func find(id: String, base: Array) -> Dictionary:
	for item in base+EXTRA+SUPPLIES:
		if str(item.id) == id: return item
	return {}

static func tag(item: Dictionary) -> String:
	return str(item.get("tag",BASE_TAGS.get(str(item.id),"进攻")))
