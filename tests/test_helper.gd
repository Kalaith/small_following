extends SceneTree
## Isolated real-scene helper checks; never touches ordinary progression.
const STEP: float = 1.0 / 60.0
const Helper = preload("res://scripts/helper.gd")
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


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(not is_instance_valid(scene.helper), "fresh village has no free helper")
	scene.round_active = false
	scene.progression.coins = 1000
	scene.progression.total_recruits = 1000
	scene.progression.available_recruits = 1000
	check(not scene.purchase_upgrade("helper_1") and scene.coins == 1000, "helper requires meadow invitation")
	for id in ["persuade_1", "persuade_2", "persuade_3", "meadow_1"]:
		check(scene.purchase_upgrade(id), "helper prerequisite purchase: " + id)
	var before: int = scene.coins
	scene.progression.save_enabled = true
	scene.progression.save_path = "user://missing_helper_test_directory/save.json"
	check(not scene.purchase_upgrade("helper_1") and not is_instance_valid(scene.helper) and scene.coins == before, "failed helper save grants no actor and spends nothing")
	scene.progression.save_enabled = false
	check(scene.purchase_upgrade("helper_1", 0) and is_instance_valid(scene.helper) and scene.coins == before - 76, "helper purchase creates one actor for seventy-six donations")
	check(scene.purchase_upgrade("run_1") and scene.purchase_upgrade("talk_1"), "player stat upgrades can coexist with independent helper stats")
	var helper = scene.helper
	scene.apply_upgrades()
	check(scene.helper == helper and not scene.purchase_upgrade("helper_1", 0), "reapply and stale purchases cannot create a second helper")
	var start: Vector2 = helper.position
	scene.advance_round(10.0)
	check(helper.position == start and helper.completed_recruits == 0, "helper waits during intermission")
	scene.start_next_round()
	scene.player.position = Vector2(780, 1010)
	before = scene.coins
	scene.advance_round(0.5)
	check(helper.position.distance_to(start) > 30.0 and helper.position.distance_to(start) <= 75.01 and helper.conviction == 0.0, "helper actually travels at its own speed before speaking")
	check(helper.target_index >= 0 and helper.target_group != null, "helper chooses one specific listener")
	var travel_steps: int = 0
	while not helper.speaking and scene.round_active and travel_steps < 300:
		scene.advance_round(STEP)
		travel_steps += 1
	check(helper.speaking and helper.global_position.distance_to(helper.target_group.listeners[helper.target_index].global_position) < 50.0, "path ends beside the individual listener")
	scene.advance_round(1.01)
	check(helper.conviction == 1.0 and helper.completed_recruits == 0 and scene.coins == before, "one helper phrase does one conviction without instant recruitment")
	var contested = helper.target_group
	var contested_index: int = helper.target_index
	check(contested.recruit_listener(contested_index), "player-side conversion can finish the helper target first")
	check(not contested.recruit_listener(contested_index) and scene.coins == before + 3, "shared listener authority rejects duplicate rewards")
	scene.advance_round(STEP)
	check(helper.conviction == 0.0 and helper.completed_recruits == 0 and (helper.target_group != contested or helper.target_index != contested_index), "helper drops old effort and retargets when the player finishes its listener")
	scene.advance_round(100.0)
	check(not scene.round_active and not helper.active and helper.completed_recruits > 0, "helper recruits during active time then rests at round expiry")
	check(scene.coins == before + 3 * scene.round_recruits, "each player/helper conversion pays exactly once")
	start = helper.position
	before = scene.coins
	scene.advance_round(100.0)
	check(helper.position == start and scene.coins == before, "expired round gives no further helper movement or earnings")
	scene.player.set_physics_process(true)
	var player_start: Vector2 = scene.player.position
	Input.action_press("move_left")
	for index in range(8):
		await physics_frame
	Input.action_release("move_left")
	check(scene.player.position.x < player_start.x, "helper never takes away direct intermission movement")
	scene.player.set_physics_process(false)
	scene.start_next_round()
	check(helper.position == scene.START_POSITION + helper.START_OFFSET and helper.target_index == -1 and helper.conviction == 0 and helper.completed_recruits == 0, "new round resets helper position, target and effort")
	check(scene.groups[2].recruits == 0, "helper recruits reset with the audience")
	# A final tiny time slice cannot use the caller's excess delta to finish a phrase.
	scene.player.position = Vector2(780, 1010)
	helper.set_active(true)
	helper.target_group = scene.groups[0]
	helper.target_index = 0
	helper.path.clear()
	helper.phrase_elapsed = 0.90
	helper.conviction = 2.0
	scene.seconds_left = 0.05
	before = scene.coins
	scene.advance_round(50.0)
	check(scene.coins == before and helper.completed_recruits == 0 and not helper.active, "helper cannot finish beyond clamped round time")
	# Player speech must skip an out-of-order helper recruit and keep overflow.
	var group = scene.groups[0]
	group.reset_round()
	before = scene.coins
	group.recruit_listener(3)
	group.tick_persuasion(4.0, 1.0, 2.0)
	check(group.recruits == 3 and group.progress == 2.0 and not group.listeners[2].following, "player overflow survives an out-of-order helper conversion")
	group.tick_persuasion(1.0, 1.0, 2.0)
	check(group.recruits == 4 and scene.coins == before + 12, "all listeners finish exactly once after mixed recruitment")
	# Check every current listener's stand cell, including both invitation groups.
	scene.round_active = false
	for id in ["talk_2", "talk_3", "talk_4", "east_1"]:
		check(scene.purchase_upgrade(id), "path coverage setup: " + id)
	var reachable: bool = true
	check(scene.wanderers.size() == 5, "lone wanderers are part of the helper's audience")
	for audience in scene.audiences():
		for listener in range(audience.listeners.size()):
			for index in range(audience.listeners.size()):
				audience.listeners[index].following = index != listener
			helper.reset_round(scene.START_POSITION)
			var one_group: Array[Node2D] = [audience]
			helper._choose_target(one_group)
			if helper.target_index != listener or helper.path.is_empty() or helper.path[-1].distance_to(audience.listeners[listener].global_position) > 50.0:
				reachable = false
		audience.reset_round()
	check(reachable, "every group listener and lone wanderer has a reachable helper stand cell")
	# Route from below the market to the east audience; direct travel crosses its body.
	helper.reset_round(Vector2(1128, 792) - helper.START_OFFSET)
	helper.set_active(true)
	var route_groups: Array[Node2D] = [scene.groups[1]]
	group.reset_round()
	var points: Array[Vector2] = []
	for index in range(600):
		helper.advance(STEP, route_groups)
		points.append(helper.global_position)
		if helper.completed_recruits > 0:
			break
	var touches_prop: bool = false
	var probe := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = helper.BODY_RADIUS
	probe.shape = circle
	probe.collision_mask = 2
	for point in points:
		probe.transform = Transform2D(0, point)
		if not scene.get_world_2d().direct_space_state.intersect_shape(probe, 1).is_empty():
			touches_prop = true
	check(helper.completed_recruits == 1 and not touches_prop, "helper path detours around actual market collision before recruiting")
	for audience in scene.groups:
		audience.tick_persuasion(100.0, 0.1, 10.0)
	helper.advance(STEP, scene.groups)
	check(helper.target_index == -1 and not helper.speaking, "helper rests without a target when every listener is converted")
	scene.queue_free()
	await process_frame
	await _test_obstacle_group_contract()
	await _test_bounded_empty_search()
	print("HELPER RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_obstacle_group_contract() -> void:
	# Blocking must follow the "helper_obstacle_shape" group, not a shape
	# node coincidentally named "Shape" (see village.gd/market.gd).
	var actors := Node2D.new()
	root.add_child(actors)
	var grouped_body := StaticBody2D.new()
	var grouped_shape := CollisionShape2D.new()
	grouped_shape.name = "AnythingAtAll"
	grouped_shape.add_to_group("helper_obstacle_shape")
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	grouped_shape.shape = circle
	grouped_body.add_child(grouped_shape)
	grouped_body.position = Vector2(300, 300)
	actors.add_child(grouped_body)
	var ungrouped_body := StaticBody2D.new()
	var ungrouped_shape := CollisionShape2D.new()
	ungrouped_shape.name = "Shape"
	var other_circle := CircleShape2D.new()
	other_circle.radius = 20.0
	ungrouped_shape.shape = other_circle
	ungrouped_body.add_child(ungrouped_shape)
	ungrouped_body.position = Vector2(600, 300)
	actors.add_child(ungrouped_body)
	var helper := Helper.new()
	actors.add_child(helper)
	helper.configure_navigation(actors)
	check(helper.navigation.is_point_solid(helper._cell(Vector2(300, 300))), "a shape in the obstacle group blocks pathing regardless of its node name")
	check(not helper.navigation.is_point_solid(helper._cell(Vector2(600, 300))), "a shape named \"Shape\" but outside the obstacle group no longer blocks pathing")
	actors.queue_free()
	await process_frame


func _test_bounded_empty_search() -> void:
	# Finding no reachable eligible listener must not repeat the full A*
	# sweep on every one of up to sixty sub-steps in a single advance() call.
	var actors := Node2D.new()
	root.add_child(actors)
	var helper := Helper.new()
	actors.add_child(helper)
	helper.configure_navigation(actors)
	helper.global_position = Vector2(300, 300)
	helper.set_active(true)
	var empty_groups: Array[Node2D] = []
	helper.advance(1.0, empty_groups)
	check(helper.search_attempts == 1, "a full second with no listener sweeps for a target at most once, not once per sub-step")
	actors.queue_free()
	await process_frame
