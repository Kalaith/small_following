extends SceneTree
## Full-village campaign regressions. All market earnings come from actual
## eleven-second routes, and every purchase uses the normal transactional API.
## The scripts choose consistent routes/orders; this is not a human-play estimate.

const Route = preload("res://tests/market_route_fixture.gd")
const BRANCH_ORDER: Array[String] = ["patron", "guild", "run", "talk", "persuade"]
const MAX_ROUNDS: int = 200
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
		push_error("MARKET CAMPAIGN: " + description)


func _purchase_order(strategy: String) -> Array[String]:
	var ids: Array[String] = []
	if strategy == "balanced":
		for tier in range(1, 7):
			for branch in BRANCH_ORDER:
				ids.append("market_%s_%d" % [branch, tier])
	else:
		for branch in BRANCH_ORDER:
			ids.append_array(Route.branch_purchases(branch))
	return ids


func _choice_counts(state: RefCounted) -> Dictionary:
	var frontier: int = 0
	var affordable: int = 0
	var unfinished_branches: Dictionary = {}
	for entry in state.catalog:
		var status: String = state.status(entry.id)
		if status != "purchased":
			unfinished_branches[entry.branch] = true
		if status in ["affordable", "unaffordable"]:
			frontier += 1
			affordable += int(status == "affordable")
	return {"frontier": frontier, "affordable": affordable, "unfinished_branches": unfinished_branches.size()}


func simulate_campaign(strategy: String, entry_bank: int) -> Dictionary:
	var label: String = "%s / %d carried gold" % [strategy, entry_bank]
	var fixture: Dictionary = await Route.setup(self)
	var scene = fixture.scene
	check(fixture.ok and scene.progression.is_circle_complete("bramblewick") and scene.progression.has_unlock("helper_unlock"), label + ": market entry retains every village rank and helper")
	scene.progression.coins = entry_bank
	# Zero spare recruits tests an actual emptied assignment wallet, without
	# granting support currency to buy the market's later ranks during setup.
	scene.progression.available_recruits = 0
	var entry_history: int = scene.progression.total_recruits
	var planned: Array[String] = _purchase_order(strategy)
	var purchase_index: int = 0
	var rounds: int = 0
	var earned_gold: int = 0
	var earned_recruits: int = 0
	var spent_gold: int = 0
	var spent_recruits: int = 0
	var max_income: int = 0
	var min_income: int = Route.SETUP_BUDGET
	var first_purchase_round: int = -1
	var first_round_purchases: int = 0
	var first_income: int = 0
	var choice_histogram: Dictionary = {}
	var frontier_ok: bool = true
	var accounting_ok: bool = true
	var purchases_ok: bool = true
	var ledger: Array[Dictionary] = []
	var measured_rounds: Array[Dictionary] = []
	while purchase_index < planned.size() and rounds <= MAX_ROUNDS:
		while purchase_index < planned.size() and scene.progression.status(planned[purchase_index]) == "affordable":
			var id: String = planned[purchase_index]
			var choices: Dictionary = _choice_counts(scene.progression)
			frontier_ok = frontier_ok and choices.frontier == choices.unfinished_branches and choices.frontier <= 5
			choice_histogram[str(choices.affordable)] = int(choice_histogram.get(str(choices.affordable), 0)) + 1
			var price: int = scene.progression.next_cost(id)
			var recruit_price: int = scene.progression.next_recruit_cost(id)
			var before_gold: int = scene.progression.coins
			var before_recruits: int = scene.progression.available_recruits
			if not scene.purchase_upgrade(id, 0):
				purchases_ok = false
				break
			purchases_ok = purchases_ok and scene.progression.coins == before_gold - price and scene.progression.available_recruits == before_recruits - recruit_price
			spent_gold += price
			spent_recruits += recruit_price
			ledger.append({"round": rounds, "id": id, "gold_before": before_gold, "gold_cost": price,
				"recruits_before": before_recruits, "recruit_cost": recruit_price,
				"affordable_choices": choices.affordable, "unlocked_choices": choices.frontier})
			if first_purchase_round < 0:
				first_purchase_round = rounds
			purchase_index += 1
		if rounds <= 1:
			first_round_purchases = purchase_index
		if not purchases_ok or purchase_index == planned.size() or rounds == MAX_ROUNDS:
			break
		var result: Dictionary = await Route.simulate_round(self, scene, label)
		rounds += 1
		earned_gold += result.donations
		earned_recruits += result.recruits
		max_income = maxi(max_income, result.donations)
		min_income = mini(min_income, result.donations)
		if rounds == 1:
			first_income = result.donations
		accounting_ok = accounting_ok and result.finished and result.accounting_ok and result.seconds == 11.0 and result.donations > 0
		measured_rounds.append({"round": rounds, "owned_market_nodes": purchase_index,
			"gold": result.donations, "recruits": result.recruits,
			"ordinary": result.recruited_types.ordinary, "guild": result.recruited_types.guild, "patron": result.recruited_types.patron,
			"clear_seconds": result.eligible_clear_seconds})
		if rounds % 20 == 0:
			print("MARKET CAMPAIGN PROGRESS: %s, %d rounds, %d purchased nodes" % [label, rounds, purchase_index])
	var result: Dictionary = {
		"strategy": strategy, "entry_gold": entry_bank, "entry_available_recruits": 0,
		"rounds_to_first_purchase": first_purchase_round, "rounds_to_complete": rounds,
		"first_round_gold": first_income, "purchases_by_first_round": first_round_purchases,
		"gold_earned": earned_gold, "gold_spent": spent_gold, "gold_remaining": scene.progression.coins,
		"recruits_earned": earned_recruits, "recruits_spent": spent_recruits,
		"recruits_remaining": scene.progression.available_recruits,
		"min_round_gold": min_income, "max_round_gold": max_income,
		"purchase_choice_histogram": choice_histogram,
		"purchases": ledger, "measured_rounds": measured_rounds,
	}
	check(purchases_ok and scene.progression.is_circle_complete() and purchase_index == planned.size(), label + ": real round earnings buy the whole market through validated purchases")
	check(accounting_ok and scene.progression.coins == entry_bank + earned_gold - spent_gold and scene.progression.available_recruits == earned_recruits - spent_recruits and scene.progression.total_recruits == entry_history + earned_recruits, label + ": every round and purchase preserves both wallets and recruitment history")
	check(first_round_purchases < planned.size() and rounds >= 25 and max_income * 20 < spent_gold, label + ": a single round cannot bankroll the circle even at the strongest observed income")
	check(frontier_ok and int(choice_histogram.get("5", 0)) > 0 and int(choice_histogram.get("4", 0)) > 0 and int(choice_histogram.get("3", 0)) > 0, label + ": each unfinished path retains an independent next step and actual purchases encounter three, four and five affordable choices")
	check(entry_bank > 0 or first_purchase_round >= 2, label + ": zero-wallet full-village entry must earn across rounds before its first purchase")
	print("MARKET CAMPAIGN SUMMARY: %s; first purchase after %d rounds; %d rounds to complete; gold +%d / -%d / %d remaining; recruits +%d / -%d / %d remaining; first-round gold %d; peak round gold %d; affordable-choice histogram %s" % [
		label, result.rounds_to_first_purchase, result.rounds_to_complete,
		result.gold_earned, result.gold_spent, result.gold_remaining,
		result.recruits_earned, result.recruits_spent, result.recruits_remaining,
		result.first_round_gold, result.max_round_gold,
		JSON.stringify(result.purchase_choice_histogram),
	])
	scene.queue_free()
	await process_frame
	return result


func _run() -> void:
	for bank in [0, 1000]:
		var balanced: Dictionary = await simulate_campaign("balanced", bank)
		var specialist: Dictionary = await simulate_campaign("patron_then_guild", bank)
		check(balanced.gold_spent == specialist.gold_spent and balanced.rounds_to_complete != specialist.rounds_to_complete, "purchase strategy changes measured funding time with %d carried gold" % bank)
	print("MARKET CAMPAIGN RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
