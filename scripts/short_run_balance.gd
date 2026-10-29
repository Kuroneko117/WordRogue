extends RefCounted

# Only HP and map progression are tuned. Attack, spells and momentum stay intact.
const BASE_HP := {"ink_wraith":46,"dust_sentinel":48,"paper_golem":52,"grimoire_mimic":48,"lantern_wisp":42,"marginalia":68,"silent_archivist":72,"librarian":90}

static func growth(kind: String) -> int:
	return 1 if kind == "normal" else 2
