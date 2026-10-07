extends Node2D
## Session-only typed gathering. Audiences reset each round.
signal recruited(donation: int)
signal phrase_spoken

const Progression = preload("res://scripts/progression.gd")
const LISTENER_COUNT: int = 5
const CONVICTION_REQUIRED: float = 3.0
const DONATION: int = 3
const MERCHANT_COUNT: int = 2
const MERCHANT_CONVICTION: float = 9.0

var listener_count: int = LISTENER_COUNT
var conviction_required: float = CONVICTION_REQUIRED
var donation: int = DONATION
var npc_type: String = "villager"
## Empty profiles preserve the original homogeneous village/merchant rules.
var listener_profiles: Array[Dictionary] = []
var _market_progression: Progression = null

var group_name: String = "Neighbours"
var recruits: int = 0
var progress: float = 0.0
var phrase_elapsed: float = 0.0
var last_phrase_interval: float = 1.0
var is_listening: bool = false
var is_nearby: bool = false
var listeners: Array[Node2D] = []


class Listener extends Node2D:
	const DonationPopup = preload("res://scripts/donation_popup.gd")
	var following: bool = false
	var coat: Color = Color("#9c695a")
	var phase: float = 0.0
	var merchant: bool = false
	var role: String = ""
	var profile_type: String = "ordinary"
	var locked: bool = false
	var reward_label: Label

	func show_reward(amount: int) -> void:
		clear_reward()
		reward_label = DonationPopup.new()
		reward_label.amount = amount
		reward_label.position.y = -64
		add_child(reward_label)

	func clear_reward() -> void:
		if is_instance_valid(reward_label):
			reward_label.hide()
			reward_label.queue_free()
			reward_label = null

	func _process(delta: float) -> void:
		phase += delta * 1.8
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2(0, 0), 0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 12, Color(0.22, 0.27, 0.2, 0.17))
		draw_set_transform(Vector2.ZERO)
		var bob: float = sin(phase) * 0.65
		var tint: Color = Color("#9780a7") if following else coat
		draw_line(Vector2(-4, -9), Vector2(-5, 0), Color("#625648"), 4)
		draw_line(Vector2(4, -9), Vector2(5, 0), Color("#625648"), 4)
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -23 + bob), Vector2(8, -23 + bob), Vector2(12, -6), Vector2(-11, -6)]), tint)
		draw_circle(Vector2(0, -29 + bob), 9, Color("#eac49a"))
		draw_arc(Vector2(0, -31 + bob), 9, PI, TAU, 12, Color("#75604a"), 4, true)
		draw_circle(Vector2(-3, -29 + bob), 1.1, Color("#4e4944"))
		draw_circle(Vector2(3, -29 + bob), 1.1, Color("#4e4944"))
		if merchant:
			draw_rect(Rect2(-12, -40 + bob, 24, 5), Color("#75562d"))
			draw_rect(Rect2(-7, -48 + bob, 14, 10), Color("#b38c3c"))
			draw_circle(Vector2(12, -12), 6, Color("#e2b953"))
			draw_line(Vector2(12, -16), Vector2(12, -8), Color("#765923"), 2)
		if not role.is_empty():
			_draw_role(bob)
		if locked and not following:
			draw_rect(Rect2(-5, -60, 10, 9), Color("#f3ddb0"))
			draw_arc(Vector2(0, -60), 4, PI, TAU, 10, Color("#f3ddb0"), 2, true)
			draw_circle(Vector2(0, -56), 1.2, Color("#514b58"))
		if following:
			draw_line(Vector2(-4, -45), Vector2(-1, -42), Color("#fbf1b6"), 2)
			draw_line(Vector2(-1, -42), Vector2(5, -49), Color("#fbf1b6"), 2)

	func _draw_role(bob: float) -> void:
		if profile_type == "guild":
			# A square cap, apron and tool belt identify guild tradespeople.
			draw_rect(Rect2(-10, -41 + bob, 20, 6), Color("#466d75"))
			draw_rect(Rect2(-5, -23 + bob, 10, 15), Color("#d2c39b"))
			draw_line(Vector2(-9, -13), Vector2(10, -13), Color("#6a5136"), 3)
			draw_line(Vector2(12, -25), Vector2(12, -8), Color("#856f4d"), 3)
			draw_line(Vector2(7, -25), Vector2(17, -25), Color("#bcc2b1"), 4)
		elif profile_type == "patron":
			# A broad hat, feather and fan give patrons a richer silhouette.
			draw_rect(Rect2(-14, -40 + bob, 28, 4), Color("#85628f"))
			draw_rect(Rect2(-8, -46 + bob, 16, 8), Color("#a07aae"))
			draw_line(Vector2(6, -44 + bob), Vector2(13, -53 + bob), Color("#f1dfb1"), 3)
			draw_colored_polygon(PackedVector2Array([Vector2(11, -11), Vector2(6, -23), Vector2(19, -23)]), Color("#e3c587"))
		elif role == "Porter" or role == "Courier":
			draw_rect(Rect2(5, -23, 14, 13), Color("#b99361"))
			draw_line(Vector2(12, -23), Vector2(12, -10), Color("#e8d6a4"), 2)
		elif role == "Baker" or role == "Cook":
			draw_rect(Rect2(-6, -22 + bob, 12, 15), Color("#efdeb0"))
			draw_circle(Vector2(0, -41 + bob), 7, Color("#efdeb0"))
		else:
			draw_arc(Vector2(13, -17), 5, PI, TAU, 10, Color("#8f744e"), 2, true)
			draw_rect(Rect2(7, -17, 12, 9), Color("#c9a771"))


func _ready() -> void:
	y_sort_enabled = true
	if not listener_profiles.is_empty():
		var error: String = validate_profiles()
		if not error.is_empty():
			push_error(error)
			listener_count = 0
			return
		listener_count = listener_profiles.size()
		npc_type = "mixed"
	var offsets: Array[Vector2] = [Vector2(-43, -13), Vector2(0, -29), Vector2(41, -8), Vector2(-23, 26), Vector2(28, 30)]
	var colors: Array[Color] = [Color("#be8066"), Color("#b89c58"), Color("#679391"), Color("#7c88aa"), Color("#caaf77")]
	for i in range(listener_count):
		var listener := Listener.new()
		listener.position = offsets[i]
		listener.merchant = npc_type == "merchant"
		listener.coat = colors[i]
		listener.phase = float(i)
		if not listener_profiles.is_empty():
			listener.role = String(listener_profiles[i]["role"])
			listener.profile_type = String(listener_profiles[i]["npc_type"])
			listener.locked = not is_listener_eligible(i)
		add_child(listener)
		listeners.append(listener)


func tick_persuasion(delta: float, phrase_interval: float, conviction: float) -> void:
	if first_unconverted() < 0:
		return
	last_phrase_interval = maxf(phrase_interval, 0.05)
	phrase_elapsed += maxf(delta, 0.0)
	while phrase_elapsed + 0.000001 >= last_phrase_interval and first_unconverted() >= 0:
		phrase_elapsed = maxf(0.0, phrase_elapsed - last_phrase_interval)
		phrase_spoken.emit()
		progress += maxf(0.0, conviction)
		var next: int = first_unconverted()
		while next >= 0 and progress + 0.000001 >= listener_conviction_required(next):
			progress = maxf(0.0, progress - listener_conviction_required(next))
			recruit_listener(next)
			next = first_unconverted()
	if recruits == listener_count:
		progress = 0.0
		phrase_elapsed = 0.0
	elif first_unconverted() < 0:
		# The last usable phrase ends at this boundary; surplus caller time
		# must not become stored work against a listener who is still locked.
		phrase_elapsed = 0.0
	queue_redraw()


func first_unconverted() -> int:
	for index in range(listeners.size()):
		if not listeners[index].following and is_listener_eligible(index):
			return index
	return -1


func recruit_listener(index: int) -> bool:
	if index < 0 or index >= listeners.size() or listeners[index].following or not is_listener_eligible(index):
		return false
	var amount: int = listener_donation(index)
	listeners[index].following = true
	listeners[index].show_reward(amount)
	listeners[index].queue_redraw()
	recruits += 1
	if recruits == listener_count:
		progress = 0.0
		phrase_elapsed = 0.0
	recruited.emit(amount)
	queue_redraw()
	return true


func reset_round() -> void:
	recruits = 0
	progress = 0.0
	phrase_elapsed = 0.0
	is_listening = false
	is_nearby = false
	for listener in listeners:
		listener.following = false
		listener.clear_reward()
	queue_redraw()


func configure_market(progression: Progression) -> void:
	_market_progression = progression
	for index in range(listeners.size()):
		listeners[index].locked = not is_listener_eligible(index)
		listeners[index].queue_redraw()
	queue_redraw()


func validate_profiles() -> String:
	if listener_profiles.size() > LISTENER_COUNT:
		return "A market gathering supports at most five listeners."
	for profile in listener_profiles:
		if not profile.get("role", "") is String or String(profile.get("role", "")).strip_edges().is_empty():
			return "A market listener needs a role name."
		if not profile.get("npc_type", "") in ["ordinary", "guild", "patron"]:
			return "A market listener has an unsupported audience type."
		var threshold: Variant = profile.get("conviction_required")
		if not (threshold is int or threshold is float) or not is_finite(float(threshold)) or float(threshold) <= 0.0:
			return "A market listener needs a positive finite conviction threshold."
		var reward: Variant = profile.get("donation")
		if not reward is int or int(reward) <= 0 or int(reward) > 1000000:
			return "A market listener needs a bounded positive integer donation."
		if not profile.get("requires", "") in ["", "market_guild_unlock", "market_patron_unlock"]:
			return "A market listener names an unsupported introduction."
	return ""


func is_listener_eligible(index: int) -> bool:
	if index < 0 or index >= listener_count:
		return false
	if listener_profiles.is_empty():
		return true
	if index >= listener_profiles.size():
		return false
	var requirement: String = String(listener_profiles[index].get("requires", ""))
	return requirement.is_empty() or (_market_progression != null and _market_progression.has_unlock(requirement))


func listener_conviction_required(index: int) -> float:
	if listener_profiles.is_empty():
		return conviction_required
	if index < 0 or index >= listener_profiles.size():
		return INF
	return float(listener_profiles[index]["conviction_required"])


func listener_donation(index: int) -> int:
	if listener_profiles.is_empty():
		return donation
	if index < 0 or index >= listener_profiles.size():
		return 0
	var profile: Dictionary = listener_profiles[index]
	var amount: int = int(profile["donation"])
	return amount if _market_progression == null else _market_progression.market_donation(String(profile["npc_type"]), amount)


func set_nearby(value: bool) -> void:
	if value != is_nearby:
		is_nearby = value
		queue_redraw()


func set_listening(value: bool) -> void:
	if value != is_listening:
		is_listening = value
		queue_redraw()


func _draw() -> void:
	if not is_listening and not is_nearby:
		return
	if not listener_profiles.is_empty():
		_draw_market_details()
		return
	draw_arc(Vector2.ZERO, 69, 0, TAU, 56, Color(1, 0.93, 0.62, 0.7), 2, true)
	var font := ThemeDB.fallback_font
	var caption: String = "%s  %d/%d" % [group_name, recruits, listener_count]
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_style_box(_caption_style(), Rect2(-width * 0.5 - 10, -142, width + 20, 30))
	draw_string(font, Vector2(-width * 0.5, -121), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff1d0"))
	draw_line(Vector2(-38, 58), Vector2(38, 58), Color("#55654e"), 5)
	draw_line(Vector2(-38, 58), Vector2(-38 + 76 * progress / conviction_required, 58), Color("#f3d98c"), 5)
	for i in range(3):
		var filled: bool = progress >= conviction_required * float(i + 1) / 3.0
		draw_circle(Vector2(-14 + i * 14, 69), 3, Color("#f3d98c") if filled else Color("#6d7353"))
	draw_line(Vector2(-22, 78), Vector2(22, 78), Color("#6d7353"), 2)
	draw_line(Vector2(-22, 78), Vector2(-22 + 44 * phrase_elapsed / last_phrase_interval, 78), Color("#c4b1df"), 2)


func _draw_market_details() -> void:
	var next: int = first_unconverted()
	var lines: Array[String] = ["%s  %d/%d" % [group_name, recruits, listener_count]]
	if next >= 0:
		lines.append("%s: %.0f conviction / %d donations" % [listener_profiles[next]["role"], listener_conviction_required(next), listener_donation(next)])
	else:
		lines.append("Everyone approachable has joined")
	var locked_roles: Dictionary = {}
	for index in range(listeners.size()):
		if not is_listener_eligible(index) and not listeners[index].following:
			var key: String = String(listener_profiles[index].get("requires", ""))
			var roles: Array = locked_roles.get(key, [])
			roles.append(listener_profiles[index]["role"])
			locked_roles[key] = roles
	for requirement in locked_roles:
		var introduction: String = "Guild Introduction" if requirement == "market_guild_unlock" else "Patron's Introduction"
		lines.append("%s: %s required" % [", ".join(locked_roles[requirement]), introduction])
	var font := ThemeDB.fallback_font
	var width: float = 0.0
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
	var top: float = -95.0 - float(lines.size()) * 20.0
	draw_style_box(_caption_style(), Rect2(-width * 0.5 - 10, top, width + 20, float(lines.size()) * 20.0 + 10))
	for index in range(lines.size()):
		draw_string(font, Vector2(-width * 0.5, top + 19 + index * 20), lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff1d0"))
	if not is_listening or next < 0:
		return
	draw_arc(Vector2.ZERO, 69, 0, TAU, 56, Color(1, 0.93, 0.62, 0.7), 2, true)
	draw_line(Vector2(-38, 58), Vector2(38, 58), Color("55654e"), 5)
	draw_line(Vector2(-38, 58), Vector2(-38 + 76 * minf(progress / listener_conviction_required(next), 1.0), 58), Color("f3d98c"), 5)
	draw_line(Vector2(-22, 72), Vector2(22, 72), Color("6d7353"), 2)
	draw_line(Vector2(-22, 72), Vector2(-22 + 44 * minf(phrase_elapsed / last_phrase_interval, 1.0), 72), Color("c4b1df"), 2)


func _caption_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.28, 0.22, 0.9)
	style.set_corner_radius_all(8)
	return style
