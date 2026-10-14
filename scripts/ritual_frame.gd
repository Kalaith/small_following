extends RefCounted
## Where every ritual screen control sits, and the circle-complete overlay. The
## screen owns the controls; this only places and builds them.

const Style = preload("res://scripts/ritual_style.gd")
## Height of the argument card row the graph gives up at Quillmoor.
const CARD_ROW: float = 84.0

var screen: Control


func _init(owner_screen: Control) -> void:
	screen = owner_screen


func place() -> void:
	var size: Vector2 = screen.size
	var margin: float = 40.0
	var detail_width: float = clampf(size.x * 0.245, 255.0, 330.0)
	screen._detail_x = size.x - detail_width - margin
	screen._column_right = screen._detail_x - 48.0
	var detail_x: float = screen._detail_x
	var column_right: float = screen._column_right
	screen.graph.position = Vector2(24, 184)
	screen.graph.size = Vector2(maxf(280.0, column_right - 24.0), maxf(280.0, size.y - 304.0 - (CARD_ROW if screen.uni_circle else 0.0)))
	# Quillmoor's argument cards sit directly under the circle they change.
	screen.argument_cards.position = Vector2(margin, screen.graph.position.y + screen.graph.size.y + 4.0)
	screen.argument_cards.size = Vector2(column_right - margin, CARD_ROW - 8.0)
	screen.zoom_in_button.position = Vector2(column_right - 52, 122)
	screen.zoom_in_button.size = Vector2(52, 52)
	screen.zoom_out_button.position = Vector2(column_right - 112, 122)
	screen.zoom_out_button.size = Vector2(52, 52)
	screen.branch_bar.position = Vector2(margin, 122)
	screen.branch_bar.size = Vector2(column_right - 124 - margin, 52)
	screen.branch_picker.position = screen.branch_bar.position
	screen.branch_picker.size = Vector2(minf(430, screen.branch_bar.size.x), 52)
	screen.completion_button.position = Vector2(column_right - 226, size.y - 112)
	screen.completion_button.size = Vector2(226, 52)
	screen.node_picker.position = Vector2(margin, size.y - 112)
	screen.node_picker.size = Vector2(minf(440, screen.completion_button.position.x - 12 - margin), 52)
	screen._title_label.position = Vector2(margin, 43)
	screen._subtitle_label.position = Vector2(margin + 2.0, 23)
	screen.recenter_button.position = Vector2(column_right - 100, 52)
	screen.recenter_button.size = Vector2(100, 46)
	screen.focus_button.position = Vector2(column_right - 248, 52)
	screen.focus_button.size = Vector2(140, 46)
	screen._coins_label.position = Vector2(detail_x, 41)
	screen._recruits_label.position = Vector2(detail_x, 69)
	screen._lifetime_label.position = Vector2(detail_x, 98)
	screen.next_button.position = Vector2(detail_x, size.y - 170)
	screen.next_button.size = Vector2(detail_width, 50)
	screen.village_button.position = Vector2(detail_x, size.y - 112)
	screen.village_button.size = Vector2(detail_width, 50)
	screen._hint_label.position = Vector2(detail_x, size.y - 50)
	screen._hint_label.size = Vector2(detail_width, 36)
	screen._hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen._detail_box.position = Vector2(detail_x, 150)
	screen._detail_box.size = Vector2(detail_width, 0)
	place_footer()


func place_footer() -> void:
	if not is_instance_valid(screen.return_area_button):
		return
	var size: Vector2 = screen.size
	screen.return_area_button.position = Vector2(40, size.y - 50)
	screen.return_area_button.size = Vector2(200, 36)
	var legend: Label = screen._legend_label
	legend.text = "Diamond: locked   /   Hollow: needs resources   /   +: ready   /   Check: complete"
	legend.position = Vector2(256 if screen.away_circle else 40, size.y - 50)
	legend.size = Vector2(screen._column_right - legend.position.x, 36)
	var message_height: float = 390 if not screen._destination_id.is_empty() else 332
	screen._demo_panel.custom_minimum_size = Vector2(minf(600, size.x - 80), message_height)


## The circle-complete message: a shaded overlay with travel and keep-playing choices.
func build_completion() -> void:
	screen._demo_overlay = Control.new()
	var overlay: Control = screen._demo_overlay
	overlay.name = "DemoCompletion"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.01, 0.045, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var centering := CenterContainer.new()
	centering.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centering)
	screen._demo_panel = PanelContainer.new()
	centering.add_child(screen._demo_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Style.PANEL
	style.border_color = Style.VIOLET
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	screen._demo_panel.add_theme_stylebox_override("panel", style)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	screen._demo_panel.add_child(body)
	_centered_label(body, "THE CIRCLE IS COMPLETE", 13, Style.VIOLET)
	screen.demo_message_label = _centered_label(body, "This is the end of the demo", 30, Style.WHITE)
	screen._demo_description = _centered_label(body, "Every inscription is yours. You can keep playing in this village.", 17, Style.LILAC)
	screen.destination_button = screen._button("Travel", true, body)
	screen.destination_button.custom_minimum_size.y = 46
	screen.destination_button.pressed.connect(func() -> void:
		if screen.is_circle_complete() and not screen._destination_id.is_empty():
			screen.travel_requested.emit(screen._destination_id)
	)
	screen.destination_button.hide()
	screen.demo_continue_button = screen._button("Keep playing", true, body)
	screen.demo_continue_button.custom_minimum_size.y = 46
	screen.demo_continue_button.pressed.connect(screen.dismiss_demo_message)
	screen._demo_hint = screen._label("", 12, Style.MUTED, body)
	screen._demo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.hide()


func _centered_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label: Label = screen._label(value, font_size, color, parent)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
