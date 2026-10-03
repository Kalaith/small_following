extends SceneTree
## Uses an isolated user:// fixture. Never reads/writes the normal progression save.

const Progression = preload("res://scripts/progression.gd")
const FIXTURE: String = "user://test_progression_fixture.json"
const CATALOG_FIXTURE: String = "user://test_progression_catalog.json"
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
		push_error("FAIL: " + description)


func fresh() -> RefCounted:
	var state = Progression.new()
	state.save_path = FIXTURE
	state.load_catalog()
	return state


func write_fixture(path: String, contents: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()


func clean_fixture() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var path: String = FIXTURE + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if FileAccess.file_exists(CATALOG_FIXTURE):
		DirAccess.remove_absolute(CATALOG_FIXTURE)


func snapshot(version: int, upgrades: Dictionary) -> Dictionary:
	return {"schema_version": version, "coins": 27, "total_recruits": 41, "round_number": 12, "purchased": upgrades}


func legacy_purchases(state: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	for entry in state.catalog:
		result[entry.id] = true
	return result


func _run() -> void:
	clean_fixture()
	var state = fresh()
	check(state.catalog.size() == 9, "nine real definitions load")
	check(state.max_rank("talk_1") == 1 and state.max_rank("talk_3") == 2 and state.rank("talk_3") == 0, "ranks extend outer seals without adding nodes")
	check(state.max_rank("none") == 0 and state.next_cost("none") == 0, "unknown nodes have no purchasable rank")
	check(state.load_progress() and state.coins == 0 and state.round_number == 1, "missing save has fresh defaults")
	check(state.status("none") == "unknown" and state.status("talk_2") == "locked", "unknown and prerequisite states")
	check(state.status("talk_1") == "unaffordable" and not state.try_purchase("talk_1"), "insufficient funds cannot buy")
	state.add_donation(9, 3)
	check(state.coins == 9 and state.total_recruits == 3 and FileAccess.file_exists(FIXTURE), "recruit earnings persist immediately")
	check(state.status("talk_1") == "affordable" and state.try_purchase("talk_1"), "affordable first tier purchases")
	check(state.coins == 3 and state.purchased.has("talk_1"), "purchase charges exact integer price")
	check(not state.try_purchase("talk_1") and state.coins == 3 and state.status("talk_1") == "purchased", "one-time maximum prevents repeated buy")
	check(is_equal_approx(state.speech_interval(), 1.0 / 1.2) and state.conviction_per_phrase() == 1.0 and state.run_multiplier() == 1.0, "talking alters phrase timing only")
	state.round_number = 4
	check(state.save_progress(), "round number persists")
	var restored = fresh()
	check(restored.load_progress() and restored.coins == 3 and restored.total_recruits == 3 and restored.round_number == 4 and restored.purchased.has("talk_1"), "save round trip retains balances, upgrades and round")
	state.save_enabled = false
	state.coins = 100
	check(not state.try_purchase("run_2") and state.coins == 100, "prerequisite enforced even with funds")
	check(state.try_purchase("persuade_1") and state.conviction_per_phrase() == 1.5 and state.run_multiplier() == 1.0, "persuasion changes conviction only")
	check(state.try_purchase("run_1") and is_equal_approx(state.run_multiplier(), 1.15) and state.conviction_per_phrase() == 1.5, "running changes movement multiplier only")
	for id in ["talk_2", "talk_3", "persuade_2", "persuade_3", "run_2", "run_3"]:
		check(state.try_purchase(id), "functional tier: " + id)
	check(is_equal_approx(state.speech_interval(), 0.625) and state.conviction_per_phrase() == 2.5 and is_equal_approx(state.run_multiplier(), 1.45), "all tiers sum their distinct effects")
	check(state.coins == 25 and state.purchased.size() == 9, "all remaining node prices accounted exactly")
	check(state.rank("talk_3") == 1 and state.status("talk_3") == "affordable" and state.next_cost("talk_3") == 18, "owned outer seal offers its second rank at the new price")
	var preview: Dictionary = state.effect_preview("talk_3")
	check(is_equal_approx(preview.current.speech_frequency, 1.6) and is_equal_approx(preview.next.speech_frequency, 1.9) and preview.current.conviction == preview.next.conviction and preview.current.run_multiplier == preview.next.run_multiplier, "rank preview shows absolute current and next values for only its effect")
	check(state.effect_preview("talk_1").next.is_empty() and state.effect_preview("none").next.is_empty(), "maxed and unknown nodes do not advertise another effect")
	check(state.try_purchase("talk_3", 1) and state.rank("talk_3") == 2 and state.coins == 7, "second rank increments once and charges eighteen donations")
	check(not state.try_purchase("talk_3", 1) and state.rank("talk_3") == 2 and state.coins == 7, "stale purchase request cannot spend twice")
	check(state.status("talk_3") == "purchased" and state.next_cost("talk_3") == 0 and not state.try_purchase("talk_3"), "maximum rank has no further cost and rejects purchases")
	check(state.status("persuade_3") == "unaffordable" and not state.try_purchase("persuade_3", 1) and state.rank("persuade_3") == 1 and state.coins == 7, "insufficient funds preserve owned rank and donations")
	var full = fresh()
	full.save_enabled = false
	full.coins = 135
	for entry in full.catalog:
		for desired_rank in range(full.max_rank(entry.id)):
			check(full.try_purchase(entry.id, desired_rank), "purchase each shipped rank: " + entry.id + " rank " + str(desired_rank + 1))
	check(full.coins == 0 and full.purchased.size() == 9, "all twelve purchases cost exactly 135 across the original nine nodes")
	check(is_equal_approx(full.speech_interval(), 1.0 / 1.9) and full.conviction_per_phrase() == 3.0 and is_equal_approx(full.run_multiplier(), 1.6), "full ranks apply their distinct cumulative effects")
	full.coins = 100
	check(not full.try_purchase("run_3", 2) and full.coins == 100, "maximum rank rejects repeated purchase even with sufficient currency")
	var stale = fresh()
	stale.save_enabled = false
	stale.coins = 100
	stale.purchased = {"talk_1": 1, "talk_2": 1}
	check(stale.try_purchase("talk_3", 0) and not stale.try_purchase("talk_3", 0) and stale.coins == 88 and stale.rank("talk_3") == 1, "duplicate first-rank activation does not silently buy second rank")

	var failed = fresh()
	failed.coins = 20
	failed.save_path = "user://missing_progression_test_directory/save.json"
	check(not failed.try_purchase("run_1") and failed.coins == 20 and failed.purchased.is_empty() and not failed.last_error.is_empty(), "failed storage rolls back purchase and exposes error")
	failed.purchased = {"run_1": 1, "run_2": 1, "run_3": 1}
	check(not failed.try_purchase("run_3", 1) and failed.coins == 20 and failed.rank("run_3") == 1 and is_equal_approx(failed.run_multiplier(), 1.45), "failed second-rank save preserves previous rank, effect and currency")
	failed.save_path = "res://invalid_save.json"
	check(not failed.save_progress(), "save path cannot escape user data")

	# The backup contains the previous valid save, not a partially written candidate.
	write_fixture(FIXTURE, "{broken")
	var recovery = fresh()
	check(recovery.load_progress() and recovery.purchased.has("talk_1") and not recovery.last_error.is_empty(), "malformed main recovers validated backup with warning")
	check(recovery.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".corrupt") == "{broken", "recovery preserves exact damaged original")
	write_fixture(FIXTURE, "{broken again")
	var repeat_recovery = fresh()
	check(repeat_recovery.load_progress() and not repeat_recovery.save_progress() and FileAccess.get_file_as_string(FIXTURE) == "{broken again", "second corruption is preserved without overwriting first archive")

	clean_fixture()
	write_fixture(FIXTURE, '{"schema_version":3,"coins":700}')
	var future = fresh()
	check(not future.load_progress() and not future.save_progress() and FileAccess.get_file_as_string(FIXTURE) == '{"schema_version":3,"coins":700}', "future schema blocks writes and stays byte-for-byte intact")

	# Migration retains old progress/effects, then rotates original bytes on the first v2 write.
	clean_fixture()
	var old_text: String = JSON.stringify(snapshot(1, {"talk_1": true, "talk_2": true, "talk_3": true}))
	write_fixture(FIXTURE, old_text)
	var migrated = fresh()
	check(migrated.load_progress() and migrated.last_error.is_empty() and migrated.coins == 27 and migrated.total_recruits == 41 and migrated.round_number == 12 and migrated.rank("talk_3") == 1, "partial v1 save migrates counters and booleans without damage warning")
	check(FileAccess.get_file_as_string(FIXTURE) == old_text and not FileAccess.file_exists(FIXTURE + ".corrupt"), "loading migration leaves original save byte-for-byte intact")
	check(is_equal_approx(migrated.speech_interval(), 0.625) and migrated.conviction_per_phrase() == 1.0 and migrated.run_multiplier() == 1.0, "migration preserves all existing effects without granting unpaid ranks")
	check(migrated.try_purchase("talk_3", 1) and migrated.coins == 9 and migrated.rank("talk_3") == 2, "migrated outer seal can buy exactly its next rank")
	check(FileAccess.get_file_as_string(FIXTURE + ".bak") == old_text and not FileAccess.file_exists(FIXTURE + ".corrupt"), "first v2 write preserves valid old save as exact backup")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(saved.schema_version == 2 and saved.purchased.talk_3 == 2 and not saved.purchased.talk_3 is bool, "new save encodes explicit schema2 numerical ranks")
	var ranked_reload = fresh()
	check(ranked_reload.load_progress() and ranked_reload.rank("talk_3") == 2 and ranked_reload.coins == 9 and ranked_reload.total_recruits == 41 and ranked_reload.round_number == 12, "rank2 save round trip retains progression and counters")
	clean_fixture()
	old_text = JSON.stringify(snapshot(1, legacy_purchases(state)))
	write_fixture(FIXTURE, old_text)
	migrated = fresh()
	check(migrated.load_progress() and migrated.purchased.size() == 9 and migrated.rank("talk_3") == 1 and migrated.rank("persuade_3") == 1 and migrated.rank("run_3") == 1, "all-nine v1 save migrates every old purchase to rank1")
	check(is_equal_approx(migrated.speech_interval(), 0.625) and migrated.conviction_per_phrase() == 2.5 and is_equal_approx(migrated.run_multiplier(), 1.45), "fully purchased legacy save retains exactly its original stats")
	clean_fixture()
	write_fixture(FIXTURE + ".bak", old_text)
	var old_backup = fresh()
	check(old_backup.load_progress() and old_backup.rank("run_3") == 1 and old_backup.coins == 27, "missing main recovers and migrates a v1 backup")
	check(old_backup.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".bak") == old_text, "recovered v1 backup remains intact through first v2 save")
	clean_fixture()
	write_fixture(FIXTURE, "damaged main before migration")
	write_fixture(FIXTURE + ".bak", old_text)
	old_backup = fresh()
	check(old_backup.load_progress() and old_backup.rank("persuade_3") == 1 and old_backup.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".corrupt") == "damaged main before migration" and FileAccess.get_file_as_string(FIXTURE + ".bak") == old_text, "damaged main recovers v1 backup and archives only damaged bytes")
	for invalid_ranks in [{"talk_1": true}, {"talk_1": false}, {"talk_1": 1.5}, {"talk_1": 0}, {"talk_1": -1}, {"talk_1": 2}, {"talk_1": "1"}, {"talk_3": 2}, {"missing": 1}]:
		clean_fixture()
		write_fixture(FIXTURE, JSON.stringify(snapshot(2, invalid_ranks)))
		check(not fresh().load_progress(), "v2 rejects invalid rank or prerequisite: " + JSON.stringify(invalid_ranks))

	clean_fixture()
	write_fixture(FIXTURE, '{"schema_version":1,"coins":-2,"round_number":1,"total_recruits":0,"purchased":{}}')
	var invalid = fresh()
	check(not invalid.load_progress() and invalid.coins == 0 and invalid.save_progress() and FileAccess.file_exists(FIXTURE + ".corrupt"), "invalid counters rejected and original archived on fresh save")
	clean_fixture()
	write_fixture(FIXTURE, '{"schema_version":1,"coins":1,"round_number":1,"total_recruits":0,"purchased":{"run_2":true}}')
	check(not fresh().load_progress(), "save cannot bypass prerequisites")
	clean_fixture()
	state = fresh()
	state.add_donation(9, 3)
	state.add_donation(3)
	DirAccess.remove_absolute(FIXTURE)
	var interrupted = fresh()
	check(interrupted.load_progress() and interrupted.coins == 9 and interrupted.total_recruits == 3, "interrupted replacement with missing main restores backup")

	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	var modified: Dictionary = definitions.duplicate(true)
	modified.upgrades[0].requires = ["talk_3"]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE) and state.catalog.size() == 9, "cyclic catalog rejected without replacing current definitions")
	modified = definitions.duplicate(true)
	modified.upgrades[1].id = "talk_1"
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "duplicate IDs rejected")
	modified = definitions.duplicate(true)
	modified.upgrades[0].ring = 0
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "invalid ritual coordinates rejected")
	modified = definitions.duplicate(true)
	modified.upgrades[0].max_rank = 2
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "rank price count must match maximum")
	modified = definitions.duplicate(true)
	modified.upgrades[6].rank_costs = [12, 0]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "free or negative rank prices rejected")
	modified = definitions.duplicate(true)
	modified.upgrades[0].rank_costs = [7]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "catalog rejects ambiguous first price")
	modified = definitions.duplicate(true)
	modified.upgrades[6].rank_effects = [{"speech_speed_add": 0.2}]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "rank effect count must match maximum")
	modified = definitions.duplicate(true)
	modified.upgrades[6].rank_effects = [{"speech_speed_add": 0.2}, {"unknown_effect": 0.3}]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "unknown rank effect rejected")
	modified = definitions.duplicate(true)
	modified.upgrades[6].rank_effects = [{"speech_speed_add": 0.2}, {"speech_speed_add": 0.0}]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "zero rank effect rejected")
	modified = definitions.duplicate(true)
	modified.upgrades[6].rank_effects = [{"speech_speed_add": 0.3}, {"speech_speed_add": 0.3}]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "catalog rejects ambiguous first effect")
	modified = definitions.duplicate(true)
	for entry in modified.upgrades:
		entry.erase("max_rank")
		entry.erase("rank_costs")
		entry.erase("rank_effects")
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(state.load_catalog(CATALOG_FIXTURE) and state.max_rank("talk_3") == 1, "cost-only graph fixture stays compatible as single-rank catalog")
	clean_fixture()
	print("PROGRESSION RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
