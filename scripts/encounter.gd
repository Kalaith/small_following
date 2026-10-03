extends Node2D
## One visiting opponent. Main supplies only time remaining in the active round.
signal convinced(stage: int)

const CENTER := Vector2(790, 570)
const ENTRANCE := Vector2(1470, 630)
const TURN := Vector2(1000, 630)
const WALK_SPEED: float = 220.0
const PROFILES: Array[Dictionary] = [
	{"id": "skeptic", "title": "Skeptic", "conviction": 42.0, "rebuttals": 0, "decay": 0.0, "coat": "728b98", "hint": "A patient argument / 42 conviction"},
	{"id": "guard", "title": "Town Guard", "conviction": 72.0, "rebuttals": 2, "decay": 0.0, "coat": "607590", "hint": "First 2 phrases answer objections"},
	{"id": "zealot", "title": "Zealot", "conviction": 108.0, "rebuttals": 0, "decay": 6.0, "coat": "bb7454", "hint": "Loses 6 conviction/s when you leave"},
	{"id": "priest", "title": "Priest of Bramblewick", "conviction": 240.0, "rebuttals": 3, "decay": 9.0, "coat": "e4d3a3", "hint": "3 objections / loses 9 conviction/s alone"},
]

var stage: int = 0
var progress: float = 0.0
var phrase_elapsed: float = 0.0
var rebuttals_left: int = 0
var arrived: bool = false
var defeated: bool = false
var listening: bool = false
var path: Array[Vector2] = [TURN, CENTER]


func _ready() -> void:
	position = ENTRANCE
	rebuttals_left = int(PROFILES[stage].rebuttals)


func advance_arrival(delta: float) -> float:
	var remaining: float = maxf(0.0, delta)
	while not path.is_empty() and remaining > 0.0:
		var used: float = minf(remaining, position.distance_to(path[0]) / WALK_SPEED)
		position = position.move_toward(path[0], WALK_SPEED * used)
		remaining -= used
		if position.distance_to(path[0]) < 0.001:
			path.remove_at(0)
		else:
			break
	arrived = path.is_empty()
	queue_redraw()
	return remaining if arrived else 0.0


func advance_speech(delta: float, in_range: bool, interval: float, conviction: float) -> void:
	interval = maxf(0.05, interval)
	delta = maxf(0.0, delta)
	listening = in_range and arrived and not defeated
	if not arrived or defeated:
		return
	if not listening:
		progress = maxf(0.0, progress - float(PROFILES[stage].decay) * delta)
	else:
		phrase_elapsed += maxf(0.0, delta)
		while phrase_elapsed + 0.000001 >= interval and not defeated:
			phrase_elapsed = maxf(0.0, phrase_elapsed - interval)
			if rebuttals_left > 0:
				rebuttals_left -= 1
			else:
				progress = minf(float(PROFILES[stage].conviction), progress + maxf(0.0, conviction))
				if progress >= float(PROFILES[stage].conviction):
					defeated = true
					convinced.emit(stage)
	queue_redraw()


func _draw() -> void:
	var profile: Dictionary = PROFILES[stage]
	var color := Color("b49bd0") if defeated else Color(profile.coat)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 18, Color(0.22, 0.27, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -34), Vector2(11, -34), Vector2(18, -2), Vector2(-18, -2)]), color)
	draw_circle(Vector2(0, -41), 11, Color("edc9a3"))
	draw_circle(Vector2(-4, -41), 1.6, Color("51453f"))
	draw_circle(Vector2(4, -41), 1.6, Color("51453f"))
	match stage:
		0: # Book and spectacles.
			draw_arc(Vector2(-4, -41), 4, 0, TAU, 16, Color("493f3e"), 1.2, true)
			draw_arc(Vector2(4, -41), 4, 0, TAU, 16, Color("493f3e"), 1.2, true)
			draw_rect(Rect2(-18, -24, 15, 17), Color("634d78"))
			draw_line(Vector2(-11, -23), Vector2(-11, -8), Color("efdcbb"), 2)
		1: # Helmet and shield.
			draw_arc(Vector2(0, -44), 12, PI, TAU, 20, Color("aab9bd"), 7, true)
			draw_colored_polygon(PackedVector2Array([Vector2(8, -28), Vector2(25, -28), Vector2(23, -10), Vector2(16, -4), Vector2(9, -10)]), Color("a2b7bf"))
			draw_line(Vector2(16, -26), Vector2(16, -9), Color("506778"), 3)
		2: # Tall red hood and sun medallion.
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -48), Vector2(0, -65), Vector2(13, -48)]), color)
			draw_circle(Vector2.ZERO + Vector2(0, -25), 6, Color("f3d075"))
			draw_line(Vector2(-9, -9), Vector2(9, -31), Color("f1c79d"), 3)
		3: # Mitre, purple stole and a crozier.
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -48), Vector2(-11, -64), Vector2(0, -75), Vector2(11, -64), Vector2(13, -48)]), color)
			draw_line(Vector2(0, -69), Vector2(0, -51), Color("ad853c"), 3)
			for x in [-7, 7]:
				draw_line(Vector2(x, -32), Vector2(x, -4), Color("895897"), 4)
			draw_line(Vector2(26, 0), Vector2(26, -55), Color("af863c"), 4)
			draw_arc(Vector2(22, -55), 7, PI, TAU + PI * 0.5, 20, Color("dbb656"), 3, true)
	var font := ThemeDB.fallback_font
	var title: String = str(profile.title)
	var detail: String = "Walking to the town center"
	if defeated:
		detail = "Convinced / Bramblewick complete!" if stage == 3 else "Convinced / next visitor next round"
	elif arrived:
		detail = "%d / %d conviction" % [int(progress), int(profile.conviction)]
		if rebuttals_left > 0:
			detail += " / %d objections" % rebuttals_left
	var hint: String = str(profile.hint) if arrived and not defeated else ""
	var width: float = maxf(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x, font.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	width = maxf(width, font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x) + 24
	draw_style_box(_style(), Rect2(-width * 0.5, -150, width, 66 if not hint.is_empty() else 46))
	draw_string(font, Vector2(-width * 0.5 + 12, -130), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0ce"))
	draw_string(font, Vector2(-width * 0.5 + 12, -111), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8d4a9"))
	if not hint.is_empty():
		draw_string(font, Vector2(-width * 0.5 + 12, -92), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff0ce"))
	if arrived and not defeated:
		draw_arc(Vector2.ZERO, 28, 0, TAU, 40, Color("e9cc8f"), 2, true)
		draw_line(Vector2(-48, 17), Vector2(48, 17), Color("62634d"), 6)
		draw_line(Vector2(-48, 17), Vector2(-48 + 96 * progress / float(profile.conviction), 17), Color("d6b3ee"), 6)



func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("44354c")
	style.set_corner_radius_all(7)
	return style
