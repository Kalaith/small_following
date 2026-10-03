extends SceneTree
## Completion derives from catalog ranks; isolated fixtures never touch player saves.
const Progression = preload("res://scripts/progression.gd")
const FIXTURE: String = "user://test_demo_completion_fixture.json"
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
		push_error("DEMO COMPLETION: " + description)


func fresh() -> RefCounted:
	var state = Progression.new()
	state.save_path = FIXTURE
	state.load_catalog()
	return state


func clean_fixture() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)


func fill_ranks(state: RefCounted) -> void:
	for entry in state.catalog:
		state.purchased[entry.id] = state.max_rank(entry.id)


func action(name: String) -> void:
	var event: InputEventKey = InputMap.action_get_events(name)[0].duplicate()
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)


func click_core(screen) -> void:
	var event := InputEventMouseButton.new()
	event.position = screen.world_to_screen(Vector2.ZERO) - screen.graph.global_position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	screen.graph._gui_input(event)
	event.pressed = false
	screen.graph._gui_input(event)


func _run() -> void:
	clean_fixture()
	var empty = Progression.new()
	check(not empty.is_circle_complete(), "empty catalog cannot complete a circle")
	var state = fresh()
	check(not state.is_circle_complete(), "unbought current catalog remains incomplete")
	state.encounter_stage = 4
	check(state.map_complete() and not state.is_circle_complete(), "Priest victory remains distinct from all-ranks completion")
	for entry in state.catalog:
		state.purchased[entry.id] = 1
	check(not state.is_circle_complete(), "one rank on every node is insufficient when more ranks exist")
	fill_ranks(state)
	check(state.is_circle_complete(), "every current maximum rank completes the circle")
	var extra: Dictionary = state.catalog[0].duplicate(true)
	extra.id = "test_future_circle_rank"
	state.catalog.append(extra)
	check(not state.is_circle_complete(), "adding catalog content requires its ranks without updating completion code")
	state.purchased[extra.id] = int(extra.max_rank)
	check(state.is_circle_complete(), "completion includes the additional catalog definition")
	state.catalog.pop_back()
	state.purchased.erase(extra.id)
	state.purchased.talk_3 = 1
	state.coins = 17
	check(not state.try_purchase("talk_3", 1) and not state.is_circle_complete(), "unaffordable final rank cannot light the centre")
	state.coins = 55
	state.encounter_stage = 2
	state.total_recruits = 123
	state.round_number = 8
	state.save_path = "user://missing_demo_completion_test_directory/save.json"
	check(not state.try_purchase("talk_3", 1) and not state.is_circle_complete() and state.rank("talk_3") == 1 and state.coins == 55, "failed final-rank save cannot grant completion or spend donations")
	state.save_path = FIXTURE
	check(state.try_purchase("talk_3", 1) and state.is_circle_complete() and state.coins == 37, "successful final rank lights the centre and charges only its existing price")
	check(not state.map_complete(), "all ranks do not grant the separate Priest victory")
	var restored = fresh()
	check(restored.load_progress() and restored.is_circle_complete(), "completed save reload derives completion without a new flag")
	check(restored.purchased == state.purchased and restored.coins == 37 and restored.total_recruits == 123 and restored.round_number == 8 and restored.encounter_stage == 2, "completed-save reload preserves ranks, donations, recruitment, round and encounter stage")
	var stored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(stored.schema_version == 2 and stored.size() == 6, "completion adds no save-schema fields")
	await _test_screen()
	clean_fixture()
	print("DEMO COMPLETION RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_screen() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = FIXTURE
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.advance_round(100.0)
	await process_frame
	var screen = scene.ritual_screen
	check(screen.is_circle_complete() and not screen.completion_button.disabled and not screen.demo_message_visible(), "completed reload enables the centre without automatically opening a notice")
	# Exercise the UI's live final-purchase transition using the existing transactional action.
	scene.progression.purchased.talk_3 = 1
	screen.update_state()
	click_core(screen)
	check(not screen.demo_message_visible() and screen.completion_button.disabled and not screen.open_demo_message(), "incomplete centre ignores clicks and disables its navigation alternative")
	check(scene.purchase_upgrade("talk_3", 1) and screen.is_circle_complete() and not screen.completion_button.disabled, "last purchase updates the centre immediately through the normal purchase action")
	check(not screen.demo_message_visible(), "last purchase leaves the bright centre available for deliberate activation")
	var saved_text: String = FileAccess.get_file_as_string(FIXTURE)
	var saved_ranks: Dictionary = scene.progression.purchased.duplicate(true)
	var saved_coins: int = scene.coins
	for target_zoom in [0.18, 0.6, 1.8]:
		screen.reset_view()
		screen.zoom_at(screen.world_to_screen(Vector2.ZERO), target_zoom / screen.zoom)
		screen.pan_by(Vector2(47, -31))
		var centre: Vector2 = screen.world_to_screen(Vector2.ZERO)
		check(screen.completion_hit_test(centre) and not screen.completion_hit_test(centre + Vector2(100, 0)), "centre hit area follows pan and zoom %.2f" % target_zoom)
		var hover := InputEventMouseMotion.new()
		hover.position = centre - screen.graph.global_position
		screen.graph._gui_input(hover)
		check(screen._core_hovered and screen.graph.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "lit centre hover advertises clicking at zoom %.2f" % target_zoom)
		click_core(screen)
		check(screen.demo_message_visible() and screen.demo_message_label.text == "This is the end of the demo", "transformed centre opens exact demo message at zoom %.2f" % target_zoom)
		var overlay_id: int = screen._demo_overlay.get_instance_id()
		check(screen.open_demo_message() and screen._demo_overlay.get_instance_id() == overlay_id, "repeated activation reuses one notice at zoom %.2f" % target_zoom)
		screen.demo_continue_button.pressed.emit()
		check(not screen.demo_message_visible() and screen.visible and screen.is_circle_complete(), "Keep playing dismisses without losing completion at zoom %.2f" % target_zoom)
	screen.pan_by(Vector2(2000, 0))
	check(not screen.completion_hit_test(screen.world_to_screen(Vector2.ZERO)), "clipped centre cannot receive an off-graph click")
	screen.completion_button.pressed.emit()
	check(screen.demo_message_visible(), "fixed centre control remains usable when the graph centre is panned away")
	var before: Vector2 = scene.player.position
	Input.action_press("move_left")
	scene.player.set_physics_process(true)
	for frame in range(4):
		await physics_frame
	Input.action_release("move_left")
	scene.player.set_physics_process(false)
	check(scene.player.position.distance_to(before) > 1.0 and not paused and screen.demo_message_visible(), "normal movement input remains active while the demo notice is open")
	action("toggle_settings")
	await process_frame
	check(not screen.demo_message_visible() and not scene.settings_screen.visible, "Esc dismisses the notice before opening settings")
	action("toggle_settings")
	await process_frame
	check(scene.settings_screen.visible, "a following Esc retains the existing settings action")
	scene.set_settings_visible(false)
	screen.open_demo_message()
	scene.settings_button.pressed.emit()
	check(scene.settings_screen.visible and not screen.demo_message_visible(), "opening settings dismisses the notice underneath")
	scene.set_settings_visible(false)
	screen.open_demo_message()
	action("toggle_ritual")
	await process_frame
	check(not screen.visible and not screen.demo_message_visible(), "Tab returns to the village and dismisses the notice")
	action("toggle_ritual")
	await process_frame
	check(screen.visible and not screen.demo_message_visible(), "reopening the ritual does not resurrect its dismissed notice")
	screen.open_demo_message()
	screen.configure(scene.progression.catalog, scene.progression)
	check(not screen.demo_message_visible() and screen.is_circle_complete(), "catalog reconfiguration dismisses transient UI and recomputes completion")
	check(scene.coins == saved_coins and scene.progression.purchased == saved_ranks and FileAccess.get_file_as_string(FIXTURE) == saved_text, "open, repeat, dismissal, movement and navigation never reward, spend or save progression")
	screen.open_demo_message()
	action("next_round")
	await process_frame
	check(scene.round_active and not screen.visible and not screen.demo_message_visible() and scene.round_number == 9, "Enter continues into the next round and dismisses the notice")
	scene.advance_round(100.0)
	check(screen.visible and not screen.demo_message_visible() and screen.is_circle_complete(), "continued play returns to the completed circle with no automatic notice")
	screen.open_demo_message()
	screen.next_button.pressed.emit()
	check(scene.round_active and not screen.demo_message_visible(), "existing next-round button remains a valid completion exit")
	scene.queue_free()
	await process_frame
