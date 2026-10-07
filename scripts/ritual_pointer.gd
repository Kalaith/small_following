extends RefCounted
## Mouse and touch gestures on the ritual graph: select, pan, zoom and tap-versus-drag.
## Reads and moves the view through the screen's public pan/zoom methods.

const TOUCH_DRAG_THRESHOLD: float = 10.0
const TOUCH_TARGET_RADIUS: float = 28.0
const EMULATED_MOUSE_DEVICE: int = -1

var screen: Control
## Also gates keyboard/gamepad graph navigation; see RitualScreen.set_pointer_input_enabled.
var enabled: bool = true
var dragging: bool = false
var drag_button: int = 0
var touch_index: int = -1
var touch_start: Vector2 = Vector2.ZERO
var touch_last: Vector2 = Vector2.ZERO
var touch_dragged: bool = false


func _init(owner_screen: Control) -> void:
	screen = owner_screen


func handle_graph_input(event: InputEvent) -> void:
	if not enabled or screen.demo_message_visible():
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		handle_touch(event)
		screen.graph.accept_event()
		return
	# Godot also sends an emulated mouse event for a finger; the native touch
	# path waits for release so panning cannot accidentally select a node.
	if event.device == EMULATED_MOUSE_DEVICE:
		screen.graph.accept_event()
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		var screen_point: Vector2 = screen.graph.global_position + mouse.position
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			screen.zoom_at(screen_point, 1.13)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			screen.zoom_at(screen_point, 1.0 / 1.13)
		elif mouse.button_index == MOUSE_BUTTON_LEFT or mouse.button_index == MOUSE_BUTTON_MIDDLE:
			if not mouse.pressed:
				if mouse.button_index == drag_button:
					dragging = false
			else:
				var id: String = screen.hit_test(screen_point)
				if mouse.button_index == MOUSE_BUTTON_LEFT and screen.completion_hit_test(screen_point):
					screen.open_demo_message()
				elif mouse.button_index == MOUSE_BUTTON_LEFT and not id.is_empty():
					screen.select_node(id)
				else:
					dragging = true
					drag_button = mouse.button_index
		screen.graph.accept_event()
	elif event is InputEventMouseMotion:
		var mouse: InputEventMouseMotion = event
		if dragging:
			# Release outside the clipping rectangle cannot leave a stuck drag.
			var held: bool = (mouse.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE)) != 0
			if held:
				screen.pan_by(mouse.relative)
			else:
				dragging = false
		screen.hovered_id = screen.hit_test(screen.graph.global_position + mouse.position)
		screen.core_hovered = screen.completion_hit_test(screen.graph.global_position + mouse.position)
		screen.graph.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if screen.core_hovered or not screen.hovered_id.is_empty() else Control.CURSOR_DRAG
		screen.graph.queue_redraw()


func handle_input(event: InputEvent) -> void:
	# Capture native touches before their emulated mouse events, keeping the
	# same finger through release outside the graph's clipping rectangle.
	if not enabled or not screen.is_visible_in_tree() or screen.demo_message_visible():
		return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	if screen.branch_picker.get_popup().visible or screen.node_picker.get_popup().visible:
		return
	if touch_index < 0:
		if not event is InputEventScreenTouch or not event.pressed or event.canceled:
			return
		var local_event: InputEvent = screen.graph.make_input_local(event)
		if not Rect2(Vector2.ZERO, screen.graph.size).has_point(local_event.position):
			return
		handle_touch(local_event)
		screen.get_viewport().set_input_as_handled()
	elif event.index == touch_index:
		# Keep tracking outside the clip, including release over another control.
		handle_touch(screen.graph.make_input_local(event))
		screen.get_viewport().set_input_as_handled()


func reset_gesture() -> void:
	dragging = false
	drag_button = 0
	touch_index = -1
	touch_dragged = false


func handle_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and not touch.canceled:
			if touch_index >= 0:
				return
			touch_index = touch.index
			touch_start = touch.position
			touch_last = touch.position
			touch_dragged = false
			screen.hovered_id = ""
			screen.core_hovered = false
			screen.graph.queue_redraw()
		elif touch.index == touch_index:
			var tapped: bool = not touch.canceled and not touch_dragged and touch.position.distance_to(touch_start) < TOUCH_DRAG_THRESHOLD
			reset_gesture()
			if tapped:
				var screen_point: Vector2 = screen.graph.global_position + touch.position
				if screen.completion_hit_test(screen_point):
					screen.open_demo_message()
				else:
					screen.select_node(screen.hit_test(screen_point, TOUCH_TARGET_RADIUS))
	elif event is InputEventScreenDrag and event.index == touch_index:
		var drag: InputEventScreenDrag = event
		if not touch_dragged and drag.position.distance_to(touch_start) >= TOUCH_DRAG_THRESHOLD:
			touch_dragged = true
			screen.pan_by(drag.position - touch_start)
		elif touch_dragged:
			screen.pan_by(drag.position - touch_last)
		touch_last = drag.position
