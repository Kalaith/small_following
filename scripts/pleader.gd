extends Node2D
## A follower won at the abbey, on the road to the Pope. It walks the path it is
## given, then stands in its place before the throne and pleads. The person is a
## Listener dressed as the one they were; this only moves and times them.
const Listener = preload("res://scripts/listener.gd")

signal arrived

var plea: float = 0.0
var standing: bool = false
var _path: PackedVector2Array = []
var _speed: float = 190.0
var _person: Node2D


## Dress as the listener they were won from, and begin at their feet.
func begin(from: Node2D, route: PackedVector2Array, walk_speed: float, plea_rate: float) -> void:
	plea = plea_rate
	_speed = walk_speed
	_path = route
	global_position = from.global_position
	y_sort_enabled = true
	var person := Listener.new()
	person.role = from.role
	person.profile_type = from.profile_type
	person.coat = from.coat
	person.phase = from.phase
	person.following = true
	person.pleading = false
	add_child(person)
	_person = person
	if _path.is_empty():
		_arrive()


func _process(delta: float) -> void:
	if standing or _path.is_empty():
		return
	var remaining: float = _speed * delta
	while remaining > 0.0 and not _path.is_empty():
		var distance: float = global_position.distance_to(_path[0])
		var used: float = minf(remaining, distance)
		global_position = global_position.move_toward(_path[0], used)
		remaining -= used
		if global_position.distance_to(_path[0]) < 0.001:
			_path.remove_at(0)
	if _path.is_empty():
		_arrive()


func _arrive() -> void:
	standing = true
	_person.pleading = true
	_person.queue_redraw()
	arrived.emit()
