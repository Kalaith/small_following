extends SceneTree
## Integration uses an isolated in-memory game; no ordinary progression is loaded.
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("MARKET FLOW: " + description)
	else:
		print("PASS: " + description)


func type_key(code: int, unicode: int = 0) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.unicode = unicode
		event.pressed = pressed
		root.push_input(event)


func _run() -> void:
	var game = load("res://scenes/title.tscn").instantiate()
	game.persistence_enabled = false
	game.game_audio.output_enabled = false
	root.add_child(game)
	game.set_process(false)
	await process_frame
	check(game.title_active and game.title_screen.visible and not game.round_active, "project entry opens title without spending round time")
	game.advance_round(20.0)
	check(game.seconds_left == game.ROUND_SECONDS and game.coins == 0, "title does not advance earning or timer")
	check(not game.title_screen.submit_password("wrong") and not game.title_screen.unlocked, "wrong password cannot unlock level selection")
	game.title_screen.continue_button.pressed.emit()
	game.player.set_physics_process(false)
	check(game.round_active and not game.title_active and game.progression.active_area == "bramblewick" and game.round_number == 1, "Play begins ordinary level one at round one")
	game.advance_round(100.0)
	check(not game.travel_to("bellmarket"), "unfinished village circle blocks normal travel")
	game.show_title()
	# Use the real LineEdit input path with characters bound to gameplay actions.
	for binding in [["toggle_fullscreen", KEY_P], ["next_round", KEY_L], ["toggle_audio", KEY_Z], ["buy_upgrade", KEY_K], ["toggle_voice", KEY_T]]:
		game._rebind_key(binding[0], 0, binding[1])
	var was_muted: bool = game.game_audio.muted
	var was_voice_muted: bool = game.game_audio.voice_muted
	game.title_screen.password_input.grab_focus()
	await process_frame
	for code in [KEY_P, KEY_L, KEY_Z, KEY_K, KEY_T, KEY_K, KEY_S]:
		type_key(code, code)
	check(game.title_screen.password_input.text == "PLZKTKS" and game.title_active and not game.round_active, "password typing survives remapped fullscreen, round, buy and audio shortcuts")
	check(game.game_audio.muted == was_muted and game.game_audio.voice_muted == was_voice_muted, "typing the password does not change audio preferences")
	type_key(KEY_ENTER)
	check(game.title_screen.unlocked and game.title_active and not game.round_active, "Enter submits the actual password field without starting a hidden round")
	game._reset_keys()
	game.title_screen.level_two_button.pressed.emit()
	game.player.set_physics_process(false)
	check(game.progression.active_area == "bellmarket" and game.round_active and not game.title_active, "level two selection starts the implemented market")
	check(game.progression.purchased.is_empty() and game.coins == 0, "password selection grants no ranks or money")
	check(game.groups.size() == 5 and game.encounter == null, "market has five local groups and no village opponents")
	check(game.ritual_screen.node_positions.size() == 30 and not game.ritual_screen.node_positions.has("talk_1"), "market displays its separate thirty-node circle")
	# A nearest group whose remaining people are locked must not steal speech
	# from an eligible group in range; its inspection caption remains available.
	var open_group = game.groups[0]
	var mixed_group = game.groups[3]
	var open_position: Vector2 = open_group.position
	var mixed_position: Vector2 = mixed_group.position
	open_group.position = game.player.position + Vector2(85, 0)
	mixed_group.position = game.player.position + Vector2(0, -25)
	for index in range(mixed_group.listener_count):
		if mixed_group.is_listener_eligible(index):
			mixed_group.recruit_listener(index)
	var before_coins: int = game.coins
	game.advance_round(3.0)
	check(game.nearest_group == open_group and open_group.recruits == 1 and game.coins == before_coins + 4, "nearer locked-only audience cannot steal completed speech from an eligible group")
	check(mixed_group.is_nearby and mixed_group.first_unconverted() == -1 and mixed_group.progress == 0.0 and mixed_group.phrase_elapsed == 0.0, "locked-only audience stays inspectable without banking conviction or phrase time")
	open_group.position = open_position
	mixed_group.position = mixed_position
	game.advance_round(100.0)
	check(game.ritual_screen.visible, "market round opens local ritual")
	game.set_ritual_visible(false)
	await physics_frame
	var before: Vector2 = game.player.position
	game.player.step_motion(Vector2.RIGHT, 1.0 / 60.0)
	check(game.player.position.distance_to(before) > 0 and not game.round_active, "direct movement remains available between market rounds")
	game.set_ritual_visible(true)
	await physics_frame
	before = game.player.position
	game.player.step_motion(Vector2.RIGHT, 1.0 / 60.0)
	check(game.player.position.distance_to(before) > 0, "movement remains available beneath market ritual")
	game.progression.coins = 120
	var ready: int = 0
	for entry in game.progression.catalog:
		if game.progression.status(entry.id) == "affordable":
			ready += 1
	check(ready == 5, "120 donations allow five different upgrades")
	check(game.purchase_upgrade("market_guild_1", 0), "guild introduction purchases through main authority")
	var eligible: int = 0
	for group in game.groups:
		for index in range(group.listener_count):
			eligible += int(group.is_listener_eligible(index))
	check(eligible == 22, "guild purchase updates eligibility across the live market")
	game.start_next_round()
	check(game.player.position == game.area_start_position() and game.round_active and not game.ritual_screen.visible, "next market round resets entrance and closes ritual")
	game.advance_round(100.0)
	var ranks: Dictionary = game.progression.purchased.duplicate(true)
	game.ritual_screen.return_area_button.pressed.emit()
	check(game.progression.active_area == "bramblewick" and game.groups.size() == 3 and not game.round_active, "ritual return button restores village between rounds")
	check(game.progression.purchased == ranks and game.progression.catalog.size() == 32, "return preserves market ranks and original village catalog")
	for entry in game.progression.catalog:
		game.progression.purchased[entry.id] = entry.max_rank
	game.progression.level_select_unlocked = false
	game.apply_upgrades()
	game.ritual_screen.update_state()
	check(game.ritual_screen.open_demo_message(), "completed village centre opens deliberate destination")
	game.progression.save_enabled = true
	game.progression.save_path = "user://missing_market_flow_directory/progress.json"
	game.ritual_screen.destination_button.pressed.emit()
	check(game.progression.active_area == "bramblewick" and not game.ritual_screen.demo_message_visible() and not game.ritual_screen._error_label.text.is_empty(), "failed destination action reveals its save error instead of covering it with the modal")
	game.progression.save_enabled = false
	game.ritual_screen.open_demo_message()
	game.ritual_screen.destination_button.pressed.emit()
	check(game.progression.active_area == "bellmarket" and game.groups.size() == 5 and game.encounter == null and is_instance_valid(game.helper), "completed centre travel button carries helper without copying village gatherings/opponents")
	var stable_world: int = game.groups[0].get_instance_id()
	game.progression.save_enabled = true
	game.progression.save_path = "user://missing_market_flow_directory/progress.json"
	check(not game.travel_to("bramblewick") and game.progression.active_area == "bellmarket" and game.groups[0].get_instance_id() == stable_world, "failed travel save leaves current area and actors intact")
	game.progression.save_enabled = false
	game.queue_free()
	await process_frame
	print("MARKET FLOW RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
