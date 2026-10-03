extends SceneTree
## Exit the real game through its button; only dedicated fixture saves are used.
const SETTINGS_PATH: String = "user://exit_settings_fixture.json"
const PROGRESS_PATH: String = "user://exit_progress_fixture.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.settings.path = SETTINGS_PATH
	scene.settings.save_enabled = true
	scene.progression.save_path = PROGRESS_PATH
	scene.progression.save_enabled = true
	scene.set_settings_visible(true)
	await process_frame
	await process_frame
	scene.settings_screen.sliders.music.value = 37
	scene.progression.coins = 17
	# The click must flush immediately, before the preference debounce timer.
	var motion := InputEventMouseMotion.new()
	motion.position = scene.settings_screen.exit_button.get_global_rect().get_center()
	root.push_input(motion, true)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = scene.settings_screen.exit_button.get_global_rect().get_center()
		root.push_input(click, true)
	var saved = load("res://scripts/settings_store.gd").new()
	saved.path = SETTINGS_PATH
	saved.load_settings()
	var progress = load("res://scripts/progression.gd").new()
	progress.save_path = PROGRESS_PATH
	progress.load_catalog()
	progress.load_progress()
	var passed: bool = saved.values.music == 0.37 and progress.coins == 17 and scene.settings_timer.is_stopped()
	for path in [SETTINGS_PATH, PROGRESS_PATH]:
		for suffix in ["", ".tmp", ".bak", ".corrupt"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	if not passed:
		print("Exit diagnostics: music=%s coins=%s pending=%s button=%s" % [saved.values.music, progress.coins, not scene.settings_timer.is_stopped(), scene.settings_screen.exit_button.get_global_rect()])
		push_error("EXIT RESULT: preferences or progression were not flushed")
		quit(1)
		return
	print("EXIT RESULT: actual button click flushed preferences and progression; waiting for requested shutdown")
	# If the button failed to quit, this watchdog makes the test fail.
	create_timer(2.0).timeout.connect(func() -> void:
		push_error("EXIT RESULT: the game did not quit")
		quit(1)
	)
