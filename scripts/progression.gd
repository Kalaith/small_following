extends RefCounted
## Single owner for upgrade purchases and durable earnings. Definitions contain no code.
## Saves only progression: rounds always start fresh after relaunch; no offline accrual.

const SAVE_VERSION: int = 4
const MAX_COUNTER: int = 1000000000
const AREA_IDS: Array[String] = ["bramblewick", "bellmarket"]
## Village nodes added after Bellmarket shipped. Saves validate earned market
## access without them, so a player already there is not rejected; ordinary
## travel still requires the whole current circle.
const POST_MARKET_VILLAGE_IDS: Array[String] = ["beckon_1"]
## One beckon point draws wanderers from this many world pixels away.
const BECKON_PIXELS_PER_POINT: float = 100.0
const EFFECT_KEYS: Array[String] = ["beckon_add", "encounter_conviction_add", "skeptic_conviction_add", "guard_conviction_add", "zealot_conviction_add", "priest_conviction_add", "merchant_conviction_add", "merchant_donation_add", "speech_speed_add", "conviction_add", "run_speed_add", "meadow_unlock", "east_unlock", "helper_unlock", "merchant_unlock", "encounter_unlock", "market_guild_unlock", "market_patron_unlock", "market_guild_donation_add", "market_patron_donation_add"]
const UNLOCK_KEYS: Array[String] = ["meadow_unlock", "east_unlock", "helper_unlock", "merchant_unlock", "encounter_unlock", "market_guild_unlock", "market_patron_unlock"]

const BASE_MERCHANT_DONATION: int = 12
const ENCOUNTER_REWARDS: Array[int] = [30, 45, 60, 120]

var encounter_stage: int = 0
var coins: int = 0
# Recruitment events are lifetime history; assigning supporters spends only availability.
var total_recruits: int = 0
var available_recruits: int = 0
var round_number: int = 1
var purchased: Dictionary = {}
# The active circle is exposed to the graph; every rank is validated against all areas.
var catalog: Array[Dictionary] = []
var all_catalog: Array[Dictionary] = []
var active_area: String = "bramblewick"
# Title-screen access is independent of earned ranks and completion.
var level_select_unlocked: bool = false
var save_path: String = "user://progression.json"
var last_error: String = ""
var save_enabled: bool = true
var _write_blocked: bool = false
var _archive_corrupt_on_save: bool = false


func load_catalog(path: String = "res://data/upgrades.json") -> bool:
	last_error = ""
	var raw: Variant = _parse_json(FileAccess.get_file_as_string(path))
	if not raw is Dictionary or raw.get("schema_version") != 1 or not raw.get("upgrades") is Array:
		return _fail("Upgrade catalog is missing or has an unsupported format.")
	var candidate: Array[Dictionary] = []
	var ids: Dictionary = {}
	for entry in raw.upgrades:
		if not entry is Dictionary:
			return _fail("Upgrade entry must be an object.")
		for key in ["id", "title", "description", "branch"]:
			if not entry.get(key) is String or entry[key].strip_edges().is_empty():
				return _fail("Upgrade entry needs a nonempty " + key + ".")
		if ids.has(entry.id):
			return _fail("Duplicate upgrade ID: " + entry.id)
		var area: Variant = entry.get("area", "bramblewick")
		if not area is String or not area in AREA_IDS:
			return _fail("Unknown upgrade area: " + entry.id)
		if not _integer_between(entry.get("ring"), 1, 10000) or not _finite_number(entry.get("angle_degrees")):
			return _fail("Invalid ritual coordinate: " + entry.id)
		if not _integer_between(entry.get("cost"), 1, MAX_COUNTER):
			return _fail("Invalid upgrade cost: " + entry.id)
		var rank_limit: Variant = entry.get("max_rank", 1)
		if not _integer_between(rank_limit, 1, 100):
			return _fail("Invalid upgrade rank limit: " + entry.id)
		var prices: Variant = entry.get("rank_costs", [entry.cost])
		if not prices is Array or prices.size() != int(rank_limit):
			return _fail("Upgrade needs one price per rank: " + entry.id)
		for price in prices:
			if not _integer_between(price, 1, MAX_COUNTER):
				return _fail("Invalid upgrade rank price: " + entry.id)
		if int(prices[0]) != int(entry.cost):
			return _fail("First rank price must match cost: " + entry.id)
		var recruit_prices: Variant = entry.get("rank_recruit_costs", [])
		if not recruit_prices is Array:
			return _fail("Recruit prices must be an array: " + entry.id)
		if not entry.has("rank_recruit_costs"):
			for index in range(int(rank_limit)):
				recruit_prices.append(0)
		if recruit_prices.size() != int(rank_limit):
			return _fail("Upgrade needs one recruit price per rank: " + entry.id)
		for price in recruit_prices:
			if not _integer_between(price, 0, MAX_COUNTER):
				return _fail("Invalid upgrade recruit price: " + entry.id)
		if entry.has("support_description") and not entry.support_description is String:
			return _fail("Support description must be text: " + entry.id)
		if not entry.get("requires") is Array or not entry.get("effect") is Dictionary or entry.effect.is_empty():
			return _fail("Invalid prerequisites/effects: " + entry.id)
		for effect in entry.effect:
			if not effect in EFFECT_KEYS or not _finite_number(entry.effect[effect]) or entry.effect[effect] <= 0.0 or entry.effect[effect] > 100.0:
				return _fail("Unsupported effect: " + entry.id)
		var effects: Variant = entry.get("rank_effects", [])
		if not effects is Array:
			return _fail("Rank effects must be an array: " + entry.id)
		if not entry.has("rank_effects"):
			for index in range(int(rank_limit)):
				effects.append(entry.effect.duplicate(true))
		if effects.size() != int(rank_limit):
			return _fail("Upgrade needs one effect per rank: " + entry.id)
		for rank_effect in effects:
			if not rank_effect is Dictionary or rank_effect.is_empty():
				return _fail("Rank effect must be a nonempty object: " + entry.id)
			for effect in rank_effect:
				if not effect in EFFECT_KEYS or not _finite_number(rank_effect[effect]) or rank_effect[effect] <= 0.0 or rank_effect[effect] > 100.0:
					return _fail("Unsupported rank effect: " + entry.id)
		if effects[0] != entry.effect:
			return _fail("First rank effect must match effect: " + entry.id)
		var movement_upgrade: bool = entry.branch == "run"
		for rank_effect in effects:
			movement_upgrade = movement_upgrade or rank_effect.has("run_speed_add")
		if movement_upgrade:
			for price in recruit_prices:
				if price != 0:
					return _fail("Running upgrades must remain gold-only: " + entry.id)
		var normalized: Dictionary = entry.duplicate(true)
		normalized.area = area
		normalized.max_rank = int(rank_limit)
		normalized.rank_costs = prices.duplicate()
		normalized.rank_recruit_costs = recruit_prices.duplicate()
		normalized.rank_effects = effects.duplicate(true)
		ids[entry.id] = normalized
		candidate.append(normalized)
	var unlocks: Dictionary = {}
	for entry in candidate:
		for rank_effect in entry.rank_effects:
			for effect in rank_effect:
				if effect in ["merchant_donation_add", "market_guild_donation_add", "market_patron_donation_add"] and not _integer_between(rank_effect[effect], 1, 100):
					return _fail("Donation bonuses must be whole numbers: " + entry.id)
				if effect.begins_with("market_") and entry.area != "bellmarket":
					return _fail("Market effects belong to Bellmarket: " + entry.id)
				if effect in UNLOCK_KEYS:
					if entry.max_rank != 1 or rank_effect[effect] != 1 or unlocks.has(effect):
						return _fail("Unlocks must appear once, at one rank and value 1: " + entry.id)
					unlocks[effect] = true
		var seen: Dictionary = {}
		for requirement in entry.requires:
			if not requirement is String or not ids.has(requirement) or requirement == entry.id or seen.has(requirement):
				return _fail("Invalid prerequisite: " + entry.id)
			if ids[requirement].area != entry.area:
				return _fail("Circle prerequisites must stay within their area: " + entry.id)
			seen[requirement] = true
	# Iterative topological validation avoids recursion limits for future large catalogs.
	var resolved: Dictionary = {}
	while resolved.size() < candidate.size():
		var previous_size: int = resolved.size()
		for entry in candidate:
			if resolved.has(entry.id):
				continue
			var ready: bool = true
			for requirement in entry.requires:
				if not resolved.has(requirement):
					ready = false
			if ready:
				resolved[entry.id] = true
		if resolved.size() == previous_size:
			return _fail("Upgrade prerequisite cycle detected.")
	all_catalog = candidate
	catalog = catalog_for_area(active_area)
	return true


func catalog_for_area(area_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		if entry.get("area", "bramblewick") == area_id:
			result.append(entry)
	return result


## The town-debate encounters require their one unlocking upgrade, whichever
## stable ID currently carries the encounter_unlock effect in the catalog.
func _encounter_unlock_id() -> String:
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		if entry.get("effect", {}).has("encounter_unlock"):
			return str(entry.id)
	return ""


func find_upgrade(id: String) -> Dictionary:
	for entry in catalog:
		if entry.id == id:
			return entry
	for entry in all_catalog:
		if entry.id == id:
			return entry
	return {}


func rank(id: String) -> int:
	return int(purchased.get(id, 0))


func max_rank(id: String) -> int:
	return _definition_max_rank(find_upgrade(id))


func next_cost(id: String) -> int:
	return _definition_next_cost(find_upgrade(id), id)


func next_recruit_cost(id: String) -> int:
	return _definition_next_recruit_cost(find_upgrade(id), id)


## The definition-taking forms let one caller resolve an upgrade once. Views ask
## for every node's state on each refresh, so repeating the catalog lookup five
## times per question made the cost of a refresh grow with the catalog squared.
func _definition_max_rank(upgrade: Dictionary) -> int:
	return int(upgrade.get("max_rank", 1)) if not upgrade.is_empty() else 0


func _definition_next_cost(upgrade: Dictionary, id: String) -> int:
	if upgrade.is_empty() or rank(id) >= _definition_max_rank(upgrade):
		return 0
	var prices: Array = upgrade.get("rank_costs", [upgrade.cost])
	return int(prices[rank(id)])


func _definition_next_recruit_cost(upgrade: Dictionary, id: String) -> int:
	if upgrade.is_empty() or rank(id) >= _definition_max_rank(upgrade):
		return 0
	var prices: Array = upgrade.get("rank_recruit_costs", [])
	return int(prices[rank(id)]) if not prices.is_empty() else 0


## The single implementation of the purchase rules. Keep every gate here so the
## graph's status query and the player-facing panel can never disagree.
func _definition_status(upgrade: Dictionary, id: String) -> String:
	if upgrade.is_empty():
		return "unknown"
	if upgrade.get("area", "bramblewick") != active_area:
		return "locked"
	if rank(id) >= _definition_max_rank(upgrade):
		return "purchased"
	for requirement in upgrade.requires:
		if rank(requirement) < 1:
			return "locked"
	if _definition_next_cost(upgrade, id) > coins or _definition_next_recruit_cost(upgrade, id) > available_recruits:
		return "unaffordable"
	return "affordable"


## Explains the rules above for the selected inscription only. Views that ask
## about every node call `status` instead and skip this message building.
func purchase_state(id: String) -> Dictionary:
	var upgrade: Dictionary = find_upgrade(id)
	var state: Dictionary = {
		"status": _definition_status(upgrade, id), "message": "Unknown inscription.",
		"missing_gold": 0, "missing_recruits": 0,
		"gold_cost": 0, "recruit_cost": 0,
	}
	if state.status == "unknown":
		return state
	if state.status == "locked" and upgrade.get("area", "bramblewick") != active_area:
		state.message = "Travel to this inscription's area before purchasing it."
		return state
	if state.status == "purchased":
		state.message = "This inscription is already at maximum rank."
		return state
	state.gold_cost = _definition_next_cost(upgrade, id)
	state.recruit_cost = _definition_next_recruit_cost(upgrade, id)
	if state.status == "locked":
		state.message = "This inscription is sealed."
		for requirement in upgrade.requires:
			if rank(requirement) < 1:
				state.message = "Requires " + str(find_upgrade(requirement).get("title", requirement)) + "."
				break
		return state
	state.missing_gold = maxi(0, int(state.gold_cost) - coins)
	state.missing_recruits = maxi(0, int(state.recruit_cost) - available_recruits)
	var missing: Array[String] = []
	if state.missing_gold > 0:
		missing.append("%d more donations" % state.missing_gold)
	if state.missing_recruits > 0:
		missing.append("%d more recruit%s" % [state.missing_recruits, "" if state.missing_recruits == 1 else "s"])
	state.message = "Ready to inscribe rank %d." % (rank(id) + 1) if missing.is_empty() else "Need %s for rank %d." % [" and ".join(missing), rank(id) + 1]
	return state


func status(id: String) -> String:
	return _definition_status(find_upgrade(id), id)


func try_purchase(id: String, expected_rank: int = -1) -> bool:
	last_error = ""
	# The UI passes the displayed rank so repeated/stale activation cannot buy a second rank.
	if expected_rank >= 0 and rank(id) != expected_rank:
		return _fail("This rank changed. Review the next rank before buying again.")
	var state: Dictionary = purchase_state(id)
	if state.status != "affordable":
		return _fail(state.message)
	var candidate: Dictionary = _snapshot()
	# The affordable state already priced this rank against the same definition.
	candidate.coins -= int(state.gold_cost)
	candidate.available_recruits -= int(state.recruit_cost)
	candidate.purchased[id] = rank(id) + 1
	# Persist the candidate first: failed writes never charge or grant the upgrade.
	if not _write_snapshot(candidate):
		return false
	_apply_snapshot(candidate)
	return true


func add_donation(amount: int, recruits: int = 1) -> void:
	if amount < 0 or recruits < 0:
		last_error = "Negative rewards are not valid."
		return
	_add_earnings(amount, recruits)
	# Keep earned progress in memory if storage fails; expose last_error to the UI.
	save_progress()


func _add_earnings(amount: int, recruits: int) -> void:
	# Clamp the increment before adding so even large valid rewards cannot overflow.
	coins += mini(amount, MAX_COUNTER - coins)
	total_recruits += mini(recruits, MAX_COUNTER - total_recruits)
	available_recruits += mini(recruits, MAX_COUNTER - available_recruits)


func speech_interval() -> float:
	return 1.0 / (1.0 + _sum_effect("speech_speed_add"))


func conviction_per_phrase() -> float:
	return 1.0 + _sum_effect("conviction_add")


func run_multiplier() -> float:
	return 1.0 + _sum_effect("run_speed_add")


## World pixels within which lone wanderers walk toward the cultist; zero without Beckoning Call.
func beckon_reach() -> float:
	return BECKON_PIXELS_PER_POINT * _sum_effect("beckon_add")


func has_unlock(key: String) -> bool:
	return key in UNLOCK_KEYS and _sum_effect(key) >= 1.0


func conviction_for(npc_type: String) -> float:
	return conviction_per_phrase() + (_sum_effect("merchant_conviction_add") if npc_type == "merchant" else 0.0)


func encounter_conviction(kind: String) -> float:
	return conviction_per_phrase() + _sum_effect("encounter_conviction_add") + _sum_effect(kind + "_conviction_add")


func complete_encounter(expected_stage: int) -> bool:
	if expected_stage != encounter_stage or encounter_stage >= 4 or not has_unlock("encounter_unlock"):
		return false
	_add_earnings(ENCOUNTER_REWARDS[encounter_stage], 1)
	encounter_stage += 1
	# Like earned donations, victory stays in memory on failed storage; expose the error.
	save_progress()
	return true


func map_complete() -> bool:
	return encounter_stage == 4


func is_circle_complete(area_id: String = "") -> bool:
	# Completion follows actual local ranks, independently of the Priest objective.
	# Preserve direct catalog fixtures for the currently displayed circle.
	var definitions: Array[Dictionary] = catalog if area_id.is_empty() or area_id == active_area else catalog_for_area(area_id)
	return _ranks_complete(definitions, purchased)


func _ranks_complete(definitions: Array[Dictionary], ranks: Dictionary) -> bool:
	if definitions.is_empty():
		return false
	for entry in definitions:
		if int(ranks.get(entry.id, 0)) != int(entry.get("max_rank", 1)):
			return false
	return true


func is_area_unlocked(area_id: String) -> bool:
	if not area_id in AREA_IDS or catalog_for_area(area_id).is_empty():
		return false
	return area_id == "bramblewick" or level_select_unlocked or is_circle_complete("bramblewick")


func try_travel(area_id: String, bypass_unlock: bool = false) -> bool:
	last_error = ""
	if not area_id in AREA_IDS or catalog_for_area(area_id).is_empty():
		return _fail("That destination is not implemented.")
	if not bypass_unlock and not is_area_unlocked(area_id):
		return _fail("Complete Bramblewick's ritual circle to reach Bellmarket.")
	var candidate: Dictionary = _snapshot()
	candidate.active_area = area_id
	candidate.level_select_unlocked = level_select_unlocked or bypass_unlock
	# Main prepares the destination before requesting this durable transition.
	if not _write_snapshot(candidate):
		return false
	_apply_snapshot(candidate)
	return true


func merchant_donation() -> int:
	return BASE_MERCHANT_DONATION + int(_sum_effect("merchant_donation_add"))


func market_donation(npc_type: String, base_amount: int) -> int:
	if npc_type in ["guild", "patron"]:
		return base_amount + int(_sum_effect("market_" + npc_type + "_donation_add"))
	return base_amount


func gathering_count() -> int:
	return 3 + int(has_unlock("meadow_unlock")) + int(has_unlock("east_unlock"))


func effect_preview(id: String) -> Dictionary:
	# Composed from one catalog pass: the per-key helpers below answer the same
	# questions, but asking each separately swept every rank thirty times here.
	var totals: Dictionary = _all_effect_totals()
	var base_conviction: float = 1.0 + float(totals.conviction_add)
	var opponent_bonus: float = float(totals.encounter_conviction_add)
	var current: Dictionary = {
		"speech_frequency": 1.0 + float(totals.speech_speed_add),
		"conviction": base_conviction,
		"run_multiplier": 1.0 + float(totals.run_speed_add),
		"gatherings": 3 + int(_unlocked(totals, "meadow_unlock")) + int(_unlocked(totals, "east_unlock")),
		"merchant_unlock": int(_unlocked(totals, "merchant_unlock")),
		"merchant_conviction_add": base_conviction + float(totals.merchant_conviction_add),
		"merchant_donation_add": BASE_MERCHANT_DONATION + int(float(totals.merchant_donation_add)),
		"helpers": int(_unlocked(totals, "helper_unlock")),
		"beckon_reach": BECKON_PIXELS_PER_POINT * float(totals.beckon_add),
	}
	current.encounter_unlock = int(_unlocked(totals, "encounter_unlock"))
	current.encounter_conviction_add = base_conviction + opponent_bonus
	for kind in ["skeptic", "guard", "zealot", "priest"]:
		current[kind + "_conviction_add"] = base_conviction + opponent_bonus + float(totals[kind + "_conviction_add"])
	for kind in ["guild", "patron"]:
		current["market_" + kind + "_unlock"] = int(_unlocked(totals, "market_" + kind + "_unlock"))
		current["market_" + kind + "_donation_add"] = float(totals["market_" + kind + "_donation_add"])
	var result: Dictionary = {"current": current, "next": {}}
	var upgrade: Dictionary = find_upgrade(id)
	if upgrade.is_empty() or rank(id) >= max_rank(id):
		return result
	result.next = current.duplicate()
	var effect: Dictionary = _rank_effect(upgrade, rank(id))
	result.next.speech_frequency += float(effect.get("speech_speed_add", 0.0))
	result.next.conviction += float(effect.get("conviction_add", 0.0))
	result.next.run_multiplier += float(effect.get("run_speed_add", 0.0))
	result.next.gatherings += int(effect.get("meadow_unlock", 0)) + int(effect.get("east_unlock", 0))
	for key in ["merchant_unlock", "merchant_conviction_add", "merchant_donation_add", "encounter_unlock", "encounter_conviction_add", "skeptic_conviction_add", "guard_conviction_add", "zealot_conviction_add", "priest_conviction_add"]:
		result.next[key] += float(effect.get(key, 0.0))
	for kind in ["guild", "patron"]:
		for suffix in ["_unlock", "_donation_add"]:
			var key: String = "market_" + kind + suffix
			result.next[key] += float(effect.get(key, 0.0))
	result.next.helpers += int(effect.get("helper_unlock", 0))
	result.next.beckon_reach += BECKON_PIXELS_PER_POINT * float(effect.get("beckon_add", 0.0))
	return result


func save_progress() -> bool:
	return _write_snapshot(_snapshot())


func load_progress() -> bool:
	last_error = ""
	_write_blocked = false
	_archive_corrupt_on_save = false
	if not save_enabled:
		return true
	if not save_path.begins_with("user://"):
		_write_blocked = true
		return _fail("Save path must be under user://.")
	if not FileAccess.file_exists(save_path):
		# A missing canonical file plus backup can result from interrupted replacement.
		if FileAccess.file_exists(save_path + ".bak"):
			var backup: Dictionary = _read_snapshot(save_path + ".bak")
			if not backup.is_empty():
				_apply_snapshot(backup)
				last_error = "Recovered progression from backup after an interrupted save."
				return true
			_write_blocked = true
			return _fail("The save backup is invalid; preserved it without overwriting.")
		return true
	var raw: Variant = _parse_json(FileAccess.get_file_as_string(save_path))
	if raw is Dictionary and _finite_number(raw.get("schema_version")) and raw.schema_version > SAVE_VERSION:
		_write_blocked = true
		return _fail("Save uses a newer version; it is preserved and saving is disabled.")
	var current: Dictionary = _validated_snapshot(raw)
	if not current.is_empty():
		_apply_snapshot(current)
		return true
	_archive_corrupt_on_save = true
	var recovered: Dictionary = _read_snapshot(save_path + ".bak")
	if not recovered.is_empty():
		_apply_snapshot(recovered)
		last_error = "Save was damaged. Recovered its backup; damaged original will be preserved as .corrupt."
		return true
	# Start clean in memory, but preserve the bad file on the first successful save.
	_apply_snapshot({"coins": 0, "total_recruits": 0, "available_recruits": 0, "round_number": 1, "purchased": {}})
	return _fail("Save was damaged. Fresh progression started; damaged original will be preserved as .corrupt.")


func _snapshot() -> Dictionary:
	return {"schema_version": SAVE_VERSION, "coins": coins, "total_recruits": total_recruits, "available_recruits": available_recruits, "round_number": round_number, "purchased": purchased.duplicate(true), "encounter_stage": encounter_stage, "active_area": active_area, "level_select_unlocked": level_select_unlocked}


func _apply_snapshot(state: Dictionary) -> void:
	var next_area: String = str(state.get("active_area", "bramblewick"))
	if next_area != active_area:
		active_area = next_area
		catalog = catalog_for_area(active_area)
	level_select_unlocked = bool(state.get("level_select_unlocked", false))
	encounter_stage = int(state.get("encounter_stage", 0))
	coins = int(state.coins)
	total_recruits = int(state.total_recruits)
	available_recruits = int(state.available_recruits)
	round_number = int(state.round_number)
	purchased = state.purchased.duplicate(true)


## Called every frame for speech and conviction, so this stays allocation-free.
func _sum_effect(key: String) -> float:
	var total: float = 0.0
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		# Bramblewick's earned benefits carry into new places. Market tuning is local,
		# so returning never changes the measured first-map routes.
		if entry.get("area", "bramblewick") != "bramblewick" and entry.area != active_area:
			continue
		for index in range(rank(entry.id)):
			total += float(_rank_effect(entry, index).get(key, 0.0))
	return total


## Every supported effect from one pass over the ranks `_sum_effect` reads, using
## the same area rule and the same catalog and rank order, so the totals match it.
func _all_effect_totals() -> Dictionary:
	var totals: Dictionary = {}
	for key in EFFECT_KEYS:
		totals[key] = 0.0
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		if entry.get("area", "bramblewick") != "bramblewick" and entry.area != active_area:
			continue
		for index in range(rank(entry.id)):
			var effect: Dictionary = _rank_effect(entry, index)
			for key in effect:
				if totals.has(key):
					totals[key] += float(effect[key])
	return totals


func _unlocked(totals: Dictionary, key: String) -> bool:
	return key in UNLOCK_KEYS and float(totals.get(key, 0.0)) >= 1.0


func _rank_effect(upgrade: Dictionary, index: int) -> Dictionary:
	return upgrade.rank_effects[index] if upgrade.has("rank_effects") else upgrade.effect


func _validated_snapshot(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not _integer_between(raw.get("schema_version"), 1, SAVE_VERSION):
		return {}
	for key in ["coins", "total_recruits"]:
		if not _integer_between(raw.get(key), 0, MAX_COUNTER):
			return {}
	if int(raw.schema_version) >= 3 and not _integer_between(raw.get("available_recruits"), 0, int(raw.total_recruits)):
		return {}
	if not _integer_between(raw.get("round_number"), 1, MAX_COUNTER) or not raw.get("purchased") is Dictionary:
		return {}
	if not _integer_between(raw.get("encounter_stage", 0), 0, 4):
		return {}
	var unlock_id: String = _encounter_unlock_id()
	if int(raw.get("encounter_stage", 0)) > 0 and (unlock_id.is_empty() or not raw.purchased.has(unlock_id)):
		return {}
	if int(raw.schema_version) >= 4:
		if not raw.get("active_area") is String or not raw.active_area in AREA_IDS:
			return {}
		if catalog_for_area(raw.active_area).is_empty() or not raw.get("level_select_unlocked") is bool:
			return {}
	var normalized: Dictionary = raw.duplicate(true)
	# Old saves never spent recruits. Preserve all prior ranks without charging them.
	normalized.available_recruits = int(raw.available_recruits) if int(raw.schema_version) >= 3 else int(raw.total_recruits)
	normalized.encounter_stage = int(raw.get("encounter_stage", 0))
	normalized.active_area = raw.active_area if int(raw.schema_version) >= 4 else "bramblewick"
	normalized.level_select_unlocked = raw.level_select_unlocked if int(raw.schema_version) >= 4 else false
	normalized.schema_version = SAVE_VERSION
	for id in raw.purchased:
		if not id is String:
			return {}
		var definition: Dictionary = find_upgrade(id)
		if definition.is_empty():
			return {}
		if int(raw.schema_version) < 4 and definition.get("area", "bramblewick") != "bramblewick":
			return {}
		if int(raw.schema_version) == 1:
			if not raw.purchased[id] is bool or raw.purchased[id] != true:
				return {}
			normalized.purchased[id] = 1
		else:
			if not _integer_between(raw.purchased[id], 1, max_rank(id)):
				return {}
			normalized.purchased[id] = int(raw.purchased[id])
		for requirement in definition.requires:
			if not raw.purchased.has(requirement):
				return {}
	# Neither a saved active area nor off-area purchases may bypass the normal gate.
	var needs_market_access: bool = normalized.active_area == "bellmarket"
	for id in normalized.purchased:
		needs_market_access = needs_market_access or find_upgrade(id).get("area", "bramblewick") == "bellmarket"
	if needs_market_access and not normalized.level_select_unlocked and not _ranks_complete(_market_gate_definitions(), normalized.purchased):
		return {}
	return normalized


func _market_gate_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in catalog_for_area("bramblewick"):
		if not entry.id in POST_MARKET_VILLAGE_IDS:
			result.append(entry)
	return result


func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return _validated_snapshot(_parse_json(FileAccess.get_file_as_string(path)))


func _write_snapshot(state: Dictionary) -> bool:
	last_error = ""
	if _validated_snapshot(state).is_empty():
		return _fail("Progression is invalid; it was not saved.")
	if not save_enabled:
		return true
	if _write_blocked:
		return _fail("Saving is disabled to preserve an incompatible or damaged save.")
	if not save_path.begins_with("user://"):
		return _fail("Save path must be under user://.")
	var temp: String = save_path + ".tmp"
	var backup: String = save_path + ".bak"
	var output: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if output == null:
		return _fail("Cannot write progression; earnings remain in memory. Storage error " + str(FileAccess.get_open_error()) + ".")
	output.store_string(JSON.stringify(state, "\t"))
	output.flush()
	var write_error: Error = output.get_error()
	output.close()
	if write_error != OK or _read_snapshot(temp).is_empty():
		return _fail("Progression write did not verify; previous save was preserved.")
	if _archive_corrupt_on_save and FileAccess.file_exists(save_path):
		if FileAccess.file_exists(save_path + ".corrupt"):
			return _fail("A previous .corrupt recovery file already exists; damaged save preserved. Move it aside before saving again.")
		if DirAccess.rename_absolute(save_path, save_path + ".corrupt") != OK:
			return _fail("Cannot preserve the damaged save; saving stopped.")
		_archive_corrupt_on_save = false
	elif FileAccess.file_exists(save_path):
		# A backup is replaced only with a known-valid canonical save.
		if _read_snapshot(save_path).is_empty():
			return _fail("Save changed or is damaged; reload before saving again.")
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			return _fail("Cannot rotate the progression backup.")
		if DirAccess.rename_absolute(save_path, backup) != OK:
			return _fail("Cannot preserve the previous save.")
	if DirAccess.rename_absolute(temp, save_path) != OK:
		if not FileAccess.file_exists(save_path) and FileAccess.file_exists(backup):
			DirAccess.copy_absolute(backup, save_path)
		return _fail("Cannot finish progression save; previous progress preserved.")
	return true


func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _parse_json(contents: String) -> Variant:
	var parser: JSON = JSON.new()
	return parser.data if parser.parse(contents) == OK else null


func _integer_between(value: Variant, minimum: int, maximum: int) -> bool:
	return _finite_number(value) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum


func _fail(message: String) -> bool:
	last_error = message
	return false
