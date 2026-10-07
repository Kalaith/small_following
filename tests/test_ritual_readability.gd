extends SceneTree
## Readability and navigation checks use the same graph model and inputs as drawing.
## All progression is in memory; this suite never opens the player's save.
const Fixture = preload("res://tests/fixtures/ritual_fixture.gd")
const Layout = preload("res://scripts/ritual_layout.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("READABILITY: " + description)


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.advance_round(100.0)
	await process_frame
	var screen = scene.ritual_screen
	var original_catalog: String = JSON.stringify(scene.progression.catalog)
	var original_purchases: Dictionary = scene.progression.purchased.duplicate(true)
	var original_coins: int = scene.coins
	_test_constellations(screen, scene.progression.catalog)
	_test_prerequisite_routes(screen, scene.progression.catalog)
	_test_paths_and_hover(screen)
	_test_navigation_controls(screen)
	_test_keyboard_gamepad_navigation(screen)
	_test_overview_control(screen)
	_test_transforms(screen)
	_test_labels(screen)
	await _test_large_graph(screen)
	screen.configure(scene.progression.catalog, scene.progression)
	check(screen.node_positions.size() == 32, "restoring production data preserves all thirty-two upgrades")
	check(JSON.stringify(scene.progression.catalog) == original_catalog, "view layout never mutates catalog definitions")
	check(scene.progression.purchased == original_purchases and scene.coins == original_coins, "view navigation never changes ranks or donations")
	scene.queue_free()
	await process_frame
	print("READABILITY RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_constellations(screen, catalog: Array) -> void:
	var directions: Dictionary = {
		"talk": Vector2.UP, "run": Vector2.LEFT, "persuade": Vector2.RIGHT,
		"gather": Vector2.from_angle(deg_to_rad(45.0)),
		"helper": Vector2.from_angle(deg_to_rad(135.0)),
		"merchant": Vector2.from_angle(deg_to_rad(-135.0)),
		"trial": Vector2.from_angle(deg_to_rad(-45.0)),
		"faith": Vector2.DOWN,
	}
	var angles: Array[float] = []
	var minimum_spacing: float = INF
	var center_clearance: float = INF
	var outer_extent: float = 0.0
	for id in screen.node_positions:
		var point: Vector2 = screen.node_positions[id]
		angles.append(fposmod(point.angle(), TAU))
		center_clearance = minf(center_clearance, point.length())
		outer_extent = maxf(outer_extent, point.length())
		for other in screen.node_positions:
			if id != other:
				minimum_spacing = minf(minimum_spacing, point.distance_to(screen.node_positions[other]))
	angles.sort()
	var widest_gap: float = 0.0
	for index in range(angles.size()):
		widest_gap = maxf(widest_gap, fposmod(angles[(index + 1) % angles.size()] - angles[index], TAU))
	check(rad_to_deg(widest_gap) <= 40.0, "authored constellations occupy the complete circle rather than one crowded arc")
	check(minimum_spacing >= 80.0, "production nodes retain clear silhouette and hit-target separation")
	check(center_clearance >= 140.0, "real upgrade nodes leave room around the central medallion")
	check(outer_extent <= 560.0, "all production upgrades fit within the composed seal")
	for branch in directions:
		var coherent: bool = true
		for item in catalog:
			if item.branch != branch:
				continue
			var point: Vector2 = screen.node_positions[item.id]
			coherent = coherent and point.normalized().dot(directions[branch]) > 0.70
		check(coherent, "constellation retains its broad branch direction: " + branch)
	screen.clear_selection()
	var edges: Array = screen.get_visible_edges()
	var paths_clear: bool = true
	for edge in edges:
		var start: Vector2 = screen.node_positions[edge.from]
		var end: Vector2 = screen.node_positions[edge.to]
		for id in screen.node_positions:
			if id == edge.from or id == edge.to:
				continue
			var point: Vector2 = screen.node_positions[id]
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, start, end)
			paths_clear = paths_clear and closest.distance_to(point) >= 36.0
	check(paths_clear, "main prerequisite paths do not run through unrelated upgrade silhouettes")
	for factor in [0.7, 1.0, 1.7]:
		var reachable: bool = true
		for id in screen.node_positions:
			screen.focus_node(id)
			var point: Vector2 = screen.world_to_screen(screen.node_positions[id])
			screen.zoom_at(point, factor)
			screen.pan_by(Vector2(27, -19))
			point = screen.world_to_screen(screen.node_positions[id])
			reachable = reachable and screen.hit_test(point) == id
		check(reachable, "every authored node remains pickable after focus, zoom and pan %.1f" % factor)


func _test_prerequisite_routes(screen, catalog: Array) -> void:
	var topology_preserved: bool = true
	var nodes_clear: bool = true
	var core_clear: bool = true
	var tips_clear: bool = true
	var simple_paths: bool = true
	for item in catalog:
		var target: String = str(item.id)
		for required in item.get("requires", []):
			var source: String = str(required)
			var points: PackedVector2Array = Layout.edge_path(source, target, screen.node_positions)
			topology_preserved = topology_preserved and points.size() >= 2 and points[0] == screen.node_positions[source] and points[-1] == screen.node_positions[target]
			simple_paths = simple_paths and points.size() <= 4
			tips_clear = tips_clear and points[0].distance_to(points[1]) > 40.0 and points[-1].distance_to(points[-2]) > 40.0
			for segment in range(points.size() - 1):
				var start: Vector2 = points[segment]
				var end: Vector2 = points[segment + 1]
				core_clear = core_clear and Geometry2D.get_closest_point_to_segment(Vector2.ZERO, start, end).length() >= 90.0
				for id in screen.node_positions:
					if id == source or id == target:
						continue
					var point: Vector2 = screen.node_positions[id]
					var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, start, end)
					nodes_clear = nodes_clear and closest.distance_to(point) >= 36.0
	check(topology_preserved, "every routed prerequisite keeps its actual source and target")
	check(nodes_clear, "all prerequisite routes, including crosslinks, clear unrelated upgrade icons")
	check(core_clear, "prerequisite routes leave the central medallion unobstructed")
	check(tips_clear, "routed link ends leave room for node rims and direction arrows")
	check(simple_paths, "authored prerequisite routes use at most two purposeful bends")
	var fixture: Array = Fixture.build()
	var fixture_positions: Dictionary = Layout.build(fixture)
	var direct_fallback: bool = true
	for item in fixture:
		for required in item.get("requires", []):
			var points: PackedVector2Array = Layout.edge_path(str(required), str(item.id), fixture_positions)
			direct_fallback = direct_fallback and points.size() == 2 and points[0] == fixture_positions[required] and points[-1] == fixture_positions[item.id]
	check(direct_fallback, "unknown fixture prerequisites retain their direct source-to-target routes")


func _test_paths_and_hover(screen) -> void:
	screen.reset_view()
	screen.clear_selection()
	var edges: Array = screen.get_visible_edges()
	var cross_count: int = 0
	for edge in edges:
		if edge.kind == "cross":
			cross_count += 1
	check(cross_count == 0, "unfocused overview hides cross-branch links")
	check(_find_edge(edges, "talk_3", "talk_4").size() > 0 and _find_edge(edges, "run_4", "run_5").size() > 0, "main branch progress remains connected in overview")
	screen.select_node("east_1")
	edges = screen.get_visible_edges()
	var cross: Dictionary = _find_edge(edges, "talk_4", "east_1")
	check(not cross.is_empty() and cross.kind == "cross" and cross.relevant, "selecting East Lane reveals its cross-branch prerequisite")
	check(not _find_edge(edges, "meadow_1", "east_1").is_empty(), "selected path includes the village progression edge")
	check(_find_edge(edges, "talk_1", "talk_2").get("relevant", false) and _find_edge(edges, "persuade_2", "persuade_3").get("relevant", false) and _find_edge(edges, "persuade_3", "meadow_1").get("relevant", false), "selection highlights recursive prerequisite ancestry across branches")
	var unrelated: Dictionary = _find_edge(edges, "run_1", "run_2")
	check(not unrelated.is_empty() and not unrelated.relevant and float(unrelated.alpha) < float(cross.get("alpha", 0.0)), "unrelated main paths dim below the selected prerequisite path")
	check(screen._status_label.text.contains("Meadow Invitations") and screen._status_label.text.contains("Quickened Words IV"), "right panel explicitly names both missing East Lane requirements")
	var selected_before: String = screen.selected_id
	var title_before: String = screen._node_title.text
	var effect_before: String = screen._effect_label.text
	_hover_node(screen, "talk_5")
	check(screen._hovered_id == "talk_5", "actual mouse motion resolves the hovered node")
	check(screen.selected_id == selected_before and screen._node_title.text == title_before and screen._effect_label.text == effect_before, "hover previews paths without replacing selected details")
	check(not _find_edge(screen.get_visible_edges(), "east_1", "talk_5").is_empty(), "hover reveals Words V cross-branch requirement")
	screen.graph.mouse_exited.emit()
	check(screen._hovered_id.is_empty(), "leaving graph clears the hover preview")
	check(screen.selected_id == selected_before and _find_edge(screen.get_visible_edges(), "east_1", "talk_5").is_empty(), "mouse exit returns to the selected path")
	screen.clear_selection()
	check(screen.purchase_button.disabled, "clearing selection cannot leave a purchase enabled")


func _test_navigation_controls(screen) -> void:
	var summaries: Array = screen.get_branch_summaries()
	var represented: int = 0
	for summary in summaries:
		represented += int(summary.count)
	check(summaries.size() == 8 and represented == 32, "branch navigation accounts for every production upgrade")
	check(screen.branch_picker.visible and screen.branch_picker.item_count == 8, "eight branches use the visible branch dropdown")
	screen.branch_picker.item_selected.emit(screen._branch_order.find("run"))
	check(screen.selected_id == "run_1" and screen._node_title.text.contains("Footsteps"), "branch button focuses an available progression choice and refreshes details")
	var target_index: int = _find_item(screen.node_picker, "run_5")
	check(target_index >= 0, "node picker offers the distant tier without requiring a tiny hit target")
	if target_index >= 0:
		screen.node_picker.item_selected.emit(target_index)
		check(screen.selected_id == "run_5", "node picker signal selects the requested distant upgrade")
		screen.pan_by(Vector2(1300, 1000))
		screen.focus_button.pressed.emit()
		check(screen.hit_test(screen.world_to_screen(screen.node_positions["run_5"])) == "run_5", "focus selected button recovers an offscreen selection")


func _test_keyboard_gamepad_navigation(screen) -> void:
	# Keyboard/gamepad graph traversal has no pointer or hit-test geometry to
	# drive; these check navigate() directly against the real authored seal.
	screen.clear_selection()
	screen.navigate(Vector2.UP)
	check(screen.selected_id == "talk_4", "pressing up from the unselected centre enters the most up-aligned real node")
	screen.clear_selection()
	screen.navigate(Vector2.DOWN)
	check(screen.selected_id == "sermon_1", "pressing down from the unselected centre enters the faith branch")
	screen.clear_selection()
	screen.navigate(Vector2.LEFT)
	check(screen.selected_id == "run_2", "pressing left from the unselected centre enters the running branch")
	screen.clear_selection()
	screen.navigate(Vector2.RIGHT)
	check(screen.selected_id == "persuade_1", "pressing right from the unselected centre enters the conviction branch")
	screen.focus_node("talk_1")
	screen.navigate(Vector2.UP)
	var reached: String = screen.selected_id
	check(reached != "talk_1" and screen._by_id.has(reached), "navigating up from a selected node moves to a different real node")
	screen.navigate(Vector2.UP)
	check(screen.selected_id == reached, "repeating the same direction at the accessible edge holds the current selection instead of erroring")
	screen.navigate(Vector2.ZERO)
	check(screen.selected_id == reached, "a zero direction is a no-op")


func _test_overview_control(screen) -> void:
	screen.reset_view()
	var overview_zoom: float = screen.zoom
	var original_coins: int = screen._progression.coins
	screen._progression.coins = 6
	screen.focus_node("run_1")
	check(not screen.purchase_button.disabled, "affordable selection enables purchase before entering overview")
	_hover_node(screen, "run_1")
	screen.pan_by(Vector2(420, -320))
	screen.overview_button.pressed.emit()
	check(screen.selected_id.is_empty() and screen._hovered_id.is_empty(), "overview button clears both selection and hover")
	check(screen.pan.is_zero_approx() and is_equal_approx(screen.zoom, overview_zoom), "overview button restores the complete fitted graph")
	check(screen.branch_picker.selected == -1 and screen.branch_picker.text.contains("Browse"), "overview branch selector does not imply a selected branch")
	check(screen.purchase_button.disabled and screen.get_selected_rank() == 0, "overview button removes the previous purchasable selection")
	check(not screen._rank_label.visible and not screen._branch_label.visible, "overview hides empty rank and branch readouts")
	screen._progression.coins = original_coins
	screen.update_state()


func _test_transforms(screen) -> void:
	for factor in [0.65, 1.0, 1.8]:
		screen.reset_view()
		screen.focus_node("run_4")
		var point: Vector2 = screen.world_to_screen(screen.node_positions["run_4"])
		var anchor: Vector2 = point + Vector2(19, -13)
		var before: Vector2 = screen.screen_to_world(anchor)
		screen.zoom_at(anchor, factor)
		check(screen.screen_to_world(anchor).distance_to(before) < 0.01, "pointer anchor survives zoom factor %.2f" % factor)
		screen.pan_by(Vector2(43, -29))
		point = screen.world_to_screen(screen.node_positions["run_4"])
		check(screen.hit_test(point) == "run_4", "drawn node is pickable after zoom and pan %.2f" % factor)
		screen.select_node("talk_1")
		_click_node(screen, "run_4")
		check(screen.selected_id == "run_4", "actual transformed click selects intended node %.2f" % factor)
		screen.recenter_button.pressed.emit()
		check(screen.pan.is_zero_approx() and screen.selected_id == "run_4", "recenter removes pan while retaining selection %.2f" % factor)
		screen.clear_selection()


func _test_labels(screen) -> void:
	screen.overview_button.pressed.emit()
	var bounds: Dictionary = screen.label_bounds()
	var overlap: bool = false
	var ids: Array = bounds.keys()
	for index in range(ids.size()):
		for other in range(index + 1, ids.size()):
			if Rect2(bounds[ids[index]]).intersects(Rect2(bounds[ids[other]])):
				overlap = true
	check(not overlap, "production overview graph labels do not overlap")
	check(bounds.size() > 0, "production overview retains useful graph labels")


func _test_large_graph(screen) -> void:
	var fixture = load("res://scripts/progression.gd").new()
	fixture.save_enabled = false
	fixture.catalog = Fixture.build()
	fixture.coins = 1000
	screen.configure(fixture.catalog, fixture)
	screen.overview_button.pressed.emit()
	await process_frame
	check(screen.node_positions.size() == 144, "large fixture retains all 144 interactive nodes")
	var distinct: Dictionary = {}
	var reachable: bool = true
	for item in fixture.catalog:
		var point: Vector2 = screen.node_positions[item.id]
		distinct[point] = true
		screen.focus_node(item.id)
		if screen.hit_test(screen.world_to_screen(point)) != item.id:
			reachable = false
	check(distinct.size() == 144, "large fixture does not stack distinct upgrades")
	check(reachable, "every fixture upgrade can be focused and selected")
	screen.overview_button.pressed.emit()
	var overview_zoom: float = screen.zoom
	var overview_labels: int = screen.label_bounds().size()
	var branch_index: int = _find_item(screen.branch_picker, "test_11")
	check(screen.branch_picker.visible and branch_index >= 0, "large overview exposes every branch in the navigation dropdown")
	if branch_index >= 0:
		screen.branch_picker.item_selected.emit(branch_index)
	else:
		screen.focus_branch("test_11")
	check(screen.zoom > overview_zoom, "branch navigation expands the overview into readable detail")
	check(screen.label_bounds().size() > 0, "branch focus exposes node labels")
	check(overview_labels < 144, "large overview suppresses the wall of individual labels")
	screen.focus_node("fixture_1_6")
	var walked_all_rings: bool = true
	for ring in range(2, 13):
		screen.navigate(Vector2.DOWN)
		if screen.selected_id != "fixture_%d_6" % ring:
			walked_all_rings = false
	check(walked_all_rings and screen.selected_id == "fixture_12_6", "repeated directional presses walk the separate fixture outward one ring at a time")
	screen.navigate(Vector2.DOWN)
	check(screen.selected_id == "fixture_12_6", "holding the direction at the outermost fixture ring does not error or wrap")
	screen.focus_node("fixture_12_11")
	check(screen.selected_id == "fixture_12_11" and screen.hit_test(screen.world_to_screen(screen.node_positions["fixture_12_11"])) == "fixture_12_11", "distant selected node remains reachable after branch navigation")
	screen.recenter_button.pressed.emit()
	check(screen.pan.is_zero_approx() and is_equal_approx(screen.zoom, overview_zoom), "large graph recenter restores complete overview")


func _find_edge(edges: Array, source: String, target: String) -> Dictionary:
	for edge in edges:
		if edge.from == source and edge.to == target:
			return edge
	return {}


func _find_item(picker: OptionButton, id: String) -> int:
	for index in range(picker.item_count):
		if str(picker.get_item_metadata(index)) == id:
			return index
	return -1


func _hover_node(screen, id: String) -> void:
	var event := InputEventMouseMotion.new()
	event.position = screen.world_to_screen(screen.node_positions[id]) - screen.graph.global_position
	screen.graph._gui_input(event)


func _click_node(screen, id: String) -> void:
	var event := InputEventMouseButton.new()
	event.position = screen.world_to_screen(screen.node_positions[id]) - screen.graph.global_position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	screen.graph._gui_input(event)
	event.pressed = false
	screen.graph._gui_input(event)
