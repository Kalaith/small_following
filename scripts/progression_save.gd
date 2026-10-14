extends RefCounted
## Progression's save file: new game, load with backup recovery, validation and
## the staged write. Progression owns the numbers; this owns the file.

## Weak, because progression holds this helper; a strong pair would never be freed.
var _owner: WeakRef
var progression: RefCounted:
	get:
		return _owner.get_ref()


func _init(owner_progression: RefCounted) -> void:
	_owner = weakref(owner_progression)


## Replaces progression with a fresh first-round village save. The old save is
## first copied to `.previous`, which ordinary saves never rotate, so it outlives
## the next rounds' writes. A failed copy or write changes nothing.
func start_new_game() -> bool:
	progression.last_error = ""
	if progression.save_enabled and not progression._write_blocked and FileAccess.file_exists(progression.save_path):
		if DirAccess.copy_absolute(progression.save_path, progression.save_path + ".previous") != OK:
			return progression._fail("Cannot keep a copy of the current save, so it was not replaced.")
	var fresh: Dictionary = {"schema_version": progression.SAVE_VERSION, "coins": 0, "total_recruits": 0, "available_recruits": 0, "round_number": 1, "purchased": {}, "encounter_stage": 0, "fair_stage": 0, "uni_stage": 0, "uni_loadout": [], "active_area": "bramblewick", "level_select_unlocked": false}
	if not write(fresh):
		return false
	apply(fresh)
	return true


func save() -> bool:
	return write(snapshot())


func load_file() -> bool:
	progression.last_error = ""
	progression._write_blocked = false
	progression._archive_corrupt_on_save = false
	if not progression.save_enabled:
		return true
	if not progression.save_path.begins_with("user://"):
		progression._write_blocked = true
		return progression._fail("Save path must be under user://.")
	if not FileAccess.file_exists(progression.save_path):
		# A missing canonical file plus backup can result from interrupted replacement.
		if FileAccess.file_exists(progression.save_path + ".bak"):
			var backup: Dictionary = read(progression.save_path + ".bak")
			if not backup.is_empty():
				apply(backup)
				progression.last_error = "Recovered progression from backup after an interrupted save."
				return true
			progression._write_blocked = true
			return progression._fail("The save backup is invalid; preserved it without overwriting.")
		return true
	var raw: Variant = progression._parse_json(FileAccess.get_file_as_string(progression.save_path))
	if raw is Dictionary and progression._finite_number(raw.get("schema_version")) and raw.schema_version > progression.SAVE_VERSION:
		progression._write_blocked = true
		return progression._fail("Save uses a newer version; it is preserved and saving is disabled.")
	var current: Dictionary = validated(raw)
	if not current.is_empty():
		apply(current)
		return true
	progression._archive_corrupt_on_save = true
	var recovered: Dictionary = read(progression.save_path + ".bak")
	if not recovered.is_empty():
		apply(recovered)
		progression.last_error = "Save was damaged. Recovered its backup; damaged original will be preserved as .corrupt."
		return true
	# Start clean in memory, but preserve the bad file on the first successful save.
	apply({"coins": 0, "total_recruits": 0, "available_recruits": 0, "round_number": 1, "purchased": {}})
	return progression._fail("Save was damaged. Fresh progression started; damaged original will be preserved as .corrupt.")


func snapshot() -> Dictionary:
	return {"schema_version": progression.SAVE_VERSION, "coins": progression.coins, "total_recruits": progression.total_recruits, "available_recruits": progression.available_recruits, "round_number": progression.round_number, "purchased": progression.purchased.duplicate(true), "encounter_stage": progression.encounter_stage, "fair_stage": progression.fair_stage, "uni_stage": progression.uni_stage, "uni_loadout": progression.uni_loadout.duplicate(), "active_area": progression.active_area, "level_select_unlocked": progression.level_select_unlocked}


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
		if progression.catalog_for_area(raw.active_area).is_empty() or not raw.get("level_select_unlocked") is bool:
			return {}
	var normalized: Dictionary = raw.duplicate(true)
	# Old saves never spent recruits. Preserve all prior ranks without charging them.
	normalized.available_recruits = int(raw.available_recruits) if int(raw.schema_version) >= 3 else int(raw.total_recruits)
	normalized.encounter_stage = int(raw.get("encounter_stage", 0))
	normalized.fair_stage = int(raw.get("fair_stage", 0))
	normalized.uni_stage = int(raw.get("uni_stage", 0))
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
	if not normalized.level_select_unlocked:
		if furthest >= 1 and not progression._ranks_complete(_market_gate_definitions(), normalized.purchased):
			return {}
		if furthest >= 2 and not progression._ranks_complete(progression.catalog_for_area("bellmarket"), normalized.purchased):
			return {}
		if furthest >= 3 and not progression._ranks_complete(progression.catalog_for_area("lantern_fair"), normalized.purchased):
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


func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return validated(progression._parse_json(FileAccess.get_file_as_string(path)))


func write(state: Dictionary) -> bool:
	progression.last_error = ""
	if validated(state).is_empty():
		return progression._fail("Progression is invalid; it was not saved.")
	if not progression.save_enabled:
		return true
	if progression._write_blocked:
		return progression._fail("Saving is disabled to preserve an incompatible or damaged save.")
	if not progression.save_path.begins_with("user://"):
		return progression._fail("Save path must be under user://.")
	var temp: String = progression.save_path + ".tmp"
	var backup: String = progression.save_path + ".bak"
	var output: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if output == null:
		return progression._fail("Cannot write progression; earnings remain in memory. Storage error " + str(FileAccess.get_open_error()) + ".")
	output.store_string(JSON.stringify(state, "\t"))
	output.flush()
	var write_error: Error = output.get_error()
	output.close()
	if write_error != OK or read(temp).is_empty():
		return progression._fail("Progression write did not verify; previous save was preserved.")
	if progression._archive_corrupt_on_save and FileAccess.file_exists(progression.save_path):
		if FileAccess.file_exists(progression.save_path + ".corrupt"):
			return progression._fail("A previous .corrupt recovery file already exists; damaged save preserved. Move it aside before saving again.")
		if DirAccess.rename_absolute(progression.save_path, progression.save_path + ".corrupt") != OK:
			return progression._fail("Cannot preserve the damaged save; saving stopped.")
		progression._archive_corrupt_on_save = false
	elif FileAccess.file_exists(progression.save_path):
		# A backup is replaced only with a known-valid canonical save.
		if read(progression.save_path).is_empty():
			return progression._fail("Save changed or is damaged; reload before saving again.")
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			return progression._fail("Cannot rotate the progression backup.")
		if DirAccess.rename_absolute(progression.save_path, backup) != OK:
			return progression._fail("Cannot preserve the previous save.")
	if DirAccess.rename_absolute(temp, progression.save_path) != OK:
		if not FileAccess.file_exists(progression.save_path) and FileAccess.file_exists(backup):
			DirAccess.copy_absolute(backup, progression.save_path)
		return progression._fail("Cannot finish progression save; previous progress preserved.")
	return true
