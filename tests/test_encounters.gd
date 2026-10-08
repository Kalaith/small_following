extends SceneTree
## Isolated encounter mechanics, staged victories, saves and real movement routes.
const Encounter = preload("res://scripts/encounter.gd")
const Progression = preload("res://scripts/progression.gd")
const STEP: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _mechanics()
	await _campaign()
	await _route("practical full priest", true, 0.2, true)
	await _route("incomplete priest build", false, 0.2, false)
	await _route("late arrival full priest", true, 6.0, false)
	print("ENCOUNTER RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _mechanics() -> void:
	for stage in range(4):
		var opponent = Encounter.new()
		opponent.stage = stage
		root.add_child(opponent)
		opponent.advance_speech(10, true, 1, 100)
		check(opponent.progress == 0 and not opponent.defeated, "cannot persuade walking opponent %d" % stage)
		var remaining: float = opponent.advance_arrival(4.0)
		check(opponent.arrived and opponent.position == Encounter.CENTER and remaining > 0.8 and remaining < 0.9, "arrival reaches center and consumes travel time %d" % stage)
		for phrase in range(int(Encounter.profiles()[stage].rebuttals)):
			opponent.advance_speech(1.0, true, 1.0, 10)
		check(opponent.progress == 0 and opponent.rebuttals_left == 0, "opening objections consume whole phrases %d" % stage)
		opponent.advance_speech(1.0, true, 1.0, 10)
		check(opponent.progress == 10, "completed phrase adds conviction %d" % stage)
		opponent.advance_speech(1.0, false, 1.0, 10)
		check(opponent.progress == maxf(0, 10 - float(Encounter.profiles()[stage].decay)), "opponent-specific unattended conviction %d" % stage)
		opponent.advance_speech(100, true, 1.0, 10)
		check(opponent.defeated, "ordinary phrases can convince opponent %d" % stage)
		opponent.queue_free()
	await process_frame

func _setup(full: bool):
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.round_active = false
	scene.progression.coins = 5000
	scene.progression.total_recruits = 1000
	scene.progression.available_recruits = 1000
	if full:
		for item in scene.progression.catalog:
			for rank in range(scene.progression.max_rank(item.id)):
				check(scene.purchase_upgrade(item.id, rank), "buy working rank: %s/%d" % [item.id, rank + 1])
	else:
		for id in ["persuade_1", "persuade_2", "persuade_3", "meadow_1", "talk_1", "talk_2", "talk_3", "talk_4", "east_1", "debate_1"]:
			check(scene.purchase_upgrade(id, 0), "minimum debate prerequisite: " + id)
	return scene

func _campaign() -> void:
	var scene = _setup(true)
	var state = scene.progression
	check(state.catalog.size() == 33, "production circle contains 33 implemented nodes")
	check(state.conviction_per_phrase() == 5 and is_equal_approx(state.speech_interval(), 1.0 / 3.5), "full player stats keep frequency and conviction distinct")
	check(state.encounter_conviction("priest") == 14 and state.encounter_conviction("skeptic") == 10 and state.conviction_for("merchant") == 8, "specialist effects target their actual NPCs")
	for version in [1, 2]:
		var legacy: Dictionary = state._validated_snapshot({"schema_version": version, "coins": 7, "total_recruits": 8, "round_number": 9, "purchased": {}})
		check(legacy.encounter_stage == 0 and legacy.coins == 7 and legacy.total_recruits == 8 and legacy.round_number == 9, "older save defaults to unstarted encounters without losing counters %d" % version)
	var before: int = scene.coins
	for item in state.catalog.slice(16):
		check(not scene.purchase_upgrade(item.id, 0) and not scene.purchase_upgrade(item.id, 1) and scene.coins == before, "new inscriptions reject stale and maximum requests: " + item.id)
	check(not state.complete_encounter(2) and scene.coins == before and state.encounter_stage == 0, "cannot skip opponents or award an out-of-order victory")
	# Real local file for round trip, invalid fields, recovery and completion reload.
	var path: String = "user://encounters_%d.json" % Time.get_ticks_usec()
	state.save_enabled = true
	state.save_path = path
	check(state.save_progress(), "save new ranks with a fresh encounter stage")
	for stage in range(4):
		scene.start_next_round()
		check(is_instance_valid(scene.encounter) and scene.encounter.stage == stage and not scene.encounter.arrived, "next round spawns the next walking opponent %d" % stage)
		scene.player.position = Encounter.CENTER + Vector2(0, 90)
		var steps: int = 0
		while scene.round_active and not scene.encounter.defeated:
			scene.advance_round(STEP)
			steps += 1
		check(scene.encounter.defeated and state.encounter_stage == stage + 1 and scene.seconds_left > 0, "convincing opponent advances exactly one saved stage %d" % stage)
		var reward = scene.encounter.get_child(0)
		check(reward is Label and reward.text == str(int(Encounter.profiles()[stage].reward)), "opponent displays its numeric victory payout %d" % stage)
		print("CAMPAIGN: %s convinced in %.3fs / %.3fs left" % [Encounter.profiles()[stage].title, steps * STEP, scene.seconds_left])
		before = state.coins
		check(not state.complete_encounter(stage) and state.coins == before, "duplicate victory cannot pay twice %d" % stage)
		var loaded = Progression.new()
		loaded.load_catalog()
		loaded.save_path = path
		check(loaded.load_progress() and loaded.encounter_stage == stage + 1 and loaded.coins == state.coins and loaded.total_recruits == state.total_recruits, "victory reward and stage round trip together %d" % stage)
		scene.advance_round(100)
		check(not scene.round_active and scene.ritual_screen.visible, "victory retains normal round-to-ritual transition %d" % stage)
	check(state.map_complete() and scene.ritual_screen._subtitle_label.text.contains("BRAMBLEWICK COMPLETE"), "priest victory displays explicit map completion")
	scene.set_ritual_visible(false)
	check(scene.hud_layout.visible and not scene.ritual_screen.visible, "completed map still permits village return")
	scene.start_next_round()
	check(scene.round_active and not is_instance_valid(scene.encounter) and scene.groups.size() == 9, "after completion ordinary village rounds remain available, with each opponent's villagers")
	# Reload the actual scene from the fixture, without touching normal progression.
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.save_path_override = path
	root.add_child(restored)
	restored.set_process(false)
	check(restored.progression.map_complete() and not is_instance_valid(restored.encounter), "relaunch retains first-map completion and does not respawn priest")
	restored.queue_free()
	# Stage field rejects invalid values and inconsistent missing unlocks.
	var snapshot: Dictionary = state._snapshot()
	for invalid in [-1, 5, 1.5, true, "4"]:
		var broken: Dictionary = snapshot.duplicate(true)
		broken.encounter_stage = invalid
		check(state._validated_snapshot(broken).is_empty(), "reject invalid encounter stage " + str(invalid))
	var broken: Dictionary = snapshot.duplicate(true)
	broken.purchased.erase("debate_1")
	check(state._validated_snapshot(broken).is_empty(), "victories require the debate unlock in saves")
	# The required ID is derived from whichever definition carries
	# encounter_unlock, not the literal string "debate_1"; a minimal
	# catalog avoids the production prerequisite web entirely.
	var relabeled := Progression.new()
	relabeled.save_enabled = false
	relabeled.catalog = [{"id": "renamed_debate_unlock", "title": "Renamed", "description": "", "branch": "trial", "ring": 1, "cost": 1, "requires": [], "effect": {"encounter_unlock": 1}}]
	relabeled.all_catalog = relabeled.catalog
	check(relabeled._encounter_unlock_id() == "renamed_debate_unlock", "the unlock ID follows a rename in the catalog")
	var minimal_snapshot: Dictionary = {"schema_version": Progression.SAVE_VERSION, "coins": 0, "total_recruits": 0, "available_recruits": 0, "round_number": 1, "encounter_stage": 1, "active_area": "bramblewick", "level_select_unlocked": false, "purchased": {"debate_1": 1}}
	check(relabeled._validated_snapshot(minimal_snapshot).is_empty(), "the literal string debate_1 no longer satisfies a renamed unlock")
	minimal_snapshot.purchased = {"renamed_debate_unlock": 1}
	check(not relabeled._validated_snapshot(minimal_snapshot).is_empty(), "the renamed unlock id satisfies the same rule")
	# Backup after a second stage-four save is itself complete.
	check(state.save_progress(), "save completion backup")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	var recovered = Progression.new()
	recovered.load_catalog()
	recovered.save_path = path
	check(recovered.load_progress() and recovered.map_complete() and not recovered.last_error.is_empty(), "damaged canonical save recovers completed map from backup")
	state.encounter_stage = 3
	state.save_path = "user://missing_encounter_directory/progress.json"
	before = state.coins
	check(state.complete_encounter(3) and state.map_complete() and state.coins == before + 120 and not state.last_error.is_empty(), "failed victory storage retains earned reward and completion in memory with notice")
	check(not state.complete_encounter(3) and state.coins == before + 120, "failed storage cannot duplicate earned victory")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func _route(label: String, full: bool, delay: float, should_win: bool) -> void:
	var scene = _setup(full)
	scene.progression.encounter_stage = 3 # Isolated route fixture begins at the boss.
	scene.start_next_round()
	await physics_frame
	await physics_frame
	var steps: int = 0
	var distance: float = 0
	while scene.round_active and not scene.encounter.defeated:
		await physics_frame
		var direction := Vector2.ZERO
		if steps * STEP >= delay and scene.player.position.distance_to(Encounter.CENTER) > 85:
			direction = scene.player.position.direction_to(Encounter.CENTER)
		var before: Vector2 = scene.player.position
		scene.player.step_motion(direction, STEP)
		distance += before.distance_to(scene.player.position)
		scene.advance_round(STEP)
		steps += 1
	print("ENCOUNTER ROUTE: %s / defeated=%s / %.3fs / %.3fs left / %.1fpx walked / %.1f conviction" % [label, scene.encounter.defeated, steps * STEP, scene.seconds_left, distance, scene.encounter.progress])
	check(scene.encounter.defeated == should_win and distance > 20, label + " uses real movement and counts the completed boss conversion")
	if should_win:
		check(scene.progression.map_complete() and scene.seconds_left > 0.5, "practical boss route completes with a positive margin")
	else:
		check(not scene.progression.map_complete() and scene.progression.encounter_stage == 3, "incomplete encounter never completes the map")
		var stopped_at: Vector2 = scene.encounter.position
		var stopped_progress: float = scene.encounter.progress
		scene.advance_round(20)
		check(scene.encounter.position == stopped_at and scene.encounter.progress == stopped_progress, "encounter work stops during intermission")
		scene.start_next_round()
		check(scene.encounter.stage == 3 and scene.encounter.progress == 0 and scene.encounter.rebuttals_left == 3 and not scene.encounter.arrived, "failed boss retries from arrival with fresh conviction and objections")
	scene.queue_free()
	await process_frame
