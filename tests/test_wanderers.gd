extends SceneTree
## Lone wanderers and Beckoning Call against the real scene; never touches ordinary progression.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_wanderers.gd
const Balance = preload("res://scripts/balance.gd")
const STEP: float = 1.0 / 60.0
const Progression = preload("res://scripts/progression.gd")
const Wanderers = preload("res://scripts/wanderers.gd")
const RitualText = preload("res://scripts/ritual_text.gd")
const FIXTURE: String = "user://test_wanderers_save.json"
const OFFSTAGE := Vector2(-5000, -5000)
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
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.wanderer_seed = 99
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	_check_placement(scene)
	var before: Array[Vector2] = _positions(scene)
	scene.round_active = false
	scene.start_next_round()
	check(_positions(scene) != before, "each new round scatters the wanderers afresh")
	check(scene.audiences().size() == scene.groups.size() + 5, "wanderers join the speakable audiences beside the groups")
	_check_pull(scene)
	_check_footprint_slide(scene)
	scene.round_active = false
	check(scene.travel_to("bellmarket", true) and scene.wanderers.is_empty() and scene.audiences().size() == scene.groups.size(), "Bellmarket keeps its authored districts without village wanderers")
	scene.queue_free()
	await process_frame
	_check_progression()
	_check_migration()
	print("WANDERER RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_placement(scene) -> void:
	check(scene.wanderers.size() == Balance.integer("village.wanderers.count"), "the village scatters five lone wanderers")
	var all_clear: bool = true
	for seed in range(1, 301):
		scene._wanderer_rng.seed = seed
		scene.scatter_wanderers()
		if not _placement_clear(scene):
			all_clear = false
			push_error("Wanderer placement failed for seed %d: %s" % [seed, str(_positions(scene))])
			break
	check(all_clear, "300 seeded scatters keep every wanderer visible, apart, and clear of prop art, groups and the entrance")


func _placement_clear(scene) -> bool:
	var sites: Array[Vector2] = [scene.START_POSITION, scene.Encounter.CENTER]
	for group in scene.groups:
		sites.append(group.position)
	var props: Array[Node] = scene._village_props()
	var positions: Array[Vector2] = _positions(scene)
	for index in range(positions.size()):
		var at: Vector2 = positions[index]
		if not scene.wanderers[index].visible or not Wanderers.AREA.has_point(at):
			return false
		for site in sites:
			if at.distance_to(site) < Wanderers.GATHERING_CLEARANCE:
				return false
		for other in range(index + 1, positions.size()):
			if at.distance_to(positions[other]) < Wanderers.SPACING:
				return false
		# Independent of Wanderers.is_clear: the drawn body must not overlap any prop's art.
		var body := Rect2(at + Vector2(-14, -42), Vector2(28, 46))
		for prop in props:
			var art: Rect2 = prop.visual_rect()
			if art.size == Vector2.ZERO or Rect2(prop.global_position + art.position, art.size).intersects(body):
				return false
	return props.size() > 10


func _check_pull(scene) -> void:
	var wanderer = scene.wanderers[0]
	_isolate(scene, wanderer, Vector2(600, 250))
	scene.player.position = Vector2(750, 250)
	_advance(scene, 0.5)
	check(wanderer.position == Vector2(600, 250), "without Beckoning Call wanderers stay where they stand")
	scene.round_active = false
	scene.progression.coins = 1000
	scene.progression.total_recruits = 1000
	scene.progression.available_recruits = 1000
	check(scene.purchase_upgrade("run_1") and scene.purchase_upgrade("beckon_1"), "Beckoning Call I is bought through the normal purchase API")
	check(scene.progression.beckon_reach() == 180.0 and is_equal_approx(scene.player.movement_speed, 207.0), "rank one reaches 180 px and leaves running speed to Fleet Footsteps")
	scene.start_next_round()
	_isolate(scene, wanderer, Vector2(600, 250))
	var far = scene.wanderers[1]
	far.position = Vector2(500, 250)
	scene.player.position = Vector2(750, 250)
	var coins: int = scene.coins
	_advance(scene, 0.3)
	check(wanderer.position.x > 620.0 and absf(wanderer.position.y - 250.0) < 0.5, "a wanderer within reach walks toward the cultist")
	check(far.position == Vector2(500, 250), "a wanderer beyond reach stays put")
	_advance(scene, 1.5)
	check(absf(wanderer.position.distance_to(scene.player.position) - Wanderers.PULL_STOP) < 0.5, "a beckoned wanderer stops inside speaking range")
	_advance(scene, 3.5)
	check(wanderer.recruits == 1 and scene.coins == coins + 3, "speech converts the beckoned wanderer at the ordinary rate")
	var settled: Vector2 = wanderer.position
	scene.player.position = Vector2(750, 400)
	_advance(scene, 0.5)
	check(wanderer.position == settled, "a converted wanderer is no longer pulled")
	scene.seconds_left = 0.0
	scene.advance_round(STEP)
	far.position = Vector2(650, 400)
	_advance(scene, 0.5)
	check(not scene.round_active and far.position == Vector2(650, 400), "wanderers are not pulled between rounds")
	check(scene.purchase_upgrade("beckon_1") and scene.progression.beckon_reach() == 320.0, "rank two reaches 320 px")
	scene.start_next_round()
	_isolate(scene, far, Vector2(500, 250))
	scene.player.position = Vector2(750, 250)
	_advance(scene, 0.3)
	check(far.position.x > 510.0, "rank two draws in a wanderer 250 px away")


## Above the well, pulled straight down toward a cultist below it: the wanderer
## must slide around the well footprint, never stepping inside it.
func _check_footprint_slide(scene) -> void:
	var wanderer = scene.wanderers[2]
	scene.round_active = false
	scene.start_next_round()
	_isolate(scene, wanderer, Vector2(790, 330))
	scene.player.position = Vector2(780, 470)
	var well: Node = null
	for footprint in scene._footprints:
		if footprint.shape is CircleShape2D and footprint.global_position.distance_to(Vector2(780, 391)) < 1.0:
			well = footprint
	var stayed_out: bool = well != null
	for index in range(180):
		scene.advance_round(STEP)
		if well != null and wanderer.global_position.distance_to(well.global_position) <= well.shape.radius:
			stayed_out = false
	check(stayed_out, "a beckoned wanderer never walks through the well")


func _check_progression() -> void:
	var state := Progression.new()
	state.save_enabled = false
	check(state.load_catalog(), "production catalog loads")
	var definition: Dictionary = state.find_upgrade("beckon_1")
	check(definition.branch == "run" and definition.max_rank == 2 and int(definition.rank_costs[0]) == 9 and int(definition.rank_costs[1]) == 18 and definition.rank_recruit_costs.max() == 0, "Beckoning Call is a two-rank, gold-only Running node")
	state.coins = 100
	check(state.status("beckon_1") == "locked" and not state.try_purchase("beckon_1"), "Beckoning Call requires Fleet Footsteps I")
	check(state.try_purchase("run_1") and state.beckon_reach() == 0.0, "running alone does not beckon")
	var by_id: Dictionary = {"beckon_1": definition}
	check(RitualText.effect_text(state, by_id, "beckon_1", "run", false) == "BECKONING REACH\n0 → 180 px", "the ritual preview states the reach it adds")
	check(state.try_purchase("beckon_1", 0) and state.try_purchase("beckon_1", 1) and not state.try_purchase("beckon_1", 2), "both ranks buy once each")
	check(state.coins == 100 - 6 - 9 - 18 and state.beckon_reach() == 320.0 and is_equal_approx(state.run_multiplier(), 1.15) and state.conviction_per_phrase() == 1.0, "ranks cost 27 and change only the beckoning reach")


## A Bellmarket save from the 32-node village circle stays valid after Beckoning
## Call joins it; the save gains no flags, and live travel needs the new node.
func _check_migration() -> void:
	var catalog_state := Progression.new()
	catalog_state.load_catalog()
	var old_circle: Dictionary = {}
	for entry in catalog_state.catalog_for_area("bramblewick"):
		if entry.id != "beckon_1":
			old_circle[entry.id] = int(entry.max_rank)
	var snapshot: Dictionary = {"schema_version": 4, "coins": 50, "total_recruits": 300, "available_recruits": 20, "round_number": 40, "encounter_stage": 4, "active_area": "bellmarket", "level_select_unlocked": false, "purchased": old_circle}
	_write(JSON.stringify(snapshot))
	var existing := _fixture_state()
	check(existing.load_progress() and existing.last_error.is_empty() and existing.active_area == "bellmarket" and not existing.level_select_unlocked, "a Bellmarket save from the old full circle still loads, with no granted bypass")
	check(existing.save_progress() and _fixture_state().load_progress(), "that save round-trips unchanged in shape")
	check(existing.try_travel("bramblewick") and not existing.is_area_unlocked("bellmarket"), "back in the village, the new node is needed before travelling to Bellmarket again")
	existing.coins = 100
	check(existing.try_purchase("run_1") or existing.rank("run_1") > 0, "Fleet Footsteps I is owned")
	check(existing.try_purchase("beckon_1", 0) and existing.try_purchase("beckon_1", 1) and existing.is_area_unlocked("bellmarket"), "buying Beckoning Call completes the circle and reopens Bellmarket")
	var partial: Dictionary = old_circle.duplicate()
	partial.erase("priest_2")
	snapshot.purchased = partial
	_write(JSON.stringify(snapshot))
	check(not _fixture_state().load_progress(), "a Bellmarket save missing an older village rank is still rejected without the bypass")
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)


func _fixture_state() -> Progression:
	var state := Progression.new()
	state.save_path = FIXTURE
	state.load_catalog()
	return state


func _write(text: String) -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(FIXTURE + suffix):
			DirAccess.remove_absolute(FIXTURE + suffix)
	var file := FileAccess.open(FIXTURE, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _isolate(scene, wanderer, at: Vector2) -> void:
	for other in scene.wanderers:
		other.position = OFFSTAGE
	wanderer.position = at


func _advance(scene, seconds: float) -> void:
	for index in range(roundi(seconds / STEP)):
		scene.advance_round(STEP)


func _positions(scene) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for wanderer in scene.wanderers:
		result.append(wanderer.position)
	return result
