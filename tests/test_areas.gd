extends SceneTree
## Area persistence checks use dedicated fixture saves, never ordinary progression.

const Progression = preload("res://scripts/progression.gd")
const FIXTURE: String = "user://test_areas_fixture.json"
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("AREAS: " + description)


func fresh() -> RefCounted:
	var state = Progression.new()
	state.save_path = FIXTURE
	state.load_catalog()
	return state


func clean_fixture() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)


func write_fixture(path: String, state: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	file.close()


func fill_village(state: RefCounted) -> void:
	for entry in state.catalog_for_area("bramblewick"):
		state.purchased[entry.id] = state.max_rank(entry.id)


func _run() -> void:
	clean_fixture()
	var state = fresh()
	check(state.active_area == "bramblewick" and state.catalog.size() == 32 and state.all_catalog.size() == 62, "fresh game exposes village circle and validates both catalogs")
	check(state.catalog_for_area("bellmarket").size() == 30 and state.catalog_for_area("unknown").is_empty(), "area catalogs include exactly implemented local nodes")
	check(state.is_area_unlocked("bramblewick") and not state.is_area_unlocked("bellmarket") and not state.is_area_unlocked("unknown"), "only the implemented opening area starts unlocked")
	check(not state.try_travel("bellmarket") and not state.try_travel("unknown", true) and state.active_area == "bramblewick", "locked and unknown travel preserve the current area")
	fill_village(state)
	state.purchased.talk_3 = 1
	check(not state.is_area_unlocked("bellmarket") and not state.try_travel("bellmarket"), "every village rank is needed, including outer second ranks")
	state.purchased.talk_3 = 2
	state.coins = 77
	state.total_recruits = 91
	state.available_recruits = 23
	state.round_number = 18
	state.encounter_stage = 2
	check(state.is_area_unlocked("bellmarket") and not state.level_select_unlocked, "full first circle opens market independently of priest and password")
	check(state.save_progress(), "completed village snapshot is staged successfully")
	var original_bytes: String = FileAccess.get_file_as_string(FIXTURE)
	state.save_path = "user://missing_area_test_directory/progression.json"
	check(not state.try_travel("bellmarket") and state.active_area == "bramblewick" and state.catalog.size() == 32 and not state.level_select_unlocked, "failed travel write changes neither area, catalog nor bypass access")
	check(FileAccess.get_file_as_string(FIXTURE) == original_bytes, "failed travel preserves the prior save bytes")
	state.save_path = FIXTURE
	check(state.try_travel("bellmarket") and state.active_area == "bellmarket" and state.catalog.size() == 30, "successful travel selects the separate market circle")
	check(state.coins == 77 and state.total_recruits == 91 and state.available_recruits == 23 and state.round_number == 18 and state.encounter_stage == 2 and state.purchased.size() == 32, "travel preserves wallets, lifetime history, round, encounters and village ranks")
	check(state.is_circle_complete("bramblewick") and not state.is_circle_complete() and not state.is_circle_complete("bellmarket"), "completion is derived separately for each area")
	var restored = fresh()
	check(restored.load_progress() and restored.active_area == "bellmarket" and restored.catalog.size() == 30 and restored.purchased == state.purchased and restored.encounter_stage == 2, "schema4 reload restores area while validating off-area ranks")
	check(restored.try_travel("bramblewick") and restored.catalog.size() == 32 and restored.try_travel("bellmarket") and restored.purchased == state.purchased, "repeated return travel preserves all progress")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(saved.schema_version == 4 and saved.active_area == "bellmarket" and saved.level_select_unlocked == false and not saved.has("circle_complete"), "schema4 stores area and explicit access without a completion flag")
	write_fixture(FIXTURE, {"broken": true})
	var recovered = fresh()
	check(recovered.load_progress() and recovered.active_area == "bramblewick" and recovered.is_circle_complete(), "corrupt active-area save recovers the valid previous-area backup")
	check(recovered.save_progress() and FileAccess.file_exists(FIXTURE + ".corrupt"), "area recovery preserves damaged bytes before writing")
	_test_existing_market_save()

	clean_fixture()
	var bypass = fresh()
	bypass.save_path = "user://missing_area_test_directory/progression.json"
	check(not bypass.try_travel("bellmarket", true) and not bypass.level_select_unlocked and bypass.active_area == "bramblewick", "failed password travel grants no durable or in-memory access")
	bypass.save_path = FIXTURE
	check(bypass.try_travel("bellmarket", true) and bypass.level_select_unlocked and bypass.purchased.is_empty() and bypass.coins == 0 and bypass.total_recruits == 0, "password travel grants access without fabricating upgrades or resources")
	var bypass_reload = fresh()
	check(bypass_reload.load_progress() and bypass_reload.active_area == "bellmarket" and bypass_reload.level_select_unlocked and bypass_reload.is_area_unlocked("bellmarket"), "validated password access survives restart")
	check(bypass_reload.try_travel("bramblewick") and bypass_reload.try_travel("bellmarket"), "persisted level selection supports return travel without changing completion")

	for version in [1, 2, 3]:
		clean_fixture()
		var legacy: Dictionary = {"schema_version": version, "coins": 19, "total_recruits": 42, "round_number": 7, "purchased": {"run_1": true if version == 1 else 1}}
		if version == 3:
			legacy.available_recruits = 9
		write_fixture(FIXTURE, legacy)
		var legacy_bytes: String = FileAccess.get_file_as_string(FIXTURE)
		var migrated = fresh()
		check(migrated.load_progress() and migrated.active_area == "bramblewick" and not migrated.level_select_unlocked and migrated.coins == 19 and migrated.total_recruits == 42 and migrated.available_recruits == (9 if version == 3 else 42) and migrated.round_number == 7 and migrated.rank("run_1") == 1, "schema%d migrates to village preserving all existing counters and ranks" % version)
		check(FileAccess.get_file_as_string(FIXTURE) == legacy_bytes and migrated.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".bak") == legacy_bytes, "schema%d migration preserves exact original until staged save and backup" % version)

	var base = fresh()
	var valid: Dictionary = base._snapshot()
	var invalid_snapshots: Array[Dictionary] = []
	for bad_area in ["unknown", 2, null]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.active_area = bad_area
		invalid_snapshots.append(invalid)
	for bad_access in [1, "true", null]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.level_select_unlocked = bad_access
		invalid_snapshots.append(invalid)
	var inaccessible: Dictionary = valid.duplicate(true)
	inaccessible.active_area = "bellmarket"
	invalid_snapshots.append(inaccessible)
	var unpaid_market: Dictionary = valid.duplicate(true)
	unpaid_market.purchased.market_run_1 = 1
	invalid_snapshots.append(unpaid_market)
	var missing_area: Dictionary = valid.duplicate(true)
	missing_area.erase("active_area")
	invalid_snapshots.append(missing_area)
	var missing_access: Dictionary = valid.duplicate(true)
	missing_access.erase("level_select_unlocked")
	invalid_snapshots.append(missing_access)
	for index in range(invalid_snapshots.size()):
		clean_fixture()
		write_fixture(FIXTURE, invalid_snapshots[index])
		var invalid = fresh()
		check(not invalid.load_progress() and invalid.active_area == "bramblewick" and invalid.purchased.is_empty() and not invalid.level_select_unlocked, "invalid area snapshot %d cannot activate or grant access" % index)
	clean_fixture()
	valid.schema_version = 5
	write_fixture(FIXTURE, valid)
	var future = fresh()
	var future_bytes: String = FileAccess.get_file_as_string(FIXTURE)
	check(not future.load_progress() and not future.try_travel("bellmarket", true) and FileAccess.get_file_as_string(FIXTURE) == future_bytes, "unsupported future schema remains preserved and blocks travel writes")
	clean_fixture()
	print("AREAS RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_existing_market_save() -> void:
	clean_fixture()
	var original = fresh()
	fill_village(original)
	var village_speed: float = original.run_multiplier()
	var village_frequency: float = 1.0 / original.speech_interval()
	var village_conviction: float = original.conviction_per_phrase()
	# A real pre-expansion schema-4 shape: all village ranks and the former
	# fifteen-node market circle, with no fabricated new purchases or charges.
	var legacy: Dictionary = original._snapshot()
	legacy.active_area = "bellmarket"
	legacy.coins = 81
	legacy.total_recruits = 421
	legacy.available_recruits = 4
	legacy.round_number = 23
	legacy.encounter_stage = 4
	for branch in ["run", "talk", "persuade", "guild", "patron"]:
		for tier in [1, 2, 3]:
			legacy.purchased["market_" + branch + "_" + str(tier)] = 1
	write_fixture(FIXTURE, legacy)
	var original_bytes: String = FileAccess.get_file_as_string(FIXTURE)
	var restored = fresh()
	check(restored.load_progress() and restored.active_area == "bellmarket" and restored.purchased == legacy.purchased and restored.purchased.size() == 47, "old completed market schema4 save retains every village and original market rank")
	check(restored.coins == 81 and restored.total_recruits == 421 and restored.available_recruits == 4 and restored.round_number == 23 and restored.encounter_stage == 4 and not restored.level_select_unlocked, "higher prices never retroactively charge existing market saves or change their history")
	check(is_equal_approx(restored.run_multiplier(), village_speed + 1.05) and is_equal_approx(1.0 / restored.speech_interval(), village_frequency + 1.8) and restored.conviction_per_phrase() == village_conviction + 3.0 and restored.market_donation("guild", 12) == 22 and restored.market_donation("patron", 18) == 33 and restored.has_unlock("helper_unlock"), "all original market benefits and full village carry-over survive unchanged")
	var new_ranks: int = 0
	for branch in ["run", "talk", "persuade", "guild", "patron"]:
		for tier in [4, 5, 6]:
			new_ranks += restored.rank("market_" + branch + "_" + str(tier))
	check(new_ranks == 0 and restored.is_circle_complete("bramblewick") and not restored.is_circle_complete(), "new fifteen ranks begin unowned and expanded market completion is derived from all thirty nodes")
	check(FileAccess.get_file_as_string(FIXTURE) == original_bytes and restored.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".bak") == original_bytes, "loading old market ranks preserves exact original bytes through the next staged backup")
	var round_trip = fresh()
	check(round_trip.load_progress() and round_trip._snapshot() == legacy and not round_trip.is_circle_complete(), "pre-expansion schema4 state round-trips without charges, grants or stale completion")
