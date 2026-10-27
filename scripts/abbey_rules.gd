extends RefCounted
## The abbey's reading of progression: the Fellowship the Pope asks for and the
## numbers the abbey circle changes. Static, so progression and this never hold
## each other. Callers cache the numbers per round rather than asking per frame.
const Balance = preload("res://addons/hatchery/core/balance.gd")
const AREA_ID: String = "abbey"


## Every inscription that raises a follower: whole branches plus named nodes.
static func follower_ids(p: RefCounted) -> Array[String]:
	var fellowship: Dictionary = Balance.dict("abbey.fellowship")
	var ids: Array[String] = []
	for entry in p.all_catalog:
		if str(entry.branch) in fellowship.branches or str(entry.id) in fellowship.ids:
			ids.append(str(entry.id))
	return ids


## Follower inscriptions at full rank, and how many exist.
static func fellowship(p: RefCounted) -> Vector2i:
	var ids: Array[String] = follower_ids(p)
	var mastered: int = 0
	for id in ids:
		if p.rank(id) >= p.max_rank(id):
			mastered += 1
	return Vector2i(mastered, ids.size())


static func fellowship_complete(p: RefCounted) -> bool:
	var counts: Vector2i = fellowship(p)
	return counts.y > 0 and counts.x == counts.y


## The Pope takes his seat for a pilgrim the King approved who brings every follower.
static func pope_present(p: RefCounted) -> bool:
	return p.abbey_pope_won or (p.rose_king_won and fellowship_complete(p))


## Why the throne is empty, for the HUD; empty when he is seated.
static func throne_reason(p: RefCounted) -> String:
	if pope_present(p):
		return ""
	if not p.rose_king_won:
		return "The throne is empty: the Pope receives only a pilgrim with the King's approval"
	var counts: Vector2i = fellowship(p)
	return "The throne is empty: the Pope will not see a pilgrim who walks alone (%d/%d follower inscriptions mastered)" % [counts.x, counts.y]


## How much harder each follower pleads: 1.0 plus Voices at His Feet.
static func plea_multiplier(p: RefCounted) -> float:
	return 1.0 + p.effect_total("abbey_plea_add")


static func plea_walk_multiplier(p: RefCounted) -> float:
	return 1.0 + p.effect_total("abbey_plea_walk_add")


## Advocates the Pope needs before he hears the cultist: the base less Open Doors.
static func pleaders_needed(p: RefCounted) -> int:
	return maxi(1, Balance.integer("abbey.pope.open_pleaders") - int(p.effect_total("abbey_heed_add")))


static func helper_power(p: RefCounted) -> float:
	return 1.0 + p.effect_total("abbey_helper_power_add")


static func helper_speed(p: RefCounted) -> float:
	return 1.0 + p.effect_total("abbey_helper_speed_add")


static func helper_walk(p: RefCounted) -> float:
	return 1.0 + p.effect_total("abbey_helper_walk_add")
