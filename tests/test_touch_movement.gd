extends SceneTree
## Synthetic viewport input and physics coverage; does not certify browser/device touch.
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame


func touch(viewport: Viewport, at: Vector2, pressed: bool, index: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = viewport.get_final_transform() * at
	event.pressed = pressed
	event.index = index
	event.canceled = canceled
	viewport.push_input(event)


func tap(viewport: Viewport, at: Vector2) -> void:
	touch(viewport, at, true)
	touch(viewport, at, false)


func mouse(viewport: Viewport, at: Vector2, device: int = 0) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = viewport.get_final_transform() * at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.device = device
		viewport.push_input(event)


func world_point(scene, at: Vector2) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * at


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.game_audio.output_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	await frames(2)
	var player = scene.player
	var target := Vector2(660, 680)
	var point: Vector2 = world_point(scene, target)
	touch(root, point, true)
	check(not player.has_walk_target, "touch press waits for release")
	touch(root, point, false)
	check(player.has_walk_target and player.walk_target.distance_to(target) < 0.01, "released tap uses inverse camera transform")
	var before: Vector2 = player.position
	await frames(8)
	check(player.position.x < before.x - 10.0, "village tap moves the actual cultist")
	target = Vector2(900, 680)
	tap(root, world_point(scene, target))
	check(player.walk_target.distance_to(target) < 0.01, "repeated tap replaces the destination")
	tap(root, world_point(scene, player.position + Vector2(0, -35)))
	check(not player.has_walk_target, "tapping the cultist hood stops walking")
	point = world_point(scene, target)
	touch(root, point, true)
	touch(root, point, false, 0, true)
	check(not player.has_walk_target, "canceled touch does not walk")
	touch(root, point, true)
	var drag := InputEventScreenDrag.new()
	drag.position = point + Vector2(60, 0)
	drag.relative = Vector2(60, 0)
	root.push_input(drag)
	touch(root, point, false)
	check(not player.has_walk_target, "drag returning to its origin is not a tap")
	touch(root, point, true)
	touch(root, point + Vector2(50, 0), true, 1)
	touch(root, point + Vector2(50, 0), false, 1)
	touch(root, point, false)
	check(not player.has_walk_target, "multiple fingers cancel the pending walk tap")
	mouse(root, point, -1)
	check(not player.has_walk_target, "emulated mouse event does not duplicate touch movement")
	mouse(root, point)
	check(player.has_walk_target, "ordinary mouse click still chooses a destination")
	player.clear_walk_target()
	for control in [scene.settings_button, scene.stats_label, scene.context_label]:
		tap(root, control.get_global_rect().get_center())
		check(not player.has_walk_target, "UI touch cannot leak into walking: " + control.get_class())
	# Viewport.push_input does not emulate touch as mouse; supply the engine's
	# emulated device separately to check GUI dispatch without claiming browser input.
	mouse(root, scene.settings_button.get_global_rect().get_center(), -1)
	check(scene.settings_screen.visible and not player.has_walk_target, "emulated mouse opens Settings without walking")
	tap(root, point)
	check(not player.has_walk_target, "settings overlay blocks village taps")
	scene.set_settings_visible(false)
	touch(root, point, true)
	scene.set_settings_visible(true)
	scene.set_settings_visible(false)
	touch(root, point, false)
	check(not player.has_walk_target, "opening a menu cancels a pending village press")
	touch(root, point, true)
	touch(root, scene.settings_button.get_global_rect().get_center(), false)
	check(not player.has_walk_target, "release over a UI control cancels a village tap")
	scene.advance_round(20.0)
	tap(root, point)
	check(not player.has_walk_target, "ritual overlay blocks village taps")
	scene.set_ritual_visible(false)
	tap(root, world_point(scene, Vector2(680, 680)))
	before = player.position
	await frames(8)
	check(not scene.round_active and player.position.x < before.x - 10.0, "touch walking remains active between rounds")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await frames(3)
	check(not player.has_walk_target and player.velocity.x > 0.0, "keyboard steering cancels a touch destination")
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	player.position = Vector2(600, 680)
	player.set_walk_target(Vector2(640, 680))
	await frames(30)
	check(not player.has_walk_target and absf(player.position.x - 640.0) <= 2.0, "short destination settles without overshooting")
	before = player.position
	await frames(10)
	check(player.position.distance_to(before) < 0.01, "arrival stays still")
	player.position = Vector2(780, 480)
	player.set_walk_target(Vector2(780, 350))
	await frames(45)
	check(player.position.y > 430.0 and player.position.y < 470.0 and not player.has_walk_target, "well collision stops blocked tap movement")
	player.set_walk_target(Vector2(700, 600))
	scene.start_next_round()
	check(not player.has_walk_target and player.position == scene.START_POSITION, "next round resets the destination and entrance")
	player.set_walk_target(Vector2(660, 680))
	scene.village_input.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not player.has_walk_target, "focus loss clears tap walking")
	scene.queue_free()
	await process_frame
	await scaled_viewport()
	print("TOUCH MOVEMENT RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func scaled_viewport() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 400)
	viewport.size_2d_override = Vector2i(1280, 800)
	viewport.size_2d_override_stretch = true
	root.add_child(viewport)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.game_audio.output_enabled = false
	viewport.add_child(scene)
	scene.set_process(false)
	var camera: Camera2D = scene.player.get_node("Camera2D")
	camera.zoom = Vector2(0.85, 0.85)
	camera.reset_smoothing()
	await frames(3)
	var target := Vector2(920, 650)
	check(viewport.get_final_transform().get_scale().distance_to(Vector2(0.5, 0.5)) < 0.01, "scaled viewport exercises half-size input coordinates")
	tap(viewport, world_point(scene, target))
	check(scene.player.has_walk_target and scene.player.walk_target.distance_to(target) < 0.01, "tap remains accurate through viewport scale and camera zoom")
	viewport.queue_free()
	await process_frame
