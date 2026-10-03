extends RefCounted
## Single owner for upgrade purchases and durable earnings. Definitions contain no code.
## Saves only progression: rounds always start fresh after relaunch; no offline accrual.

const SAVE_VERSION: int = 2
const MAX_COUNTER: int = 1000000000
const EFFECT_KEYS: Array[String] = ["speech_speed_add", "conviction_add", "run_speed_add"]

var coins: int = 0
var total_recruits: int = 0
var round_number: int = 1
var purchased: Dictionary = {}
var catalog: Array[Dictionary] = []
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
		var normalized: Dictionary = entry.duplicate(true)
		normalized.max_rank = int(rank_limit)
		normalized.rank_costs = prices.duplicate()
		normalized.rank_effects = effects.duplicate(true)
		ids[entry.id] = normalized
		candidate.append(normalized)
	for entry in candidate:
		var seen: Dictionary = {}
		for requirement in entry.requires:
			if not requirement is String or not ids.has(requirement) or requirement == entry.id or seen.has(requirement):
				return _fail("Invalid prerequisite: " + entry.id)
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
	catalog = candidate
	return true


func find_upgrade(id: String) -> Dictionary:
	for entry in catalog:
		if entry.id == id:
			return entry
	return {}


func rank(id: String) -> int:
	return int(purchased.get(id, 0))


func max_rank(id: String) -> int:
	var upgrade: Dictionary = find_upgrade(id)
	return int(upgrade.get("max_rank", 1)) if not upgrade.is_empty() else 0


func next_cost(id: String) -> int:
	var upgrade: Dictionary = find_upgrade(id)
	if upgrade.is_empty() or rank(id) >= max_rank(id):
		return 0
	var prices: Array = upgrade.get("rank_costs", [upgrade.cost])
	return int(prices[rank(id)])


func status(id: String) -> String:
	var upgrade: Dictionary = find_upgrade(id)
	if upgrade.is_empty():
		return "unknown"
	if rank(id) >= max_rank(id):
		return "purchased"
	for requirement in upgrade.requires:
		if rank(requirement) < 1:
			return "locked"
	return "affordable" if coins >= next_cost(id) else "unaffordable"


func try_purchase(id: String, expected_rank: int = -1) -> bool:
	last_error = ""
	# The UI passes the displayed rank so repeated/stale activation cannot buy a second rank.
	if expected_rank >= 0 and rank(id) != expected_rank:
		return _fail("This rank changed. Review the next rank before buying again.")
	if status(id) != "affordable":
		return false
	var candidate: Dictionary = _snapshot()
	candidate.coins -= next_cost(id)
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
	coins = mini(coins + amount, MAX_COUNTER)
	total_recruits = mini(total_recruits + recruits, MAX_COUNTER)
	# Keep earned progress in memory if storage fails; expose last_error to the UI.
	save_progress()


func speech_interval() -> float:
	return 1.0 / (1.0 + _sum_effect("speech_speed_add"))


func conviction_per_phrase() -> float:
	return 1.0 + _sum_effect("conviction_add")


func run_multiplier() -> float:
	return 1.0 + _sum_effect("run_speed_add")


func effect_preview(id: String) -> Dictionary:
	var current: Dictionary = {
		"speech_frequency": 1.0 + _sum_effect("speech_speed_add"),
		"conviction": conviction_per_phrase(),
		"run_multiplier": run_multiplier(),
	}
	var result: Dictionary = {"current": current, "next": {}}
	var upgrade: Dictionary = find_upgrade(id)
	if upgrade.is_empty() or rank(id) >= max_rank(id):
		return result
	result.next = current.duplicate()
	var effect: Dictionary = _rank_effect(upgrade, rank(id))
	result.next.speech_frequency += float(effect.get("speech_speed_add", 0.0))
	result.next.conviction += float(effect.get("conviction_add", 0.0))
	result.next.run_multiplier += float(effect.get("run_speed_add", 0.0))
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
	_apply_snapshot({"coins": 0, "total_recruits": 0, "round_number": 1, "purchased": {}})
	return _fail("Save was damaged. Fresh progression started; damaged original will be preserved as .corrupt.")


func _snapshot() -> Dictionary:
	return {"schema_version": SAVE_VERSION, "coins": coins, "total_recruits": total_recruits, "round_number": round_number, "purchased": purchased.duplicate(true)}


func _apply_snapshot(state: Dictionary) -> void:
	coins = int(state.coins)
	total_recruits = int(state.total_recruits)
	round_number = int(state.round_number)
	purchased = state.purchased.duplicate(true)


func _sum_effect(key: String) -> float:
	var total: float = 0.0
	for entry in catalog:
		for index in range(rank(entry.id)):
			total += float(_rank_effect(entry, index).get(key, 0.0))
	return total


func _rank_effect(upgrade: Dictionary, index: int) -> Dictionary:
	return upgrade.rank_effects[index] if upgrade.has("rank_effects") else upgrade.effect


func _validated_snapshot(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not _integer_between(raw.get("schema_version"), 1, SAVE_VERSION):
		return {}
	for key in ["coins", "total_recruits"]:
		if not _integer_between(raw.get(key), 0, MAX_COUNTER):
			return {}
	if not _integer_between(raw.get("round_number"), 1, MAX_COUNTER) or not raw.get("purchased") is Dictionary:
		return {}
	var normalized: Dictionary = raw.duplicate(true)
	normalized.schema_version = SAVE_VERSION
	for id in raw.purchased:
		if not id is String:
			return {}
		var definition: Dictionary = find_upgrade(id)
		if definition.is_empty():
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
	return normalized


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
