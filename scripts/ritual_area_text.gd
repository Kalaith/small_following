extends RefCounted
## The ritual screen's wording for each area's circle: its title, the road back
## to the visible place, the round subtitle and the completion message.

const AbbeyRules = preload("res://scripts/abbey_rules.gd")
const AREA_WORDS: Dictionary = {
	"bramblewick": {"title": "The circle grows.", "back": "Return to the village", "complete": "Bramblewick's circle is complete", "after": "Every inscription is yours. You can keep playing in this village."},
	"bellmarket": {"title": "Bellmarket's circle.", "back": "Return to the market", "complete": "Bellmarket's circle is complete", "after": "Every inscription is yours. Keep exploring the market or return to Bramblewick."},
	"lantern_fair": {"title": "The fair's circle.", "back": "Return to the fair", "complete": "The fair's circle is complete", "after": "Every inscription is yours. Keep enjoying the fair or return to Bellmarket."},
	"university": {"title": "Quillmoor's circle.", "back": "Return to the university", "complete": "Quillmoor's circle is complete", "after": "Every inscription is yours. Keep debating at Quillmoor or return to the fair."},
	"rosecourt": {"title": "The rose circle.", "back": "Return to the garden", "complete": "The rose circle is complete", "after": "Every inscription is yours. Win the King's approval, or return to Quillmoor."},
	"abbey": {"title": "The abbey's circle.", "back": "Return to the abbey", "complete": "The abbey's circle is complete", "after": "Every inscription is yours. Bring every follower before the Pope, or return to Rosecourt."},
}


static func words(area: String, key: String) -> String:
	return String(AREA_WORDS.get(area, AREA_WORDS["bramblewick"])[key])


## The completion panel's two lines. Rosecourt's depends on the King, and so does
## the road on from it: the abbey is open, but the Pope receives only his friend.
static func completion(area: String, progression: RefCounted, destination: String) -> Dictionary:
	var king_won: bool = is_instance_valid(progression) and progression.rose_king_won
	if area == "rosecourt" and not destination.is_empty():
		if king_won:
			return {"title": "The road to %s is open" % destination, "body": "The King has given his approval: the Pope will receive you. Bring every follower."}
		return {"title": "The road to %s is open" % destination, "body": "The Pope receives only a pilgrim with the King's approval. Win it in Rosecourt first."}
	if area == "rosecourt":
		return {"title": words(area, "complete"), "body": "Every inscription is yours. " + ("The King's approval is yours: go before the Pope." if king_won else "Win the King's approval, then go before the Pope.")}
	if not destination.is_empty():
		return {"title": "The road to %s is open" % destination, "body": "Visit its separate circle and new listeners. Your progress in both towns is kept."}
	return {"title": words(area, "complete"), "body": words(area, "after")}


## The line under the title: the round's followers plus the area's own goal.
static func subtitle(area: String, progression: RefCounted, round_recruits: int) -> String:
	var text: String = "ROUND COMPLETE  /  %d NEW FOLLOWERS" % round_recruits
	if not is_instance_valid(progression):
		return text
	match area:
		"university":
			var debaters: Array[String] = ["Debate Captain", "Logician", "Astronomer", "Rector"]
			text = "QUILLMOOR  /  %d NEW FOLLOWERS  /  " % round_recruits
			if progression.uni_complete():
				text += "RECTOR CONVINCED"
			else:
				text += "DEBATES %d/4 / Next: %s" % [progression.uni_stage, debaters[progression.uni_stage]]
		"lantern_fair":
			var headliners: Array[String] = ["Performer", "Head Clown", "Mime", "Ringmaster"]
			text = "THE LANTERN FAIR  /  %d NEW FOLLOWERS  /  " % round_recruits
			if progression.fair_complete():
				text += "RINGMASTER CONVINCED"
			else:
				text += "HEADLINERS %d/4 / Next: %s / Interest %d" % [progression.fair_stage, headliners[progression.fair_stage], progression.fair_interest()]
		"rosecourt":
			text = "ROSECOURT  /  %d NEW FOLLOWERS  /  " % round_recruits
			text += "THE KING'S APPROVAL IS YOURS" if progression.rose_king_won else "Win the high nobles, then the King"
		"abbey":
			var fellowship: Vector2i = AbbeyRules.fellowship(progression)
			text = "THE HILLTOP ABBEY  /  %d NEW FOLLOWERS  /  " % round_recruits
			if progression.abbey_pope_won:
				text += "THE POPE HAS HEARD YOU"
			elif not progression.rose_king_won:
				text += "The Pope needs the King's approval"
			else:
				text += "FOLLOWERS %d/%d / %s" % [fellowship.x, fellowship.y, "The Pope will receive you" if fellowship.x == fellowship.y else "Master every follower inscription"]
	return text
