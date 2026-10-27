extends RefCounted
## Abbey inscriptions, read like Rosecourt's: the current value from progression
## and, before the rank is bought, the value it would reach.

const Balance = preload("res://addons/hatchery/core/balance.gd")
const AbbeyRules = preload("res://scripts/abbey_rules.gd")


static func effect_text(progression: RefCounted, by_id: Dictionary, id: String, current: Dictionary, complete: bool) -> String:
	var item: Dictionary = by_id.get(id, {})
	var rank: int = progression.rank(id)
	var next_effect: Dictionary = {} if complete or rank >= int(item.get("max_rank", 1)) else item.rank_effects[rank]
	var lines: PackedStringArray = []
	for key in item.get("effect", {}):
		var step: float = float(next_effect.get(key, 0.0))
		match key:
			"speech_speed_add":
				lines.append(_pair("Phrases / second", float(current.get("speech_frequency", 0.0)), step, "%.2f"))
			"conviction_add":
				lines.append(_pair("Conviction / phrase", float(current.get("conviction", 0.0)), step, "%.2f"))
			"run_speed_add":
				lines.append(_pair("Running / base speed", float(current.get("run_multiplier", 0.0)), step, "%.2f"))
			"abbey_plea_add":
				lines.append(_pair("Plea strength / follower (x)", AbbeyRules.plea_multiplier(progression), step, "%.2f"))
			"abbey_plea_walk_add":
				var walk: float = Balance.number("abbey.procession.walk_speed")
				lines.append(_pair("Followers walk to the Pope (px/s)", walk * AbbeyRules.plea_walk_multiplier(progression), walk * step, "%.0f"))
			"abbey_heed_add":
				var needed: float = float(AbbeyRules.pleaders_needed(progression))
				lines.append(_pair("Advocates the Pope needs", needed, -step, "%.0f"))
			"abbey_helper_power_add":
				lines.append(_pair("Helpers / conviction (x)", AbbeyRules.helper_power(progression), step, "%.2f"))
			"abbey_helper_speed_add":
				lines.append(_pair("Helpers / speech (x)", AbbeyRules.helper_speed(progression), step, "%.2f"))
			"abbey_helper_walk_add":
				lines.append(_pair("Helpers / walking (x)", AbbeyRules.helper_walk(progression), step, "%.2f"))
			"abbey_donation_add":
				lines.append(_pair("Extra gold / brother, elder, cardinal", progression.effect_total(key), step, "+%.0f"))
	return "\n".join(lines)


static func _pair(label: String, now: float, step: float, shown: String) -> String:
	var text: String = label + "\n" + shown % now
	if step != 0.0:
		text += " -> " + shown % (now + step)
	return text
