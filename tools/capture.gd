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
	for area_id in ["bellmarket", "lantern_fair", "university", "rosecourt"]:
		main.show_title()
		main.title_screen.unlocked = true
		await seconds(0.3)
		main._start_selected_level(area_id)
		await seconds(3.0)
		await shot("area_" + area_id)
