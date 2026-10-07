extends RefCounted
## Physical keyboard slots; gamepad events and reserved navigation stay intact.
const ACTIONS: Dictionary = {
	"move_left": "Move left", "move_right": "Move right",
	"move_up": "Move up", "move_down": "Move down",
	"next_round": "Next round", "buy_upgrade": "Buy upgrade",
	"toggle_audio": "Mute all sound", "toggle_voice": "Mute speech",
	"toggle_fullscreen": "Fullscreen",
	"ritual_nav_up": "Graph: move up", "ritual_nav_down": "Graph: move down",
	"ritual_nav_left": "Graph: move left", "ritual_nav_right": "Graph: move right",
}


static func defaults() -> Dictionary:
	var result: Dictionary = {}
	for action in ACTIONS:
		var codes: Array = []
		for event in ProjectSettings.get_setting("input/" + action).events:
			if event is InputEventKey:
				codes.append(int(event.physical_keycode))
		while codes.size() < 2:
			codes.append(0)
		result[action] = codes
	return result


static func allowed(code: int) -> bool:
	if code <= 0 or code in [KEY_ESCAPE, KEY_TAB, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return false
	return OS.find_keycode_from_string(OS.get_keycode_string(code)) == code


static func valid(mapping: Variant) -> bool:
	if not mapping is Dictionary or mapping.size() != ACTIONS.size():
		return false
	var used: Array[int] = []
	for action in ACTIONS:
		var slots: Variant = mapping.get(action)
		if not slots is Array or slots.size() != 2:
			return false
		for slot in range(2):
			var code: Variant = slots[slot]
			if not (code is int or code is float) or not is_finite(float(code)) or float(code) != floorf(float(code)):
				return false
			if code == 0 and slot == 1:
				continue
			if code > 0x1ffffff or not allowed(int(code)) or used.has(int(code)):
				return false
			used.append(int(code))
	return true


static func change_error(mapping: Dictionary, action: String, slot: int, code: int) -> String:
	if not ACTIONS.has(action) or slot < 0 or slot > 1:
		return "Unknown binding."
	if code == 0 and slot == 0:
		return "Keep a primary key for every action."
	if code != 0 and not allowed(code):
		return "Choose a single key. Esc and Tab are reserved for navigation."
	if code != 0:
		for other in ACTIONS:
			for other_slot in range(2):
				if other == action and other_slot == slot:
					continue
				if int(mapping[other][other_slot]) == code:
					return "%s is already assigned to %s. Choose another key." % [key_name(code), ACTIONS[other]]
	return ""


static func normalized(mapping: Dictionary) -> Dictionary:
	# JSON numbers arrive as floats; keep runtime slots consistently integral.
	var result: Dictionary = {}
	for action in ACTIONS:
		result[action] = [int(mapping[action][0]), int(mapping[action][1])]
	return result


static func apply(mapping: Dictionary) -> void:
	for action in ACTIONS:
		Input.action_release(action)
		var other_events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if not event is InputEventKey:
				other_events.append(event)
		InputMap.action_erase_events(action)
		for code in mapping[action]:
			if code != 0:
				var event := InputEventKey.new()
				event.physical_keycode = int(code)
				InputMap.action_add_event(action, event)
		for event in other_events:
			InputMap.action_add_event(action, event)


static func key_name(code: int) -> String:
	return OS.get_keycode_string(code) if code != 0 else "Unassigned"


static func hint(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return key_name(event.physical_keycode)
	return ""
