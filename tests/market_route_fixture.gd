extends RefCounted
## Shared test-only Bellmarket fixture. Real movement, collisions, phrase timing,
## helper work and reward authority run at fixed physics steps; saves stay disabled.

const STEP: float = 1.0 / 60.0
const STOP_DISTANCE: float = 95.0
const SETUP_BUDGET: int = 100000
const PRACTICAL: Dictionary = {"reaction_seconds": 0.20, "switch_seconds": 0.10}
const CIRCUIT: Array[int] = [0, 2, 1, 4, 3]


static func setup(tree: SceneTree, carry_village: bool = true, purchases: Array[String] = [], full_market: bool = false) -> Dictionary:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.show_title_on_start = false
	scene.game_audio.output_enabled = false
	tree.root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.round_active = false
	var setup_ok: bool = true
	var village_cost: int = 0
	scene.progression.coins = SETUP_BUDGET
	scene.progression.total_recruits = SETUP_BUDGET
	scene.progression.available_recruits = SETUP_BUDGET
	if carry_village:
		for entry in scene.progression.catalog:
			for desired_rank in range(scene.progression.max_rank(entry.id)):
				setup_ok = scene.purchase_upgrade(entry.id, desired_rank) and setup_ok
		village_cost = SETUP_BUDGET - scene.progression.coins
	setup_ok = scene.travel_to("bellmarket", not carry_village) and setup_ok
	scene.progression.coins = SETUP_BUDGET
	if full_market:
		for entry in scene.progression.catalog:
			setup_ok = scene.purchase_upgrade(entry.id, 0) and setup_ok
	else:
		for id in purchases:
			setup_ok = scene.purchase_upgrade(id, 0) and setup_ok
	var market_cost: int = SETUP_BUDGET - scene.progression.coins
	# Only fixture setup is funded. Every measured round begins with the wallet
	# assigned by its caller and earns through the normal gathering authority.
	scene.progression.coins = 0
	scene.progression.available_recruits = 0
	await tree.physics_frame
	await tree.physics_frame
	return {"scene": scene, "ok": setup_ok, "carry_village": carry_village,
		"village_upgrade_spend": village_cost, "market_upgrade_spend": market_cost}


static func branch_purchases(branch: String, tiers: int = 6) -> Array[String]:
	var result: Array[String] = []
	for tier in range(1, tiers + 1):
		result.append("market_%s_%d" % [branch, tier])
	return result


static func simulate_round(tree: SceneTree, scene: Node, label: String, order: Array[int] = CIRCUIT, options: Dictionary = PRACTICAL) -> Dictionary:
	var starting_coins: int = scene.progression.coins
	var starting_recruits: int = scene.progression.available_recruits
	var starting_history: int = scene.progression.total_recruits
	scene.start_next_round()
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
		await tree.physics_frame
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
	var earned_coins: int = scene.progression.coins - starting_coins
	var accounting_ok: bool = counted_donations == earned_coins \
		and scene.round_recruits == recruited_types.ordinary + recruited_types.guild + recruited_types.patron \
		and scene.progression.available_recruits - starting_recruits == scene.round_recruits \
		and scene.progression.total_recruits - starting_history == scene.round_recruits
	return {
		"route": label, "order": order, "seconds": configured_seconds,
		"running_speed": scene.player.movement_speed,
		"phrase_frequency": snappedf(1.0 / scene.progression.speech_interval(), 0.001),
		"conviction_per_phrase": scene.progression.conviction_per_phrase(),
		"eligible_listeners": eligible, "recruits": scene.round_recruits,
		"recruited_types": recruited_types, "groups": group_counts,
		"helper_recruits": scene.helper.completed_recruits if is_instance_valid(scene.helper) else 0,
		"donations": earned_coins, "walking_seconds": snappedf(walking_time, 0.001),
		"distance_pixels": snappedf(distance_walked, 0.01),
		"first_speaking_seconds": snappedf(first_speaking, 0.001),
		"recruit_seconds": recruit_times, "last_conversion_seconds": snappedf(last_conversion, 0.001),
		"eligible_clear_seconds": snappedf(eligible_clear, 0.001),
		"eligible_clear_margin_seconds": snappedf(configured_seconds - eligible_clear, 0.001) if eligible_clear >= 0.0 else -1.0,
		"route_options": options, "finished": not scene.round_active and scene.seconds_left == 0.0,
		"accounting_ok": accounting_ok,
	}
