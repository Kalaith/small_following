extends SceneTree
## Doubters, the town watch and devotees: villagers who arrive after each
## debate victory and share that opponent's habit. Never touches player saves.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_village_types.gd
const STEP: float = 1.0 / 60.0
const Gathering = preload("res://scripts/gathering.gd")
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
	_check_rules()
	await _check_scene()
	print("VILLAGE TYPES RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _group(type_id: String, count: int = 3) -> Node2D:
	var group := Gathering.new()
	group.listener_count = count
	group.configure_village_type(type_id)
	root.add_child(group)
	return group


func _check_rules() -> void:
	var doubters := _group("doubter")
	var paid: Array[int] = []
	doubters.recruited.connect(func(amount: int) -> void: paid.append(amount))
	doubters.tick_persuasion(5.0, 1.0, 1.0)
	check(doubters.recruits == 0 and doubters.progress == 5.0, "a doubter resists five baseline phrases")
	doubters.tick_persuasion(1.0, 1.0, 1.0)
	check(doubters.recruits == 1 and paid == [6], "the sixth phrase converts a doubter for six donations")
	doubters.tick_persuasion(1.0, 1.0, 8.0)
	check(doubters.recruits == 2 and doubters.progress == 2.0, "conviction overflow still carries to the next doubter")

	var watch := _group("watch")
	check(watch.rebuttals_left == 2, "the watch starts each visit with two objections")
	watch.tick_persuasion(2.0, 1.0, 3.0)
	check(watch.progress == 0.0 and watch.rebuttals_left == 0, "the first two phrases are answered and add nothing")
	watch.tick_persuasion(2.0, 1.0, 3.0)
	check(watch.recruits == 1 and watch.progress == 0.0, "later phrases persuade normally: six conviction converts a watchman")
	watch.advance_unattended(0.3)
	check(watch.rebuttals_left == 0, "a brief step away keeps the objections answered")
	watch.advance_unattended(0.3)
	check(watch.rebuttals_left == 2, "half a second away readies two fresh objections")
	watch.tick_persuasion(1.0, 1.0, 3.0)
	check(watch.rebuttals_left == 1 and watch.progress == 0.0, "returning means answering them again")

	var devotees := _group("devotee")
	devotees.tick_persuasion(2.0, 1.0, 3.0)
	check(devotees.progress == 6.0 and devotees.recruits == 0, "a devotee needs nine conviction")
	devotees.advance_unattended(2.0)
	check(is_equal_approx(devotees.progress, 2.0), "a devotee loses two conviction per second while unattended")
	devotees.advance_unattended(5.0)
	check(devotees.progress == 0.0, "conviction never falls below zero")
	devotees.tick_persuasion(3.0, 1.0, 3.0)
	check(devotees.recruits == 1 and devotees.listeners[0].following, "steady attention still converts a devotee for ten donations")
	devotees.reset_round()
	check(devotees.recruits == 0 and devotees.progress == 0.0 and devotees.rebuttals_left == 0, "devotees reset with the round")

	var ordinary := Gathering.new()
	root.add_child(ordinary)
	ordinary.tick_persuasion(1.0, 1.0, 1.0)
	ordinary.advance_unattended(10.0)
	check(ordinary.progress == 1.0 and ordinary.rebuttals_left == 0, "ordinary villagers keep their progress and raise no objections")
	for node in [doubters, watch, devotees, ordinary]:
		node.queue_free()


func _check_scene() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.wanderer_seed = 5
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(scene.groups.size() == 3 and not _titles(scene).has("Doubters"), "a fresh village has none of the new types")
	scene.progression.encounter_stage = 1
	check(not _titles(scene).has("Doubters"), "a victory mid-round does not drop villagers into the current round")
	scene.round_active = false
	scene.start_next_round()
	check(_titles(scene).has("Doubters") and not _titles(scene).has("Town watch"), "the Skeptic's doubters join from the next round")
	var count: int = scene.groups.size()
	scene.round_active = false
	scene.start_next_round()
	check(scene.groups.size() == count, "later rounds do not duplicate a group")
	scene.progression.encounter_stage = 3
	scene.round_active = false
	scene.start_next_round()
	check(_titles(scene).has("Town watch") and _titles(scene).has("Devotees") and scene.groups.size() == count + 2, "the Guard's watch and the Zealot's devotees follow their victories")
	# Every new group stands clear of prop art and of the other groups.
	var clear: bool = true
	var props: Array[Node] = scene._village_props()
	for group in scene.groups:
		if not group.npc_type in Gathering.VILLAGE_TYPES:
			continue
		for listener in group.listeners:
			var body := Rect2(listener.global_position + Vector2(-14, -42), Vector2(28, 46))
			for prop in props:
				var art: Rect2 = prop.visual_rect()
				if Rect2(prop.global_position + art.position, art.size).intersects(body):
					clear = false
					push_error("%s overlaps %s" % [group.group_name, prop.name])
		for other in scene.groups:
			if other != group and other.position.distance_to(group.position) < 170.0:
				clear = false
				push_error("%s is crowded by %s" % [group.group_name, other.group_name])
	check(clear, "new groups stand clear of houses, trees and other groups")
	# The helper's grid reaches every new listener.
	var helper = load("res://scripts/helper.gd").new()
	scene.get_node("Actors").add_child(helper)
	helper.configure_navigation(scene.get_node("Actors"))
	var reachable: bool = true
	for group in scene.groups:
		if not group.npc_type in Gathering.VILLAGE_TYPES:
			continue
		for index in range(group.listeners.size()):
			for other in range(group.listeners.size()):
				group.listeners[other].following = other != index
			helper.reset_round(scene.START_POSITION)
			var one: Array[Node2D] = [group]
			helper._choose_target(one)
			reachable = reachable and helper.target_index == index and not helper.path.is_empty()
		group.reset_round()
	check(reachable, "the helper can reach every new listener")
	# Real speech against the watch through the round code, with the player parked beside it.
	var watch = null
	for group in scene.groups:
		if group.npc_type == "watch":
			watch = group
	for wanderer in scene.wanderers:
		wanderer.position = Vector2(-5000, -5000)
	scene.player.position = watch.position + Vector2(-70, 40)
	var coins: int = scene.coins
	for index in range(roundi(2.0 / STEP)):
		scene.advance_round(STEP)
	check(watch.progress == 0.0 and watch.rebuttals_left == 0 and scene.coins == coins, "in play, the watch spends the first two phrases on objections")
	for index in range(roundi(6.0 / STEP)):
		scene.advance_round(STEP)
	check(watch.recruits == 1 and scene.coins == coins + 8, "the next six phrases convert a watchman for eight donations")
	scene.queue_free()
	await process_frame


func _titles(scene) -> Array[String]:
	var titles: Array[String] = []
	for group in scene.groups:
		titles.append(group.group_name)
	return titles
