extends SceneTree
## Pure session fixtures and a real market world; never loads a player save.
const Gathering = preload("res://scripts/gathering.gd")
const Helper = preload("res://scripts/helper.gd")
const Market = preload("res://scripts/market.gd")
const Progression = preload("res://scripts/progression.gd")
## Mechanics fixture with small hand-checkable thresholds, independent of the
## tuned Bellmarket values in market.gd.
const BAKER = {"role": "Baker", "npc_type": "ordinary", "conviction_required": 3.0, "donation": 4, "requires": ""}
const PORTER = {"role": "Porter", "npc_type": "ordinary", "conviction_required": 3.0, "donation": 4, "requires": ""}
const SHOPPER = {"role": "Shopper", "npc_type": "ordinary", "conviction_required": 3.0, "donation": 4, "requires": ""}
const ARTISAN = {"role": "Artisan", "npc_type": "guild", "conviction_required": 9.0, "donation": 12, "requires": "market_guild_unlock"}
const PATRON = {"role": "Patron", "npc_type": "patron", "conviction_required": 12.0, "donation": 20, "requires": "market_patron_unlock"}

var checks: int = 0
var failures: int = 0
var rewards: Array[int] = []
var phrases: int = 0


class MarketProgression extends Progression:
	# A minimal double satisfying gathering.configure_market's typed parameter;
	# only the two members market gatherings actually call are overridden.
	var guild: bool = false
	var patron: bool = false
	var guild_bonus: int = 0
	var patron_bonus: int = 0

	func has_unlock(effect: String) -> bool:
		return (effect == "market_guild_unlock" and guild) or (effect == "market_patron_unlock" and patron)

	func market_donation(npc_type: String, amount: int) -> int:
		return amount + (guild_bonus if npc_type == "guild" else patron_bonus if npc_type == "patron" else 0)


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func _eligible(group: Node2D) -> int:
	var count: int = 0
	for index in range(group.listener_count):
		count += int(group.is_listener_eligible(index))
	return count


func _run() -> void:
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	root.add_child(actors)
	var progression := MarketProgression.new()
	var group := Gathering.new()
	group.group_name = "Mixed fixture"
	group.position = Vector2(650, 500)
	group.listener_profiles.assign([ARTISAN, BAKER, PATRON, PORTER, SHOPPER])
	group.configure_market(progression)
	check(group.validate_profiles().is_empty(), "authored mixed roster validates before activation")
	actors.add_child(group)
	group.recruited.connect(func(amount: int): rewards.append(amount))
	group.phrase_spoken.connect(func(): phrases += 1)
	check(group.npc_type == "mixed" and group.listener_count == 5 and _eligible(group) == 3, "three of five listeners are initially approachable")
	check(group.first_unconverted() == 1 and group.listeners[0].locked and group.listeners[2].locked, "authored selection skips a locked first slot and displays locks")
	check(not group.recruit_listener(0) and not group.recruit_listener(2) and rewards.is_empty(), "recruitment authority rejects both locked roles without payouts")
	group.tick_persuasion(100.0, 1.0, 12.0)
	check(group.recruits == 3 and group.progress == 3.0 and rewards == [4, 4, 4], "base conviction crosses three eligible thresholds and preserves overflow")
	check(phrases == 1 and group.phrase_elapsed == 0.0, "surplus frame time cannot accumulate after only locked listeners remain")
	group.tick_persuasion(100.0, 0.1, 100.0)
	check(group.recruits == 3 and group.progress == 3.0 and group.phrase_elapsed == 0.0 and phrases == 1, "locked-only audience accrues neither phrase time nor conviction")
	check(not group.recruit_listener(1) and rewards.size() == 3, "a converted ordinary listener cannot pay twice")
	progression.guild = true
	progression.guild_bonus = 5
	group.configure_market(progression)
	check(_eligible(group) == 4 and not group.listeners[0].locked and group.listeners[2].locked, "guild introduction opens only its fourth listener")
	group.tick_persuasion(1.0, 1.0, 6.0)
	check(group.recruits == 4 and group.progress == 0.0 and rewards.back() == 17, "retained base overflow contributes to the guild threshold and its targeted reward")
	check(group.listener_donation(1) == 4 and group.listener_donation(2) == 20, "guild donation bonus leaves ordinary and patron rewards unchanged")
	progression.patron = true
	progression.patron_bonus = 8
	group.configure_market(progression)
	check(_eligible(group) == 5 and not group.listeners[2].locked, "both introductions open all five listeners")
	group.tick_persuasion(11.0, 1.0, 1.0)
	check(group.recruits == 4 and group.progress == 11.0, "patron still needs speech after its introduction")
	group.tick_persuasion(1.0, 1.0, 1.0)
	check(group.recruits == 5 and group.progress == 0 and group.phrase_elapsed == 0 and rewards.back() == 28, "patron pays its own reward once and a full group clears transient work")
	group.reset_round()
	check(group.recruits == 0 and group.first_unconverted() == 0 and group.listeners[0].reward_label == null, "round reset clears all conversions and payout feedback while retaining introductions")
	progression.guild = false
	group.configure_market(progression)
	check(_eligible(group) == 4 and group.first_unconverted() == 1, "patron introduction can be chosen independently before guild access")
	group.tick_persuasion(1.0, 1.0, 20.0)
	check(group.recruits == 3 and group.progress == 2.0 and group.listeners[2].following and not group.listeners[4].following, "overflow crosses unlike ordinary and patron thresholds in authored eligible order")
	group.tick_persuasion(1.0, 1.0, 1.0)
	check(group.recruits == 4 and group.progress == 0 and not group.listeners[0].following, "locked guild remains unconverted after other roles finish")
	# The helper uses the same lock authority, with its own baseline phrase value.
	group.reset_round()
	progression.patron = false
	group.configure_market(progression)
	var helper := Helper.new()
	actors.add_child(helper)
	helper.configure_navigation(actors)
	helper.reset_round(Vector2(650, 580))
	var one_group: Array[Node2D] = [group]
	helper._choose_target(one_group)
	check(helper.target_index >= 0 and helper.target_index != 0 and helper.target_index != 2, "helper skips closer or earlier locked listeners")
	helper.target_group = group
	helper.target_index = 0
	helper.path.clear()
	helper.conviction = 100.0
	helper.set_active(true)
	helper.advance(0.01, one_group)
	check(not group.listeners[0].following and helper.target_index != 0 and helper.conviction == 0.0, "stale helper target cannot bypass a newly locked role")
	progression.guild = true
	group.configure_market(progression)
	helper.target_group = group
	helper.target_index = 0
	helper.path.clear()
	helper.conviction = 0.0
	helper.phrase_elapsed = 0.0
	helper.advance(8.0, one_group)
	check(not group.listeners[0].following and helper.conviction == 8.0, "helper does not borrow player conviction for a guild listener")
	helper.advance(1.0, one_group)
	check(group.listeners[0].following and helper.completed_recruits == 1 and group.listeners[0].reward_label.text == "17", "helper uses the slot threshold and the same upgraded donation authority")
	# Malformed rosters are rejected before an area can become active.
	var invalid := Gathering.new()
	invalid.listener_profiles.assign([Market.profile("Baker")])
	invalid.listener_profiles[0]["requires"] = "unknown_gate"
	check(not invalid.validate_profiles().is_empty(), "unknown introduction is rejected before scene activation")
	invalid.listener_profiles[0] = Market.profile("Baker")
	invalid.listener_profiles[0]["conviction_required"] = INF
	check(not invalid.validate_profiles().is_empty(), "nonfinite listener threshold is rejected")
	invalid.listener_profiles[0] = Market.profile("Baker")
	invalid.listener_profiles[0]["donation"] = -1
	check(not invalid.validate_profiles().is_empty(), "negative listener reward is rejected")
	invalid.free()
	# Preserve homogeneous merchants' existing thresholds and mutable rewards.
	var ordinary := Gathering.new()
	actors.add_child(ordinary)
	ordinary.tick_persuasion(5.0, 1.0, 2.0)
	check(ordinary.recruits == 3 and ordinary.progress == 1.0, "ordinary village overflow remains unchanged")
	var merchants := Gathering.new()
	merchants.listener_count = 2
	merchants.conviction_required = 9.0
	merchants.donation = 18
	merchants.npc_type = "merchant"
	actors.add_child(merchants)
	merchants.tick_persuasion(1.0, 1.0, 12.0)
	check(merchants.recruits == 1 and merchants.progress == 3.0 and merchants.listeners[0].reward_label.text == "18", "homogeneous merchant overflow and upgraded reward remain unchanged")
	actors.queue_free()
	await process_frame
	await _check_market_world(progression)
	print("MIXED AUDIENCE RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_market_world(progression: MarketProgression) -> void:
	var world := Node2D.new()
	root.add_child(world)
	var market := Market.new()
	world.add_child(market)
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	world.add_child(actors)
	market.build_props(actors)
	var prop_count: int = actors.get_child_count()
	market.build_props(actors)
	check(actors.get_child_count() == prop_count, "market prop setup is idempotent")
	var groups: Array[Node2D] = []
	var total: int = 0
	var initially_open: int = 0
	progression.guild = false
	progression.patron = false
	for entry in Market.group_layout():
		var group := Gathering.new()
		group.group_name = entry["title"]
		group.position = entry["position"]
		group.listener_profiles.assign(entry["profiles"])
		check(group.validate_profiles().is_empty(), "market roster validates: " + group.group_name)
		group.configure_market(progression)
		actors.add_child(group)
		groups.append(group)
		total += group.listener_count
		initially_open += _eligible(group)
	check(groups.size() == 5 and total == 25 and initially_open == 18, "five market districts provide eighteen repeatable open listeners and seven specialists")
	var helper := Helper.new()
	actors.add_child(helper)
	helper.configure_navigation(actors)
	await physics_frame
	var probe := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12
	probe.shape = circle
	probe.collision_mask = 2
	probe.transform = Transform2D(0, Market.START_POSITION)
	check(world.get_world_2d().direct_space_state.intersect_shape(probe, 1).is_empty(), "market entrance has no prop collision")
	progression.guild = true
	progression.patron = true
	var reachable: bool = true
	for group in groups:
		group.configure_market(progression)
		for target in range(group.listener_count):
			for index in range(group.listener_count):
				group.listeners[index].following = index != target
			helper.reset_round(Market.START_POSITION)
			var one_group: Array[Node2D] = [group]
			helper._choose_target(one_group)
			if helper.target_index != target or helper.path.is_empty() or helper.path[-1].distance_to(group.listeners[target].global_position) > 50.0:
				reachable = false
		group.reset_round()
	check(reachable, "all twenty-five market listener stand cells have reachable paths around actual props")
	# The homogeneous (no-profile) path sets listener_count directly; it must
	# not index the five authored offsets/colors out of bounds.
	var oversized := Gathering.new()
	oversized.listener_count = 9
	world.add_child(oversized)
	check(oversized.listener_count == 5 and oversized.listeners.size() == 5, "an oversized listener_count without profiles is bounded to the five authored slots")
	world.queue_free()
	await process_frame
