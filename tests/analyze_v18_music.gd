extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if OS.get_environment("WORDROGUE_TEST_PROFILE") != "1" or not OS.get_user_data_dir().contains(".local_test"): quit(2); return
	var records := {}
	var rate := AudioServer.get_mix_rate()
	for key in ["normal_battle","boss_battle","title_map","elite_battle","memory_rest","event_special"]:
		var stream := AudioStreamOggVorbis.load_from_file("res://assets/audio/bgm/"+str(key)+".ogg")
		if stream == null: push_error("BGM decode failed "+str(key)); quit(1); return
		var duration := stream.get_length()
		if duration <= 0 or (key not in ["normal_battle","boss_battle"] and duration < 25): push_error("Music unexpectedly short "+str(key)); quit(1); return
		var energy := 0.0
		var peak := 0.0
		var count := 0
		var playback := stream.instantiate_playback()
		for part in 8:
			playback.start(maxf(0,duration*float(part)/8.0))
			var samples := playback.mix_audio(1.0,rate*2)
			for sample in samples:
				energy += (sample.x*sample.x+sample.y*sample.y)*0.5
				peak = maxf(peak,maxf(absf(sample.x),absf(sample.y))); count += 1
			playback.stop()
		var rms := sqrt(energy/maxi(1,count))
		if peak < 0.001: push_error("Silent music "+str(key)); quit(1); return
		stream.loop = true
		playback = stream.instantiate_playback()
		playback.start(duration-0.15)
		var seam := playback.mix_audio(1.0,ceili(rate*0.4))
		var loop_alive := playback.is_playing()
		playback.stop()
		var index := ceili(rate*0.15)
		var jump := maxf(absf(seam[index].x-seam[index-1].x),absf(seam[index].y-seam[index-1].y))
		var gain_db := minf(0.0,linear_to_db(0.13/maxf(rms,0.001)))
		records[key] = {"duration":duration,"rms_sampled_16s":rms,"sample_peak":peak,"loop_alive":loop_alive,"loop_boundary_step":jump,"suggested_gain_db":gain_db}
		print("V18 MUSIC ",key," ",records[key])
	var file := FileAccess.open("res://assets/audio/v18_music_analysis.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t")); file.close()
	quit()
