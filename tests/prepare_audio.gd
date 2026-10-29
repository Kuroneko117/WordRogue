extends SceneTree

# Offline asset preparation with Godot's own Vorbis decoder; no new tools.
const SOURCES := {
	"ui_click": ["interface/Audio/click_001.ogg",0.25,"Kenney Interface Sounds"],
	"correct": ["interface/Audio/confirmation_001.ogg",0.55,"Kenney Interface Sounds"],
	"wrong": ["interface/Audio/error_001.ogg",0.50,"Kenney Interface Sounds"],
	"player_cast": ["magical_3.ogg",0.65,"JaggedStone Magic Spell SFX"],
	"magic_hit": ["magical_5.ogg",0.40,"JaggedStone Magic Spell SFX"],
	"player_hurt": ["rpg/Audio/bookPlace1.ogg",0.40,"Kenney RPG Audio"],
	"enemy_death": ["magical_6.ogg",0.85,"JaggedStone Magic Spell SFX"],
	"combo": ["magical_1.ogg",0.65,"JaggedStone Magic Spell SFX"],
	"reward_select": ["interface/Audio/confirmation_003.ogg",0.55,"Kenney Interface Sounds"],
	"boss_intro": ["magical_4.ogg",1.20,"JaggedStone Magic Spell SFX"],
	"victory": ["jingles/Audio/Pizzicato jingles/jingles_PIZZI00.ogg",1.50,"Kenney Music Jingles"],
	"defeat": ["jingles/Audio/Pizzicato jingles/jingles_PIZZI15.ogg",1.25,"Kenney Music Jingles"]
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var metadata: Dictionary = {}
	var sample_rate := AudioServer.get_mix_rate()
	for event in SOURCES:
		var entry: Array = SOURCES[event]
		var source := "res://.local_test/audio_sources/"+str(entry[0])
		var stream := AudioStreamOggVorbis.load_from_file(source)
		if stream == null:
			push_error("Missing audio source: "+source)
			quit(1)
			return
		var playback := stream.instantiate_playback()
		playback.start()
		var samples := playback.mix_audio(1.0,ceili(minf(stream.get_length(),float(entry[1])+0.25)*sample_rate))
		playback.stop()
		var start := 0
		while start < samples.size() and maxf(absf(samples[start].x),absf(samples[start].y)) < 0.003:
			start += 1
		var count := mini(ceili(float(entry[1])*sample_rate),samples.size()-start)
		var mono := PackedFloat32Array()
		var peak := 0.0
		var sum_squared := 0.0
		for i in count:
			var value := (samples[start+i].x+samples[start+i].y)*0.5
			mono.append(value)
			peak = maxf(peak,absf(value))
			sum_squared += value*value
		if peak < 0.001 or count <= 0:
			push_error("Silent source: "+source)
			quit(1)
			return
		var rms := sqrt(sum_squared/count)
		var gain := minf(0.60/peak,0.14/maxf(rms,0.001))
		var pcm := PackedByteArray()
		pcm.resize(count*2)
		var fade := mini(ceili(0.035*sample_rate),count/3)
		for i in count:
			var envelope := minf(1.0,minf(float(i)/maxi(1,fade/3),float(count-1-i)/maxi(1,fade)))
			var value := roundi(clampf(mono[i]*gain*envelope,-0.65,0.65)*32767.0)
			pcm.encode_s16(i*2,value)
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = sample_rate
		wav.stereo = false
		wav.data = pcm
		var target := "res://assets/audio/sfx/"+str(event)+".wav"
		if FileAccess.file_exists(target):
			push_error("Refusing to overwrite existing user audio: "+target)
			quit(1)
			return
		if wav.save_to_wav(target) != OK:
			quit(1)
			return
		metadata[event] = {"file":str(event)+".wav","source_file":entry[0],"pack":entry[2],"license":"CC0","duration":float(count)/sample_rate,"source_peak":peak,"source_rms":rms,"gain":gain,"edits":"Trim leading silence, cap duration, mono 16-bit PCM, RMS/peak gain and short fade edges"}
		print(event," duration=",snappedf(float(count)/sample_rate,0.01)," source=",entry[0])
	for key in ["normal_battle","boss_battle"]:
		var target := "res://assets/audio/bgm/"+str(key)+".ogg"
		if FileAccess.file_exists(target):
			push_error("Refusing to overwrite existing music: "+target)
			quit(1)
			return
		DirAccess.copy_absolute("res://.local_test/audio_sources/"+str(key)+".ogg",target)
	var file := FileAccess.open("res://assets/audio/audio_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata,"  "))
	print("AUDIO PREPARATION: 12 WAV effects + 2 OGG loops")
	quit()
