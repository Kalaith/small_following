extends RefCounted
## Draws the catalog's edges and node sigils at the screen's current pan and zoom.

const Style = preload("res://scripts/ritual_style.gd")
const Layout = preload("res://scripts/ritual_layout.gd")

var screen: Control


func _init(owner_screen: Control) -> void:
	screen = owner_screen


func _point(world: Vector2) -> Vector2:
	return screen.graph_point(world)


func draw_edges(canvas: Control) -> void:
	var path: Dictionary = screen.get_focus_path()
	for edge in screen.get_visible_edges():
		# Authored bends keep real requirements from implying links through other nodes.
		var route: PackedVector2Array = Layout.edge_path(edge.from, edge.to, screen.node_positions)
		for index in range(route.size()):
			route[index] = _point(route[index])
		if route.size() < 2:
			continue
		var radius: float = screen.node_radius()
		route[0] += route[0].direction_to(route[1]) * (radius + 3.0)
		var last: int = route.size() - 1
		var direction: Vector2 = route[last - 1].direction_to(route[last])
		route[last] -= direction * (radius + 3.0)
		var color := Color(Style.LILAC if edge.relevant else Style.VIOLET, float(edge.alpha))
		if edge.cross_branch:
			# A dashed cross-branch link differs from the permanent branch spine.
			for index in range(last):
				canvas.draw_dashed_line(route[index], route[index + 1], color, 1.5, 7.0, true)
		else:
			canvas.draw_polyline(route, color, 2.2 if edge.relevant else 1.5, true)
		if edge.relevant and route[last - 1].distance_to(route[last]) > 20.0:
			var tip: Vector2 = route[last] - direction * 6.0
			canvas.draw_polyline(PackedVector2Array([tip - direction.rotated(-0.55) * 7.0, tip, tip - direction.rotated(0.55) * 7.0]), color, 1.2, true)
	for item in screen.catalog:
		if item.get("requires", []).is_empty():
			var at: Vector2 = screen.node_positions[str(item.id)]
			var alpha: float = 0.46 if path.has(str(item.id)) or path.is_empty() else 0.14
			canvas.draw_line(_point(at.normalized() * (Style.CORE_ORNAMENT_RADIUS + 6.0)), _point(at - at.normalized() * Style.NODE_RADIUS), Color(Style.VIOLET, alpha), 1.0, true)


func draw_node(canvas: Control, item: Dictionary) -> void:
	var id: String = str(item.get("id", ""))
	if not screen.node_positions.has(id):
		return
	var point: Vector2 = _point(screen.node_positions[id])
	var radius: float = screen.node_radius()
	var state: String = screen.state_of(id)
	var current_rank: int = screen.rank_of(id)
	var rank_limit: int = screen.max_rank_of(id)
	var complete: bool = state == "purchased"
	var selected: bool = id == screen.selected_id
	var hovered: bool = id == screen.hovered_id
	var color: Color = Style.LILAC if state == "affordable" or current_rank > 0 else Color("a18daf") if state == "unaffordable" else Color("706078")
	if selected or hovered:
		canvas.draw_arc(point, radius + 5.0, 0, TAU, 48, Style.WHITE if selected else Style.LILAC, 1.5, true)
		if selected:
			for index in range(4):
				var direction: Vector2 = Vector2.from_angle(PI * 0.25 + index * PI * 0.5)
				canvas.draw_line(point + direction * (radius + 8.0), point + direction * (radius + 11.0), Style.LILAC, 1.0, true)
	canvas.draw_circle(point, radius + 2.0, Style.INK)
	if state == "locked":
		var diamond := PackedVector2Array([point + Vector2(0, -radius), point + Vector2(radius, 0), point + Vector2(0, radius), point + Vector2(-radius, 0), point + Vector2(0, -radius)])
		canvas.draw_colored_polygon(diamond, Color("19121f"))
		canvas.draw_polyline(diamond, color, 1.2, true)
		# The bar and diamond survive at overview scale; details name missing ranks.
		canvas.draw_line(point + Vector2(-radius * 0.28, 0), point + Vector2(radius * 0.28, 0), color, 1.5, true)
	else:
		var fill: Color = Color("644582") if complete else Color("39214e") if state == "affordable" else Color("19121f")
		canvas.draw_circle(point, radius, fill)
		canvas.draw_arc(point, radius, 0, TAU, 48, color, 2.0 if state == "affordable" or complete else 1.1, true)
		if radius >= 10.0:
			_draw_glyph(canvas, point, str(item.get("branch", "")), color)
		if current_rank > 0 and not complete:
			canvas.draw_arc(point, maxf(2, radius - 4), -PI * 0.5, -PI * 0.5 + TAU * current_rank / float(rank_limit), 40, Style.WHITE, 2.2, true)
		if complete:
			var check_at: Vector2 = point + Vector2(radius * 0.70, -radius * 0.68) if radius >= 10 else point
			canvas.draw_circle(check_at, 5.0 if radius >= 10 else 3.0, Style.INK)
			canvas.draw_polyline(PackedVector2Array([check_at + Vector2(-3, 0), check_at + Vector2(-0.5, 2.2), check_at + Vector2(3.5, -2.5)]), Style.WHITE, 1.5, true)
		elif state == "affordable":
			var plus_at: Vector2 = point + Vector2(0, -radius - 2) if radius >= 10 else point
			canvas.draw_circle(plus_at, 4.0, Style.INK)
			canvas.draw_line(plus_at + Vector2(-3, 0), plus_at + Vector2(3, 0), Style.WHITE, 1.4, true)
			canvas.draw_line(plus_at + Vector2(0, -3), plus_at + Vector2(0, 3), Style.WHITE, 1.4, true)
	if screen.zoom >= 0.65 and rank_limit > 1:
		for index in range(rank_limit):
			var pip_at: Vector2 = point + Vector2((index - (rank_limit - 1) * 0.5) * 8.0, radius * 0.64)
			if index < current_rank:
				canvas.draw_circle(pip_at, 2.0, Style.WHITE)
			else:
				canvas.draw_arc(pip_at, 2.0, 0, TAU, 12, Style.MUTED, 1.0, true)


func _draw_glyph(canvas: Control, at: Vector2, branch: String, color: Color) -> void:
	var scale: float = screen.zoom
	match branch:
		"talk", "market_talk":
			canvas.draw_line(at + Vector2(-5, -10) * scale, at + Vector2(-5, 10) * scale, color, 1.7, true)
			canvas.draw_arc(at + Vector2(-6, 0) * scale, 9 * scale, -PI * 0.42, PI * 0.42, 18, color, 1.3, true)
			canvas.draw_arc(at + Vector2(-6, 0) * scale, 15 * scale, -PI * 0.35, PI * 0.35, 18, color, 1.3, true)
		"persuade", "market_persuade":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(0, -12) * scale, at + Vector2(9, 0) * scale, at + Vector2(0, 12) * scale, at + Vector2(-9, 0) * scale, at + Vector2(0, -12) * scale]), color, 1.6, true)
			canvas.draw_line(at + Vector2(0, -6) * scale, at + Vector2(0, 6) * scale, color, 1.2, true)
		"helper":
			canvas.draw_circle(at + Vector2(0, -7) * scale, 4.0 * scale, color)
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-8, 10) * scale, at + Vector2(0, -1) * scale, at + Vector2(8, 10) * scale]), color, 1.6, true)
		"gather":
			for x in [-9, 0, 9]:
				canvas.draw_circle(at + Vector2(x, -5) * scale, 3.0 * scale, color)
				canvas.draw_line(at + Vector2(x, 0) * scale, at + Vector2(x, 8) * scale, color, 2.0, true)
		"merchant":
			canvas.draw_arc(at, 10 * scale, 0, TAU, 20, color, 1.6, true)
			canvas.draw_line(at + Vector2(0, -7) * scale, at + Vector2(0, 7) * scale, color, 2, true)
		"trial":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-9, -9) * scale, at + Vector2(9, -9) * scale, at + Vector2(8, 5) * scale, at + Vector2(0, 12) * scale, at + Vector2(-8, 5) * scale, at + Vector2(-9, -9) * scale]), color, 1.6, true)
		"faith":
			canvas.draw_line(at + Vector2(0, -12) * scale, at + Vector2(0, 12) * scale, color, 2, true)
			canvas.draw_line(at + Vector2(-8, -4) * scale, at + Vector2(8, -4) * scale, color, 2, true)
			canvas.draw_arc(at, 15 * scale, 0, TAU, 24, color, 1, true)
		"market_guild":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-12, 1) * scale, at + Vector2(-10, -9) * scale, at + Vector2(10, -9) * scale, at + Vector2(12, 1) * scale, at + Vector2(-12, 1) * scale]), color, 1.5, true)
			canvas.draw_line(at + Vector2(-8, 1) * scale, at + Vector2(-8, 10) * scale, color, 1.5, true)
			canvas.draw_line(at + Vector2(8, 1) * scale, at + Vector2(8, 10) * scale, color, 1.5, true)
			canvas.draw_line(at + Vector2(-10, 10) * scale, at + Vector2(10, 10) * scale, color, 1.5, true)
		"market_patron":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-11, -7) * scale, at + Vector2(-8, 8) * scale, at + Vector2(8, 8) * scale, at + Vector2(11, -7) * scale, at + Vector2(4, -2) * scale, at + Vector2(0, -11) * scale, at + Vector2(-4, -2) * scale, at + Vector2(-11, -7) * scale]), color, 1.5, true)
		"run", "market_run":
			for x in [-5, 4]:
				canvas.draw_polyline(PackedVector2Array([at + Vector2(x - 4, -10) * scale, at + Vector2(x + 3, 0) * scale, at + Vector2(x - 4, 10) * scale]), color, 1.7, true)
		_:
			canvas.draw_circle(at, 5.0 * scale, color)
