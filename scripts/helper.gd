extends Node2D
## One visible, nonblocking recruiter. Main supplies only active-round time.
## A conservative grid uses the actual prop footprints, not decorative artwork.
const Balance = preload("res://scripts/balance.gd")
const CELL: float = 24.0
const BODY_RADIUS: float = 7.0
const START_OFFSET := Vector2(-24, 24)
const STAND_OFFSET := Vector2(0, 28)
const MAX_STEP: float = 1.0 / 60.0
## Floating-point slack when comparing accumulated per-frame time to a fixed interval.
const TIME_EPSILON: float = 0.000001

## Tuning and robe colours; the market hand swaps these via configure_market().
var walk_speed: float = Balance.number("helper.walk_speed")
var phrase_seconds: float = Balance.number("helper.phrase_seconds")
var conviction_per_phrase: float = Balance.number("helper.conviction_per_phrase")
var title: String = "Helper"
var robe := Color("528c83")
var hood := Color("69a699")
var sash := Color("dac5ee")
var start_offset := START_OFFSET
## Other helpers; a listener one of them is walking to is never chosen twice.
var rivals: Array[Node2D] = []
var target_group: Node2D = null
var target_index: int = -1
var phrase_elapsed: float = 0.0
var conviction: float = 0.0
var completed_recruits: int = 0
var active: bool = false
var speaking: bool = false
var path: PackedVector2Array = []
var _target_spot := Vector2.ZERO
## The listener node _target_spot belongs to; targets assigned elsewhere skip the check.
var _spot_listener: Node2D = null
var navigation := AStarGrid2D.new()
var _cloth_trail := Vector2.ZERO
# Bounds repeated full sweeps within one advance() call once a search finds
# no reachable eligible listener; advance() clears it for the next call.
var _search_exhausted: bool = false
## Counts full _choose_target sweeps; diagnostic and test-observable only.
var search_attempts: int = 0


## Bellmarket's second helper: an amber robe and a stronger pitch for the market's
## harder listeners (balance data "market.helper").
func configure_market() -> void:
	walk_speed = Balance.number("market.helper.walk_speed")
	phrase_seconds = Balance.number("market.helper.phrase_seconds")
	conviction_per_phrase = Balance.number("market.helper.conviction_per_phrase")
	title = "Market hand"
	robe = Color("b5793a")
	hood = Color("d49a4c")
	sash = Color("f3e2b0")
	start_offset = Vector2(24, 24)


func configure_navigation(actors: Node2D) -> void:
	navigation.region = Rect2i(2, 2, 61, 41)
	navigation.cell_size = Vector2(CELL, CELL)
	navigation.offset = Vector2(CELL * 0.5, CELL * 0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	# Obstacle shapes state their contract through the "helper_obstacle_shape"
	# group rather than a coincidental node name village.gd and market.gd must
	# both happen to use; the player's own shape is never in that group.
	var footprints: Array[Node] = []
	for shape_node in actors.find_children("*", "CollisionShape2D", true, false):
		if shape_node.is_in_group("helper_obstacle_shape"):
			footprints.append(shape_node)
	# Inflate by a cell half-diagonal as well as the helper radius, so edges
	# between free cell centers cannot cut across a thin prop footprint.
	var clearance: float = CELL * 0.707107 + BODY_RADIUS
	for y in range(navigation.region.position.y, navigation.region.end.y):
		for x in range(navigation.region.position.x, navigation.region.end.x):
			var cell := Vector2i(x, y)
			var at: Vector2 = navigation.get_point_position(cell)
			for footprint in footprints:
				var shape: Shape2D = footprint.shape
				var local: Vector2 = at - footprint.global_position
				var blocked: bool = false
				if shape is CircleShape2D:
					blocked = local.length() <= shape.radius + clearance
				elif shape is RectangleShape2D:
					blocked = Rect2(-shape.size * 0.5, shape.size).grow(clearance).has_point(local)
				if blocked:
					navigation.set_point_solid(cell)
					break


func reset_round(at: Vector2) -> void:
	position = at + start_offset
	completed_recruits = 0
	_cloth_trail = Vector2.ZERO
	_clear_target()
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	if not active:
		speaking = false
		_cloth_trail = Vector2.ZERO
	queue_redraw()


func advance(delta: float, groups: Array[Node2D]) -> void:
	if not active:
		return
	_search_exhausted = false
	search_attempts = 0
	# Bounded steps also handle a long render frame or the final clamped slice.
	var remaining: float = maxf(delta, 0.0)
	while remaining > TIME_EPSILON:
		var step: float = minf(remaining, MAX_STEP)
		_advance_step(step, groups)
		remaining -= step
	queue_redraw()


func _advance_step(delta: float, groups: Array[Node2D]) -> void:
	if not is_instance_valid(target_group) or target_index < 0 or not target_group.is_listener_eligible(target_index) or target_group.listeners[target_index].following or _target_moved():
		_clear_target()
		if not _search_exhausted:
			_choose_target(groups)
			_search_exhausted = target_index < 0
	if target_index < 0:
		_cloth_trail = _cloth_trail.move_toward(Vector2.ZERO, delta * 25.0)
		return
	var remaining: float = delta
	while not path.is_empty() and remaining > 0.0:
		var distance: float = global_position.distance_to(path[0])
		var movement: Vector2 = global_position.direction_to(path[0])
		var used: float = minf(remaining, distance / walk_speed)
		global_position = global_position.move_toward(path[0], walk_speed * used)
		_cloth_trail = _cloth_trail.lerp(-movement * 5.0, 0.2)
		remaining -= used
		if global_position.distance_to(path[0]) < 0.001:
			path.remove_at(0)
		else:
			break
	speaking = path.is_empty()
	if not speaking:
		return
	_cloth_trail = _cloth_trail.move_toward(Vector2.ZERO, remaining * 25.0)
	phrase_elapsed += remaining
	if phrase_elapsed + TIME_EPSILON >= phrase_seconds:
		phrase_elapsed = maxf(0.0, phrase_elapsed - phrase_seconds)
		conviction += conviction_per_phrase
		if conviction >= target_group.listener_conviction_required(target_index):
			if target_group.recruit_listener(target_index):
				completed_recruits += 1
			_clear_target()


## A beckoned wanderer that walked off the spot this helper pathed to needs a fresh path.
func _target_moved() -> bool:
	var listener: Node2D = target_group.listeners[target_index]
	return listener == _spot_listener and listener.global_position.distance_to(_target_spot) > CELL


func _cell(at: Vector2) -> Vector2i:
	return Vector2i((at / CELL).floor())


func _choose_target(groups: Array[Node2D]) -> void:
	search_attempts += 1
	var from: Vector2i = _cell(global_position)
	if not navigation.is_in_boundsv(from) or navigation.is_point_solid(from):
		return
	var best_distance: float = INF
	for group in groups:
		for index in range(group.listeners.size()):
			if group.listeners[index].following or not group.is_listener_eligible(index) or _claimed(group, index):
				continue
			var destination: Vector2 = group.listeners[index].global_position + STAND_OFFSET
			var to: Vector2i = _cell(destination)
			if not navigation.is_in_boundsv(to) or navigation.is_point_solid(to):
				continue
			var candidate: PackedVector2Array = navigation.get_point_path(from, to)
			if candidate.is_empty():
				continue
			var distance: float = global_position.distance_to(candidate[0])
			for point in range(1, candidate.size()):
				distance += candidate[point - 1].distance_to(candidate[point])
			if distance < best_distance:
				best_distance = distance
				target_group = group
				target_index = index
				_target_spot = group.listeners[index].global_position
				_spot_listener = group.listeners[index]
				path = candidate


func _claimed(group: Node2D, index: int) -> bool:
	for rival in rivals:
		if is_instance_valid(rival) and rival.target_group == group and rival.target_index == index:
			return true
	return false


func _clear_target() -> void:
	target_group = null
	target_index = -1
	_spot_listener = null
	phrase_elapsed = 0.0
	conviction = 0.0
	speaking = false
	path.clear()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 12, Color(0.22, 0.27, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO)
	# A small coloured hood and sash distinguish each helper from the cultist.
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -24), Vector2(7, -24), Vector2(12, -2) + _cloth_trail, Vector2(-12, -2) + _cloth_trail]), robe)
	draw_line(Vector2(-7, -21), Vector2(7, -5) + _cloth_trail, sash, 3)
	draw_circle(Vector2(0, -29), 11, hood)
	draw_circle(Vector2(0, -28), 7, Color("314c4e"))
	draw_circle(Vector2(-2, -28), 1, Color("fff1d0"))
	draw_circle(Vector2(3, -28), 1, Color("fff1d0"))
	var caption: String = title if active else title + " / resting"
	if speaking and is_instance_valid(target_group):
		var target: Vector2 = to_local(target_group.listeners[target_index].global_position)
		draw_arc(target, 14, 0, TAU, 24, Color("e5d3f5"), 1.5, true)
		caption = "%s / %d of %d" % [title, int(conviction), int(target_group.listener_conviction_required(target_index))]
		draw_line(Vector2(-13, 9), Vector2(13, 9), robe.darkened(0.25), 3)
		draw_line(Vector2(-13, 9), Vector2(-13 + 26 * phrase_elapsed / phrase_seconds, 9), sash, 3)
	var font := ThemeDB.fallback_font
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_rect(Rect2(-width * 0.5 - 5, -60, width + 10, 19), Color(0.16, 0.25, 0.22, 0.92))
	draw_string(font, Vector2(-width * 0.5, -46), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1d0"))
