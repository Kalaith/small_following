extends RefCounted
## Quillmoor's faculty badges, drawn wherever an argument is shown: on academics,
## bosses, the HUD and the ritual screen's cards. Each argument has its own
## shape (scroll, star, candle, quill) so colour is never the only cue.

const Balance = preload("res://scripts/balance.gd")
const COLORS: Dictionary = {"proof": Color("8fb3e0"), "evidence": Color("f0d36a"), "scripture": Color("f2e6c8"), "eloquence": Color("e39aa8")}
const INK := Color("2a2233")


static func title(argument: String) -> String:
	for entry in Balance.list("university.arguments"):
		if String(entry.id) == argument:
			return String(entry.title)
	return argument.capitalize()


static func faculty(argument: String) -> String:
	for entry in Balance.list("university.arguments"):
		if String(entry.id) == argument:
			return String(entry.faculty)
	return ""


static func color(argument: String) -> Color:
	return COLORS.get(argument, Color("d7b9ff"))


## A round plate with the argument's emblem, `radius` pixels across its half.
## A dimmed badge marks an argument that is not prepared.
static func draw(canvas: CanvasItem, at: Vector2, argument: String, radius: float = 7.0, dimmed: bool = false) -> void:
	var tint: Color = color(argument)
	if dimmed:
		tint = tint.darkened(0.45)
	canvas.draw_circle(at, radius + 1.5, INK)
	canvas.draw_circle(at, radius, tint)
	var s: float = radius / 7.0
	match argument:
		"proof": # A scroll with curled ends.
			canvas.draw_rect(Rect2(at + Vector2(-3.5, -4) * s, Vector2(7, 8) * s), Color("fbf6e8"))
			canvas.draw_circle(at + Vector2(-3.5, -4) * s, 1.6 * s, Color("fbf6e8"))
			canvas.draw_circle(at + Vector2(3.5, 4) * s, 1.6 * s, Color("fbf6e8"))
			canvas.draw_line(at + Vector2(-2, -1.5) * s, at + Vector2(2, -1.5) * s, INK, maxf(1.0, s * 0.8))
			canvas.draw_line(at + Vector2(-2, 1.5) * s, at + Vector2(2, 1.5) * s, INK, maxf(1.0, s * 0.8))
		"evidence": # A five-pointed star.
			var star := PackedVector2Array()
			for index in range(10):
				var reach: float = 5.2 if index % 2 == 0 else 2.2
				star.append(at + Vector2.from_angle(-PI * 0.5 + index * PI / 5.0) * reach * s)
			canvas.draw_colored_polygon(star, INK)
		"scripture": # A candle and its flame.
			canvas.draw_rect(Rect2(at + Vector2(-1.8, -1) * s, Vector2(3.6, 6) * s), INK)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5.5) * s, at + Vector2(1.8, -2) * s, at + Vector2(-1.8, -2) * s]), Color("e0702f"))
		"eloquence": # A quill pen.
			canvas.draw_line(at + Vector2(-4, 4.5) * s, at + Vector2(4, -4.5) * s, INK, maxf(1.0, s * 1.1))
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(4, -4.5) * s, at + Vector2(-1, -2) * s, at + Vector2(1.5, 1) * s]), INK)


## A speech bubble struck through, with the badge of the argument it wanted.
static func draw_rebuttal(canvas: CanvasItem, at: Vector2, argument: String) -> void:
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color("f6efe0")
	bubble.set_corner_radius_all(7)
	canvas.draw_style_box(bubble, Rect2(at, Vector2(30, 17)))
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(4, 16), at + Vector2(11, 16), at + Vector2(3, 22)]), Color("f6efe0"))
	draw(canvas, at + Vector2(15, 8.5), argument, 5.5)
	canvas.draw_line(at + Vector2(3, 15), at + Vector2(27, 2), Color("b4363c"), 2.0, true)
