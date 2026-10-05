extends SceneTree
## Bellmarket balance assumes every village rank. A fresh password start is
## a separate accessibility diagnostic, not the normal second-level entry build.

const Route = preload("res://tests/market_route_fixture.gd")
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
		push_error("MARKET PACING: " + description)


func simulate(label: String, order: Array[int] = Route.CIRCUIT, purchases: Array[String] = [], full_market: bool = false, options: Dictionary = Route.PRACTICAL, carry_village: bool = true) -> Dictionary:
	var fixture: Dictionary = await Route.setup(self, carry_village, purchases, full_market)
	check(fixture.ok, label + ": setup uses validated purchases and area travel")
	var result: Dictionary = await Route.simulate_round(self, fixture.scene, label, order, options)
	result.carry_village = carry_village
	result.village_upgrade_spend = fixture.village_upgrade_spend
	result.market_upgrade_spend = fixture.market_upgrade_spend
	check(result.finished and result.accounting_ok, label + ": real completed listeners account for both wallets and lifetime history within round expiry")
	print("MARKET PACING ROUTE: " + JSON.stringify(result))
	fixture.scene.queue_free()
	await process_frame
	return result


func _run() -> void:
	var carried: Dictionary = await simulate("all village ranks / market entry")
	check(carried.running_speed == 432.0 and carried.phrase_frequency == 3.5 and carried.conviction_per_phrase == 5.0 and carried.village_upgrade_spend == 1014, "normal market balancing uses ALL village ranks and their distinct carried stats")
	check(carried.recruited_types.guild == 0 and carried.recruited_types.patron == 0 and carried.donations == carried.recruits * 4, "full village entry improves actual open-listener yield without bypassing specialist introductions")
	var guild: Dictionary = await simulate("six guild ranks / Guild Row to carts", [2, 1, 0], Route.branch_purchases("guild"))
	check(guild.recruited_types.guild >= 2 and guild.recruited_types.patron == 0 and guild.donations > carried.donations, "guild specialization pays through completed rich-trader conversations")
	var patrons: Dictionary = await simulate("six patron ranks / steps to silk", [4, 3, 1], Route.branch_purchases("patron"))
	check(patrons.recruited_types.patron >= 2 and patrons.recruited_types.guild == 0 and patrons.donations > carried.donations, "patron specialization supports its separate rich-audience route")
	var running: Dictionary = await simulate("six running ranks / open-stall circuit", Route.CIRCUIT, Route.branch_purchases("run"))
	check(running.first_speaking_seconds < carried.first_speaking_seconds and running.walking_seconds < carried.walking_seconds and running.eligible_clear_seconds < carried.eligible_clear_seconds, "running specialization reduces actual travel and completes the same eligible route earlier")
	for branch in ["talk", "persuade"]:
		var speaking: Dictionary = await simulate("six " + branch + " ranks / open-stall circuit", Route.CIRCUIT, Route.branch_purchases(branch))
		check(speaking.running_speed == carried.running_speed and speaking.recruits >= carried.recruits and speaking.eligible_clear_seconds < carried.eligible_clear_seconds, branch + " specialization improves real speaking clearance without increasing running speed")
	var early_ranks: Array[String] = []
	for branch in BRANCHES:
		early_ranks.append_array(Route.branch_purchases(branch, 3))
	var middle: Dictionary = await simulate("first three tiers / fifteen market ranks", Route.CIRCUIT, early_ranks)
	var full: Dictionary = await simulate("all thirty market ranks / five-district circuit", Route.CIRCUIT, [], true)
	check(full.recruits == 25 and full.recruited_types.guild == 4 and full.recruited_types.patron == 3 and full.donations > middle.donations and full.eligible_clear_seconds < middle.eligible_clear_seconds, "new outer ranks improve earned rich-audience donations and actual full-clear timing beyond the former fifteen-node build")
	check(full.market_upgrade_spend > full.donations * 20 and carried.donations < guild.market_upgrade_spend, "even a fully upgraded real round cannot fund the market circle or an entry branch")
	var hesitant: Dictionary = await simulate("all thirty ranks / hesitation and crossed route", [4, 0, 3, 2, 1], [], true, {"reaction_seconds": 4.0, "switch_seconds": 0.85})
	check(hesitant.recruits < full.recruits and hesitant.donations < full.donations, "full ranks never automatically finish a hesitant nonoptimal route")
	var fresh: Dictionary = await simulate("diagnostic only / fresh password Bread Court", [0], [], false, Route.PRACTICAL, false)
	check(fresh.recruits >= 3 and fresh.donations > 0 and fresh.market_upgrade_spend == 0 and fresh.village_upgrade_spend == 0, "unupgraded password entry retains repeatable actual funding without becoming the balance target")
	print("MARKET PACING RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
