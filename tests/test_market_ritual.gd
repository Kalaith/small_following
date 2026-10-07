extends SceneTree
## Market circle UI and travel intents use in-memory progression only.
const Progression = preload("res://scripts/progression.gd")
const Ritual = preload("res://scripts/ritual_screen.gd")
const Fixture = preload("res://tests/fixtures/ritual_fixture.gd")
var failures: int = 0
var checks: int = 0
var travel_requests: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("MARKET RITUAL: " + description)


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var state := Progression.new()
	state.save_enabled = false
	check(state.load_catalog(), "production catalog loads")
	state.active_area = "bellmarket"
	state.catalog = state.catalog_for_area("bellmarket")
	for item in state.catalog_for_area("bramblewick"):
		state.purchased[item.id] = state.max_rank(item.id)
	state.coins = 120
	var screen := Ritual.new()
	screen.configure(state.catalog, state)
	root.add_child(screen)
	screen.travel_requested.connect(func(area_id: String) -> void: travel_requests.append(area_id))
	await process_frame
	check(screen.node_positions.size() == 30 and screen.market_circle, "market uses only its separate thirty-node circle")
	check(screen.get_branch_summaries().size() == 5, "five branches are independently browsable")
	for branch in screen.get_branch_summaries():
		check(branch.available == 1 and branch.count == 6, "each six-node branch offers one affordable root")
		for id in branch.ids:
			screen.focus_node(id)
			check(screen.selected_id == id and screen.hit_test(screen.world_to_screen(screen.nodes_position(id))) == id, "branch nodes remain selectable: " + id)
			check(not screen._effect_label.text.is_empty(), "market selection describes its current and next effect: " + id)
	var minimum_separation: float = INF
	for id in screen.node_positions:
		screen.reset_view()
		screen.focus_node(id)
		screen.zoom_at(screen.world_to_screen(screen.nodes_position(id)), 1.5)
		screen.pan_by(Vector2(33, -21))
		check(screen.hit_test(screen.world_to_screen(screen.nodes_position(id))) == id, "market picking follows panning and zooming: " + id)
		for other_id in screen.node_positions:
			if id != other_id:
				minimum_separation = minf(minimum_separation, screen.nodes_position(id).distance_to(screen.nodes_position(other_id)))
	check(minimum_separation > 60.0, "thirty market nodes retain separated silhouettes")
	check(screen.return_area_button.visible, "market always offers return travel")
	screen.return_area_button.pressed.emit()
	check(travel_requests == ["bramblewick"], "return control emits travel intent")
	check(not screen.open_demo_message(), "incomplete market centre remains sealed")
	var market_catalog: Array = state.catalog
	state.active_area = "bramblewick"
	state.catalog = state.catalog_for_area("bramblewick")
	state.purchased.erase("talk_6")
	screen.configure(state.catalog, state)
	screen.configure_destination("bellmarket", "Bellmarket")
	screen.destination_button.pressed.emit()
	check(travel_requests.size() == 1, "destination signal cannot bypass incomplete ranks")
	for item in state.catalog:
		state.purchased[item.id] = state.max_rank(item.id)
	screen.update_state()
	check(screen.open_demo_message() and screen.destination_button.visible and screen.demo_message_label.text.contains("Bellmarket"), "completed village centre presents real destination")
	await process_frame
	await process_frame
	check(Rect2(Vector2.ZERO, screen.size).encloses(screen._demo_panel.get_global_rect()), "destination panel fits within the viewport")
	screen.destination_button.pressed.emit()
	check(travel_requests == ["bramblewick", "bellmarket"], "completed centre emits destination intent")
	screen.configure_destination()
	check(screen.open_demo_message() and screen.demo_message_label.text == "This is the end of the demo", "unconfigured standalone ritual retains demo compatibility")
	state.active_area = "bellmarket"
	state.catalog.assign(market_catalog)
	screen.configure(state.catalog, state)
	for item in state.catalog:
		state.purchased[item.id] = 1
	screen.update_state()
	check(screen.is_circle_complete() and screen.open_demo_message() and screen.demo_message_label.text.contains("Bellmarket"), "market completion stays specific to its own circle")
	screen.configure(Fixture.build(), state)
	check(screen.node_positions.size() == 144 and not screen.market_circle, "separate large fixture still uses scalable fallback")
	screen.focus_node("fixture_12_11")
	check(screen.hit_test(screen.world_to_screen(screen.nodes_position("fixture_12_11"))) == "fixture_12_11", "fixture distant node transform remains usable")
	var renamed_market := Progression.new()
	renamed_market.save_enabled = false
	renamed_market.catalog = [{"id": "not_prefixed_at_all", "title": "Renamed", "area": "bellmarket", "branch": "market_talk", "ring": 1, "cost": 1, "requires": [], "effect": {"speech_speed_add": 0.1}}]
	screen.configure(renamed_market.catalog, renamed_market)
	check(screen.market_circle, "market presentation follows the validated area field, not a catalog[0] ID prefix")
	var disguised_village := Progression.new()
	disguised_village.save_enabled = false
	disguised_village.catalog = [{"id": "market_shaped_village_node", "title": "Disguised", "area": "bramblewick", "branch": "talk", "ring": 1, "cost": 1, "requires": [], "effect": {"speech_speed_add": 0.1}}]
	screen.configure(disguised_village.catalog, disguised_village)
	check(not screen.market_circle, "a village node whose ID happens to start with market_ does not trigger market presentation")
	screen.queue_free()
	await process_frame
	print("MARKET RITUAL RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
