extends RefCounted
## Progression's save file: new game, the validation and migration of older
## schemas, and how saved state reaches progression. Progression owns the
## numbers; the shared toolkit's JsonSave owns the file (staged writes, backup
## recovery, damaged files kept as .corrupt, newer versions left untouched).
const JsonSave = preload("res://addons/hatchery/storage/json_save.gd")

## Weak, because progression holds this helper; a strong pair would never be freed.
var _owner: WeakRef
var progression: RefCounted:
	get:
		return _owner.get_ref()
var _file: JsonSave


func _init(owner_progression: RefCounted) -> void:
	_owner = weakref(owner_progression)
	# Method callables, not lambdas: a lambda would hold this helper strongly
	# from its own file and never be freed.
	_file = JsonSave.new("", owner_progression.SAVE_VERSION, _accepts)
	_file.schema_key = "schema_version"
	_file.noun = "progression"
	_file.migrate = _migrated


func _accepts(data: Dictionary) -> bool:
	return not validated(data).is_empty()


## Every older schema is brought up to date by validation itself; one it
## rejects keeps its old version, so the file reads as damaged.
func _migrated(data: Dictionary) -> Dictionary:
	var current: Dictionary = validated(data)
	return current if not current.is_empty() else data


## The file, following progression's current path and persistence switch.
func file() -> JsonSave:
	_file.path = progression.save_path
	_file.enabled = progression.save_enabled
	return _file


## Replaces progression with a fresh first-round village save. The old save is
## first copied to `.previous`, which ordinary saves never rotate, so it outlives
## the next rounds' writes. A failed copy or write changes nothing.
func start_new_game() -> bool:
	progression.last_error = ""
	if not file().writes_blocked and not _file.keep_previous():
		return progression._fail("Cannot keep a copy of the current save, so it was not replaced.")
	var fresh: Dictionary = {"schema_version": progression.SAVE_VERSION, "coins": 0, "total_recruits": 0, "available_recruits": 0, "round_number": 1, "purchased": {}, "encounter_stage": 0, "fair_stage": 0, "uni_stage": 0, "uni_loadout": [], "rose_king_won": false, "active_area": "bramblewick", "level_select_unlocked": false}
	if not write(fresh):
		return false
	apply(fresh)
	return true


func save() -> bool:
	return write(snapshot())


func load_file() -> bool:
	progression.last_error = ""
	var data: Dictionary = file().load_data()
	if not data.is_empty():
		apply(validated(data))
		progression.last_error = _file.last_error
		return true
	if _file.last_error.is_empty():
		return true
	if not _file.writes_blocked:
		# Start clean in memory; the damaged file is kept as .corrupt on the first save.
		apply({"coins": 0, "total_recruits": 0, "available_recruits": 0, "round_number": 1, "purchased": {}})
	return progression._fail(_file.last_error)


func snapshot() -> Dictionary:
	return {"schema_version": progression.SAVE_VERSION, "coins": progression.coins, "total_recruits": progression.total_recruits, "available_recruits": progression.available_recruits, "round_number": progression.round_number, "purchased": progression.purchased.duplicate(true), "encounter_stage": progression.encounter_stage, "fair_stage": progression.fair_stage, "uni_stage": progression.uni_stage, "uni_loadout": progression.uni_loadout.duplicate(), "rose_king_won": progression.rose_king_won, "active_area": progression.active_area, "level_select_unlocked": progression.level_select_unlocked}


func apply(state: Dictionary) -> void:
	var next_area: String = str(state.get("active_area", "bramblewick"))
	if next_area != progression.active_area:
		progression.active_area = next_area
		progression.catalog = progression.catalog_for_area(progression.active_area)
	progression.level_select_unlocked = bool(state.get("level_select_unlocked", false))
	progression.encounter_stage = int(state.get("encounter_stage", 0))
	progression.fair_stage = int(state.get("fair_stage", 0))
	progression.uni_stage = int(state.get("uni_stage", 0))
	progression.uni_loadout.assign(state.get("uni_loadout", []))
	progression.rose_king_won = bool(state.get("rose_king_won", false))
	progression.coins = int(state.coins)
	progression.total_recruits = int(state.total_recruits)
	progression.available_recruits = int(state.available_recruits)
	progression.round_number = int(state.round_number)
	progression.purchased = state.purchased.duplicate(true)


func validated(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not progression._integer_between(raw.get("schema_version"), 1, progression.SAVE_VERSION):
		return {}
	for key in ["coins", "total_recruits"]:
		if not progression._integer_between(raw.get(key), 0, progression.MAX_COUNTER):
			return {}
	if int(raw.schema_version) >= 3 and not progression._integer_between(raw.get("available_recruits"), 0, int(raw.total_recruits)):
		return {}
	if not progression._integer_between(raw.get("round_number"), 1, progression.MAX_COUNTER) or not raw.get("purchased") is Dictionary:
		return {}
	if not progression._integer_between(raw.get("encounter_stage", 0), 0, 4):
		return {}
	if not progression._integer_between(raw.get("fair_stage", 0), 0, progression.FAIR_BOSS_COUNT if int(raw.schema_version) >= 5 else 0):
		return {}
	if not progression._integer_between(raw.get("uni_stage", 0), 0, progression.UNI_BOSS_COUNT if int(raw.schema_version) >= 6 else 0):
		return {}
	# The King arrived with schema 7; his approval is a plain flag.
	if not raw.get("rose_king_won", false) is bool or (int(raw.schema_version) < 7 and raw.get("rose_king_won", false)):
		return {}
	var unlock_id: String = progression._encounter_unlock_id()
	if int(raw.get("encounter_stage", 0)) > 0 and (unlock_id.is_empty() or not raw.purchased.has(unlock_id)):
		return {}
	if int(raw.schema_version) >= 4:
		if not raw.get("active_area") is String or not raw.active_area in progression.AREA_IDS:
			return {}
		# The fair arrived with schema 5; an older save cannot already stand there.
		if int(raw.schema_version) < 5 and raw.active_area == "lantern_fair":
			return {}
		# Quillmoor arrived with schema 6.
		if int(raw.schema_version) < 6 and raw.active_area == progression.UNI_AREA:
			return {}
		# Rosecourt arrived with schema 7.
		if int(raw.schema_version) < 7 and raw.active_area == progression.ROSE_AREA:
			return {}
		if progression.catalog_for_area(raw.active_area).is_empty() or not raw.get("level_select_unlocked") is bool:
			return {}
	var normalized: Dictionary = raw.duplicate(true)
	# Old saves never spent recruits. Preserve all prior ranks without charging them.
	normalized.available_recruits = int(raw.available_recruits) if int(raw.schema_version) >= 3 else int(raw.total_recruits)
	normalized.encounter_stage = int(raw.get("encounter_stage", 0))
	normalized.fair_stage = int(raw.get("fair_stage", 0))
	normalized.uni_stage = int(raw.get("uni_stage", 0))
	normalized.rose_king_won = bool(raw.get("rose_king_won", false))
	normalized.active_area = raw.active_area if int(raw.schema_version) >= 4 else "bramblewick"
	normalized.level_select_unlocked = raw.level_select_unlocked if int(raw.schema_version) >= 4 else false
	normalized.schema_version = progression.SAVE_VERSION
	for id in raw.purchased:
		if not id is String:
			return {}
		var definition: Dictionary = progression.find_upgrade(id)
		if definition.is_empty():
			return {}
		if int(raw.schema_version) < 4 and definition.get("area", "bramblewick") != "bramblewick":
			return {}
		if int(raw.schema_version) < 5 and definition.get("area", "bramblewick") == "lantern_fair":
			return {}
		if int(raw.schema_version) < 6 and definition.get("area", "bramblewick") == progression.UNI_AREA:
			return {}
		if int(raw.schema_version) < 7 and definition.get("area", "bramblewick") == progression.ROSE_AREA:
			return {}
		if int(raw.schema_version) == 1:
			if not raw.purchased[id] is bool or raw.purchased[id] != true:
				return {}
			normalized.purchased[id] = 1
		else:
			if not progression._integer_between(raw.purchased[id], 1, progression.max_rank(id)):
				return {}
			normalized.purchased[id] = int(raw.purchased[id])
		for requirement in definition.requires:
			if not raw.purchased.has(requirement):
				return {}
	# Neither a saved active area nor off-area purchases may bypass the normal gate.
	var furthest: int = progression.AREA_IDS.find(normalized.active_area)
	for id in normalized.purchased:
		furthest = maxi(furthest, progression.AREA_IDS.find(str(progression.find_upgrade(id).get("area", "bramblewick"))))
	if normalized.fair_stage > 0:
		furthest = maxi(furthest, progression.AREA_IDS.find("lantern_fair"))
	if normalized.uni_stage > 0:
		furthest = maxi(furthest, progression.AREA_IDS.find(progression.UNI_AREA))
	if normalized.rose_king_won:
		furthest = maxi(furthest, progression.AREA_IDS.find(progression.ROSE_AREA))
	if not normalized.level_select_unlocked:
		if furthest >= 1 and not progression._ranks_complete(_market_gate_definitions(), normalized.purchased):
			return {}
		if furthest >= 2 and not progression._ranks_complete(progression.catalog_for_area("bellmarket"), normalized.purchased):
			return {}
		if furthest >= 3 and not progression._ranks_complete(progression.catalog_for_area("lantern_fair"), normalized.purchased):
			return {}
		if furthest >= 4 and not progression._ranks_complete(progression.catalog_for_area(progression.UNI_AREA), normalized.purchased):
			return {}
	# The loadout is trimmed, never a reason to reject a save: unknown or repeated
	# arguments are dropped, then any beyond the owned slots.
	var loadout: Array[String] = []
	var saved_loadout: Variant = raw.get("uni_loadout", [])
	if saved_loadout is Array:
		var known: Array[String] = progression.argument_ids()
		for id in saved_loadout:
			if id is String and id in known and not id in loadout:
				loadout.append(id)
	normalized.uni_loadout = loadout.slice(0, progression._slots_for(normalized.purchased))
	return normalized


func _market_gate_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in progression.catalog_for_area("bramblewick"):
		if not entry.id in progression.POST_MARKET_VILLAGE_IDS:
			result.append(entry)
	return result


func write(state: Dictionary) -> bool:
	progression.last_error = ""
	if validated(state).is_empty():
		return progression._fail("Progression is invalid; it was not saved.")
	if not file().save_data(state):
		return progression._fail(_file.last_error + " Earnings remain in memory.")
	return true
