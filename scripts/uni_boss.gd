extends Node2D
## One Quillmoor boss (Debate Captain, Logician, Astronomer, Rector) at its own
## spot. Like Bramblewick's opponents it needs a large conviction, has habits
## (rebuttals at the start of each visit, decay while left), pays a reward and
## sends followers. It also demands arguments: unless every one it needs is
## prepared, it rebuts everything. Main supplies only active-round time;
## thresholds are balance data "university.bosses".
signal convinced(stage: int)
signal phrase_spoken

const Balance = preload("res://scripts/balance.gd")
const DrawShapes = preload("res://scripts/draw_shapes.gd")
const ArgumentBadge = preload("res://scripts/argument_badge.gd")
## Floating-point slack when comparing accumulated per-frame time to a fixed interval.
const TIME_EPSILON: float = 0.000001


static func profiles() -> Array:
	return Balance.list("university.bosses")


## The habit caption, written from the boss's actual data.
static func hint(profile: Dictionary) -> String:
	var parts: Array[String] = []
	var needs: PackedStringArray = []
	for argument in profile.needs:
		needs.append(ArgumentBadge.title(String(argument)))
	parts.append("needs " + " + ".join(needs))
	var rebuttals: int = int(profile.get("rebuttals", 0))
	if rebuttals > 0:
		parts.append("rebuts your first %d phrase%s" % [rebuttals, "" if rebuttals == 1 else "s"])
	if float(profile.get("decay", 0.0)) > 0.0:
		parts.append("loses %d/s when left" % int(profile.decay))
	return " / ".join(parts)


var stage: int = 0
var progress: float = 0.0
var phrase_elapsed: float = 0.0
var rebuttals_left: int = 0
var defeated: bool = false
## In range and speaking; `rebutting` while the needed arguments are missing.
var listening: bool = false
var rebutting: bool = false
## Every argument this boss needs is in the loadout; set by main each frame.
var prepared: bool = false
## Seconds into the round; the Rector arrives late.
var clock: float = 0.0
## Needed arguments missing from the loadout, as last told by `prepared_from`.
var missing: Array = []
var _unattended: float = 0.0
var _phase: float = 0.0


func profile() -> Dictionary:
	return profiles()[stage]


func needs() -> Array:
	return profile().needs


func arrived() -> bool:
	return clock + TIME_EPSILON >= float(profile().get("arrive_seconds", 0.0))


func _ready() -> void:
	y_sort_enabled = true
	position = Balance.vec(profile().at)
	rebuttals_left = int(profile().get("rebuttals", 0))


func advance(delta: float, in_range: bool, interval: float, conviction: float) -> void:
	delta = maxf(0.0, delta)
	clock += delta
	_phase += delta
	if defeated or not arrived():
		listening = false
		rebutting = false
		queue_redraw()
		return
	var heard: bool = in_range and prepared
	listening = in_range
	rebutting = in_range and not prepared
	if not heard:
		progress = maxf(0.0, progress - float(profile().get("decay", 0.0)) * delta)
	if in_range:
		_unattended = 0.0
		interval = maxf(0.05, interval)
		phrase_elapsed += delta
		while phrase_elapsed + TIME_EPSILON >= interval and not defeated:
			phrase_elapsed = maxf(0.0, phrase_elapsed - interval)
			phrase_spoken.emit()
			if not heard:
				continue
			if rebuttals_left > 0:
				rebuttals_left -= 1
				continue
			progress = minf(float(profile().conviction), progress + maxf(0.0, conviction))
			if progress >= float(profile().conviction):
				defeated = true
				convinced.emit(stage)
	else:
		phrase_elapsed = 0.0
		_unattended += delta
		if _unattended >= Balance.number("village.rebuttal_reset_seconds"):
			rebuttals_left = int(profile().get("rebuttals", 0))
	queue_redraw()


func _draw() -> void:
	var data: Dictionary = profile()
	if not arrived():
		# An empty place kept for a late arrival.
		draw_arc(Vector2.ZERO, 26, 0, TAU, 32, Color(1.0, 0.95, 0.8, 0.5), 2.0, true)
		_draw_caption(data, "Arrives in %ds" % ceili(float(data.get("arrive_seconds", 0.0)) - clock))
		return
	var color := Color("b49bd0") if defeated else Color(String(data.coat))
	var bob: float = sin(_phase * 2.2) * 1.2
	DrawShapes.oval(self, Vector2.ZERO, Vector2(20, 8), Color(0.22, 0.2, 0.15, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -34 + bob), Vector2(12, -34 + bob), Vector2(19, -2), Vector2(-19, -2)]), color)
	draw_circle(Vector2(0, -41 + bob), 11, Color("edc9a3"))
	var glance: float = 3.0 if rebutting else 0.0
	draw_circle(Vector2(-4 + glance, -41 + bob), 1.6, Color("51453f"))
	draw_circle(Vector2(4 + glance, -41 + bob), 1.6, Color("51453f"))
	match String(data.id):
		"captain": # Mortarboard, a debating sash and a raised finger.
			_mortarboard(bob, Color("26212e"))
			draw_line(Vector2(-11, -32 + bob), Vector2(12, -8), Color("e6d8bc"), 4)
			draw_line(Vector2(14, -26 + bob), Vector2(22, -46 + bob), Color("edc9a3"), 3)
		"logician": # Spectacles and a long proof on a scroll.
			_mortarboard(bob, Color("26212e"))
			draw_arc(Vector2(-4, -41 + bob), 4, 0, TAU, 16, Color("493f3e"), 1.2, true)
			draw_arc(Vector2(4, -41 + bob), 4, 0, TAU, 16, Color("493f3e"), 1.2, true)
			draw_rect(Rect2(12, -30, 10, 26), Color("fbf6e8"))
			for line in range(4):
				draw_line(Vector2(14, -26 + line * 6), Vector2(20, -26 + line * 6), Color("6a6070"), 1)
		"astronomer": # A starry hat and a brass telescope.
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -48 + bob), Vector2(0, -80 + bob), Vector2(13, -48 + bob)]), color.darkened(0.2))
			for star in [Vector2(-3, -58), Vector2(4, -66), Vector2(0, -52)]:
				draw_circle(star + Vector2(0, bob), 1.6, Color("f0d36a"))
			draw_line(Vector2(10, -20), Vector2(30, -42), Color("c9a24f"), 5)
		"rector": # Ermine collar, a tall velvet cap and the university mace.
			draw_rect(Rect2(-14, -36 + bob, 28, 6), Color("f4f0e8"))
			for dot in [-9, -3, 3, 9]:
				draw_circle(Vector2(dot, -33 + bob), 1.0, Color("2a2233"))
			draw_rect(Rect2(-10, -66 + bob, 20, 16), color.darkened(0.25))
			draw_rect(Rect2(-12, -52 + bob, 24, 4), Color("c9a24f"))
			draw_line(Vector2(24, 2), Vector2(24, -60), Color("c9a24f"), 4)
			draw_circle(Vector2(24, -62), 6, Color("e0c06a"))
	_draw_caption(data, "")
	if defeated:
		return
	draw_arc(Vector2.ZERO, 28, 0, TAU, 40, Color("ffd36b") if listening and not rebutting else Color("e9cc8f"), 2, true)
	draw_line(Vector2(-48, 17), Vector2(48, 17), Color("62634d"), 6)
	draw_line(Vector2(-48, 17), Vector2(-48 + 96 * progress / float(data.conviction), 17), Color("d6b3ee"), 6)
	if rebutting:
		ArgumentBadge.draw_rebuttal(self, Vector2(8, -92), String(missing[0]) if not missing.is_empty() else String(needs()[0]))


func _mortarboard(bob: float, tint: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -51 + bob), Vector2(0, -57 + bob), Vector2(15, -51 + bob), Vector2(0, -45 + bob)]), tint)
	draw_line(Vector2(11, -51 + bob), Vector2(13, -40 + bob), Color("d9b45a"), 1.5)


## Every needed argument must be in the loadout; main calls this each frame.
func prepared_from(progression) -> void:
	missing.clear()
	for argument in needs():
		if not progression.is_prepared(String(argument)):
			missing.append(argument)
	prepared = missing.is_empty()


func _draw_caption(data: Dictionary, override: String) -> void:
	var font := ThemeDB.fallback_font
	var title: String = String(data.title)
	var detail: String = override
	if detail.is_empty():
		detail = "%d / %d conviction" % [int(progress), int(data.conviction)]
		if defeated:
			detail = "Convinced / Quillmoor is won!" if stage == profiles().size() - 1 else "Convinced / followers arrive next round"
		elif rebutting:
			detail += " / rebuts everything"
		elif rebuttals_left > 0:
			detail += " / %d rebuttal%s" % [rebuttals_left, "" if rebuttals_left == 1 else "s"]
	if override.is_empty() and not listening and not defeated:
		_draw_name_tag(title, -132.0)
		return
	var hint_text: String = hint(data) if not defeated else ""
	var width: float = maxf(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x, font.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	width = maxf(width, font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20.0 * needs().size()) + 24
	var top: float = -168.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("44354c")
	style.set_corner_radius_all(7)
	draw_style_box(style, Rect2(-width * 0.5, top, width, 66 if not hint_text.is_empty() else 46))
	draw_string(font, Vector2(-width * 0.5 + 12, top + 20), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0ce"))
	draw_string(font, Vector2(-width * 0.5 + 12, top + 39), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8d4a9"))
	if hint_text.is_empty():
		return
	# One badge per needed argument, dimmed while it is not prepared.
	var x: float = -width * 0.5 + 18
	for argument in needs():
		ArgumentBadge.draw(self, Vector2(x, top + 54), String(argument), 7.0, argument in missing)
		x += 20.0
	draw_string(font, Vector2(x, top + 58), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffd0c0") if not prepared else Color("fff0ce"))


## Out of speaking range a boss shows only its name; the full card appears in range.
func _draw_name_tag(title: String, top: float) -> void:
	var font := ThemeDB.fallback_font
	var width: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 24
	var style := StyleBoxFlat.new()
	style.bg_color = Color("44354c")
	style.set_corner_radius_all(7)
	draw_style_box(style, Rect2(-width * 0.5, top, width, 30))
	draw_string(font, Vector2(-width * 0.5 + 12, top + 21), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff0ce"))
