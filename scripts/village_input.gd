extends Node
## Only a press that began on unobscured village ground can become a walk tap.
## GUI controls keep Godot's touch-to-mouse emulation; custom movement ignores it.
const TAP_SLOP: float = 24.0
## _pointer identifies the one gesture currently tracked: a real touch index
## (>= 0), the mouse (MOUSE_POINTER), or no active press (NO_POINTER).
const MOUSE_POINTER: int = -1
const NO_POINTER: int = -2
var game: Node2D
var _touches: Dictionary = {}
var _pointer: int = NO_POINTER
var _pressed_at: Vector2
var _world_at: Vector2


func _ready() -> void:
	game = get_parent()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(game):
		cancel_gesture()
		_touches.clear()
		game.player.clear_walk_target()


func cancel_gesture() -> void:
	_pointer = NO_POINTER


func _input(event: InputEvent) -> void:
	# Observe releases before GUI dispatch, including releases over a menu/HUD.
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = true
			if _touches.size() > 1:
				cancel_gesture()
		else:
			_touches.erase(event.index)
			if event.canceled:
				cancel_gesture()
				game.player.clear_walk_target()
			elif _pointer == event.index:
				_finish_tap(event.position)
	elif event is InputEventScreenDrag and event.index == _pointer:
		if event.position.distance_to(_pressed_at) > TAP_SLOP:
			cancel_gesture()
	elif event is InputEventMouseButton and event.device != -1:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _pointer == MOUSE_POINTER:
			_finish_tap(event.position)
	elif event is InputEventMouseMotion and event.device != -1 and _pointer == MOUSE_POINTER:
		if event.position.distance_to(_pressed_at) > TAP_SLOP:
			cancel_gesture()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and _touches.size() == 1:
		_begin_tap(event.index, event.position)
	elif event is InputEventMouseButton and event.device != -1:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_begin_tap(MOUSE_POINTER, event.position)


func _begin_tap(pointer: int, at: Vector2) -> void:
	if not game.village_tap_available(at):
		return
	_pointer = pointer
	_pressed_at = at
	# Input positions already use viewport coordinates. Invert the current camera
	# canvas transform once at press time so camera smoothing cannot move the goal.
	_world_at = game.get_viewport().get_canvas_transform().affine_inverse() * at


func _finish_tap(at: Vector2) -> void:
	if at.distance_to(_pressed_at) <= TAP_SLOP and game.village_tap_available(at):
		game.player.set_walk_target(_world_at)
	cancel_gesture()
