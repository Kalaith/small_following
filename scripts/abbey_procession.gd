extends Node2D
## The abbey's procession. Whoever is won here, by the cultist or a helper,
## leaves their place and walks up the pilgrim way to stand before the Pope and
## plead; each one standing pleads every second at a strength set by their
## standing in the abbey. Everything resets each round. The procession lives on
## the abbey's floor; the pleaders themselves are Y-sorted actors.

const Balance = preload("res://addons/hatchery/core/balance.gd")
const Abbey = preload("res://scripts/abbey.gd")
const AbbeyRules = preload("res://scripts/abbey_rules.gd")
const NavGrid = preload("res://scripts/nav_grid.gd")
const Pleader = preload("res://scripts/pleader.gd")
## A cell no route can start or end on.
const NO_CELL := Vector2i(-9999, -9999)
const SEARCH_CELLS: int = 5

var progression: RefCounted = null
var pleaders: Array[Node2D] = []
## Advocates the Pope needs standing before he hears the cultist.
var needed: int = 1
var _actors: Node2D = null
var _navigation: AStarGrid2D = null
var _slots: Array[Vector2] = []
var _plea_multiplier: float = 1.0
var _walk_multiplier: float = 1.0


func bind(owner_progression: RefCounted, actors: Node2D, world_size: Vector2) -> void:
	progression = owner_progression
	_actors = actors
	_navigation = NavGrid.build(actors, world_size)
	_slots = Abbey.plea_slots()
	refresh()
	reset_round()


## Reads the abbey circle once; upgrades only change between rounds.
func refresh() -> void:
	_plea_multiplier = AbbeyRules.plea_multiplier(progression)
	_walk_multiplier = AbbeyRules.plea_walk_multiplier(progression)
	needed = AbbeyRules.pleaders_needed(progression)


func reset_round() -> void:
	for pleader in pleaders:
		if is_instance_valid(pleader):
			pleader.get_parent().remove_child(pleader)
			pleader.queue_free()
	pleaders.clear()


## The gathering reports every conversion: the person leaves for the throne.
func on_converted(group: Node2D, index: int) -> void:
	if pleaders.size() >= _slots.size():
		return
	var person: Node2D = group.listeners[index]
	var role: String = String(group.listener_profiles[index].npc_type)
	var plea: float = float(Balance.dict("abbey.roles")[role].plea) * _plea_multiplier
	var slot: Vector2 = _slots[pleaders.size()]
	var pleader := Pleader.new()
	_actors.add_child(pleader)
	pleader.name = "Pleader_%d" % pleaders.size()
	pleader.begin(person, _route(person.global_position, slot), Balance.number("abbey.procession.walk_speed") * _walk_multiplier, plea)
	person.departed = true
	person.queue_redraw()
	pleaders.append(pleader)


## How many have reached their place before the throne.
func standing_count() -> int:
	var count: int = 0
	for pleader in pleaders:
		if pleader.standing:
			count += 1
	return count


## Conviction per second all who stand before the Pope are pleading.
func plea_rate() -> float:
	var total: float = 0.0
	for pleader in pleaders:
		if pleader.standing:
			total += pleader.plea
	return total


func _route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start: Vector2i = _free_cell_near(NavGrid.cell_of(from))
	var goal: Vector2i = _free_cell_near(NavGrid.cell_of(to))
	var route := PackedVector2Array()
	if start != NO_CELL and goal != NO_CELL:
		route = _navigation.get_point_path(start, goal)
	route.append(to)
	return route


func _free_cell_near(cell: Vector2i) -> Vector2i:
	for radius in range(SEARCH_CELLS + 1):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var candidate := cell + Vector2i(dx, dy)
				if _navigation.is_in_boundsv(candidate) and not _navigation.is_point_solid(candidate):
					return candidate
	return NO_CELL
