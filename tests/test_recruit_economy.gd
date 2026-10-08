extends SceneTree
## Focused dual-resource checks. Every file uses an isolated user:// test path.

const Progression = preload("res://scripts/progression.gd")
const FIXTURE: String = "user://test_recruit_economy.json"
const CATALOG_FIXTURE: String = "user://test_recruit_economy_catalog.json"
const Balance = preload("res://scripts/balance.gd")
const Expect = preload("res://tests/expect.gd")
## Scenario input: recruitment history beyond what the purchases below need.
const EXTRA_HISTORY: int = 29
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("RECRUIT ECONOMY: " + description)


func fresh(persist: bool = false) -> RefCounted:
	var state = Progression.new()
	state.save_path = FIXTURE
	state.save_enabled = persist
	check(state.load_catalog(), "production catalog loads")
	return state


func write_fixture(path: String, contents: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()


func clean_fixture() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)
	if FileAccess.file_exists(CATALOG_FIXTURE):
		DirAccess.remove_absolute(CATALOG_FIXTURE)


func _run() -> void:
	clean_fixture()
	_test_catalog()
	_test_purchases()
	_test_rewards()
	_test_persistence()
	await _test_scene_ui()
	clean_fixture()
	print("RECRUIT ECONOMY RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_catalog() -> void:
	var state = fresh()
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	var gold_total: int = 0
	var recruit_total: int = 0
	var ranks: int = 0
	var explicit_costs: bool = true
	var running_free: bool = true
	for entry in definitions.upgrades:
		if entry.get("area", "bramblewick") != "bramblewick":
			continue
		explicit_costs = explicit_costs and entry.has("rank_recruit_costs") and entry.rank_recruit_costs.size() == entry.max_rank
		for index in range(int(entry.max_rank)):
			gold_total += int(entry.rank_costs[index])
			recruit_total += int(entry.rank_recruit_costs[index])
			ranks += 1
			var effect: Dictionary = state.find_upgrade(entry.id).rank_effects[index]
			if entry.branch == "run" or effect.has("run_speed_add"):
				running_free = running_free and int(entry.rank_recruit_costs[index]) == 0
	var village_ids: Array[String] = Expect.area_ids(state, "bramblewick")
	check(state.catalog.size() == village_ids.size() and ranks == Expect.area_ranks(state, "bramblewick") and gold_total == Expect.total_cost(state, village_ids), "the loaded village circle matches every node, rank and base gold price in the catalog")
	check(explicit_costs and recruit_total == Expect.total_recruit_cost(state, village_ids), "every village rank declares its recruit cost and the loaded total matches")
	check(running_free, "every movement rank explicitly costs zero recruits")
	check(state.next_recruit_cost("talk_1") == Expect.recruit_cost(state, "talk_1") and state.next_recruit_cost("persuade_1") == Expect.recruit_cost(state, "persuade_1"), "early support ranks charge their catalog recruit prices")
	for invalid in [[], [-1], [1.5], [true], ["1"], [null], [1, 2], [Progression.MAX_COUNTER + 1]]:
		var modified: Dictionary = definitions.duplicate(true)
		modified.upgrades[0].rank_recruit_costs = invalid
		write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
		check(not state.load_catalog(CATALOG_FIXTURE) and state.catalog.size() == Expect.area_ids(state, "bramblewick").size(), "reject malformed recruit costs without replacing catalog: " + JSON.stringify(invalid))
	for branch in ["run", "renamed_movement"]:
		var modified: Dictionary = definitions.duplicate(true)
		modified.upgrades[2].branch = branch
		modified.upgrades[2].rank_recruit_costs = [1]
		write_fixture(CATALOG_FIXTURE, JSON.stringify(modified))
		check(not state.load_catalog(CATALOG_FIXTURE), "movement recruit charges rejected even under branch " + branch)
	var legacy: Dictionary = definitions.duplicate(true)
	for entry in legacy.upgrades:
		entry.erase("rank_recruit_costs")
	write_fixture(CATALOG_FIXTURE, JSON.stringify(legacy))
	check(state.load_catalog(CATALOG_FIXTURE) and state.next_recruit_cost("talk_1") == 0, "catalog fixtures without recruit prices default to zero")


func _test_purchases() -> void:
	var state = fresh()
	state.purchased = {"talk_1": 1, "talk_2": 1}
	state.total_recruits = 100
	var gold: int = Expect.cost(state, "talk_3")
	var recruits: int = Expect.recruit_cost(state, "talk_3")
	var second_gold: int = Expect.cost(state, "talk_3", 1)
	var second_recruits: int = Expect.recruit_cost(state, "talk_3", 1)
	# [gold held, recruits held, gold missing, recruits missing]
	for balance in [[gold - 1, recruits, 1, 0], [gold, recruits - 1, 0, 1], [gold - 2, recruits - 2, 2, 2]]:
		state.coins = balance[0]
		state.available_recruits = balance[1]
		var before: Dictionary = state._snapshot()
		var offer: Dictionary = state.purchase_state("talk_3")
		check(offer.status == "unaffordable" and offer.missing_gold == balance[2] and offer.missing_recruits == balance[3], "affordability identifies exact missing resources: " + str(balance))
		check(not state.try_purchase("talk_3", 0) and state._snapshot() == before, "short purchase spends neither resource and grants no rank: " + str(balance))
		check(state.last_error.contains("rank 1") and (balance[2] == 0 or state.last_error.contains("donations")) and (balance[3] == 0 or state.last_error.contains("recruit")), "failed purchase explains its rank and missing resource")
	state.coins = gold
	state.available_recruits = recruits
	check(state.try_purchase("talk_3", 0) and state.coins == 0 and state.available_recruits == 0 and state.total_recruits == 100 and state.rank("talk_3") == 1, "exact funds atomically buy one rank while preserving lifetime history")
	check(state.next_cost("talk_3") == second_gold and state.next_recruit_cost("talk_3") == second_recruits, "second rank uses its own gold and recruit prices")
	state.coins = second_gold
	state.available_recruits = second_recruits
	var before: Dictionary = state._snapshot()
	check(not state.try_purchase("talk_3", 0) and state._snapshot() == before, "stale activation cannot spend the next rank's resources")
	check(state.try_purchase("talk_3", 1) and state.coins == 0 and state.available_recruits == 0 and state.total_recruits == 100 and state.rank("talk_3") == 2, "second rank spends its exact dual price once")
	before = state._snapshot()
	check(not state.try_purchase("talk_3", 2) and not state.try_purchase("talk_3", 1) and state._snapshot() == before, "maximum and repeated rank requests never spend either resource")
	check(state.next_recruit_cost("talk_3") == 0 and state.next_recruit_cost("missing") == 0, "maxed and unknown nodes have no next recruit cost")
	state.coins = Expect.cost(state, "run_1")
	check(state.try_purchase("run_1", 0) and state.coins == 0 and state.available_recruits == 0, "running remains purchasable with gold and no available recruits")
	state.coins = 100
	state.available_recruits = 100
	before = state._snapshot()
	check(not state.try_purchase("meadow_1", 0) and not state.try_purchase("missing", 0) and state._snapshot() == before, "locked and unknown purchases preserve both resources")
	var full = fresh()
	var all_ids: Array[String] = Expect.area_ids(full, "bramblewick")
	full.coins = Expect.total_cost(full, all_ids)
	full.available_recruits = Expect.total_recruit_cost(full, all_ids)
	full.total_recruits = full.available_recruits + EXTRA_HISTORY
	var history: int = full.total_recruits
	for entry in full.catalog:
		for expected_rank in range(full.max_rank(entry.id)):
			check(full.try_purchase(entry.id, expected_rank), "buy existing catalog rank: %s/%d" % [entry.id, expected_rank + 1])
	check(full.coins == 0 and full.available_recruits == 0 and full.total_recruits == history and full.is_circle_complete(), "before any debate victory all ranks cost exactly their catalog gold and recruits; zero balance still completes the demo")
	full.purchased.talk_3 = 1
	full.available_recruits = 279
	check(not full.is_circle_complete(), "abundant recruits cannot replace a missing purchased rank")


func _test_rewards() -> void:
	var state = fresh()
	var start_gold: int = Expect.cost(state, "talk_1") + 3
	var start_recruits: int = Expect.recruit_cost(state, "talk_1") + 2
	state.add_donation(start_gold, start_recruits)
	check(state.coins == start_gold and state.available_recruits == start_recruits and state.total_recruits == start_recruits, "recruitment events credit both recruit counts once")
	state.try_purchase("talk_1", 0)
	state.add_donation(3)
	var coins: int = start_gold - Expect.cost(state, "talk_1") + 3
	var available: int = start_recruits - Expect.recruit_cost(state, "talk_1") + 1
	check(state.coins == coins and state.available_recruits == available and state.total_recruits == start_recruits + 1, "later recruitment refills available recruits without erasing past assignment")
	state.add_donation(12, 0)
	coins += 12
	check(state.coins == coins and state.available_recruits == available and state.total_recruits == start_recruits + 1, "a gold-only reward cannot create recruits")
	var before: Dictionary = state._snapshot()
	state.add_donation(-1, 1)
	state.add_donation(1, -1)
	check(state._snapshot() == before, "negative rewards cannot reduce or duplicate resources")
	for entry in state.catalog:
		state.purchased[entry.id] = state.max_rank(entry.id)
	coins += int(Expect.opponent(0).reward)
	check(state.complete_encounter(0) and state.coins == coins and state.available_recruits == available + 1 and state.total_recruits == start_recruits + 2, "opponent victory credits its reward and one recruit to each count")
	before = state._snapshot()
	check(not state.complete_encounter(0) and state._snapshot() == before, "duplicate opponent victory credits neither count twice")
	state.save_enabled = true
	state.save_path = "user://missing_recruit_economy_directory/save.json"
	state.add_donation(3, 1)
	check(state.coins == coins + 3 and state.available_recruits == available + 2 and state.total_recruits == start_recruits + 3 and not state.last_error.is_empty(), "earned resources stay in memory when persistence fails")
	state.save_enabled = false
	state.coins = Progression.MAX_COUNTER - 1
	state.total_recruits = Progression.MAX_COUNTER - 1
	state.available_recruits = Progression.MAX_COUNTER - 3
	state.add_donation(9223372036854775807, 9223372036854775807)
	check(state.coins == Progression.MAX_COUNTER and state.available_recruits == Progression.MAX_COUNTER and state.total_recruits == Progression.MAX_COUNTER, "large rewards saturate counters without overflow or underflow")


func _test_persistence() -> void:
	clean_fixture()
	var state = fresh(true)
	state.add_donation(30, 10)
	check(state.try_purchase("talk_1", 0), "dual-resource purchase saves successfully")
	var restored = fresh(true)
	check(restored.load_progress() and restored.coins == 30 - Expect.cost(state, "talk_1") and restored.available_recruits == 10 - Expect.recruit_cost(state, "talk_1") and restored.total_recruits == 10 and restored.rank("talk_1") == 1, "reload retains spent recruits separately from lifetime events")
	var saved_text: String = FileAccess.get_file_as_string(FIXTURE)
	state.save_path = "user://missing_recruit_economy_directory/save.json"
	var before: Dictionary = state._snapshot()
	check(not state.try_purchase("talk_2", 0) and state._snapshot() == before and FileAccess.get_file_as_string(FIXTURE) == saved_text and not state.last_error.is_empty(), "failed candidate write rolls back rank and both balances and preserves saved bytes")
	for version in [1, 2]:
		clean_fixture()
		var old: Dictionary = {"schema_version": version, "coins": 54, "total_recruits": 279, "round_number": 12, "purchased": {"talk_1": true if version == 1 else 1, "talk_2": true if version == 1 else 1, "talk_3": true if version == 1 else 2}}
		var old_text: String = JSON.stringify(old)
		write_fixture(FIXTURE, old_text)
		var migrated = fresh(true)
		check(migrated.load_progress() and migrated.coins == 54 and migrated.available_recruits == 279 and migrated.total_recruits == 279 and migrated.round_number == 12 and migrated.rank("talk_3") == (1 if version == 1 else 2), "schema %d retains owned ranks and grants old event count without retroactive charges" % version)
		check(FileAccess.get_file_as_string(FIXTURE) == old_text and migrated.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".bak") == old_text, "schema %d migration preserves old bytes until a backed-up save" % version)
		var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
		check(current.schema_version == Progression.SAVE_VERSION and current.available_recruits == 279 and current.total_recruits == 279, "schema %d writes separate available and lifetime counts" % version)
		var again = fresh(true)
		check(again.load_progress() and again.available_recruits == 279 and again.total_recruits == 279 and again.purchased == migrated.purchased, "migration does not duplicate recruits on reload")
	clean_fixture()
	state = fresh(true)
	state.add_donation(30, 10)
	state.try_purchase("talk_1", 0)
	state.save_progress()
	var invalid_text: String = "{broken recruit economy save"
	write_fixture(FIXTURE, invalid_text)
	var recovered = fresh(true)
	check(recovered.load_progress() and recovered.available_recruits == 10 - Expect.recruit_cost(state, "talk_1") and recovered.total_recruits == 10 and recovered.rank("talk_1") == 1 and not recovered.last_error.is_empty(), "backup recovery preserves spent recruits and lifetime history together")
	check(recovered.save_progress() and FileAccess.get_file_as_string(FIXTURE + ".corrupt") == invalid_text, "recovery preserves the damaged original")
	var valid: Dictionary = recovered._snapshot()
	for invalid in [-1, 11, 0.5, true, "9", null]:
		clean_fixture()
		var broken: Dictionary = valid.duplicate(true)
		broken.available_recruits = invalid
		write_fixture(FIXTURE, JSON.stringify(broken))
		var rejected = fresh(true)
		check(not rejected.load_progress() and rejected.available_recruits == 0 and rejected.total_recruits == 0 and not rejected.last_error.is_empty(), "invalid schema3 available counter fails gracefully: " + str(invalid))
	clean_fixture()
	var missing: Dictionary = valid.duplicate(true)
	missing.erase("available_recruits")
	write_fixture(FIXTURE, JSON.stringify(missing))
	check(not fresh(true).load_progress(), "schema3 cannot silently recreate a missing available balance")
	clean_fixture()
	var future_text: String = '{"schema_version":5,"coins":27,"available_recruits":6}'
	write_fixture(FIXTURE, future_text)
	var future = fresh(true)
	check(not future.load_progress() and not future.save_progress() and FileAccess.get_file_as_string(FIXTURE) == future_text, "unsupported future save is preserved without crashing or overwriting")


func _test_scene_ui() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.advance_round(100.0)
	await process_frame
	var state = scene.progression
	var screen = scene.ritual_screen
	var group = scene.groups[0]
	var phrases: float = ceilf(Balance.number("village.listener.conviction"))
	group.tick_persuasion(phrases, 1.0, 1.0)
	check(state.coins == Balance.integer("village.listener.donation") and state.available_recruits == 1 and state.total_recruits == 1, "real gathering event credits both recruit counters once")
	var before: Dictionary = state._snapshot()
	check(not group.recruit_listener(0) and state._snapshot() == before, "same listener cannot double-credit spendable or lifetime recruits")
	group.reset_round()
	group.tick_persuasion(phrases, 1.0, 1.0)
	check(state.available_recruits == 2 and state.total_recruits == 2, "audience reset permits another event in both counters")
	state.total_recruits = 100
	state.available_recruits = 0
	var talk_gold: int = Expect.cost(state, "talk_1")
	var talk_recruits: int = Expect.recruit_cost(state, "talk_1")
	state.coins = talk_gold
	screen.select_node("talk_1")
	check(screen.purchase_button.disabled and screen.purchase_button.text.contains("%d donations + %d recruit" % [talk_gold, talk_recruits]) and screen._status_label.text.contains("%d more recruit" % talk_recruits) and not screen._status_label.text.contains("more donations"), "recruit-only shortage disables purchase and labels both rank costs")
	check(screen.node_picker.text.contains("needs resources") and not screen.node_picker.text.contains("needs donations"), "node picker does not mislabel a recruit-only shortage as missing donations")
	check(screen._recruits_label.text.contains("0  recruits available") and screen._lifetime_label.text.contains("100 lifetime recruits"), "ritual separately labels available recruits and lifetime recruitment")
	check(screen._node_description.text.contains("followers") and screen._node_description.text.contains("crowd"), "eligible rank explains followers' supporting role")
	state.coins = 0
	screen.update_state()
	check(screen.purchase_button.disabled and screen._status_label.text.contains("%d more donations" % talk_gold) and screen._status_label.text.contains("%d more recruit" % talk_recruits), "combined shortage names both missing resources")
	before = state._snapshot()
	screen.purchase_button.pressed.emit()
	check(state._snapshot() == before, "unaffordable button action spends neither resource")
	state.coins = Expect.cost(state, "run_1")
	screen.select_node("run_1")
	check(not screen.purchase_button.disabled and screen.purchase_button.text.contains("gold only") and not screen.purchase_button.text.contains("recruits"), "running button remains enabled and explicitly gold-only at zero recruits")
	screen.purchase_button.pressed.emit()
	check(state.rank("run_1") == 1 and state.available_recruits == 0, "running button buys its rank without assigning recruits")
	state.purchased.talk_1 = 1
	state.purchased.talk_2 = 1
	var first: Array[int] = [Expect.cost(state, "talk_3"), Expect.recruit_cost(state, "talk_3")]
	var second: Array[int] = [Expect.cost(state, "talk_3", 1), Expect.recruit_cost(state, "talk_3", 1)]
	state.coins = first[0] + second[0]
	state.available_recruits = first[1] + second[1]
	screen.select_node("talk_3")
	check(not screen.purchase_button.disabled and screen.purchase_button.text.contains("rank 1") and screen.purchase_button.text.contains("%d donations + %d recruit" % first), "first-rank button exposes exact dual-resource price")
	screen.purchase_button.pressed.emit()
	check(state.rank("talk_3") == 1 and state.coins == second[0] and state.available_recruits == second[1] and state.total_recruits == 100, "first-rank UI action spends both resources once and preserves lifetime history")
	check(not screen.purchase_button.disabled and screen.purchase_button.text.contains("rank 2") and screen.purchase_button.text.contains("%d donations + %d recruit" % second), "selection refreshes to the second rank's specific costs")
	screen.purchase_button.pressed.emit()
	check(state.rank("talk_3") == 2 and state.coins == 0 and state.available_recruits == 0 and state.total_recruits == 100 and screen.purchase_button.disabled, "second-rank UI action spends exact remaining resources and disables maximum rank")
	scene.set_ritual_visible(false)
	check(scene.stats_label.text.contains("0 recruits available") and not scene.stats_label.text.contains("100"), "village HUD shows spendable recruits after purchases")
	scene.queue_free()
	await process_frame
