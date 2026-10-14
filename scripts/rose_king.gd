extends Node2D
## The King of Rosecourt on his throne before the pavilion. Like Bramblewick's
## Priest he needs a large conviction, pays a reward and, once won, stays won.
## He arrives late (the throne stands empty until enough of the rose circle is
## owned) and is reserved: he listens only after every grandee with a thread
## to him has been won this round, and each of their whispers already fills a
## share of his conviction. Tuning is balance data "rosecourt.king"; main
## supplies only active-round time. He carries no text: the HUD explains him.
signal convinced
signal phrase_spoken

const Balance = preload("res://scripts/balance.gd")
const DrawShapes = preload("res://scripts/draw_shapes.gd")
## Floating-point slack when comparing accumulated per-frame time to a fixed interval.
const TIME_EPSILON: float = 0.000001

## On the throne this round; false leaves the throne empty.
var present: bool = false
var progress: float = 0.0
var phrase_elapsed: float = 0.0
## Won this round, or his approval was already given (a lasting victory).
var defeated: bool = false
var listening: bool = false
## Grandee whispers that have reached him this round, out of `whispers_needed`.
var whispers: int = 0
var whispers_needed: int = 0
var _phase: float = 0.0


static func rules() -> Dictionary:
	return Balance.dict("rosecourt.king")


## Grandees whose threads end at the King: all of them must be won in one round.
static func needed() -> int:
	var count: int = 0
	for thread in Balance.list("rosecourt.threads"):
		if "king" in thread.to:
			count += 1
	return count


func _ready() -> void:
	y_sort_enabled = true
	position = Balance.vec(rules().at)
	whispers_needed = needed()


func conviction() -> float:
	return float(rules().conviction)


## He listens once every grandee has whispered to him this round.
func reserved() -> bool:
	return whispers < whispers_needed


## A grandee's whisper reached him: one more voice, and a share of his conviction.
func hear_whisper() -> void:
	if defeated or not present:
		return
	whispers += 1
	progress = minf(conviction(), progress + conviction() * float(rules().whisper_share))
	queue_redraw()


func advance(delta: float, in_range: bool, interval: float, phrase_conviction: float) -> void:
	delta = maxf(0.0, delta)
	_phase += delta
	listening = in_range and present and not defeated
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
			defeated = true
			convinced.emit()
	queue_redraw()


func _draw() -> void:
	_draw_throne()
	if not present and not defeated:
		return
	var content: bool = defeated
	var robe := Color("b49bd0") if content else Color(String(rules().coat))
	var bob: float = sin(_phase * 2.0) * 1.0
	DrawShapes.oval(self, Vector2.ZERO, Vector2(22, 8), Color(0.22, 0.2, 0.15, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -36 + bob), Vector2(14, -36 + bob), Vector2(22, -2), Vector2(-22, -2)]), robe)
	# Ermine cape, a gold chain and the sceptre.
	draw_rect(Rect2(-16, -38 + bob, 32, 7), Color("f4f0e8"))
	for dot in [-11, -4, 4, 11]:
		draw_circle(Vector2(dot, -35 + bob), 1.1, Color("2a2233"))
	draw_arc(Vector2(0, -26 + bob), 8, 0.2, PI - 0.2, 10, Color("d9b45a"), 2, true)
	draw_line(Vector2(20, 0), Vector2(26, -48), Color("c9a24f"), 3)
	draw_circle(Vector2(26, -51), 4, Color("e0c06a"))
	draw_circle(Vector2(0, -44 + bob), 11, Color("edc9a3"))
	draw_circle(Vector2(-4, -44 + bob), 1.6, Color("51453f"))
	draw_circle(Vector2(4, -44 + bob), 1.6, Color("51453f"))
	draw_arc(Vector2(0, -36 + bob), 7, 0.3, PI - 0.3, 10, Color("e8e2d6"), 3, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -51 + bob), Vector2(-11, -62 + bob), Vector2(-5, -56 + bob), Vector2(0, -65 + bob), Vector2(5, -56 + bob), Vector2(11, -62 + bob), Vector2(11, -51 + bob)]), Color("e0c06a"))
	if content:
		draw_line(Vector2(-4, -76), Vector2(-1, -73), Color("#fbf1b6"), 2)
		draw_line(Vector2(-1, -73), Vector2(5, -80), Color("#fbf1b6"), 2)
		return
	if reserved():
		# Reserved, like his nobles: a closed fan until every grandee has whispered.
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -72), Vector2(3, -72), Vector2(6, -94), Vector2(-6, -94)]), Color("f3ddb0"))
		draw_line(Vector2(0, -72), Vector2(0, -94), Color("8a6a43"), 1)
	# One rose per grandee whisper he needs, lit as each arrives.
	for index in range(whispers_needed):
		var at := Vector2(-14 + index * 14, 30)
		draw_circle(at, 5.0, Color("c2486a") if index < whispers else Color(0.35, 0.3, 0.32, 0.6))
		draw_circle(at, 2.0, Color("f0a0b4") if index < whispers else Color(0.5, 0.45, 0.47, 0.6))
	draw_arc(Vector2.ZERO, 30, 0, TAU, 40, Color("ffd36b") if listening and not reserved() else Color("e9cc8f"), 2, true)
	draw_line(Vector2(-48, 18), Vector2(48, 18), Color("62634d"), 6)
	draw_line(Vector2(-48, 18), Vector2(-48 + 96 * progress / conviction(), 18), Color("d6b3ee"), 6)


## The gilded throne, drawn behind him; it stands empty until he arrives.
func _draw_throne() -> void:
	DrawShapes.oval(self, Vector2(0, -2), Vector2(30, 10), Color(0.22, 0.2, 0.15, 0.2))
	draw_rect(Rect2(-26, -78, 52, 70), Color("b8913f"))
	draw_rect(Rect2(-20, -72, 40, 58), Color("9b2f45"))
	draw_rect(Rect2(-30, -20, 60, 16), Color("c9a24f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -78), Vector2(0, -98), Vector2(26, -78)]), Color("c9a24f"))
	draw_circle(Vector2(0, -88), 4, Color("c2486a"))
