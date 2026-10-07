extends SceneTree
## Title-screen new game against the real scene, with an isolated save fixture.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_new_game.gd
const FIXTURE: String = "user://test_new_game_save.json"
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
	_clean()
	var scene = await _open()
	scene.round_active = false
	scene.progression.coins = 500
	scene.progression.total_recruits = 400
	scene.progression.available_recruits = 400
	for id in ["persuade_1", "persuade_2", "persuade_3", "meadow_1", "helper_1"]:
		check(scene.purchase_upgrade(id), "setup purchase: " + id)
	scene.progression.round_number = 7
	check(scene.progression.save_progress() and scene.groups.size() == 4 and is_instance_valid(scene.helper), "an established game is saved")
	var established: String = FileAccess.get_file_as_string(FIXTURE)
	scene.start_new_game()
	check(scene.progression.round_number == 7 and scene.progression.rank("meadow_1") == 1, "a new game cannot be started from play, only from the title")
	scene.show_title()
	check(scene.title_screen.has_progress and scene.title_screen.new_game_button.visible, "the title offers a new game and knows there is progress to lose")
	scene.title_screen.new_game_button.pressed.emit()
	check(scene.title_active and scene.progression.round_number == 7, "the first press only asks for confirmation")
	var coins_before: int = scene.progression.coins
	scene.title_screen.cancel_new_game_button.pressed.emit()
	check(scene.title_active and scene.progression.coins == coins_before and scene.progression.rank("meadow_1") == 1 and FileAccess.get_file_as_string(FIXTURE) == established, "keeping the save changes nothing")
	# A failed write keeps the current game in memory and on disk.
	var path: String = scene.progression.save_path
	scene.progression.save_path = "user://missing_new_game_directory/save.json"
	scene.title_screen.new_game_button.pressed.emit()
	scene.title_screen.confirm_new_game_button.pressed.emit()
	check(scene.title_active and scene.progression.rank("meadow_1") == 1 and scene.progression.coins > 0 and not scene.title_screen.feedback_label.text.is_empty(), "a failed save keeps the game and explains why on the title")
	scene.progression.save_path = path
	var saved_before: String = FileAccess.get_file_as_string(FIXTURE)
	scene.title_screen.new_game_button.pressed.emit()
	scene.title_screen.confirm_new_game_button.pressed.emit()
	var progression = scene.progression
	check(not scene.title_active and scene.round_active and scene.seconds_left == scene.ROUND_SECONDS and scene.player.position == scene.START_POSITION, "confirming leaves the title and begins round 1 at the entrance")
	check(progression.coins == 0 and progression.total_recruits == 0 and progression.available_recruits == 0 and progression.round_number == 1 and progression.purchased.is_empty() and progression.encounter_stage == 0, "wallets, lifetime history, ranks and round reset")
	check(scene.groups.size() == 3 and scene.wanderers.size() == 5 and not is_instance_valid(scene.helper) and scene.player.movement_speed == scene.BASE_RUN_SPEED, "the village returns to its opening audiences and stats")
	check(FileAccess.get_file_as_string(FIXTURE + ".previous") == saved_before and saved_before == established, "the replaced save is kept byte-for-byte beside the new one")
	scene.queue_free()
	await process_frame
	var reloaded = await _open()
	check(reloaded.progression.round_number == 1 and reloaded.progression.purchased.is_empty() and reloaded.progression.coins == 0 and reloaded.groups.size() == 3, "relaunch loads the fresh game")
	# From Bellmarket, a new game returns to Bramblewick and drops password access.
	reloaded.round_active = false
	check(reloaded.travel_to("bellmarket", true) and reloaded.progression.active_area == "bellmarket" and reloaded.progression.level_select_unlocked, "setup: travelled to Bellmarket by password")
	reloaded.show_title()
	reloaded.title_screen.new_game_button.pressed.emit()
	check(reloaded.title_screen._new_game_confirm.visible, "being in Bellmarket counts as progress worth confirming")
	reloaded.title_screen.confirm_new_game_button.pressed.emit()
	check(reloaded.progression.active_area == "bramblewick" and not reloaded.progression.level_select_unlocked and reloaded.progression.catalog.size() == 33 and reloaded.groups.size() == 3 and reloaded.wanderers.size() == 5 and reloaded.encounter == null, "a new game from Bellmarket starts in Bramblewick's circle and village")
	check(FileAccess.get_file_as_string(FIXTURE + ".previous").contains("bellmarket"), "a second new game keeps the save it just replaced")
	reloaded.queue_free()
	await process_frame
	_clean()
	print("NEW GAME RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _open():
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = FIXTURE
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	await process_frame
	return scene


func _clean() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt", ".previous"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)
