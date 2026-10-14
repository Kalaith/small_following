extends Control
## A zoomable, data-driven constellation. The village simulation remains unpaused.
## Geometry is procedural placeholder artwork, informed by the supplied reference descriptions.
## Drawing, labels, pointer gestures, branch navigation and detail wording live in
## the ritual_*.gd helpers; this screen owns the state they read and the controls.

signal purchase_requested(id: String, expected_rank: int)
signal next_round_requested
signal return_to_village_requested
signal travel_requested(area_id: String)
## A Quillmoor argument card was chosen; progression decides the loadout.
signal argument_toggled(argument: String)

const Style = preload("res://scripts/ritual_style.gd")
const INK := Style.INK
const PANEL := Style.PANEL
const LINE := Style.LINE
const LILAC := Style.LILAC
const VIOLET := Style.VIOLET
const MUTED := Style.MUTED
const WHITE := Style.WHITE
const GOLD := Style.GOLD
const RING_STEP: float = 86.0
const FIRST_RING: float = 112.0
const NODE_RADIUS: float = Style.NODE_RADIUS
const MIN_ZOOM: float = 0.025
const MAX_ZOOM: float = 2.4
const CORE_RADIUS: float = Style.CORE_RADIUS
const CORE_ORNAMENT_RADIUS: float = Style.CORE_ORNAMENT_RADIUS
const Layout = preload("res://scripts/ritual_layout.gd")
const Keys = preload("res://scripts/key_bindings.gd")
const Progression = preload("res://scripts/progression.gd")
const Widgets = preload("res://scripts/ritual_widgets.gd")
const RitualText = preload("res://scripts/ritual_text.gd")
const SealArt = preload("res://scripts/ritual_seal_art.gd")
const NodeArt = preload("res://scripts/ritual_node_art.gd")
const Labels = preload("res://scripts/ritual_labels.gd")
const Pointer = preload("res://scripts/ritual_pointer.gd")
const BranchNav = preload("res://scripts/ritual_branch_nav.gd")
const ArgumentCards = preload("res://scripts/ritual_argument_cards.gd")
const Frame = preload("res://scripts/ritual_frame.gd")
const AreaText = preload("res://scripts/ritual_area_text.gd")

class GraphCanvas extends Control:
	var screen: Control
	func _draw() -> void:
		if is_instance_valid(screen):
			screen._draw_graph(self)
	func _gui_input(event: InputEvent) -> void:
		if is_instance_valid(screen):
			screen.pointer.handle_graph_input(event)

var selected_id: String = ""
var node_positions: Dictionary = {}
var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
## True once the player has panned, zoomed or focused; a window resize then keeps that view.
var _view_adjusted: bool = false
var graph: GraphCanvas
var purchase_button: Button
var next_button: Button
var village_button: Button
var recenter_button: Button
var focus_button: Button
var zoom_in_button: Button
var zoom_out_button: Button
var branch_picker: OptionButton
var node_picker: OptionButton
var completion_button: Button
var demo_message_label: Label
var demo_continue_button: Button
var destination_button: Button
var return_area_button: Button
var branch_bar := HBoxContainer.new()
var pointer: Pointer = Pointer.new(self)
var branch_nav: BranchNav = BranchNav.new(self, branch_bar)
var seal_art: SealArt = SealArt.new(self)
var node_art: NodeArt = NodeArt.new(self)
var labels: Labels = Labels.new(self)
var frame: Frame = Frame.new(self)
var hovered_id: String = ""
var core_hovered: bool = false
var market_circle: bool = false
var fair_circle: bool = false
var uni_circle: bool = false
var rose_circle: bool = false
## The area whose circle is shown; its wording comes from ritual_area_text.gd.
var circle_area: String = "bramblewick"
var argument_cards: ArgumentCards
## Any circle after Bramblewick's: it offers a road back and a compact legend.
var away_circle: bool = false
var max_radius: float = FIRST_RING
var catalog: Array = []
var by_id: Dictionary = {}
var _demo_overlay: Control
var _demo_panel: PanelContainer
var _progression: Progression
var _round_recruits: int = 0
var _title_label: Label
var _subtitle_label: Label
var _coins_label: Label
var _recruits_label: Label
var _lifetime_label: Label
var _branch_label: Label
var _node_title: Label
var _rank_label: Label
var _effect_label: Label
var _node_description: Label
var _status_label: Label
var _hint_label: Label
var _demo_hint: Label
var _legend_label: Label
var _error_label: Label
var _detail_x: float = 0.0
## Right edge of the circle's column; its controls align here, clear of the detail panel.
var _column_right: float = 0.0
## The selected node's details stack here, so long descriptions push the button down.
var _detail_box: VBoxContainer
var _built: bool = false
var _displayed_rank: int = 0
var _destination_id: String = ""
var _destination_title: String = ""
var _return_id: String = ""
var _demo_description: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	resized.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()
	_built = true
	branch_nav.rebuild()
	update_state()


func configure(new_catalog: Array, progression: Progression) -> void:
	pointer.reset_gesture()
	dismiss_demo_message()
	hovered_id = ""
	catalog = new_catalog
	var area: String = str(catalog[0].get("area", "bramblewick")) if not catalog.is_empty() else "bramblewick"
	market_circle = area == "bellmarket"
	fair_circle = area == "lantern_fair"
	uni_circle = area == "university"
	rose_circle = area == "rosecourt"
	circle_area = area
	away_circle = market_circle or fair_circle or uni_circle or rose_circle
	_progression = progression
	by_id.clear()
	node_positions = Layout.build(catalog)
	max_radius = FIRST_RING
	for value in catalog:
		var item: Dictionary = value
		var id: String = str(item.get("id", ""))
		if id.is_empty():
			continue
		by_id[id] = item
		# Authored constellations need not share the catalog's nominal ring radius.
		max_radius = maxf(node_positions.get(id, Vector2.ZERO).length(), max_radius)
	if not by_id.has(selected_id):
		selected_id = str(catalog[0].get("id", "")) if not catalog.is_empty() else ""
	if _built:
		branch_nav.rebuild()
		# The card row comes and goes with Quillmoor's circle.
		_layout()
		reset_view()
		update_state()


func configure_destination(area_id: String = "", destination_title: String = "") -> void:
	_destination_id = area_id
	_destination_title = destination_title
	dismiss_demo_message()
	if _built:
		update_state(_round_recruits)


## The road back from a later circle; empty hides the button.
func configure_return(area_id: String = "", area_title: String = "") -> void:
	_return_id = area_id
	if is_instance_valid(return_area_button):
		return_area_button.text = "Return to " + area_title if not area_id.is_empty() else ""
	if _built:
		update_state(_round_recruits)


func update_state(round_recruits: int = 0) -> void:
	_round_recruits = round_recruits
	if not _built:
		return
	_hint_label.text = "%s%s%s%s / D-pad: select   ·   %s: inscribe" % [Keys.hint("ritual_nav_up"), Keys.hint("ritual_nav_down"), Keys.hint("ritual_nav_left"), Keys.hint("ritual_nav_right"), Keys.hint("buy_upgrade")]
	_demo_hint.text = "Esc: dismiss / Tab: village / %s: next round" % Keys.hint("next_round")
	_subtitle_label.text = AreaText.subtitle(circle_area, _progression, _round_recruits)
	_title_label.text = AreaText.words(circle_area, "title")
	return_area_button.visible = not _return_id.is_empty()
	village_button.text = AreaText.words(circle_area, "back") + "  ·  Tab"
	next_button.text = "Begin next round  ·  " + Keys.hint("next_round")
	argument_cards.visible = uni_circle
	if uni_circle and is_instance_valid(_progression):
		argument_cards.refresh(_progression)
	elif market_circle:
		_subtitle_label.text = "BELLMARKET  /  %d NEW FOLLOWERS  /  FIVE PATHS, YOUR CHOICE" % _round_recruits
	elif circle_area == "bramblewick" and is_instance_valid(_progression) and _progression.map_complete():
		_subtitle_label.text = "BRAMBLEWICK COMPLETE  /  PRIEST CONVINCED"
	elif circle_area == "bramblewick" and is_instance_valid(_progression) and _progression.has_unlock("encounter_unlock"):
		var opponents: Array[String] = ["Skeptic", "Town Guard", "Zealot", "Priest"]
		_subtitle_label.text = "TOWN DEBATE %d/4  /  Next: %s" % [_progression.encounter_stage, opponents[_progression.encounter_stage]]
		if _progression.encounter_stage > 0:
			_subtitle_label.text += " / Town resistance: prices +%d%%" % roundi((_progression.resistance_price_multiplier() - 1.0) * 100.0)
	var coins: int = _progression.coins if is_instance_valid(_progression) else 0
	_coins_label.text = "%d  donations" % coins
	_recruits_label.text = "%d  recruits available" % (_progression.available_recruits if is_instance_valid(_progression) else 0)
	_lifetime_label.text = "%d lifetime recruits" % (_progression.total_recruits if is_instance_valid(_progression) else 0)
	var save_error: String = _progression.last_error if is_instance_valid(_progression) else ""
	_error_label.text = "NOTICE: " + save_error if not save_error.is_empty() else ""
	_error_label.visible = not save_error.is_empty()
	_error_label.tooltip_text = save_error
	var item: Dictionary = by_id.get(selected_id, {})
	_branch_label.visible = not item.is_empty()
	_rank_label.visible = not item.is_empty()
	var state: String = _state(selected_id)
	_displayed_rank = _rank(selected_id)
	var rank_limit: int = _max_rank(selected_id)
	var cost: int = _next_cost(selected_id)
	var recruit_cost: int = _next_recruit_cost(selected_id)
	var price: String = "%d donations" % cost
	price += " + %d recruit%s" % [recruit_cost, "" if recruit_cost == 1 else "s"] if recruit_cost > 0 else " / gold only"
	var branch: String = str(item.get("branch", ""))
	var branch_name: String = RitualText.branch_name(branch)
	_branch_label.text = "%s  /  TIER %s" % [branch_name, RitualText.roman(int(item.get("ring", 1)))]
	_node_title.text = str(item.get("title", "Choose an inscription"))
	_rank_label.text = "RANK %d / %d%s" % [_displayed_rank, rank_limit, "  -  COMPLETE" if state == "purchased" else ""]
	_effect_label.text = RitualText.effect_text(_progression, by_id, selected_id, branch, state == "purchased")
	_node_description.text = str(item.get("description", "Select a sigil in the circle to study its effect."))
	if not str(item.get("support_description", "")).is_empty():
		_node_description.text += "\n" + str(item.support_description)
	var requirements: Array = item.get("requires", [])
	match state:
		"purchased":
			_status_label.text = "FULLY INSCRIBED\nEvery rank is yours. No further cost."
			purchase_button.text = "Maximum rank reached"
		"locked":
			var required_names: PackedStringArray = []
			for prerequisite in requirements:
				if _rank(str(prerequisite)) < 1:
					var required: Dictionary = by_id.get(str(prerequisite), {})
					required_names.append(str(required.get("title", prerequisite)) + " rank 1")
			_status_label.text = "SEALED\nRequires " + ", ".join(required_names) + "."
			purchase_button.text = "Rank %d\n%s" % [_displayed_rank + 1, price]
		"unaffordable":
			var purchase_state: Dictionary = _progression.purchase_state(selected_id)
			_status_label.text = "AWAITING OFFERING\n" + str(purchase_state.message)
			purchase_button.text = "Inscribe rank %d\n%s" % [_displayed_rank + 1, price]
		"affordable":
			_status_label.text = "READY FOR RANK %d\n%s" % [_displayed_rank + 1, "Assign recruits; keep lifetime progress." if recruit_cost > 0 else "A permanent gift for every round."]
			purchase_button.text = "Inscribe rank %d\n%s" % [_displayed_rank + 1, price]
		_:
			_status_label.text = "Select a sigil to begin."
			purchase_button.text = "Choose an inscription"
	purchase_button.disabled = state != "affordable"
	var complete: bool = is_circle_complete()
	completion_button.disabled = not complete
	completion_button.text = "Inner circle lit / Open" if complete else "Inner circle / Earn every rank"
	completion_button.tooltip_text = "All ranks are yours. Open the lit centre." if complete else "Purchase every rank in this circle to light its centre."
	if not _destination_id.is_empty() and complete:
		completion_button.text = "Circle complete / Travel"
		completion_button.tooltip_text = "Open the route to " + _destination_title + "."
	demo_message_label.text = "The road to %s is open" % _destination_title if not _destination_id.is_empty() else AreaText.words(circle_area, "complete")
	_demo_description.text = "Visit its separate circle and new listeners. Your progress in both towns is kept." if not _destination_id.is_empty() else AreaText.words(circle_area, "after")
	destination_button.visible = not _destination_id.is_empty()
	destination_button.text = "Travel to " + _destination_title
	if not complete:
		dismiss_demo_message()
	_status_label.add_theme_color_override("font_color", LILAC if state == "affordable" or state == "purchased" else MUTED)
	branch_nav.update()
	_layout_footer()
	graph.queue_redraw()
	queue_redraw()


func select_node(id: String) -> void:
	if not by_id.has(id):
		return
	selected_id = id
	update_state(_round_recruits)


func clear_selection() -> void:
	selected_id = ""
	hovered_id = ""
	update_state(_round_recruits)


func get_focus_path() -> Dictionary:
	var result: Dictionary = {}
	var target: String = hovered_id if not hovered_id.is_empty() else selected_id
	var pending: Array[String] = [target]
	while not pending.is_empty():
		var id: String = pending.pop_back()
		if not by_id.has(id) or result.has(id):
			continue
		result[id] = true
		for required in by_id[id].get("requires", []):
			pending.append(str(required))
	return result


func get_visible_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var path: Dictionary = get_focus_path()
	for item in catalog:
		var id: String = str(item.get("id", ""))
		for required in item.get("requires", []):
			var from: String = str(required)
			if not by_id.has(from):
				continue
			var cross: bool = str(item.get("branch", "")) != str(by_id[from].get("branch", ""))
			var relevant: bool = path.has(id) and path.has(from)
			if cross and not relevant:
				continue
			var alpha: float = 0.9 if relevant else 0.21 if not path.is_empty() else 0.64
			result.append({"from": from, "to": id, "kind": "cross" if cross else "main", "relevant": relevant, "alpha": alpha, "focused": relevant, "cross_branch": cross})
	return result


func get_label_rects() -> Dictionary:
	labels.prepare()
	return labels.rects.duplicate()


func label_bounds() -> Dictionary:
	return get_label_rects()


func get_branch_summaries() -> Array[Dictionary]:
	return branch_nav.summaries()


func focus_branch(branch: String) -> void:
	branch_nav.focus(branch)


func get_selected_rank() -> int:
	# Carry the rank the player saw; duplicate stale requests must not buy another.
	return _displayed_rank


func is_circle_complete() -> bool:
	return is_instance_valid(_progression) and _progression.is_circle_complete()


func completion_hit_test(screen_point: Vector2) -> bool:
	if not is_circle_complete() or not graph.get_global_rect().has_point(screen_point):
		return false
	return screen_to_world(screen_point).length() <= maxf(CORE_RADIUS, 18.0 / zoom)


func demo_message_visible() -> bool:
	return is_instance_valid(_demo_overlay) and _demo_overlay.visible and visible


func open_demo_message() -> bool:
	if not visible or not is_circle_complete() or not is_instance_valid(_demo_overlay):
		return false
	# One reusable in-scene panel; opening it neither rewards nor persists anything.
	_demo_overlay.show()
	pointer.reset_gesture()
	return true


func dismiss_demo_message() -> void:
	if is_instance_valid(_demo_overlay):
		_demo_overlay.hide()


func nodes_position(id: String) -> Vector2:
	return node_positions.get(id, Vector2.ZERO)


func world_to_screen(point: Vector2) -> Vector2:
	return graph.global_position + graph.size * 0.5 + pan + point * zoom


func screen_to_world(point: Vector2) -> Vector2:
	return (point - graph.global_position - graph.size * 0.5 - pan) / zoom


func hit_test(screen_point: Vector2, target_radius: float = 7.0) -> String:
	if not graph.get_global_rect().has_point(screen_point):
		return ""
	var world_point: Vector2 = screen_to_world(screen_point)
	var closest: String = ""
	var distance: float = maxf(NODE_RADIUS + 6.0, target_radius / zoom)
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
	_view_adjusted = true
	graph.queue_redraw()


func pan_by(delta: Vector2) -> void:
	pan += delta
	_view_adjusted = true
	graph.queue_redraw()


func reset_view() -> void:
	if not is_instance_valid(graph):
		return
	# Reserve the inscription rim, outward ticks and a little breathing room.
	zoom = clampf(minf(graph.size.x, graph.size.y) / ((max_radius + 64.0) * 2.0), MIN_ZOOM, 1.0)
	pan = Vector2.ZERO
	_view_adjusted = false
	hovered_id = ""
	graph.queue_redraw()


func focus_node(id: String) -> void:
	if not node_positions.has(id):
		return
	hovered_id = ""
	select_node(id)
	zoom = maxf(0.8, zoom)
	pan = -Vector2(node_positions[id]) * zoom
	_view_adjusted = true
	graph.queue_redraw()


func navigate(direction: Vector2) -> void:
	# Keyboard/gamepad graph traversal: step from the selected node (or the
	# centre, when nothing is selected) to the closest node whose position
	# falls within a roughly 70-degree cone around the requested direction.
	# A radial branch's own nodes stay the best-aligned candidates, so
	# repeated presses walk outward along one branch; a wide cone still lets
	# an unaligned press cross into a neighboring branch near the centre.
	if direction.is_zero_approx() or node_positions.is_empty():
		return
	var origin: Vector2 = node_positions.get(selected_id, Vector2.ZERO)
	var want: Vector2 = direction.normalized()
	var best_id: String = ""
	var best_alignment: float = -1.0
	var best_distance: float = INF
	for id in node_positions:
		if id == selected_id:
			continue
		var delta: Vector2 = node_positions[id] - origin
		if delta.is_zero_approx():
			continue
		var alignment: float = delta.normalized().dot(want)
		if alignment < 0.35:
			continue
		var distance: float = delta.length()
		if best_id.is_empty() or alignment > best_alignment + 0.02 or (absf(alignment - best_alignment) <= 0.02 and distance < best_distance):
			best_id = str(id)
			best_alignment = alignment
			best_distance = distance
	if not best_id.is_empty():
		focus_node(best_id)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not pointer.enabled or demo_message_visible():
		return
	if uni_circle and _argument_card_input(event):
		get_viewport().set_input_as_handled()
		return
	var direction: Vector2 = Vector2.ZERO
	if event.is_action_pressed("ritual_nav_up"):
		direction = Vector2.UP
	elif event.is_action_pressed("ritual_nav_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed("ritual_nav_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed("ritual_nav_right"):
		direction = Vector2.RIGHT
	else:
		return
	navigate(direction)
	get_viewport().set_input_as_handled()


## Keys 1-4 toggle a card; a pad's bumpers move the highlight and Y toggles it.
## A key or button the player bound to any action keeps that action instead.
func _argument_card_input(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo() or _bound_to_action(event):
		return false
	if event is InputEventKey:
		var digit: int = [KEY_1, KEY_2, KEY_3, KEY_4].find(event.physical_keycode)
		if digit >= 0:
			argument_cards.toggle_at(digit)
			return true
	elif event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				argument_cards.move_cursor(-1)
				return true
			JOY_BUTTON_RIGHT_SHOULDER:
				argument_cards.move_cursor(1)
				return true
			JOY_BUTTON_Y:
				argument_cards.toggle_at(argument_cards.cursor)
				return true
	return false


func _bound_to_action(event: InputEvent) -> bool:
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_") and InputMap.event_is_action(event, action, true):
			return true
	return false


func _state(id: String) -> String:
	return _progression.status(id) if is_instance_valid(_progression) else "unknown"


func _rank(id: String) -> int:
	return _progression.rank(id) if is_instance_valid(_progression) else 0


func _max_rank(id: String) -> int:
	return _progression.max_rank(id) if is_instance_valid(_progression) else 1


func _next_cost(id: String) -> int:
	return _progression.next_cost(id) if is_instance_valid(_progression) else 0


func _next_recruit_cost(id: String) -> int:
	return _progression.next_recruit_cost(id) if is_instance_valid(_progression) else 0


func _build_controls() -> void:
	graph = GraphCanvas.new()
	graph.name = "RitualGraph"
	graph.screen = self
	graph.clip_contents = true
	graph.mouse_filter = Control.MOUSE_FILTER_STOP
	graph.mouse_exited.connect(func() -> void:
		hovered_id = ""
		core_hovered = false
		graph.queue_redraw()
	)
	add_child(graph)
	_title_label = _label("The circle grows.", 34, WHITE)
	_subtitle_label = _label("ROUND COMPLETE", 12, MUTED)
	_coins_label = _label("0  donations", 23, LILAC)
	_recruits_label = _label("0  recruits available", 20, LILAC)
	_lifetime_label = _label("0 lifetime recruits", 12, MUTED)
	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 6)
	add_child(_detail_box)
	_branch_label = _label("THE VOICE  /  RING I", 12, VIOLET, _detail_box)
	_node_title = _label("Choose an inscription", 26, WHITE, _detail_box)
	_node_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rank_label = _label("RANK 0 / 1", 13, VIOLET, _detail_box)
	_detail_gap(8)
	_effect_label = _label("", 18, WHITE, _detail_box)
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_node_description = _label("", 14, LILAC, _detail_box)
	_node_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_gap(8)
	_status_label = _label("", 14, MUTED, _detail_box)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_gap(4)
	purchase_button = _button("Inscribe", true, _detail_box)
	purchase_button.custom_minimum_size.y = 56
	purchase_button.pressed.connect(_purchase_selected)
	_error_label = _label("", 11, LILAC, _detail_box)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.max_lines_visible = 3
	_error_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_error_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_hint_label = _label("", 12, MUTED)
	_legend_label = _label("", 11, MUTED)
	_legend_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_button = _button("Begin next round", true)
	next_button.pressed.connect(func() -> void: next_round_requested.emit())
	village_button = _button("Return to the village", false)
	village_button.pressed.connect(func() -> void: return_to_village_requested.emit())
	recenter_button = _button("Recenter", false)
	recenter_button.pressed.connect(reset_view)
	focus_button = _button("Focus selected", false)
	focus_button.pressed.connect(func() -> void: focus_node(selected_id))
	zoom_out_button = _button("-", false)
	zoom_out_button.tooltip_text = "Zoom out"
	zoom_out_button.pressed.connect(func() -> void: zoom_at(graph.get_global_rect().get_center(), 1.0 / 1.25))
	zoom_in_button = _button("+", false)
	zoom_in_button.tooltip_text = "Zoom in"
	zoom_in_button.pressed.connect(func() -> void: zoom_at(graph.get_global_rect().get_center(), 1.25))
	branch_bar.add_theme_constant_override("separation", 6)
	add_child(branch_bar)
	branch_picker = OptionButton.new()
	branch_picker.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	branch_picker.focus_mode = Control.FOCUS_NONE
	branch_picker.add_theme_font_size_override("font_size", 13)
	branch_picker.get_popup().add_theme_constant_override("v_separation", 40)
	branch_picker.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < branch_nav.order.size():
			focus_branch(branch_nav.order[index])
	)
	Widgets.style_picker(branch_picker)
	add_child(branch_picker)
	node_picker = OptionButton.new()
	node_picker.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	node_picker.focus_mode = Control.FOCUS_NONE
	node_picker.add_theme_font_size_override("font_size", 12)
	node_picker.get_popup().add_theme_constant_override("v_separation", 40)
	node_picker.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < branch_nav.browse_ids.size():
			focus_node(branch_nav.browse_ids[index])
	)
	Widgets.style_picker(node_picker)
	add_child(node_picker)
	completion_button = _button("Inner circle / Earn every rank", false)
	completion_button.add_theme_font_size_override("font_size", 12)
	completion_button.pressed.connect(open_demo_message)
	return_area_button = _button("Return to Bramblewick", false)
	return_area_button.add_theme_font_size_override("font_size", 13)
	return_area_button.pressed.connect(func() -> void:
		if not _return_id.is_empty():
			travel_requested.emit(_return_id)
	)
	return_area_button.hide()
	argument_cards = ArgumentCards.new()
	argument_cards.name = "ArgumentCards"
	argument_cards.toggled.connect(func(argument: String) -> void: argument_toggled.emit(argument))
	argument_cards.hide()
	add_child(argument_cards)
	frame.build_completion()


func _detail_gap(height: float) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_box.add_child(gap)


func _label(value: String, font_size: int, color: Color, parent: Node = null) -> Label:
	return Widgets.label(parent if parent != null else self, value, font_size, color)


func _button(value: String, primary: bool, parent: Node = null) -> Button:
	return Widgets.button(parent if parent != null else self, value, primary)


func _layout() -> void:
	if not is_instance_valid(graph):
		return
	frame.place()
	branch_nav.fit()
	if not _view_adjusted:
		reset_view()
	queue_redraw()


func _layout_footer() -> void:
	frame.place_footer()


func _purchase_selected() -> void:
	if _state(selected_id) == "affordable":
		purchase_requested.emit(selected_id, _displayed_rank)
		update_state(_round_recruits)


func _on_visibility_changed() -> void:
	pointer.reset_gesture()
	hovered_id = ""
	core_hovered = false
	if not visible:
		dismiss_demo_message()
	if visible and _built:
		update_state(_round_recruits)


func _input(event: InputEvent) -> void:
	pointer.handle_input(event)


func set_pointer_input_enabled(value: bool) -> void:
	pointer.enabled = value
	pointer.reset_gesture()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pointer.reset_gesture()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	draw_rect(Rect2(Vector2(_detail_x - 24, 118), Vector2(size.x - _detail_x + 24, size.y - 118)), PANEL)
	draw_line(Vector2(40, 110), Vector2(_column_right, 110), Color("372344"), 1.0)
	draw_line(Vector2(_detail_x - 24, 135), Vector2(_detail_x - 24, size.y - 32), Color("483059"), 1.0)
	# Separates the selected inscription from the round controls below it.
	if is_instance_valid(next_button):
		draw_line(Vector2(_detail_x, next_button.position.y - 16), Vector2(size.x - 40, next_button.position.y - 16), Color("483059"), 1.0)


func graph_point(world: Vector2) -> Vector2:
	return graph.size * 0.5 + pan + world * zoom


func node_radius() -> float:
	return maxf(4.0, NODE_RADIUS * zoom)


func state_of(id: String) -> String:
	return _state(id)


func rank_of(id: String) -> int:
	return _rank(id)


func max_rank_of(id: String) -> int:
	return _max_rank(id)


func _draw_graph(canvas: Control) -> void:
	seal_art.draw_backdrop(canvas)
	node_art.draw_edges(canvas)
	seal_art.draw_core(canvas)
	for item in catalog:
		node_art.draw_node(canvas, item)
	labels.draw(canvas)
