extends SceneTree
## Deterministic route simulations against the actual player, collisions and round code.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_pacing.gd
## No user save is read or written. These scripted routes do not establish human play feel.

const STEP: float = 1.0 / 60.0
const SPAWN: Vector2 = Vector2(780, 680)
const STOP_DISTANCE: float = 95.0
const WANDERER_SEED: int = 4242
const WANDERER_COMPARISON_SEEDS: Array[int] = [4242, 11, 777, 2024, 99]
const MAX_STEPS: int = 6000
const PRACTICAL: Dictionary = {"reaction_seconds": 0.20, "switch_seconds": 0.10, "stop_distance": 95.0}
const PREVIOUS_FULL: Array[String] = ["talk_1", "persuade_1", "run_1", "talk_2", "persuade_2", "run_2", "talk_3", "persuade_3", "run_3"]
const FULL_RANKS: Array[String] = ["talk_1", "persuade_1", "run_1", "talk_2", "persuade_2", "run_2", "talk_3", "persuade_3", "run_3", "talk_3", "persuade_3", "run_3"]

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


func simulate_route(label: String, order: Array[int], quotas: Array[int], duration: float = -1.0, purchase_ids: Array[String] = [], route_options: Dictionary = {}) -> Dictionary:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	# Fixed wanderer placement keeps measured routes reproducible.
	scene.wanderer_seed = int(route_options.get("seed", WANDERER_SEED))
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	# Allow added collision footprints to enter the physics world before motion.
	await physics_frame
	await physics_frame
	var purchase_cost: int = 0
	if not purchase_ids.is_empty():
		scene.round_active = false
		scene.progression.coins = 1000
		scene.progression.total_recruits = 1000
		scene.progression.available_recruits = 1000
		var purchases_ok: bool = true
		for id in purchase_ids:
			purchases_ok = scene.purchase_upgrade(id) and purchases_ok
		check(purchases_ok, label + ": all setup ranks bought through normal API")
		purchase_cost = 1000 - scene.progression.coins
		scene.start_next_round()
	scene.player.position = SPAWN
	var starting_coins: int = scene.progression.coins
	if duration > 0.0:
		scene.seconds_left = duration
	var configured_duration: float = scene.seconds_left
	var stop: int = 0
	var steps: int = 0
	var walking_time: float = 0.0
	var distance_walked: float = 0.0
	var first_speaking: float = -1.0
	var recruit_times: Array[float] = []
	var previous_count: int = 0
	var wait_seconds: float = float(route_options.get("reaction_seconds", 0.0))
	var stop_distance: float = float(route_options.get("stop_distance", STOP_DISTANCE))
	var capacity: int = 0
	for group in scene.groups:
		capacity += group.listener_count
	var group_clear_seconds: float = -1.0
	var chasing: Node2D = null
	while scene.round_active and steps < MAX_STEPS:
		await physics_frame
		var target = scene.groups[order[stop]]
		if target.recruits >= mini(quotas[stop], target.listener_count) and stop + 1 < order.size():
			stop += 1
			target = scene.groups[order[stop]]
			wait_seconds = float(route_options.get("switch_seconds", 0.0))
		# Optional final leg: walk to the nearest open lone wanderer, one at a time.
		if bool(route_options.get("then_wanderers", false)) and stop + 1 >= order.size() and target.recruits >= mini(quotas[stop], target.listener_count):
			var wanderer: Node2D = _nearest_open_wanderer(scene)
			if wanderer != null:
				if wanderer != chasing:
					chasing = wanderer
					wait_seconds = maxf(wait_seconds, float(route_options.get("switch_seconds", 0.0)))
				target = wanderer
		var direction: Vector2 = Vector2.ZERO
		if wait_seconds > 0.000001:
			wait_seconds = maxf(0.0, wait_seconds - STEP)
		elif scene.player.position.distance_to(target.position) > stop_distance:
			direction = scene.player.position.direction_to(target.position)
			if bool(route_options.get("keyboard_directions", false)):
				direction = Vector2.RIGHT.rotated(snappedf(direction.angle(), PI / 4.0))
			walking_time += STEP
		var before: Vector2 = scene.player.position
		scene.player.step_motion(direction, STEP)
		distance_walked += before.distance_to(scene.player.position)
		scene.advance_round(STEP)
		steps += 1
		if first_speaking < 0.0 and is_instance_valid(scene.nearest_group):
			first_speaking = float(steps) * STEP
		while previous_count < scene.round_recruits:
			recruit_times.append(float(steps) * STEP)
			previous_count += 1
		if group_clear_seconds < 0.0 and _group_recruits(scene) == capacity:
			group_clear_seconds = float(steps) * STEP
	var audience_counts: Array[int] = []
	for group in scene.groups:
		audience_counts.append(group.recruits)
	var full_clear_seconds: float = group_clear_seconds
	var result: Dictionary = {
		"route": label,
		"seconds": configured_duration,
		"phrase_frequency": snappedf(1.0 / scene.progression.speech_interval(), 0.001),
		"conviction_per_phrase": scene.progression.conviction_per_phrase(),
		"running_speed": scene.player.movement_speed,
		"upgrade_spend": purchase_cost,
		"recruits": scene.round_recruits,
		"group_recruits": _group_recruits(scene),
		"wanderer_recruits": _wanderer_recruits(scene),
		"capacity": capacity,
		"helper_recruits": scene.helper.completed_recruits if is_instance_valid(scene.helper) else 0,
		"donations": scene.progression.coins - starting_coins,
		"groups": audience_counts,
		"walking_seconds": snappedf(walking_time, 0.001),
		"distance_pixels": snappedf(distance_walked, 0.01),
		"first_speaking_seconds": snappedf(first_speaking, 0.001),
		"recruit_seconds": recruit_times,
		"full_clear_seconds": snappedf(full_clear_seconds, 0.001),
		"margin_seconds": snappedf(configured_duration - full_clear_seconds, 0.001) if full_clear_seconds >= 0.0 else -1.0,
		"route_options": route_options,
		"finished": not scene.round_active,
	}
	print("PACING ROUTE: " + JSON.stringify(result))
	scene.queue_free()
	await process_frame
	return result


func _nearest_open_wanderer(scene) -> Node2D:
	var best: Node2D = null
	for wanderer in scene.wanderers:
		if wanderer.visible and wanderer.recruits == 0 and (best == null or scene.player.position.distance_to(wanderer.position) < scene.player.position.distance_to(best.position)):
			best = wanderer
	return best


func _wanderer_recruits(scene) -> int:
	var total: int = 0
	for wanderer in scene.wanderers:
		total += wanderer.recruits
	return total


func _group_recruits(scene) -> int:
	var total: int = 0
	for group in scene.groups:
		total += group.recruits
	return total


func _run() -> void:
	var nearest: Dictionary = await simulate_route("garden and stay", [2], [5])
	check(nearest.finished, "ordinary opening round expires")
	check(nearest.recruits == 3, "nearest audience yields three individual recruits")
	check(nearest.donations == 9, "three recruits fund a first purchase with nine donations")
	check(nearest.groups == [0, 0, 3], "three means listeners, not three entire gatherings")
	check(absf(nearest.first_speaking_seconds - 0.45) < 0.05, "actual motion reaches garden range in about 0.45 seconds")
	var well: Dictionary = await simulate_route("well and stay", [0], [5])
	check(well.recruits == 3, "starting at well also yields about three recruits")
	var market: Dictionary = await simulate_route("market and stay", [1], [5])
	check(market.recruits == 3, "starting at market also yields about three recruits")
	var switch_once: Dictionary = await simulate_route("one garden recruit then well", [2, 0], [1, 5])
	check(switch_once.recruits >= 2 and switch_once.recruits <= 3, "one route switch stays within ordinary opening pacing")
	var tour: Dictionary = await simulate_route("one recruit per gathering tour", [2, 0, 1], [1, 1, 1])
	check(tour.recruits >= 1 and tour.recruits < 3, "extra touring costs time and does not clear every audience")
	var talking: Dictionary = await simulate_route("garden with talking I", [2], [5], -1.0, ["talk_1"])
	check(talking.recruits > nearest.recruits, "faster phrases exceed three recruits within the same round")
	var persuasion: Dictionary = await simulate_route("garden with persuasion I", [2], [5], -1.0, ["persuade_1"])
	check(persuasion.recruits > nearest.recruits, "stronger phrases exceed three recruits within the same round")
	var running: Dictionary = await simulate_route("garden with running I", [2], [5], -1.0, ["run_1"])
	check(running.first_speaking_seconds < nearest.first_speaking_seconds, "running improvement shortens actual travel to first audience")
	check(running.recruits == nearest.recruits, "running alone preserves baseline speaking cadence on a short route")
	var extended: Dictionary = await simulate_route("counterfactual sixty-second full tour", [2, 0, 1], [5, 5, 5], 60.0)
	check(extended.group_recruits == 11 and extended.groups == [4, 3, 4], "longer baseline round can recruit all eleven group listeners: no artificial three-recruit cap")
	check(extended.donations == extended.recruits * 3, "full audience still grants normal individual donations")
	check(extended.full_clear_seconds > 33.0, "clearing the groups takes over thirty-three seconds including travel at base stats")
	var opening_practical: Dictionary = await simulate_route("practical unupgraded garden", [2], [5], -1.0, [], PRACTICAL)
	check(opening_practical.recruits == 3, "opening still recruits three with a small reaction allowance")
	for destination: int in [0, 1]:
		var opening_alternative: Dictionary = await simulate_route("practical unupgraded audience " + str(destination), [destination], [5], -1.0, [], PRACTICAL)
		check(opening_alternative.recruits == 3, "opening at audience %d still recruits three with a small reaction allowance" % destination)
	var previous_full: Dictionary = await simulate_route("previous nine purchases practical garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, PREVIOUS_FULL, PRACTICAL)
	check(previous_full.group_recruits < 11, "previous nine purchases alone do not clear the village groups")
	var full_practical: Dictionary = {}
	var clear_times: Array[float] = []
	for route: Array in [[2, 0, 1], [2, 1, 0], [0, 2, 1], [0, 1, 2], [1, 2, 0], [1, 0, 2]]:
		var order: Array[int] = []
		order.assign(route)
		var full: Dictionary = await simulate_route("full ranks practical order " + str(order), order, [5, 5, 5], -1.0, FULL_RANKS, PRACTICAL)
		if full.full_clear_seconds > 0.0:
			clear_times.append(full.full_clear_seconds)
		if order == [2, 0, 1]:
			full_practical = full
	check(full_practical.groups == [4, 3, 4], "full ranks practical garden-well-market convert every listener in all three groups")
	check(full_practical.margin_seconds >= 1.5, "full-rank group clear leaves at least 1.5 seconds to chase wanderers")
	check(full_practical.donations == full_practical.recruits * 3, "full ranks earn normal donations for every conversion")
	check(clear_times.size() == 6 and clear_times.max() - clear_times.min() > 0.3, "route choice still changes the full-rank finish time")
	for missing: String in ["talk_3", "persuade_3", "run_3"]:
		var purchases: Array[String] = FULL_RANKS.duplicate()
		purchases.remove_at(purchases.rfind(missing))
		var partial: Dictionary = await simulate_route("without final " + missing + " rank", [2, 0, 1], [5, 5, 5], -1.0, purchases, PRACTICAL)
		check(partial.group_recruits < 11 or partial.full_clear_seconds > full_practical.full_clear_seconds, "final " + missing + " rank clears the groups sooner")
	var deep_options: Dictionary = PRACTICAL.duplicate()
	deep_options.stop_distance = 60.0
	var deep: Dictionary = await simulate_route("full ranks deeper 60px garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, deep_options)
	check(deep.groups == [4, 3, 4] and deep.margin_seconds > 0.0, "deeper 60px positioning also clears all three groups with a positive margin")
	var no_final_running: Array[String] = FULL_RANKS.duplicate()
	no_final_running.remove_at(no_final_running.rfind("run_3"))
	var deep_without_running: Dictionary = await simulate_route("without final running rank deeper 60px route", [2, 0, 1], [5, 5, 5], -1.0, no_final_running, deep_options)
	check(deep_without_running.group_recruits < 11 or deep_without_running.full_clear_seconds > deep.full_clear_seconds, "final running rank improves the deeper practical route as well")
	var keyboard_options: Dictionary = PRACTICAL.duplicate()
	keyboard_options.keyboard_directions = true
	var keyboard: Dictionary = await simulate_route("full ranks eight-direction garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, keyboard_options)
	check(keyboard.groups == [4, 3, 4] and keyboard.margin_seconds > 0.0, "eight-direction movement also clears all three groups with a positive margin")
	var slow_options: Dictionary = PRACTICAL.duplicate()
	slow_options.reaction_seconds = 1.20
	slow_options.switch_seconds = 0.30
	var slow: Dictionary = await simulate_route("full ranks hesitant garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, slow_options)
	check(slow.group_recruits < 11 or slow.full_clear_seconds > full_practical.full_clear_seconds + 1.0, "longer pauses spend the time otherwise left for wanderers")
	# Wanderers: the spare full-rank time is spent running to lone villagers.
	var chase_options: Dictionary = PRACTICAL.duplicate()
	chase_options.then_wanderers = true
	var beckon_ranks: Array[String] = FULL_RANKS.duplicate()
	beckon_ranks.append_array(["beckon_1", "beckon_1"])
	# Wanderer yield depends on each round's scatter, so compare several seeds.
	var plain_total: int = 0
	var beckon_total: int = 0
	var all_reached: bool = true
	var same_costs: bool = true
	for seed: int in WANDERER_COMPARISON_SEEDS:
		chase_options.seed = seed
		var chase: Dictionary = await simulate_route("full ranks groups then wanderers, seed %d" % seed, [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, chase_options)
		var beckoned: Dictionary = await simulate_route("full ranks plus Beckoning Call II then wanderers, seed %d" % seed, [2, 0, 1], [5, 5, 5], -1.0, beckon_ranks, chase_options)
		all_reached = all_reached and chase.groups == [4, 3, 4] and chase.wanderer_recruits > 0
		same_costs = same_costs and beckoned.upgrade_spend == chase.upgrade_spend + 27 and beckoned.running_speed == chase.running_speed
		plain_total += chase.recruits
		beckon_total += beckoned.recruits
	print("WANDERER COMPARISON: without %d, with Beckoning Call II %d recruits over %d seeds" % [plain_total, beckon_total, WANDERER_COMPARISON_SEEDS.size()])
	check(all_reached, "full ranks clear the groups and still reach lone wanderers on every compared scatter")
	check(same_costs, "Beckoning Call costs 27 donations and leaves running speed unchanged")
	check(beckon_total > plain_total, "Beckoning Call converts more people across the compared scatters")
	var beckon_only: Dictionary = await simulate_route("opening garden with Beckoning Call I", [2], [5], -1.0, ["run_1", "beckon_1"], PRACTICAL)
	check(beckon_only.recruits >= opening_practical.recruits and beckon_only.phrase_frequency == 1.0 and beckon_only.conviction_per_phrase == 1.0, "Beckoning Call leaves talking frequency and conviction unchanged")
	var expanded_ranks: Array[String] = FULL_RANKS.duplicate()
	expanded_ranks.append_array(["meadow_1", "talk_4", "run_4", "east_1", "talk_5", "run_5"])
	var expanded: Dictionary = await simulate_route("expanded practical garden-meadow-well-market-east", [2, 3, 0, 1, 4], [5, 5, 5, 5, 5], -1.0, expanded_ranks, PRACTICAL)
	check(expanded.groups == [4, 3, 4, 4, 3] and expanded.donations == expanded.recruits * 3, "expanded ranks recruit seven invited listeners at ordinary donation rates")
	var partial_expansion: Array[String] = expanded_ranks.duplicate()
	partial_expansion.erase("talk_5")
	partial_expansion.erase("run_5")
	var expanded_partial: Dictionary = await simulate_route("expanded without final stat tier", [2, 3, 0, 1, 4], [5, 5, 5, 5, 5], -1.0, partial_expansion, PRACTICAL)
	check(expanded.recruits > expanded_partial.recruits, "new final speaking and running tier improves actual expanded route yield")
	var expanded_slow: Dictionary = await simulate_route("expanded hesitant route", [2, 3, 0, 1, 4], [5, 5, 5, 5, 5], -1.0, expanded_ranks, slow_options)
	check(expanded_slow.recruits < expanded.recruits, "expanded population still rewards route execution")
	var assisted_ranks: Array[String] = expanded_ranks.duplicate()
	assisted_ranks.append("helper_1")
	var meadow_first: Dictionary = await simulate_route("expanded meadow-first without helper", [3, 0, 1, 4, 2], [5, 5, 5, 5, 5], -1.0, expanded_ranks, PRACTICAL)
	var assisted_meadow: Dictionary = await simulate_route("expanded meadow-first with helper", [3, 0, 1, 4, 2], [5, 5, 5, 5, 5], -1.0, assisted_ranks, PRACTICAL)
	check(assisted_meadow.helper_recruits > 0 and assisted_meadow.full_clear_seconds < meadow_first.full_clear_seconds, "leaving garden work to the helper clears a measured alternate route sooner")
	var assisted: Dictionary = await simulate_route("expanded helper garden-first route", [2, 3, 0, 1, 4], [5, 5, 5, 5, 5], -1.0, assisted_ranks, PRACTICAL)
	check(assisted.recruits >= expanded.recruits and assisted.recruits <= expanded.recruits + assisted.helper_recruits, "helper ownership adds only the recruits it actually converts")
	print("PACING RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
