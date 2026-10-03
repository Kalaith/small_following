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
const Layout = preload("res://scripts/ritual_layout.gd")

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
var focus_button: Button
var overview_button: Button
var branch_picker: OptionButton
var node_picker: OptionButton
var _branch_bar: HBoxContainer
var _branch_buttons: Dictionary = {}
var _branch_order: Array[String] = []
var _browse_ids: Array[String] = []
var _label_rects: Dictionary = {}
var _label_model: Array[Dictionary] = []
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
	_rebuild_branch_navigation()
	update_state()


func configure(catalog: Array, progression: RefCounted) -> void:
	_hovered_id = ""
	_catalog = catalog
	_progression = progression
	_by_id.clear()
	node_positions = Layout.build(catalog)
	_max_radius = FIRST_RING
	for value in _catalog:
		var item: Dictionary = value
		var id: String = str(item.get("id", ""))
		if id.is_empty():
			continue
		_by_id[id] = item
		var ring: int = maxi(1, int(item.get("ring", 1)))
		var radius: float = FIRST_RING + (ring - 1) * RING_STEP
		_max_radius = maxf(radius, _max_radius)
	if not _by_id.has(selected_id):
		selected_id = str(_catalog[0].get("id", "")) if not _catalog.is_empty() else ""
	if _built:
		_rebuild_branch_navigation()
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
	_branch_label.visible = not item.is_empty()
	_rank_label.visible = not item.is_empty()
	var state: String = _state(selected_id)
	_displayed_rank = _rank(selected_id)
	var rank_limit: int = _max_rank(selected_id)
	var cost: int = _next_cost(selected_id)
	var branch: String = str(item.get("branch", ""))
	var branch_name: String = {"talk": "THE VOICE", "persuade": "THE CONVICTION", "run": "THE PILGRIM", "gather": "THE VILLAGE", "helper": "THE COMPANION"}.get(branch, "THE CIRCLE")
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
	_update_branch_navigation()
	graph.queue_redraw()
	queue_redraw()


func select_node(id: String) -> void:
	if not _by_id.has(id):
		return
	selected_id = id
	update_state(_round_recruits)


func clear_selection() -> void:
	selected_id = ""
	_hovered_id = ""
	update_state(_round_recruits)


func get_focus_path() -> Dictionary:
	var result: Dictionary = {}
	var target: String = _hovered_id if not _hovered_id.is_empty() else selected_id
	var pending: Array[String] = [target]
	while not pending.is_empty():
		var id: String = pending.pop_back()
		if not _by_id.has(id) or result.has(id):
			continue
		result[id] = true
		for required in _by_id[id].get("requires", []):
			pending.append(str(required))
	return result


func get_visible_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var path: Dictionary = get_focus_path()
	for item in _catalog:
		var id: String = str(item.get("id", ""))
		for required in item.get("requires", []):
			var from: String = str(required)
			if not _by_id.has(from):
				continue
			var cross: bool = str(item.get("branch", "")) != str(_by_id[from].get("branch", ""))
			var relevant: bool = path.has(id) and path.has(from)
			if cross and not relevant:
				continue
			var alpha: float = 0.9 if relevant else 0.21 if not path.is_empty() else 0.54
			result.append({"from": from, "to": id, "kind": "cross" if cross else "main", "relevant": relevant, "alpha": alpha, "focused": relevant, "cross_branch": cross})
	return result


func get_label_rects() -> Dictionary:
	_prepare_labels()
	return _label_rects.duplicate()


func label_bounds() -> Dictionary:
	return get_label_rects()


func get_branch_summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var order: Array[String] = ["talk", "run", "persuade", "gather", "helper"]
	for item in _catalog:
		var branch: String = str(item.get("branch", ""))
		if not order.has(branch):
			order.append(branch)
	for branch in order:
		var ids: Array[String] = []
		var owned: int = 0
		var available: int = 0
		for item in _catalog:
			if str(item.get("branch", "")) != branch:
				continue
			var id: String = str(item.get("id", ""))
			ids.append(id)
			owned += 1 if _rank(id) > 0 else 0
			available += 1 if _state(id) == "affordable" else 0
		if not ids.is_empty():
			ids.sort_custom(func(a: String, b: String) -> bool: return int(_by_id[a].get("ring", 1)) < int(_by_id[b].get("ring", 1)))
			result.append({"id": branch, "title": Layout.branch_title(branch), "count": ids.size(), "owned": owned, "available": available, "ids": ids})
	return result


func focus_branch(branch: String) -> void:
	for summary in get_branch_summaries():
		if str(summary.id) != branch:
			continue
		var target: String = str(summary.ids[0])
		for id in summary.ids:
			if _state(id) == "affordable":
				target = str(id)
				break
			if _state(id) == "unaffordable":
				target = str(id)
		_hovered_id = ""
		focus_node(target)
		return


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
	var distance: float = maxf(NODE_RADIUS + 6.0, 7.0 / zoom)
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
	_hovered_id = ""
	graph.queue_redraw()


func focus_node(id: String) -> void:
	if not node_positions.has(id):
		return
	_hovered_id = ""
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
	var stat_key: String = {"talk": "speech_frequency", "persuade": "conviction", "run": "run_multiplier", "gather": "gatherings", "helper": "helpers"}.get(branch, "")
	var heading: String = {"talk": "TALKING FREQUENCY", "persuade": "CONVICTION PER PHRASE", "run": "RUNNING SPEED", "gather": "VILLAGE GATHERINGS", "helper": "HELPERS"}.get(branch, "")
	var units: String = {"talk": "phrases/s", "persuade": "conviction", "run": "x base", "gather": "groups of five", "helper": "helpers"}.get(branch, "")
	if stat_key.is_empty() or not current.has(stat_key):
		return ""
	var current_value: float = float(current[stat_key])
	if branch == "helper":
		return "ONE LISTENER AT A TIME\n1 helper / 150 px per second" if complete else "HELPERS\n0 → 1 / one listener at a time"
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
	graph.mouse_exited.connect(func() -> void:
		_hovered_id = ""
		graph.queue_redraw()
	)
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
	_legend_label = _label("Diamond: locked   /   Hollow: needs donations   /   +: ready   /   Check: complete\nDrag to explore · Scroll to zoom · Hover or select to trace requirements", 11, MUTED)
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
	focus_button = _button("Focus selected", false)
	focus_button.pressed.connect(func() -> void: focus_node(selected_id))
	overview_button = _button("Overview", false)
	overview_button.pressed.connect(func() -> void:
		reset_view()
		clear_selection()
	)
	_branch_bar = HBoxContainer.new()
	_branch_bar.add_theme_constant_override("separation", 6)
	add_child(_branch_bar)
	branch_picker = OptionButton.new()
	branch_picker.focus_mode = Control.FOCUS_NONE
	branch_picker.add_theme_font_size_override("font_size", 13)
	branch_picker.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < _branch_order.size():
			focus_branch(_branch_order[index])
	)
	add_child(branch_picker)
	node_picker = OptionButton.new()
	node_picker.focus_mode = Control.FOCUS_NONE
	node_picker.add_theme_font_size_override("font_size", 12)
	node_picker.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < _browse_ids.size():
			focus_node(_browse_ids[index])
	)
	add_child(node_picker)


func _rebuild_branch_navigation() -> void:
	for child in _branch_bar.get_children():
		_branch_bar.remove_child(child)
		child.queue_free()
	_branch_buttons.clear()
	_branch_order.clear()
	branch_picker.clear()
	var summaries: Array[Dictionary] = get_branch_summaries()
	for summary in summaries:
		var branch: String = str(summary.id)
		_branch_order.append(branch)
		branch_picker.add_item(str(summary.title))
		branch_picker.set_item_metadata(branch_picker.item_count - 1, branch)
		if summaries.size() <= 6:
			var button: Button = _button(str(summary.title), false)
			remove_child(button)
			_branch_bar.add_child(button)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 12)
			button.pressed.connect(focus_branch.bind(branch))
			_branch_buttons[branch] = button
	_branch_bar.visible = summaries.size() <= 6
	branch_picker.visible = summaries.size() > 6
	_update_branch_navigation()


func _update_branch_navigation() -> void:
	if not is_instance_valid(node_picker):
		return
	var selected_branch: String = str(_by_id.get(selected_id, {}).get("branch", ""))
	for summary in get_branch_summaries():
		var text: String = "%s  %d/%d" % [summary.title, summary.owned, summary.count]
		var tooltip: String = "%s: %d of %d nodes owned; %d ready to buy. Click to focus this branch." % [summary.title, summary.owned, summary.count, summary.available]
		if _branch_buttons.has(summary.id):
			var button: Button = _branch_buttons[summary.id]
			button.text = text + (" +" if int(summary.available) > 0 else "")
			button.tooltip_text = tooltip
			button.add_theme_color_override("font_color", WHITE if str(summary.id) == selected_branch else MUTED)
		var index: int = _branch_order.find(str(summary.id))
		if index >= 0:
			branch_picker.set_item_text(index, "%s · %d ready" % [text, summary.available])
			if str(summary.id) == selected_branch:
				branch_picker.select(index)
	_browse_ids.clear()
	node_picker.clear()
	for summary in get_branch_summaries():
		if str(summary.id) != selected_branch:
			continue
		for id in summary.ids:
			_browse_ids.append(str(id))
			var state: String = _state(id)
			var state_text: String = {"locked": "locked", "affordable": "ready", "unaffordable": "needs donations", "purchased": "complete"}.get(state, state)
			node_picker.add_item("%s · %d/%d · %s" % [_by_id[id].get("title", id), _rank(id), _max_rank(id), state_text])
			node_picker.set_item_metadata(node_picker.item_count - 1, str(id))
			if str(id) == selected_id:
				node_picker.select(_browse_ids.size() - 1)
	node_picker.disabled = _browse_ids.is_empty()
	if _browse_ids.is_empty():
		node_picker.add_item("Choose a branch above to browse its nodes")
	node_picker.tooltip_text = "Browse every node in the selected branch, including locked nodes. Choosing one centers it at a readable scale."
	focus_button.disabled = selected_id.is_empty()


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
	graph.position = Vector2(24, 159)
	graph.size = Vector2(maxf(280.0, _detail_x - 51.0), maxf(280.0, size.y - 268.0))
	_branch_bar.position = Vector2(margin, 120)
	_branch_bar.size = Vector2(_detail_x - margin - 36, 30)
	branch_picker.position = _branch_bar.position
	branch_picker.size = Vector2(minf(430, _branch_bar.size.x), 30)
	node_picker.position = Vector2(margin, size.y - 103)
	node_picker.size = Vector2(minf(440, _detail_x - margin - 36), 30)
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
	_legend_label.size = Vector2(_detail_x - margin - 22, 38)
	recenter_button.position = Vector2(_detail_x - 118, 82)
	recenter_button.size = Vector2(91, 30)
	focus_button.position = Vector2(_detail_x - 265, 82)
	focus_button.size = Vector2(138, 30)
	overview_button.position = Vector2(_detail_x - 366, 82)
	overview_button.size = Vector2(92, 30)
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
	var rings: Dictionary = {}
	for item in _catalog:
		rings[int(item.get("ring", 1))] = true
	# Rings give depth and orientation; only real progress edges form the graph.
	for key in rings:
		_arc(canvas, center, FIRST_RING + (int(key) - 1) * RING_STEP, Color(0.52, 0.36, 0.68, 0.14), 1.0)
	var outer: float = _max_radius + 31.0
	_arc(canvas, center, outer, Color(0.60, 0.43, 0.78, 0.25), 1.0)
	_draw_runes(canvas, outer + 8.0)
	var path: Dictionary = get_focus_path()
	for edge in get_visible_edges():
		var from: Vector2 = _point(node_positions[edge.from])
		var to: Vector2 = _point(node_positions[edge.to])
		var direction: Vector2 = from.direction_to(to)
		var radius: float = _node_radius()
		from += direction * (radius + 3.0)
		to -= direction * (radius + 3.0)
		var color := Color(LILAC if edge.relevant else VIOLET, float(edge.alpha))
		if edge.cross_branch:
			# A dashed cross-branch link differs from the permanent branch spine.
			canvas.draw_dashed_line(from, to, color, 1.5, 7.0, true)
		else:
			canvas.draw_line(from, to, color, 2.2 if edge.relevant else 1.5, true)
		if edge.relevant and from.distance_to(to) > 20.0:
			var tip: Vector2 = to - direction * 6.0
			canvas.draw_polyline(PackedVector2Array([tip - direction.rotated(-0.55) * 7.0, tip, tip - direction.rotated(0.55) * 7.0]), color, 1.2, true)
	for item in _catalog:
		if item.get("requires", []).is_empty():
			var at: Vector2 = node_positions[str(item.id)]
			var alpha: float = 0.46 if path.has(str(item.id)) or path.is_empty() else 0.14
			canvas.draw_line(_point(at.normalized() * 47.0), _point(at - at.normalized() * NODE_RADIUS), Color(VIOLET, alpha), 1.0, true)
	_draw_core(canvas)
	for item in _catalog:
		_draw_node(canvas, item)
	_prepare_labels()
	for label in _label_model:
		var bounds: Rect2 = label.rect
		canvas.draw_rect(bounds, Color(INK, 0.96))
		canvas.draw_string(_font, bounds.position + Vector2(4, label.font_size + 1), label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size, label.color)
		if not str(label.rank_text).is_empty():
			canvas.draw_string(_font, bounds.position + Vector2(4, label.font_size + 16), label.rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)


func _node_radius() -> float:
	return maxf(4.0, NODE_RADIUS * zoom)


func _arc(canvas: Control, center: Vector2, radius: float, color: Color, width: float) -> void:
	canvas.draw_arc(center, radius * zoom, 0.0, TAU, 180, color, width, true)


func _draw_runes(canvas: Control, radius: float) -> void:
	var count: int = mini(192, maxi(48, int(radius / 5.0)))
	for index in range(count):
		var angle: float = TAU * index / float(count)
		var radial: Vector2 = Vector2.from_angle(angle)
		var tangent: Vector2 = radial.orthogonal()
		var at: Vector2 = radial * radius
		var color := Color(0.70, 0.47, 0.9, 0.23 if index % 3 == 0 else 0.12)
		canvas.draw_line(_point(at - radial * 3.7), _point(at + radial * 3.7), color, 1.0, true)
		if index % 3 == 0:
			canvas.draw_line(_point(at + radial * 2.5), _point(at + tangent * 3.0), color, 1.0, true)
		elif index % 3 == 1:
			canvas.draw_line(_point(at + tangent * 2.2), _point(at - tangent * 2.2), color, 1.0, true)


func _draw_core(canvas: Control) -> void:
	var center: Vector2 = _point(Vector2.ZERO)
	canvas.draw_circle(center, 42.0 * zoom, Color("17101f"))
	_arc(canvas, center, 42.0, Color(VIOLET, 0.18), 1.0)
	# A small fictional seal; lower contrast than every upgrade state.
	var star := PackedVector2Array()
	for index in range(6):
		var angle: float = PI * 0.5 + TAU * ((index * 2) % 5) / 5.0
		star.append(_point(Vector2.from_angle(angle) * 27.0))
	canvas.draw_polyline(star, Color(VIOLET, 0.25), 1.0, true)


func _draw_node(canvas: Control, item: Dictionary) -> void:
	var id: String = str(item.get("id", ""))
	if not node_positions.has(id):
		return
	var point: Vector2 = _point(node_positions[id])
	var radius: float = _node_radius()
	var state: String = _state(id)
	var current_rank: int = _rank(id)
	var rank_limit: int = _max_rank(id)
	var complete: bool = state == "purchased"
	var selected: bool = id == selected_id
	var hovered: bool = id == _hovered_id
	var color: Color = LILAC if state == "affordable" or current_rank > 0 else Color("a18daf") if state == "unaffordable" else Color("706078")
	if selected or hovered:
		canvas.draw_arc(point, radius + 5.0, 0, TAU, 48, WHITE if selected else LILAC, 1.5, true)
		if selected:
			for index in range(4):
				var direction: Vector2 = Vector2.from_angle(PI * 0.25 + index * PI * 0.5)
				canvas.draw_line(point + direction * (radius + 8.0), point + direction * (radius + 11.0), LILAC, 1.0, true)
	canvas.draw_circle(point, radius + 2.0, INK)
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
			canvas.draw_arc(point, maxf(2, radius - 4), -PI * 0.5, -PI * 0.5 + TAU * current_rank / float(rank_limit), 40, WHITE, 2.2, true)
		if complete:
			var check_at: Vector2 = point + Vector2(radius * 0.70, -radius * 0.68) if radius >= 10 else point
			canvas.draw_circle(check_at, 5.0 if radius >= 10 else 3.0, INK)
			canvas.draw_polyline(PackedVector2Array([check_at + Vector2(-3, 0), check_at + Vector2(-0.5, 2.2), check_at + Vector2(3.5, -2.5)]), WHITE, 1.5, true)
		elif state == "affordable":
			var plus_at: Vector2 = point + Vector2(0, -radius - 2) if radius >= 10 else point
			canvas.draw_circle(plus_at, 4.0, INK)
			canvas.draw_line(plus_at + Vector2(-3, 0), plus_at + Vector2(3, 0), WHITE, 1.4, true)
			canvas.draw_line(plus_at + Vector2(0, -3), plus_at + Vector2(0, 3), WHITE, 1.4, true)
	if zoom >= 0.65 and rank_limit > 1:
		for index in range(rank_limit):
			var pip_at: Vector2 = point + Vector2((index - (rank_limit - 1) * 0.5) * 8.0, radius * 0.64)
			if index < current_rank:
				canvas.draw_circle(pip_at, 2.0, WHITE)
			else:
				canvas.draw_arc(pip_at, 2.0, 0, TAU, 12, MUTED, 1.0, true)


func _compact_title(item: Dictionary) -> String:
	return str(item.get("title", item.get("id", ""))).replace("Quickened Words", "Words").replace("Compelling Creed", "Creed").replace("Fleet Footsteps", "Run").replace(" Invitations", "")


func _prepare_labels() -> void:
	_label_rects.clear()
	_label_model.clear()
	if not is_instance_valid(graph) or not is_instance_valid(_font):
		return
	var candidates: Array = _catalog.duplicate()
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _label_priority(a) > _label_priority(b))
	var visible_bounds := Rect2(Vector2(4, 4), graph.size - Vector2(8, 8))
	var radius: float = _node_radius()
	for item in candidates:
		var id: String = str(item.get("id", ""))
		var selected: bool = id == selected_id or id == _hovered_id
		var major: bool = str(item.get("branch", "")) in ["gather", "helper"]
		# At distant scale reveal major unlocks and focus; every other node remains
		# visible/pickable and listed by branch in the stationary browser.
		if zoom < 0.45 and not selected and not major:
			continue
		var point: Vector2 = _point(node_positions[id])
		if not visible_bounds.has_point(point):
			continue
		var text: String = str(item.get("title", id)) if zoom >= 1.15 else _compact_title(item)
		var font_size: int = 14 if zoom >= 1.15 else 12
		var rank_text: String = "RANK %d/%d" % [_rank(id), _max_rank(id)] if zoom >= 0.8 else ""
		var width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8.0
		if not rank_text.is_empty():
			width = maxf(width, _font.get_string_size(rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 8.0)
		var height: float = font_size + 6.0 + (15.0 if not rank_text.is_empty() else 0.0)
		var offsets: Array[Vector2] = [Vector2(radius + 10, -height * 0.5), Vector2(-width * 0.5, -radius - height - 8), Vector2(-width * 0.5, radius + 8), Vector2(-radius - width - 10, -height * 0.5)]
		if str(item.get("branch", "")) in ["run", "persuade"]:
			offsets = [offsets[1], offsets[2], offsets[0], offsets[3]]
		for offset in offsets:
			var bounds := Rect2(point + offset, Vector2(width, height))
			if not visible_bounds.encloses(bounds) or _label_collides(bounds, id, radius):
				continue
			var color: Color = WHITE if selected else LILAC if _rank(id) > 0 or _state(id) == "affordable" else MUTED
			_label_model.append({"id": id, "rect": bounds, "text": text, "rank_text": rank_text, "font_size": font_size, "color": color})
			_label_rects[id] = Rect2(bounds.position + graph.global_position, bounds.size)
			break


func _label_priority(item: Dictionary) -> int:
	var id: String = str(item.get("id", ""))
	if id == _hovered_id:
		return 1000
	if id == selected_id:
		return 900
	if str(item.get("branch", "")) in ["gather", "helper"]:
		return 500 - int(item.get("ring", 1))
	return 100 - int(item.get("ring", 1))


func _label_collides(bounds: Rect2, own_id: String, radius: float) -> bool:
	for label in _label_model:
		if bounds.grow(3.0).intersects(label.rect):
			return true
	for id in node_positions:
		if str(id) == own_id:
			continue
		var at: Vector2 = _point(node_positions[id])
		if bounds.grow(3.0).intersects(Rect2(at - Vector2.ONE * (radius + 3.0), Vector2.ONE * (radius + 3.0) * 2.0)):
			return true
	return false


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
		"helper":
			canvas.draw_circle(at + Vector2(0, -7) * scale, 4.0 * scale, color)
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-8, 10) * scale, at + Vector2(0, -1) * scale, at + Vector2(8, 10) * scale]), color, 1.6, true)
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
