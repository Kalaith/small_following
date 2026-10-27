extends Node2D
## The Pope, on the cathedra before the church doors. The hardest person in the
## game: he needs an enormous conviction, hears the cultist only once enough
## advocates stand before him, and meanwhile is moved only by those advocates,
## who plead every second. He takes his seat late (see AbbeyRules.pope_present).
## Tuning is balance data "abbey.pope"; main supplies only active-round time. He
## carries no text: the HUD explains him, and a row of candles counts advocates.
signal convinced
signal phrase_spoken

const Balance = preload("res://addons/hatchery/core/balance.gd")
const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
## Floating-point slack when comparing accumulated per-frame time to a fixed interval.
const TIME_EPSILON: float = 0.000001
const CANDLE_ROW: int = 11

## On the cathedra this round; false leaves it empty.
var present: bool = false
var progress: float = 0.0
var phrase_elapsed: float = 0.0
## Won, now or on an earlier visit (a lasting victory).
var defeated: bool = false
var listening: bool = false
## The abbey's procession: who stands before him and how hard they plead.
var procession: Node2D = null
var _phase: float = 0.0


static func rules() -> Dictionary:
	return Balance.dict("abbey.pope")


func _ready() -> void:
	y_sort_enabled = true
	position = Balance.vec(rules().at)


func conviction() -> float:
	return float(rules().conviction)


func needed() -> int:
	return procession.needed if is_instance_valid(procession) else int(rules().open_pleaders)


func standing() -> int:
	return procession.standing_count() if is_instance_valid(procession) else 0


## His ears are closed to the cultist until enough advocates stand before him.
func reserved() -> bool:
	return standing() < needed()


func advance(delta: float, in_range: bool, interval: float, phrase_conviction: float) -> void:
	delta = maxf(0.0, delta)
	_phase += delta
	listening = false
	if not present or defeated:
		queue_redraw()
		return
	# The advocates plead whether or not the cultist is near.
	if is_instance_valid(procession):
		progress = minf(conviction(), progress + procession.plea_rate() * delta)
	if progress >= conviction():
		_win()
		return
	listening = in_range
	if not listening:
		phrase_elapsed = 0.0
		queue_redraw()
		return
	# Twenty phrases a second at most, as everywhere; faster speech makes each heavier.
	var burst: float = 0.05 / interval if interval > 0.0 and interval < 0.05 else 1.0
	interval = maxf(0.05, interval)
	phrase_elapsed += delta
	while phrase_elapsed + TIME_EPSILON >= interval and not defeated:
		phrase_elapsed = maxf(0.0, phrase_elapsed - interval)
		phrase_spoken.emit()
		if reserved():
			continue
		progress = minf(conviction(), progress + maxf(0.0, phrase_conviction) * burst)
		if progress >= conviction():
			_win()
	queue_redraw()


func _win() -> void:
	defeated = true
	listening = false
	convinced.emit()
	queue_redraw()


func _draw() -> void:
	_draw_throne()
	if not present and not defeated:
		return
	var content: bool = defeated
	var bob: float = sin(_phase * 1.6) * 1.0
	DrawShapes.oval(self, Vector2.ZERO, Vector2(24, 9), Color(0.22, 0.2, 0.15, 0.25))
	var robe := Color("e6dcf0") if content else Color(String(rules().coat))
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -38 + bob), Vector2(14, -38 + bob), Vector2(24, -2), Vector2(-24, -2)]), robe)
	# The pallium, a gold-embroidered band over the shoulders and down the front.
	draw_rect(Rect2(-16, -40 + bob, 32, 6), Color("f4f0e8"))
	draw_line(Vector2(0, -36 + bob), Vector2(0, -6), Color("c9a24f"), 3)
	for cross in [-7, 7]:
		draw_line(Vector2(cross, -30 + bob), Vector2(cross, -22 + bob), Color("2a2233"), 2)
	# The ferula: a tall golden staff topped with a cross.
	draw_line(Vector2(24, 0), Vector2(28, -66), Color("c9a24f"), 3)
	draw_line(Vector2(21, -58), Vector2(35, -58), Color("c9a24f"), 3)
	draw_circle(Vector2(0, -46 + bob), 11, Color("edc9a3"))
	draw_circle(Vector2(-4, -46 + bob), 1.6, Color("51453f"))
	draw_circle(Vector2(4, -46 + bob), 1.6, Color("51453f"))
	draw_arc(Vector2(0, -42 + bob), 4, 0.3, PI - 0.3, 8, Color("8a5a46"), 1.5, true)
	# The triple tiara.
	for tier in range(3):
		var y: float = -55.0 - tier * 8.0 + bob
		var half: float = 11.0 - tier * 2.4
		draw_rect(Rect2(-half, y - 8, half * 2.0, 8), Color("f2eee6") if tier % 2 == 0 else Color("e0c06a"))
		draw_line(Vector2(-half, y), Vector2(half, y), Color("c9a24f"), 1.5)
	draw_circle(Vector2(0, -82 + bob), 3, Color("e0c06a"))
	if content:
		draw_line(Vector2(-4, -98), Vector2(-1, -95), Color("#fbf1b6"), 2)
		draw_line(Vector2(-1, -95), Vector2(5, -102), Color("#fbf1b6"), 2)
		return
	if reserved():
		# Closed to the cultist, like a reserved noble: a closed fan beside the tiara.
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -88), Vector2(3, -88), Vector2(6, -110), Vector2(-6, -110)]), Color("f3ddb0"))
		draw_line(Vector2(0, -88), Vector2(0, -110), Color("8a6a43"), 1)
	# One candle per advocate he needs, lit as each arrives to plead.
	var lit: int = standing()
	for index in range(needed()):
		var at := Vector2(-50 + (index % CANDLE_ROW) * 10.0, 30 + (index / CANDLE_ROW) * 11.0)
		var on: bool = index < lit
		draw_rect(Rect2(at.x - 1.5, at.y, 3, 6), Color("f0e8d4") if on else Color(0.4, 0.38, 0.42, 0.7))
		if on:
			draw_circle(at + Vector2(0, -2), 2.4, Color("ffd36b"))
	draw_arc(Vector2.ZERO, 32, 0, TAU, 40, Color("ffd36b") if listening and not reserved() else Color("e9cc8f"), 2, true)
	draw_line(Vector2(-60, 18), Vector2(60, 18), Color("62634d"), 6)
	draw_line(Vector2(-60, 18), Vector2(-60 + 120.0 * progress / conviction(), 18), Color("d6b3ee"), 6)


## The cathedra, drawn behind him; it stands empty until he takes his seat.
func _draw_throne() -> void:
	DrawShapes.oval(self, Vector2(0, -2), Vector2(34, 11), Color(0.22, 0.2, 0.15, 0.2))
	draw_rect(Rect2(-30, -92, 60, 84), Color("b8913f"))
	draw_rect(Rect2(-23, -85, 46, 70), Color("f0ebe0"))
	draw_rect(Rect2(-34, -20, 68, 16), Color("c9a24f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -92), Vector2(0, -116), Vector2(30, -92)]), Color("c9a24f"))
	draw_line(Vector2(0, -116), Vector2(0, -130), Color("c9a24f"), 3)
	draw_line(Vector2(-6, -124), Vector2(6, -124), Color("c9a24f"), 3)
