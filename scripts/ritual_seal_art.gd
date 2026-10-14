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
	if screen.uni_circle:
		draw_uni_seal(canvas)
		return
	if screen.fair_circle:
		draw_fair_seal(canvas)
		return
	if screen.market_circle:
		draw_market_seal(canvas)
		for seal in Layout.satellite_seals(screen.catalog):
			_draw_satellite(canvas, seal)
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


func draw_fair_seal(canvas: Control) -> void:
	# A striped tent canopy seen from above: scalloped rim, faint alternating
	# wedges and a carousel crown. Ornament only; the nodes carry every link.
	var center: Vector2 = _point(Vector2.ZERO)
	var outer: float = screen.max_radius + 40.0
	arc(canvas, center, outer, Color(Style.GOLD, 0.22), 1)
	arc(canvas, center, outer + 13.0, Color(Style.LILAC, 0.16), 1)
	_draw_runes(canvas, outer + 6.0)
	for index in range(24):
		var start: float = index * TAU / 24.0
		var scallop_at: Vector2 = Vector2.from_angle(start + TAU / 48.0) * (outer - 9.0)
		canvas.draw_arc(_point(scallop_at), 13.0 * screen.zoom, start + PI * 0.5 - 0.2, start + PI * 1.5 + 0.2, 12, Color(Style.VIOLET, 0.16), 1.0, true)
		if index % 2 == 0:
			var wedge := PackedVector2Array([center, _point(Vector2.from_angle(start) * (outer - 22.0)), _point(Vector2.from_angle(start + TAU / 24.0) * (outer - 22.0))])
			canvas.draw_colored_polygon(wedge, Color(Style.VIOLET, 0.035))
	for radius in [outer * 0.45, outer * 0.72]:
		arc(canvas, center, radius, Color(Style.VIOLET, 0.09), 1.0)


func draw_uni_seal(canvas: Control) -> void:
	# An astrolabe: a degree-ticked limb, an hour ring of numerals and a pierced
	# rete of star pointers. Ornament only; the nodes carry every link.
	var center: Vector2 = _point(Vector2.ZERO)
	var outer: float = screen.max_radius + 40.0
	arc(canvas, center, outer, Color(Style.GOLD, 0.24), 1)
	arc(canvas, center, outer + 12.0, Color(Style.LILAC, 0.16), 1)
	_draw_runes(canvas, outer + 6.0)
	for index in range(120):
		var radial := Vector2.from_angle(index * TAU / 120.0)
		var major: bool = index % 10 == 0
		canvas.draw_line(_point(radial * (outer - 3.0)), _point(radial * (outer - (14.0 if major else 7.0))), Color(Style.GOLD, 0.30 if major else 0.13), 1.0, true)
	# The rete: an off-centre ecliptic ring and a few star pointers.
	canvas.draw_arc(_point(Vector2(0, -outer * 0.16)), outer * 0.62 * screen.zoom, 0, TAU, 120, Color(Style.VIOLET, 0.12), 1.0, true)
	for index in range(7):
		var angle: float = -PI * 0.5 + index * TAU / 7.0 + 0.3
		var tip: Vector2 = Vector2.from_angle(angle) * outer * 0.84
		var side: Vector2 = Vector2.from_angle(angle).orthogonal() * 9.0
		canvas.draw_colored_polygon(PackedVector2Array([_point(tip), _point(tip * 0.9 + side), _point(tip * 0.9 - side)]), Color(Style.VIOLET, 0.10))
	for radius in [outer * 0.45, outer * 0.72]:
		arc(canvas, center, radius, Color(Style.VIOLET, 0.08), 1.0)


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
	if screen.uni_circle:
		# Quillmoor's centre is an open book under a single star.
		var ink: Color = Style.GOLD if complete else Color(Style.GOLD, 0.5)
		var page := PackedVector2Array([center + Vector2(0, radius * 0.40), center + Vector2(-radius * 0.58, radius * 0.24), center + Vector2(-radius * 0.58, -radius * 0.18), center + Vector2(0, -radius * 0.02), center + Vector2(radius * 0.58, -radius * 0.18), center + Vector2(radius * 0.58, radius * 0.24), center + Vector2(0, radius * 0.40), center + Vector2(0, -radius * 0.02)])
		canvas.draw_polyline(page, ink, 1.4, true)
		for line in range(3):
			var y: float = radius * (0.02 + line * 0.1)
			canvas.draw_line(center + Vector2(-radius * 0.48, y), center + Vector2(-radius * 0.1, y + radius * 0.08), Color(ink, ink.a * 0.7), 1.0, true)
			canvas.draw_line(center + Vector2(radius * 0.1, y + radius * 0.08), center + Vector2(radius * 0.48, y), Color(ink, ink.a * 0.7), 1.0, true)
		var star := PackedVector2Array()
		for index in range(11):
			var reach: float = radius * (0.2 if index % 2 == 0 else 0.08)
			star.append(center + Vector2(0, -radius * 0.48) + Vector2.from_angle(-PI * 0.5 + index * PI / 5.0) * reach)
		canvas.draw_polyline(star, ink, 1.2, true)
		return
	if screen.fair_circle:
		# The fair's centre is a carousel crown: a striped cone over a ring of lights.
		var tip: Vector2 = center + Vector2(0, -radius * 0.62)
		for index in range(6):
			var base_a: Vector2 = center + Vector2(-radius * 0.6 + index * radius * 0.2, radius * 0.18)
			var base_b: Vector2 = base_a + Vector2(radius * 0.2, 0)
			if index % 2 == 0:
				canvas.draw_colored_polygon(PackedVector2Array([tip, base_a, base_b]), Style.GOLD if complete else Color(Style.GOLD, 0.4))
		canvas.draw_polyline(PackedVector2Array([center + Vector2(-radius * 0.6, radius * 0.18), tip, center + Vector2(radius * 0.6, radius * 0.18)]), Style.GOLD if complete else Color(Style.GOLD, 0.5), 1.2, true)
		for index in range(7):
			canvas.draw_circle(center + Vector2(-radius * 0.54 + index * radius * 0.18, radius * 0.36), maxf(1.2, radius * 0.05), Style.GOLD if complete else Color(Style.GOLD, 0.45))
		return
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
