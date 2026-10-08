extends RefCounted
## Lone villagers and market-goers, scattered afresh each round, and the
## Beckoning Call / Market Call pull that walks nearby ones toward the cultist. Each wanderer is an
## ordinary one-listener gathering, so speech, helpers and payouts are unchanged.
## Placement checks the drawn prop art, not only collision, so nobody spawns
## hidden behind a roof or canopy.

const Balance = preload("res://scripts/balance.gd")
const TITLE: String = "Wanderer"
## Feet positions stay inside the fences and the helper's navigation grid.
const AREA := Rect2(110, 170, 1340, 820)
## Listener body around its feet origin, grown by PROP_MARGIN against prop art.
const BODY := Rect2(-14, -42, 28, 46)
const PROP_MARGIN: float = 12.0
## Keeps wanderers visibly apart from a group's huddle; a player at a group's
## edge may also reach a nearby wanderer, which is fine.
const GATHERING_CLEARANCE: float = 190.0
const SPACING: float = 150.0
const MAX_ATTEMPTS: int = 600
## Pulled wanderers walk at "village.wanderers.pull_speed" and stop inside speaking range.
const PULL_STOP: float = 58.0
const BODY_RADIUS: float = 10.0


## Returns up to `count` feet positions; fewer only if the map is too crowded.
static func scatter(rng: RandomNumberGenerator, props: Array[Node], avoid: Array[Vector2], count: int) -> Array[Vector2]:
	var placed: Array[Vector2] = []
	var attempts: int = 0
	while placed.size() < count and attempts < MAX_ATTEMPTS:
		attempts += 1
		var at := Vector2(rng.randf_range(AREA.position.x, AREA.end.x), rng.randf_range(AREA.position.y, AREA.end.y))
		if is_clear(at, props, avoid, placed):
			placed.append(at)
	return placed


static func is_clear(at: Vector2, props: Array[Node], avoid: Array[Vector2], placed: Array[Vector2]) -> bool:
	for point in avoid:
		if at.distance_to(point) < GATHERING_CLEARANCE:
			return false
	for point in placed:
		if at.distance_to(point) < SPACING:
			return false
	var body := Rect2(at + BODY.position, BODY.size).grow(PROP_MARGIN)
	for prop in props:
		var art: Rect2 = prop.visual_rect()
		if Rect2(prop.global_position + art.position, art.size).intersects(body):
			return false
	return true


## Walks unconverted wanderers within `reach` toward `toward`, sliding along
## prop footprints instead of entering them. Converted wanderers, and market
## wanderers still awaiting an introduction, stay put.
static func pull(wanderers: Array[Node2D], toward: Vector2, reach: float, delta: float, footprints: Array[Node]) -> void:
	if reach <= 0.0 or delta <= 0.0:
		return
	for wanderer in wanderers:
		if wanderer.recruits > 0 or wanderer.first_unconverted() < 0:
			continue
		var from: Vector2 = wanderer.global_position
		var distance: float = from.distance_to(toward)
		if distance > reach or distance <= PULL_STOP:
			continue
		var step: Vector2 = from.direction_to(toward) * minf(Balance.number("village.wanderers.pull_speed") * delta, distance - PULL_STOP)
		for candidate in [step, Vector2(step.x, 0), Vector2(0, step.y)]:
			if not _blocked(from + candidate, footprints):
				wanderer.global_position = from + candidate
				break


static func _blocked(at: Vector2, footprints: Array[Node]) -> bool:
	if not AREA.grow(40.0).has_point(at):
		return true
	for footprint in footprints:
		var shape: Shape2D = footprint.shape
		var local: Vector2 = at - footprint.global_position
		if shape is CircleShape2D and local.length() <= shape.radius + BODY_RADIUS:
			return true
		if shape is RectangleShape2D and Rect2(-shape.size * 0.5, shape.size).grow(BODY_RADIUS).has_point(local):
			return true
	return false
