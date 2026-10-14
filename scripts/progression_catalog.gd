extends RefCounted
## Validates the upgrade catalog for progression: ranks, prices, effects that
## stay in their own area, unlocks that appear once and an acyclic prerequisite
## graph. Returns the normalized definitions, or the reason they were refused.


static func parse(p: RefCounted, raw: Variant) -> Variant:
	if not raw is Dictionary or raw.get("schema_version") != 1 or not raw.get("upgrades") is Array:
		return "Upgrade catalog is missing or has an unsupported format."
	var candidate: Array[Dictionary] = []
	var ids: Dictionary = {}
	for entry in raw.upgrades:
		if not entry is Dictionary:
			return "Upgrade entry must be an object."
		for key in ["id", "title", "description", "branch"]:
			if not entry.get(key) is String or entry[key].strip_edges().is_empty():
				return "Upgrade entry needs a nonempty " + key + "."
		if ids.has(entry.id):
			return "Duplicate upgrade ID: " + entry.id
		var area: Variant = entry.get("area", "bramblewick")
		if not area is String or not area in p.AREA_IDS:
			return "Unknown upgrade area: " + entry.id
		if not p._integer_between(entry.get("ring"), 1, 10000) or not p._finite_number(entry.get("angle_degrees")):
			return "Invalid ritual coordinate: " + entry.id
		if not p._integer_between(entry.get("cost"), 1, p.MAX_COUNTER):
			return "Invalid upgrade cost: " + entry.id
		var rank_limit: Variant = entry.get("max_rank", 1)
		if not p._integer_between(rank_limit, 1, 100):
			return "Invalid upgrade rank limit: " + entry.id
		var prices: Variant = entry.get("rank_costs", [entry.cost])
		if not prices is Array or prices.size() != int(rank_limit):
			return "Upgrade needs one price per rank: " + entry.id
		for price in prices:
			if not p._integer_between(price, 1, p.MAX_COUNTER):
				return "Invalid upgrade rank price: " + entry.id
		if int(prices[0]) != int(entry.cost):
			return "First rank price must match cost: " + entry.id
		var recruit_prices: Variant = entry.get("rank_recruit_costs", [])
		if not recruit_prices is Array:
			return "Recruit prices must be an array: " + entry.id
		if not entry.has("rank_recruit_costs"):
			for index in range(int(rank_limit)):
				recruit_prices.append(0)
		if recruit_prices.size() != int(rank_limit):
			return "Upgrade needs one recruit price per rank: " + entry.id
		for price in recruit_prices:
			if not p._integer_between(price, 0, p.MAX_COUNTER):
				return "Invalid upgrade recruit price: " + entry.id
		if entry.has("support_description") and not entry.support_description is String:
			return "Support description must be text: " + entry.id
		if not entry.get("requires") is Array or not entry.get("effect") is Dictionary or entry.effect.is_empty():
			return "Invalid prerequisites/effects: " + entry.id
		for effect in entry.effect:
			if not effect in p.EFFECT_KEYS or not p._finite_number(entry.effect[effect]) or entry.effect[effect] <= 0.0 or entry.effect[effect] > 100.0:
				return "Unsupported effect: " + entry.id
		var effects: Variant = entry.get("rank_effects", [])
		if not effects is Array:
			return "Rank effects must be an array: " + entry.id
		if not entry.has("rank_effects"):
			for index in range(int(rank_limit)):
				effects.append(entry.effect.duplicate(true))
		if effects.size() != int(rank_limit):
			return "Upgrade needs one effect per rank: " + entry.id
		for rank_effect in effects:
			if not rank_effect is Dictionary or rank_effect.is_empty():
				return "Rank effect must be a nonempty object: " + entry.id
			for effect in rank_effect:
				if not effect in p.EFFECT_KEYS or not p._finite_number(rank_effect[effect]) or rank_effect[effect] <= 0.0 or rank_effect[effect] > 100.0:
					return "Unsupported rank effect: " + entry.id
		if effects[0] != entry.effect:
			return "First rank effect must match effect: " + entry.id
		var movement_upgrade: bool = entry.branch == "run"
		for rank_effect in effects:
			movement_upgrade = movement_upgrade or rank_effect.has("run_speed_add")
		if movement_upgrade:
			for price in recruit_prices:
				if price != 0:
					return "Running upgrades must remain gold-only: " + entry.id
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
				if effect in ["merchant_donation_add", "market_guild_donation_add", "market_patron_donation_add"] and not p._integer_between(rank_effect[effect], 1, 100):
					return "Donation bonuses must be whole numbers: " + entry.id
				for owner in p.AREA_EFFECT_PREFIXES:
					if effect.begins_with(p.AREA_EFFECT_PREFIXES[owner]) and entry.area != owner:
						return "Effects named %s* belong to %s: %s" % [p.AREA_EFFECT_PREFIXES[owner], p.AREA_TITLES[owner], entry.id]
				if effect in p.WHOLE_FAIR_KEYS and not p._integer_between(rank_effect[effect], 1, 100):
					return "Interest and Distraction effects must be whole numbers: " + entry.id
				if effect in p.WHOLE_UNI_KEYS and not p._integer_between(rank_effect[effect], 1, 100):
					return "Argument slots and Quillmoor donations must be whole numbers: " + entry.id
				if effect in p.WHOLE_ROSE_KEYS and not p._integer_between(rank_effect[effect], 1, 100):
					return "Rosecourt threads, trusted nobles and donations must be whole numbers: " + entry.id
				if effect in p.UNLOCK_KEYS:
					if entry.max_rank != 1 or rank_effect[effect] != 1 or unlocks.has(effect):
						return "Unlocks must appear once, at one rank and value 1: " + entry.id
					unlocks[effect] = true
		var seen: Dictionary = {}
		for requirement in entry.requires:
			if not requirement is String or not ids.has(requirement) or requirement == entry.id or seen.has(requirement):
				return "Invalid prerequisite: " + entry.id
			if ids[requirement].area != entry.area:
				return "Circle prerequisites must stay within their area: " + entry.id
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
			return "Upgrade prerequisite cycle detected."
	return candidate
