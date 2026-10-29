extends RefCounted
## Presentation metadata only. Does not enter reward selection, ownership or combat math.
const TIERS := {
	"blade":0,"tome":0,"echo":0,"opening":0,"restoration":0,
	"crystal":1,"quill":1,"aegis_edge":1,"bulwark":1,"focus":1,
	"shield":2,"mana_ring":2,"spring":2,"renewal":2,"lifebond":2,
	"flame":3,"thorns":3,"resonance":3
}
const NAMES := ["普通","稀有","史诗","传奇"]
const COLORS := [Color("#a5b0b0"),Color("#8caeb6"),Color("#b1a2b2"),Color("#be9a74")]

static func describe(item: Dictionary) -> Dictionary:
	var tier := int(TIERS.get(str(item.id),0))
	return {"name":NAMES[tier],"color":COLORS[tier],"marks":"I".repeat(tier+1)}
