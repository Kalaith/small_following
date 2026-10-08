extends RefCounted
## Procedural ornament for the ritual circle: seals, rune rings and the central medallion.
## Everything here is decoration; the catalog's edges and nodes are drawn by ritual_node_art.gd.

const Style = preload("res://scripts/ritual_style.gd")
const Layout = preload("res://scripts/ritual_layout.gd")

var screen: Control


func _init(owner_screen: Control) -> void:
	screen = owner_screen


func _point(world: Vector2) -> Vector2:
	return screen.graph_point(world)


func arc(canvas: Control, center: Vector2, radius: float, color: Color, width: float) -> void:
	canvas.draw_arc(center, radius * screen.zoom, 0.0, TAU, 180, color, width, true)


func draw_backdrop(canvas: Control) -> void:
	if screen.market_circle:
		draw_market_seal(canvas)
		return
	# These bands and satellites are ornament, never extra upgrade connections.
	# Their contrast stays below the solid/dashed catalog edges drawn afterward.
	var center: Vector2 = _point(Vector2.ZERO)
	var outer: float = screen.max_radius + 31.0
	arc(canvas, center, outer, Color(Style.LILAC, 0.32), 1.0)
	arc(canvas, center, outer - 12.0, Color(Style.VIOLET, 0.20), 1.0)
	arc(canvas, center, outer - 27.0, Color(Style.VIOLET, 0.15), 1.0)
	_draw_runes(canvas, outer - 19.0)
	for index in range(96):
		var angle: float = TAU * index / 96.0
		var radial: Vector2 = Vector2.from_angle(angle)
		var major: bool = index % 8 == 0
		canvas.draw_line(_point(radial * (outer + 3.0)), _point(radial * (outer + (12.0 if major else 7.0))), Color(Style.LILAC, 0.31 if major else 0.14), 1.0, true)
	# Broken inner bands leave deliberate breathing room around the constellations.
	for index in range(3):
		var radius: float = outer * [0.40, 0.62, 0.80][index]
		var phase: float = [-0.20, 0.12, -0.08][index]
		for segment in range(4):
			var start: float = phase + segment * PI * 0.5
			canvas.draw_arc(center, radius * screen.zoom, start, start + PI * 0.32, 45, Color(Style.VIOLET, 0.10), 1.0, true)
			canvas.draw_arc(center, (radius + 6.0) * screen.zoom, start + 0.07, start + PI * 0.26, 40, Color(Style.VIOLET, 0.055), 1.0, true)
	for seal in Layout.satellite_seals(screen.catalog):
		_draw_satellite(canvas, seal)


func draw_market_seal(canvas: Control) -> void:
	# Five woven petals echo market awnings and coins. Real equal-weight branches
	# sit over this quiet ornament and remain the only actionable connections.
	# Kept deliberately sparse: one faint outline per petal, so the real edges
	# and the nodes in the gaps between petals read clearly over it.
	var center: Vector2 = _point(Vector2.ZERO)
	arc(canvas, center, 425.0, Color(Style.GOLD, 0.20), 1)
	arc(canvas, center, 439.0, Color(Style.LILAC, 0.16), 1)
	_draw_runes(canvas, 432.0)
	for index in range(5):
		var radial := Vector2.from_angle(-PI / 2 + index * TAU / 5)
		var tangent := radial.orthogonal()
		var petal := PackedVector2Array()
		for point_index in range(81):
			var phase: float = point_index * TAU / 80.0
			petal.append(_point(radial * (238.0 + cos(phase) * 153.0) + tangent * sin(phase) * 94.0))
		canvas.draw_polyline(petal, Color(Style.VIOLET, 0.13), 1.0, true)
	for index in range(60):
		var radial := Vector2.from_angle(index * TAU / 60)
		canvas.draw_line(_point(radial * 444), _point(radial * (455 if index % 6 == 0 else 449)), Color(Style.GOLD, 0.30 if index % 6 == 0 else 0.15), 1, true)


func _draw_satellite(canvas: Control, seal: Dictionary) -> void:
	var origin: Vector2 = seal.center
	var center: Vector2 = _point(origin)
	var radius: float = float(seal.radius)
	var motif: String = str(seal.get("motif", "rings"))
	arc(canvas, center, radius, Color(Style.VIOLET, 0.24), 1.0)
	arc(canvas, center, radius - 8.0, Color(Style.LILAC, 0.10), 1.0)
	if motif == "spiral":
		var spiral := PackedVector2Array()
		for index in range(81):
			var fraction: float = index / 80.0
			var angle: float = -0.5 + fraction * TAU * 1.45
			spiral.append(_point(origin + Vector2.from_angle(angle) * lerpf(radius * 0.16, radius * 0.84, fraction)))
		canvas.draw_polyline(spiral, Color(Style.VIOLET, 0.11), 1.0, true)
	elif motif == "petals":
		for index in range(4):
			var petal: Vector2 = origin + Vector2.from_angle(index * PI * 0.5) * radius * 0.20
			arc(canvas, _point(petal), radius * 0.49, Color(Style.VIOLET, 0.15), 1.0)
	else:
		arc(canvas, center, radius * 0.57, Color(Style.VIOLET, 0.11), 1.0)
		var diamond := PackedVector2Array()
		for index in range(5):
			diamond.append(_point(origin + Vector2.from_angle(PI * 0.25 + index * PI * 0.5) * radius * 0.77))
		canvas.draw_polyline(diamond, Color(Style.VIOLET, 0.12), 1.0, true)
	for index in range(8):
		var radial: Vector2 = Vector2.from_angle(index * PI * 0.25)
		canvas.draw_line(_point(origin + radial * (radius + 2.0)), _point(origin + radial * (radius + 6.0)), Color(Style.LILAC, 0.20), 1.0, true)


func _draw_runes(canvas: Control, radius: float) -> void:
	# A repeated invented inscription alphabet, deliberately regular rather than noise.
	var count: int = 32
	for index in range(count):
		var angle: float = TAU * index / float(count)
		var radial: Vector2 = Vector2.from_angle(angle)
		var tangent: Vector2 = radial.orthogonal()
		var at: Vector2 = radial * radius
		var color := Color(Style.LILAC, 0.25)
		canvas.draw_line(_point(at - radial * 4.0), _point(at + radial * 4.0), color, 1.0, true)
		if index % 3 == 0:
			canvas.draw_line(_point(at + radial * 2.5), _point(at + tangent * 3.0), color, 1.0, true)
		elif index % 3 == 1:
			canvas.draw_line(_point(at + tangent * 2.2), _point(at - tangent * 2.2), color, 1.0, true)


func draw_core(canvas: Control) -> void:
	var center: Vector2 = _point(Vector2.ZERO)
	var complete: bool = screen.is_circle_complete()
	var radius: float = maxf(Style.CORE_RADIUS * screen.zoom, 18.0) if complete else Style.CORE_RADIUS * screen.zoom
	# The medallion masks decorative lines; bright illumination is completion-only.
	canvas.draw_circle(center, maxf(Style.CORE_ORNAMENT_RADIUS * screen.zoom, radius + 4.0), Style.INK)
	if complete:
		for index in range(5, 0, -1):
			canvas.draw_circle(center, radius + index * 3.0, Color(Style.VIOLET, 0.045))
	canvas.draw_circle(center, radius, Color("593b7c") if complete else Color("1d1429"))
	var edge: Color = Style.WHITE if complete and screen.core_hovered else Style.LILAC if complete else Color(Style.LILAC, 0.47)
	canvas.draw_arc(center, radius, 0.0, TAU, 96, edge, 1.8 if complete else 1.0, true)
	canvas.draw_arc(center, radius * 0.82, 0.0, TAU, 96, Color(Style.LILAC, 0.60 if complete else 0.21), 1.0, true)
	arc(canvas, center, Style.CORE_ORNAMENT_RADIUS, Color(Style.LILAC, 0.78 if complete else 0.22), 1.0)
	arc(canvas, center, Style.CORE_ORNAMENT_RADIUS - 5.0, Color(Style.VIOLET, 0.50 if complete else 0.15), 1.0)
	for index in range(20):
		var radial: Vector2 = Vector2.from_angle(-PI * 0.5 + index * TAU / 20.0)
		canvas.draw_line(_point(radial * (Style.CORE_RADIUS + 4.0)), _point(radial * (Style.CORE_ORNAMENT_RADIUS - (6.0 if index % 4 == 0 else 10.0))), Color(Style.LILAC, 0.80 if complete else 0.30), 1.0, true)
	if screen.market_circle:
		# Bellmarket's centre is a five-petalled coin, distinct from the village star.
		for index in range(5):
			var petal_at: Vector2 = center + Vector2.from_angle(-PI / 2 + index * TAU / 5) * radius * 0.24
			canvas.draw_arc(petal_at, radius * 0.32, 0, TAU, 32, Style.GOLD if complete else Color(Style.GOLD, 0.50), 1.2, true)
		canvas.draw_circle(center, radius * 0.12, Style.GOLD if complete else Color(Style.GOLD, 0.45))
		return
	# A crisp pentagram and five small rim marks make the central source legible.
	var star := PackedVector2Array()
	for index in range(6):
		var angle: float = -PI * 0.5 + TAU * ((index * 2) % 5) / 5.0
		star.append(center + Vector2.from_angle(angle) * radius * 0.66)
	canvas.draw_polyline(star, Style.WHITE if complete else Color(Style.LILAC, 0.48), 1.7 if complete else 1.1, true)
	for index in range(5):
		var radial: Vector2 = Vector2.from_angle(-PI * 0.5 + index * TAU / 5.0)
		canvas.draw_circle(center + radial * radius * 0.90, 1.8 if complete else 1.2, edge)
