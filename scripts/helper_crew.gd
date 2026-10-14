extends RefCounted
## Hires the helpers each area allows, places them at its entrance and tunes
## them from balance data and that area's upgrades. The helpers themselves stay
## on main (`helper`, `market_helper`, `fair_helper`), where area travel clears them.
const Helper = preload("res://scripts/helper.gd")
const Balance = preload("res://scripts/balance.gd")
const Fair = preload("res://scripts/fair.gd")
const University = preload("res://scripts/university.gd")
const Rosecourt = preload("res://scripts/rosecourt.gd")

var game: Node2D


func _init(owner_game: Node2D) -> void:
	game = owner_game


func apply() -> void:
	var progression = game.progression
	if progression.has_unlock("helper_unlock") and not is_instance_valid(game.helper):
		game.helper = _hire("teal")
	# The Market Hand's upgrades are Bellmarket's own, so it stays there; the
	# Barker works only the fair. The teal helper travels everywhere.
	if progression.active_area == "bellmarket" and progression.has_unlock("market_helper_unlock") and not is_instance_valid(game.market_helper):
		game.market_helper = _hire("amber")
	if progression.active_area == Fair.AREA_ID and progression.has_unlock("fair_barker_unlock") and not is_instance_valid(game.fair_helper):
		game.fair_helper = _hire("moss")
	var team: Array[Node2D] = members()
	for each in team:
		each.rivals.assign(team.filter(func(other: Node2D) -> bool: return other != each))
	_tune()


## Bramblewick's helper keeps its village stats. In Bellmarket the teal helper
## and the amber Market Hand use "market.helper.teal" / ".amber" plus their own
## Followers upgrades: teal gains conviction per phrase, amber speaks faster.
func _tune() -> void:
	var progression = game.progression
	var helper: Node2D = game.helper
	if is_instance_valid(helper):
		var market: bool = progression.active_area == "bellmarket"
		var fair: bool = progression.active_area == Fair.AREA_ID
		var university: bool = progression.active_area == University.AREA_ID
		var rosecourt: bool = progression.active_area == Rosecourt.AREA_ID
		var stats: String = "market.helper.teal." if market else "fair.helper.teal." if fair else "university.helper.teal." if university else "rosecourt.helper.teal." if rosecourt else "helper."
		helper.walk_speed = Balance.number(stats + "walk_speed")
		helper.phrase_seconds = Balance.number(stats + "phrase_seconds")
		helper.conviction_per_phrase = Balance.number(stats + "conviction_per_phrase") + (progression.market_teal_conviction_bonus() if market else 0.0)
		if university:
			# Teaching Assistant ranks; the faculty rule still limits whom it can win.
			helper.walk_speed *= 1.0 + progression.uni_helper_walk_bonus()
			helper.phrase_seconds /= 1.0 + progression.uni_helper_speed_bonus()
			helper.conviction_per_phrase += progression.uni_helper_conviction_bonus()
		if rosecourt:
			# Trusted Name ranks; its conversions whisper like the cultist's.
			helper.walk_speed *= 1.0 + progression.rose_helper_walk_bonus()
			helper.conviction_per_phrase += progression.rose_helper_conviction_bonus()
		# At the fair the teal helper obeys the same hearing rule, with its own Interest.
		helper.interest = progression.fair_teal_interest() if fair else -1
	var fair_helper: Node2D = game.fair_helper
	if is_instance_valid(fair_helper):
		fair_helper.walk_speed = Balance.number("fair.helper.moss.walk_speed")
		fair_helper.phrase_seconds = Balance.number("fair.helper.moss.phrase_seconds") / (1.0 + progression.fair_barker_speed_bonus())
		fair_helper.conviction_per_phrase = Balance.number("fair.helper.moss.conviction_per_phrase")
		fair_helper.interest = Balance.integer("fair.helper.moss.interest")
		fair_helper.distraction_cut = progression.fair_barker_cut()
	var market_helper: Node2D = game.market_helper
	if is_instance_valid(market_helper):
		market_helper.walk_speed = Balance.number("market.helper.amber.walk_speed")
		market_helper.phrase_seconds = Balance.number("market.helper.amber.phrase_seconds") / (1.0 + progression.market_amber_speed_bonus())
		market_helper.conviction_per_phrase = Balance.number("market.helper.amber.conviction_per_phrase")


func _hire(robe: String) -> Node2D:
	var created := Helper.new()
	if robe == "amber":
		created.wear_amber()
	elif robe == "moss":
		created.wear_moss()
	game.actors().add_child(created)
	created.configure_navigation(game.actors())
	created.reset_round(game.area_start_position())
	return created


## Every helper present in this area, original first.
func members() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for each in [game.helper, game.market_helper, game.fair_helper]:
		if is_instance_valid(each):
			result.append(each)
	return result
