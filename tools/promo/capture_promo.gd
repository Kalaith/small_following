extends SceneTree
## Promo-only staged takes. Uses real motion/speech and never reads/writes player saves.
const STEP: float = 1.0 / 60.0
var destination: String = "res://exports/promo/capture"
var scene: Node2D
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func setup(purchases: int = 0) -> void:
	if is_instance_valid(scene):
		root.remove_child(scene)
		scene.queue_free()
	scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	if purchases > 0:
		scene.round_active = false
		scene.progression.coins = 2000
		for item in scene.progression.catalog.slice(0, purchases):
			for rank in range(scene.progression.max_rank(item.id)):
				if not scene.purchase_upgrade(item.id, rank):
					failures += 1
		# Funded build setup is cut away; each visible take starts with zero donations.
		scene.progression.coins = 0
		scene.start_next_round()
	await physics_frame
	await physics_frame


func save_frame(take: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var path: String = destination.path_join(take).path_join("%05d.png" % frame)
	if root.get_texture().get_image().save_png(path) != OK:
		failures += 1
		push_error("Promo frame failed: " + path)


func route(take: String, seconds: float, order: Array[int], boss: bool = false) -> void:
	DirAccess.make_dir_recursive_absolute(destination.path_join(take))
	var stop: int = 0
	var pause_steps: int = 12
	for step in range(int(seconds * 60)):
		await physics_frame
		var target: Vector2 = Vector2(790, 570)
		if not boss:
			var group = scene.groups[order[stop]]
			if group.recruits >= group.listener_count and stop + 1 < order.size():
				stop += 1
				group = scene.groups[order[stop]]
				pause_steps = 6
			target = group.position
		var direction := Vector2.ZERO
		if pause_steps > 0:
			pause_steps -= 1
		elif scene.player.position.distance_to(target) > (85.0 if boss else 95.0):
			direction = scene.player.position.direction_to(target)
		scene.player.step_motion(direction, STEP)
		scene.advance_round(STEP)
		scene._update_hud()
		if step % 2 == 0:
			await save_frame(take, step / 2)
	print("PROMO TAKE %s: %d recruits, %.3fs left, helper=%d, boss=%s" % [take,
		scene.round_recruits, scene.seconds_left,
		scene.helper.completed_recruits if is_instance_valid(scene.helper) else 0,
		scene.progression.map_complete()])


func ritual() -> void:
	DirAccess.make_dir_recursive_absolute(destination.path_join("ritual"))
	scene.advance_round(1.0)
	scene.ritual_screen.clear_selection()
	scene.ritual_screen.reset_view()
	for step in range(480):
		await physics_frame
		if step == 90:
			scene.ritual_screen.select_node("talk_1")
		if step == 180:
			scene.ritual_screen.purchase_button.pressed.emit()
		if step == 270:
			scene.ritual_screen.focus_node("talk_1")
		if step == 390:
			scene.ritual_screen.reset_view()
		scene.player.step_motion(Vector2.ZERO, STEP)
		if step % 2 == 0:
			await save_frame("ritual", step / 2)
	if scene.progression.rank("talk_1") != 1 or scene.coins != 3:
		failures += 1
	print("PROMO TAKE ritual: first talking rank bought with actual opening donations")


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			destination = argument.trim_prefix("--capture-dir=")
	await setup()
	await route("opening", 11.0, [2])
	if scene.round_recruits != 3:
		failures += 1
	await ritual()
	await setup(9)
	await route("full_core", 11.0, [2, 0, 1])
	if scene.round_recruits != 15:
		failures += 1
	await setup(16)
	await route("helper", 11.0, [3, 0, 1, 4, 2])
	if scene.helper.completed_recruits < 1:
		failures += 1
	await setup(32)
	scene.round_active = false
	scene.progression.encounter_stage = 3
	scene.start_next_round()
	await route("priest", 10.0, [], true)
	if not scene.progression.map_complete():
		failures += 1
	print("PROMO CAPTURE COMPLETE: %d failures; 1530 frames at 30fps" % failures)
	quit(0 if failures == 0 else 1)
