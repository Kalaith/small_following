extends SceneTree
## Uses an isolated user:// fixture. Never reads/writes the normal progression save.

const Progression = preload("res://scripts/progression.gd")
const FIXTURE: String = "user://test_progression_fixture.json"
const CATALOG_FIXTURE: String = "user://test_progression_catalog.json"
const Balance = preload("res://scripts/balance.gd")
const Expect = preload("res://tests/expect.gd")
## Scenario inputs: donations left over after a purchase, and the counters
## written into legacy save fixtures. These are not balance values.
const SPARE: int = 3
const FIXTURE_COINS: int = 27
const FIXTURE_RECRUITS: int = 41
const FIXTURE_ROUND: int = 12
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
	return {"schema_version": version, "coins": FIXTURE_COINS, "total_recruits": FIXTURE_RECRUITS, "round_number": FIXTURE_ROUND, "purchased": upgrades}


func legacy_purchases(state: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	for entry in state.catalog.slice(0, 9):
		result[entry.id] = true
	return result


func _run() -> void:
	clean_fixture()
	var state = fresh()
	var village_ids: Array[String] = Expect.area_ids(state, "bramblewick")
	var core: Array[String] = []
	for entry in state.catalog.slice(0, 9):
		core.append(String(entry.id))
	var base_groups: int = Balance.list("village.gatherings").size()
	check(state.catalog.size() == village_ids.size(), "every implemented village definition loads")
	var ranks_match: bool = true
	for id in village_ids:
		ranks_match = ranks_match and state.max_rank(id) == Expect.max_rank(state, id)
	check(ranks_match and state.max_rank("talk_1") == 1 and state.max_rank("talk_3") > 1 and state.rank("talk_3") == 0, "ranks extend outer seals without adding nodes")
	check(state.max_rank("none") == 0 and state.next_cost("none") == 0, "unknown nodes have no purchasable rank")
	check(state.load_progress() and state.coins == 0 and state.round_number == 1, "missing save has fresh defaults")
	check(state.status("none") == "unknown" and state.status("talk_2") == "locked", "unknown and prerequisite states")
	check(state.status("talk_1") == "unaffordable" and not state.try_purchase("talk_1"), "insufficient funds cannot buy")
	var talk_price: int = Expect.cost(state, "talk_1")
	var earned_recruits: int = Expect.recruit_cost(state, "talk_1") + SPARE
	state.add_donation(talk_price + SPARE, earned_recruits)
	check(state.coins == talk_price + SPARE and state.total_recruits == earned_recruits and FileAccess.file_exists(FIXTURE), "recruit earnings persist immediately")
	check(state.status("talk_1") == "affordable" and state.try_purchase("talk_1"), "affordable first tier purchases")
	check(state.coins == SPARE and state.purchased.has("talk_1"), "purchase charges exact integer price")
	check(not state.try_purchase("talk_1") and state.coins == SPARE and state.status("talk_1") == "purchased", "one-time maximum prevents repeated buy")
	check(is_equal_approx(state.speech_interval(), 1.0 / Expect.speech_frequency(state, ["talk_1"])) and state.conviction_per_phrase() == 1.0 and state.run_multiplier() == 1.0, "talking alters phrase timing only")
	state.round_number = 4
	check(state.save_progress(), "round number persists")
	var restored = fresh()
	check(restored.load_progress() and restored.coins == SPARE and restored.total_recruits == earned_recruits and restored.round_number == 4 and restored.purchased.has("talk_1"), "save round trip retains balances, upgrades and round")
	state.save_enabled = false
	state.coins = 1000
	state.total_recruits = 1000
	state.available_recruits = 1000
	check(not state.try_purchase("run_2") and state.coins == 1000, "prerequisite enforced even with funds")
	check(state.try_purchase("persuade_1") and is_equal_approx(state.conviction_per_phrase(), Expect.conviction(state, ["persuade_1"])) and state.run_multiplier() == 1.0, "persuasion changes conviction only")
	check(state.try_purchase("run_1") and is_equal_approx(state.run_multiplier(), Expect.run_multiplier(state, ["run_1"])) and is_equal_approx(state.conviction_per_phrase(), Expect.conviction(state, ["persuade_1"])), "running changes movement multiplier only")
	for id in ["talk_2", "talk_3", "persuade_2", "persuade_3", "run_2", "run_3"]:
		check(state.try_purchase(id), "functional tier: " + id)
	var first_ranks: Dictionary = {}
	for id in core:
		first_ranks[id] = 1
	check(is_equal_approx(state.speech_interval(), 1.0 / Expect.speech_frequency(state, first_ranks)) and is_equal_approx(state.conviction_per_phrase(), Expect.conviction(state, first_ranks)) and is_equal_approx(state.run_multiplier(), Expect.run_multiplier(state, first_ranks)), "all tiers sum their distinct effects")
	check(state.coins == 1000 - Expect.total_cost(state, core, first_ranks) + talk_price and state.purchased.size() == core.size(), "all remaining node prices accounted exactly")
	check(state.rank("talk_3") == 1 and state.status("talk_3") == "affordable" and state.next_cost("talk_3") == Expect.cost(state, "talk_3", 1), "owned outer seal offers its second rank at its own price")
	var preview: Dictionary = state.effect_preview("talk_3")
	check(is_equal_approx(preview.current.speech_frequency, Expect.speech_frequency(state, first_ranks)) and is_equal_approx(preview.next.speech_frequency, Expect.speech_frequency(state, first_ranks) + Expect.effect(state, "talk_3", "speech_speed_add", 1)) and preview.current.conviction == preview.next.conviction and preview.current.run_multiplier == preview.next.run_multiplier, "rank preview shows absolute current and next values for only its effect")
	check(state.effect_preview("talk_1").next.is_empty() and state.effect_preview("none").next.is_empty(), "maxed and unknown nodes do not advertise another effect")
	# Leave exactly one donation short of the persuasion seal's second rank afterwards.
	var short_of_persuade: int = Expect.cost(state, "persuade_3", 1) - 1
	state.coins = Expect.cost(state, "talk_3", 1) + short_of_persuade
	check(state.try_purchase("talk_3", 1) and state.rank("talk_3") == 2 and state.coins == short_of_persuade, "second rank increments once and charges its price")
	check(not state.try_purchase("talk_3", 1) and state.rank("talk_3") == 2 and state.coins == short_of_persuade, "stale purchase request cannot spend twice")
	check(state.status("talk_3") == "purchased" and state.next_cost("talk_3") == 0 and not state.try_purchase("talk_3"), "maximum rank has no further cost and rejects purchases")
	check(state.status("persuade_3") == "unaffordable" and not state.try_purchase("persuade_3", 1) and state.rank("persuade_3") == 1 and state.coins == short_of_persuade, "insufficient funds preserve owned rank and donations")
	var full = fresh()
	full.save_enabled = false
	full.coins = Expect.total_cost(full, core)
	full.total_recruits = 1000
	full.available_recruits = 1000
	for id in core:
		for desired_rank in range(full.max_rank(id)):
			check(full.try_purchase(id, desired_rank), "purchase each shipped rank: " + id + " rank " + str(desired_rank + 1))
	check(full.coins == 0 and full.purchased.size() == core.size(), "every rank of the original nine nodes costs exactly its catalog total")
	check(is_equal_approx(full.speech_interval(), 1.0 / Expect.speech_frequency(full, core)) and is_equal_approx(full.conviction_per_phrase(), Expect.conviction(full, core)) and is_equal_approx(full.run_multiplier(), Expect.run_multiplier(full, core)), "full ranks apply their distinct cumulative effects")
	full.coins = 100
	check(not full.try_purchase("run_3", Expect.max_rank(full, "run_3")) and full.coins == 100, "maximum rank rejects repeated purchase even with sufficient currency")
	check(full.status("talk_4") == "locked" and full.status("run_4") == "locked" and full.status("east_1") == "locked", "new tiers require gathering invitations")
	check(full.gathering_count() == base_groups and full.effect_preview("meadow_1").next.gatherings == base_groups + 1, "unlock preview counts actual groups")
	var expansion: Array[String] = ["meadow_1", "talk_4", "run_4", "east_1", "talk_5", "run_5"]
	full.coins = Expect.total_cost(full, expansion)
	for id in expansion:
		var before_coins: int = full.coins
		var price: int = full.next_cost(id)
		check(price == Expect.cost(full, id) and full.try_purchase(id, 0) and full.coins == before_coins - price, "expansion purchase charges exact price: " + id)
		check(not full.try_purchase(id, 0) and not full.try_purchase(id, 1) and full.coins == before_coins - price, "stale and maximum expansion purchases cannot charge: " + id)
	var expanded: Array[String] = core + expansion
	check(full.coins == 0 and full.gathering_count() == base_groups + Balance.list("village.invited_gatherings").size() and is_equal_approx(full.speech_interval(), 1.0 / Expect.speech_frequency(full, expanded)) and is_equal_approx(full.run_multiplier(), Expect.run_multiplier(full, expanded)) and is_equal_approx(full.conviction_per_phrase(), Expect.conviction(full, expanded)), "six expansion nodes cost their catalog total and apply distinct effects")
	check(full.effect_preview("helper_1").current.helpers == 0 and full.effect_preview("helper_1").next.helpers == 1, "helper preview explains one unlocked actor")
	full.coins = Expect.cost(full, "helper_1")
	check(full.try_purchase("helper_1", 0) and full.coins == 0 and full.has_unlock("helper_unlock"), "one helper costs its catalog price")
	# Town resistance: each convinced opponent raises unbought village prices.
	var resist = fresh()
	resist.save_enabled = false
	check(resist.resistance_price_multiplier() == 1.0 and resist.next_cost("talk_1") == Expect.cost(resist, "talk_1"), "no resistance before the first debate victory")
	resist.encounter_stage = 2
	check(Expect.resistance(2) > 1.0 and is_equal_approx(resist.resistance_price_multiplier(), Expect.resistance(2)) and resist.next_cost("talk_1") == Expect.resisted_cost(resist, "talk_1", 0, 2) and resist.next_cost("talk_3") == Expect.resisted_cost(resist, "talk_3", 0, 2), "two victories raise village prices by the resistance step, rounded")
	check(resist.next_cost("market_run_1") == Expect.cost(resist, "market_run_1"), "market prices ignore Bramblewick's resistance")
	resist.coins = Expect.resisted_cost(resist, "talk_1", 0, 2)
	resist.total_recruits = Expect.recruit_cost(resist, "talk_1")
	resist.available_recruits = resist.total_recruits
	check(resist.purchase_state("talk_1").gold_cost == resist.coins and resist.status("talk_1") == "affordable", "the purchase panel prices with the same resistance")
	full.save_enabled = true
	check(full.save_progress(), "expanded ranks save using current schema")
	var expanded_reload = fresh()
	check(expanded_reload.load_progress() and expanded_reload.purchased == full.purchased and expanded_reload.gathering_count() == full.gathering_count(), "expanded rank round trip restores invitations")
	check(expanded_reload.has_unlock("helper_unlock"), "helper unlock survives current-schema round trip")
	var stale = fresh()
	stale.save_enabled = false
	stale.coins = 100
	stale.total_recruits = 1000
	stale.available_recruits = 1000
	stale.purchased = {"talk_1": 1, "talk_2": 1}
	check(stale.try_purchase("talk_3", 0) and not stale.try_purchase("talk_3", 0) and stale.coins == 100 - Expect.cost(stale, "talk_3") and stale.rank("talk_3") == 1, "duplicate first-rank activation does not silently buy second rank")

	var failed = fresh()
	# Enough for either purchase, so only the failed save can refuse them.
	failed.coins = maxi(Expect.cost(failed, "run_1"), Expect.cost(failed, "run_3", 1))
	var failed_coins: int = failed.coins
	failed.save_path = "user://missing_progression_test_directory/save.json"
	check(not failed.try_purchase("run_1") and failed.coins == failed_coins and failed.purchased.is_empty() and not failed.last_error.is_empty(), "failed storage rolls back purchase and exposes error")
	failed.purchased = {"run_1": 1, "run_2": 1, "run_3": 1}
	check(not failed.try_purchase("run_3", 1) and failed.coins == failed_coins and failed.rank("run_3") == 1 and is_equal_approx(failed.run_multiplier(), Expect.run_multiplier(failed, {"run_1": 1, "run_2": 1, "run_3": 1})), "failed second-rank save preserves previous rank, effect and currency")
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
	write_fixture(FIXTURE, '{"schema_version":5,"coins":700}')
	var future = fresh()
	check(not future.load_progress() and not future.save_progress() and FileAccess.get_file_as_string(FIXTURE) == '{"schema_version":5,"coins":700}', "future schema blocks writes and stays byte-for-byte intact")

	# Migration retains old progress/effects, then rotates original bytes on the first current-schema write.
	clean_fixture()
	var old_text: String = JSON.stringify(snapshot(1, {"talk_1": true, "talk_2": true, "talk_3": true}))
	write_fixture(FIXTURE, old_text)
	var migrated = fresh()
	check(migrated.load_progress() and migrated.last_error.is_empty() and migrated.coins == FIXTURE_COINS and migrated.total_recruits == FIXTURE_RECRUITS and migrated.round_number == FIXTURE_ROUND and migrated.rank("talk_3") == 1, "partial v1 save migrates counters and booleans without damage warning")
	check(FileAccess.get_file_as_string(FIXTURE) == old_text and not FileAccess.file_exists(FIXTURE + ".corrupt"), "loading migration leaves original save byte-for-byte intact")
	var talk_firsts: Dictionary = {"talk_1": 1, "talk_2": 1, "talk_3": 1}
	check(is_equal_approx(migrated.speech_interval(), 1.0 / Expect.speech_frequency(migrated, talk_firsts)) and migrated.conviction_per_phrase() == 1.0 and migrated.run_multiplier() == 1.0, "migration preserves all existing effects without granting unpaid ranks")
	var after_second_rank: int = FIXTURE_COINS - Expect.cost(migrated, "talk_3", 1)
	check(after_second_rank >= 0 and migrated.try_purchase("talk_3", 1) and migrated.coins == after_second_rank and migrated.rank("talk_3") == 2, "migrated outer seal can buy exactly its next rank")
	check(FileAccess.get_file_as_string(FIXTURE + ".bak") == old_text and not FileAccess.file_exists(FIXTURE + ".corrupt"), "first current-schema write preserves valid old save as exact backup")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(saved.schema_version == Progression.SAVE_VERSION and saved.purchased.talk_3 == 2 and not saved.purchased.talk_3 is bool, "new save encodes current schema with numerical ranks")
	var ranked_reload = fresh()
	check(ranked_reload.load_progress() and ranked_reload.rank("talk_3") == 2 and ranked_reload.coins == after_second_rank and ranked_reload.total_recruits == FIXTURE_RECRUITS and ranked_reload.round_number == FIXTURE_ROUND, "rank2 save round trip retains progression and counters")
	clean_fixture()
	old_text = JSON.stringify(snapshot(1, legacy_purchases(state)))
	write_fixture(FIXTURE, old_text)
	migrated = fresh()
	check(migrated.load_progress() and migrated.purchased.size() == legacy_purchases(state).size() and migrated.rank("talk_3") == 1 and migrated.rank("persuade_3") == 1 and migrated.rank("run_3") == 1, "all-nine v1 save migrates every old purchase to rank1")
	var legacy_ranks: Dictionary = {}
	for id in legacy_purchases(state):
		legacy_ranks[id] = 1
	check(is_equal_approx(migrated.speech_interval(), 1.0 / Expect.speech_frequency(migrated, legacy_ranks)) and is_equal_approx(migrated.conviction_per_phrase(), Expect.conviction(migrated, legacy_ranks)) and is_equal_approx(migrated.run_multiplier(), Expect.run_multiplier(migrated, legacy_ranks)), "fully purchased legacy save retains exactly its original stats")
	clean_fixture()
	write_fixture(FIXTURE + ".bak", old_text)
	var old_backup = fresh()
	check(old_backup.load_progress() and old_backup.rank("run_3") == 1 and old_backup.coins == FIXTURE_COINS, "missing main recovers and migrates a v1 backup")
	check(old_backup.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".bak") == old_text, "recovered v1 backup remains intact through first current-schema save")
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
	for value in [0.5, 2.0]:
		modified = definitions.duplicate(true)
		modified.upgrades[9].effect = {"meadow_unlock": value}
		write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
		check(not state.load_catalog(CATALOG_FIXTURE), "unlock rejects nonbinary count: " + str(value))
	modified = definitions.duplicate(true)
	modified.upgrades[12].effect = {"meadow_unlock": 1}
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "same gathering cannot be unlocked by duplicate effects")
	modified = definitions.duplicate(true)
	modified.upgrades[15].max_rank = 2
	modified.upgrades[15].rank_costs = [30, 30]
	modified.upgrades[15].rank_recruit_costs = [5, 5]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE), "helper unlock cannot advertise unimplemented extra helpers through ranks")
	modified = definitions.duplicate(true)
	modified.upgrades[0].requires = ["talk_3"]
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(not state.load_catalog(CATALOG_FIXTURE) and state.catalog.size() == Expect.area_ids(state, "bramblewick").size(), "cyclic catalog rejected without replacing current definitions")
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
		entry.erase("rank_recruit_costs")
		entry.erase("rank_effects")
	write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
	check(state.load_catalog(CATALOG_FIXTURE) and state.max_rank("talk_3") == 1, "cost-only graph fixture stays compatible as single-rank catalog")
	clean_fixture()
	print("PROGRESSION RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
