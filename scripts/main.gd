extends Node2D
## Movement remains independent of round state and the ritual overlay.
const Gathering = preload("res://scripts/gathering.gd")
const Progression = preload("res://scripts/progression.gd")
const RitualScreen = preload("res://scripts/ritual_screen.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Helper = preload("res://scripts/helper.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const SettingsStore = preload("res://scripts/settings_store.gd")
const SettingsScreen = preload("res://scripts/settings_screen.gd")
const Keys = preload("res://scripts/key_bindings.gd")
const ROUND_SECONDS: float = 11.0
const START_POSITION := Vector2(780, 680)
const BASE_RUN_SPEED: float = 180.0

var persistence_enabled: bool = true
var save_path_override: String = ""
var catalog_ready: bool = false
var progression = Progression.new()
var game_audio = GameAudio.new()
var settings = SettingsStore.new()
var settings_path_override: String = ""
var settings_screen: Control
var settings_button: Button
var settings_timer: Timer
var groups: Array[Node2D] = []
var added_gatherings: Dictionary = {}
var encounter: Node2D = null
var helper: Node2D = null
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
var village_input: Node
var ritual_button: Button
var next_round_button: Button
var _village_blockers: Array[Control] = []


func _ready() -> void:
	# Existing isolated scene tests must also avoid the normal preferences file.
	settings.save_enabled = persistence_enabled and (save_path_override.is_empty() or not settings_path_override.is_empty())
	if not settings_path_override.is_empty():
		settings.path = settings_path_override
	settings.load_settings()
	Keys.apply(settings.key_bindings)
	game_audio.apply_preferences(settings.values)
	game_audio.name = "GameAudio"
	add_child(game_audio)
	game_audio.preferences_changed.connect(_audio_preferences_changed)
	player.moved.connect(game_audio.on_motion)
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
	_build_settings()
	village_input = preload("res://scripts/village_input.gd").new()
	add_child(village_input)
	if settings.values.fullscreen and not OS.has_feature("web"):
		set_fullscreen(true)
	apply_upgrades()
	_reset_encounter()
	_update_hud()
	if not catalog_ready:
		set_ritual_visible(true)
	print("Small Following: starter scene ready.")


func _add_gathering(title: String, at: Vector2, merchant: bool = false) -> void:
	var gathering := Gathering.new()
	gathering.group_name = title
	gathering.position = at
	if merchant:
		gathering.npc_type = "merchant"
		gathering.listener_count = Gathering.MERCHANT_COUNT
		gathering.conviction_required = Gathering.MERCHANT_CONVICTION
		gathering.donation = progression.merchant_donation()
	gathering.recruited.connect(_on_recruited)
	gathering.phrase_spoken.connect(game_audio.on_phrase)
	$Actors.add_child(gathering)
	groups.append(gathering)


func _process(delta: float) -> void:
	advance_round(delta)
	_update_hud()
	if DisplayServer.get_name() != "headless" and settings.values.fullscreen != is_fullscreen():
		settings.values.fullscreen = is_fullscreen()
		_queue_settings_save()
	if settings_screen.visible:
		_refresh_settings()


func _input(event: InputEvent) -> void:
	if settings_screen.visible and settings_screen.capture_key(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_settings"):
		if ritual_screen.demo_message_visible():
			ritual_screen.dismiss_demo_message()
		else:
			set_settings_visible(not settings_screen.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(not is_fullscreen())
		get_viewport().set_input_as_handled()
	elif settings_screen.visible and event.is_action_pressed("toggle_ritual") and not round_active:
		set_settings_visible(false)
		set_ritual_visible(false)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_audio"):
		game_audio.toggle_mute()
	elif event.is_action_pressed("toggle_voice"):
		game_audio.toggle_voice()
	elif settings_screen.visible:
		return
	elif event.is_action_pressed("next_round"):
		start_next_round()
	elif event.is_action_pressed("buy_upgrade") and ritual_screen.visible:
		purchase_upgrade(ritual_screen.selected_id, ritual_screen.get_selected_rank())
	elif event.is_action_pressed("toggle_ritual") and not round_active:
		set_ritual_visible(not ritual_screen.visible)


func is_fullscreen() -> bool:
	return get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]


func set_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
	settings.values.fullscreen = is_fullscreen()
	_queue_settings_save()


func set_settings_visible(value: bool) -> void:
	if is_instance_valid(village_input):
		village_input.cancel_gesture()
	settings_screen.cancel_capture()
	ritual_screen.set_pointer_input_enabled(not value)
	if value:
		ritual_screen.dismiss_demo_message()
	settings_screen.visible = value
	settings_button.visible = not value
	if value:
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null:
			focused.release_focus()
		_refresh_settings()
	elif not settings_timer.is_stopped():
		_save_settings()


func _audio_preferences_changed() -> void:
	for channel in game_audio.volumes:
		settings.values[channel] = game_audio.volumes[channel]
	settings.values.muted = game_audio.muted
	settings.values.voice_muted = game_audio.voice_muted
	_queue_settings_save()


func _queue_settings_save() -> void:
	settings_timer.start()
	_refresh_settings()


func _save_settings() -> void:
	settings_timer.stop()
	settings.save_settings()
	_refresh_settings()


func _refresh_settings() -> void:
	var message: String = settings.last_error
	if message.is_empty():
		message = "Saving preferences..." if not settings_timer.is_stopped() else "Preferences saved automatically."
	settings_screen.refresh(game_audio, is_fullscreen(), message)
	settings_screen.refresh_bindings(settings.key_bindings)


func _exit_tree() -> void:
	if is_instance_valid(settings_timer) and not settings_timer.is_stopped():
		settings.save_settings()


func exit_game() -> void:
	if OS.has_feature("web"):
		return
	_save_settings()
	progression.save_progress()
	get_tree().quit()


func _build_settings() -> void:
	settings_timer = Timer.new()
	settings_timer.one_shot = true
	settings_timer.wait_time = 0.4
	settings_timer.timeout.connect(_save_settings)
	add_child(settings_timer)
	var canvas := CanvasLayer.new()
	canvas.name = "Settings"
	canvas.layer = 10
	add_child(canvas)
	settings_button = Button.new()
	settings_button.text = "Settings  ·  Esc"
	settings_button.focus_mode = Control.FOCUS_NONE
	canvas.add_child(settings_button)
	settings_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	settings_button.offset_left = -176
	settings_button.offset_right = -26
	settings_button.offset_top = 98
	settings_button.offset_bottom = 154
	settings_button.pressed.connect(set_settings_visible.bind(true))
	settings_screen = SettingsScreen.new()
	canvas.add_child(settings_screen)
	for state in ["normal", "hover", "pressed"]:
		settings_button.add_theme_stylebox_override(state, settings_screen.close_button.get_theme_stylebox(state))
	settings_screen.close_requested.connect(set_settings_visible.bind(false))
	settings_screen.exit_requested.connect(exit_game)
	settings_screen.volume_changed.connect(game_audio.set_volume)
	settings_screen.mute_requested.connect(game_audio.toggle_mute)
	settings_screen.voice_mute_requested.connect(game_audio.toggle_voice)
	settings_screen.fullscreen_requested.connect(set_fullscreen)
	settings_screen.binding_requested.connect(_rebind_key)
	settings_screen.reset_keys_requested.connect(_reset_keys)
	_refresh_settings()


func _rebind_key(action: String, slot: int, code: int) -> void:
	var error: String = settings.rebind(action, slot, code)
	if not error.is_empty():
		settings_screen.binding_message.text = error
		return
	settings_screen.cancel_capture()
	settings_screen.binding_message.text = "%s: %s" % [Keys.ACTIONS[action], Keys.key_name(code)]
	_keys_changed()


func _reset_keys() -> void:
	settings.reset_keys()
	settings_screen.binding_message.text = "Default keys restored."
	_keys_changed()


func _keys_changed() -> void:
	_queue_settings_save()
	ritual_screen.update_state(round_recruits)
	_update_hud()


func advance_round(delta: float) -> void:
	game_audio.advance_time(delta)
	nearest_group = null
	var closest_distance: float = player.speaking_radius
	for group in groups:
		var distance: float = player.global_position.distance_to(group.global_position)
		if distance <= closest_distance and group.recruits < group.listener_count:
			closest_distance = distance
			nearest_group = group
		group.set_listening(false)
	if not round_active:
		game_audio.stop_speech()
		return
	var usable_delta: float = minf(maxf(delta, 0.0), seconds_left)
	var speaking_to_opponent: bool = false
	if is_instance_valid(encounter) and not encounter.defeated:
		var speech_delta: float = encounter.advance_arrival(usable_delta)
		speaking_to_opponent = encounter.arrived and player.global_position.distance_to(encounter.global_position) <= player.speaking_radius
		encounter.advance_speech(speech_delta, speaking_to_opponent, progression.speech_interval(), progression.encounter_conviction(str(Encounter.PROFILES[encounter.stage].id)))
	if speaking_to_opponent:
		nearest_group = null
	if is_instance_valid(nearest_group):
		nearest_group.set_listening(true)
		nearest_group.tick_persuasion(usable_delta, progression.speech_interval(), progression.conviction_for(nearest_group.npc_type))
	elif not speaking_to_opponent:
		game_audio.stop_speech()
	if is_instance_valid(helper):
		helper.set_active(true)
		helper.advance(usable_delta, groups)
	seconds_left = maxf(0.0, seconds_left - usable_delta)
	if seconds_left <= 0.0:
		round_active = false
		game_audio.stop_speech()
		if is_instance_valid(helper):
			helper.set_active(false)
		for group in groups:
			group.set_listening(false)
		progression.save_progress()
		set_ritual_visible(true)


func _reset_encounter() -> void:
	if is_instance_valid(encounter):
		encounter.get_parent().remove_child(encounter)
		encounter.queue_free()
	encounter = null
	if not progression.has_unlock("encounter_unlock") or progression.map_complete():
		return
	encounter = Encounter.new()
	encounter.stage = progression.encounter_stage
	encounter.convinced.connect(_on_encounter_convinced)
	encounter.phrase_spoken.connect(game_audio.on_phrase)
	$Actors.add_child(encounter)


func _on_encounter_convinced(stage: int) -> void:
	if round_active and progression.complete_encounter(stage):
		round_recruits += 1
		var popup = preload("res://scripts/donation_popup.gd").new()
		popup.amount = progression.ENCOUNTER_REWARDS[stage]
		popup.position = Vector2(52, -80)
		encounter.add_child(popup)


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
	if progression.has_unlock("merchant_unlock") and not added_gatherings.has("merchant_unlock"):
		_add_gathering("Travelling merchants", Vector2(1020, 650), true)
		added_gatherings["merchant_unlock"] = true
	for group in groups:
		if group.npc_type == "merchant":
			group.donation = progression.merchant_donation()
	if progression.has_unlock("helper_unlock") and not is_instance_valid(helper):
		helper = Helper.new()
		$Actors.add_child(helper)
		helper.configure_navigation($Actors)
		helper.reset_round(START_POSITION)


func set_ritual_visible(value: bool) -> void:
	if is_instance_valid(village_input):
		village_input.cancel_gesture()
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
	player.clear_walk_target()
	player.position = START_POSITION
	game_audio.reset_motion()
	game_audio.stop_speech()
	if is_instance_valid(helper):
		helper.reset_round(START_POSITION)
	_reset_encounter()
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
	_village_blockers.append(heading)
	heading.position = Vector2(26, 20)
	hud_layout.add_child(heading)
	var title := _label("Small Following", 29, Color("#fff3d5"))
	title.add_theme_color_override("font_shadow_color", Color("#3f513d"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	heading.add_child(title)
	heading.add_child(_label("BRAMBLEWICK / a small beginning", 13, Color("#f5ebd0")))
	var status := _panel()
	_village_blockers.append(status)
	hud_layout.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
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
	_village_blockers.append(help_panel)
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
	help_rows.add_child(_label("Tap / click to walk; tap yourself to stop. Keys / stick also work.", 13, Color("#d9dfc2")))
	ritual_button = _village_button("Ritual circle", -422, -226)
	ritual_button.pressed.connect(set_ritual_visible.bind(true))
	next_round_button = _village_button("Next round", -214, -26)
	next_round_button.pressed.connect(start_next_round)
	save_label = _label("", 13, Color("#ffe4a1"))
	canvas.add_child(save_label)
	save_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	save_label.offset_left = -590
	save_label.offset_right = -26
	save_label.offset_top = -28
	save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_village_blockers.append(save_label)


func _village_button(caption: String, left: float, right: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	hud_layout.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = left
	button.offset_right = right
	button.offset_top = -94
	button.offset_bottom = -30
	_village_blockers.append(button)
	return button


func village_tap_available(at: Vector2) -> bool:
	if ritual_screen.visible or settings_screen.visible:
		return false
	if settings_button.is_visible_in_tree() and settings_button.get_global_rect().has_point(at):
		return false
	for control in _village_blockers:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(at):
			return false
	return get_viewport().get_visible_rect().has_point(at)


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
	ritual_button.visible = not round_active
	next_round_button.visible = not round_active
	stats_label.text = "%d donations / %d recruits available" % [coins, progression.available_recruits]
	round_label.text = "Round %d   /   %.1fs remaining" % [round_number, seconds_left]
	save_label.text = "Progress notice: see the ritual screen." if not progression.last_error.is_empty() else ""
	if progression.map_complete():
		context_label.text = "Bramblewick complete!" + ("  Choose Ritual circle or Next round." if not round_active else "  Enjoy the village.")
	elif not round_active:
		context_label.text = "Round complete - Ritual circle / Next round"
	elif is_instance_valid(encounter) and not encounter.defeated:
		context_label.text = "Convince %s in the town center" % Encounter.PROFILES[encounter.stage].title
	elif is_instance_valid(nearest_group):
		context_label.text = "Speaking with %s..." % nearest_group.group_name
	else:
		context_label.text = "Walk around props; stand near a gathering to speak."
