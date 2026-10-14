extends Node2D
## One fair headliner (Performer, Head Clown, Mime, Ringmaster) at its own spot.
## Like Bramblewick's opponents it needs a large conviction, has a habit, pays a
## reward and leaves a lasting effect; like every fair listener it must hear the
## cultist (Interest against its Distraction) and drains fast when it does not.
## Main supplies only active-round time; thresholds are balance data "fair.bosses".
signal convinced(stage: int)
signal phrase_spoken

const Balance = preload("res://addons/hatchery/core/balance.gd")
const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
## Floating-point slack when comparing accumulated per-frame time to a fixed interval.
const TIME_EPSILON: float = 0.000001


static func profiles() -> Array:
	return Balance.list("fair.bosses")


## The habit caption, written from the headliner's actual data.
static func hint(profile: Dictionary) -> String:
	var parts: Array[String] = ["Distraction %d" % int(profile.distraction)]
	if profile.has("show"):
		parts.append("deaf while performing")
	if int(profile.get("rebuttals", 0)) > 0:
		parts.append("honks at your first %d phrases" % int(profile.rebuttals))
	if bool(profile.get("still_only", false)):
		parts.append("stand completely still")
	if profile.has("hoops"):
		parts.append("run through the lit hoop")
	parts.append("drains %d/s" % int(profile.drain))
	return " / ".join(parts)


var stage: int = 0
var progress: float = 0.0
var phrase_elapsed: float = 0.0
var rebuttals_left: int = 0
var defeated: bool = false
## In range and speaking; `deaf` when those phrases do not count.
var listening: bool = false
var deaf: bool = false
## The Performer's own show; set by the fair director.
var show_on: bool = false
var next_show_in: float = -1.0
## Captivating upgrades slow the drain; set by main.
var drain_multiplier: float = 1.0
var viewer_interest: int = 0
## The Ringmaster's hoops in world space, the lit one and the Bravo window.
var hoops: Array[Vector2] = []
var lit_hoop: int = 0
var bravo_left: float = 0.0
var _unattended: float = 0.0
var _phase: float = 0.0


func profile() -> Dictionary:
	return profiles()[stage]


func _ready() -> void:
	y_sort_enabled = true
	position = Balance.vec(profile().at)
	rebuttals_left = int(profile().get("rebuttals", 0))
	if profile().has("hoops"):
		var ring: Dictionary = profile().hoops
		for index in range(int(ring.count)):
			# Evenly spaced round the Ringmaster, every one inside his speaking range.
			var direction := Vector2.from_angle(-PI * 0.5 + index * TAU / float(ring.count))
			hoops.append(position + Vector2(direction.x, direction.y * 0.8) * float(ring.radius))


func distraction() -> int:
	return int(profile().distraction)


## Whether a phrase spoken now would count.
func hears(interest: int, still: bool) -> bool:
	if interest < distraction() or show_on:
		return false
	if bool(profile().get("still_only", false)) and not still:
		return false
	if not hoops.is_empty() and bravo_left <= 0.0:
		return false
	return true


## Running through the lit hoop earns a Bravo: a short window in which the
## Ringmaster hears you, and the next hoop lights. Missing one only costs time.
func check_hoops(player_at: Vector2) -> void:
	if hoops.is_empty() or defeated:
		return
	if player_at.distance_to(hoops[lit_hoop]) <= float(profile().hoops.trigger):
		bravo_left = float(profile().hoops.bravo_seconds)
		lit_hoop = (lit_hoop + 1) % hoops.size()


func advance(delta: float, in_range: bool, interval: float, conviction: float, interest: int, still: bool, player_at: Vector2) -> void:
	delta = maxf(0.0, delta)
	_phase += delta
	if defeated:
		listening = false
		deaf = false
		queue_redraw()
		return
	bravo_left = maxf(0.0, bravo_left - delta)
	check_hoops(player_at)
	viewer_interest = interest
	var heard: bool = in_range and hears(interest, still)
	listening = in_range
	deaf = in_range and not heard
	if not heard:
		progress = maxf(0.0, progress - float(profile().drain) * drain_multiplier * delta)
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
	var color := Color("b49bd0") if defeated else Color(String(data.coat))
	var bob: float = sin(_phase * 2.4) * 1.5
	DrawShapes.oval(self, Vector2.ZERO, Vector2(20, 8), Color(0.22, 0.2, 0.15, 0.25))
	match String(data.id):
		"performer": _draw_performer(color, bob)
		"clown": _draw_clown(color, bob)
		"mime": _draw_mime(color, bob)
		"ringmaster": _draw_ringmaster(color, bob)
	_draw_caption(data)


func _body(color: Color, bob: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -34 + bob), Vector2(11, -34 + bob), Vector2(18, -2), Vector2(-18, -2)]), color)
	draw_circle(Vector2(0, -41 + bob), 11, Color("edc9a3"))
	var glance: float = 3.0 if deaf else 0.0
	draw_circle(Vector2(-4 + glance, -41 + bob), 1.6, Color("51453f"))
	draw_circle(Vector2(4 + glance, -41 + bob), 1.6, Color("51453f"))


func _draw_performer(color: Color, bob: float) -> void:
	_body(color, bob)
	# A wide-brimmed busker's hat and a lute, strummed while the show runs.
	draw_rect(Rect2(-16, -52 + bob, 32, 4), Color("4a3a30"))
	draw_rect(Rect2(-9, -62 + bob, 18, 11), Color("4a3a30"))
	draw_line(Vector2(-8, -55 + bob), Vector2(8, -55 + bob), Color("d9b45a"), 2)
	var strum: float = sin(_phase * 14.0) * 3.0 if show_on else 0.0
	DrawShapes.oval(self, Vector2(12, -18), Vector2(9, 11), Color("b07a45"))
	draw_line(Vector2(12, -26), Vector2(24, -46), Color("7a5232"), 3)
	draw_line(Vector2(6, -22 + strum), Vector2(16, -16 - strum), Color("f2e3c0"), 1)


func _draw_clown(color: Color, bob: float) -> void:
	_body(color, bob)
	for x in [-11, 0, 11]:
		draw_circle(Vector2(x, -30 + bob), 5, Color("f4eee2"))
	for button in range(3):
		draw_circle(Vector2(0, -24 + button * 7 + bob), 2.2, Color("d8423c"))
	draw_circle(Vector2(0, -39 + bob), 3.6, Color("e0332e"))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -50 + bob), Vector2(0, -72 + bob), Vector2(9, -50 + bob)]), Color("5f9bd1"))
	draw_circle(Vector2(0, -73 + bob), 3.5, Color("f2c84b"))
	draw_arc(Vector2(-13, -44 + bob), 5, 0, TAU, 12, Color("e86f4f"), 3, true)
	draw_arc(Vector2(13, -44 + bob), 5, 0, TAU, 12, Color("e86f4f"), 3, true)


func _draw_mime(color: Color, bob: float) -> void:
	# Striped shirt, white face and beret; the gesture changes while listening.
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -34 + bob), Vector2(11, -34 + bob), Vector2(18, -2), Vector2(-18, -2)]), Color("f1eef2"))
	for stripe in range(4):
		draw_line(Vector2(-13 + stripe, -28 + stripe * 7 + bob), Vector2(13 - stripe, -28 + stripe * 7 + bob), Color("2f2f36"), 3)
	draw_circle(Vector2(0, -41 + bob), 11, Color("f7f4f6"))
	var glance: float = 3.0 if deaf else 0.0
	draw_line(Vector2(-6 + glance, -42 + bob), Vector2(-2 + glance, -42 + bob), Color("2f2f36"), 1.5)
	draw_line(Vector2(2 + glance, -42 + bob), Vector2(6 + glance, -42 + bob), Color("2f2f36"), 1.5)
	draw_line(Vector2(-3, -35 + bob), Vector2(3, -35 + bob), Color("c0303a"), 2)
	DrawShapes.oval(self, Vector2(2, -52 + bob), Vector2(12, 5), Color("2f2f36"))
	var hands: float = -8.0 if listening and not deaf else 0.0
	for side in [-1, 1]:
		draw_line(Vector2(side * 10, -28 + bob), Vector2(side * 22, -34 + hands + bob), Color("f1eef2"), 4)
		draw_circle(Vector2(side * 22, -34 + hands + bob), 3, Color("f7f4f6"))
	if color == Color("b49bd0"):
		draw_circle(Vector2(0, -12), 4, color)


func _draw_ringmaster(color: Color, bob: float) -> void:
	_body(color, bob)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -12), Vector2(-20, 4), Vector2(-6, -2)]), color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(11, -12), Vector2(20, 4), Vector2(6, -2)]), color.darkened(0.25))
	draw_line(Vector2(0, -33 + bob), Vector2(0, -6), Color("f2c84b"), 2)
	draw_rect(Rect2(-14, -53 + bob, 28, 4), Color("1f1a22"))
	draw_rect(Rect2(-9, -74 + bob, 18, 22), Color("1f1a22"))
	draw_rect(Rect2(-9, -58 + bob, 18, 4), Color("c0303a"))
	draw_line(Vector2(16, -24), Vector2(34, -52 + sin(_phase * 3.0) * 6.0), Color("6b4a2f"), 2)
	draw_arc(Vector2(-4, -36 + bob), 5, 0.2, PI - 0.2, 8, Color("5a3a28"), 2, true)


func _draw_caption(data: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	var title: String = String(data.title)
	var detail: String = "%d / %d conviction" % [int(progress), int(data.conviction)]
	if defeated:
		detail = "Convinced / the Lantern Fair is won!" if stage == profiles().size() - 1 else "Convinced / joins your act"
	elif deaf:
		detail += " / can't hear you"
	if rebuttals_left > 0 and not defeated:
		detail += " / %d honk%s" % [rebuttals_left, "" if rebuttals_left == 1 else "s"]
	if not defeated and data.has("show"):
		detail += " / SHOW!" if show_on else " / show in %ds" % ceili(maxf(next_show_in, 0.0))
	var hint_text: String = hint(data) if not defeated else ""
	var width: float = maxf(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x, font.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	width = maxf(width, font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x) + 24
	var top: float = -168.0 if data.has("hoops") else -150.0
	if not listening and not defeated:
		_draw_name_tag(title, top + 36.0)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("44354c")
		style.set_corner_radius_all(7)
		draw_style_box(style, Rect2(-width * 0.5, top, width, 66 if not hint_text.is_empty() else 46))
		draw_string(font, Vector2(-width * 0.5 + 12, top + 20), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0ce"))
		draw_string(font, Vector2(-width * 0.5 + 12, top + 39), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8d4a9"))
		if not hint_text.is_empty():
			draw_string(font, Vector2(-width * 0.5 + 12, top + 58), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffd0c0") if viewer_interest < distraction() else Color("fff0ce"))
	if defeated:
		return
	draw_arc(Vector2.ZERO, 28, 0, TAU, 40, Color("ffd36b") if listening and not deaf else Color("e9cc8f"), 2, true)
	draw_line(Vector2(-48, 17), Vector2(48, 17), Color("62634d"), 6)
	draw_line(Vector2(-48, 17), Vector2(-48 + 96 * progress / float(data.conviction), 17), Color("d6b3ee"), 6)
	if deaf:
		var bubble := StyleBoxFlat.new()
		bubble.bg_color = Color("f6efe0")
		bubble.set_corner_radius_all(7)
		draw_style_box(bubble, Rect2(8, -82, 30, 16))
		for dot in range(3):
			draw_circle(Vector2(16 + dot * 7, -74), 1.8, Color("6a6070"))


## Out of speaking range a boss shows only its name; the full card appears in range.
func _draw_name_tag(title: String, top: float) -> void:
	var font := ThemeDB.fallback_font
	var width: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 24
	var style := StyleBoxFlat.new()
	style.bg_color = Color("44354c")
	style.set_corner_radius_all(7)
	draw_style_box(style, Rect2(-width * 0.5, top, width, 30))
	draw_string(font, Vector2(-width * 0.5 + 12, top + 21), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff0ce"))
