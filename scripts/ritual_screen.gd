extends Control
## A zoomable, data-driven constellation. The village simulation remains unpaused.
## Geometry is procedural placeholder artwork, informed by the supplied reference descriptions.

signal purchase_requested(id: String, expected_rank: int)
signal next_round_requested
signal return_to_village_requested

const INK := Color("110d1c")
const PANEL := Color("191124")
const LINE := Color("66468d")
const LILAC := Color("d7b9ff")
const VIOLET := Color("a873eb")
const MUTED := Color("9786af")
const WHITE := Color("f1e5ff")
const RING_STEP: float = 86.0
const FIRST_RING: float = 112.0
const NODE_RADIUS: float = 26.0
const MIN_ZOOM: float = 0.025
const MAX_ZOOM: float = 2.4

class GraphCanvas extends Control:
	var screen: Control
	func _draw() -> void:
		if is_instance_valid(screen):
			screen._draw_graph(self)
	func _gui_input(event: InputEvent) -> void:
		if is_instance_valid(screen):
			screen._graph_input(event)

var selected_id: String = ""
var node_positions: Dictionary = {}
var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var graph: GraphCanvas
var purchase_button: Button
var next_button: Button
var village_button: Button
var recenter_button: Button
var _catalog: Array = []
var _by_id: Dictionary = {}
var _progression: RefCounted
var _max_radius: float = FIRST_RING
var _round_recruits: int = 0
var _dragging: bool = false
var _drag_button: int = 0
var _hovered_id: String = ""
var _font: Font
var _title_label: Label
var _subtitle_label: Label
var _coins_label: Label
var _branch_label: Label
var _node_title: Label
var _rank_label: Label
var _effect_label: Label
var _node_description: Label
var _status_label: Label
var _hint_label: Label
var _legend_label: Label
var _error_label: Label
var _detail_x: float = 0.0
var _built: bool = false
var _displayed_rank: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_build_controls()
	resized.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()
	_built = true
	update_state()


func configure(catalog: Array, progression: RefCounted) -> void:
	_catalog = catalog
	_progression = progression
	_by_id.clear()
	node_positions.clear()
	_max_radius = FIRST_RING
	for value in _catalog:
		var item: Dictionary = value
		var id: String = str(item.get("id", ""))
		if id.is_empty():
			continue
		_by_id[id] = item
		var ring: int = maxi(1, int(item.get("ring", 1)))
		var radius: float = FIRST_RING + (ring - 1) * RING_STEP
		var angle: float = deg_to_rad(float(item.get("angle_degrees", -90.0)))
		node_positions[id] = Vector2.from_angle(angle) * radius
		_max_radius = maxf(radius, _max_radius)
	if not _by_id.has(selected_id):
		selected_id = str(_catalog[0].get("id", "")) if not _catalog.is_empty() else ""
	if _built:
		reset_view()
		update_state()


func update_state(round_recruits: int = 0) -> void:
	_round_recruits = round_recruits
	if not _built:
		return
	_subtitle_label.text = "ROUND COMPLETE  /  %d NEW FOLLOWERS" % _round_recruits
	var coins: int = int(_progression.get("coins")) if is_instance_valid(_progression) else 0
	_coins_label.text = "%d  donations" % coins
	var save_error: String = str(_progression.get("last_error")) if is_instance_valid(_progression) else ""
	_error_label.text = "SAVE NOTICE: " + save_error if not save_error.is_empty() else ""
	_error_label.tooltip_text = save_error
	var item: Dictionary = _by_id.get(selected_id, {})
	var state: String = _state(selected_id)
	_displayed_rank = _rank(selected_id)
	var rank_limit: int = _max_rank(selected_id)
	var cost: int = _next_cost(selected_id)
	var branch: String = str(item.get("branch", ""))
	var branch_name: String = {"talk": "THE VOICE", "persuade": "THE CONVICTION", "run": "THE PILGRIM", "gather": "THE VILLAGE"}.get(branch, "THE CIRCLE")
	_branch_label.text = "%s  /  RING %s" % [branch_name, _roman(int(item.get("ring", 1)))]
	_node_title.text = str(item.get("title", "Choose an inscription"))
	_rank_label.text = "RANK %d / %d  %s" % [_displayed_rank, rank_limit, "- COMPLETE" if state == "purchased" else ""]
	_effect_label.text = _effect_text(selected_id, branch, state == "purchased")
	_node_description.text = str(item.get("description", "Select a sigil in the circle to study its effect."))
	var requirements: Array = item.get("requires", [])
	match state:
		"purchased":
			_status_label.text = "FULLY INSCRIBED\nEvery rank is yours. No further cost."
			purchase_button.text = "Maximum rank reached"
		"locked":
			var required_names: PackedStringArray = []
			for prerequisite in requirements:
				if _rank(str(prerequisite)) < 1:
					var required: Dictionary = _by_id.get(str(prerequisite), {})
					required_names.append(str(required.get("title", prerequisite)) + " rank 1")
			_status_label.text = "SEALED\nRequires " + ", ".join(required_names) + "."
			purchase_button.text = "Rank %d  /  %d donations" % [_displayed_rank + 1, cost]
		"unaffordable":
			_status_label.text = "AWAITING OFFERING\n%d more donations needed." % maxi(0, cost - coins)
			purchase_button.text = "Inscribe rank %d  /  %d donations" % [_displayed_rank + 1, cost]
		"affordable":
			_status_label.text = "READY FOR RANK %d\nA permanent gift for every round." % (_displayed_rank + 1)
			purchase_button.text = "Inscribe rank %d  /  %d donations" % [_displayed_rank + 1, cost]
		_:
			_status_label.text = "Select a sigil to begin."
			purchase_button.text = "Choose an inscription"
	purchase_button.disabled = state != "affordable"
	_status_label.add_theme_color_override("font_color", LILAC if state == "affordable" or state == "purchased" else MUTED)
	graph.queue_redraw()
	queue_redraw()


func select_node(id: String) -> void:
	if not _by_id.has(id):
		return
	selected_id = id
	update_state(_round_recruits)


func get_selected_rank() -> int:
	# Carry the rank the player saw; duplicate stale requests must not buy another.
	return _displayed_rank


func nodes_position(id: String) -> Vector2:
	return node_positions.get(id, Vector2.ZERO)


func world_to_screen(point: Vector2) -> Vector2:
	return graph.global_position + graph.size * 0.5 + pan + point * zoom


func screen_to_world(point: Vector2) -> Vector2:
	return (point - graph.global_position - graph.size * 0.5 - pan) / zoom


func hit_test(screen_point: Vector2) -> String:
	if not graph.get_global_rect().has_point(screen_point):
		return ""
	var world_point: Vector2 = screen_to_world(screen_point)
	var closest: String = ""
	var distance: float = NODE_RADIUS + 6.0
	for id in node_positions:
		var candidate: Vector2 = node_positions[id]
		var candidate_distance: float = candidate.distance_to(world_point)
		if candidate_distance < distance:
			closest = str(id)
			distance = candidate_distance
	return closest


func zoom_at(screen_point: Vector2, factor: float) -> void:
	var world_anchor: Vector2 = screen_to_world(screen_point)
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	pan = screen_point - graph.global_position - graph.size * 0.5 - world_anchor * zoom
	graph.queue_redraw()


func pan_by(delta: Vector2) -> void:
	pan += delta
	graph.queue_redraw()


func reset_view() -> void:
	if not is_instance_valid(graph):
		return
	zoom = clampf(minf(graph.size.x, graph.size.y) / ((_max_radius + 54.0) * 2.0), MIN_ZOOM, 1.0)
	pan = Vector2.ZERO
	graph.queue_redraw()


func focus_node(id: String) -> void:
	if not node_positions.has(id):
		return
	select_node(id)
	zoom = maxf(0.8, zoom)
	pan = -Vector2(node_positions[id]) * zoom
	graph.queue_redraw()


func _state(id: String) -> String:
	if is_instance_valid(_progression) and _progression.has_method("status"):
		return str(_progression.call("status", id))
	return "unknown"


func _rank(id: String) -> int:
	if is_instance_valid(_progression) and _progression.has_method("rank"):
		return int(_progression.call("rank", id))
	return 0


func _max_rank(id: String) -> int:
	if is_instance_valid(_progression) and _progression.has_method("max_rank"):
		return int(_progression.call("max_rank", id))
	return 1


func _next_cost(id: String) -> int:
	if is_instance_valid(_progression) and _progression.has_method("next_cost"):
		return int(_progression.call("next_cost", id))
	return 0


func _effect_text(id: String, branch: String, complete: bool) -> String:
	if not is_instance_valid(_progression) or not _progression.has_method("effect_preview"):
		return ""
	var preview: Dictionary = _progression.call("effect_preview", id)
	var current: Dictionary = preview.get("current", {})
	var next: Dictionary = preview.get("next", {})
	var stat_key: String = {"talk": "speech_frequency", "persuade": "conviction", "run": "run_multiplier", "gather": "gatherings"}.get(branch, "")
	var heading: String = {"talk": "TALKING FREQUENCY", "persuade": "CONVICTION PER PHRASE", "run": "RUNNING SPEED", "gather": "VILLAGE GATHERINGS"}.get(branch, "")
	var units: String = {"talk": "phrases/s", "persuade": "conviction", "run": "x base", "gather": "groups of five"}.get(branch, "")
	if stat_key.is_empty() or not current.has(stat_key):
		return ""
	var current_value: float = float(current[stat_key])
	if branch == "gather":
		if complete or not next.has(stat_key):
			return "%s\n%d groups / %d listeners" % [heading, int(current_value), int(current_value) * 5]
		return "%s\n%d → %d groups of five" % [heading, int(current_value), int(next[stat_key])]
	if complete or not next.has(stat_key):
		return "%s\n%.2f %s" % [heading, current_value, units]
	return "%s\n%.2f → %.2f %s" % [heading, current_value, float(next[stat_key]), units]


func _build_controls() -> void:
	graph = GraphCanvas.new()
	graph.name = "RitualGraph"
	graph.screen = self
	graph.clip_contents = true
	graph.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(graph)
	_title_label = _label("The circle grows.", 34, WHITE)
	_subtitle_label = _label("ROUND COMPLETE", 12, MUTED)
	_coins_label = _label("0  donations", 23, LILAC)
	_branch_label = _label("THE VOICE  /  RING I", 12, VIOLET)
	_node_title = _label("Choose an inscription", 26, WHITE)
	_node_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rank_label = _label("RANK 0 / 1", 13, VIOLET)
	_effect_label = _label("", 18, WHITE)
	_node_description = _label("", 15, LILAC)
	_node_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label = _label("", 14, MUTED)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label = _label("Tab: village  /  Enter: next round\nWASD still moves your cultist.", 12, MUTED)
	_legend_label = _label("Drag to explore  /  Scroll to zoom     |     Open pips: unbought    Filled pips: ranks", 12, MUTED)
	_error_label = _label("", 11, LILAC)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.max_lines_visible = 3
	_error_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_error_label.mouse_filter = Control.MOUSE_FILTER_PASS
	purchase_button = _button("Inscribe", true)
	purchase_button.pressed.connect(_purchase_selected)
	next_button = _button("Begin next round", true)
	next_button.pressed.connect(func() -> void: next_round_requested.emit())
	village_button = _button("Return to the village", false)
	village_button.pressed.connect(func() -> void: return_to_village_requested.emit())
	recenter_button = _button("Recenter", false)
	recenter_button.pressed.connect(reset_view)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_disabled_color", MUTED)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("42265e") if primary else Color("20162f")
		style.border_color = Color("8b5fba") if primary else Color("49305f")
		if state == "hover":
			style.bg_color = Color("634184")
			style.border_color = LILAC
		elif state == "pressed":
			style.bg_color = Color("8a59b9")
		elif state == "disabled":
			style.bg_color = Color("231a2e")
			style.border_color = Color("3a2b4b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state, style)
	add_child(button)
	return button


func _layout() -> void:
	if not is_instance_valid(graph):
		return
	var margin: float = 40.0
	var detail_width: float = clampf(size.x * 0.245, 255.0, 330.0)
	_detail_x = size.x - detail_width - margin
	graph.position = Vector2(24, 118)
	graph.size = Vector2(maxf(280.0, _detail_x - 51.0), maxf(280.0, size.y - 197.0))
	_title_label.position = Vector2(margin, 43)
	_subtitle_label.position = Vector2(margin + 2.0, 23)
	_coins_label.position = Vector2(_detail_x, 49)
	_branch_label.position = Vector2(_detail_x, 153)
	_node_title.position = Vector2(_detail_x, 182)
	_node_title.size = Vector2(detail_width, 72)
	_rank_label.position = Vector2(_detail_x, 260)
	_rank_label.size = Vector2(detail_width, 23)
	_effect_label.position = Vector2(_detail_x, 295)
	_effect_label.size = Vector2(detail_width, 56)
	_node_description.position = Vector2(_detail_x, 362)
	_node_description.size = Vector2(detail_width, 64)
	_status_label.position = Vector2(_detail_x, 440)
	_status_label.size = Vector2(detail_width, 60)
	purchase_button.position = Vector2(_detail_x, 510)
	purchase_button.size = Vector2(detail_width, 49)
	_error_label.position = Vector2(_detail_x, 566)
	_error_label.size = Vector2(detail_width, 46)
	next_button.position = Vector2(_detail_x, size.y - 183)
	next_button.size = Vector2(detail_width, 50)
	village_button.position = Vector2(_detail_x, size.y - 124)
	village_button.size = Vector2(detail_width, 39)
	_hint_label.position = Vector2(_detail_x, size.y - 65)
	_hint_label.size = Vector2(detail_width, 43)
	_legend_label.position = Vector2(margin, size.y - 53)
	_legend_label.size = Vector2(_detail_x - margin - 22, 28)
	recenter_button.position = Vector2(_detail_x - 118, 82)
	recenter_button.size = Vector2(91, 30)
	reset_view()
	queue_redraw()


func _purchase_selected() -> void:
	if _state(selected_id) == "affordable":
		purchase_requested.emit(selected_id, _displayed_rank)
		update_state(_round_recruits)


func _on_visibility_changed() -> void:
	_dragging = false
	_hovered_id = ""
	if visible and _built:
		update_state(_round_recruits)


func _graph_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		var screen_point: Vector2 = graph.global_position + mouse.position
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(screen_point, 1.13)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(screen_point, 1.0 / 1.13)
		elif mouse.button_index == MOUSE_BUTTON_LEFT or mouse.button_index == MOUSE_BUTTON_MIDDLE:
			if not mouse.pressed:
				if mouse.button_index == _drag_button:
					_dragging = false
			else:
				var id: String = hit_test(screen_point)
				if mouse.button_index == MOUSE_BUTTON_LEFT and not id.is_empty():
					select_node(id)
				else:
					_dragging = true
					_drag_button = mouse.button_index
		graph.accept_event()
	elif event is InputEventMouseMotion:
		var mouse: InputEventMouseMotion = event
		if _dragging:
			# Release outside the clipping rectangle cannot leave a stuck drag.
			var held: bool = (mouse.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE)) != 0
			if held:
				pan_by(mouse.relative)
			else:
				_dragging = false
		_hovered_id = hit_test(graph.global_position + mouse.position)
		graph.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not _hovered_id.is_empty() else Control.CURSOR_DRAG
		graph.queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	draw_rect(Rect2(Vector2(_detail_x - 24, 118), Vector2(size.x - _detail_x + 24, size.y - 118)), PANEL)
	draw_line(Vector2(40, 110), Vector2(size.x - 40, 110), Color("372344"), 1.0)
	draw_line(Vector2(_detail_x - 24, 135), Vector2(_detail_x - 24, size.y - 32), Color("483059"), 1.0)
	if is_instance_valid(_error_label) and _error_label.text.is_empty():
		draw_line(Vector2(_detail_x, 586), Vector2(size.x - 40, 586), Color("483059"), 1.0)
	# Small title ornament, deliberately separate from the interactive constellation.
	for offset in range(3):
		var x: float = _detail_x - 81.0 + offset * 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 49), Vector2(x + 3, 54), Vector2(x, 59), Vector2(x - 3, 54)]), VIOLET)


func _point(world: Vector2) -> Vector2:
	return graph.size * 0.5 + pan + world * zoom


func _draw_graph(canvas: Control) -> void:
	var center: Vector2 = _point(Vector2.ZERO)
	# Sparse violet dust anchors the seal to a dark, tactile field.
	for index in range(65):
		var at := Vector2(fmod(index * 157.37 + 27.0, canvas.size.x), fmod(index * 93.17 + 51.0, canvas.size.y))
		canvas.draw_circle(at, 0.65, Color(0.55, 0.39, 0.7, 0.18))
	var rings: Dictionary = {}
	for item in _catalog:
		var ring: int = int(item.get("ring", 1))
		if not rings.has(ring):
			rings[ring] = []
		rings[ring].append(str(item.get("id", "")))
	for key in rings:
		var radius: float = FIRST_RING + (int(key) - 1) * RING_STEP
		_arc(canvas, center, radius, Color(0.58, 0.37, 0.78, 0.36), 1.0)
		_arc(canvas, center, radius + 7.0, Color(0.47, 0.30, 0.64, 0.23), 1.0)
		var ids: Array = rings[key]
		# Every connecting polygon is anchored to real upgrade nodes.
		if ids.size() >= 3:
			for index in range(ids.size()):
				var a: Vector2 = node_positions.get(str(ids[index]), Vector2.ZERO)
				var b: Vector2 = node_positions.get(str(ids[(index + 1) % ids.size()]), Vector2.ZERO)
				canvas.draw_line(_point(a), _point(b), Color(0.56, 0.35, 0.75, 0.27), 1.0, true)
	var outer: float = _max_radius + 31.0
	_arc(canvas, center, outer, Color(0.70, 0.47, 0.89, 0.56), 1.2)
	_arc(canvas, center, outer + 14.0, Color(0.58, 0.35, 0.78, 0.37), 1.0)
	_draw_runes(canvas, outer + 7.0)
	# Paths between an inscription and its prerequisites are the upgrade branches.
	for value in _catalog:
		var item: Dictionary = value
		var id: String = str(item.get("id", ""))
		if not node_positions.has(id):
			continue
		var requirements: Array = item.get("requires", [])
		var to: Vector2 = node_positions[id]
		var has_rank: bool = _rank(id) > 0
		var path_color: Color = Color(0.71, 0.49, 0.91, 0.77) if has_rank else Color(0.54, 0.34, 0.73, 0.52)
		if requirements.is_empty():
			canvas.draw_line(_point(to.normalized() * 53.0), _point(to), path_color, 1.5, true)
		for required in requirements:
			if node_positions.has(str(required)):
				canvas.draw_line(_point(node_positions[str(required)]), _point(to), path_color, 2.0 if has_rank else 1.2, true)
	_draw_core(canvas)
	for value in _catalog:
		_draw_node(canvas, value)


func _arc(canvas: Control, center: Vector2, radius: float, color: Color, width: float) -> void:
	canvas.draw_arc(center, radius * zoom, 0.0, TAU, 180, color, width, true)


func _draw_runes(canvas: Control, radius: float) -> void:
	var count: int = mini(192, maxi(48, int(radius / 5.0)))
	for index in range(count):
		var angle: float = TAU * index / float(count)
		var radial: Vector2 = Vector2.from_angle(angle)
		var tangent: Vector2 = radial.orthogonal()
		var at: Vector2 = radial * radius
		var color := Color(0.70, 0.47, 0.9, 0.60 if index % 3 == 0 else 0.35)
		canvas.draw_line(_point(at - radial * 3.7), _point(at + radial * 3.7), color, 1.0, true)
		if index % 3 == 0:
			canvas.draw_line(_point(at + radial * 2.5), _point(at + tangent * 3.0), color, 1.0, true)
		elif index % 3 == 1:
			canvas.draw_line(_point(at + tangent * 2.2), _point(at - tangent * 2.2), color, 1.0, true)


func _draw_core(canvas: Control) -> void:
	var center: Vector2 = _point(Vector2.ZERO)
	canvas.draw_circle(center, 51.0 * zoom, Color("1e142c"))
	_arc(canvas, center, 48.0, LINE, 1.0)
	_arc(canvas, center, 42.0, Color(0.68, 0.43, 0.88, 0.45), 1.0)
	# Thorned, inverted star: a fictional seal made from our own geometry.
	var star := PackedVector2Array()
	for index in range(6):
		var angle: float = PI * 0.5 + TAU * ((index * 2) % 5) / 5.0
		star.append(_point(Vector2.from_angle(angle) * 31.0))
	canvas.draw_polyline(star, LILAC, 1.6, true)
	canvas.draw_line(_point(Vector2(0, -36)), _point(Vector2(0, 33)), VIOLET, 1.1, true)
	for side in [-1.0, 1.0]:
		canvas.draw_polyline(PackedVector2Array([_point(Vector2(side * 24, -18)), _point(Vector2(side * 35, -28)), _point(Vector2(side * 31, -7))]), VIOLET, 1.1, true)
	canvas.draw_circle(center, 3.0 * zoom, WHITE)


func _draw_node(canvas: Control, item: Dictionary) -> void:
	var id: String = str(item.get("id", ""))
	if not node_positions.has(id):
		return
	var point: Vector2 = _point(node_positions[id])
	var radius: float = NODE_RADIUS * zoom
	var state: String = _state(id)
	var current_rank: int = _rank(id)
	var rank_limit: int = _max_rank(id)
	var complete: bool = current_rank >= rank_limit and rank_limit > 0
	var selected: bool = id == selected_id
	var hovered: bool = id == _hovered_id
	var color: Color = LILAC if state == "affordable" or current_rank > 0 else Color("77618e")
	if selected:
		canvas.draw_circle(point, radius + 11.0, Color(0.65, 0.39, 0.9, 0.09))
		canvas.draw_arc(point, radius + 7.0, 0.0, TAU, 48, LILAC, 1.7, true)
		for index in range(4):
			var direction: Vector2 = Vector2.from_angle(PI * 0.25 + index * PI * 0.5)
			canvas.draw_line(point + direction * (radius + 11.0), point + direction * (radius + 16.0), LILAC, 1.5, true)
	elif hovered:
		canvas.draw_arc(point, radius + 6.0, 0.0, TAU, 48, LILAC, 1.0, true)
	canvas.draw_circle(point, radius + 2.0, INK)
	var fill: Color = Color("422759") if complete else Color("2b1b3d") if current_rank > 0 else Color("21162e")
	canvas.draw_circle(point, radius, fill)
	canvas.draw_arc(point, radius, 0.0, TAU, 48, color, 2.0 if complete else 1.3, true)
	canvas.draw_arc(point, maxf(2.0, radius - 4.0), 0.0, TAU, 48, Color(color, 0.25), 1.0, true)
	if current_rank > 0 and not complete:
		canvas.draw_arc(point, radius - 4.0, -PI * 0.5, -PI * 0.5 + TAU * current_rank / float(rank_limit), 48, LILAC, 2.1, true)
	_draw_glyph(canvas, point, str(item.get("branch", "talk")), color)
	# Pips show ranks independently of affordability and ring numbering.
	if zoom >= 0.5:
		for index in range(rank_limit):
			var pip_at: Vector2 = point + Vector2((index - (rank_limit - 1) * 0.5) * 9.0, 19.0) * zoom
			var pip_radius: float = maxf(1.5, 2.2 * zoom)
			if index < current_rank:
				canvas.draw_circle(pip_at, pip_radius, WHITE)
			else:
				canvas.draw_arc(pip_at, pip_radius, 0.0, TAU, 12, MUTED, 1.0, true)
	if complete:
		canvas.draw_circle(point + Vector2(radius * 0.74, -radius * 0.74), maxf(2.0, 3.5 * zoom), WHITE)
	elif state == "affordable":
		var diamond: Vector2 = point + Vector2(0, -radius - 4.0)
		canvas.draw_colored_polygon(PackedVector2Array([diamond + Vector2(0, -3), diamond + Vector2(3, 0), diamond + Vector2(0, 3), diamond + Vector2(-3, 0)]), LILAC)
	if zoom >= 0.50:
		var title: String = str(item.get("title", id))
		if zoom < 0.8:
			# A fitted overview keeps every glyph visible; full titles/ranks remain in details.
			title = title.replace("Quickened Words", "Words").replace("Compelling Creed", "Creed").replace("Fleet Footsteps", "Run").replace(" Invitations", "")
			var compact_width: float = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var compact_at: Vector2 = point + Vector2(-compact_width * 0.5, radius + 17.0)
			canvas.draw_rect(Rect2(compact_at + Vector2(-3, -12), Vector2(compact_width + 6, 16)), INK)
			canvas.draw_string(_font, compact_at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
			return
		var text_size: int = 13 if zoom < 1.15 else 15
		var title_width: float = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
		var tier: String = "%s  /  RANK %d/%d" % [_roman(int(item.get("ring", 1))), current_rank, rank_limit]
		var tier_width: float = _font.get_string_size(tier, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var label_offset: float = 0.0
		var tier_bounds := Rect2(point + Vector2(-tier_width * 0.5, radius + 27.0), Vector2(tier_width, 15.0))
		# Neighboring rings can put a rank row at the height of another node's title.
		# Nudge only the text block horizontally; the ritual geometry and hit areas stay fixed.
		for neighbor in _catalog:
			var neighbor_id: String = str(neighbor.get("id", ""))
			if neighbor_id == id or not node_positions.has(neighbor_id):
				continue
			var neighbor_point: Vector2 = _point(node_positions[neighbor_id])
			var neighbor_width: float = _font.get_string_size(str(neighbor.get("title", neighbor_id)), HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
			var neighbor_bounds := Rect2(neighbor_point + Vector2(-neighbor_width * 0.5 - 4.0, radius + 22.0 - text_size), Vector2(neighbor_width + 8.0, text_size + 5.0))
			if tier_bounds.intersects(neighbor_bounds):
				var shift: float = neighbor_bounds.position.x - 8.0 - tier_bounds.end.x if point.x < neighbor_point.x else neighbor_bounds.end.x + 8.0 - tier_bounds.position.x
				label_offset += shift
				tier_bounds.position.x += shift
		var label_position := point + Vector2(-title_width * 0.5 + label_offset, radius + 22.0)
		canvas.draw_rect(Rect2(label_position + Vector2(-4, -text_size), Vector2(title_width + 8, text_size + 5)), INK)
		canvas.draw_string(_font, label_position, title, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, LILAC if selected else color)
		var tier_position: Vector2 = point + Vector2(-tier_width * 0.5 + label_offset, radius + 38)
		canvas.draw_rect(Rect2(tier_position + Vector2(-3, -11), Vector2(tier_width + 6, 15)), INK)
		canvas.draw_string(_font, tier_position, tier, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LILAC if current_rank > 0 else MUTED)


func _draw_glyph(canvas: Control, at: Vector2, branch: String, color: Color) -> void:
	var scale: float = zoom
	match branch:
		"talk":
			canvas.draw_line(at + Vector2(-5, -10) * scale, at + Vector2(-5, 10) * scale, color, 1.7, true)
			canvas.draw_arc(at + Vector2(-6, 0) * scale, 9 * scale, -PI * 0.42, PI * 0.42, 18, color, 1.3, true)
			canvas.draw_arc(at + Vector2(-6, 0) * scale, 15 * scale, -PI * 0.35, PI * 0.35, 18, color, 1.3, true)
		"persuade":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(0, -12) * scale, at + Vector2(9, 0) * scale, at + Vector2(0, 12) * scale, at + Vector2(-9, 0) * scale, at + Vector2(0, -12) * scale]), color, 1.6, true)
			canvas.draw_line(at + Vector2(0, -6) * scale, at + Vector2(0, 6) * scale, color, 1.2, true)
		"gather":
			for x in [-9, 0, 9]:
				canvas.draw_circle(at + Vector2(x, -5) * scale, 3.0 * scale, color)
				canvas.draw_line(at + Vector2(x, 0) * scale, at + Vector2(x, 8) * scale, color, 2.0, true)
		"run":
			for x in [-5, 4]:
				canvas.draw_polyline(PackedVector2Array([at + Vector2(x - 4, -10) * scale, at + Vector2(x + 3, 0) * scale, at + Vector2(x - 4, 10) * scale]), color, 1.7, true)
		_:
			canvas.draw_circle(at, 5.0 * scale, color)


func _roman(value: int) -> String:
	var numerals: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
	return numerals[value - 1] if value >= 1 and value <= numerals.size() else str(value)
