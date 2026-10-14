extends RefCounted
## Single owner for upgrade purchases and durable earnings. Definitions contain no code.
## Saves only progression: rounds always start fresh after relaunch; no offline accrual.

const Balance = preload("res://scripts/balance.gd")
const ProgressionSave = preload("res://scripts/progression_save.gd")
const ProgressionCatalog = preload("res://scripts/progression_catalog.gd")
const SAVE_VERSION: int = 6
const MAX_COUNTER: int = 1000000000
## Travel order. An area's earned effects carry into every later area, never back.
const AREA_IDS: Array[String] = ["bramblewick", "bellmarket", "lantern_fair", "university"]
const AREA_TITLES: Dictionary = {"bramblewick": "Bramblewick", "bellmarket": "Bellmarket", "lantern_fair": "the Lantern Fair", "university": "Quillmoor"}
## Effect keys a circle may hold only in its own area, by prefix.
const AREA_EFFECT_PREFIXES: Dictionary = {"bellmarket": "market_", "lantern_fair": "fair_", "university": "uni_"}
const FAIR_BOSS_COUNT: int = 4
const UNI_AREA: String = "university"
const UNI_BOSS_COUNT: int = 4
## Village nodes added after Bellmarket shipped. Saves validate earned market
## access without them, so a player already there is not rejected; ordinary
## travel still requires the whole current circle.
const POST_MARKET_VILLAGE_IDS: Array[String] = ["beckon_1"]
const EFFECT_KEYS: Array[String] = ["beckon_add", "encounter_conviction_add", "skeptic_conviction_add", "guard_conviction_add", "zealot_conviction_add", "priest_conviction_add", "merchant_conviction_add", "merchant_donation_add", "speech_speed_add", "conviction_add", "run_speed_add", "meadow_unlock", "east_unlock", "helper_unlock", "merchant_unlock", "encounter_unlock", "market_guild_unlock", "market_patron_unlock", "market_guild_donation_add", "market_patron_donation_add", "market_beckon_add", "market_wanderer_add", "market_helper_unlock", "market_teal_conviction_add", "market_amber_speed_add", "fair_interest_add", "fair_stage_bonus_add", "fair_stage_reach_add", "fair_drain_cut_add", "fair_barker_unlock", "fair_barker_speed_add", "fair_barker_cut_add", "fair_teal_interest_add", "fair_steal_window_add", "fair_crowd_radius_add", "uni_slot_add", "uni_academic_conviction_add", "uni_proof_conviction_add", "uni_evidence_conviction_add", "uni_scripture_conviction_add", "uni_eloquence_conviction_add", "uni_proof_donation_add", "uni_evidence_donation_add", "uni_scripture_donation_add", "uni_eloquence_donation_add", "uni_ta_conviction_add", "uni_ta_walk_add", "uni_ta_speed_add"]
const UNLOCK_KEYS: Array[String] = ["meadow_unlock", "east_unlock", "helper_unlock", "merchant_unlock", "encounter_unlock", "market_guild_unlock", "market_patron_unlock", "market_helper_unlock", "fair_barker_unlock"]
## Whole-number fair effects (Interest and Distraction are counted in whole lanterns).
const WHOLE_FAIR_KEYS: Array[String] = ["fair_interest_add", "fair_stage_bonus_add", "fair_barker_cut_add", "fair_teal_interest_add"]
## Whole-number Quillmoor effects: argument slots and gold.
const WHOLE_UNI_KEYS: Array[String] = ["uni_slot_add", "uni_proof_donation_add", "uni_evidence_donation_add", "uni_scripture_donation_add", "uni_eloquence_donation_add"]


var encounter_stage: int = 0
## Fair headliners convinced so far: Performer, Head Clown, Mime, Ringmaster.
## Their Interest bonus is derived from this count, never stored on its own.
var fair_stage: int = 0
## Quillmoor bosses convinced so far: Debate Captain, Logician, Astronomer, Rector.
var uni_stage: int = 0
## Arguments prepared for the next Quillmoor round, in the order chosen. Never
## longer than the owned slots; academics of any other faculty rebut everything.
var uni_loadout: Array[String] = []
var coins: int = 0
# Recruitment events are lifetime history; assigning supporters spends only availability.
var total_recruits: int = 0
var available_recruits: int = 0
var round_number: int = 1
var purchased: Dictionary = {}
# The active circle is exposed to the graph; every rank is validated against all areas.
var catalog: Array[Dictionary] = []
var all_catalog: Array[Dictionary] = []
var active_area: String = "bramblewick"
# Title-screen access is independent of earned ranks and completion.
var level_select_unlocked: bool = false
var save_path: String = "user://progression.json"
var last_error: String = ""
var save_enabled: bool = true
var _write_blocked: bool = false
var _archive_corrupt_on_save: bool = false
## The save file itself: loading, validation and staged writes.
var save_file: ProgressionSave = ProgressionSave.new(self)


func load_catalog(path: String = "res://data/upgrades.json") -> bool:
	last_error = ""
	var result: Variant = ProgressionCatalog.parse(self, _parse_json(FileAccess.get_file_as_string(path)))
	if result is String:
		return _fail(result)
	all_catalog.assign(result)
	catalog = catalog_for_area(active_area)
	return true


func catalog_for_area(area_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		if entry.get("area", "bramblewick") == area_id:
			result.append(entry)
	return result


## The town-debate encounters require their one unlocking upgrade, whichever
## stable ID currently carries the encounter_unlock effect in the catalog.
func _encounter_unlock_id() -> String:
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		if entry.get("effect", {}).has("encounter_unlock"):
			return str(entry.id)
	return ""


func find_upgrade(id: String) -> Dictionary:
	for entry in catalog:
		if entry.id == id:
			return entry
	for entry in all_catalog:
		if entry.id == id:
			return entry
	return {}


func rank(id: String) -> int:
	return int(purchased.get(id, 0))


func max_rank(id: String) -> int:
	return _definition_max_rank(find_upgrade(id))


func next_cost(id: String) -> int:
	return _definition_next_cost(find_upgrade(id), id)


func next_recruit_cost(id: String) -> int:
	return _definition_next_recruit_cost(find_upgrade(id), id)


## The definition-taking forms let one caller resolve an upgrade once. Views ask
## for every node's state on each refresh, so repeating the catalog lookup five
## times per question made the cost of a refresh grow with the catalog squared.
func _definition_max_rank(upgrade: Dictionary) -> int:
	return int(upgrade.get("max_rank", 1)) if not upgrade.is_empty() else 0


func _definition_next_cost(upgrade: Dictionary, id: String) -> int:
	if upgrade.is_empty() or rank(id) >= _definition_max_rank(upgrade):
		return 0
	var prices: Array = upgrade.get("rank_costs", [upgrade.cost])
	var price: int = int(prices[rank(id)])
	if upgrade.get("area", "bramblewick") == "bramblewick":
		price = roundi(float(price) * resistance_price_multiplier())
	# Prices of "price_rounding.from" or more round down to a multiple of
	# "price_rounding.step", after resistance too; cheaper opening prices stay exact.
	if price >= Balance.integer("price_rounding.from"):
		price -= price % Balance.integer("price_rounding.step")
	return price


## Bramblewick resists harder as each debate opponent is convinced: 1.0 before
## the first victory, rising "village.resistance_price_step" per victory.
func resistance_price_multiplier() -> float:
	return 1.0 + Balance.number("village.resistance_price_step") * float(encounter_stage)


func _definition_next_recruit_cost(upgrade: Dictionary, id: String) -> int:
	if upgrade.is_empty() or rank(id) >= _definition_max_rank(upgrade):
		return 0
	var prices: Array = upgrade.get("rank_recruit_costs", [])
	return int(prices[rank(id)]) if not prices.is_empty() else 0


## The single implementation of the purchase rules. Keep every gate here so the
## graph's status query and the player-facing panel can never disagree.
func _definition_status(upgrade: Dictionary, id: String) -> String:
	if upgrade.is_empty():
		return "unknown"
	if upgrade.get("area", "bramblewick") != active_area:
		return "locked"
	if rank(id) >= _definition_max_rank(upgrade):
		return "purchased"
	for requirement in upgrade.requires:
		if rank(requirement) < 1:
			return "locked"
	if _definition_next_cost(upgrade, id) > coins or _definition_next_recruit_cost(upgrade, id) > available_recruits:
		return "unaffordable"
	return "affordable"


## Explains the rules above for the selected inscription only. Views that ask
## about every node call `status` instead and skip this message building.
func purchase_state(id: String) -> Dictionary:
	var upgrade: Dictionary = find_upgrade(id)
	var state: Dictionary = {
		"status": _definition_status(upgrade, id), "message": "Unknown inscription.",
		"missing_gold": 0, "missing_recruits": 0,
		"gold_cost": 0, "recruit_cost": 0,
	}
	if state.status == "unknown":
		return state
	if state.status == "locked" and upgrade.get("area", "bramblewick") != active_area:
		state.message = "Travel to this inscription's area before purchasing it."
		return state
	if state.status == "purchased":
		state.message = "This inscription is already at maximum rank."
		return state
	state.gold_cost = _definition_next_cost(upgrade, id)
	state.recruit_cost = _definition_next_recruit_cost(upgrade, id)
	if state.status == "locked":
		state.message = "This inscription is sealed."
		for requirement in upgrade.requires:
			if rank(requirement) < 1:
				state.message = "Requires " + str(find_upgrade(requirement).get("title", requirement)) + "."
				break
		return state
	state.missing_gold = maxi(0, int(state.gold_cost) - coins)
	state.missing_recruits = maxi(0, int(state.recruit_cost) - available_recruits)
	var missing: Array[String] = []
	if state.missing_gold > 0:
		missing.append("%d more donations" % state.missing_gold)
	if state.missing_recruits > 0:
		missing.append("%d more recruit%s" % [state.missing_recruits, "" if state.missing_recruits == 1 else "s"])
	state.message = "Ready to inscribe rank %d." % (rank(id) + 1) if missing.is_empty() else "Need %s for rank %d." % [" and ".join(missing), rank(id) + 1]
	return state


func status(id: String) -> String:
	return _definition_status(find_upgrade(id), id)


func try_purchase(id: String, expected_rank: int = -1) -> bool:
	last_error = ""
	# The UI passes the displayed rank so repeated/stale activation cannot buy a second rank.
	if expected_rank >= 0 and rank(id) != expected_rank:
		return _fail("This rank changed. Review the next rank before buying again.")
	var state: Dictionary = purchase_state(id)
	if state.status != "affordable":
		return _fail(state.message)
	var candidate: Dictionary = save_file.snapshot()
	# The affordable state already priced this rank against the same definition.
	candidate.coins -= int(state.gold_cost)
	candidate.available_recruits -= int(state.recruit_cost)
	candidate.purchased[id] = rank(id) + 1
	# Persist the candidate first: failed writes never charge or grant the upgrade.
	if not save_file.write(candidate):
		return false
	save_file.apply(candidate)
	return true


func add_donation(amount: int, recruits: int = 1) -> void:
	if amount < 0 or recruits < 0:
		last_error = "Negative rewards are not valid."
		return
	_add_earnings(amount, recruits)
	# Keep earned progress in memory if storage fails; expose last_error to the UI.
	save_progress()


func _add_earnings(amount: int, recruits: int) -> void:
	# Clamp the increment before adding so even large valid rewards cannot overflow.
	coins += mini(amount, MAX_COUNTER - coins)
	total_recruits += mini(recruits, MAX_COUNTER - total_recruits)
	available_recruits += mini(recruits, MAX_COUNTER - available_recruits)


func speech_interval() -> float:
	return 1.0 / (1.0 + _sum_effect("speech_speed_add"))


func conviction_per_phrase() -> float:
	return 1.0 + _sum_effect("conviction_add")


func run_multiplier() -> float:
	return 1.0 + _sum_effect("run_speed_add")


## World pixels within which lone wanderers walk toward the cultist; zero without Beckoning Call.
func beckon_reach() -> float:
	return Balance.number("village.wanderers.beckon_pixels_per_point") * _sum_effect("beckon_add")


## Bellmarket's wanderers answer only the market's own call, never the village's.
func market_beckon_reach() -> float:
	return Balance.number("village.wanderers.beckon_pixels_per_point") * _sum_effect("market_beckon_add")


## Extra conviction per phrase for the teal helper in Bellmarket (Seasoned Helper).
func market_teal_conviction_bonus() -> float:
	return _sum_effect("market_teal_conviction_add")


## Extra phrases per second, as a share of base, for the amber Market Hand (Quick Hands).
func market_amber_speed_bonus() -> float:
	return _sum_effect("market_amber_speed_add")


## Lone wanderers each Bellmarket round, capped by the people authored for them.
func market_wanderer_count() -> int:
	var people: int = Balance.list("market.wanderers.people").size()
	return mini(Balance.integer("market.wanderers.count") + int(_sum_effect("market_wanderer_add")), people)


## The cultist's Interest at the fair before any stage: the carried base
## ("fair.interest.base"), Showmanship ranks and one point per convinced headliner.
func fair_interest() -> int:
	return Balance.integer("fair.interest.base") + int(_sum_effect("fair_interest_add")) + fair_boss_interest()


func fair_boss_interest() -> int:
	return Balance.integer("fair.interest.boss_bonus") * mini(fair_stage, FAIR_BOSS_COUNT)


## Extra Interest while standing on a stage; the convinced Performer adds his own.
func fair_stage_bonus() -> int:
	var bonus: int = Balance.integer("fair.stage_bonus") + int(_sum_effect("fair_stage_bonus_add"))
	for index in range(mini(fair_stage, FAIR_BOSS_COUNT)):
		bonus += int(Balance.list("fair.bosses")[index].get("effect", {}).get("stage_bonus", 0))
	return bonus


func fair_stage_reach_bonus() -> float:
	return _sum_effect("fair_stage_reach_add")


## Multiplies every fair drain rate (Captivating); never below a fifth of it.
func fair_drain_multiplier() -> float:
	return maxf(0.2, 1.0 - _sum_effect("fair_drain_cut_add"))


func fair_teal_interest() -> int:
	return Balance.integer("fair.helper.teal.interest") + int(_sum_effect("fair_teal_interest_add"))


func fair_barker_cut() -> int:
	return Balance.integer("fair.helper.moss.cut") + int(_sum_effect("fair_barker_cut_add"))


func fair_barker_speed_bonus() -> float:
	return _sum_effect("fair_barker_speed_add")


func fair_steal_seconds() -> float:
	return Balance.number("fair.stolen.seconds") + _sum_effect("fair_steal_window_add")


func fair_crowd_radius_bonus() -> float:
	return _sum_effect("fair_crowd_radius_add")


## Distraction a convinced headliner removes for good from one fair zone.
func fair_zone_cut(zone: String) -> int:
	var cut: int = 0
	for index in range(mini(fair_stage, FAIR_BOSS_COUNT)):
		var effect: Dictionary = Balance.list("fair.bosses")[index].get("effect", {})
		if String(effect.get("zone", "")) == zone:
			cut -= int(effect.get("distraction", 0))
	return cut


func complete_fair_boss(expected_stage: int) -> bool:
	if active_area != "lantern_fair" or expected_stage != fair_stage or fair_stage >= FAIR_BOSS_COUNT:
		return false
	_add_earnings(int(Balance.list("fair.bosses")[fair_stage].reward), 1)
	fair_stage += 1
	save_progress()
	return true


func fair_complete() -> bool:
	return fair_stage >= FAIR_BOSS_COUNT


## Argument IDs in card order, from "university.arguments".
static func argument_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in Balance.list("university.arguments"):
		ids.append(String(entry.id))
	return ids


## Argument slots owned: the base slot plus every Commonplace Book slot, capped.
func argument_slots() -> int:
	return _slots_for(purchased)


func _slots_for(ranks: Dictionary) -> int:
	var extra: int = 0
	for entry in catalog_for_area(UNI_AREA):
		for index in range(mini(int(ranks.get(entry.id, 0)), int(entry.get("max_rank", 1)))):
			extra += int(_rank_effect(entry, index).get("uni_slot_add", 0))
	return mini(Balance.integer("university.slots.base") + extra, Balance.integer("university.slots.max"))


func is_prepared(argument: String) -> bool:
	return argument in uni_loadout


## The only way the loadout changes. Unknown, repeated or too many arguments are
## refused; the choice is kept in memory even if storage fails, like earnings.
func set_loadout(ids: Array) -> bool:
	last_error = ""
	if active_area != UNI_AREA:
		return _fail("Arguments are prepared only at Quillmoor.")
	var known: Array[String] = argument_ids()
	var next: Array[String] = []
	for id in ids:
		if not id is String or not id in known or id in next:
			return _fail("That is not an argument you can prepare.")
		next.append(id)
	if next.size() > argument_slots():
		return _fail("You have only %d argument slot%s." % [argument_slots(), "" if argument_slots() == 1 else "s"])
	uni_loadout = next
	save_progress()
	return true


## A card tap: a prepared argument is put away; another one is prepared, and
## when every slot is full the earliest choice makes room for it.
func toggle_argument(id: String) -> bool:
	var next: Array = uni_loadout.duplicate()
	if id in next:
		next.erase(id)
	else:
		if next.size() >= argument_slots() and not next.is_empty():
			next.remove_at(0)
		next.append(id)
	return set_loadout(next)


## Extra conviction per phrase against a listener or boss who needs these
## arguments: the Commonplace Book once, plus each argument's own Mastery.
func uni_argument_conviction(arguments: Array) -> float:
	if arguments.is_empty():
		return 0.0
	var bonus: float = _sum_effect("uni_academic_conviction_add")
	for argument in arguments:
		bonus += _sum_effect("uni_" + String(argument) + "_conviction_add")
	return bonus


func uni_argument_donation(argument: String) -> int:
	return int(_sum_effect("uni_" + argument + "_donation_add")) if not argument.is_empty() else 0


## The summed effect behind an inscription's preview line.
func effect_total(key: String) -> float:
	return _sum_effect(key)


func uni_helper_conviction_bonus() -> float:
	return _sum_effect("uni_ta_conviction_add")


func uni_helper_walk_bonus() -> float:
	return _sum_effect("uni_ta_walk_add")


func uni_helper_speed_bonus() -> float:
	return _sum_effect("uni_ta_speed_add")


func complete_uni_boss(expected_stage: int) -> bool:
	if active_area != UNI_AREA or expected_stage != uni_stage or uni_stage >= UNI_BOSS_COUNT:
		return false
	_add_earnings(int(Balance.list("university.bosses")[uni_stage].reward), 1)
	uni_stage += 1
	save_progress()
	return true


func uni_complete() -> bool:
	return uni_stage >= UNI_BOSS_COUNT


func has_unlock(key: String) -> bool:
	return key in UNLOCK_KEYS and _sum_effect(key) >= 1.0


func conviction_for(npc_type: String) -> float:
	return conviction_per_phrase() + (_sum_effect("merchant_conviction_add") if npc_type == "merchant" else 0.0)


func encounter_conviction(kind: String) -> float:
	return conviction_per_phrase() + _sum_effect("encounter_conviction_add") + _sum_effect(kind + "_conviction_add")


func complete_encounter(expected_stage: int) -> bool:
	if expected_stage != encounter_stage or encounter_stage >= 4 or not has_unlock("encounter_unlock"):
		return false
	_add_earnings(int(Balance.list("encounters.opponents")[encounter_stage].reward), 1)
	encounter_stage += 1
	# Like earned donations, victory stays in memory on failed storage; expose the error.
	save_progress()
	return true


func map_complete() -> bool:
	return encounter_stage == 4


func is_circle_complete(area_id: String = "") -> bool:
	# Completion follows actual local ranks, independently of the Priest objective.
	# Preserve direct catalog fixtures for the currently displayed circle.
	var definitions: Array[Dictionary] = catalog if area_id.is_empty() or area_id == active_area else catalog_for_area(area_id)
	return _ranks_complete(definitions, purchased)


func _ranks_complete(definitions: Array[Dictionary], ranks: Dictionary) -> bool:
	if definitions.is_empty():
		return false
	for entry in definitions:
		if int(ranks.get(entry.id, 0)) != int(entry.get("max_rank", 1)):
			return false
	return true


## Each area opens from the completed circle of the area before it.
func is_area_unlocked(area_id: String) -> bool:
	if not area_id in AREA_IDS or catalog_for_area(area_id).is_empty():
		return false
	var index: int = AREA_IDS.find(area_id)
	return index == 0 or level_select_unlocked or is_circle_complete(AREA_IDS[index - 1])


func try_travel(area_id: String, bypass_unlock: bool = false) -> bool:
	last_error = ""
	if not area_id in AREA_IDS or catalog_for_area(area_id).is_empty():
		return _fail("That destination is not implemented.")
	if not bypass_unlock and not is_area_unlocked(area_id):
		var previous: String = AREA_IDS[maxi(0, AREA_IDS.find(area_id) - 1)]
		return _fail("Complete %s's ritual circle to reach %s." % [AREA_TITLES[previous], AREA_TITLES[area_id]])
	var candidate: Dictionary = save_file.snapshot()
	candidate.active_area = area_id
	candidate.level_select_unlocked = level_select_unlocked or bypass_unlock
	# Main prepares the destination before requesting this durable transition.
	if not save_file.write(candidate):
		return false
	save_file.apply(candidate)
	return true


func merchant_donation() -> int:
	return Balance.integer("village.merchants.base_donation") + int(_sum_effect("merchant_donation_add"))


func market_donation(npc_type: String, base_amount: int) -> int:
	if npc_type in ["guild", "patron"]:
		return base_amount + int(_sum_effect("market_" + npc_type + "_donation_add"))
	return base_amount


func gathering_count() -> int:
	return Balance.list("village.gatherings").size() + int(has_unlock("meadow_unlock")) + int(has_unlock("east_unlock"))


func effect_preview(id: String) -> Dictionary:
	# Composed from one catalog pass: the per-key helpers below answer the same
	# questions, but asking each separately swept every rank thirty times here.
	var totals: Dictionary = _all_effect_totals()
	var base_conviction: float = 1.0 + float(totals.conviction_add)
	var opponent_bonus: float = float(totals.encounter_conviction_add)
	var current: Dictionary = {
		"speech_frequency": 1.0 + float(totals.speech_speed_add),
		"conviction": base_conviction,
		"run_multiplier": 1.0 + float(totals.run_speed_add),
		"gatherings": Balance.list("village.gatherings").size() + int(_unlocked(totals, "meadow_unlock")) + int(_unlocked(totals, "east_unlock")),
		"merchant_unlock": int(_unlocked(totals, "merchant_unlock")),
		"merchant_conviction_add": base_conviction + float(totals.merchant_conviction_add),
		"merchant_donation_add": Balance.integer("village.merchants.base_donation") + int(float(totals.merchant_donation_add)),
		"helpers": int(_unlocked(totals, "helper_unlock")),
		"beckon_reach": Balance.number("village.wanderers.beckon_pixels_per_point") * float(totals.beckon_add),
		"market_beckon_reach": Balance.number("village.wanderers.beckon_pixels_per_point") * float(totals.market_beckon_add),
		"market_wanderers": Balance.integer("market.wanderers.count") + int(float(totals.market_wanderer_add)),
		"market_helper_unlock": int(_unlocked(totals, "market_helper_unlock")),
		"market_teal_conviction": Balance.number("market.helper.teal.conviction_per_phrase") + float(totals.market_teal_conviction_add),
		"market_amber_phrases": (1.0 + float(totals.market_amber_speed_add)) / Balance.number("market.helper.amber.phrase_seconds"),
	}
	current.encounter_unlock = int(_unlocked(totals, "encounter_unlock"))
	current.encounter_conviction_add = base_conviction + opponent_bonus
	for kind in ["skeptic", "guard", "zealot", "priest"]:
		current[kind + "_conviction_add"] = base_conviction + opponent_bonus + float(totals[kind + "_conviction_add"])
	for kind in ["guild", "patron"]:
		current["market_" + kind + "_unlock"] = int(_unlocked(totals, "market_" + kind + "_unlock"))
		current["market_" + kind + "_donation_add"] = float(totals["market_" + kind + "_donation_add"])
	var result: Dictionary = {"current": current, "next": {}}
	var upgrade: Dictionary = find_upgrade(id)
	if upgrade.is_empty() or rank(id) >= max_rank(id):
		return result
	result.next = current.duplicate()
	var effect: Dictionary = _rank_effect(upgrade, rank(id))
	result.next.speech_frequency += float(effect.get("speech_speed_add", 0.0))
	result.next.conviction += float(effect.get("conviction_add", 0.0))
	result.next.run_multiplier += float(effect.get("run_speed_add", 0.0))
	result.next.gatherings += int(effect.get("meadow_unlock", 0)) + int(effect.get("east_unlock", 0))
	for key in ["merchant_unlock", "merchant_conviction_add", "merchant_donation_add", "encounter_unlock", "encounter_conviction_add", "skeptic_conviction_add", "guard_conviction_add", "zealot_conviction_add", "priest_conviction_add"]:
		result.next[key] += float(effect.get(key, 0.0))
	for kind in ["guild", "patron"]:
		for suffix in ["_unlock", "_donation_add"]:
			var key: String = "market_" + kind + suffix
			result.next[key] += float(effect.get(key, 0.0))
	result.next.helpers += int(effect.get("helper_unlock", 0))
	result.next.beckon_reach += Balance.number("village.wanderers.beckon_pixels_per_point") * float(effect.get("beckon_add", 0.0))
	result.next.market_beckon_reach += Balance.number("village.wanderers.beckon_pixels_per_point") * float(effect.get("market_beckon_add", 0.0))
	result.next.market_wanderers += int(effect.get("market_wanderer_add", 0))
	result.next.market_helper_unlock += int(effect.get("market_helper_unlock", 0))
	result.next.market_teal_conviction += float(effect.get("market_teal_conviction_add", 0.0))
	result.next.market_amber_phrases += float(effect.get("market_amber_speed_add", 0.0)) / Balance.number("market.helper.amber.phrase_seconds")
	return result


## Replaces progression with a fresh first-round village save. The old save is
## first copied to `.previous`, which ordinary saves never rotate, so it outlives
## the next rounds' writes. A failed copy or write changes nothing.
func start_new_game() -> bool:
	return save_file.start_new_game()


func save_progress() -> bool:
	return save_file.save()


func load_progress() -> bool:
	return save_file.load_file()


func has_progress() -> bool:
	return coins > 0 or total_recruits > 0 or round_number > 1 or not purchased.is_empty() or encounter_stage > 0 or fair_stage > 0 or uni_stage > 0 or active_area != "bramblewick" or level_select_unlocked


## Called every frame for speech and conviction, so this stays allocation-free.
func _sum_effect(key: String) -> float:
	var total: float = 0.0
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		# Earned benefits carry forward into later places; a later circle's tuning
		# never reaches back, so returning never changes an earlier map's routes.
		if not _carries_here(entry):
			continue
		for index in range(rank(entry.id)):
			total += float(_rank_effect(entry, index).get(key, 0.0))
	return total


## Every supported effect from one pass over the ranks `_sum_effect` reads, using
## the same area rule and the same catalog and rank order, so the totals match it.
func _all_effect_totals() -> Dictionary:
	var totals: Dictionary = {}
	for key in EFFECT_KEYS:
		totals[key] = 0.0
	var definitions: Array[Dictionary] = all_catalog if not all_catalog.is_empty() else catalog
	for entry in definitions:
		if not _carries_here(entry):
			continue
		for index in range(rank(entry.id)):
			var effect: Dictionary = _rank_effect(entry, index)
			for key in effect:
				if totals.has(key):
					totals[key] += float(effect[key])
	return totals


## Allocation-free: AREA_IDS is a constant array searched with find().
func _carries_here(entry: Dictionary) -> bool:
	return AREA_IDS.find(str(entry.get("area", "bramblewick"))) <= AREA_IDS.find(active_area)


func _unlocked(totals: Dictionary, key: String) -> bool:
	return key in UNLOCK_KEYS and float(totals.get(key, 0.0)) >= 1.0


func _rank_effect(upgrade: Dictionary, index: int) -> Dictionary:
	return upgrade.rank_effects[index] if upgrade.has("rank_effects") else upgrade.effect


func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _parse_json(contents: String) -> Variant:
	var parser: JSON = JSON.new()
	return parser.data if parser.parse(contents) == OK else null


func _integer_between(value: Variant, minimum: int, maximum: int) -> bool:
	return _finite_number(value) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum


func _fail(message: String) -> bool:
	last_error = message
	return false
