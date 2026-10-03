extends SceneTree
## Does not read or write the player's save. Run --headless --script with --fixed-fps 60.
const Fixture = preload("res://tests/fixtures/ritual_fixture.gd")
var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)


func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
	await process_frame


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.seconds_left = scene.ROUND_SECONDS
	var player = scene.player
	check(scene.groups.size() == 3 and scene.progression.catalog.size() == 15, "three gatherings and fifteen real upgrades")
	check(player.get_node("Camera2D").enabled, "following camera enabled")
	for action in ["move_left", "move_right", "move_up", "move_down", "next_round", "buy_upgrade", "toggle_ritual"]:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "mapped action: " + action)
	player.position = Vector2(600, 720)
	var start: Vector2 = player.position
	Input.action_press("move_right")
	await frames(12)
	check(player.position.x > start.x + 10, "mapped input moves player")
	Input.action_press("move_down")
	await frames(12)
	check(absf(player.velocity.length() - 180.0) < 0.01, "diagonal movement stays normalized")
	check(player._trail_direction.dot(-player.velocity.normalized()) > 0.5 and player._flutter_amount > 1.0, "robe trails and flutters")
	Input.action_release("move_right")
	Input.action_release("move_down")
	await frames(45)
	check(player._flutter_amount < 0.01, "robe settles")
	player.position = Vector2(-50, -50)
	await frames(2)
	check(player.world_bounds.has_point(player.position), "world bounds enforced")
	player.position = Vector2(780, 480)
	Input.action_press("move_up")
	await frames(40)
	Input.action_release("move_up")
	check(player.position.y > 430 and player.position.y < 470, "well collision still blocks movement")

	player.position = Vector2(600, 680)
	scene.advance_round(0.5)
	check(scene.coins == 0, "outside audience gives no income")
	player.position = scene.groups[0].position + Vector2(70, 0)
	scene.advance_round(1.0)
	check(scene.groups[0].progress == 1.0 and scene.coins == 0, "one phrase adds one conviction, not an immediate recruit")
	player.position = Vector2(600, 680)
	scene.advance_round(0.5)
	check(scene.groups[0].progress == 1.0, "leaving range stops progress")
	player.position = scene.groups[0].position + Vector2(70, 0)
	scene.advance_round(8.0)
	check(scene.coins == 9 and scene.round_recruits == 3, "nine speaking seconds convert three individuals")
	check(not scene.purchase_upgrade("talk_1"), "purchases blocked during round")
	scene.advance_round(20.0)
	check(not scene.round_active and scene.seconds_left == 0.0 and scene.ritual_screen.visible, "expiry opens actual ritual screen")
	var earned: int = scene.coins
	scene.advance_round(20.0)
	check(scene.coins == earned, "ritual grants no earnings")
	var before: Vector2 = player.position
	Input.action_press("move_down")
	await frames(8)
	Input.action_release("move_down")
	check(player.position.y > before.y, "movement remains available under ritual")
	scene.set_ritual_visible(false)
	check(not scene.ritual_screen.visible and not scene.round_active, "return to village does not start or earn")
	scene.set_ritual_visible(true)
	check(not scene.purchase_upgrade("talk_2"), "tier prerequisite enforced")
	check(scene.purchase_upgrade("talk_1") and scene.coins == 3, "first tier purchase charges six")
	check(not scene.purchase_upgrade("talk_1") and scene.coins == 3, "repeated purchase cannot charge again")
	check(not scene.purchase_upgrade("run_1"), "insufficient funds rejected")
	check(scene.progression.speech_interval() < 1.0 and scene.progression.conviction_per_phrase() == 1.0 and player.movement_speed == 180.0, "talking speed alters cadence alone")
	scene.start_next_round()
	check(scene.round_active and not scene.ritual_screen.visible and scene.seconds_left == 11.0, "next round closes ritual and resets timer")
	check(player.position == scene.START_POSITION and scene.groups[0].recruits == 0 and scene.coins == 3 and scene.nearest_group == null, "round uses entrance, clears old audience and preserves progression")
	player.position = scene.groups[0].position
	scene.advance_round(2.5)
	check(scene.groups[0].recruits == 1, "talk speed accelerates phrases")
	scene.advance_round(100.0)
	scene.progression.coins = 100
	check(scene.purchase_upgrade("persuade_1"), "persuasion purchase")
	check(scene.progression.conviction_per_phrase() == 1.5 and player.movement_speed == 180.0, "persuasion changes conviction alone")
	check(scene.purchase_upgrade("run_1"), "running purchase")
	check(is_equal_approx(player.movement_speed, 207.0), "running changes actual movement speed")
	var group = scene.groups[1]
	group.reset_round()
	group.tick_persuasion(5.0, 1.0, 2.0)
	check(group.recruits == 3 and group.progress == 1.0, "persuasion overflow is retained across listeners")
	group.tick_persuasion(100.0, 0.5, 2.5)
	check(group.recruits == 5, "audience capacity still applies, no duplicate rewards")

	await _test_graph(scene)
	scene.queue_free()
	await process_frame
	await _test_relaunch()
	await _test_migrated_rank_loop()
	await _test_expanded_village()
	print("SMOKE RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_expanded_village() -> void:
	var path: String = "user://integration_expansion_%d.json" % Time.get_ticks_usec()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = path
	root.add_child(scene)
	scene.set_process(false)
	scene.round_active = false
	scene.progression.coins = 1000
	check(not scene.purchase_upgrade("meadow_1") and scene.groups.size() == 3, "locked invitation cannot spawn listeners")
	for item in scene.progression.catalog:
		check(scene.purchase_upgrade(item.id), "expanded scene purchase: " + item.id)
	check(scene.groups.size() == 5 and scene.added_gatherings.size() == 2, "invitations create two actual groups immediately")
	scene.apply_upgrades()
	check(scene.groups.size() == 5, "applying upgrades again does not duplicate listeners")
	scene.start_next_round()
	scene.player.position = scene.groups[3].position
	var before: int = scene.coins
	scene.advance_round(3.0)
	check(scene.groups[3].recruits == 5 and scene.coins == before + 15, "new listeners recruit and pay through ordinary conversation")
	scene.advance_round(100.0)
	scene.start_next_round()
	check(scene.groups[3].recruits == 0 and scene.groups.size() == 5, "expanded audiences reset next round and remain unlocked")
	scene.queue_free()
	await process_frame
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.save_path_override = path
	root.add_child(restored)
	restored.set_process(false)
	check(restored.groups.size() == 5 and restored.groups[3].recruits == 0 and restored.progression.rank("talk_5") == 1, "relaunch recreates expanded village from saved ranks")
	restored.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _test_graph(scene) -> void:
	var screen = scene.ritual_screen
	screen.reset_view()
	screen.select_node("talk_1")
	var point: Vector2 = screen.world_to_screen(screen.node_positions["talk_1"])
	check(screen.hit_test(point) == "talk_1", "real node selection uses drawn geometry")
	var anchor: Vector2 = point + Vector2(16, 8)
	var before: Vector2 = screen.screen_to_world(anchor)
	screen.zoom_at(anchor, 1.4)
	check(screen.screen_to_world(anchor).distance_to(before) < 0.01, "zoom stays anchored under pointer")
	screen.pan_by(Vector2(53, -37))
	point = screen.world_to_screen(screen.node_positions["talk_1"])
	check(screen.hit_test(point) == "talk_1", "hit testing follows pan and zoom")
	screen.select_node("talk_1")
	check(screen.selected_id == "talk_1", "selection remains explicit, separate from purchase")
	screen.focus_node("run_1")
	var mouse := InputEventMouseButton.new()
	mouse.position = screen.world_to_screen(screen.node_positions["run_1"]) - screen.graph.global_position
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	screen.graph._gui_input(mouse)
	check(screen.selected_id == "run_1", "actual graph mouse handler selects drawn node")
	var old_zoom: float = screen.zoom
	mouse.button_index = MOUSE_BUTTON_WHEEL_UP
	screen.graph._gui_input(mouse)
	check(screen.zoom > old_zoom, "actual wheel handler zooms")
	mouse.button_index = MOUSE_BUTTON_MIDDLE
	screen.graph._gui_input(mouse)
	var old_pan: Vector2 = screen.pan
	var motion := InputEventMouseMotion.new()
	motion.position = mouse.position + Vector2(30, 15)
	motion.relative = Vector2(30, 15)
	motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	screen.graph._gui_input(motion)
	check(screen.pan.distance_to(old_pan + Vector2(30, 15)) < 0.01, "actual drag handler pans")
	motion.button_mask = 0
	screen.graph._gui_input(motion)
	check(not screen._dragging, "pointer release outside clears drag state")
	var fake = load("res://scripts/progression.gd").new()
	fake.save_enabled = false
	fake.catalog = Fixture.build()
	fake.coins = 1000
	screen.configure(fake.catalog, fake)
	screen.reset_view()
	await process_frame
	check(screen.node_positions.size() == 144, "separate 144-node fixture renders all catalog nodes")
	var all_reachable: bool = true
	var distinct: Dictionary = {}
	for item in fake.catalog:
		var id: String = item.id
		var node_at: Vector2 = screen.node_positions[id]
		distinct[node_at] = true
		screen.focus_node(id)
		var pixel: Vector2 = screen.world_to_screen(node_at)
		if screen.hit_test(pixel) != id:
			all_reachable = false
	check(distinct.size() == 144, "144 fixture positions are distinct")
	check(all_reachable, "all 144 nodes can be focused and hit")
	screen.pan_by(Vector2(-500, 320))
	screen.zoom_at(Vector2(450, 390), 0.7)
	screen.focus_node("fixture_12_11")
	check(screen.hit_test(screen.world_to_screen(screen.node_positions["fixture_12_11"])) == "fixture_12_11", "outermost ring remains navigable after pan/zoom")
	screen.configure(scene.progression.catalog, scene.progression)
	check(screen.node_positions.size() == 15, "fixture never becomes gameplay content")
	screen.select_node("talk_1")
	check(screen.purchase_button.disabled, "purchased node button shows maximum state")
	screen.select_node("talk_3")
	check(screen.purchase_button.disabled and screen._status_label.text.begins_with("SEALED"), "locked node explains prerequisite")
	screen.select_node("run_2")
	scene.progression.coins = 0
	screen.update_state()
	check(screen.purchase_button.disabled and screen._status_label.text.begins_with("AWAITING"), "insufficient funds visibly disable purchase")


func _test_relaunch() -> void:
	var path: String = "user://integration_round_loop_%d.json" % Time.get_ticks_usec()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = path
	root.add_child(scene)
	scene.set_process(false)
	scene.player.position = scene.groups[0].position
	scene.advance_round(11.0)
	scene.ritual_screen.select_node("run_1")
	scene.ritual_screen.purchase_button.pressed.emit()
	check(scene.progression.purchased.has("run_1") and scene.coins == 3, "screen button persists an actual earned purchase")
	scene.ritual_screen.next_button.pressed.emit()
	check(scene.round_active and scene.round_number == 2, "screen next-round button transitions")
	scene.queue_free()
	await process_frame
	var loaded = load("res://scenes/main.tscn").instantiate()
	loaded.save_path_override = path
	root.add_child(loaded)
	loaded.set_process(false)
	check(loaded.coins == 3 and loaded.total_recruits == 3 and loaded.round_number == 2, "relaunch restores currency, recruitment count and round")
	check(is_equal_approx(loaded.player.movement_speed, 207.0), "relaunch reapplies purchased running effect")
	check(loaded.round_active and loaded.seconds_left == 11.0 and loaded.player.position == loaded.START_POSITION, "relaunch starts a fresh round at entrance")
	loaded.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _test_migrated_rank_loop() -> void:
	var path: String = "user://integration_rank_loop_%d.json" % Time.get_ticks_usec()
	var legacy_purchases: Dictionary = {}
	for branch in ["talk", "persuade", "run"]:
		for tier in range(1, 4):
			legacy_purchases["%s_%d" % [branch, tier]] = true
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 1, "coins": 54, "total_recruits": 123, "round_number": 7, "purchased": legacy_purchases}))
	file.close()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = path
	root.add_child(scene)
	scene.set_process(false)
	check(scene.coins == 54 and scene.total_recruits == 123 and scene.round_number == 7, "v1 main-scene load preserves wallet and counters")
	check(scene.progression.rank("talk_3") == 1 and scene.progression.rank("run_3") == 1, "v1 purchases become first ranks, not free maximums")
	check(is_equal_approx(scene.player.movement_speed, 261.0) and is_equal_approx(scene.progression.speech_interval(), 0.625), "v1 gameplay effects remain unchanged before new purchases")
	scene.round_active = false
	scene.set_ritual_visible(true)
	var screen = scene.ritual_screen
	screen.select_node("talk_3")
	check(screen.get_selected_rank() == 1 and not screen.purchase_button.disabled, "partially ranked node offers its next purchase")
	var before: int = scene.coins
	screen.purchase_button.pressed.emit()
	check(scene.progression.rank("talk_3") == 2 and scene.coins == before - 18, "rank button buys exactly one rank at displayed price")
	check(not scene.purchase_upgrade("talk_3", 1) and scene.coins == before - 18, "duplicate stale purchase cannot spend twice")
	check(screen.purchase_button.disabled and screen.get_selected_rank() == 2, "maximum rank refreshes selection and disables purchase")
	for id in ["persuade_3", "run_3"]:
		screen.select_node(id)
		screen.purchase_button.pressed.emit()
	check(scene.coins == 0 and is_equal_approx(scene.player.movement_speed, 288.0), "final ranks apply distinct live effects and spend exact wallet")
	scene.queue_free()
	await process_frame
	var loaded = load("res://scenes/main.tscn").instantiate()
	loaded.save_path_override = path
	root.add_child(loaded)
	loaded.set_process(false)
	check(loaded.progression.rank("talk_3") == 2 and loaded.progression.rank("persuade_3") == 2 and loaded.progression.rank("run_3") == 2, "ranked main-scene reload restores all maximum ranks")
	check(loaded.coins == 0 and loaded.total_recruits == 123 and loaded.round_number == 7, "rank migration and purchases retain unrelated progression on reload")
	check(is_equal_approx(1.0 / loaded.progression.speech_interval(), 1.9) and is_equal_approx(loaded.player.movement_speed, 288.0), "relaunch reapplies full ranked effects")
	loaded.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
