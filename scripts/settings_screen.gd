extends Control
## A focused utility page over the current village or ritual; never pauses play.
signal close_requested
signal volume_changed(channel: String, value: float)
signal mute_requested
signal voice_mute_requested
signal fullscreen_requested(value: bool)

var sliders: Dictionary = {}
var percentages: Dictionary = {}
var mute_button: CheckButton
var speech_button: CheckButton
var fullscreen_button: CheckButton
var close_button: Button
var notice: Label
var panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.02, 0.06, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	panel = PanelContainer.new()
	add_child(panel)
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("21182e")
	surface.border_color = Color("76548e")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(18)
	surface.content_margin_left = 30
	surface.content_margin_right = 30
	surface.content_margin_top = 24
	surface.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", surface)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	panel.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	rows.add_child(_label("SMALL FOLLOWING", 13, Color("b89dce")))
	rows.add_child(_label("Settings", 32))
	rows.add_child(_label("Sound", 20, Color("d7b9ff")))
	mute_button = _toggle("Mute all sound   ·   M")
	mute_button.toggled.connect(func(_value: bool) -> void: mute_requested.emit())
	rows.add_child(mute_button)
	for entry in [["master", "Master volume"], ["music", "Background music"], ["footsteps", "Footsteps"], ["speech", "Speech"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var label := _label(entry[1], 17)
		label.custom_minimum_size.x = 168
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.custom_minimum_size = Vector2(140, 30)
		slider.focus_mode = Control.FOCUS_NONE
		slider.value_changed.connect(func(value: float) -> void: volume_changed.emit(entry[0], value / 100.0))
		row.add_child(slider)
		var percent := _label("100%", 16, Color("d7b9ff"))
		percent.custom_minimum_size.x = 48
		percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(percent)
		sliders[entry[0]] = slider
		percentages[entry[0]] = percent
		rows.add_child(row)
	speech_button = _toggle("Mute nonsense speech   ·   V")
	speech_button.toggled.connect(func(_value: bool) -> void: voice_mute_requested.emit())
	rows.add_child(speech_button)
	rows.add_child(HSeparator.new())
	rows.add_child(_label("Display", 20, Color("d7b9ff")))
	fullscreen_button = _toggle("Fullscreen   ·   F11")
	fullscreen_button.toggled.connect(func(value: bool) -> void: fullscreen_requested.emit(value))
	rows.add_child(fullscreen_button)
	var hint := _label("Movement and the round timer continue while settings are open.", 14, Color("bdaece"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(hint)
	notice = _label("", 14, Color("e1cf9b"))
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(notice)
	close_button = Button.new()
	close_button.text = "Back to game   ·   Esc"
	close_button.custom_minimum_size.y = 44
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void: close_requested.emit())
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("654580") if state == "hover" else Color("443052")
		style.border_color = Color("906dac")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		close_button.add_theme_stylebox_override(state, style)
	body.add_child(close_button)
	resized.connect(_layout)
	_layout()
	hide()


func _layout() -> void:
	if panel == null:
		return
	panel.size = Vector2(minf(580, size.x - 32), minf(700, size.y - 32))
	panel.position = (size - panel.size) * 0.5


func refresh(audio: Node, fullscreen: bool, message: String) -> void:
	for channel in sliders:
		sliders[channel].set_value_no_signal(audio.volumes[channel] * 100.0)
		percentages[channel].text = "%d%%" % roundi(audio.volumes[channel] * 100.0)
	mute_button.set_pressed_no_signal(audio.muted)
	speech_button.set_pressed_no_signal(audio.voice_muted)
	fullscreen_button.set_pressed_no_signal(fullscreen)
	notice.text = message
	# Reserve space so feedback does not shift the controls during a drag.
	notice.custom_minimum_size.y = 34


func _toggle(title: String) -> CheckButton:
	var button := CheckButton.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 17)
	return button


func _label(value: String, font_size: int, color: Color = Color("f1e5ff")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
