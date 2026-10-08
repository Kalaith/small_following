extends SceneTree
## Fresh-save Bramblewick campaign: a simple bot plays real eleven-second rounds
## (actual movement, collisions, speech and opponents) and buys the cheapest
## affordable rank between rounds until the circle is complete and the Priest
## is convinced. It shops instantly and never hesitates, so its round count is
## a lower bound on human play, not a play-time estimate. After a lost debate it
## farms for RETRY_AFTER_ROUNDS rounds before trying that opponent again.
## Use --headless --fixed-fps 60 --path . --script res://tests/test_village_campaign.gd

const STEP: float = 1.0 / 60.0
const MAX_ROUNDS: int = 150
const WANDERER_SEED: int = 31337
## Provisional pacing window for this bot (see PACING); widen only with evidence.
const ROUND_WINDOW := Vector2i(48, 62)
## After losing to an opponent the bot farms this many rounds before retrying,
## as a player would rather than repeating a hopeless debate every round.
const RETRY_AFTER_ROUNDS: int = 2
var checks: int = 0
var failures: int = 0
var _rest_rounds: int = 0


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
	scene.wanderer_seed = WANDERER_SEED
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	var rounds: int = 0
	var stage_rounds: Dictionary = {}
	var type_recruits: Dictionary = {"doubter": 0, "watch": 0, "devotee": 0}
	var spent: int = 0
	var escalated_purchases: int = 0
	var accounting_ok: bool = true
	while rounds < MAX_ROUNDS:
		var stage_before: int = scene.progression.encounter_stage
		var debating: bool = _rest_rounds == 0
		var result: Dictionary = await _play_round(scene, debating)
		rounds += 1
		if _rest_rounds > 0:
			_rest_rounds -= 1
		elif is_instance_valid(scene.encounter) and scene.encounter.arrived and not scene.encounter.defeated:
			_rest_rounds = RETRY_AFTER_ROUNDS
		for type_id in type_recruits:
			type_recruits[type_id] += int(result.types.get(type_id, 0))
		if scene.progression.encounter_stage > stage_before:
			stage_rounds[str(scene.progression.encounter_stage)] = rounds
		var shop: Dictionary = _shop(scene)
		spent += shop.spent
		escalated_purchases += shop.escalated
		accounting_ok = accounting_ok and shop.ok
		print("CAMPAIGN ROUND %d: donations %d, recruits %d, bank %d, debate %d/4, groups %d, bought %s" % [rounds, result.gold, result.recruits, scene.progression.coins, scene.progression.encounter_stage, scene.groups.size(), ",".join(shop.bought)])
		if scene.progression.is_circle_complete("bramblewick") and scene.progression.map_complete():
			break
		scene.start_next_round()
	var complete: bool = scene.progression.is_circle_complete("bramblewick") and scene.progression.map_complete()
	print("CAMPAIGN SUMMARY: %d rounds; debate victories at rounds %s; spent %d donations; %d purchases at raised prices; village-type recruits %s" % [rounds, JSON.stringify(stage_rounds), spent, escalated_purchases, JSON.stringify(type_recruits)])
	check(complete, "real rounds fund the whole village circle and convince the Priest")
	check(accounting_ok, "every purchase charges exactly its displayed price")
	check(rounds >= ROUND_WINDOW.x and rounds <= ROUND_WINDOW.y, "fresh campaign takes %d-%d bot rounds (measured %d)" % [ROUND_WINDOW.x, ROUND_WINDOW.y, rounds])
	check(escalated_purchases > 0, "ranks bought after a debate victory cost more")
	check(type_recruits.doubter > 0 and type_recruits.watch > 0 and type_recruits.devotee > 0, "each opponent's villagers appear and are recruited during the campaign")
	var titles: Array[String] = []
	for group in scene.groups:
		titles.append(group.group_name)
	check(titles.has("Doubters") and titles.has("Town watch") and titles.has("Devotees"), "the finished village keeps all three new groups")
	scene.queue_free()
	await process_frame
	print("VILLAGE CAMPAIGN RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _shop(scene) -> Dictionary:
	var result: Dictionary = {"bought": [], "spent": 0, "escalated": 0, "ok": true}
	while true:
		var best: String = ""
		var best_cost: int = 1 << 30
		for entry in scene.progression.catalog:
			if scene.progression.status(entry.id) != "affordable":
				continue
			var cost: int = scene.progression.next_cost(entry.id)
			if cost < best_cost:
				best_cost = cost
				best = entry.id
		if best.is_empty():
			break
		var before: int = scene.progression.coins
		if not scene.purchase_upgrade(best):
			result.ok = false
			break
		result.ok = result.ok and scene.progression.coins == before - best_cost
		result.spent += best_cost
		result.escalated += int(scene.progression.encounter_stage > 0)
		result.bought.append(best)
	return result


func _play_round(scene, debating: bool) -> Dictionary:
	var gold_before: int = scene.progression.coins
	var recruits_before: int = scene.progression.total_recruits
	var type_before: Dictionary = _type_counts(scene)
	var target = null
	var stuck_time: float = 0.0
	var banned: Dictionary = {}
	var steps: int = 0
	while scene.round_active and steps < 1000:
		await physics_frame
		steps += 1
		var encounter = scene.encounter
		var target_position: Vector2 = scene.player.position
		var stop: float = 85.0
		if debating and is_instance_valid(encounter) and not encounter.defeated and encounter.arrived:
			target_position = encounter.global_position
		else:
			if target == null or not is_instance_valid(target) or target.first_unconverted() < 0 or banned.has(target):
				target = _nearest(scene, banned)
			if target != null:
				target_position = target.global_position
				stop = 60.0 if target.listener_count == 1 else 90.0
		var direction := Vector2.ZERO
		if scene.player.position.distance_to(target_position) > stop:
			direction = scene.player.position.direction_to(target_position)
		var before: Vector2 = scene.player.position
		scene.player.step_motion(direction, STEP)
		# Direct steering can snag on a prop; give up on that audience this round.
		if direction != Vector2.ZERO and before.distance_to(scene.player.position) < 0.5:
			stuck_time += STEP
			if stuck_time > 0.3 and target != null:
				banned[target] = true
				target = null
				stuck_time = 0.0
		else:
			stuck_time = 0.0
		scene.advance_round(STEP)
	var types: Dictionary = {}
	var type_after: Dictionary = _type_counts(scene)
	for type_id in type_after:
		types[type_id] = type_after[type_id] - int(type_before.get(type_id, 0))
	return {"gold": scene.progression.coins - gold_before, "recruits": scene.progression.total_recruits - recruits_before, "types": types}


func _type_counts(scene) -> Dictionary:
	var counts: Dictionary = {}
	for group in scene.groups:
		counts[group.npc_type] = int(counts.get(group.npc_type, 0)) + group.recruits
	return counts


func _nearest(scene, banned: Dictionary):
	var best = null
	var best_distance: float = INF
	for audience in scene.audiences():
		if not audience.visible or audience.first_unconverted() < 0 or banned.has(audience):
			continue
		var distance: float = scene.player.position.distance_to(audience.global_position)
		if distance < best_distance:
			best_distance = distance
			best = audience
	return best
