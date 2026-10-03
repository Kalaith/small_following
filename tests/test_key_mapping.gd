extends SceneTree
## Physical key events catch incorrect serialized codes that action_press misses.
const Keys = preload("res://scripts/key_bindings.gd")
const Store = preload("res://scripts/settings_store.gd")
const FIXTURE: String = "user://key_mapping_test_fixture.json"
const PROGRESSION_FIXTURE: String = "user://key_mapping_progression_fixture.json"
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)


func key_event(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.game_audio.output_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	for phase in ["village", "ritual", "settings"]:
		if phase == "ritual":
			scene.advance_round(20.0)
		elif phase == "settings":
			scene.set_settings_visible(true)
		for pair in [[KEY_LEFT, Vector2.LEFT], [KEY_RIGHT, Vector2.RIGHT], [KEY_UP, Vector2.UP], [KEY_DOWN, Vector2.DOWN], [KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
			scene.player.position = scene.START_POSITION
			key_event(pair[0], true)
			for frame in range(5):
				await physics_frame
			var travel: Vector2 = scene.player.position - scene.START_POSITION
			check(travel.dot(pair[1]) > 0.0 and absf(travel.cross(pair[1])) < 0.01, "%s moves correctly in %s" % [OS.get_keycode_string(pair[0]), phase])
			key_event(pair[0], false)
			await physics_frame
	key_event(KEY_END, true)
	check(Input.get_vector("move_left", "move_right", "move_up", "move_down") == Vector2.ZERO, "End is not movement")
	key_event(KEY_END, false)
	await test_bindings(scene)
	scene.queue_free()
	await process_frame
	print("KEY MAPPING RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func tap(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		root.push_input(event)


func click(button: Control) -> void:
	click_at(button.get_global_rect().get_center())


func click_at(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)


func cleanup() -> void:
	for path in [FIXTURE, PROGRESSION_FIXTURE]:
		for suffix in ["", ".bak", ".tmp", ".corrupt"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)


func test_bindings(scene) -> void:
	cleanup()
	var page = scene.settings_screen
	if DisplayServer.get_name() == "headless":
		page.tabs.current_tab = 1
	else:
		var bar: TabBar = page.tabs.get_tab_bar()
		click_at(bar.global_position + bar.get_tab_rect(1).get_center())
	check(page.tabs.current_tab == 1, "key mapping tab opens (real click on display)")
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		# Dummy font metrics cannot establish pointer geometry; display run clicks it.
		page.binding_buttons.move_left[0].pressed.emit()
	else:
		click(page.binding_buttons.move_left[0])
	check(page.capture_action == "move_left", "binding button starts key capture (real click on display)")
	tap(KEY_J)
	check(page.capture_action.is_empty() and scene.settings.key_bindings.move_left[0] == KEY_J, "physical J event assigns and finishes capture")
	check(page.binding_buttons.move_left[0].text == "J", "binding label reflects the assigned key")
	scene.player.position = scene.START_POSITION
	key_event(KEY_J, true)
	for frame in range(5):
		await physics_frame
	check(scene.player.position.x < scene.START_POSITION.x, "rebound key moves the actual player while settings remain open")
	key_event(KEY_J, false)
	key_event(KEY_A, true)
	check(not Input.is_action_pressed("move_left"), "replaced primary no longer triggers movement")
	key_event(KEY_A, false)
	key_event(KEY_LEFT, true)
	check(Input.is_action_pressed("move_left"), "rebinding primary retains alternate arrow")
	key_event(KEY_LEFT, false)
	var gamepad := InputEventJoypadMotion.new()
	gamepad.axis = JOY_AXIS_LEFT_X
	gamepad.axis_value = -1.0
	check(InputMap.event_is_action(gamepad, "move_left"), "gamepad movement mapping is preserved")
	page.begin_capture("move_left", 1)
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_L
	echo.pressed = true
	echo.echo = true
	root.push_input(echo)
	check(page.capture_action == "move_left" and scene.settings.key_bindings.move_left[1] == KEY_LEFT, "key repeat cannot assign a binding")
	tap(KEY_L)
	key_event(KEY_L, true)
	check(Input.is_action_pressed("move_left"), "new alternate key triggers movement")
	key_event(KEY_L, false)
	var alternate: Button = page.binding_buttons.move_left[1]
	var clear: Button = alternate.get_parent().get_child(alternate.get_index() + 1)
	if DisplayServer.get_name() == "headless":
		clear.pressed.emit()
	else:
		click(clear)
	check(scene.settings.key_bindings.move_left == [KEY_J, 0], "Clear removes only its row's alternate (real click on display)")
	scene._rebind_key("move_left", 1, KEY_LEFT)
	page.begin_capture("move_right", 0)
	tap(KEY_J)
	check(scene.settings.key_bindings.move_right[0] == KEY_D and page.capture_action == "move_right" and page.binding_message.text.contains("already assigned"), "conflict explains the existing action and preserves both mappings")
	tap(KEY_ESCAPE)
	check(page.visible and page.capture_action.is_empty(), "Escape cancels capture without closing settings")
	page.begin_capture("move_right", 0)
	var modified := InputEventKey.new()
	modified.physical_keycode = KEY_K
	modified.pressed = true
	modified.ctrl_pressed = true
	root.push_input(modified)
	check(page.binding_message.text.contains("without Shift") and scene.settings.key_bindings.move_right[0] == KEY_D, "modifier chords are rejected")
	page.tabs.current_tab = 0
	check(page.capture_action.is_empty(), "switching tabs cancels capture")
	page.tabs.current_tab = 1
	page.begin_capture("move_right", 0)
	var muted: bool = scene.game_audio.muted
	tap(KEY_M)
	check(scene.game_audio.muted == muted, "capturing an occupied shortcut does not activate it")
	tap(KEY_TAB)
	check(not page.visible and not scene.ritual_screen.visible and page.capture_action.is_empty(), "Tab during capture still returns to the village between rounds")
	scene.set_settings_visible(true)
	page.begin_capture("move_right", 0)
	var before: Vector2 = scene.player.position
	key_event(KEY_LEFT, true)
	for frame in range(5):
		await physics_frame
	check(scene.player.position.x < before.x, "movement remains available even during key capture")
	key_event(KEY_LEFT, false)
	page.cancel_button.pressed.emit()
	check(page.capture_action.is_empty(), "visible cancel button ends capture")
	check(not scene.settings.rebind("move_left", 0, 0).is_empty(), "primary key cannot be cleared")
	check(not scene.settings.rebind("move_left", 1, KEY_TAB).is_empty() and not scene.settings.rebind("move_left", 1, KEY_ESCAPE).is_empty(), "navigation keys cannot be assigned")
	scene._rebind_key("move_left", 1, 0)
	key_event(KEY_LEFT, true)
	check(not Input.is_action_pressed("move_left"), "clearing alternate removes its action")
	key_event(KEY_LEFT, false)
	scene._rebind_key("next_round", 0, KEY_N)
	check(scene.context_label.text.contains("N: next round") and scene.ritual_screen._hint_label.text.contains("N: next round"), "village and ritual hints follow changed shortcuts")
	scene._rebind_key("toggle_audio", 0, KEY_B)
	check(page.mute_button.text.ends_with("B"), "sound switch hint follows changed shortcut")
	tap(KEY_M)
	check(scene.game_audio.muted == muted, "old audio shortcut stops working")
	tap(KEY_B)
	check(scene.game_audio.muted != muted, "new audio shortcut works")
	scene.settings.path = FIXTURE
	scene.settings.save_enabled = true
	scene.set_settings_visible(false)
	var loaded := Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.key_bindings == scene.settings.key_bindings, "closing settings persists primary and cleared alternate slots")
	tap(KEY_ENTER)
	check(not scene.round_active, "old next-round key no longer starts a round")
	tap(KEY_N)
	check(scene.round_active, "rebound next-round key starts the actual next round")
	# Restart through normal loading, with both stores using explicit fixture paths.
	var restarted = load("res://scenes/main.tscn").instantiate()
	restarted.save_path_override = PROGRESSION_FIXTURE
	restarted.settings_path_override = FIXTURE
	restarted.game_audio.output_enabled = false
	root.add_child(restarted)
	restarted.set_process(false)
	await process_frame
	check(restarted.settings.key_bindings.move_left[0] == KEY_J and Keys.hint("move_left") == "J", "scene restart applies saved bindings")
	restarted.queue_free()
	await process_frame
	scene.set_settings_visible(true)
	page.reset_keys_button.pressed.emit()
	check(scene.settings.key_bindings == Keys.defaults() and Keys.hint("move_left") == "A", "restore defaults resets all keyboard slots")
	check(InputMap.event_is_action(gamepad, "move_left"), "restore defaults preserves gamepad bindings")
	scene.set_settings_visible(false)
	loaded.load_settings()
	check(loaded.key_bindings == Keys.defaults(), "restored defaults persist")
	var legacy: Dictionary = {"schema": 1, "values": Store.DEFAULTS.duplicate()}
	legacy.values.music = 0.37
	var file := FileAccess.open(FIXTURE, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	loaded = Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.values.music == 0.37 and loaded.key_bindings == Keys.defaults(), "older preferences retain audio and receive corrected default keys")
	for malformed in ["missing", "duplicate", "fraction", "reserved", "unknown", "empty primary", "extra slot", "boolean", "invalid code"]:
		var mapping: Dictionary = Keys.defaults()
		match malformed:
			"missing": mapping.erase("move_left")
			"duplicate": mapping.move_left[0] = KEY_D
			"fraction": mapping.move_left[0] = 65.5
			"reserved": mapping.move_left[0] = KEY_TAB
			"unknown": mapping.other_action = [KEY_J, 0]
			"empty primary": mapping.move_left[0] = 0
			"extra slot": mapping.move_left.append(KEY_J)
			"boolean": mapping.move_left[0] = true
			"invalid code": mapping.move_left[0] = 999999999
		check(not loaded.valid({"schema": 1, "values": Store.DEFAULTS, "key_bindings": mapping}), "reject malformed key data: " + malformed)
	loaded.rebind("move_left", 0, KEY_J)
	check(loaded.save_settings(), "custom mapping creates a valid save")
	loaded.rebind("move_left", 0, KEY_K)
	check(loaded.save_settings(), "replacement keeps mapping backup")
	file = FileAccess.open(FIXTURE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema": 1, "values": Store.DEFAULTS, "key_bindings": {}}))
	file.close()
	var recovered := Store.new()
	recovered.path = FIXTURE
	recovered.load_settings()
	check(recovered.key_bindings.move_left[0] == KEY_J and not recovered.last_error.is_empty(), "damaged binding save recovers validated backup")
	check(recovered.save_settings() and FileAccess.file_exists(FIXTURE + ".corrupt"), "recovery preserves damaged settings original")
	scene.settings.path = "user://missing_key_mapping_test_directory/settings.json"
	scene._rebind_key("move_left", 0, KEY_J)
	scene._save_settings()
	check(page.notice.text.contains("Could not save") and Keys.hint("move_left") == "J", "failed save keeps session binding and explains it")
	scene.settings.save_enabled = false
	scene._reset_keys()
	scene._save_settings()
	cleanup()
