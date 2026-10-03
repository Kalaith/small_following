extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.round_active = false
	var neighbours = scene.groups[0]
	neighbours.tick_persuasion(1.0, 1.0, 6.0)
	check(neighbours.recruits == 2 and neighbours.listeners[0].reward_label.text == "3" and neighbours.listeners[1].reward_label.text == "3", "each simultaneous ordinary recruitment shows its numeric payout")
	neighbours.reset_round()
	check(neighbours.listeners[0].reward_label == null, "round reset clears pending reward feedback")
	scene.progression.coins = 1000
	scene.progression.total_recruits = 1000
	scene.progression.available_recruits = 1000
	for id in ["persuade_1", "persuade_2", "persuade_3", "meadow_1", "merchant_1"]:
		check(scene.purchase_upgrade(id, 0), "merchant prerequisite purchased: " + id)
	var merchants = scene.groups.back()
	check(merchants.listener_count == 2 and merchants.conviction_required == 9.0, "two merchants each need nine conviction")
	var before: int = scene.coins
	merchants.tick_persuasion(8.0, 1.0, 1.0)
	check(merchants.recruits == 0, "merchant resists eight baseline phrases")
	merchants.tick_persuasion(1.0, 1.0, 4.0)
	check(merchants.recruits == 1 and merchants.progress == 3.0 and scene.coins == before + 12, "merchant gives twelve and preserves conviction overflow")
	var first_popup = merchants.listeners[0].reward_label
	check(first_popup.text == "12", "merchant recruitment shows the actual numeric payout")
	check(not merchants.recruit_listener(0) and scene.coins == before + 12, "converted merchant cannot pay twice")
	check(merchants.listeners[0].reward_label == first_popup, "duplicate recruitment cannot restart or duplicate reward feedback")
	for id in ["merchant_2", "merchant_3", "merchant_4"]:
		check(scene.purchase_upgrade(id, 0), "working merchant upgrade: " + id)
	check(scene.progression.conviction_for("merchant") == scene.progression.conviction_per_phrase() + 3.0, "merchant conviction remains targeted")
	check(merchants.donation == 18, "purse upgrade updates existing merchants")
	scene.start_next_round()
	check(merchants.recruits == 0 and merchants.progress == 0.0 and merchants.donation == 18, "merchant resets retain purchased donation bonus")
	var helper = load("res://scripts/helper.gd").new()
	scene.get_node("Actors").add_child(helper)
	helper.target_group = merchants
	helper.target_index = 0
	helper.position = merchants.listeners[0].global_position
	helper.set_active(true)
	helper.advance(8.0, scene.groups)
	check(merchants.recruits == 0 and is_equal_approx(helper.conviction, 8.0), "helper cannot bypass merchant threshold with player bonuses")
	helper.advance(1.0, scene.groups)
	check(merchants.recruits == 1 and helper.completed_recruits == 1, "helper uses nine baseline phrases for a merchant")
	check(merchants.listeners[0].reward_label.text == "18", "helper recruitment shows the upgraded merchant payout")
	merchants.donation = 1250 # Isolated fixture, not production balance.
	merchants.recruit_listener(1)
	var large_popup = merchants.listeners[1].reward_label
	check(large_popup.text == "1250" and large_popup.get_minimum_size().x > 40.0, "four-digit rewards stay numeric and expand to fit")
	var initial_y: float = large_popup.position.y
	await create_timer(0.6).timeout
	check(is_instance_valid(large_popup) and large_popup.position.y < initial_y and large_popup.modulate.a < 1.0, "reward rises and fades after its readable hold")
	await create_timer(0.4).timeout
	check(not is_instance_valid(large_popup) and not is_instance_valid(merchants.listeners[0].reward_label), "reward feedback removes itself after the brief flash")
	scene.queue_free()
	await process_frame
	print("MERCHANT RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
