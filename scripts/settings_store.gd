extends RefCounted
## Preferences never share a file or schema with earned progression.
const Keys = preload("res://scripts/key_bindings.gd")
const DEFAULTS: Dictionary = {
	"master": 1.0, "music": 1.0, "footsteps": 1.0, "speech": 1.0,
	"muted": false, "voice_muted": false, "fullscreen": false,
}
var values: Dictionary = DEFAULTS.duplicate()
var key_bindings: Dictionary = Keys.defaults()
var save_enabled: bool = true
var path: String = "user://settings.json"
var last_error: String = ""
var writes_blocked: bool = false


func valid(data: Variant) -> bool:
	if not data is Dictionary or not (data.get("schema") is int or data.get("schema") is float):
		return false
	if data.schema != 1 or not data.get("values") is Dictionary:
		return false
	var candidate: Dictionary = data.values
	for key in DEFAULTS:
		if not candidate.has(key):
			return false
		if DEFAULTS[key] is bool:
			if not candidate[key] is bool:
				return false
		else:
			if not (candidate[key] is float or candidate[key] is int):
				return false
			var amount: float = float(candidate[key])
			if not is_finite(amount) or amount < 0.0 or amount > 1.0:
				return false
	return not data.has("key_bindings") or Keys.valid(data.key_bindings)


func _read(filename: String) -> Variant:
	if not FileAccess.file_exists(filename):
		return null
	var parser := JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(filename)) == OK else null


func load_settings() -> void:
	if not save_enabled:
		return
	var data: Variant = _read(path)
	if valid(data):
		values = data.values.duplicate()
		key_bindings = Keys.normalized(data.get("key_bindings", Keys.defaults()))
		return
	# Preserve future formats rather than replacing them with an older backup.
	if data is Dictionary and data.get("schema") != 1:
		writes_blocked = true
		last_error = "Settings use an unsupported version. Changes last this session."
		return
	var backup: Variant = _read(path + ".bak")
	if valid(backup):
		values = backup.values.duplicate()
		key_bindings = Keys.normalized(backup.get("key_bindings", Keys.defaults()))
		last_error = "Recovered settings from backup."
	elif FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		writes_blocked = true
		last_error = "Saved settings could not be read. Changes last this session."


func save_settings() -> bool:
	if not save_enabled:
		return true
	if writes_blocked:
		return false
	var snapshot := {"schema": 1, "values": values, "key_bindings": key_bindings}
	if not valid(snapshot):
		last_error = "Settings are invalid and could not be saved."
		return false
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _failed()
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	file.close()
	if not valid(_read(temporary)):
		return _failed()
	if FileAccess.file_exists(path):
		var destination: String = path + ".bak" if valid(_read(path)) else path + ".corrupt"
		if DirAccess.copy_absolute(path, destination) != OK:
			return _failed()
	if DirAccess.rename_absolute(temporary, path) != OK:
		return _failed()
	last_error = ""
	return true


func _failed() -> bool:
	last_error = "Could not save settings. Changes last this session."
	return false


func rebind(action: String, slot: int, code: int) -> String:
	var error: String = Keys.change_error(key_bindings, action, slot, code)
	if error.is_empty():
		key_bindings[action][slot] = code
		Keys.apply(key_bindings)
	return error


func reset_keys() -> void:
	key_bindings = Keys.defaults()
	Keys.apply(key_bindings)
