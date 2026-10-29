extends RefCounted

# Presentation only: these keys never determine damage, intent or learning.
const SCENES := {
	"title_map":{"backgrounds":["title_map.png","library_battle.png"],"music":"title_map","shade":0.30},
	"battle_normal":{"backgrounds":["library_corridor.jpg","library_battle.png"],"music":"battle_normal","shade":0.38},
	"battle_elite":{"backgrounds":["library_elite.jpg","library_battle.png"],"music":"battle_elite","shade":0.48},
	"battle_boss":{"backgrounds":["library_boss.png","library_battle.png"],"music":"battle_boss","shade":0.36},
	"memory_rest":{"backgrounds":["memory_chamber.jpg","memory_rest.jpg","library_battle.png"],"music":"memory_rest","shade":0.38},
	"event_special":{"backgrounds":["event_ritual.jpg","library_battle.png"],"music":"event_special","shade":0.43},
	"report_win":{"backgrounds":["memory_chamber.jpg","memory_rest.jpg","library_battle.png"],"music":"optional_victory","shade":0.38},
	"report_fail":{"backgrounds":["memory_chamber.jpg","memory_rest.jpg","library_battle.png"],"music":"memory_rest","shade":0.43}
}
const MUSIC := {
	"title_map":["title_map"],"battle_normal":["normal_battle"],
	"battle_elite":["elite_battle","normal_battle"],"battle_boss":["boss_battle","normal_battle"],
	"memory_rest":["memory_rest","title_map"],"event_special":["event_special","title_map"],
	"optional_victory":["victory_result","title_map"]
}
const PORTRAITS := {
	"dust_sentinel":{"art":"dust_guard","fallback":"ink_wraith","height":480.0},
	"paper_golem":{"art":"paper_golem","height":480.0},
	"grimoire_mimic":{"art":"grimoire_mimic","height":480.0},
	"lantern_wisp":{"art":"lantern_wisp","height":430.0},
	"silent_archivist":{"art":"silent_archivist","height":520.0}
}
# family, motion, projectile, hit, cast sound, hit sound. No implicit paper fallback.
const ATTACKS := {
	"ink_bolt":["ink","shoot","ink_orb","splash","ink_cast","ink_splash"],
	"shadow_lunge":["ink","dash","trail","claw","ink_dash","ink_claw_hit"],
	"ink_surge":["ink","shoot","ink_wave","splash","ink_surge_cast","ink_surge_hit"],
	"paper_fist":["paper","punch","fist","paper_hit","paper_fist_swing","paper_thud"],
	"binding_ram":["paper","dash","trail","paper_hit","binding_ram_cast","paper_heavy_hit"],
	"page_quake":["paper","shoot","paper_wave","paper_hit","page_charge","page_quake_hit"],
	"mimic_bite":["mimic","bite","trail","mouth","mimic_open","mimic_bite_hit"],
	"arcane_theft":["mimic","siphon","siphon","seal","mimic_siphon","mana_drain_hit"],
	"mimic_devour":["mimic","sigil","mouth","mouth","mimic_devour_cast","mimic_devour_hit"],
	"wisp_spark":["wisp","shoot","flame","fire_hit","wisp_cast","wisp_spark_hit"],
	"spirit_dash":["wisp","dash","trail","fire_hit","wisp_dash","wisp_flare_hit"],
	"wisp_flash":["wisp","sigil","flare","fire_hit","wisp_charge","wisp_flash_hit"],
	"paper_slash":["margin","shoot","paper_blade","paper_hit","margin_page_cast","margin_page_hit"],
	"ink_mark":["margin","sigil","curse","seal","margin_mark_cast","margin_mark_hit"],
	"torn_page":["margin","shoot","paper_wave","paper_hit","margin_torn_cast","margin_torn_hit"],
	"margin_storm":["margin","sigil","paper_storm","paper_hit","margin_storm_cast","margin_storm_hit"],
	"archive_chain":["archive","line","chain","seal","archive_chain_cast","chain_hit"],
	"silent_seal":["archive","sigil","seal","seal","archive_seal_cast","archive_seal_hit"],
	"archive_judgment":["archive","sigil","judgment","judgment","archive_judgment_cast","archive_judgment_hit"],
	"final_volume":["archive","sigil","volume","seal","archive_volume_cast","archive_volume_hit"],
	"arcane_tome":["boss","shoot","book","paper_hit","boss_tome_cast","boss_tome_hit"],
	"oblivion_mark":["boss","sigil","curse","seal","boss_oblivion_cast","boss_mark_hit"],
	"judgment":["boss","sigil","judgment","judgment","boss_judgment_cast","boss_judgment_hit"],
	"sealed_pages":["boss","line","chain","seal","boss_seal_cast","boss_seal_hit"],
	"final_judgment":["boss","sigil","judgment","judgment","boss_final_cast","boss_final_hit"],
	"dust_quake":["dust","shoot","paper_wave","paper_hit","dust_charge","dust_quake_hit"]
}

static func battle_scene(kind: String) -> String:
	return "battle_boss" if kind == "boss" else ("battle_elite" if kind == "elite" else "battle_normal")

static func scene(key: String) -> Dictionary:
	return SCENES.get(key,SCENES.title_map)

static func attack(id: String, enemy_id: String = "") -> Dictionary:
	var item: Array = ATTACKS.get(id,["ink","shoot","ink_orb","splash","ink_cast","ink_splash"])
	var profile := {"vfx_id":id,"family":str(item[0]),"motion":str(item[1]),"projectile":str(item[2]),"hit":str(item[3]),"cast_sfx":str(item[4]),"hit_sfx":str(item[5])}
	if enemy_id == "dust_sentinel" and id in ["ink_bolt","shadow_lunge"]:
		profile.family = "dust"
		profile.cast_sfx = "dust_cast" if id == "ink_bolt" else "dust_dash"
		profile.hit_sfx = "dust_hit"
	return profile
