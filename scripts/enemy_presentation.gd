extends RefCounted

const Effect = preload("res://scripts/ui/enemy_effect.gd")
const Spell = preload("res://scripts/ui/enemy_spell.gd")
const Profiles = preload("res://scripts/presentation_profiles.gd")

# Keep the original Boss phase-aura API.
static func effect(host: Control, mode: String, position: Vector2, red: bool, life: float) -> Node2D:
	var node := Effect.new()
	node.mode = mode
	node.position = position
	node.red = red
	node.life = life
	node.z_index = 2
	host.add_child(node)
	return node

static func graphic(host: Control, mode: String, family: String, position: Vector2, life: float = 0.65) -> Node2D:
	var node := Spell.new()
	node.mode = mode
	node.family = family
	node.position = position
	node.life = life
	node.z_index = 2
	host.add_child(node)
	return node

static func play(host: Control, result: Dictionary, epoch: int) -> bool:
	var intent: Dictionary = result.intent
	var id := str(intent.id)
	var profile := Profiles.attack(id,str(GameState.current_enemy().get("id","")))
	var family := str(profile.family)
	var motion := str(profile.motion)
	var lunge := motion in ["dash","bite"]
	var ultimate := bool(intent.get("uninterruptible",false))
	var actor: Control = host.enemy_avatar
	var target: Control = host.player_avatar
	var from: Vector2 = actor.spell_origin()
	var to: Vector2 = target.spell_origin()
	var pose: Node2D = actor.pose
	actor.idle_enabled = false
	var charge_time := 0.26 if ultimate or id in ["torn_page","judgment"] else 0.15
	var gather := graphic(host,"charge",family,from,1.0)
	host._fx().tween_property(gather,"progress",1.0,charge_time)
	var charging_sound := str(profile.cast_sfx).ends_with("_charge")
	if charging_sound: AudioBus.play_event(str(profile.cast_sfx))
	if id in ["judgment","final_judgment"]: AudioBus.play_event("boss_charge")
	host._fx().tween_property(pose,"position:x",34.0 if lunge else -15.0,charge_time)
	if not await host._wait(charge_time,epoch): return false
	if is_instance_valid(gather): gather.queue_free()
	if not charging_sound: AudioBus.play_event(str(profile.cast_sfx))
	host._present("release",id)
	if lunge:
		var trail := graphic(host,"trail",family,actor.visual.global_position,0.7)
		trail.endpoint = Vector2(to.x-from.x,0)
		if actor.uses_texture:
			trail.image = actor.art.texture
			trail.image_size = actor.texture_bounds().size
		host._fx().tween_property(trail,"progress",1.0,0.24)
		host._fx().tween_property(pose,"position:x",to.x-from.x,0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if not await host._wait(0.24,epoch): return false
	elif motion in ["sigil","line","siphon"]:
		var origin := from if motion == "line" else to
		var sigil := graphic(host,str(profile.projectile),family,origin,0.75)
		sigil.endpoint = to-from if motion == "line" else from-to
		host._fx().tween_property(sigil,"progress",1.0,0.28)
		if not await host._wait(0.28,epoch): return false
	else:
		var projectile := graphic(host,str(profile.projectile),family,from,0.8)
		if profile.projectile in ["paper_blade","paper_wave"]: projectile.rotation = (to-from).angle()
		host._fx().tween_property(projectile,"position",to,0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if not await host._wait(0.30,epoch): return false
		projectile.queue_free()
	AudioBus.play_event(str(profile.hit_sfx))
	if int(result.damage) > 0: AudioBus.play_event("player_hit")
	if bool(result.shielded) or int(result.barrier_absorbed) > 0: AudioBus.play_event("shield_hit")
	host._present("impact",id)
	host._enemy_impact(result)
	if lunge and not await host._wait(0.12,epoch): return false
	var hit := graphic(host,str(profile.hit),family,to,0.42)
	host._fx().tween_property(hit,"progress",1.0,0.35)
	host._fx().tween_property(pose,"position",Vector2.ZERO,0.22)
	if not await host._wait(0.22,epoch): return false
	actor.idle_enabled = true
	return true
