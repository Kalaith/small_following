extends "res://addons/hatchery/testing/capture_runner.gd"
## Screenshot tour of the main screens, saved flat to docs/verification/ (needs a window, not --headless):
##     Godot --path . --audio-driver Dummy --script res://tools/capture.gd
## Back up user://progression.json first: the tour starts a new game.

const MAIN: String = "res://scenes/main.tscn"


func tour() -> void:
	var main: Node = await open_scene(MAIN, 30)
	main.progression.save_enabled = false
	await shot("title")
	main.set_settings_visible(true)
	await seconds(0.5)
	await shot("settings")
	main.set_settings_visible(false)
	main.start_new_game()
	await seconds(2.0)
	await shot("village_round_start")
	await seconds(6.0)
	await shot("village_round_running")
	main.seconds_left = 0.0
	await seconds(1.0)
	main.set_ritual_visible(true)
	await seconds(1.0)
	await shot("ritual")
	main.set_ritual_visible(false)
	for area_id in ["bellmarket", "lantern_fair", "university", "rosecourt", "abbey"]:
		main.show_title()
		main.title_screen.unlocked = true
		await seconds(0.3)
		main._start_selected_level(area_id)
		await seconds(3.0)
		await shot("area_" + area_id)
	await _abbey_procession(main)


## A full build with the King's approval: the Pope is seated, the won walk up the
## pilgrim way and plead, then the abbey's circle and the ending.
func _abbey_procession(main: Node) -> void:
	var progression = main.progression
	progression.rose_king_won = true
	for entry in progression.all_catalog:
		progression.purchased[entry.id] = int(entry.max_rank)
	main.apply_upgrades()
	main.round_active = false
	main.start_next_round()
	var pope: Node2D = main.pope
	while main.seconds_left > 17.0 and not pope.defeated:
		await seconds(0.05)
		var unconverted: Array = []
		for group in main.audiences():
			if group.first_unconverted() >= 0:
				unconverted.append(group)
		if pope.present and not pope.reserved():
			main.player.global_position = pope.global_position + Vector2(0, 70)
		elif not unconverted.is_empty():
			main.player.global_position = unconverted[0].global_position + Vector2(0, 30)
	await shot("abbey_procession")
	main.seconds_left = 0.0
	await seconds(0.5)
	main.set_ritual_visible(true)
	await seconds(1.0)
	await shot("ritual_abbey")
	main.finish_campaign()
	await seconds(0.5)
	await shot("abbey_ending")
