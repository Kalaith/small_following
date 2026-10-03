extends SceneTree
## Isolated presentation checks; never loads the player's progression.
var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func walk(player: CharacterBody2D, direction: Vector2, count: int) -> void:
	for i in range(count):
		await physics_frame
		player.step_motion(direction, 1.0 / 60.0)


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	var sound = scene.game_audio
	check(sound.music.playing == sound.output_enabled and sound.music.stream.loop, "promo score loops; playback starts on a rendering display")
	check(absf(sound.music.stream.get_length() - 72.0) < 0.1, "complete original promo score is available")
	check(sound.voice.max_polyphony == 1, "speech has one voice, never layered chatter")
	for clip in sound.MURMURS:
		check(clip.get_length() < sound.MIN_VOICE_SECONDS, "syllables leave a gap before the next permitted voice")
	await walk(scene.player, Vector2.ZERO, 30)
	check(sound.step_count == 0, "idle cultist makes no footsteps")
	scene.player.position = Vector2(600, 700)
	await walk(scene.player, Vector2.RIGHT, 60)
	var base_steps: int = sound.step_count
	check(base_steps >= 4 and base_steps <= 5, "base walking makes light distance-based footsteps")
	sound.reset_motion()
	scene.player.position = Vector2(600, 700)
	scene.player.movement_speed = 432.0
	await walk(scene.player, Vector2.RIGHT, 60)
	var fast_steps: int = sound.step_count - base_steps
	check(fast_steps > base_steps and fast_steps <= 8, "full running increases steps with a cadence ceiling")
	scene.player.position = Vector2(scene.player.world_bounds.end.x, 700)
	sound.reset_motion()
	var before: int = sound.step_count
	await walk(scene.player, Vector2.RIGHT, 30)
	check(sound.step_count == before, "pressing into a world edge makes no footsteps")
	scene.player.position = Vector2(780, 480)
	await walk(scene.player, Vector2.UP, 30)
	before = sound.step_count
	await walk(scene.player, Vector2.UP, 30)
	check(sound.step_count == before, "pressing into the well makes no footsteps")
	scene.player.position = scene.groups[0].position + Vector2(70, 0)
	scene.advance_round(1.0)
	check(sound.voice_count == 1 and scene.groups[0].progress == 1.0, "completed player phrase drives speech without altering conviction")
	scene.player.position = Vector2(600, 700)
	scene.advance_round(0.1)
	check(not sound.voice.playing, "leaving the audience stops speech")
	sound.voice_cooldown = 0.0
	before = sound.voice_count
	for i in range(60):
		sound.advance_time(1.0 / 60.0)
		sound.on_phrase()
	check(sound.voice_count - before <= 2, "burst phrase events are dropped instead of queued")
	check(sound.voice.pitch_scale == 1.0, "fast speech does not pitch up the syllables")
	var mute_event := InputEventAction.new()
	mute_event.action = "toggle_audio"
	mute_event.pressed = true
	scene._unhandled_input(mute_event)
	before = sound.voice_count
	sound.advance_time(1.0)
	sound.on_phrase()
	check(sound.muted and sound.music.volume_db == -80.0 and sound.voice_count == before, "M mutes music and suppresses new effects")
	scene._unhandled_input(mute_event)
	mute_event.action = "toggle_voice"
	scene._unhandled_input(mute_event)
	sound.on_phrase()
	check(sound.voice_muted and not sound.muted and sound.voice_count == before, "V disables only nonsense speech")
	scene._unhandled_input(mute_event)
	var original_stream: AudioStream = sound.music.stream
	scene.advance_round(20.0)
	check(not scene.round_active and scene.ritual_screen.visible and not sound.voice.playing, "expiry opens ritual and ends speech")
	before = sound.step_count
	scene.player.position = Vector2(600, 700)
	await walk(scene.player, Vector2.RIGHT, 30)
	check(sound.step_count > before, "movement under the ritual still makes footsteps")
	scene.set_ritual_visible(false)
	check(sound.music.playing == sound.output_enabled and sound.music.stream == original_stream, "Tab village return keeps the existing music stream")
	scene.start_next_round()
	check(sound.step_distance == 0.0 and not sound.footsteps.playing, "round entrance reset creates no phantom footsteps")
	check(sound.music.playing == sound.output_enabled and sound.music.stream == original_stream, "next round does not restart music")
	# Exercise the real opponent signal connection, including opening objections.
	scene.progression.coins = 10000
	for definition in scene.progression.catalog:
		scene.progression.try_purchase(str(definition.id), 0)
	scene.progression.encounter_stage = 1
	scene._reset_encounter()
	check(is_instance_valid(scene.encounter), "opponent audio fixture unlocks the actual encounter")
	if is_instance_valid(scene.encounter):
		scene.encounter.path.clear()
		scene.encounter.position = scene.encounter.CENTER
		scene.player.position = scene.encounter.CENTER + Vector2(70, 0)
		sound.voice_cooldown = 0.0
		before = sound.voice_count
		scene.advance_round(scene.progression.speech_interval())
		check(sound.voice_count == before + 1, "opponent phrases also produce speech during objections")
	if sound.output_enabled:
		sound.music.seek(71.8)
		await create_timer(0.6).timeout
		check(sound.music.playing and sound.music.get_playback_position() < 2.0, "real mixer wraps the score end back to its opening")
	scene.queue_free()
	await process_frame
	# Let the real audio mixer release its final playback references on exit.
	await create_timer(0.1).timeout
	print("AUDIO: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
