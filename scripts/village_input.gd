extends "res://addons/hatchery/input/pointer_tap.gd"
## Tap-to-walk on the village: only a press that began on unobscured village
## ground can become a walk tap. The gesture itself (slop, second fingers,
## drags, emulated mouse) is the shared toolkit's pointer tap.
var game: Node2D


func _ready() -> void:
	game = get_parent()
	available = func(at: Vector2) -> bool: return game.village_tap_available(at)
	tapped.connect(func(_screen: Vector2, world: Vector2) -> void: game.player.set_walk_target(world))


func _notification(what: int) -> void:
	super(what)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(game):
		game.player.clear_walk_target()


func cancel_gesture() -> void:
	cancel()


func _input(event: InputEvent) -> void:
	# A system-cancelled touch also abandons the walk it may have started.
	if event is InputEventScreenTouch and not event.pressed and event.canceled and is_instance_valid(game):
		game.player.clear_walk_target()
	super(event)
