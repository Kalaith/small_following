extends SceneTree
## UI-only checks: no scene progression or ordinary save files are opened.
const TitleScreen = preload("res://scripts/title_screen.gd")
var failures: int = 0
var checks: int = 0
var requested_levels: Array[String] = []
var continue_count: int = 0
var settings_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("TITLE: " + description)


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var title := TitleScreen.new()
	title.configure("bramblewick", false)
	root.add_child(title)
	title.level_requested.connect(func(area_id: String) -> void: requested_levels.append(area_id))
	title.continue_requested.connect(func() -> void: continue_count += 1)
	title.settings_requested.connect(func() -> void: settings_count += 1)
	await process_frame
	check(not title.unlocked and not title._level_choices.visible, "level choices start hidden")
	title.level_two_button.pressed.emit()
	check(requested_levels.is_empty(), "hidden button cannot request a locked level")
	for invalid in ["", "plzktks", "PLZKTK", " PLZKTKS", "PLZKTKS "]:
		check(not title.submit_password(invalid) and not title.unlocked, "password is exact: " + invalid)
	check(not title.feedback_label.text.is_empty(), "incorrect password has visible feedback")
	title.continue_button.pressed.emit()
	check(continue_count == 1, "normal play remains available without password")
	await _capture("title-screen")
	title.password_input.text = "PLZKTKS"
	title.password_input.text_submitted.emit(title.password_input.text)
	check(title.unlocked and title._level_choices.visible and title.password_input.text.is_empty(), "password submit reveals both levels and clears entry")
	title.level_one_button.pressed.emit()
	title.level_two_button.pressed.emit()
	check(requested_levels == ["bramblewick", "bellmarket"], "each implemented level emits its stable area id")
	title.configure("bellmarket", true)
	check(title.unlocked and title._journey_label.text.contains("Bellmarket"), "reconfiguration preserves this session's shortcut")
	check(not title.submit_password("wrong") and title.unlocked, "subsequent incorrect text does not revoke the open session")
	title.submit_password("PLZKTKS")
	await process_frame
	check(Rect2(Vector2.ZERO, title.size).encloses(title.level_two_button.get_global_rect()), "second level stays within base viewport")
	await _capture("title-level-select")
	title.queue_free()
	await process_frame
	var reopened := TitleScreen.new()
	root.add_child(reopened)
	check(not reopened.unlocked, "new title instance does not persist password access")
	reopened.queue_free()
	await process_frame
	print("TITLE RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _capture(filename: String) -> void:
	var destination: String = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			destination = argument.trim_prefix("--capture-dir=")
	if destination.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(destination.path_join(filename + ".png")) == OK, "rendered title capture saved")
