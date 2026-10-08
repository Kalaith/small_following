extends RefCounted
## Wording for the ritual's detail panel: branch headings and effect previews.

const Progression = preload("res://scripts/progression.gd")
const BRANCH_NAMES: Dictionary = {"talk": "THE VOICE", "persuade": "THE CONVICTION", "run": "THE PILGRIM", "gather": "THE VILLAGE", "helper": "THE COMPANION", "merchant": "THE MERCHANT", "trial": "THE TRIALS", "faith": "THE FAITH", "market_run": "THE MARKET ROUTES", "market_talk": "THE MARKET VOICE", "market_persuade": "THE COMMON CAUSE", "market_guild": "THE GUILD", "market_patron": "THE PATRONS"}


static func branch_name(branch: String) -> String:
	return BRANCH_NAMES.get(branch, "THE CIRCLE")


static func effect_text(progression: Progression, by_id: Dictionary, id: String, branch: String, complete: bool) -> String:
	if not is_instance_valid(progression):
		return ""
	var preview: Dictionary = progression.effect_preview(id)
	var current: Dictionary = preview.get("current", {})
	var next: Dictionary = preview.get("next", {})
	if branch.begins_with("market_"):
		var market_item: Dictionary = by_id[id]
		var lines: PackedStringArray = []
		var labels: Dictionary = {"speech_frequency": "Phrases / second", "conviction": "Conviction / phrase", "run_multiplier": "Running / base speed", "market_guild_unlock": "GUILD TRADERS", "market_guild_donation_add": "Extra donations / guild trader", "market_patron_unlock": "WEALTHY PATRONS", "market_patron_donation_add": "Extra donations / patron", "market_beckon_reach": "Wanderers walk to you within (px)", "market_wanderers": "Lone wanderers / round"}
		var keys: Dictionary = {"speech_speed_add": "speech_frequency", "conviction_add": "conviction", "run_speed_add": "run_multiplier", "market_beckon_add": "market_beckon_reach", "market_wanderer_add": "market_wanderers"}
		for effect_key in market_item.get("effect", {}):
			var key: String = str(keys.get(effect_key, effect_key))
			if not current.has(key):
				continue
			var label: String = str(labels.get(key, key.replace("_", " ").capitalize()))
			if key.ends_with("_unlock"):
				lines.append(label + ("\nReady to listen" if complete else "\nSealed → ready to listen"))
				continue
			# Reach and head counts are whole numbers; rates keep two decimals.
			var shown: String = "%d" if key in ["market_beckon_reach", "market_wanderers"] else "%.2f"
			lines.append("%s\n%s%s" % [label, shown % float(current[key]), "" if complete or not next.has(key) else " → " + shown % float(next[key])])
		return "\n".join(lines)
	if branch in ["merchant", "trial", "faith"]:
		var item: Dictionary = by_id[id]
		var key: String = str(item.effect.keys()[0])
		if not current.has(key):
			return ""
		var labels: Dictionary = {"merchant_unlock": "MERCHANT PAIR", "merchant_conviction_add": "MERCHANT CONVICTION", "merchant_donation_add": "GOLD PER MERCHANT", "encounter_unlock": "TOWN DEBATE", "encounter_conviction_add": "ALL OPPONENTS / CONVICTION", "skeptic_conviction_add": "SKEPTIC / CONVICTION", "guard_conviction_add": "GUARD / CONVICTION", "zealot_conviction_add": "ZEALOT / CONVICTION", "priest_conviction_add": "PRIEST / CONVICTION"}
		var label: String = str(labels.get(key, key.replace("_", " ").capitalize()))
		return "%s\n%.1f%s" % [label, current[key], "" if complete or not next.has(key) else " -> %.1f" % next[key]]
	if by_id.has(id) and by_id[id].get("effect", {}).has("beckon_add") and current.has("beckon_reach"):
		var reach: float = float(current.beckon_reach)
		if complete or not next.has("beckon_reach"):
			return "BECKONING REACH\nwanderers within %d px" % int(reach)
		return "BECKONING REACH\n%d → %d px" % [int(reach), int(next.beckon_reach)]
	var stat_key: String = {"talk": "speech_frequency", "persuade": "conviction", "run": "run_multiplier", "gather": "gatherings", "helper": "helpers"}.get(branch, "")
	var heading: String = {"talk": "TALKING FREQUENCY", "persuade": "CONVICTION PER PHRASE", "run": "RUNNING SPEED", "gather": "VILLAGE GATHERINGS", "helper": "HELPERS"}.get(branch, "")
	var units: String = {"talk": "phrases/s", "persuade": "conviction", "run": "x base", "gather": "groups", "helper": "helpers"}.get(branch, "")
	if stat_key.is_empty() or not current.has(stat_key):
		return ""
	var current_value: float = float(current[stat_key])
	if branch == "helper":
		return "ONE LISTENER AT A TIME\n1 helper / 150 px per second" if complete else "HELPERS\n0 → 1 / one listener at a time"
	if branch == "gather":
		if complete or not next.has(stat_key):
			return "%s\n%d groups of three or four" % [heading, int(current_value)]
		return "%s\n%d → %d groups" % [heading, int(current_value), int(next[stat_key])]
	if complete or not next.has(stat_key):
		return "%s\n%.2f %s" % [heading, current_value, units]
	return "%s\n%.2f → %.2f %s" % [heading, current_value, float(next[stat_key]), units]


static func roman(value: int) -> String:
	var numerals: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
	return numerals[value - 1] if value >= 1 and value <= numerals.size() else str(value)
