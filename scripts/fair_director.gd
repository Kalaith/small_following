extends RefCounted
## Runs the Lantern Fair's round: a deterministic clock from round start, show
## bells, gathered and stolen crowds, performers' acts, stages and every
## audience's current Distraction. Interest is derived each frame from
## progression (base, Showmanship, headliners) plus the stage underfoot.
## Presentation state (stage glow, show rings, hoops) is pushed to the world.

const Balance = preload("res://scripts/balance.gd")
const Fair = preload("res://scripts/fair.gd")
const Wanderers = preload("res://scripts/wanderers.gd")

## Seconds since the round began; shows and stolen windows run on this clock.
var clock: float = 0.0
## The cultist's Interest right now, including any stage bonus.
var interest: int = 0
## Index into "fair.stages" the cultist stands on, or -1.
var on_stage: int = -1
## Speaking radius right now: a stage's reach replaces the cultist's own.
var reach: float = 0.0


func reset_round() -> void:
	clock = 0.0


## Stage and Interest follow the cultist every frame, between rounds as well,
## so the HUD and captions always tell the truth.
func update_speaker(progression, player_at: Vector2, base_radius: float) -> void:
	on_stage = -1
	var stages: Array = Balance.list("fair.stages")
	for index in range(stages.size()):
		if player_at.distance_to(Balance.vec(stages[index].at)) <= float(stages[index].radius):
			on_stage = index
			break
	interest = progression.fair_interest()
	reach = base_radius
	if on_stage >= 0:
		interest += progression.fair_stage_bonus()
		reach = maxf(base_radius, float(stages[on_stage].reach) + progression.fair_stage_reach_bonus())


func stage_title() -> String:
	return String(Balance.list("fair.stages")[on_stage].title) if on_stage >= 0 else ""


## Advances shows by `delta` of active-round time (zero between rounds) and
## recomputes every audience's Distraction. `boss` may be null.
func advance(delta: float, progression, audiences: Array[Node2D], boss: Node2D, footprints: Array[Node], world: Node2D) -> void:
	clock += maxf(delta, 0.0)
	var sources: Array[Dictionary] = []
	var crowd_bonus: float = progression.fair_crowd_radius_bonus()
	for group in audiences:
		if group.act_show.is_empty():
			continue
		# A won act ends for the round; won mid-show, its crowd is stolen.
		if group.act_won() and not group.act_cancelled:
			group.act_cancelled = true
			if group.show_running:
				_steal(group, audiences, progression)
		var running: bool = not group.act_cancelled and Fair.show_running(group.act_show, clock)
		group.set_performing(running)
		group.next_show_in = Fair.next_bell(group.act_show, clock)
		if running:
			sources.append({"at": group.global_position, "radius": float(group.act_show.radius), "node": group})
	if is_instance_valid(boss) and boss.profile().has("show"):
		var show: Dictionary = boss.profile().show
		boss.show_on = not boss.defeated and Fair.show_running(show, clock)
		boss.next_show_in = Fair.next_bell(show, clock)
		if boss.show_on:
			sources.append({"at": boss.global_position, "radius": float(show.radius), "node": boss})
	# The bell walks lone fair-goers over into a ring of spectators.
	var spectators: Array[Node2D] = []
	for group in audiences:
		if group.listener_count == 1 and group.act_show.is_empty() and not _is_stilt(group):
			spectators.append(group)
	for source in sources:
		if delta > 0.0:
			Wanderers.pull(spectators, source.at, float(source.radius) + crowd_bonus, delta, footprints, Balance.number("fair.crowd_ring"), Balance.number("fair.crowd_pull_speed"))
	_apply_distraction(progression, audiences, sources, delta)
	if is_instance_valid(world):
		world.set_stage(on_stage)
		var rings: Array[Dictionary] = []
		for source in sources:
			rings.append({"at": source.at, "radius": source.radius})
		world.set_show_rings(rings)
		if is_instance_valid(boss) and not boss.hoops.is_empty() and not boss.defeated:
			world.set_hoops(boss.hoops, boss.lit_hoop, boss.bravo_left)
		else:
			world.set_hoops([] as Array[Vector2], -1, 0.0)


func _apply_distraction(progression, audiences: Array[Node2D], sources: Array[Dictionary], delta: float) -> void:
	var show_lift: int = Balance.integer("fair.show_distraction")
	var performer_cut: int = Balance.integer("fair.performer_cut")
	var stolen_cut: int = Balance.integer("fair.stolen.cut")
	var stilts: Dictionary = Balance.dict("fair.wanderers.stilts")
	var drain: float = Balance.number("fair.drain_share_per_second") * progression.fair_drain_multiplier()
	for group in audiences:
		if group.distraction < 0:
			continue
		var level: int = group.distraction - progression.fair_zone_cut(group.zone)
		var at: Vector2 = group.global_position
		for source in sources:
			if at.distance_to(source.at) <= float(source.radius):
				level += show_lift
				break
		for other in audiences:
			if other == group:
				continue
			# Won performers stop distracting their corner for the rest of the round.
			if other.act_cancelled and not other.act_show.is_empty() and at.distance_to(other.global_position) <= float(other.act_show.radius):
				level -= performer_cut
			elif _is_stilt(other) and other.recruits == 0 and other.visible and at.distance_to(other.global_position) <= float(stilts.radius):
				level += int(stilts.aura)
		if group.stolen_left > 0.0:
			level -= stolen_cut
			group.stolen_left = maxf(0.0, group.stolen_left - delta)
		group.current_distraction = maxi(0, level)
		group.viewer_interest = interest
		group.drain_share = drain
		group.queue_redraw()


func _steal(performer: Node2D, audiences: Array[Node2D], progression) -> void:
	var window: float = progression.fair_steal_seconds()
	for group in audiences:
		if group == performer or not group.act_show.is_empty() or group.first_unconverted() < 0:
			continue
		if group.global_position.distance_to(performer.global_position) <= float(performer.act_show.radius):
			group.stolen_left = window
			group.stolen_total = window


static func _is_stilt(group: Node2D) -> bool:
	return group.listener_count == 1 and not group.listener_profiles.is_empty() and String(group.listener_profiles[0].role) == "Stilt-walker"
