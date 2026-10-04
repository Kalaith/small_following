extends SceneTree
## Native viewport touch events; isolated ranks, no browser/device claim.
const Fixture = preload("res://tests/fixtures/ritual_fixture.gd")
const Progression = preload("res://scripts/progression.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("RITUAL TOUCH: " + description)


func touch(point: Vector2, pressed: bool, index: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	event.index = index
	event.canceled = canceled
	root.push_input(event, true)


func drag(point: Vector2, relative: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point
	event.relative = relative
	event.index = index
	root.push_input(event, true)


func tap(point: Vector2) -> void:
	touch(point, true)
	touch(point, false)


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.advance_round(100.0)
	await process_frame
	var screen = scene.ritual_screen
	screen.focus_node("run_4")
	screen.zoom_at(screen.graph.get_global_rect().get_center(), 1.5)
	screen.pan_by(Vector2(31, -27))
	var point: Vector2 = screen.world_to_screen(screen.node_positions["run_4"])
	screen.clear_selection()
	touch(point, true)
	check(screen.selected_id.is_empty(), "press waits for release before selecting")
	touch(point + Vector2(2, 3), false)
	check(screen.selected_id == "run_4", "viewport release selects after pan and zoom")
	check(screen._hovered_id.is_empty(), "touch details do not depend on hover")
	screen.clear_selection()
	var initial_pan: Vector2 = screen.pan
	touch(point, true)
	drag(point + Vector2(5, 2), Vector2(5, 2))
	check(screen.pan == initial_pan, "small finger jitter does not pan")
	drag(point + Vector2(70, 40), Vector2(65, 38))
	check(screen.pan.is_equal_approx(initial_pan + Vector2(70, 40)), "one finger pans by accumulated displacement")
	touch(point + Vector2(70, 40), false)
	check(screen.selected_id.is_empty(), "drag beginning on a node does not select on release")
	touch(point, true)
	touch(point + Vector2(20, 0), true, 1)
	initial_pan = screen.pan
	drag(point + Vector2(70, 0), Vector2(50, 0), 1)
	check(screen.pan == initial_pan and screen._touch_index == 0, "second finger cannot steal the gesture")
	touch(point + Vector2(70, 0), false, 1)
	touch(point, false, 0, true)
	check(screen._touch_index == -1 and screen.selected_id.is_empty(), "cancel neither selects nor leaves capture")
	touch(point, true)
	touch(screen.purchase_button.get_global_rect().get_center(), false)
	check(screen._touch_index == -1 and screen.selected_id.is_empty(), "release over details ends the graph gesture")
	touch(point, true)
	screen.hide()
	screen.show()
	check(screen._touch_index == -1, "closing the ritual resets the captured finger")
	screen.set_pointer_input_enabled(false)
	tap(point)
	check(screen._touch_index == -1 and screen.selected_id.is_empty(), "settings overlay can block graph input")
	screen.set_pointer_input_enabled(true)
	screen.focus_node("talk_1")
	point = screen.world_to_screen(screen.node_positions["talk_1"])
	screen.clear_selection()
	tap(point)
	tap(point)
	check(screen.selected_id == "talk_1", "repeated taps continue selecting")
	screen.clear_selection()
	var mouse := InputEventMouseButton.new()
	mouse.position = point - screen.graph.global_position
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.device = -1
	screen.graph._gui_input(mouse)
	check(screen.selected_id.is_empty(), "emulated mouse cannot bypass touch release selection")
	mouse.device = 0
	screen.graph._gui_input(mouse)
	check(screen.selected_id == "talk_1", "ordinary mouse selection remains available")
	var zoom_before: float = screen.zoom
	screen.zoom_in_button.pressed.emit()
	check(screen.zoom > zoom_before, "visible plus button zooms")
	screen.zoom_out_button.pressed.emit()
	check(is_equal_approx(screen.zoom, zoom_before), "visible minus button reverses zoom")
	for control in [screen.zoom_in_button, screen.zoom_out_button, screen.branch_picker, screen.node_picker, screen.completion_button]:
		check(control.size.y >= 56, "graph navigation has a larger logical finger target")
	for item in scene.progression.catalog:
		scene.progression.purchased[item.id] = scene.progression.max_rank(item.id)
	screen.update_state()
	screen.reset_view()
	point = screen.world_to_screen(Vector2.ZERO)
	touch(point, true)
	check(not screen.demo_message_visible(), "centre also waits for release")
	touch(point, false)
	check(screen.demo_message_visible(), "touching completed centre opens the demo")
	screen.demo_continue_button.pressed.emit()
	check(not screen.demo_message_visible(), "keep-playing button dismisses the demo")
	var fixture_state = Progression.new()
	fixture_state.catalog.assign(Fixture.build())
	fixture_state.save_enabled = false
	screen.configure(fixture_state.catalog, fixture_state)
	var distant: String = str(fixture_state.catalog[-1].id)
	screen.focus_node(distant)
	point = screen.world_to_screen(screen.node_positions[distant])
	screen.clear_selection()
	tap(point)
	check(screen.node_positions.size() == 144 and screen.selected_id == distant, "touch selects a focused node in the separate large fixture")
	scene.queue_free()
	await process_frame
	print("RITUAL TOUCH RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
