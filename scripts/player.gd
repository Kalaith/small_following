extends CharacterBody2D
## Directly controlled placeholder cultist. Round state never gates movement.
signal moved(distance: float, delta: float)

@export var movement_speed: float = 180.0
@export var world_bounds: Rect2 = Rect2(55.0, 55.0, 1450.0, 990.0)
@export var speaking_radius: float = 105.0
@export var show_aura: bool = true

var _trail_direction: Vector2 = Vector2.DOWN
var _trail_length: float = 8.0
var _flutter_amount: float = 0.0
var _cloth_time: float = 0.0
var _look_direction: Vector2 = Vector2.DOWN
var has_walk_target: bool = false
var walk_target: Vector2 = Vector2.ZERO
var _blocked_seconds: float = 0.0
const ARRIVAL_DISTANCE: float = 2.0
const BLOCKED_SECONDS: float = 0.2


func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	if not input_direction.is_zero_approx():
		clear_walk_target()
	elif has_walk_target:
		var remaining: Vector2 = walk_target - global_position
		if remaining.length() <= ARRIVAL_DISTANCE:
			clear_walk_target()
		else:
			# Shorten the final step instead of oscillating across the destination.
			input_direction = remaining / maxf(movement_speed * delta, remaining.length())
	var before: Vector2 = global_position
	step_motion(input_direction, delta)
	if has_walk_target:
		_blocked_seconds = _blocked_seconds + delta if before.distance_to(global_position) < 0.1 else 0.0
		if _blocked_seconds >= BLOCKED_SECONDS:
			clear_walk_target()


func set_walk_target(at: Vector2) -> void:
	# Tapping the cultist (hood or feet) is also an explicit stop action.
	if at.distance_to(global_position) <= 28.0 or at.distance_to(global_position + Vector2(0, -35)) <= 26.0:
		clear_walk_target()
		return
	walk_target = at.clamp(world_bounds.position, world_bounds.end)
	has_walk_target = true
	_blocked_seconds = 0.0
	queue_redraw()


func clear_walk_target() -> void:
	has_walk_target = false
	_blocked_seconds = 0.0
	queue_redraw()


## Shared motion entry point lets scene smoke tests drive the same movement path.
## Invoke on a physics frame: move_and_slide uses Godot's physics timestep.
func step_motion(direction: Vector2, delta: float) -> void:
	var previous_position: Vector2 = position
	var move_direction: Vector2 = direction.limit_length(1.0)
	velocity = move_direction * movement_speed
	move_and_slide()
	position.x = clampf(position.x, world_bounds.position.x, world_bounds.end.x)
	position.y = clampf(position.y, world_bounds.position.y, world_bounds.end.y)
	moved.emit(previous_position.distance_to(position), delta)

	var is_moving: bool = move_direction.length_squared() > 0.0001
	var cloth_blend: float = minf(maxf(delta, 0.0) * 10.0, 1.0)
	var target_trail: Vector2 = Vector2.DOWN
	if is_moving:
		_look_direction = move_direction.normalized()
		target_trail = -_look_direction
		_cloth_time += delta
	_trail_direction = _trail_direction.lerp(target_trail, cloth_blend)
	_trail_length = lerpf(_trail_length, 42.0 if is_moving else 8.0, cloth_blend)
	_flutter_amount = lerpf(_flutter_amount, 5.5 if is_moving else 0.0, cloth_blend)
	queue_redraw()


func _draw() -> void:
	if has_walk_target:
		var marker: Vector2 = to_local(walk_target)
		draw_arc(marker, 12.0, 0.0, TAU, 32, Color("ead4ff"), 2.0, true)
		draw_circle(marker, 3.0, Color("ead4ff"))
	if show_aura:
		draw_circle(Vector2.ZERO, speaking_radius, Color(0.76, 0.65, 0.95, 0.035))
		draw_arc(Vector2.ZERO, speaking_radius, 0.0, TAU, 72,
			Color(0.65, 0.51, 0.83, 0.20), 1.0, true)

	# Squashed circle forms a soft ground shadow; the character origin is its feet.
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 23.0, Color(0.17, 0.13, 0.21, 0.22))
	draw_set_transform(Vector2.ZERO)

	# Keep both ends perpendicular to the same axis: a fixed horizontal base
	# crossed the tip when turning and could make the polygon untriangulatable.
	var cloth_axis: Vector2 = _trail_direction.normalized()
	if cloth_axis.length_squared() < 0.001:
		cloth_axis = Vector2.DOWN
	var trail: Vector2 = cloth_axis * _trail_length
	var perpendicular: Vector2 = Vector2(-cloth_axis.y, cloth_axis.x)
	var wave: Vector2 = perpendicular * sin(_cloth_time * 15.0) * _flutter_amount
	var cloth_base: Vector2 = Vector2(0.0, -9.0)
	var cloth_tip: Vector2 = cloth_base + trail + wave
	draw_colored_polygon(PackedVector2Array([
		cloth_base - perpendicular * 10.0,
		cloth_tip - perpendicular * 8.0,
		cloth_tip + cloth_axis * 7.0,
		cloth_tip + perpendicular * 8.0,
		cloth_base + perpendicular * 10.0
	]), Color("6f4593"))
	draw_line(cloth_base, cloth_tip, Color("a57bbe"), 2.0, true)

	# Small boots, broad robe hem, and oversized hood keep the silhouette readable.
	draw_circle(Vector2(-7.0, -1.0), 5.0, Color("372b43"))
	draw_circle(Vector2(7.0, -1.0), 5.0, Color("372b43"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12.0, -38.0), Vector2(12.0, -38.0),
		Vector2(21.0, -5.0), Vector2(11.0, 0.0),
		Vector2(0.0, -3.0), Vector2(-11.0, 0.0), Vector2(-21.0, -5.0)
	]), Color("51365f"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10.0, -37.0), Vector2(10.0, -37.0),
		Vector2(17.0, -7.0), Vector2(8.0, -4.0),
		Vector2(0.0, -7.0), Vector2(-9.0, -4.0), Vector2(-17.0, -7.0)
	]), Color("9670ad"))
	draw_line(Vector2(-3.0, -28.0), Vector2(-7.0, -8.0), Color("b38dc6"), 2.0, true)
	draw_line(Vector2(7.0, -28.0), Vector2(11.0, -8.0), Color("79578e"), 2.0, true)
	draw_circle(Vector2(0.0, -43.0), 20.0, Color("51365f"))
	draw_circle(Vector2(-1.0, -45.0), 18.0, Color("9670ad"))
	draw_arc(Vector2(-1.0, -45.0), 15.0, PI * 1.10, PI * 1.80, 20,
		Color("b998cf"), 2.0, true)
	draw_circle(Vector2(0.0, -42.0), 12.0, Color("322c40"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, -42.0), Vector2(11.0, -42.0),
		Vector2(8.0, -31.0), Vector2(-8.0, -31.0)
	]), Color("322c40"))
	var eye_shift: Vector2 = _look_direction * 1.5
	draw_circle(Vector2(-4.5, -41.0) + eye_shift, 3.5, Color(0.99, 0.84, 0.52, 0.12))
	draw_circle(Vector2(4.5, -41.0) + eye_shift, 3.5, Color(0.99, 0.84, 0.52, 0.12))
	draw_circle(Vector2(-4.5, -41.0) + eye_shift, 1.8, Color("ffe4a1"))
	draw_circle(Vector2(4.5, -41.0) + eye_shift, 1.8, Color("ffe4a1"))
	draw_circle(Vector2(0.0, -27.0), 3.0, Color("e5c889"))
