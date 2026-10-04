extends Control
## A focused utility page over the current village or ritual; never pauses play.
signal close_requested
signal exit_requested
signal volume_changed(channel: String, value: float)
signal mute_requested
signal voice_mute_requested
signal fullscreen_requested(value: bool)
signal binding_requested(action: String, slot: int, code: int)
signal reset_keys_requested

const Keys = preload("res://scripts/key_bindings.gd")

var sliders: Dictionary = {}
var percentages: Dictionary = {}
var mute_button: CheckButton
var speech_button: CheckButton
var fullscreen_button: CheckButton
var close_button: Button
var exit_button: Button
var notice: Label
var panel: PanelContainer
var tabs: TabContainer
var binding_buttons: Dictionary = {}
var binding_message: Label
var cancel_button: Button
var reset_keys_button: Button
var capture_action: String = ""
var capture_slot: int = 0
var current_bindings: Dictionary = {}


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
	body.add_child(_label("SMALL FOLLOWING", 13, Color("b89dce")))
	body.add_child(_label("Settings", 32))
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	for state in ["tab_selected", "tab_unselected", "tab_disabled"]:
		var tab_style: StyleBox = tabs.get_theme_stylebox(state).duplicate()
		tab_style.content_margin_top = 17
		tab_style.content_margin_bottom = 17
		tabs.add_theme_stylebox_override(state, tab_style)
	tabs.tab_changed.connect(func(_index: int) -> void: cancel_capture())
	body.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.name = "Sound & display"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
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
		slider.custom_minimum_size = Vector2(140, 56)
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
	_build_key_mapping()
	var hint := _label("Movement and the round timer continue, including while choosing a key.", 14, Color("bdaece"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)
	notice = _label("", 14, Color("e1cf9b"))
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(notice)
	close_button = Button.new()
	close_button.text = "Back to game   ·   Esc"
	close_button.custom_minimum_size.y = 56
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void: close_requested.emit())
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("654580") if state == "hover" else Color("443052")
		style.border_color = Color("906dac")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		close_button.add_theme_stylebox_override(state, style)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(close_button)
	exit_button = Button.new()
	exit_button.text = "Exit Game"
	exit_button.custom_minimum_size = Vector2(140, 56)
	exit_button.focus_mode = Control.FOCUS_NONE
	exit_button.pressed.connect(func() -> void: exit_requested.emit())
	# A browser owns its tab's lifetime; SceneTree.quit cannot close it.
	exit_button.disabled = OS.has_feature("web")
	exit_button.tooltip_text = "Close the browser tab to exit." if exit_button.disabled else "Save preferences and close Small Following."
	actions.add_child(exit_button)
	resized.connect(_layout)
	# Wrapped text can briefly report a tall minimum before containers get width.
	panel.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	_layout()
	hide()


func _layout() -> void:
	if panel == null:
		return
	panel.size = Vector2(minf(680, size.x - 32), minf(740, size.y - 32))
	panel.position = (size - panel.size) * 0.5


func refresh(audio: Node, fullscreen: bool, message: String) -> void:
	for channel in sliders:
		sliders[channel].set_value_no_signal(audio.volumes[channel] * 100.0)
		percentages[channel].text = "%d%%" % roundi(audio.volumes[channel] * 100.0)
	mute_button.set_pressed_no_signal(audio.muted)
	speech_button.set_pressed_no_signal(audio.voice_muted)
	fullscreen_button.set_pressed_no_signal(fullscreen)
	mute_button.text = "Mute all sound   ·   " + Keys.hint("toggle_audio")
	speech_button.text = "Mute nonsense speech   ·   " + Keys.hint("toggle_voice")
	fullscreen_button.text = "Fullscreen   ·   " + Keys.hint("toggle_fullscreen")
	notice.text = message
	# Reserve space so feedback does not shift the controls during a drag.
	notice.custom_minimum_size.y = 34


func _build_key_mapping() -> void:
	var page := VBoxContainer.new()
	page.name = "Key mapping"
	page.add_theme_constant_override("separation", 10)
	tabs.add_child(page)
	var intro := _label("Click a binding, then press a key. Keys use physical keyboard positions.", 14, Color("bdaece"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	for title in ["Action", "Primary", "Alternate", ""]:
		grid.add_child(_label(title, 14, Color("d7b9ff")))
	for action in Keys.ACTIONS:
		var label := _label(Keys.ACTIONS[action], 16)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(label)
		var buttons: Array[Button] = []
		for slot in range(2):
			var button := _key_button("")
			button.custom_minimum_size.x = 112
			button.clip_text = true
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(begin_capture.bind(action, slot))
			grid.add_child(button)
			buttons.append(button)
		binding_buttons[action] = buttons
		var clear := _key_button("Clear")
		clear.tooltip_text = "Clear the alternate key for " + Keys.ACTIONS[action]
		clear.pressed.connect(func() -> void:
			cancel_capture()
			binding_requested.emit(action, 1, 0))
		grid.add_child(clear)
	var fixed := _label("Esc: settings / cancel key choice   ·   Tab: village / ritual\nThese navigation keys stay fixed. Gamepad bindings stay available.", 14, Color("bdaece"))
	fixed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(fixed)
	binding_message = _label("Choose a binding to change it.", 14, Color("e1cf9b"))
	binding_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_message.custom_minimum_size.y = 40
	page.add_child(binding_message)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	reset_keys_button = _key_button("Restore default keys")
	reset_keys_button.pressed.connect(func() -> void:
		cancel_capture()
		reset_keys_requested.emit())
	actions.add_child(reset_keys_button)
	cancel_button = _key_button("Cancel key choice")
	cancel_button.pressed.connect(cancel_capture)
	cancel_button.hide()
	actions.add_child(cancel_button)


func _key_button(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 15)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("654580") if state == "hover" else Color("35273f")
		style.border_color = Color("76548e")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 8
		style.content_margin_right = 8
		button.add_theme_stylebox_override(state, style)
	return button


func refresh_bindings(mapping: Dictionary) -> void:
	current_bindings = mapping.duplicate(true)
	for action in binding_buttons:
		for slot in range(2):
			var button: Button = binding_buttons[action][slot]
			button.text = "Press a key…" if capture_action == action and capture_slot == slot else Keys.key_name(int(mapping[action][slot]))
			button.tooltip_text = "%s: %s" % [Keys.ACTIONS[action], button.text]


func begin_capture(action: String, slot: int) -> void:
	capture_action = action
	capture_slot = slot
	binding_message.text = "Press a new key for %s. Esc cancels." % Keys.ACTIONS[action]
	cancel_button.show()
	refresh_bindings(current_bindings)


func cancel_capture() -> void:
	capture_action = ""
	if is_instance_valid(cancel_button):
		cancel_button.hide()
		binding_message.text = "Choose a binding to change it."
		refresh_bindings(current_bindings)


func capture_key(event: InputEvent) -> bool:
	if capture_action.is_empty() or not event is InputEventKey:
		return false
	# Tab retains its between-round escape route through main.gd.
	if event.is_action("toggle_ritual"):
		cancel_capture()
		return false
	if event.pressed and not event.echo:
		if event.is_action("toggle_settings"):
			cancel_capture()
		elif event.alt_pressed or event.ctrl_pressed or event.meta_pressed or event.shift_pressed:
			binding_message.text = "Choose a single key without Shift, Ctrl, Alt or Meta."
		else:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			binding_requested.emit(capture_action, capture_slot, code)
	return true


func _toggle(title: String) -> CheckButton:
	var button := CheckButton.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 56
	button.add_theme_font_size_override("font_size", 17)
	return button


func _label(value: String, font_size: int, color: Color = Color("f1e5ff")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
