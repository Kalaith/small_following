extends RefCounted
## The ritual screen's wording for each area's circle: its title, the road back
## to the visible place, the round subtitle and the completion message.

const AREA_WORDS: Dictionary = {
	"bramblewick": {"title": "The circle grows.", "back": "Return to the village", "complete": "This is the end of the demo", "after": "Every inscription is yours. You can keep playing in this village."},
	"bellmarket": {"title": "Bellmarket's circle.", "back": "Return to the market", "complete": "Bellmarket's circle is complete", "after": "Every inscription is yours. Keep exploring the market or return to Bramblewick."},
	"lantern_fair": {"title": "The fair's circle.", "back": "Return to the fair", "complete": "The fair's circle is complete", "after": "Every inscription is yours. Keep enjoying the fair or return to Bellmarket."},
	"university": {"title": "Quillmoor's circle.", "back": "Return to the university", "complete": "Quillmoor's circle is complete", "after": "Every inscription is yours. Keep debating at Quillmoor or return to the fair."},
	"rosecourt": {"title": "The rose circle.", "back": "Return to the garden", "complete": "The rose circle is complete", "after": "Every inscription is yours. Win the King's approval, or return to Quillmoor."},
}


static func words(area: String, key: String) -> String:
	return String(AREA_WORDS.get(area, AREA_WORDS["bramblewick"])[key])


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
	return text
