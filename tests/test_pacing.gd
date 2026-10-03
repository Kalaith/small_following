extends SceneTree
## Deterministic route simulations against the actual player, collisions and round code.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_pacing.gd
## No user save is read or written. These scripted routes do not establish human play feel.

const STEP: float = 1.0 / 60.0
const SPAWN: Vector2 = Vector2(780, 680)
const STOP_DISTANCE: float = 95.0
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
	while scene.round_active and steps < MAX_STEPS:
		await physics_frame
		var target = scene.groups[order[stop]]
		if target.recruits >= quotas[stop] and stop + 1 < order.size():
			stop += 1
			target = scene.groups[order[stop]]
			wait_seconds = float(route_options.get("switch_seconds", 0.0))
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
	var audience_counts: Array[int] = []
	for group in scene.groups:
		audience_counts.append(group.recruits)
	var full_clear_seconds: float = recruit_times[14] if recruit_times.size() == 15 else -1.0
	var result: Dictionary = {
		"route": label,
		"seconds": configured_duration,
		"phrase_frequency": snappedf(1.0 / scene.progression.speech_interval(), 0.001),
		"conviction_per_phrase": scene.progression.conviction_per_phrase(),
		"running_speed": scene.player.movement_speed,
		"upgrade_spend": purchase_cost,
		"recruits": scene.round_recruits,
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
	check(extended.recruits == 15, "longer baseline round can recruit all fifteen: no artificial three-recruit cap")
	check(extended.donations == 45, "full audience still grants normal individual donations")
	check(extended.recruit_seconds.back() > 45.0, "full clearance takes over forty-five seconds including travel")
	var opening_practical: Dictionary = await simulate_route("practical unupgraded garden", [2], [5], -1.0, [], PRACTICAL)
	check(opening_practical.recruits == 3, "opening still recruits three with a small reaction allowance")
	for destination: int in [0, 1]:
		var opening_alternative: Dictionary = await simulate_route("practical unupgraded audience " + str(destination), [destination], [5], -1.0, [], PRACTICAL)
		check(opening_alternative.recruits == 3, "opening at audience %d still recruits three with a small reaction allowance" % destination)
	var previous_full: Dictionary = await simulate_route("previous nine purchases practical garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, PREVIOUS_FULL, PRACTICAL)
	check(previous_full.recruits < 15, "previous nine purchases alone do not clear village")
	var full_practical: Dictionary = {}
	var completed_routes: int = 0
	for route: Array in [[2, 0, 1], [2, 1, 0], [0, 2, 1], [0, 1, 2], [1, 2, 0], [1, 0, 2]]:
		var order: Array[int] = []
		order.assign(route)
		var full: Dictionary = await simulate_route("full ranks practical order " + str(order), order, [5, 5, 5], -1.0, FULL_RANKS, PRACTICAL)
		if full.recruits == 15:
			completed_routes += 1
		if order == [2, 0, 1]:
			full_practical = full
	check(full_practical.groups == [5, 5, 5], "full ranks practical garden-well-market convert every listener in all three groups")
	check(full_practical.margin_seconds >= 0.20 and full_practical.margin_seconds <= 0.80, "competent full-rank route has a narrow positive 0.20-0.80 second margin")
	check(full_practical.donations == 45, "full ranks earn normal donations for fifteen conversions")
	check(completed_routes > 0 and completed_routes < 6, "route choice still matters at full ranks")
	for missing: String in ["talk_3", "persuade_3", "run_3"]:
		var purchases: Array[String] = FULL_RANKS.duplicate()
		purchases.remove_at(purchases.rfind(missing))
		var partial: Dictionary = await simulate_route("without final " + missing + " rank", [2, 0, 1], [5, 5, 5], -1.0, purchases, PRACTICAL)
		if missing == "run_3":
			check(partial.recruits < 15 or partial.full_clear_seconds > full_practical.full_clear_seconds, "final running rank improves completion time or makes clearance possible")
		else:
			check(partial.recruits < full_practical.recruits, "final " + missing + " rank improves practical recruitment")
	var deep_options: Dictionary = PRACTICAL.duplicate()
	deep_options.stop_distance = 60.0
	var deep: Dictionary = await simulate_route("full ranks deeper 60px garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, deep_options)
	check(deep.groups == [5, 5, 5] and deep.margin_seconds > 0.0, "deeper 60px positioning also clears all three groups with a positive margin")
	var no_final_running: Array[String] = FULL_RANKS.duplicate()
	no_final_running.remove_at(no_final_running.rfind("run_3"))
	var deep_without_running: Dictionary = await simulate_route("without final running rank deeper 60px route", [2, 0, 1], [5, 5, 5], -1.0, no_final_running, deep_options)
	check(deep_without_running.recruits < 15 or deep_without_running.full_clear_seconds > deep.full_clear_seconds, "final running rank improves the deeper practical route as well")
	var keyboard_options: Dictionary = PRACTICAL.duplicate()
	keyboard_options.keyboard_directions = true
	var keyboard: Dictionary = await simulate_route("full ranks eight-direction garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, keyboard_options)
	check(keyboard.groups == [5, 5, 5] and keyboard.margin_seconds > 0.0, "eight-direction movement also clears all three groups with a positive margin")
	var slow_options: Dictionary = PRACTICAL.duplicate()
	slow_options.reaction_seconds = 1.20
	slow_options.switch_seconds = 0.30
	var slow: Dictionary = await simulate_route("full ranks hesitant garden-well-market", [2, 0, 1], [5, 5, 5], -1.0, FULL_RANKS, slow_options)
	check(slow.recruits < 15, "full ranks do not guarantee a clear with longer pauses")
	print("PACING RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
