extends Node2D
## Movement remains independent of round state and the ritual overlay.
const Gathering = preload("res://scripts/gathering.gd")
const Progression = preload("res://scripts/progression.gd")
const RitualScreen = preload("res://scripts/ritual_screen.gd")
const ROUND_SECONDS: float = 11.0
const START_POSITION := Vector2(780, 680)
const BASE_RUN_SPEED: float = 180.0

var persistence_enabled: bool = true
var save_path_override: String = ""
var catalog_ready: bool = false
var progression = Progression.new()
var groups: Array[Node2D] = []
var added_gatherings: Dictionary = {}
var seconds_left: float = ROUND_SECONDS
var round_active: bool = true
var round_recruits: int = 0
var nearest_group: Node2D = null
var coins: int:
	get:
		return progression.coins
var total_recruits: int:
	get:
		return progression.total_recruits
var round_number: int:
	get:
		return progression.round_number

@onready var player = $Actors/Player
var stats_label: Label
var round_label: Label
var context_label: Label
var save_label: Label
var hud_layout: Control
var ritual_screen: Control


func _ready() -> void:
	progression.save_enabled = persistence_enabled
	if not save_path_override.is_empty():
		progression.save_path = save_path_override
	catalog_ready = progression.load_catalog()
	if persistence_enabled and catalog_ready:
		progression.load_progress()
	if not catalog_ready:
		progression.save_enabled = false
		round_active = false
	$Village.build_props($Actors)
	_add_gathering("Wellside neighbours", Vector2(560, 540))
	_add_gathering("Market regulars", Vector2(1050, 480))
	_add_gathering("Garden club", Vector2(850, 850))
	_build_hud()
	_build_ritual()
	apply_upgrades()
	_update_hud()
	if not catalog_ready:
		set_ritual_visible(true)
	print("Small Following: starter scene ready.")


func _add_gathering(title: String, at: Vector2) -> void:
	var gathering := Gathering.new()
	gathering.group_name = title
	gathering.position = at
	gathering.recruited.connect(_on_recruited)
	$Actors.add_child(gathering)
	groups.append(gathering)


func _process(delta: float) -> void:
	advance_round(delta)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("next_round"):
		start_next_round()
	elif event.is_action_pressed("buy_upgrade") and ritual_screen.visible:
		purchase_upgrade(ritual_screen.selected_id, ritual_screen.get_selected_rank())
	elif event.is_action_pressed("toggle_ritual") and not round_active:
		set_ritual_visible(not ritual_screen.visible)


func advance_round(delta: float) -> void:
	nearest_group = null
	var closest_distance: float = player.speaking_radius
	for group in groups:
		var distance: float = player.global_position.distance_to(group.global_position)
		if distance <= closest_distance and group.recruits < Gathering.LISTENER_COUNT:
			closest_distance = distance
			nearest_group = group
		group.set_listening(false)
	if not round_active:
		return
	var usable_delta: float = minf(maxf(delta, 0.0), seconds_left)
	if is_instance_valid(nearest_group):
		nearest_group.set_listening(true)
		nearest_group.tick_persuasion(usable_delta, progression.speech_interval(), progression.conviction_per_phrase())
	seconds_left = maxf(0.0, seconds_left - usable_delta)
	if seconds_left <= 0.0:
		round_active = false
		for group in groups:
			group.set_listening(false)
		progression.save_progress()
		set_ritual_visible(true)


func _on_recruited(donation: int) -> void:
	progression.add_donation(donation, 1)
	round_recruits += 1


func purchase_upgrade(id: String, expected_rank: int = -1) -> bool:
	if round_active:
		return false
	var purchased: bool = progression.try_purchase(id, expected_rank)
	if purchased:
		apply_upgrades()
	ritual_screen.update_state(round_recruits)
	_update_hud()
	return purchased


func apply_upgrades() -> void:
	player.movement_speed = BASE_RUN_SPEED * progression.run_multiplier()
	for entry in [
		{"key": "meadow_unlock", "title": "Meadow neighbours", "at": Vector2(470, 800)},
		{"key": "east_unlock", "title": "East lane visitors", "at": Vector2(1250, 580)},
	]:
		if progression.has_unlock(entry.key) and not added_gatherings.has(entry.key):
			_add_gathering(entry.title, entry.at)
			added_gatherings[entry.key] = true


func set_ritual_visible(value: bool) -> void:
	ritual_screen.visible = value and not round_active
	hud_layout.visible = not ritual_screen.visible
	if ritual_screen.visible:
		ritual_screen.update_state(round_recruits)


func start_next_round() -> void:
	if round_active or not catalog_ready:
		return
	progression.round_number += 1
	progression.save_progress()
	seconds_left = ROUND_SECONDS
	round_recruits = 0
	nearest_group = null
	round_active = true
	for group in groups:
		group.reset_round()
	# Every round uses the same entrance; walking in menus does not grant a head start.
	player.position = START_POSITION
	player.get_node("Camera2D").reset_smoothing()
	set_ritual_visible(false)
	_update_hud()


func _build_ritual() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Ritual"
	canvas.layer = 5
	add_child(canvas)
	ritual_screen = RitualScreen.new()
	canvas.add_child(ritual_screen)
	ritual_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ritual_screen.configure(progression.catalog, progression)
	ritual_screen.purchase_requested.connect(purchase_upgrade)
	ritual_screen.next_round_requested.connect(start_next_round)
	ritual_screen.return_to_village_requested.connect(set_ritual_visible.bind(false))
	ritual_screen.hide()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	hud_layout = Control.new()
	hud_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud_layout)
	var heading := VBoxContainer.new()
	heading.position = Vector2(26, 20)
	hud_layout.add_child(heading)
	var title := _label("Small Following", 29, Color("#fff3d5"))
	title.add_theme_color_override("font_shadow_color", Color("#3f513d"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	heading.add_child(title)
	heading.add_child(_label("BRAMBLEWICK / a small beginning", 13, Color("#f5ebd0")))
	var status := _panel()
	hud_layout.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -390
	status.offset_right = -26
	status.offset_top = 22
	status.custom_minimum_size = Vector2(364, 62)
	var status_rows := VBoxContainer.new()
	status.add_child(status_rows)
	stats_label = _label("", 19)
	round_label = _label("", 14, Color("#d9dfc2"))
	status_rows.add_child(stats_label)
	status_rows.add_child(round_label)
	var help_panel := _panel()
	hud_layout.add_child(help_panel)
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help_panel.offset_left = 26
	help_panel.offset_top = -92
	help_panel.offset_bottom = -26
	help_panel.custom_minimum_size = Vector2(575, 66)
	var help_rows := VBoxContainer.new()
	help_panel.add_child(help_rows)
	context_label = _label("", 17)
	help_rows.add_child(context_label)
	help_rows.add_child(_label("WASD / arrows / left stick - Stand near a gathering to speak", 13, Color("#d9dfc2")))
	save_label = _label("", 13, Color("#ffe4a1"))
	canvas.add_child(save_label)
	save_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	save_label.offset_left = -590
	save_label.offset_right = -26
	save_label.offset_top = -28
	save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.26, 0.21, 0.94)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	return panel


func _label(value: String, font_size: int, color: Color = Color("#fff1d0")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _update_hud() -> void:
	stats_label.text = "%d donations    /    %d recruited" % [coins, total_recruits]
	round_label.text = "Round %d   /   %.1fs remaining" % [round_number, seconds_left]
	save_label.text = "Progress notice: see the ritual screen." if not progression.last_error.is_empty() else ""
	if not round_active:
		context_label.text = "Round complete - Tab: ritual / Enter: next round"
	elif is_instance_valid(nearest_group):
		context_label.text = "Speaking with %s..." % nearest_group.group_name
	else:
		context_label.text = "A little time. A few friendly faces."
