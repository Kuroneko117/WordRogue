extends Node
const Profiles = preload("res://scripts/presentation_profiles.gd")

const EVENTS := ["ui_click", "correct", "wrong", "player_cast", "player_hit", "enemy_hit", "enemy_death", "combo_trigger", "reward_select", "victory", "defeat", "boss_intro", "enemy_cast", "magic_hit", "player_hurt", "combo", "projectile_impact", "enemy_hurt", "aegis_activate", "shield_hit", "memory_charge", "memory_burst", "burst_impact"]
const ALIASES := {"enemy_hit":"enemy_hurt","player_hit":"player_hurt","combo_trigger":"combo","player_cast":"arcane_release","magic_hit":"projectile_impact"}
const ATTACK_SOUNDS := {
	"ink_launch":["enemy_cast",0.9],"ink_impact":["projectile_impact",1.0],
	"shadow_lunge":["memory_burst",0.7],"paper_slash":["arcane_release",1.2],"paper_impact":["shield_hit",1.2],
	"curse_cast":["memory_charge",0.8],"curse_impact":["aegis_activate",0.65],
	"torn_page":["enemy_cast",0.6],"heavy_impact":["burst_impact",0.85],
	"tome_cast":["aegis_activate",0.9],"tome_impact":["projectile_impact",0.9],
	"oblivion_cast":["memory_charge",0.6],"boss_charge":["memory_charge",0.55],
	"judgment_cast":["memory_burst",0.75],"judgment_impact":["burst_impact",0.65],
	"seal_cast":["arcane_release",0.75],"seal_impact":["shield_hit",0.7]
}
var streams: Dictionary = {}
const MATERIAL_SOUNDS := {
	"ink_cast":["ink_spray",1.0],"ink_splash":["ink_splash_texture",1.0],"ink_dash":["enemy_cast",0.7],"ink_claw_hit":["ink_splash_texture",0.8],"ink_surge_cast":["ink_surge_texture",0.9],"ink_surge_hit":["ink_splash_texture",0.75],
	"dust_cast":["paper_rustle",0.8],"dust_dash":["enemy_cast",0.7],"dust_hit":["paper_strike",0.8],"dust_charge":["paper_rustle",0.7],"dust_quake_hit":["paper_heavy",0.8],
	"paper_fist_swing":["paper_rustle",1.0],"paper_thud":["paper_strike",1.0],"binding_ram_cast":["paper_heavy",0.85],"paper_heavy_hit":["paper_strike",0.8],"page_charge":["paper_rustle",0.8],"page_quake_hit":["paper_heavy",0.9],
	"mimic_open":["mimic_open_texture",1.0],"mimic_bite_hit":["mimic_bite_texture",1.0],"mimic_siphon":["mimic_drain",0.9],"mana_drain_hit":["archive_seal_texture",0.9],"mimic_devour_cast":["mimic_open_texture",0.7],"mimic_devour_hit":["mimic_devour_texture",1.0],
	"wisp_cast":["wisp_fire",1.0],"wisp_spark_hit":["wisp_fire",1.2],"wisp_dash":["wisp_shift",1.0],"wisp_flare_hit":["wisp_flare",0.9],"wisp_charge":["wisp_shift",0.8],"wisp_flash_hit":["wisp_flare",1.0],
	"margin_page_cast":["paper_rustle",1.15],"margin_page_hit":["paper_strike",1.1],"margin_mark_cast":["archive_seal_texture",0.9],"margin_mark_hit":["ink_splash_texture",0.8],"margin_torn_cast":["paper_rustle",0.9],"margin_torn_hit":["paper_heavy",0.9],"margin_storm_cast":["paper_rustle",0.75],"margin_storm_hit":["paper_heavy",0.8],
	"archive_chain_cast":["archive_chain_texture",1.0],"chain_hit":["archive_chain_texture",0.8],"archive_seal_cast":["archive_seal_texture",0.9],"archive_seal_hit":["archive_judgment_texture",0.9],"archive_judgment_cast":["archive_judgment_texture",1.0],"archive_judgment_hit":["boss_impact_texture",0.9],"archive_volume_cast":["boss_tome_texture",0.85],"archive_volume_hit":["paper_heavy",0.9],
	"boss_tome_cast":["boss_tome_texture",0.9],"boss_tome_hit":["paper_heavy",0.85],"boss_oblivion_cast":["archive_seal_texture",0.7],"boss_mark_hit":["ink_splash_texture",0.7],"boss_judgment_cast":["archive_judgment_texture",0.8],"boss_judgment_hit":["boss_impact_texture",0.8],"boss_seal_cast":["archive_seal_texture",0.8],"boss_seal_hit":["archive_chain_texture",0.7],"boss_final_cast":["archive_judgment_texture",0.7],"boss_final_hit":["boss_impact_texture",0.65]
}
var sound_pitches: Dictionary = {}
const TEXTURE_FALLBACKS := {
	"ink_spray":"enemy_cast","ink_splash_texture":"projectile_impact","ink_surge_texture":"burst_impact",
	"paper_rustle":"enemy_cast","paper_strike":"projectile_impact","paper_heavy":"burst_impact",
	"mimic_open_texture":"enemy_cast","mimic_bite_texture":"burst_impact","mimic_drain":"memory_charge","mimic_devour_texture":"burst_impact",
	"wisp_fire":"enemy_cast","wisp_shift":"memory_burst","wisp_flare":"burst_impact",
	"archive_chain_texture":"shield_hit","archive_seal_texture":"aegis_activate","archive_judgment_texture":"memory_charge",
	"boss_tome_texture":"enemy_cast","boss_impact_texture":"burst_impact"
}
var music_gains: Dictionary = {}
var event_counts: Dictionary = {}
var event_log: Array[Dictionary] = []
var music_streams: Dictionary = {}
var music_key := ""
var scene_music_key := ""
var music_start_count := 0
var music_player := AudioStreamPlayer.new()
var music_tween: Tween
var music_epoch := 0
var audio_paused := false
@export var master_db := -1.0
@export var sfx_db := -9.0
@export var bgm_db := -25.0
const SETTINGS_PATH := "user://wordrogue_audio.cfg"
var music_percent := 50.0
var sfx_percent := 75.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["SFX","BGM"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count-1
			AudioServer.set_bus_name(index,bus)
			AudioServer.set_bus_send(index,"Master")
	load_settings()
	for event in EVENTS+ATTACK_SOUNDS.keys()+MATERIAL_SOUNDS.keys():
		var filename := str(ATTACK_SOUNDS[event][0]) if ATTACK_SOUNDS.has(event) else str(ALIASES.get(event,event))
		var candidates := [filename]
		if MATERIAL_SOUNDS.has(event):
			var material_file := str(MATERIAL_SOUNDS[event][0])
			candidates = [str(event),material_file]
			if TEXTURE_FALLBACKS.has(material_file): candidates.append(str(TEXTURE_FALLBACKS[material_file]))
		for candidate in candidates:
			for extension in ["wav", "ogg"]:
				var path := "res://assets/audio/sfx/%s.%s" % [str(candidate), extension]
				if ResourceLoader.exists(path):
					var stream: Resource = load(path)
					if stream is AudioStream:
						streams[event] = stream
						if MATERIAL_SOUNDS.has(event): sound_pitches[event] = 1.0 if candidate == event else float(MATERIAL_SOUNDS[event][1])
						break
			if streams.has(event): break
	for key in ["normal_battle","boss_battle","title_map","elite_battle","memory_rest","event_special","victory_result"]:
		var path := "res://assets/audio/bgm/"+str(key)+".ogg"
		if ResourceLoader.exists(path):
			var stream: Resource = load(path)
			if stream is AudioStreamOggVorbis:
				var loop: AudioStreamOggVorbis = stream.duplicate()
				loop.loop = true
				music_streams[key] = loop
	music_player.name = "Music"
	# Per-resource attenuation never writes the user's BGM/SFX settings.
	if FileAccess.file_exists("res://assets/audio/v18_music_analysis.json"):
		var measured: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/v18_music_analysis.json"))
		if measured is Dictionary:
			for key in ["title_map","elite_battle","memory_rest","event_special"]:
				var item: Variant = measured.get(key,{})
				if item is Dictionary: music_gains[key] = clampf(float(item.get("suggested_gain_db",0.0)),-12.0,0.0)
	music_player.bus = "BGM"
	add_child(music_player)

func apply_volumes() -> void:
	bgm_db = -40.0+music_percent*0.3
	sfx_db = -28.0+sfx_percent*0.25
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),master_db)
	for pair in [["SFX",sfx_db],["BGM",bgm_db]]:
		var index := AudioServer.get_bus_index(str(pair[0]))
		if index >= 0: AudioServer.set_bus_volume_db(index,float(pair[1]))
	for pair in [["BGM",music_percent],["SFX",sfx_percent]]:
		var index := AudioServer.get_bus_index(str(pair[0]))
		if index >= 0: AudioServer.set_bus_mute(index,float(pair[1]) <= 0.0)

func _safe_percent(value: Variant, fallback: float) -> float:
	if typeof(value) not in [TYPE_INT,TYPE_FLOAT]: return fallback
	var number := float(value)
	return clampf(number,0.0,100.0) if is_finite(number) else fallback

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_percent = _safe_percent(config.get_value("audio","music",50.0),50.0)
		sfx_percent = _safe_percent(config.get_value("audio","sfx",75.0),75.0)
	else:
		music_percent = 50.0
		sfx_percent = 75.0
	apply_volumes()

func set_volume(channel: String, percent: float, persist: bool = true) -> void:
	if not is_finite(percent): return
	if channel == "music": music_percent = clampf(percent,0.0,100.0)
	elif channel == "sfx": sfx_percent = clampf(percent,0.0,100.0)
	else: return
	apply_volumes()
	if persist: save_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio","music",music_percent)
	config.set_value("audio","sfx",sfx_percent)
	if config.save(SETTINGS_PATH) != OK: push_warning("音量设置暂时无法保存。")

func reset_settings() -> void:
	music_percent = 50.0
	sfx_percent = 75.0
	apply_volumes()
	save_settings()

func play_event(event: String) -> void:
	if (not EVENTS.has(event) and not ATTACK_SOUNDS.has(event) and not MATERIAL_SOUNDS.has(event)) or audio_paused and event != "ui_click":
		return
	event_counts[event] = int(event_counts.get(event, 0)) + 1
	event_log.append({"event":event,"time":Time.get_ticks_msec(),"file":str(streams[event].resource_path) if streams.has(event) else ""})
	if event_log.size() > 128: event_log.pop_front()
	if not streams.has(event):
		return
	if get_child_count() >= 9:
		return
	var player := AudioStreamPlayer.new()
	player.set_meta("event",event)
	player.stream = streams[event]
	player.bus = "SFX"
	player.volume_db = -5.0 if event in ["projectile_impact","enemy_hurt","burst_impact","memory_charge"] or event.ends_with("impact") or event.ends_with("_hit") else (-3.0 if event in ["ui_click","correct","wrong"] else 0.0)
	player.pitch_scale = float(sound_pitches[event]) if sound_pitches.has(event) else (float(ATTACK_SOUNDS[event][1]) if ATTACK_SOUNDS.has(event) else (0.85 if event == "boss_intro" else 1.0))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func set_scene_music(key: String, quiet: bool = false) -> void:
	scene_music_key = key
	for candidate in Profiles.MUSIC.get(key,[]):
		if music_streams.has(candidate):
			set_music(str(candidate),quiet)
			return
	fade_music_out()

func fade_music_out() -> void:
	if music_key.is_empty(): return
	music_epoch += 1
	var epoch := music_epoch
	if music_tween != null and music_tween.is_valid(): music_tween.kill()
	music_key = ""
	music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	music_tween.tween_property(music_player,"volume_db",-45.0,0.25)
	music_tween.tween_callback(func() -> void:
		if epoch == music_epoch:
			music_player.stop()
			music_player.stream = null)

func set_music(key: String, quiet: bool = false) -> void:
	var volume := (-7.0 if quiet else 0.0)+float(music_gains.get(key,0.0))
	if key == music_key and music_player.playing and music_player.stream == music_streams.get(key):
		music_epoch += 1
		if music_tween != null and music_tween.is_valid(): music_tween.kill()
		music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
		music_tween.tween_property(music_player,"volume_db",volume,0.25)
		return
	music_epoch += 1
	var epoch := music_epoch
	if music_tween != null and music_tween.is_valid(): music_tween.kill()
	if not music_streams.has(key):
		stop_music()
		return
	music_key = key
	music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	music_tween.tween_property(music_player,"volume_db",-45.0,0.2 if music_player.playing else 0.01)
	music_tween.tween_callback(func() -> void:
		if epoch != music_epoch: return
		music_player.stop()
		music_player.stream = music_streams[key]
		music_player.play()
		music_player.stream_paused = audio_paused
		music_start_count += 1)
	music_tween.tween_property(music_player,"volume_db",volume,0.4)

func quiet_music() -> void:
	if not music_key.is_empty(): set_music(music_key,true)

func stop_music() -> void:
	music_epoch += 1
	if music_tween != null and music_tween.is_valid(): music_tween.kill()
	music_player.stop()
	music_player.stream = null
	music_key = ""

func stop_all() -> void:
	stop_music()
	stop_effects()

func stop_effects() -> void:
	for child in get_children():
		if child != music_player and child is AudioStreamPlayer:
			child.stop()
			child.queue_free()

func set_paused(value: bool) -> void:
	audio_paused = value
	for child in get_children():
		if child is AudioStreamPlayer: child.stream_paused = value

func _exit_tree() -> void:
	if music_tween != null and music_tween.is_valid(): music_tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
