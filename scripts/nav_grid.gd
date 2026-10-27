extends RefCounted
## The walking grid helpers and procession pleaders share: the map's cells with
## every prop footprint blocked. Obstacle shapes state their contract through the
## "helper_obstacle_shape" group; the player's own shape is never in it.
const CELL: float = 24.0
const BODY_RADIUS: float = 7.0


## The grid keeps at least two cells clear of every edge of the map.
static func build(actors: Node2D, world_size: Vector2) -> AStarGrid2D:
	var navigation := AStarGrid2D.new()
	navigation.region = Rect2i(Vector2i(2, 2), Vector2i((world_size / CELL).floor()) - Vector2i(4, 4))
	navigation.cell_size = Vector2(CELL, CELL)
	navigation.offset = Vector2(CELL * 0.5, CELL * 0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	var footprints: Array[Node] = []
	for shape_node in actors.find_children("*", "CollisionShape2D", true, false):
		if shape_node.is_in_group("helper_obstacle_shape"):
			footprints.append(shape_node)
	# Inflate by a cell half-diagonal as well as the walker's radius, so edges
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
	return navigation


static func cell_of(at: Vector2) -> Vector2i:
	return Vector2i((at / CELL).floor())
