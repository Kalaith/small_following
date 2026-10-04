extends SceneTree
## Actual movement, collisions and conversation in Bellmarket. Saves stay disabled.
## Small scripted reaction allowances are evidence, not a claim about human play feel.

const STEP: float = 1.0 / 60.0
const STOP_DISTANCE: float = 95.0
const PRACTICAL: Dictionary = {"reaction_seconds": 0.20, "switch_seconds": 0.10}
const GUILD: Array[String] = ["market_guild_1", "market_guild_2", "market_guild_3"]
const PATRON: Array[String] = ["market_patron_1", "market_patron_2", "market_patron_3"]
const RUNNING: Array[String] = ["market_run_1", "market_run_2", "market_run_3"]
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


func simulate(label: String, order: Array[int], carry_village: bool = true, purchases: Array[String] = [], full_market: bool = false, options: Dictionary = PRACTICAL) -> Dictionary:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.show_title_on_start = false
	scene.game_audio.output_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.round_active = false
	var setup_ok: bool = true
	var village_cost: int = 0
	if carry_village:
		scene.progression.coins = 10000
		scene.progression.total_recruits = 10000
		scene.progression.available_recruits = 10000
		for entry in scene.progression.catalog:
			for desired_rank in range(scene.progression.max_rank(entry.id)):
				setup_ok = scene.purchase_upgrade(entry.id, desired_rank) and setup_ok
		village_cost = 10000 - scene.progression.coins
	setup_ok = scene.travel_to("bellmarket", not carry_village) and setup_ok
	scene.progression.coins = 10000
	var market_cost: int = 0
	if full_market:
		for entry in scene.progression.catalog:
			setup_ok = scene.purchase_upgrade(entry.id, 0) and setup_ok
	else:
		for id in purchases:
			setup_ok = scene.purchase_upgrade(id, 0) and setup_ok
	market_cost = 10000 - scene.progression.coins
	check(setup_ok, label + ": setup uses validated purchases and area travel")
	# Measure funding from zero available balances, regardless of the setup build.
	scene.progression.coins = 0
	scene.progression.available_recruits = 0
	scene.start_next_round()
	await physics_frame
	await physics_frame
	var eligible: int = 0
	for group in scene.groups:
		for index in range(group.listener_count):
			eligible += int(group.is_listener_eligible(index))
	var configured_seconds: float = scene.seconds_left
	var stop: int = 0
	var steps: int = 0
	var walking_time: float = 0.0
	var distance_walked: float = 0.0
	var first_speaking: float = -1.0
	var recruit_times: Array[float] = []
	var wait_seconds: float = float(options.get("reaction_seconds", 0.0))
	while scene.round_active and steps < 900:
		await physics_frame
		var target = scene.groups[order[stop]]
		if target.first_unconverted() < 0 and stop + 1 < order.size():
			stop += 1
			target = scene.groups[order[stop]]
			wait_seconds = float(options.get("switch_seconds", 0.0))
		var direction: Vector2 = Vector2.ZERO
		if wait_seconds > 0.000001:
			wait_seconds = maxf(0.0, wait_seconds - STEP)
		elif scene.player.position.distance_to(target.position) > STOP_DISTANCE:
			direction = scene.player.position.direction_to(target.position)
			walking_time += STEP
		var before: Vector2 = scene.player.position
		scene.player.step_motion(direction, STEP)
		distance_walked += before.distance_to(scene.player.position)
		scene.advance_round(STEP)
		steps += 1
		if first_speaking < 0.0 and is_instance_valid(scene.nearest_group):
			first_speaking = float(steps) * STEP
		while recruit_times.size() < scene.round_recruits:
			recruit_times.append(float(steps) * STEP)
	var recruited_types: Dictionary = {"ordinary": 0, "guild": 0, "patron": 0}
	var group_counts: Array[int] = []
	var counted_donations: int = 0
	for group in scene.groups:
		group_counts.append(group.recruits)
		for index in range(group.listener_count):
			if group.listeners[index].following:
				var kind: String = group.listener_profiles[index].npc_type
				recruited_types[kind] += 1
				counted_donations += group.listener_donation(index)
	var last_conversion: float = recruit_times.back() if not recruit_times.is_empty() else -1.0
	var eligible_clear: float = last_conversion if scene.round_recruits == eligible else -1.0
	var result: Dictionary = {
		"route": label, "order": order, "seconds": configured_seconds,
		"carry_village": carry_village, "village_upgrade_spend": village_cost, "market_upgrade_spend": market_cost,
		"running_speed": scene.player.movement_speed,
		"phrase_frequency": snappedf(1.0 / scene.progression.speech_interval(), 0.001),
		"conviction_per_phrase": scene.progression.conviction_per_phrase(),
		"eligible_listeners": eligible, "recruits": scene.round_recruits,
		"recruited_types": recruited_types, "groups": group_counts,
		"helper_recruits": scene.helper.completed_recruits if is_instance_valid(scene.helper) else 0,
		"donations": scene.coins, "walking_seconds": snappedf(walking_time, 0.001),
		"distance_pixels": snappedf(distance_walked, 0.01),
		"first_speaking_seconds": snappedf(first_speaking, 0.001),
		"recruit_seconds": recruit_times, "last_conversion_seconds": snappedf(last_conversion, 0.001),
		"eligible_clear_seconds": snappedf(eligible_clear, 0.001),
		"eligible_clear_margin_seconds": snappedf(configured_seconds - eligible_clear, 0.001) if eligible_clear >= 0.0 else -1.0,
		"route_options": options, "finished": not scene.round_active,
	}
	check(not scene.round_active and scene.seconds_left == 0.0 and scene.round_recruits == recruited_types.ordinary + recruited_types.guild + recruited_types.patron and counted_donations == scene.coins, label + ": real completed listeners account for all rewards within round expiry")
	print("MARKET PACING ROUTE: " + JSON.stringify(result))
	scene.queue_free()
	await process_frame
	return result


func _run() -> void:
	var fresh: Dictionary = await simulate("fresh password entry / Bread Court", [0], false)
	check(fresh.recruits >= 3 and fresh.donations >= 12 and fresh.market_upgrade_spend == 0 and fresh.village_upgrade_spend == 0, "fresh password entry funds any twelve-gold root with actual Bread Court conversions")
	check(fresh.recruited_types.guild == 0 and fresh.recruited_types.patron == 0, "unintroduced rich listeners never supply free funding")
	var circuit: Array[int] = [0, 2, 1, 4, 3]
	var carried: Dictionary = await simulate("village build / open-stall circuit", circuit)
	check(carried.recruits > fresh.recruits and carried.recruited_types.guild == 0 and carried.recruited_types.patron == 0 and carried.donations == carried.recruits * 4, "earned village build improves actual market yield without bypassing introductions")
	var guild: Dictionary = await simulate("guild specialist / Guild Row to carts", [2, 1, 0], true, GUILD)
	check(guild.recruited_types.guild >= 2 and guild.recruited_types.patron == 0 and guild.donations > carried.donations, "guild specialization makes a rich-trader route pay more than the open-stall circuit")
	var patrons: Dictionary = await simulate("patron specialist / steps to silk", [4, 3, 1], true, PATRON)
	check(patrons.recruited_types.patron >= 2 and patrons.recruited_types.guild == 0 and patrons.donations > carried.donations, "patron specialization makes its separate rich-audience route worthwhile")
	var running: Dictionary = await simulate("running specialist / open-stall circuit", circuit, true, RUNNING)
	check(running.first_speaking_seconds < carried.first_speaking_seconds and running.walking_seconds < carried.walking_seconds, "running path reduces actual time spent travelling on the same circuit")
	check(running.recruits >= carried.recruits and (running.eligible_clear_seconds < carried.eligible_clear_seconds or running.recruits > carried.recruits), "running improvement reaches the same eligible clear earlier or recruits more before expiry")
	var full: Dictionary = await simulate("full market / five-district circuit", circuit, true, [], true)
	check(full.recruited_types.guild > 0 and full.recruited_types.patron > 0 and full.recruits > carried.recruits and full.donations > patrons.donations, "full market build converts additional unlocked people and earns their real donations")
	var hesitant: Dictionary = await simulate("full market / long hesitation and crossed route", [4, 0, 3, 2, 1], true, [], true, {"reaction_seconds": 3.20, "switch_seconds": 0.70})
	check(hesitant.recruits < full.recruits and hesitant.donations < full.donations, "full ranks cannot automatically finish a hesitant nonoptimal route")
	print("MARKET PACING RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
