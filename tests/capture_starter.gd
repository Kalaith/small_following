extends SceneTree
## Actual viewport captures of village, ritual and isolated scale fixture.
const Fixture = preload("res://tests/fixtures/ritual_fixture.gd")
var destination: String = "user://verification"
var failed: bool = false
var ritual_only: bool = false
var settings_only: bool = false
var economy_only: bool = false


func _initialize() -> void:
	_capture.call_deferred()


func save_frame(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(destination.path_join(filename))
	if result != OK:
		failed = true
		push_error("Viewport save failed: " + filename + " " + error_string(result))


func _capture() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			destination = argument.trim_prefix("--capture-dir=")
		elif argument == "--ritual-only":
			ritual_only = true
		elif argument == "--settings-only":
			settings_only = true
		elif argument == "--economy-only":
			economy_only = true
	DirAccess.make_dir_recursive_absolute(destination)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	# These are visual fixtures; audio has its own suite. Avoid Godot 4.2 Dummy
	# playback retaining native Ogg voices after an otherwise successful capture.
	scene.game_audio.output_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	if economy_only:
		await capture_recruit_economy(scene)
		await finish_capture(scene)
		return
	if settings_only:
		await capture_settings(scene)
		await finish_capture(scene)
		return
	if ritual_only:
		# Recheck changed ritual pixels without replaying unrelated village/audio fixtures.
		scene.advance_round(100.0)
		for frame in range(4):
			await process_frame
		scene.ritual_screen.overview_button.pressed.emit()
		await save_frame("ritual-seal-entry.png")
		await capture_demo_completion(scene)
		await capture_readability(scene)
		await capture_graph_fixture(scene)
		await finish_capture(scene)
		return
	scene.player.position = Vector2(645, 562)
	scene.player.get_node("Camera2D").reset_smoothing()
	scene.advance_round(1.5)
	scene._update_hud()
	for i in range(8):
		await process_frame
	await save_frame("starter-runtime.png")
	scene.set_settings_visible(true)
	await save_frame("settings-village.png")
	var original_size: Vector2i = root.size
	root.size = Vector2i(1024, 768)
	for i in range(4):
		await process_frame
	await save_frame("settings-compact.png")
	root.size = original_size
	scene.set_settings_visible(false)
	Input.action_press("move_right")
	for i in range(14):
		await physics_frame
	Input.action_release("move_right")
	await save_frame("starter-moving.png")
	scene.player.position = scene.groups[0].position + Vector2(70, 0)
	scene.advance_round(100.0)
	scene._update_hud()
	scene.ritual_screen.reset_view()
	await save_frame("starter-summary.png")
	scene.set_settings_visible(true)
	await save_frame("settings-ritual.png")
	scene.set_settings_visible(false)
	scene.ritual_screen.select_node("talk_1")
	scene.ritual_screen.purchase_button.pressed.emit()
	await save_frame("ritual-purchased.png")
	scene.ritual_screen.next_button.pressed.emit()
	await save_frame("starter-next-round.png")
	scene.advance_round(100.0)
	# Fund old first-rank progression only for the visual fixture, using normal purchase paths.
	scene.progression.coins = 200
	scene.progression.total_recruits = 250
	scene.progression.available_recruits = 250
	for item in scene.progression.catalog.slice(0, 9):
		if scene.progression.rank(item.id) == 0:
			scene.purchase_upgrade(item.id)
	scene.progression.coins = 54
	scene.ritual_screen.select_node("talk_3")
	await save_frame("ritual-rank-available.png")
	for id in ["talk_3", "persuade_3", "run_3"]:
		scene.ritual_screen.select_node(id)
		scene.ritual_screen.purchase_button.pressed.emit()
	scene.ritual_screen.select_node("talk_3")
	await save_frame("ritual-rank-max.png")
	await capture_full_clear(scene)
	scene.advance_round(100.0)
	await capture_expansion(scene)
	scene.progression.coins = 200
	scene.progression.total_recruits = 250
	scene.progression.available_recruits = 250
	for id in ["merchant_1", "merchant_2", "merchant_3", "merchant_4"]:
		scene.purchase_upgrade(id)
	scene.start_next_round()
	scene.player.position = Vector2(960, 675)
	scene.player.get_node("Camera2D").reset_smoothing()
	scene.advance_round(0.5)
	scene._update_hud()
	await save_frame("village-merchants.png")
	var merchants = scene.groups.back()
	merchants.tick_persuasion(1.0, 1.0, 9.0)
	scene._update_hud()
	await save_frame("merchant-reward.png")
	# Four digits exercise future reward readability without changing the catalog.
	merchants.donation = 1250
	merchants.recruit_listener(1)
	merchants.donation = scene.progression.merchant_donation()
	scene.groups[2].tick_persuasion(1.0, 1.0, 6.0)
	scene._update_hud()
	await save_frame("recruitment-rewards.png")
	await create_timer(1.0).timeout
	await save_frame("recruitment-rewards-settled.png")
	scene.advance_round(100.0)
	await capture_encounters(scene)
	await capture_demo_completion(scene)
	await capture_readability(scene)
	await capture_graph_fixture(scene)
	await finish_capture(scene)


func capture_recruit_economy(scene) -> void:
	# Only the changed wallet/cost states; no normal save or unrelated screen suite.
	scene.progression.add_donation(120, 40)
	scene.progression.purchased = {"talk_1": 1, "talk_2": 1, "talk_3": 1}
	scene._update_hud()
	await save_frame("economy-village.png")
	scene.advance_round(100.0)
	var screen = scene.ritual_screen
	screen.select_node("talk_3")
	await save_frame("economy-rank-ready.png")
	scene.progression.available_recruits = 0
	screen.update_state()
	await save_frame("economy-recruits-missing.png")
	scene.progression.coins = 0
	screen.update_state()
	await save_frame("economy-both-missing.png")
	scene.progression.coins = 6
	screen.select_node("run_1")
	await save_frame("economy-running.png")
	# Longest changed supporting-role details remain in the same narrow panel.
	scene.progression.coins = 1000
	scene.progression.available_recruits = 40
	scene.progression.purchased.merge({"persuade_1": 1, "persuade_2": 1, "persuade_3": 1, "meadow_1": 1})
	screen.select_node("helper_1")
	await save_frame("economy-helper.png")
	for item in scene.progression.catalog:
		scene.progression.purchased[item.id] = scene.progression.max_rank(item.id)
	scene.progression.available_recruits = 0
	screen.clear_selection()
	screen.completion_button.pressed.emit()
	if not screen.demo_message_visible():
		failed = true
		push_error("Zero available recruits blocked the completed centre")
	await save_frame("economy-demo.png")
	screen.dismiss_demo_message()


func capture_settings(scene) -> void:
	for frame in range(8):
		await process_frame
	scene.set_settings_visible(true)
	await save_frame("settings-village.png")
	scene.settings_screen.tabs.current_tab = 1
	for frame in range(4):
		await process_frame
	await save_frame("settings-keys.png")
	var key_scroll: ScrollContainer = scene.settings_screen.tabs.get_child(1).get_child(1)
	key_scroll.scroll_vertical = 1000
	await save_frame("settings-keys-shortcuts.png")
	key_scroll.scroll_vertical = 0
	scene.settings_screen.begin_capture("move_left", 0)
	await save_frame("settings-keys-capture.png")
	scene._rebind_key("move_left", 0, KEY_D)
	await save_frame("settings-keys-conflict.png")
	scene.settings_screen.cancel_capture()
	var original_size: Vector2i = root.size
	root.size = Vector2i(1024, 768)
	for frame in range(4):
		await process_frame
	await save_frame("settings-keys-compact.png")
	scene.settings_screen.tabs.current_tab = 0
	await save_frame("settings-compact.png")
	root.size = original_size
	scene.advance_round(100.0)
	for frame in range(4):
		await process_frame
	await save_frame("settings-ritual.png")


func capture_graph_fixture(scene) -> void:
	var fake = load("res://scripts/progression.gd").new()
	fake.save_enabled = false
	fake.catalog = Fixture.build()
	fake.coins = 1000
	scene.ritual_screen.configure(fake.catalog, fake)
	scene.ritual_screen.overview_button.pressed.emit()
	scene.ritual_screen._title_label.text = "144-node validation fixture"
	scene.ritual_screen._subtitle_label.text = "TEST DATA ONLY / NOT PLAYABLE UPGRADE CONTENT"
	await save_frame("ritual-144-fixture.png")
	scene.ritual_screen.focus_branch("test_11")
	scene.ritual_screen._subtitle_label.text = "TEST DATA ONLY / NOT PLAYABLE UPGRADE CONTENT"
	await save_frame("ritual-fixture-branch.png")
	scene.ritual_screen.focus_node("fixture_12_11")
	scene.ritual_screen._subtitle_label.text = "TEST DATA ONLY / NOT PLAYABLE UPGRADE CONTENT"
	await save_frame("ritual-fixture-focus.png")


func finish_capture(scene) -> void:
	print("RENDER CAPTURE: " + destination)
	# Complete scene teardown and deferred cleanup before shutting down servers.
	scene.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)


func capture_full_clear(scene) -> void:
	# Same competent route model as pacing tests: small reactions, ordinary 95px stops.
	scene.progression.total_recruits = 0
	scene.progression.available_recruits = 0
	scene.start_next_round()
	scene.player.set_physics_process(false)
	var order: Array[int] = [2, 0, 1]
	var index: int = 0
	var pause_steps: int = 12
	var steps: int = 0
	while scene.round_active and scene.round_recruits < 15 and steps < 700:
		await physics_frame
		var target = scene.groups[order[index]]
		if target.recruits == 5 and index < 2:
			index += 1
			target = scene.groups[order[index]]
			pause_steps = 6
		var direction := Vector2.ZERO
		if pause_steps > 0:
			pause_steps -= 1
		elif scene.player.position.distance_to(target.position) > 95.0:
			direction = scene.player.position.direction_to(target.position)
		scene.player.step_motion(direction, 1.0 / 60.0)
		scene.advance_round(1.0 / 60.0)
		steps += 1
	scene._update_hud()
	print("FULL CLEAR CAPTURE: %d recruits in %.3fs, %.3fs remaining" % [scene.round_recruits, steps / 60.0, scene.seconds_left])
	if scene.round_recruits != 15:
		failed = true
		push_error("Full-rank capture route failed to clear all three groups.")
	await save_frame("village-full-clear.png")


func capture_expansion(scene) -> void:
	scene.ritual_screen.select_node("run_5")
	await save_frame("ritual-expansion-locked.png")
	scene.progression.coins = 500
	scene.progression.total_recruits = 250
	scene.progression.available_recruits = 250
	for item in scene.progression.catalog.slice(9, 16):
		scene.purchase_upgrade(item.id)
	scene.ritual_screen.select_node("east_1")
	scene.ritual_screen.reset_view()
	await save_frame("ritual-expansion.png")
	scene.start_next_round()
	scene.player.position = scene.START_POSITION
	scene.player.get_node("Camera2D").reset_smoothing()
	scene._update_hud()
	await save_frame("village-expanded.png")
	for index in range(180):
		scene.advance_round(1.0 / 60.0)
	scene._update_hud()
	await save_frame("helper-speaking.png")
	scene.advance_round(100.0)
	scene.ritual_screen.select_node("helper_1")
	await save_frame("ritual-helper.png")


func capture_readability(scene) -> void:
	# Independent in-memory visual states keep gameplay captures and player saves intact.
	var screen = scene.ritual_screen
	var fixture = load("res://scripts/progression.gd").new()
	fixture.save_enabled = false
	if not fixture.load_catalog():
		failed = true
		push_error("Readability capture catalog failed: " + fixture.last_error)
		return
	fixture.coins = 9
	fixture.total_recruits = 250
	fixture.available_recruits = 250
	screen.configure(fixture.catalog, fixture)
	screen.overview_button.pressed.emit()
	await save_frame("ritual-readability-overview.png")
	# One purchased node, one open-but-unaffordable node, affordable roots and locked tiers.
	fixture.try_purchase("talk_1")
	fixture.coins = 6
	screen.select_node("talk_2")
	await save_frame("ritual-readability-states.png")
	fixture.coins = 1000
	for item in fixture.catalog.slice(0, 9):
		if fixture.rank(item.id) == 0:
			fixture.try_purchase(item.id)
	fixture.try_purchase("meadow_1")
	fixture.coins = 33
	screen.select_node("east_1")
	screen.reset_view()
	await save_frame("ritual-readability-missing.png")
	var hover := InputEventMouseMotion.new()
	hover.position = screen.world_to_screen(screen.node_positions["talk_5"]) - screen.graph.global_position
	screen.graph._gui_input(hover)
	await save_frame("ritual-readability-hover.png")
	screen.graph.mouse_exited.emit()
	fixture.coins = 1000
	fixture.try_purchase("talk_4")
	fixture.coins = 33
	screen.select_node("east_1")
	await save_frame("ritual-readability-east.png")
	if ritual_only:
		# These late requirements exercise the long, routed contextual connections.
		screen.select_node("priest_2")
		await save_frame("ritual-seal-priest-paths.png")
		screen.select_node("persuade_4")
		await save_frame("ritual-seal-creed-paths.png")
	screen.configure(scene.progression.catalog, scene.progression)


func capture_demo_completion(scene) -> void:
	# In-memory fixtures exercise both the final second rank and the actual centre input.
	var screen = scene.ritual_screen
	var fixture = load("res://scripts/progression.gd").new()
	fixture.save_enabled = false
	if not fixture.load_catalog():
		failed = true
		push_error("Demo capture catalog failed: " + fixture.last_error)
		return
	var final_id: String = ""
	for item in fixture.catalog:
		fixture.purchased[item.id] = fixture.max_rank(item.id)
		if fixture.max_rank(item.id) > 1:
			final_id = item.id
	if final_id.is_empty():
		final_id = fixture.catalog.back().id
	fixture.purchased[final_id] -= 1
	fixture.coins = fixture.next_cost(final_id)
	fixture.available_recruits = fixture.next_recruit_cost(final_id)
	fixture.total_recruits = fixture.available_recruits
	screen.configure(fixture.catalog, fixture)
	screen.overview_button.pressed.emit()
	screen.select_node(final_id)
	await save_frame("ritual-demo-incomplete.png")
	if screen.is_circle_complete() or not fixture.try_purchase(final_id):
		failed = true
		push_error("Demo capture final rank transition failed")
		return
	screen.update_state()
	screen.overview_button.pressed.emit()
	await save_frame("ritual-demo-ready.png")
	var click := InputEventMouseButton.new()
	click.position = screen.world_to_screen(Vector2.ZERO) - screen.graph.global_position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	screen.graph._gui_input(click)
	click.pressed = false
	screen.graph._gui_input(click)
	if not screen.demo_message_visible():
		failed = true
		push_error("Demo capture centre click did not open the message")
	await save_frame("ritual-demo-message.png")
	screen.demo_continue_button.pressed.emit()
	if screen.demo_message_visible():
		failed = true
		push_error("Demo capture message did not dismiss")
	await save_frame("ritual-demo-dismissed.png")
	screen.configure(scene.progression.catalog, scene.progression)


func capture_encounters(scene) -> void:
	scene.progression.coins = 5000
	scene.progression.total_recruits = 250
	scene.progression.available_recruits = 250
	for item in scene.progression.catalog:
		while scene.progression.rank(item.id) < scene.progression.max_rank(item.id):
			if not scene.purchase_upgrade(item.id):
				failed = true
				push_error("Could not prepare encounter capture: " + item.id)
				return
	for stage in range(4):
		scene.start_next_round()
		scene.player.position = Vector2(790, 660)
		scene.player.get_node("Camera2D").reset_smoothing()
		scene.advance_round(1.5)
		scene._update_hud()
		if stage == 0:
			await save_frame("opponent-arrival.png")
		scene.advance_round(2.9)
		scene._update_hud()
		await save_frame("opponent-%s.png" % scene.Encounter.PROFILES[stage].id)
		while scene.round_active and not scene.encounter.defeated:
			scene.advance_round(1.0 / 60.0)
		if not scene.encounter.defeated:
			failed = true
			push_error("Encounter capture failed to convince opponent")
			return
		scene._update_hud()
		if stage == 3:
			await save_frame("village-complete.png")
		scene.advance_round(100)
	scene.ritual_screen.overview_button.pressed.emit()
	await save_frame("ritual-map-complete.png")
	scene.ritual_screen.focus_node("priest_2")
	await save_frame("ritual-priest-details.png")
