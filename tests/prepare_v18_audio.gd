extends SceneTree

# Native offline decoding/preparation, isolated user profile required.
const K := "res://.local_test/audio_sources/rpg/Audio/"
const R := "res://.local_test/v13_audio_sources/rpg/"
const SOURCES := {
	"ink_spray":[[R+"creature_slime_01.ogg"],0.42],
	"ink_splash_texture":[[R+"creature_slime_02.ogg"],0.32],
	"ink_surge_texture":[[R+"creature_slime_04.ogg"],0.65],
	"paper_rustle":[[K+"bookFlip3.ogg"],0.40],
	"paper_strike":[[K+"bookPlace3.ogg"],0.32],
	"paper_heavy":[[K+"bookClose.ogg"],0.42],
	"mimic_open_texture":[[K+"bookOpen.ogg"],0.32],
	"mimic_bite_texture":[[K+"bookClose.ogg",R+"creature_monster_02.ogg"],0.55],
	"mimic_drain":[[R+"spell_02.ogg"],0.55],
	"mimic_devour_texture":[[R+"creature_monster_03.ogg",K+"bookClose.ogg"],0.65],
	"wisp_fire":[[R+"spell_fire_01.ogg"],0.42],
	"wisp_shift":[[R+"spell_fire_04.ogg"],0.38],
	"wisp_flare":[[R+"spell_fire_07.ogg"],0.65],
	"archive_chain_texture":[[R+"chain_01.ogg"],0.48],
	"archive_seal_texture":[[R+"spell_02.ogg",R+"lock_03.ogg"],0.50],
	"archive_judgment_texture":[[R+"spell_01.ogg",R+"item_gem_04.ogg"],0.60],
	"boss_tome_texture":[[K+"bookOpen.ogg",R+"spell_01.ogg"],0.50],
	"boss_impact_texture":[[R+"stones_04.ogg",R+"spell_fire_05.ogg"],0.60]
}

func _initialize() -> void: call_deferred("run")

func decode(path: String, seconds: float) -> PackedFloat32Array:
	var stream := AudioStreamOggVorbis.load_from_file(path)
	if stream == null: push_error("Missing source "+path); quit(1); return PackedFloat32Array()
	var playback := stream.instantiate_playback()
	playback.start()
	var frames := playback.mix_audio(1.0,ceili(minf(stream.get_length(),seconds+0.2)*AudioServer.get_mix_rate()))
	playback.stop()
	var start := 0
	while start < frames.size() and maxf(absf(frames[start].x),absf(frames[start].y)) < 0.003: start += 1
	var mono := PackedFloat32Array()
	for i in mini(frames.size()-start,ceili(seconds*AudioServer.get_mix_rate())):
		mono.append((frames[start+i].x+frames[start+i].y)*0.5)
	return mono

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	var rate := AudioServer.get_mix_rate()
	var records := {}
	for id in SOURCES:
		var item: Array = SOURCES[id]
		var count := ceili(float(item[1])*rate)
		var mono := PackedFloat32Array(); mono.resize(count)
		for j in item[0].size():
			var layer := decode(str(item[0][j]),float(item[1]))
			for n in mini(layer.size(),count): mono[n] += layer[n]*(1.0 if j == 0 else 0.6)
		var peak := 0.0
		var energy := 0.0
		for sample in mono: peak = maxf(peak,absf(sample)); energy += sample*sample
		if peak < 0.001: push_error("Silent source "+str(id)); quit(1); return
		var rms := sqrt(energy/count)
		var gain := minf(0.38/peak,0.09/maxf(rms,0.001))
		var pcm := PackedByteArray(); pcm.resize(count*2)
		for n in count:
			var fade := minf(1.0,minf(float(n)/maxf(1.0,rate*0.003),float(count-1-n)/maxf(1.0,rate*0.025)))
			pcm.encode_s16(n*2,roundi(clampf(mono[n]*gain*fade,-0.38,0.38)*32767))
		var path := "res://assets/audio/sfx/"+str(id)+".wav"
		if FileAccess.file_exists(path): push_error("Refusing to overwrite "+path); quit(1); return
		var wav := AudioStreamWAV.new(); wav.mix_rate = rate; wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.data = pcm
		if wav.save_to_wav(path) != OK: push_error("WAV export failed"); quit(1); return
		records[id] = {"file":str(id)+".wav","sources":item[0],"license":"CC0-1.0","duration":item[1],"source_peak":peak,"source_rms":rms,"gain":gain,"edit":"trim leading silence, layer if listed, mono PCM16, RMS/peak control, 3ms attack /25ms fade"}
		print("V18 prepared ",id)
	var file := FileAccess.open("res://assets/audio/v18_sfx_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t")); file.close()
	print("V18 SFX PREPARATION: 18 new actual WAVs, old files preserved")
	quit()
