extends SceneTree
## Doubters, the town watch and devotees: villagers who arrive after each
## debate victory and share that opponent's habit. Never touches player saves.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_village_types.gd
const STEP: float = 1.0 / 60.0
const Gathering = preload("res://scripts/gathering.gd")
const Balance = preload("res://scripts/balance.gd")
## Scenario requirement: new groups stand at least this far from any other group.
const MIN_GROUP_SPACING: float = 170.0
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
	# Phrase strengths and timings below are scenario inputs; every expected
	# threshold, payout and habit comes from the balance data.
	var types: Dictionary = Balance.dict("village.types")
	var doubter: Dictionary = types.doubter
	var doubters := _group("doubter")
	var paid: Array[int] = []
	doubters.recruited.connect(func(amount: int) -> void: paid.append(amount))
	var short: int = int(ceil(float(doubter.conviction))) - 1
	doubters.tick_persuasion(float(short), 1.0, 1.0)
	check(doubters.recruits == 0 and doubters.progress == float(short), "a doubter resists phrases short of its threshold")
	doubters.tick_persuasion(1.0, 1.0, float(doubter.conviction) - float(short))
	check(doubters.recruits == 1 and paid == [int(doubter.donation)], "reaching the threshold converts a doubter for its donation")
	doubters.tick_persuasion(1.0, 1.0, float(doubter.conviction) + 2.0)
	check(doubters.recruits == 2 and is_equal_approx(doubters.progress, 2.0), "conviction overflow still carries to the next doubter")

	var watch_rules: Dictionary = types.watch
	var objections: int = int(watch_rules.rebuttals)
	var reset: float = Balance.number("village.rebuttal_reset_seconds")
	var watch := _group("watch")
	check(objections > 0 and watch.rebuttals_left == objections, "the watch starts each visit with its objections")
	watch.tick_persuasion(float(objections), 1.0, 3.0)
	check(watch.progress == 0.0 and watch.rebuttals_left == 0, "the opening phrases are answered and add nothing")
	watch.tick_persuasion(1.0, 1.0, float(watch_rules.conviction))
	check(watch.recruits == 1 and watch.progress == 0.0, "later phrases persuade normally against the watch threshold")
	watch.advance_unattended(reset * 0.6)
	check(watch.rebuttals_left == 0, "a brief step away keeps the objections answered")
	watch.advance_unattended(reset * 0.6)
	check(watch.rebuttals_left == objections, "time away past the reset readies fresh objections")
	watch.tick_persuasion(1.0, 1.0, 3.0)
	check(watch.rebuttals_left == objections - 1 and watch.progress == 0.0, "returning means answering them again")

	var devotee: Dictionary = types.devotee
	var decay: float = float(devotee.decay)
	var partial: float = float(devotee.conviction) * 2.0 / 3.0
	var devotees := _group("devotee")
	devotees.tick_persuasion(1.0, 1.0, partial)
	check(is_equal_approx(devotees.progress, partial) and devotees.recruits == 0, "a devotee holds partial conviction below its threshold")
	devotees.advance_unattended(1.0)
	check(decay > 0.0 and is_equal_approx(devotees.progress, maxf(0.0, partial - decay)), "a devotee loses its decay per second while unattended")
	devotees.advance_unattended(partial / decay + 1.0)
	check(devotees.progress == 0.0, "conviction never falls below zero")
	devotees.tick_persuasion(1.0, 1.0, float(devotee.conviction))
	check(devotees.recruits == 1 and devotees.listeners[0].following, "steady attention still converts a devotee")
	devotees.reset_round()
	check(devotees.recruits == 0 and devotees.progress == 0.0 and devotees.rebuttals_left == int(devotee.rebuttals), "devotees reset with the round")

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
	var stages: Array = Balance.list("village.stage_gatherings")
	var type_titles: Array[String] = []
	for entry in stages:
		type_titles.append(String(entry.title))
	check(scene.groups.size() == Balance.list("village.gatherings").size() and not _has_any(scene, type_titles), "a fresh village has none of the new types")
	scene.progression.encounter_stage = 1
	check(not _has_any(scene, type_titles), "a victory mid-round does not drop villagers into the current round")
	scene.round_active = false
	scene.start_next_round()
	check(_titles(scene).has(type_titles[0]) and not _titles(scene).has(type_titles[1]), "the first opponent's villagers join from the next round")
	var count: int = scene.groups.size()
	scene.round_active = false
	scene.start_next_round()
	check(scene.groups.size() == count, "later rounds do not duplicate a group")
	scene.progression.encounter_stage = 3
	scene.round_active = false
	scene.start_next_round()
	check(_titles(scene).has(type_titles[1]) and _titles(scene).has(type_titles[2]) and scene.groups.size() == count + stages.size() - 1, "later opponents' villagers follow their victories")
	# Every new group stands clear of prop art and of the other groups.
	var clear: bool = true
	var props: Array[Node] = scene._village_props()
	for group in scene.groups:
		if not Balance.dict("village.types").has(group.npc_type):
			continue
		for listener in group.listeners:
			var body := Rect2(listener.global_position + Vector2(-14, -42), Vector2(28, 46))
			for prop in props:
				var art: Rect2 = prop.visual_rect()
				if Rect2(prop.global_position + art.position, art.size).intersects(body):
					clear = false
					push_error("%s overlaps %s" % [group.group_name, prop.name])
		for other in scene.groups:
			if other != group and other.position.distance_to(group.position) < MIN_GROUP_SPACING:
				clear = false
				push_error("%s is crowded by %s" % [group.group_name, other.group_name])
	check(clear, "new groups stand clear of houses, trees and other groups")
	# The helper's grid reaches every new listener.
	var helper = load("res://scripts/helper.gd").new()
	scene.get_node("Actors").add_child(helper)
	helper.configure_navigation(scene.get_node("Actors"))
	var reachable: bool = true
	for group in scene.groups:
		if not Balance.dict("village.types").has(group.npc_type):
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
	var watch_rules: Dictionary = Balance.dict("village.types").watch
	var interval: float = scene.progression.speech_interval()
	var strength: float = scene.progression.conviction_per_phrase()
	for index in range(roundi(float(watch_rules.rebuttals) * interval / STEP)):
		scene.advance_round(STEP)
	check(watch.progress == 0.0 and watch.rebuttals_left == 0 and scene.coins == coins, "in play, the watch spends its opening phrases on objections")
	for index in range(roundi(ceil(float(watch_rules.conviction) / strength) * interval / STEP)):
		scene.advance_round(STEP)
	check(watch.recruits == 1 and scene.coins == coins + int(watch_rules.donation), "the following phrases convert a watchman for its donation")
	scene.queue_free()
	await process_frame


func _titles(scene) -> Array[String]:
	var titles: Array[String] = []
	for group in scene.groups:
		titles.append(group.group_name)
	return titles


func _has_any(scene, titles: Array[String]) -> bool:
	for title in titles:
		if _titles(scene).has(title):
			return true
	return false
