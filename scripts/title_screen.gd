extends Control
## Title and level shortcut presentation. Main owns saved access and travel.

signal continue_requested
signal level_requested(area_id: String)
signal settings_requested

const INK := Color("110d1c")
const LILAC := Color("d7b9ff")
const WHITE := Color("f1e5ff")
const MUTED := Color("aa96bb")
const GOLD := Color("dbb879")
const ACCESS_PASSWORD: String = "PLZKTKS"

var unlocked: bool = false
var current_area: String = "bramblewick"
var market_available: bool = false
var continue_button: Button
var password_input: LineEdit
var unlock_button: Button
var level_one_button: Button
var level_two_button: Button
var feedback_label: Label
var _level_choices: VBoxContainer
var _menu: VBoxContainer
var _heading: Label
var _subtitle: Label
var _journey_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	resized.connect(_layout)
	_layout()
	_refresh()


func configure(area_id: String, available: bool) -> void:
	current_area = area_id
	market_available = available
	if is_instance_valid(continue_button):
		_refresh()


func submit_password(value: String) -> bool:
	# Deliberately exact; this is a convenience shortcut, not account security.
	if value != ACCESS_PASSWORD:
		show_error("That password did not open the seal. Try again.")
		return false
	unlocked = true
	if is_instance_valid(feedback_label):
		feedback_label.text = "The seal is open. Choose either level."
		feedback_label.add_theme_color_override("font_color", GOLD)
		password_input.clear()
		password_input.release_focus()
		_refresh()
	return true


func show_error(message: String) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = message
		feedback_label.add_theme_color_override("font_color", Color("f0b7c4"))


func _refresh() -> void:
	continue_button.text = "Play / Continue"
	_journey_label.text = "Continue in " + ("Bellmarket" if current_area == "bellmarket" else "Bramblewick")
	if market_available and current_area != "bellmarket":
		_journey_label.text += " · Bellmarket is open"
	_level_choices.visible = unlocked
	_layout()


func _build_controls() -> void:
	_heading = _label("Small\nFollowing", 78, WHITE)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_heading)
	_subtitle = _label("A little voice. A growing circle.", 20, LILAC)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 14)
	add_child(_menu)
	_menu.add_child(_label("YOUR NEXT SMALL BEGINNING", 13, GOLD))
	_journey_label = _label("", 17, LILAC)
	_menu.add_child(_journey_label)
	continue_button = _button("Play / Continue", true)
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	_menu.add_child(continue_button)
	var settings: Button = _button("Settings", false)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	_menu.add_child(settings)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	_menu.add_child(spacer)
	_menu.add_child(_label("Have a password? Open the travel seal.", 15, MUTED))
	var password_row := HBoxContainer.new()
	password_row.add_theme_constant_override("separation", 10)
	_menu.add_child(password_row)
	password_input = LineEdit.new()
	password_input.placeholder_text = "Password"
	password_input.secret = true
	password_input.max_length = 40
	password_input.custom_minimum_size = Vector2(0, 48)
	password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	password_input.add_theme_font_size_override("font_size", 18)
	password_input.text_submitted.connect(submit_password)
	password_row.add_child(password_input)
	unlock_button = _button("Unlock", false)
	unlock_button.custom_minimum_size = Vector2(108, 48)
	unlock_button.pressed.connect(func() -> void: submit_password(password_input.text))
	password_row.add_child(unlock_button)
	feedback_label = _label("", 14, MUTED)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size.y = 40
	_menu.add_child(feedback_label)
	_level_choices = VBoxContainer.new()
	_level_choices.add_theme_constant_override("separation", 10)
	_menu.add_child(_level_choices)
	_level_choices.add_child(_label("CHOOSE YOUR LEVEL", 13, GOLD))
	level_one_button = _button("1 · Bramblewick", false)
	level_one_button.pressed.connect(_request_level.bind("bramblewick"))
	_level_choices.add_child(level_one_button)
	level_two_button = _button("2 · Bellmarket", false)
	level_two_button.pressed.connect(_request_level.bind("bellmarket"))
	_level_choices.add_child(level_two_button)
	var note: Label = _label("Your existing upgrades are kept. Each town has its own circle.", 13, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_level_choices.add_child(note)


func _request_level(area_id: String) -> void:
	if unlocked and area_id in ["bramblewick", "bellmarket"]:
		level_requested.emit(area_id)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", WHITE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("583478") if primary else Color("21172e")
		style.border_color = LILAC if state in ["hover", "focus"] else Color("795497")
		if state == "pressed":
			style.bg_color = Color("75459a")
		style.set_border_width_all(2 if primary else 1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 18
		style.content_margin_right = 18
		button.add_theme_stylebox_override(state, style)
	return button


func _layout() -> void:
	if not is_instance_valid(_menu):
		return
	var menu_width: float = minf(410, size.x * 0.36)
	_menu.position = Vector2(size.x * 0.62, 100 if unlocked else 174)
	_menu.size = Vector2(menu_width, 0)
	_heading.position = Vector2(32, 110)
	_heading.size = Vector2(size.x * 0.55, 200)
	_subtitle.position = Vector2(32, 320)
	_subtitle.size = Vector2(size.x * 0.55, 36)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	var at := Vector2(size.x * 0.30, size.y * 0.69)
	var radius: float = minf(size.x * 0.18, size.y * 0.23)
	for index in range(3):
		draw_arc(at, radius + index * 13, 0, TAU, 100, Color(LILAC, 0.09 + index * 0.025), 1, true)
	for index in range(40):
		var radial := Vector2.from_angle(index * TAU / 40.0)
		draw_line(at + radial * (radius + 32), at + radial * (radius + 37 + (6 if index % 5 == 0 else 0)), Color(GOLD, 0.24), 1, true)
	var constellation := PackedVector2Array()
	for index in range(6):
		constellation.append(at + Vector2.from_angle(-PI / 2 + index * TAU / 5) * radius)
	draw_polyline(constellation, Color(LILAC, 0.17), 1.2, true)
	for index in range(5):
		var point: Vector2 = constellation[index]
		draw_circle(point, 6, Color("52346d"))
		draw_arc(point, 9, 0, TAU, 24, Color(LILAC, 0.50), 1.2, true)
	# Original procedural portrait: broad soft robe, little hood, warm eyes.
	draw_set_transform(at + Vector2(0, 36), 0, Vector2.ONE * radius / 150.0)
	_draw_ellipse_shadow()
	draw_colored_polygon(PackedVector2Array([Vector2(-42, -54), Vector2(34, -54), Vector2(62, 61), Vector2(19, 69), Vector2(-9, 61), Vector2(-53, 67), Vector2(-69, 56)]), Color("65418b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -57), Vector2(36, -40), Vector2(57, 59), Vector2(22, 64)]), Color("8254a5"))
	draw_colored_polygon(PackedVector2Array([Vector2(-44, -59), Vector2(-34, -108), Vector2(3, -147), Vector2(41, -99), Vector2(48, -52), Vector2(2, -31)]), Color("9466b9"))
	draw_colored_polygon(PackedVector2Array([Vector2(-28, -71), Vector2(-20, -103), Vector2(3, -122), Vector2(26, -95), Vector2(30, -65), Vector2(3, -52)]), Color("24162e"))
	draw_circle(Vector2(-8, -84), 3.6, GOLD)
	draw_circle(Vector2(14, -84), 3.6, GOLD)
	draw_line(Vector2(-25, -39), Vector2(-39, 46), Color("b384ce"), 2, true)
	draw_circle(Vector2(7, -30), 5, GOLD)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(size.x * 0.585, 116), Vector2(size.x * 0.585, size.y - 110), Color(LILAC, 0.15), 1, true)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(42, size.y - 35), "WALK  ·  SPEAK  ·  GATHER  ·  GROW", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)


func _draw_ellipse_shadow() -> void:
	var points := PackedVector2Array()
	for index in range(40):
		var radial := Vector2.from_angle(index * TAU / 40.0)
		points.append(Vector2(radial.x * 82, 67 + radial.y * 15))
	draw_colored_polygon(points, Color("08060e"))
