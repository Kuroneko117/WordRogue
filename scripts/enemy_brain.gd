extends RefCounted

const ATTACKS := {
	"ink_bolt":{"name":"墨弹","multiplier":1.0,"strong":false,"effect":"","release":"ink_launch","impact":"ink_impact"},
	"shadow_lunge":{"name":"暗影扑击","multiplier":1.3,"strong":true,"effect":"","release":"shadow_lunge","impact":"heavy_impact"},
	"paper_slash":{"name":"纸刃","multiplier":1.0,"strong":false,"effect":"","release":"paper_slash","impact":"paper_impact"},
	"ink_mark":{"name":"墨蚀批注","multiplier":0.7,"strong":false,"effect":"ink","release":"curse_cast","impact":"curse_impact"},
	"torn_page":{"name":"撕页重击","multiplier":1.5,"strong":true,"effect":"","release":"torn_page","impact":"heavy_impact"},
	"arcane_tome":{"name":"古书冲击","multiplier":1.0,"strong":false,"effect":"","release":"tome_cast","impact":"tome_impact"},
	"oblivion_mark":{"name":"遗忘烙印","multiplier":0.7,"strong":false,"effect":"ink","release":"oblivion_cast","impact":"curse_impact"},
	"judgment":{"name":"知识审判","multiplier":1.6,"strong":true,"effect":"","release":"judgment_cast","impact":"judgment_impact"},
	"sealed_pages":{"name":"封印书页","multiplier":0.6,"strong":false,"effect":"seal","release":"seal_cast","impact":"seal_impact"},
	"paper_fist":{"name":"纸拳","multiplier":1.0,"strong":false,"effect":"","release":"paper_slash","impact":"paper_impact"},
	"binding_ram":{"name":"装订冲撞","multiplier":1.25,"strong":true,"effect":"","release":"shadow_lunge","impact":"heavy_impact"},
	"mimic_bite":{"name":"魔典撕咬","multiplier":1.0,"strong":false,"effect":"","release":"tome_cast","impact":"heavy_impact"},
	"arcane_theft":{"name":"奥术窃取","multiplier":0.7,"strong":false,"effect":"seal","release":"seal_cast","impact":"seal_impact"},
	"wisp_spark":{"name":"幽灯火花","multiplier":0.9,"strong":false,"effect":"","release":"ink_launch","impact":"ink_impact"},
	"spirit_dash":{"name":"灵火突袭","multiplier":1.1,"strong":true,"effect":"","release":"shadow_lunge","impact":"paper_impact"},
	"archive_chain":{"name":"档案锁链","multiplier":1.0,"strong":false,"effect":"","release":"seal_cast","impact":"seal_impact"},
	"silent_seal":{"name":"沉默封印","multiplier":0.7,"strong":false,"effect":"seal","release":"seal_cast","impact":"seal_impact"},
	"archive_judgment":{"name":"档案审判","multiplier":1.45,"strong":true,"effect":"","release":"judgment_cast","impact":"judgment_impact"},
	"page_quake":{"name":"裂页震击","multiplier":1.4,"strong":true,"effect":"","release":"torn_page","impact":"heavy_impact"},
	"mimic_devour":{"name":"魔典吞噬","multiplier":1.2,"strong":true,"effect":"","release":"tome_cast","impact":"heavy_impact"},
	"wisp_flash":{"name":"幽光爆闪","multiplier":1.15,"strong":true,"effect":"","release":"curse_cast","impact":"curse_impact"},
	"final_volume":{"name":"最终封卷","multiplier":1.5,"strong":true,"effect":"seal","release":"seal_cast","impact":"heavy_impact"},
	"ink_surge":{"name":"墨潮爆涌","multiplier":1.4,"strong":true,"effect":"","release":"ink_launch","impact":"heavy_impact"},
	"dust_quake":{"name":"尘页震荡","multiplier":1.4,"strong":true,"effect":"","release":"torn_page","impact":"heavy_impact"},
	"margin_storm":{"name":"批注风暴","multiplier":1.5,"strong":true,"effect":"ink","release":"curse_cast","impact":"heavy_impact"},
	"final_judgment":{"name":"终末审判","multiplier":1.6,"strong":true,"effect":"seal","release":"judgment_cast","impact":"judgment_impact"}
}
var previous := ""

func reset() -> void:
	previous = ""

func allowed(kind: String, enemy_id: String = "") -> Array:
	if enemy_id == "paper_golem": return ["paper_fist","binding_ram"]
	if enemy_id == "grimoire_mimic": return ["mimic_bite","arcane_theft"]
	if enemy_id == "lantern_wisp": return ["wisp_spark","spirit_dash"]
	if enemy_id == "silent_archivist": return ["archive_chain","silent_seal","archive_judgment"]
	if kind == "boss": return ["arcane_tome","oblivion_mark","judgment","sealed_pages"]
	if kind == "elite": return ["paper_slash","ink_mark","torn_page"]
	return ["ink_bolt","shadow_lunge"]

func choose(kind: String, phase_two: bool, rng: RandomNumberGenerator, enemy_id: String = "") -> Dictionary:
	var ids := allowed(kind,enemy_id)
	var weights: Array = [45.0,25.0,15.0,15.0] if kind == "boss" else ([40.0,30.0,30.0] if kind == "elite" else [70.0,30.0])
	if kind == "boss" and phase_two: weights = [20.0,20.0,35.0,25.0]
	if enemy_id == "silent_archivist": weights = [45.0,30.0,25.0]
	var total := 0.0
	for i in ids.size():
		# No consecutive heavy attacks, even if the previous intent was interrupted.
		if previous != "" and ATTACKS[previous].strong and ATTACKS[ids[i]].strong: weights[i] = 0.0
		total += float(weights[i])
	var roll := rng.randf()*total
	var chosen := str(ids[0])
	for i in ids.size():
		roll -= float(weights[i])
		if roll < 0:
			chosen = str(ids[i])
			break
	previous = chosen
	var intent: Dictionary = ATTACKS[chosen].duplicate()
	intent["id"] = chosen
	intent.make_read_only()
	return intent
