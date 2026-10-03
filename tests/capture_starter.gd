extends SceneTree
## Actual viewport captures of village, ritual and isolated scale fixture.
const Fixture = preload("res://tests/fixtures/ritual_fixture.gd")
var destination: String = "user://verification"
var failed: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func save_frame(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(destination.path_join(filename))
	if result != OK:
		failed = true
		push_error("Viewport save failed: " + filename + " " + error_string(result))


func _capture() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			destination = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(destination)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.position = Vector2(645, 562)
	scene.player.get_node("Camera2D").reset_smoothing()
	scene.advance_round(1.5)
	scene._update_hud()
	for i in range(8):
		await process_frame
	await save_frame("starter-runtime.png")
	Input.action_press("move_right")
	for i in range(14):
		await physics_frame
	Input.action_release("move_right")
	await save_frame("starter-moving.png")
	scene.player.position = scene.groups[0].position + Vector2(70, 0)
	scene.advance_round(100.0)
	scene._update_hud()
	scene.ritual_screen.reset_view()
	await save_frame("starter-summary.png")
	scene.ritual_screen.select_node("talk_1")
	scene.ritual_screen.purchase_button.pressed.emit()
	await save_frame("ritual-purchased.png")
	scene.ritual_screen.next_button.pressed.emit()
	await save_frame("starter-next-round.png")
	scene.advance_round(100.0)
	# Fund old first-rank progression only for the visual fixture, using normal purchase paths.
	scene.progression.coins = 200
	for item in scene.progression.catalog:
		if scene.progression.rank(item.id) == 0:
			scene.purchase_upgrade(item.id)
	scene.progression.coins = 54
	scene.ritual_screen.select_node("talk_3")
	await save_frame("ritual-rank-available.png")
	for id in ["talk_3", "persuade_3", "run_3"]:
		scene.ritual_screen.select_node(id)
		scene.ritual_screen.purchase_button.pressed.emit()
	scene.ritual_screen.select_node("talk_3")
	await save_frame("ritual-rank-max.png")
	await capture_full_clear(scene)
	scene.advance_round(100.0)
	var fake = load("res://scripts/progression.gd").new()
	fake.save_enabled = false
	fake.catalog = Fixture.build()
	fake.coins = 1000
	scene.ritual_screen.configure(fake.catalog, fake)
	scene.ritual_screen._title_label.text = "144-node validation fixture"
	scene.ritual_screen._subtitle_label.text = "TEST DATA ONLY / NOT PLAYABLE UPGRADE CONTENT"
	scene.ritual_screen.reset_view()
	await save_frame("ritual-144-fixture.png")
	scene.ritual_screen.focus_node("fixture_12_11")
	scene.ritual_screen._subtitle_label.text = "TEST DATA ONLY / NOT PLAYABLE UPGRADE CONTENT"
	await save_frame("ritual-fixture-focus.png")
	print("RENDER CAPTURE: " + destination)
	quit(1 if failed else 0)


func capture_full_clear(scene) -> void:
	# Same competent route model as pacing tests: small reactions, ordinary 95px stops.
	scene.progression.total_recruits = 0
	scene.start_next_round()
	scene.player.set_physics_process(false)
	var order: Array[int] = [2, 0, 1]
	var index: int = 0
	var pause_steps: int = 12
	var steps: int = 0
	while scene.round_active and scene.round_recruits < 15 and steps < 700:
		await physics_frame
		var target = scene.groups[order[index]]
		if target.recruits == 5 and index < 2:
			index += 1
			target = scene.groups[order[index]]
			pause_steps = 6
		var direction := Vector2.ZERO
		if pause_steps > 0:
			pause_steps -= 1
		elif scene.player.position.distance_to(target.position) > 95.0:
			direction = scene.player.position.direction_to(target.position)
		scene.player.step_motion(direction, 1.0 / 60.0)
		scene.advance_round(1.0 / 60.0)
		steps += 1
	scene._update_hud()
	print("FULL CLEAR CAPTURE: %d recruits in %.3fs, %.3fs remaining" % [scene.round_recruits, steps / 60.0, scene.seconds_left])
	if scene.round_recruits != 15:
		failed = true
		push_error("Full-rank capture route failed to clear all three groups.")
	await save_frame("village-full-clear.png")
