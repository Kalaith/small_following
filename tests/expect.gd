extends RefCounted
## Expected values for tests, derived from the shipped data files. Tests never
## restate balance numbers: they ask here, so a retune changes only data/.
## `state` is a loaded Progression; its catalog is data/upgrades.json.

const Balance = preload("res://scripts/balance.gd")


static func upgrade(state: RefCounted, id: String) -> Dictionary:
	for entry in state.all_catalog if not state.all_catalog.is_empty() else state.catalog:
		if entry.id == id:
			return entry
	assert(false, "No catalog entry " + id)
	return {}


## Base gold price of one rank (zero-based), before town resistance.
static func cost(state: RefCounted, id: String, rank_index: int = 0) -> int:
	var entry: Dictionary = upgrade(state, id)
	return int(entry.get("rank_costs", [entry.cost])[rank_index])


static func recruit_cost(state: RefCounted, id: String, rank_index: int = 0) -> int:
	var prices: Array = upgrade(state, id).get("rank_recruit_costs", [])
	return int(prices[rank_index]) if not prices.is_empty() else 0


## Gold for every rank of each listed node (all ranks unless `ranks` names fewer).
static func total_cost(state: RefCounted, ids: Array, ranks: Dictionary = {}) -> int:
	var total: int = 0
	for id in ids:
		for index in range(int(ranks.get(id, max_rank(state, id)))):
			total += cost(state, id, index)
	return total


static func total_recruit_cost(state: RefCounted, ids: Array, ranks: Dictionary = {}) -> int:
	var total: int = 0
	for id in ids:
		for index in range(int(ranks.get(id, max_rank(state, id)))):
			total += recruit_cost(state, id, index)
	return total


static func max_rank(state: RefCounted, id: String) -> int:
	return int(upgrade(state, id).get("max_rank", 1))


## One rank's value for an effect key (zero when that rank does not change it).
static func effect(state: RefCounted, id: String, key: String, rank_index: int = 0) -> float:
	var entry: Dictionary = upgrade(state, id)
	var rank_effect: Dictionary = entry.rank_effects[rank_index] if entry.has("rank_effects") else entry.effect
	return float(rank_effect.get(key, 0.0))


## Summed effect over ranks: `owned` maps id -> ranks owned (or lists ids at full rank).
static func sum_effect(state: RefCounted, owned: Variant, key: String) -> float:
	var total: float = 0.0
	var ranks: Dictionary = _ranks(state, owned)
	for id in ranks:
		for index in range(int(ranks[id])):
			total += effect(state, id, key, index)
	return total


static func speech_frequency(state: RefCounted, owned: Variant) -> float:
	return 1.0 + sum_effect(state, owned, "speech_speed_add")


static func conviction(state: RefCounted, owned: Variant) -> float:
	return 1.0 + sum_effect(state, owned, "conviction_add")


static func run_multiplier(state: RefCounted, owned: Variant) -> float:
	return 1.0 + sum_effect(state, owned, "run_speed_add")


static func resistance(stage: int) -> float:
	return 1.0 + Balance.number("village.resistance_price_step") * float(stage)


## A village rank's price after `stage` convinced opponents.
static func resisted_cost(state: RefCounted, id: String, rank_index: int, stage: int) -> int:
	return roundi(float(cost(state, id, rank_index)) * resistance(stage))


## Catalog ids for an area, in catalog order.
static func area_ids(state: RefCounted, area: String) -> Array[String]:
	var ids: Array[String] = []
	for entry in state.all_catalog if not state.all_catalog.is_empty() else state.catalog:
		if entry.get("area", "bramblewick") == area:
			ids.append(String(entry.id))
	return ids


static func area_ranks(state: RefCounted, area: String) -> int:
	var total: int = 0
	for id in area_ids(state, area):
		total += max_rank(state, id)
	return total


static func opponent(stage: int) -> Dictionary:
	return Balance.list("encounters.opponents")[stage]


static func _ranks(state: RefCounted, owned: Variant) -> Dictionary:
	if owned is Dictionary:
		return owned
	var result: Dictionary = {}
	for id in owned:
		result[id] = max_rank(state, String(id))
	return result
