extends RefCounted
## Builds the active area's world, crowds, lone wanderers and the gatherings that
## arrive as opponents are convinced. The lists themselves stay on main.
const Gathering = preload("res://scripts/gathering.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Market = preload("res://scripts/market.gd")
const Village = preload("res://scripts/village.gd")
const Wanderers = preload("res://scripts/wanderers.gd")
const Balance = preload("res://addons/hatchery/core/balance.gd")
const Fair = preload("res://scripts/fair.gd")
const FairBoss = preload("res://scripts/fair_boss.gd")
const University = preload("res://scripts/university.gd")
const UniBoss = preload("res://scripts/uni_boss.gd")
const Rosecourt = preload("res://scripts/rosecourt.gd")
const RoseCourt = preload("res://scripts/rose_court.gd")

var game: Node2D


func _init(owner_game: Node2D) -> void:
	game = owner_game


func rebuild() -> void:
	game.nearest_group = null
	game.groups.clear()
	game.wanderers.clear()
	game.added_gatherings.clear()
	for actor in game.actors().get_children():
		if actor != game.player:
			game.actors().remove_child(actor)
			actor.queue_free()
	game.encounter = null
	game.fair_boss = null
	game.uni_boss = null
	game.rose_court = null
	game.rose_king = null
	game.helper = null
	game.market_helper = null
	game.fair_helper = null
	# No authored placeholder survives to rebuild's second call (area
	# travel); only a prior script-built world needs removing there.
	var previous: Node = game.get_node_or_null("Village")
	if previous:
		game.remove_child(previous)
		previous.queue_free()
	# Only the needed world is built; a discarded spare would leak unfreed.
	var world: Node2D
	if game.progression.active_area == "bellmarket":
		world = Market.new()
	elif game.progression.active_area == Fair.AREA_ID:
		world = Fair.new()
	elif game.progression.active_area == University.AREA_ID:
		world = University.new()
	elif game.progression.active_area == Rosecourt.AREA_ID:
		world = Rosecourt.new()
	else:
		world = Village.new()
	world.name = "Village"
	game.add_child(world)
	game.move_child(world, 0)
	world.build_props(game.actors())
	game._footprints = _obstacle_footprints()
	if game.progression.active_area == "bellmarket":
		for entry in Market.group_layout():
			var gathering := Gathering.new()
			gathering.group_name = entry.title
			gathering.position = entry.position
			gathering.listener_profiles.assign(entry.profiles)
			gathering.configure_market(game.progression)
			gathering.recruited.connect(game._on_recruited)
			gathering.phrase_spoken.connect(game.game_audio.on_phrase)
			game.actors().add_child(gathering)
			game.groups.append(gathering)
		_seed_wanderers()
		sync_market_wanderers()
	elif game.progression.active_area == Fair.AREA_ID:
		for entry in Balance.list("fair.groups"):
			game.groups.append(_new_fair_group(entry))
		add_stage_gatherings()
		_seed_wanderers()
		var lone: Dictionary = Balance.dict("fair.wanderers")
		var people: Array = lone.people.duplicate()
		for index in range(int(lone.stilts.count)):
			people.append("Stilt-walker")
		for index in range(people.size()):
			var stilt: bool = String(people[index]) == "Stilt-walker"
			var wanderer := _new_fair_group({"title": Wanderers.TITLE, "zone": lone.zone, "distraction": int(lone.stilts.distraction) if stilt else int(lone.distraction), "people": [people[index]]}, index)
			wanderer.show_caption = false
			game.wanderers.append(wanderer)
		scatter_wanderers()
		game.fair_director.reset_round()
	elif game.progression.active_area == University.AREA_ID:
		for entry in Balance.list("university.groups"):
			game.groups.append(_new_uni_group(entry))
		add_stage_gatherings()
		_seed_wanderers()
		var people: Array = Balance.list("university.wanderers.people")
		for index in range(people.size()):
			var wanderer := _new_uni_group({"title": Wanderers.TITLE, "people": [people[index]]}, index)
			wanderer.show_caption = false
			game.wanderers.append(wanderer)
		scatter_wanderers()
	elif game.progression.active_area == Rosecourt.AREA_ID:
		var salons: Dictionary = {}
		for entry in Balance.list("rosecourt.salons"):
			var salon: Node2D = _new_rose_group(entry)
			salons[String(entry.id)] = salon
			game.groups.append(salon)
		# The court sits on the garden's floor so its threads run under the guests.
		game.rose_court = RoseCourt.new()
		game.rose_court.name = "Whispers"
		world.add_child(game.rose_court)
		game.rose_court.bind(salons, game.progression)
		_seed_wanderers()
		var strollers: Array = Balance.list("rosecourt.wanderers.people")
		for index in range(strollers.size()):
			var wanderer := _new_rose_group({"title": Wanderers.TITLE, "people": [strollers[index]]}, index)
			wanderer.show_caption = false
			game.wanderers.append(wanderer)
		scatter_wanderers()
	else:
		for entry in Balance.list("village.gatherings"):
			add_gathering(entry.title, Balance.vec(entry.at), false, int(entry.count))
		_seed_wanderers()
		for index in range(Balance.integer("village.wanderers.count")):
			var wanderer: Node2D = _new_gathering(Wanderers.TITLE, Vector2.ZERO, 1, false, index)
			wanderer.show_caption = false
			game.wanderers.append(wanderer)
		scatter_wanderers()
	game.player.clear_walk_target()
	game.player.position = game.area_start_position()
	game.player.get_node("Camera2D").reset_smoothing()


func _seed_wanderers() -> void:
	if game.wanderer_seed != 0:
		game._wanderer_rng.seed = game.wanderer_seed
	else:
		game._wanderer_rng.randomize()


## Adds lone market wanderers up to the count Busy Stalls allows, then scatters
## everyone afresh.
func sync_market_wanderers() -> void:
	var profiles: Array[Dictionary] = Market.wanderer_profiles(game.progression.market_wanderer_count())
	if profiles.size() <= game.wanderers.size():
		return
	for index in range(game.wanderers.size(), profiles.size()):
		var wanderer := Gathering.new()
		wanderer.group_name = Wanderers.TITLE
		wanderer.show_caption = false
		wanderer.coat_offset = index
		wanderer.listener_profiles.assign([profiles[index]])
		wanderer.configure_market(game.progression)
		wanderer.recruited.connect(game._on_recruited)
		wanderer.phrase_spoken.connect(game.game_audio.on_phrase)
		game.actors().add_child(wanderer)
		game.wanderers.append(wanderer)
	scatter_wanderers()


## One fair audience from balance data: its people, Distraction, zone and any show.
func _new_fair_group(entry: Dictionary, coat_offset: int = 0) -> Node2D:
	var gathering := Gathering.new()
	gathering.group_name = String(entry.title)
	gathering.position = Balance.vec(entry.at) if entry.has("at") else Vector2.ZERO
	gathering.coat_offset = coat_offset
	gathering.listener_profiles.assign(Fair.profiles(entry.people))
	gathering.distraction = int(entry.distraction)
	gathering.zone = String(entry.zone)
	gathering.act_show = entry.get("show", {})
	gathering.still_only = bool(entry.get("still_only", false))
	gathering.rebuttals_per_visit = int(entry.get("rebuttals", 0))
	gathering.rebuttals_left = gathering.rebuttals_per_visit
	gathering.configure_market(game.progression)
	gathering.recruited.connect(game._on_recruited)
	gathering.phrase_spoken.connect(game.game_audio.on_phrase)
	game.actors().add_child(gathering)
	return gathering


## One Quillmoor audience from balance data: students mixed with academics who
## hear only their own faculty's argument (the eligibility rule in gathering.gd).
func _new_uni_group(entry: Dictionary, coat_offset: int = 0) -> Node2D:
	var gathering := Gathering.new()
	gathering.group_name = String(entry.title)
	gathering.position = Balance.vec(entry.at) if entry.has("at") else Vector2.ZERO
	gathering.coat_offset = coat_offset
	gathering.zone = String(entry.get("zone", ""))
	gathering.listener_profiles.assign(University.profiles(entry.people))
	gathering.configure_market(game.progression)
	gathering.recruited.connect(game._on_recruited)
	gathering.phrase_spoken.connect(game.game_audio.on_phrase)
	game.actors().add_child(gathering)
	return gathering


## One Rosecourt salon from balance data; its reserved guests wait for whispers.
func _new_rose_group(entry: Dictionary, coat_offset: int = 0) -> Node2D:
	var gathering := Gathering.new()
	gathering.group_name = String(entry.title)
	gathering.position = Balance.vec(entry.at) if entry.has("at") else Vector2.ZERO
	gathering.coat_offset = coat_offset
	gathering.zone = String(entry.get("zone", ""))
	gathering.listener_profiles.assign(Rosecourt.profiles(entry.people))
	# No text over the garden's guests: rings, bars and icons only; the HUD explains.
	gathering.show_caption = false
	gathering.configure_market(game.progression)
	gathering.recruited.connect(game._on_recruited)
	gathering.phrase_spoken.connect(game.game_audio.on_phrase)
	game.actors().add_child(gathering)
	return gathering


func add_gathering(title: String, at: Vector2, merchant: bool = false, count: int = Gathering.LISTENER_COUNT, village_type: String = "") -> void:
	var gathering := _new_gathering(title, at, Balance.integer("village.merchants.count") if merchant else count, merchant, 0, village_type)
	game.groups.append(gathering)


func _new_gathering(title: String, at: Vector2, count: int, merchant: bool = false, coat_offset: int = 0, village_type: String = "") -> Node2D:
	var gathering := Gathering.new()
	gathering.group_name = title
	gathering.position = at
	gathering.listener_count = count
	gathering.coat_offset = coat_offset
	if not village_type.is_empty():
		gathering.configure_village_type(village_type)
	if merchant:
		gathering.npc_type = "merchant"
		gathering.conviction_required = Balance.number("village.merchants.conviction")
		gathering.donation = game.progression.merchant_donation()
	gathering.recruited.connect(game._on_recruited)
	gathering.phrase_spoken.connect(game.game_audio.on_phrase)
	game.actors().add_child(gathering)
	return gathering


## Moves every wanderer to a fresh spot clear of prop art, the groups present
## now, the entrance and the debate centre. Invitations re-scatter on arrival.
func scatter_wanderers() -> void:
	if game.wanderers.is_empty():
		return
	var avoid: Array[Vector2] = [game.area_start_position()]
	if game.progression.active_area == "bramblewick":
		avoid.append(Encounter.CENTER)
	elif game.progression.active_area == Fair.AREA_ID:
		for stage in Balance.list("fair.stages"):
			avoid.append(Balance.vec(stage.at))
		for boss in FairBoss.profiles():
			avoid.append(Balance.vec(boss.at))
	elif game.progression.active_area == University.AREA_ID:
		for boss in UniBoss.profiles():
			avoid.append(Balance.vec(boss.at))
	for group in game.groups:
		avoid.append(group.position)
	var spots: Array[Vector2] = Wanderers.scatter(game._wanderer_rng, _village_props(), avoid, game.wanderers.size())
	for index in range(game.wanderers.size()):
		# A crowded map leaves surplus wanderers out of the round rather than overlapping art.
		game.wanderers[index].visible = index < spots.size()
		game.wanderers[index].position = spots[index] if index < spots.size() else Vector2(-10000, -10000)


func _village_props() -> Array[Node]:
	var props: Array[Node] = []
	for child in game.actors().get_children():
		# Village props plus Bellmarket's bell and district signs.
		if child.has_method("visual_rect"):
			props.append(child)
	return props


func _obstacle_footprints() -> Array[Node]:
	var footprints: Array[Node] = []
	for shape_node in game.actors().find_children("*", "CollisionShape2D", true, false):
		if shape_node.is_in_group("helper_obstacle_shape"):
			footprints.append(shape_node)
	return footprints


## Adds the villagers of every opponent convinced so far (at the fair, each
## headliner's new fans); never duplicates.
func add_stage_gatherings() -> void:
	if game.progression.active_area == Fair.AREA_ID:
		for entry in Balance.list("fair.fan_groups"):
			var fan_key: String = "fans_%d" % int(entry.stage)
			if game.progression.fair_stage >= int(entry.stage) and not game.added_gatherings.has(fan_key):
				game.groups.append(_new_fair_group(entry))
				game.added_gatherings[fan_key] = true
		return
	if game.progression.active_area == University.AREA_ID:
		for entry in Balance.list("university.follower_groups"):
			var follower_key: String = "followers_%d" % int(entry.stage)
			if game.progression.uni_stage >= int(entry.stage) and not game.added_gatherings.has(follower_key):
				game.groups.append(_new_uni_group(entry))
				game.added_gatherings[follower_key] = true
		return
	if game.progression.active_area != "bramblewick":
		return
	for entry in Balance.list("village.stage_gatherings"):
		var key: String = "stage_%d" % int(entry.stage)
		if game.progression.encounter_stage >= int(entry.stage) and not game.added_gatherings.has(key):
			add_gathering(entry.title, Balance.vec(entry.at), false, int(entry.count), entry.type)
			game.added_gatherings[key] = true
