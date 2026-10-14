extends Node
## Preferences behind the settings screen: its signals, the debounced save,
## key and gamepad rebinding, fullscreen and reduced motion.
const SettingsScreen = preload("res://scripts/settings_screen.gd")
const VillageHud = preload("res://scripts/village_hud.gd")
const Keys = preload("res://addons/hatchery/input/key_bindings.gd")
const Pad = preload("res://addons/hatchery/input/pad_bindings.gd")
const SettingsStore = preload("res://scripts/settings_store.gd")
const DonationPopup = preload("res://scripts/donation_popup.gd")
const Display = preload("res://addons/hatchery/settings/display.gd")

var game: Node2D
var settings_timer: Timer


func _init(owner_game: Node2D) -> void:
	game = owner_game
	name = "SettingsWiring"


func is_fullscreen() -> bool:
	return Display.is_fullscreen()


func set_fullscreen(enabled: bool) -> void:
	if Display.is_headless():
		return
	Display.set_fullscreen(enabled)
	game.settings.values.fullscreen = is_fullscreen()
	queue_save()


func set_reduce_motion(enabled: bool) -> void:
	game.settings.values.reduce_motion = enabled
	game.player.reduce_motion = enabled
	DonationPopup.reduce_motion = enabled
	queue_save()


func audio_preferences_changed() -> void:
	for channel in game.game_audio.volumes:
		game.settings.values[channel] = game.game_audio.volumes[channel]
	game.settings.values.muted = game.game_audio.muted
	game.settings.values.voice_muted = game.game_audio.voice_muted
	queue_save()


func queue_save() -> void:
	settings_timer.start()
	refresh()


func save_now() -> void:
	settings_timer.stop()
	game.settings.save_settings()
	refresh()


func refresh() -> void:
	game.settings_screen.refresh(game.game_audio, is_fullscreen(), game.settings.last_error, game.settings.values.reduce_motion)
	game.settings_screen.refresh_bindings(game.settings.key_bindings)
	game.settings_screen.refresh_pad(game.settings.pad_bindings)


func build() -> void:
	game.add_child(self)
	settings_timer = Timer.new()
	settings_timer.one_shot = true
	settings_timer.wait_time = 0.4
	settings_timer.timeout.connect(save_now)
	add_child(settings_timer)
	var canvas := CanvasLayer.new()
	canvas.name = "Settings"
	canvas.layer = 10
	game.add_child(canvas)
	# A small corner button: the village HUD and the ritual screen both keep this
	# square free, so it never covers their text.
	game.settings_button = SettingsScreen.MenuButtonIcon.new()
	game.settings_button.tooltip_text = "Settings (Esc)"
	game.settings_button.focus_mode = Control.FOCUS_NONE
	canvas.add_child(game.settings_button)
	game.settings_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	game.settings_button.offset_left = -VillageHud.HUD_MARGIN - VillageHud.SETTINGS_SIZE
	game.settings_button.offset_right = -VillageHud.HUD_MARGIN
	game.settings_button.offset_top = VillageHud.HUD_MARGIN
	game.settings_button.offset_bottom = VillageHud.HUD_MARGIN + VillageHud.SETTINGS_SIZE
	game.settings_button.pressed.connect(game.set_settings_visible.bind(true))
	game.settings_screen = SettingsScreen.new()
	canvas.add_child(game.settings_screen)
	for state in ["normal", "hover", "pressed"]:
		game.settings_button.add_theme_stylebox_override(state, game.settings_screen.close_button.get_theme_stylebox(state))
	game.settings_screen.close_requested.connect(game.set_settings_visible.bind(false))
	game.settings_screen.exit_requested.connect(game.exit_game)
	game.settings_screen.title_requested.connect(game.show_title)
	game.settings_screen.volume_changed.connect(game.game_audio.set_volume)
	game.settings_screen.mute_requested.connect(game.game_audio.toggle_mute)
	game.settings_screen.voice_mute_requested.connect(game.game_audio.toggle_voice)
	game.settings_screen.fullscreen_requested.connect(set_fullscreen)
	game.settings_screen.reduce_motion_requested.connect(set_reduce_motion)
	game.settings_screen.binding_requested.connect(_rebind_key)
	game.settings_screen.reset_keys_requested.connect(_reset_keys)
	game.settings_screen.pad_binding_requested.connect(_rebind_pad)
	game.settings_screen.reset_pad_requested.connect(_reset_pad)
	refresh()


func _rebind_key(action: String, slot: int, code: int) -> void:
	var error: String = game.settings.rebind(action, slot, code)
	if not error.is_empty():
		game.settings_screen.binding_message.text = game.settings.describe_binding_error(error)
		return
	game.settings_screen.cancel_capture()
	game.settings_screen.binding_message.text = "%s: %s" % [SettingsStore.KEY_ACTIONS[action], Keys.key_name(code)]
	_keys_changed()


func _reset_keys() -> void:
	game.settings.reset_keys()
	game.settings_screen.binding_message.text = "Default keys restored."
	_keys_changed()


func _rebind_pad(action: String, button: int) -> void:
	var error: String = game.settings.rebind_pad(action, button)
	if not error.is_empty():
		game.settings_screen.binding_message.text = game.settings.describe_binding_error(error)
		return
	game.settings_screen.cancel_capture()
	game.settings_screen.binding_message.text = "%s: %s" % [SettingsStore.PAD_ACTIONS[action], Pad.button_name(button)]
	_keys_changed()


func _reset_pad() -> void:
	game.settings.reset_pad()
	game.settings_screen.binding_message.text = "Default gamepad buttons restored."
	_keys_changed()


func _keys_changed() -> void:
	queue_save()
	game.ritual_screen.update_state(game.round_recruits)
	game._update_hud()
