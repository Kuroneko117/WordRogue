extends RefCounted

const ENEMIES := {
	"ink_wraith":{"name":"INK WRAITH","subtitle":"墨影","hp":50,"atk":10,"kind":"normal","threshold":3,"ultimate":"ink_surge","art":"ink_wraith"},
	"dust_sentinel":{"name":"DUST SENTINEL","subtitle":"尘页守卫","hp":50,"atk":10,"kind":"normal","threshold":3,"ultimate":"dust_quake","art":"ink_wraith"},
	"paper_golem":{"name":"PAPER GOLEM","subtitle":"纸页傀儡","hp":60,"atk":10,"kind":"normal","threshold":3,"ultimate":"page_quake","art":""},
	"grimoire_mimic":{"name":"GRIMOIRE MIMIC","subtitle":"拟态魔典","hp":52,"atk":10,"kind":"normal","threshold":3,"ultimate":"mimic_devour","art":""},
	"lantern_wisp":{"name":"LANTERN WISP","subtitle":"幽灯之灵","hp":44,"atk":9,"kind":"normal","threshold":2,"ultimate":"wisp_flash","art":""},
	"marginalia":{"name":"THE MARGINALIA","subtitle":"边注之灵","hp":70,"atk":12,"kind":"elite","threshold":3,"ultimate":"margin_storm","art":"marginalia"},
	"silent_archivist":{"name":"SILENT ARCHIVIST","subtitle":"沉默档案官","hp":75,"atk":12,"kind":"elite","threshold":3,"ultimate":"final_volume","art":""},
	"librarian":{"name":"THE LIBRARIAN","subtitle":"遗忘图书管理员","hp":100,"atk":15,"kind":"boss","threshold":3,"ultimate":"final_judgment","art":"librarian"}
}

static func pool(layer: int, kind: String) -> Array:
	if kind == "boss": return ["librarian"]
	if kind == "elite": return ["marginalia","silent_archivist"]
	if layer <= 2: return ["ink_wraith","paper_golem","lantern_wisp"]
	if layer <= 4: return ["ink_wraith","paper_golem","lantern_wisp","grimoire_mimic"]
	return ["ink_wraith","dust_sentinel","paper_golem","lantern_wisp","grimoire_mimic"]

static func pick(layer: int, kind: String, history: Array[String], rng: RandomNumberGenerator) -> String:
	var choices := pool(layer,kind)
	if kind == "normal" and history.size() >= 2 and history[-1] == history[-2] and choices.size() > 1: choices.erase(history[-1])
	return str(choices[rng.randi_range(0,choices.size()-1)])
