extends "res://addons/hatchery/settings/settings_store.gd"
## Small Following's preferences: which settings exist and which actions
## rebind. Storage, validation, backups and binding rules come from the shared
## toolkit store. Preferences never share a file or schema with earned
## progression.
const KeyBindings = preload("res://addons/hatchery/input/key_bindings.gd")
const PadBindings = preload("res://addons/hatchery/input/pad_bindings.gd")

## Schema 1 shipped the original six keys. Schema 2 tolerates a saved
## `values` dictionary missing a newer key (it defaults in on load) so a
## single added setting cannot invalidate every existing preferences file.
const CURRENT_SCHEMA: int = 2
const DEFAULTS: Dictionary = {
	"master": 1.0, "music": 1.0, "footsteps": 1.0, "speech": 1.0,
	"muted": false, "voice_muted": false, "fullscreen": false, "reduce_motion": false,
}
## Physical keyboard slots; gamepad events and reserved navigation stay intact.
const KEY_ACTIONS: Dictionary = {
	"move_left": "Move left", "move_right": "Move right",
	"move_up": "Move up", "move_down": "Move down",
	"next_round": "Next round", "buy_upgrade": "Buy upgrade",
	"toggle_audio": "Mute all sound", "toggle_voice": "Mute speech",
	"toggle_fullscreen": "Fullscreen",
	"ritual_nav_up": "Graph: move up", "ritual_nav_down": "Graph: move down",
	"ritual_nav_left": "Graph: move left", "ritual_nav_right": "Graph: move right",
}
## One gamepad button per action; analog movement and every keyboard slot stay intact.
const PAD_ACTIONS: Dictionary = {
	"next_round": "Next round", "buy_upgrade": "Buy upgrade",
	"ritual_nav_up": "Graph: move up", "ritual_nav_down": "Graph: move down",
	"ritual_nav_left": "Graph: move left", "ritual_nav_right": "Graph: move right",
}

## The preferences file; set before `load_settings` to redirect it.
var path: String:
	get:
		return file.path
	set(value):
		file.path = value


func _init(settings_path: String = "user://settings.json") -> void:
	super(DEFAULTS, settings_path, CURRENT_SCHEMA)
	keys = KeyBindings.new(KEY_ACTIONS)
	pad = PadBindings.new(PAD_ACTIONS)
	_reset_bindings()


## Plain English for a key or gamepad binding error code.
func describe_binding_error(error: String) -> String:
	return pad.describe(error) if error.begins_with("bind_button") else keys.describe(error)
