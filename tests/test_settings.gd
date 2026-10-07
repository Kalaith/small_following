extends SceneTree
const Payout = preload("res://scripts/donation_popup.gd")
const Store = preload("res://scripts/settings_store.gd")
const FIXTURE: String = "user://settings_test_fixture.json"
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


func action(name: String) -> void:
	var event: InputEventKey = InputMap.action_get_events(name)[0].duplicate()
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)


func write_fixture(text: String) -> void:
	var file := FileAccess.open(FIXTURE, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func cleanup() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)


func _run() -> void:
	cleanup()
	var store := Store.new()
	store.path = FIXTURE
	store.values.music = 0.35
	check(store.save_settings(), "preferences save through a staged file")
	store.values.music = 0.7
	check(store.save_settings(), "replacement preserves previous preferences as backup")
	var loaded := Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.values.music == 0.7, "preferences round trip")
	write_fixture("broken")
	loaded = Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.values.music == 0.35 and not loaded.last_error.is_empty(), "invalid main recovers validated backup")
	check(loaded.save_settings() and FileAccess.get_file_as_string(FIXTURE + ".corrupt") == "broken", "recovery preserves damaged original before saving")
	write_fixture('{"schema":99,"values":{}}')
	loaded = Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.writes_blocked and not loaded.save_settings() and FileAccess.get_file_as_string(FIXTURE).contains("99"), "future preferences are preserved")
	write_fixture('{"schema":1,"values":{"music":0.6}}')
	loaded = Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.values.music == 0.6 and loaded.values.master == Store.DEFAULTS.master and loaded.values.fullscreen == Store.DEFAULTS.fullscreen, "a schema-1 file missing newer keys defaults them instead of failing")
	check(loaded.last_error.is_empty() and not loaded.writes_blocked, "a defaulted migration is not treated as a recovered or blocked file")
	check(loaded.save_settings(), "a migrated file can be saved forward")
	loaded = Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(int(JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)).schema) == Store.CURRENT_SCHEMA, "saving a migrated file writes the current schema")
	check(not store.valid({"schema": 1, "values": {"master": 9.0}}), "a present but out-of-range key still fails validation despite the migration path")
	write_fixture("broken")
	var corrupt_file := FileAccess.open(FIXTURE + ".corrupt", FileAccess.WRITE)
	corrupt_file.store_string("already recovered once")
	corrupt_file.close()
	var guard := Store.new()
	guard.path = FIXTURE
	guard.values.music = 0.9
	check(not guard.save_settings() and guard.last_error.contains(".corrupt"), "an existing .corrupt file blocks the save instead of being overwritten")
	check(FileAccess.get_file_as_string(FIXTURE + ".corrupt") == "already recovered once", "the earlier .corrupt recovery file is left untouched")
	DirAccess.remove_absolute(FIXTURE + ".corrupt")
	var invalid: Dictionary = Store.DEFAULTS.duplicate()
	invalid.master = 1.1
	check(not store.valid({"schema": 1, "values": invalid}), "out-of-range volume rejected")
	invalid.master = true
	check(not store.valid({"schema": 1, "values": invalid}), "boolean volume rejected")
	store.path = "user://missing_settings_test_directory/settings.json"
	check(not store.save_settings() and not store.last_error.is_empty(), "failed write reports session-only changes")
	cleanup()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	check(not scene.settings.save_enabled, "ordinary isolated scenes never read/write user preferences")
	scene.settings.path = FIXTURE
	scene.settings.save_enabled = true
	var page = scene.settings_screen
	scene.settings_button.pressed.emit()
	check(page.visible and not scene.settings_button.visible, "visible Settings button opens the page")
	page.sliders.music.value = 25
	page.sliders.master.value = 50
	check(scene.game_audio.volumes.music == 0.25 and scene.game_audio.volumes.master == 0.5, "sliders apply separate music and master levels")
	check(absf(scene.game_audio.music.volume_db - (scene.game_audio.MUSIC_DB + linear_to_db(0.125))) < 0.001, "master and channel gains combine correctly")
	page.sliders.footsteps.value = 0
	page.sliders.speech.value = 0
	check(scene.game_audio.footsteps.volume_db == -80 and scene.game_audio.voice.volume_db == -80, "zero volume silences footsteps and speech independently")
	page.mute_button.button_pressed = true
	check(scene.game_audio.muted and scene.game_audio.music.volume_db == -80, "mute switch silences all audio")
	action("toggle_audio")
	await process_frame
	check(not page.mute_button.button_pressed and not scene.game_audio.muted, "M updates the open page without losing slider values")
	action("toggle_voice")
	await process_frame
	check(page.speech_button.button_pressed and scene.game_audio.voice_muted, "V updates the speech switch")
	var before: Vector2 = scene.player.position
	Input.action_press("move_left")
	for i in range(10):
		await physics_frame
	Input.action_release("move_left")
	check(scene.player.position.x < before.x, "direct movement continues with settings open")
	var remaining: float = scene.seconds_left
	scene.advance_round(0.5)
	check(scene.seconds_left == remaining - 0.5, "settings do not pause the round timer")
	scene.advance_round(20.0)
	check(page.visible and scene.ritual_screen.visible and not scene.round_active, "round can end into ritual underneath settings")
	scene.progression.coins = 20
	scene.ritual_screen.select_node("talk_1")
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = scene.ritual_screen.purchase_button.get_global_rect().get_center()
		root.push_input(click)
	check(scene.progression.rank("talk_1") == 0 and scene.coins == 20, "settings backdrop blocks clicks on an affordable ritual purchase")
	var round_before: int = scene.round_number
	action("next_round")
	await process_frame
	check(scene.round_number == round_before, "Enter cannot start a hidden next round")
	action("toggle_settings")
	await process_frame
	check(not page.visible and scene.ritual_screen.visible, "Esc returns to the underlying ritual")
	loaded = Store.new()
	loaded.path = FIXTURE
	loaded.load_settings()
	check(loaded.values.music == 0.25 and loaded.values.voice_muted, "closing the page flushes latest preferences")
	action("toggle_settings")
	await process_frame
	action("toggle_ritual")
	await process_frame
	check(not page.visible and not scene.ritual_screen.visible, "Tab reveals the village between rounds from settings")
	scene.start_next_round()
	check(scene.round_active and scene.game_audio.volumes.music == 0.25, "new rounds retain sound settings")
	scene.settings.path = "user://missing_settings_test_directory/settings.json"
	scene._save_settings()
	check(page.notice.text.contains("Could not save"), "failed preference writes are explained on the page")
	scene.settings.path = FIXTURE
	scene.settings.save_enabled = true
	scene.set_settings_visible(true)
	check(page.get_viewport().gui_get_focus_owner() == page.mute_button, "opening settings focuses the first control for keyboard and gamepad")
	page.motion_button.button_pressed = true
	check(scene.settings.values.reduce_motion and scene.player.reduce_motion and Payout.reduce_motion, "reduce motion switch reaches the player and payouts")
	scene._save_settings()
	var motion_loaded := Store.new()
	motion_loaded.path = FIXTURE
	motion_loaded.load_settings()
	check(motion_loaded.values.reduce_motion, "reduce motion persists")
	check(not motion_loaded.valid({"schema": 2, "values": {"reduce_motion": 1}}), "non-boolean reduce motion is rejected")
	page.tabs.current_tab = 0
	var bumper := InputEventJoypadButton.new()
	bumper.button_index = JOY_BUTTON_RIGHT_SHOULDER
	bumper.pressed = true
	root.push_input(bumper)
	check(page.tabs.current_tab == 1, "right bumper moves to the next settings tab")
	var back := InputEventJoypadButton.new()
	back.button_index = JOY_BUTTON_B
	back.pressed = true
	root.push_input(back)
	check(not page.visible, "gamepad B closes settings")
	page.motion_button.button_pressed = false
	Payout.reduce_motion = false
	scene.settings.path = FIXTURE
	if DisplayServer.get_name() != "headless":
		var original_mode: int = root.mode
		scene.set_settings_visible(true)
		page.fullscreen_button.button_pressed = true
		await create_timer(0.2).timeout
		check(scene.is_fullscreen(), "fullscreen switch changes the actual window mode")
		action("toggle_fullscreen")
		await create_timer(0.2).timeout
		scene._refresh_settings()
		check(not scene.is_fullscreen() and not page.fullscreen_button.button_pressed, "F11 restores windowed mode and synchronizes the switch")
		root.mode = original_mode
	scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	cleanup()
	print("SETTINGS RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
