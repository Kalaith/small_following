extends SceneTree
## Physical key events catch incorrect serialized codes that action_press misses.
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)


func key_event(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.game_audio.output_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	for phase in ["village", "ritual", "settings"]:
		if phase == "ritual":
			scene.advance_round(20.0)
		elif phase == "settings":
			scene.set_settings_visible(true)
		for pair in [[KEY_LEFT, Vector2.LEFT], [KEY_RIGHT, Vector2.RIGHT], [KEY_UP, Vector2.UP], [KEY_DOWN, Vector2.DOWN], [KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
			scene.player.position = scene.START_POSITION
			key_event(pair[0], true)
			for frame in range(5):
				await physics_frame
			var travel: Vector2 = scene.player.position - scene.START_POSITION
			check(travel.dot(pair[1]) > 0.0 and absf(travel.cross(pair[1])) < 0.01, "%s moves correctly in %s" % [OS.get_keycode_string(pair[0]), phase])
			key_event(pair[0], false)
			await physics_frame
	key_event(KEY_END, true)
	check(Input.get_vector("move_left", "move_right", "move_up", "move_down") == Vector2.ZERO, "End is not movement")
	key_event(KEY_END, false)
	scene.queue_free()
	await process_frame
	print("KEY MAPPING RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
