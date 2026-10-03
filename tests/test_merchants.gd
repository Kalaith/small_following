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
	scene.progression.coins = 1000
	for id in ["persuade_1", "persuade_2", "persuade_3", "meadow_1", "merchant_1"]:
		check(scene.purchase_upgrade(id, 0), "merchant prerequisite purchased: " + id)
	var merchants = scene.groups.back()
	check(merchants.listener_count == 2 and merchants.conviction_required == 9.0, "two merchants each need nine conviction")
	var before: int = scene.coins
	merchants.tick_persuasion(8.0, 1.0, 1.0)
	check(merchants.recruits == 0, "merchant resists eight baseline phrases")
	merchants.tick_persuasion(1.0, 1.0, 4.0)
	check(merchants.recruits == 1 and merchants.progress == 3.0 and scene.coins == before + 12, "merchant gives twelve and preserves conviction overflow")
	check(not merchants.recruit_listener(0) and scene.coins == before + 12, "converted merchant cannot pay twice")
	for id in ["merchant_2", "merchant_3", "merchant_4"]:
		check(scene.purchase_upgrade(id, 0), "working merchant upgrade: " + id)
	check(scene.progression.conviction_for("merchant") == scene.progression.conviction_per_phrase() + 3.0, "merchant conviction remains targeted")
	check(merchants.donation == 18, "purse upgrade updates existing merchants")
	scene.start_next_round()
	check(merchants.recruits == 0 and merchants.progress == 0.0 and merchants.donation == 18, "merchant resets retain purchased donation bonus")
	scene.queue_free()
	await process_frame
	print("MERCHANT RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
