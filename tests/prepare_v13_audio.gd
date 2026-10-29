extends SceneTree

const SOURCES := {
	"arcane_release": ["swishes/swishes/swish-10.wav",0.30,"artisticdude","Swishes Sound Pack"],
	"enemy_cast": ["swishes/swishes/swish-7.wav",0.38,"artisticdude","Swishes Sound Pack"],
	"memory_burst": ["swishes/swishes/swish-1.wav",0.40,"artisticdude","Swishes Sound Pack"],
	"projectile_impact": ["rpg/item_stone_02.ogg",0.18,"rubberduck","80 CC0 RPG SFX"],
	"enemy_hurt": ["rpg/creature_hurt_02.ogg",0.28,"rubberduck","80 CC0 RPG SFX"],
	"aegis_activate": ["rpg/item_gem_01.ogg",0.45,"rubberduck","80 CC0 RPG SFX"],
	"shield_hit": ["rpg/metal_03.ogg",0.22,"rubberduck","80 CC0 RPG SFX"],
	"memory_charge": ["rpg/spell_01.ogg",0.28,"rubberduck","80 CC0 RPG SFX"],
	"burst_impact": ["rpg/stones_02.ogg",0.35,"rubberduck","80 CC0 RPG SFX"]
}

func _initialize() -> void:
	call_deferred("_run")

func read_audio(path: String, seconds: float) -> PackedVector2Array:
	var stream: AudioStream = AudioStreamOggVorbis.load_from_file(path) if path.ends_with("ogg") else AudioStreamWAV.load_from_file(path)
	var playback := stream.instantiate_playback()
	playback.start()
	var samples := playback.mix_audio(1.0,ceili(minf(stream.get_length(),seconds)*AudioServer.get_mix_rate()))
	playback.stop()
	return samples

func analyze(mono: PackedFloat32Array) -> Dictionary:
	var peak := 0.0
	var energy := 0.0
	var crossings := 0
	for i in mono.size():
		peak = maxf(peak,absf(mono[i]))
		energy += mono[i]*mono[i]
		if i>0 and mono[i]*mono[i-1]<0: crossings += 1
	var correlation := 0.0
	var count := mini(8000,mono.size()-700)
	if count > 100:
		for lag in range(24,650,12):
			var dot := 0.0
			var a := 0.0
			var b := 0.0
			for i in count:
				dot += mono[i]*mono[i+lag]
				a += mono[i]*mono[i]
				b += mono[i+lag]*mono[i+lag]
			correlation = maxf(correlation,absf(dot)/maxf(0.00001,sqrt(a*b)))
	return {"peak":peak,"rms":sqrt(energy/maxi(1,mono.size())),"zero_crossing_ratio":float(crossings)/maxi(1,mono.size()),"max_periodic_correlation":correlation}

func _run() -> void:
	var rate := AudioServer.get_mix_rate()
	var output: Dictionary = {}
	for old in ["player_cast","magic_hit","player_hurt"]:
		var samples := read_audio("res://assets/audio/sfx/"+str(old)+".wav",0.7)
		var mono := PackedFloat32Array()
		for s in samples: mono.append((s.x+s.y)*0.5)
		output["v12_"+str(old)] = analyze(mono)
	for id in SOURCES:
		var item: Array = SOURCES[id]
		var samples := read_audio("res://.local_test/v13_audio_sources/"+str(item[0]),float(item[1])+0.15)
		var start := 0
		while start < samples.size() and maxf(absf(samples[start].x),absf(samples[start].y))<0.003: start += 1
		var count := mini(samples.size()-start,ceili(float(item[1])*rate))
		var mono := PackedFloat32Array()
		for i in count: mono.append((samples[start+i].x+samples[start+i].y)*0.5)
		var metrics := analyze(mono)
		var gain := minf(0.48/maxf(float(metrics["peak"]),0.001),0.11/maxf(float(metrics["rms"]),0.001))
		var pcm := PackedByteArray()
		pcm.resize(count*2)
		for i in count:
			var envelope := minf(1.0,minf(float(i)/maxf(1.0,rate*0.003),float(count-1-i)/maxf(1.0,rate*0.025)))
			pcm.encode_s16(i*2,roundi(clampf(mono[i]*gain*envelope,-0.48,0.48)*32767))
		var wav := AudioStreamWAV.new()
		wav.mix_rate = rate
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.data = pcm
		var path := "res://assets/audio/sfx/"+str(id)+".wav"
		if FileAccess.file_exists(path):
			push_error("Refusing to overwrite existing audio: "+path)
			quit(1)
			return
		wav.save_to_wav(path)
		metrics.merge({"file":str(id)+".wav","source_file":item[0],"author":item[2],"pack":item[3],"license":"CC0","gain":gain,"duration":float(count)/rate,"date":"2026-10-09"})
		output[id] = metrics
		print(id," ",metrics)
	var file := FileAccess.open("res://assets/audio/v13_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	print("V13 AUDIO PREPARATION: complete; old files and music preserved")
	quit()
