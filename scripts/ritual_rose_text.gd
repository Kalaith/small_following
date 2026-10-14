extends RefCounted
## Rosecourt inscriptions, read like Quillmoor's: the current value from
## progression and, before the rank is bought, the value it would reach.

const Balance = preload("res://addons/hatchery/core/balance.gd")


static func effect_text(progression: RefCounted, by_id: Dictionary, id: String, current: Dictionary, complete: bool) -> String:
	var item: Dictionary = by_id.get(id, {})
	var rank: int = progression.rank(id)
	var next_effect: Dictionary = {} if complete or rank >= int(item.get("max_rank", 1)) else item.rank_effects[rank]
	var lines: PackedStringArray = []
	var teal: String = "rosecourt.helper.teal."
	for key in item.get("effect", {}):
		var step: float = float(next_effect.get(key, 0.0))
		match key:
			"speech_speed_add":
				lines.append(_pair("Phrases / second", float(current.get("speech_frequency", 0.0)), step, "%.2f"))
			"conviction_add":
				lines.append(_pair("Conviction / phrase", float(current.get("conviction", 0.0)), step, "%.2f"))
			"run_speed_add":
				lines.append(_pair("Running / base speed", float(current.get("run_multiplier", 0.0)), step, "%.2f"))
			"rose_head_start_add":
				var cap: float = Balance.number("rosecourt.whispers.head_start_max")
				var now: float = progression.rose_head_start()
				lines.append(_pair("Whispered guests start (%)", now * 100.0, (minf(now + step, cap) - now) * 100.0, "%.0f"))
			"rose_reach_add":
				lines.append(_pair("Extra guests per thread", progression.rose_reach(), step, "%d"))
			"rose_trusted_add":
				lines.append(_pair("Nobles who trust you each round", progression.rose_trusted_count(), step, "%d"))
			"rose_whisper_conviction_add":
				lines.append(_pair("Bonus / phrase to a whispered guest", progression.rose_whisper_conviction(), step, "+%.0f"))
			"rose_noble_donation_add":
				lines.append(_pair("Extra gold / noble", progression.effect_total(key), step, "+%.0f"))
			"rose_helper_conviction_add":
				lines.append(_pair("Teal helper / conviction per phrase", Balance.number(teal + "conviction_per_phrase") + progression.rose_helper_conviction_bonus(), step, "%.0f"))
			"rose_helper_walk_add":
				var walk: float = Balance.number(teal + "walk_speed")
				lines.append(_pair("Teal helper / walking (px/s)", walk * (1.0 + progression.rose_helper_walk_bonus()), walk * step, "%.0f"))
	return "\n".join(lines)


static func _pair(label: String, now: float, step: float, shown: String) -> String:
	var text: String = label + "\n" + shown % now
	if step > 0.0:
		text += " -> " + shown % (now + step)
	return text
