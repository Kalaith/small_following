extends SceneTree
## Independent market choices and their actual progression effects.

const Progression = preload("res://scripts/progression.gd")
const CATALOG_FIXTURE: String = "user://test_market_catalog_fixture.json"
const BRANCHES: Array[String] = ["run", "talk", "persuade", "guild", "patron"]
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
		push_error("MARKET PROGRESSION: " + description)


func fresh_market() -> RefCounted:
	var state = Progression.new()
	state.save_enabled = false
	state.load_catalog()
	state.try_travel("bellmarket", true)
	return state


func choices(state: RefCounted) -> int:
	var count: int = 0
	for entry in state.catalog:
		count += int(state.status(entry.id) == "affordable")
	return count


func _run() -> void:
	var state = fresh_market()
	state.coins = 120
	check(choices(state) == 5 and state.available_recruits == 0, "120 gold and no recruits offers all five independent opening choices")
	for branch in BRANCHES:
		var id: String = "market_" + branch + "_1"
		check(state.next_cost(id) == 120 and state.next_recruit_cost(id) == 0 and state.find_upgrade(id).requires.is_empty(), "root is equally affordable without other paths: " + branch)
	check(state.status("market_run_2") == "locked" and not state.try_purchase("market_run_2") and state.coins == 120, "market successor enforces its own prerequisite without spending")
	check(state.try_purchase("market_run_1", 0) and is_equal_approx(state.run_multiplier(), 1.3) and state.speech_interval() == 1.0 and state.conviction_per_phrase() == 1.0, "speed path changes running alone")
	check(not state.try_purchase("market_run_1", 0) and not state.try_purchase("market_run_1", 1) and state.coins == 0, "stale and maximum market purchases spend nothing")
	state.coins = 20000
	state.total_recruits = 1000
	state.available_recruits = 1000
	check(choices(state) == 5, "buying a root replaces it with its successor while four other paths stay available")
	check(state.try_purchase("market_talk_1", 0) and is_equal_approx(state.speech_interval(), 1.0 / 2.0) and state.conviction_per_phrase() == 1.0 and is_equal_approx(state.run_multiplier(), 1.3), "speech path changes frequency independently")
	check(state.try_purchase("market_persuade_1", 0) and state.conviction_per_phrase() == 2.5 and is_equal_approx(state.speech_interval(), 1.0 / 2.0), "conviction path changes phrase strength independently")
	check(not state.has_unlock("market_guild_unlock") and not state.has_unlock("market_patron_unlock"), "stat purchases do not unlock rich audiences")
	check(state.try_purchase("market_guild_1", 0) and state.has_unlock("market_guild_unlock") and not state.has_unlock("market_patron_unlock"), "guild introduction opens only guild traders")
	check(state.try_purchase("market_patron_1", 0) and state.has_unlock("market_patron_unlock") and choices(state) == 5, "patron introduction stays independent and all second tiers remain choices")
	var preview: Dictionary = state.effect_preview("market_guild_2")
	check(preview.current.market_guild_donation_add == 0 and preview.next.market_guild_donation_add == 4 and preview.current.conviction == preview.next.conviction, "guild donation preview reports the implemented bonus without invented conviction")
	check(state.try_purchase("market_guild_2") and state.market_donation("guild", 12) == 16 and state.market_donation("patron", 18) == 18 and state.market_donation("ordinary", 3) == 3, "guild specialization changes only the intended audience reward")
	check(state.try_purchase("market_patron_2") and state.market_donation("patron", 18) == 24 and state.market_donation("guild", 12) == 16, "patron specialization retains separate donation accounting")
	for branch in BRANCHES:
		var id: String = "market_" + branch + "_2"
		if state.rank(id) == 0:
			check(state.try_purchase(id), "second-tier purchase remains independent: " + branch)
	check(choices(state) == 5, "all five third tiers are concurrently available without a cross-branch gate")
	for branch in BRANCHES:
		check(state.try_purchase("market_" + branch + "_3"), "original third-tier purchase remains independent: " + branch)
	check(not state.is_circle_complete() and choices(state) == 5 and state.market_donation("guild", 12) == 22 and state.market_donation("patron", 18) == 33, "original fifteen nodes retain their effects and open five new fourth-tier choices")
	check(is_equal_approx(state.run_multiplier(), 2.05) and is_equal_approx(state.speech_interval(), 1.0 / 4.6) and state.conviction_per_phrase() == 7.0, "original market ranks keep distinct (retuned) stat benefits")
	var coins_before: int = state.coins
	var recruits_before: int = state.available_recruits
	check(not state.try_purchase("market_run_6", 0) and state.coins == coins_before and state.available_recruits == recruits_before, "new final nodes enforce preceding tiers without spending either wallet")
	preview = state.effect_preview("market_guild_4")
	check(preview.current.market_guild_donation_add == 10 and preview.next.market_guild_donation_add == 16 and preview.current.conviction == preview.next.conviction, "new guild tier previews its actual specialist payout independently of speech")
	for tier in [4, 5]:
		for branch in BRANCHES:
			check(state.try_purchase("market_" + branch + "_" + str(tier), 0), "extended path purchases its implemented effect: %s tier %d" % [branch, tier])
		check(choices(state) == 5, "five independent paths remain choices after tier %d" % tier)
	check(state.try_purchase("market_run_6", 0) and choices(state) == 4 and state.try_purchase("market_talk_6", 0) and choices(state) == 3, "only finishing sixth-tier paths reduces funded choices from five to four to three")
	coins_before = state.coins
	recruits_before = state.available_recruits
	check(not state.try_purchase("market_talk_6", 0) and not state.try_purchase("market_talk_6", 1) and state.coins == coins_before and state.available_recruits == recruits_before, "stale and maximum new-node purchases spend neither wallet")
	for branch in ["persuade", "guild", "patron"]:
		check(state.try_purchase("market_" + branch + "_6", 0), "remaining independent final purchase: " + branch)
	check(state.is_circle_complete() and not state.is_circle_complete("bramblewick") and state.market_donation("guild", 12) == 46 and state.market_donation("patron", 18) == 69 and state.market_donation("ordinary", 4) == 4, "thirty-node market completes independently and specializations change only their intended rewards")
	check(is_equal_approx(state.run_multiplier(), 2.65) and is_equal_approx(state.speech_interval(), 1.0 / 6.4) and state.conviction_per_phrase() == 11.5, "full market build applies the purchased running, frequency and conviction independently")
	check(state.try_travel("bramblewick") and state.run_multiplier() == 1.0 and state.speech_interval() == 1.0 and state.conviction_per_phrase() == 1.0 and not state.has_unlock("market_guild_unlock") and state.market_donation("guild", 12) == 12, "returning removes market effects while preserving market purchases")
	check(state.purchased.size() == 30 and not state.try_purchase("market_run_1") and not state.try_purchase("market_guild_6"), "inactive circle purchases remain unavailable")
	for entry in state.catalog:
		state.purchased[entry.id] = state.max_rank(entry.id)
	var village_speed: float = state.run_multiplier()
	var village_frequency: float = 1.0 / state.speech_interval()
	var village_conviction: float = state.conviction_per_phrase()
	check(state.try_travel("bellmarket") and is_equal_approx(state.run_multiplier(), village_speed + 1.65) and is_equal_approx(1.0 / state.speech_interval(), village_frequency + 5.4) and state.conviction_per_phrase() == village_conviction + 10.5 and state.has_unlock("helper_unlock"), "every earned village rank and helper carry into market alongside all thirty local upgrades")
	check(state.try_travel("bramblewick") and is_equal_approx(state.run_multiplier(), village_speed) and is_equal_approx(1.0 / state.speech_interval(), village_frequency) and state.conviction_per_phrase() == village_conviction, "old village build is exactly restored after upgraded return travel")

	var exact = fresh_market()
	exact.coins = 14100
	exact.total_recruits = 183
	exact.available_recruits = 183
	for entry in exact.catalog:
		check(exact.try_purchase(entry.id, 0), "bounded catalog effect purchases: " + entry.id)
	check(exact.coins == 0 and exact.available_recruits == 0 and exact.total_recruits == 183 and exact.is_circle_complete(), "thirty market ranks cost exactly 14100 donations and 183 assigned recruits")
	var poor = fresh_market()
	poor.coins = 119
	check(choices(poor) == 0 and not poor.try_purchase("market_run_1", 0) and poor.coins == 119, "higher root cost is enforced by progression at one gold short")
	poor.coins = 320
	check(poor.try_purchase("market_talk_1") and not poor.try_purchase("market_talk_2") and poor.coins == 200 and poor.rank("market_talk_2") == 0, "later support cost is validated before spending either resource")
	poor.save_enabled = true
	poor.save_path = "user://missing_market_test_directory/progression.json"
	check(not poor.try_purchase("market_run_1") and poor.coins == 200 and poor.rank("market_run_1") == 0, "failed market purchase save charges and grants nothing")
	for tier in [2, 3]:
		poor.purchased["market_talk_" + str(tier)] = 1
	poor.coins = 480
	poor.total_recruits = 9
	poor.available_recruits = 9
	check(not poor.try_purchase("market_talk_4", 0) and poor.coins == 480 and poor.available_recruits == 9 and poor.rank("market_talk_4") == 0, "failed new-node save rolls back both higher donation cost and assigned recruits")
	poor.save_enabled = false
	check(poor.try_purchase("market_talk_4", 0) and poor.coins == 0 and poor.available_recruits == 0 and poor.total_recruits == 9 and poor.rank("market_talk_4") == 1, "successful new-node purchase spends the exact two-resource cost once")
	_test_catalog_validation()
	print("MARKET PROGRESSION RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_catalog_validation() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	var state = fresh_market()
	for kind in ["unknown_area", "cross_area_requirement", "fractional_donation", "misplaced_market_effect"]:
		var invalid: Dictionary = source.duplicate(true)
		match kind:
			"unknown_area":
				invalid.upgrades[33].area = "unimplemented"
			"cross_area_requirement":
				invalid.upgrades[33].requires = ["run_1"]
			"fractional_donation":
				invalid.upgrades[43].effect.market_guild_donation_add = 0.5
			"misplaced_market_effect":
				invalid.upgrades[0].effect = {"market_guild_donation_add": 4}
		var file: FileAccess = FileAccess.open(CATALOG_FIXTURE, FileAccess.WRITE)
		file.store_string(JSON.stringify(invalid))
		file.close()
		check(not state.load_catalog(CATALOG_FIXTURE) and state.catalog.size() == 30 and state.all_catalog.size() == 63, "invalid market catalog preserves validated definitions: " + kind)
	if FileAccess.file_exists(CATALOG_FIXTURE):
		DirAccess.remove_absolute(CATALOG_FIXTURE)
