extends Node2D
## Capture-only set pieces for the music video, drawn in the game's flat style.
## Lives under tools/; nothing here is part of the game. Origin is the ground
## anchor (feet), like the game's own props, so y-sorting works in $Actors.

const WOOD := Color("8a6440")
const WOOD_LIGHT := Color("a57a4c")
const WOOD_DARK := Color("5a3f2a")
const LILAC := Color("9670ad")
const LILAC_DARK := Color("51365f")
const LILAC_LIGHT := Color("b998cf")
const CREAM := Color("fff1d0")
const GOLD := Color("e2b953")
const GOLD_DARK := Color("a57c25")
const SHADOW := Color(0.17, 0.13, 0.21, 0.22)

var kind: String = "table"
var text: String = ""
var tint: Color = WOOD
var count: int = 0          # coins in the bowl, biscuits in the tin, tally marks
var lift: float = 0.0       # draw this far above the anchor (things on a table)
var size_scale: float = 1.0
var flipped: bool = false   # the clipboard, face-down
var carried: bool = false   # a statue or idol on carrying poles instead of a cart
var lit: float = 1.0        # spotlight strength
var time: float = 0.0


func _process(delta: float) -> void:
	time += delta
	if kind in ["fire", "candle", "zzz", "cone"]:
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale))
	match kind:
		"table": _table()
		"chair": _chair()
		"candle": _candle()
		"sign": _sign()
		"robe_hook": _robe_hook()
		"tin": _tin()
		"bowl": _bowl()
		"coin": _coin()
		"pie": _pie()
		"fire": _fire()
		"banner": _banner()
		"robe_rack": _robe_rack()
		"lectern": _lectern()
		"bell": _bell()
		"cone": _cone()
		"statue": _statue()
		"idol": _idol()
		"clipboard": _clipboard()
		"rug": _rug()
		"flag": _flag()
		"zzz": _zzz()
		"nametag": _nametag()
		"helper": _helper()


func _shadow(width: float) -> void:
	draw_set_transform(Vector2(0, 2 - lift), 0.0, Vector2(size_scale, size_scale * 0.32))
	draw_circle(Vector2.ZERO, width, SHADOW)
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale))


func _text(at: Vector2, value: String, font_size: int, color: Color, width: float = 200.0) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, at - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


func _table() -> void:
	_shadow(60)
	draw_line(Vector2(-44, 0), Vector2(36, -40), WOOD_DARK, 4)
	draw_line(Vector2(44, 0), Vector2(-36, -40), WOOD_DARK, 4)
	draw_rect(Rect2(-58, -46, 116, 9), tint)
	draw_rect(Rect2(-58, -38, 116, 3), WOOD_DARK)


func _chair() -> void:
	_shadow(16)
	draw_line(Vector2(-10, 0), Vector2(-10, -18), WOOD_DARK, 3)
	draw_line(Vector2(10, 0), Vector2(10, -18), WOOD_DARK, 3)
	draw_rect(Rect2(-13, -21, 26, 6), tint)
	draw_rect(Rect2(-13, -46, 5, 26), tint)
	draw_rect(Rect2(-13, -46, 22, 6), tint.darkened(0.15))


func _candle() -> void:
	draw_rect(Rect2(-3, -16, 6, 16), CREAM)
	var flicker: float = sin(time * 17.0) * 1.2 + sin(time * 7.3) * 0.8
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -17), Vector2(flicker * 0.4, -27 - flicker), Vector2(3, -17)]), Color("ffcf6e"))
	draw_circle(Vector2(0, -20), 9, Color(1, 0.85, 0.45, 0.16))


func _sign() -> void:
	_shadow(14)
	draw_line(Vector2(0, 0), Vector2(0, -52), WOOD_DARK, 4)
	var width: float = maxf(70.0, ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 22)
	draw_rect(Rect2(-width * 0.5, -78, width, 30), tint)
	draw_rect(Rect2(-width * 0.5, -78, width, 30), WOOD_DARK, false, 2)
	_text(Vector2(0, -57), text, 15, CREAM, width)


func _robe_hook() -> void:
	_shadow(14)
	draw_line(Vector2(0, 0), Vector2(0, -70), WOOD_DARK, 4)
	draw_line(Vector2(-12, 0), Vector2(12, 0), WOOD_DARK, 4)
	draw_line(Vector2(0, -66), Vector2(10, -66), WOOD_DARK, 3)
	draw_colored_polygon(PackedVector2Array([Vector2(4, -64), Vector2(16, -64), Vector2(24, -20), Vector2(-4, -20)]), LILAC)
	draw_line(Vector2(8, -58), Vector2(4, -24), LILAC_LIGHT, 2)


func _tin() -> void:
	var w: float = 16.0
	_shadow(w)
	draw_rect(Rect2(-w, -20, w * 2, 20), tint)
	draw_rect(Rect2(-w, -14, w * 2, 6), CREAM.darkened(0.1))
	draw_set_transform(Vector2(0, -20 * size_scale - lift), 0.0, Vector2(size_scale, size_scale * 0.4))
	draw_circle(Vector2.ZERO, w, tint.lightened(0.15))
	draw_circle(Vector2.ZERO, w - 3, Color("3a2a22") if count >= 0 else tint)
	for i in range(maxi(count, 0)):
		draw_circle(Vector2(-6 + (i % 3) * 6, -2 + (i / 3) * 4), 3.2, Color("d9a95b"))
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale))
	if text != "":
		# Shrink the label until it fits inside the tin's band.
		var font_size: int = 7
		while font_size > 3 and ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > w * 2 - 4:
			font_size -= 1
		_text(Vector2(0, -8), text, font_size, Color("3a2a22"), w * 2)


func _bowl() -> void:
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale * 0.45))
	draw_circle(Vector2(0, -6), 18, Color("6b4f2a"))
	draw_circle(Vector2(0, -8), 16, GOLD_DARK)
	for i in range(count):
		draw_circle(Vector2(-9 + (i % 4) * 6, -10 + (i / 4) * 4), 3.5, GOLD)
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale))
	draw_line(Vector2(-18, -6), Vector2(18, -6), GOLD_DARK, 2)


func _coin() -> void:
	draw_circle(Vector2.ZERO, 5, GOLD)
	draw_arc(Vector2.ZERO, 5, 0, TAU, 12, GOLD_DARK, 1.5, true)


func _pie() -> void:
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale * 0.5))
	draw_circle(Vector2(0, -6), 11, Color("b9783f"))
	draw_circle(Vector2(0, -9), 9, Color("e0b36a"))
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale))
	for dx in [-4.0, 0.0, 4.0]:
		draw_line(Vector2(dx, -6), Vector2(dx + 1.5, -3), Color("9b5f2c"), 1.2)


func _fire() -> void:
	_shadow(16)
	draw_line(Vector2(-12, -2), Vector2(12, -6), WOOD_DARK, 4)
	draw_line(Vector2(-12, -6), Vector2(12, -2), WOOD, 4)
	var f: float = sin(time * 13.0) * 1.5 + sin(time * 5.1)
	draw_circle(Vector2(0, -12), 16, Color(1, 0.6, 0.25, 0.14))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -5), Vector2(f, -26 - f), Vector2(8, -5)]), Color("f39a4b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -5), Vector2(f * 0.6, -18), Vector2(4, -5)]), Color("ffd66e"))


func _banner() -> void:
	var half: float = 120.0
	for x in [-half, half]:
		draw_line(Vector2(x, 0), Vector2(x, -110), WOOD_DARK, 5)
	draw_rect(Rect2(-half, -108, half * 2, 40), tint)
	draw_rect(Rect2(-half, -108, half * 2, 40), LILAC_DARK, false, 2)
	_text(Vector2(0, -81), text, 18, CREAM, half * 2)


func _robe_rack() -> void:
	_shadow(46)
	draw_line(Vector2(-44, 0), Vector2(-44, -70), WOOD_DARK, 4)
	draw_line(Vector2(44, 0), Vector2(44, -70), WOOD_DARK, 4)
	draw_line(Vector2(-48, -70), Vector2(48, -70), WOOD_DARK, 4)
	for i in range(5):
		var x: float = -34 + i * 17
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, -68), Vector2(x + 5, -68), Vector2(x + 9, -24), Vector2(x - 9, -24)]), LILAC if i % 2 == 0 else LILAC_LIGHT)


func _lectern() -> void:
	_shadow(20)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(6, -44), Vector2(-6, -44)]), WOOD)
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -44), Vector2(20, -50), Vector2(18, -58), Vector2(-22, -52)]), WOOD_LIGHT)
	draw_line(Vector2(-20, -45), Vector2(20, -51), WOOD_DARK, 2)


func _bell() -> void:
	_shadow(22)
	draw_line(Vector2(-22, 0), Vector2(-22, -80), WOOD_DARK, 5)
	draw_line(Vector2(22, 0), Vector2(22, -80), WOOD_DARK, 5)
	draw_line(Vector2(-26, -80), Vector2(26, -80), WOOD_DARK, 5)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -76), Vector2(6, -76), Vector2(14, -48), Vector2(-14, -48)]), Color("c9a24a"))
	draw_circle(Vector2(0, -46), 3, Color("7a5a1c"))


func _cone() -> void:
	var a: float = 0.20 * lit
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -260), Vector2(12, -260), Vector2(46, -4), Vector2(-46, -4)]), Color(1, 0.95, 0.7, a))
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 48, Color(1, 0.95, 0.7, a * 1.6))


func _cultist_shape(fill: Color, dark: Color, light: Color) -> void:
	# The player's silhouette (scripts/player.gd), recoloured as stone or gold.
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -38), Vector2(12, -38), Vector2(21, -5), Vector2(11, 0), Vector2(0, -3), Vector2(-11, 0), Vector2(-21, -5)]), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -37), Vector2(10, -37), Vector2(17, -7), Vector2(8, -4), Vector2(0, -7), Vector2(-9, -4), Vector2(-17, -7)]), fill)
	draw_circle(Vector2(0, -43), 20, dark)
	draw_circle(Vector2(-1, -45), 18, fill)
	draw_arc(Vector2(-1, -45), 15, PI * 1.10, PI * 1.80, 20, light, 2.0, true)
	draw_circle(Vector2(0, -42), 12, dark.darkened(0.3))


func _carrying_poles(half: float) -> void:
	draw_line(Vector2(-half, -12), Vector2(half, -12), WOOD_DARK, 4)
	draw_line(Vector2(-half, -2), Vector2(half, -2), WOOD_DARK, 4)


func _statue() -> void:
	if carried:
		_carrying_poles(58)
	else:
		_shadow(40)
		for x in [-26.0, 26.0]:
			draw_circle(Vector2(x, -6), 8, WOOD_DARK)
	draw_rect(Rect2(-36, -26, 72, 18), WOOD)
	draw_rect(Rect2(-22, -40, 44, 14), Color("9a9490"))
	draw_set_transform(Vector2(0, -40 * size_scale - lift), 0.0, Vector2(size_scale * 1.9, size_scale * 1.9))
	_cultist_shape(Color("b9b2ad"), Color("7d7672"), Color("d6d0cb"))


func _idol() -> void:
	if carried:
		_carrying_poles(46)
	else:
		_shadow(30)
		for x in [-20.0, 20.0]:
			draw_circle(Vector2(x, -5), 6, WOOD_DARK)
	draw_rect(Rect2(-28, -18, 56, 12), WOOD)
	draw_set_transform(Vector2(0, -18 * size_scale - lift), 0.0, Vector2(size_scale * 1.3, size_scale * 1.3))
	_cultist_shape(GOLD, GOLD_DARK, Color("fff0b0"))
	draw_circle(Vector2(-4.5, -41), 2, CREAM)
	draw_circle(Vector2(4.5, -41), 2, CREAM)


func _clipboard() -> void:
	draw_rect(Rect2(-13, -38, 26, 34), WOOD_LIGHT if not flipped else WOOD_DARK)
	if flipped:
		draw_rect(Rect2(-13, -38, 26, 34), Color("3a2a22"), false, 1.5)
		return
	draw_rect(Rect2(-10, -33, 20, 27), CREAM)
	draw_rect(Rect2(-5, -40, 10, 5), Color("777777"))
	_text(Vector2(0, -26), "FOLLOWERS", 4, Color("3a2a22"), 24)
	for i in range(count):
		var x: float = -8 + (i % 5) * 4
		var y: float = -20 + (i / 5) * 6
		if i % 5 == 4:
			draw_line(Vector2(x - 16, y + 4), Vector2(x, y - 1), Color("8a2a3a"), 1)
		else:
			draw_line(Vector2(x, y), Vector2(x, y + 5), Color("3a2a22"), 1)


func _rug() -> void:
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(size_scale, size_scale * 0.42))
	draw_circle(Vector2.ZERO, 120, LILAC_DARK)
	draw_arc(Vector2.ZERO, 108, 0, TAU, 48, LILAC_LIGHT, 3, true)
	draw_arc(Vector2.ZERO, 70, 0, TAU, 40, GOLD, 2, true)
	var star: PackedVector2Array = []
	for k in range(6):
		var angle: float = -PI / 2 + k * 4 * PI / 5
		star.append(Vector2(cos(angle), sin(angle)) * 66)
	draw_polyline(star, GOLD, 2, true)


func _flag() -> void:
	_shadow(8)
	draw_line(Vector2(0, 0), Vector2(0, -96), WOOD_DARK, 3)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -95), Vector2(40, -86 + sin(time * 3.0) * 2), Vector2(1, -76)]), tint)


func _zzz() -> void:
	for i in range(3):
		var t: float = fmod(time * 0.6 + i * 0.33, 1.0)
		var at := Vector2(6 + t * 18, -10 - t * 34)
		_text(at, "z", 10 + i * 3, Color(1, 1, 1, 1.0 - t), 30)


func _nametag() -> void:
	var font := ThemeDB.fallback_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
	draw_rect(Rect2(-width * 0.5, -14, width, 18), Color(0.16, 0.12, 0.2, 0.85))
	_text(Vector2(0, 0), text, 12, CREAM, width)


func _helper() -> void:
	# scripts/helper.gd's teal helper, without its status caption.
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 12, Color(0.22, 0.27, 0.2, 0.22))
	draw_set_transform(Vector2(0, -lift), 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -24), Vector2(7, -24), Vector2(12, -2), Vector2(-12, -2)]), Color("528c83"))
	draw_line(Vector2(-7, -21), Vector2(7, -5), Color("dac5ee"), 3)
	draw_circle(Vector2(0, -29), 11, Color("69a699"))
	draw_circle(Vector2(0, -28), 7, Color("314c4e"))
	draw_circle(Vector2(-2, -28), 1, Color("fff1d0"))
	draw_circle(Vector2(3, -28), 1, Color("fff1d0"))
