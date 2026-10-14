extends Node2D
## Session-only typed gathering. Audiences reset each round.
signal recruited(donation: int)
signal phrase_spoken

const Progression = preload("res://scripts/progression.gd")
const LISTENER_COUNT: int = 5
## Floating-point slack when comparing accumulated per-frame time to a fixed interval.
const TIME_EPSILON: float = 0.000001
const Balance = preload("res://scripts/balance.gd")
const ArgumentBadge = preload("res://scripts/argument_badge.gd")
const Listener = preload("res://scripts/listener.gd")
## Rosecourt guests; their salons carry no text over their heads.
const COURT_TYPES: Array[String] = ["servant", "courtier", "noble", "grandee"]
## Ordinary villagers who share a convinced opponent's habits join the village
## after that opponent's victory (balance data "village.types"). Rebuttals are
## phrases ignored at the start of each visit; decay is conviction lost per
## second while unattended; objections reset after time away.

var listener_count: int = LISTENER_COUNT
var conviction_required: float = Balance.number("village.listener.conviction")
var donation: int = Balance.integer("village.listener.donation")
var npc_type: String = "villager"
var rebuttals_per_visit: int = 0
var decay_per_second: float = 0.0
var rebuttals_left: int = 0
var _unattended: float = 0.0
## Empty profiles preserve the original homogeneous village/merchant rules.
var listener_profiles: Array[Dictionary] = []
var _market_progression: Progression = null
## Rosecourt's whisper court: reserved guests, head starts and threads.
var court: Node2D = null

var group_name: String = "Neighbours"
## Village-type crowds and lone wanderers carry no name or hint overhead; the
## ring and conviction bar still show who is listening.
var show_caption: bool = true
## Rotates the coat palette so lone wanderers do not all wear the same colour.
var coat_offset: int = 0
var recruits: int = 0
var progress: float = 0.0
var phrase_elapsed: float = 0.0
var last_phrase_interval: float = 1.0
var is_listening: bool = false
var is_nearby: bool = false
var listeners: Array[Node2D] = []

## Lantern Fair hearing: Interest against Distraction, a hard threshold. A
## negative `distraction` marks an audience outside the fair, which always hears.
## The fair director sets `current_distraction` every frame (shows, performers,
## stolen crowds, headliners); the Barker's cut applies on top while it speaks here.
var distraction: int = -1
var zone: String = ""
var current_distraction: int = 0
var barker_cut: int = 0
## Fraction of the current listener's threshold lost per second while no
## counted phrase reaches them (walking away, or turning deaf mid-conversation).
var drain_share: float = 0.0
## Mime watchers only listen while the cultist stands completely still.
var still_only: bool = false
## Performer groups put on shows; converting one ends its act for the round.
var act_show: Dictionary = {}
var act_cancelled: bool = false
var show_running: bool = false
var next_show_in: float = -1.0
## Seconds left of a stolen-audience window and its full length, for the ring.
var stolen_left: float = 0.0
var stolen_total: float = 1.0
## The cultist's Interest, so captions can compare; display only.
var viewer_interest: int = 0
var deaf: bool = false


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
	# Smaller village crowds stand in their own balanced huddles; a lone wanderer
	# stands on the gathering origin. Pairs and full five keep the authored ring.
	if listener_count == 1:
		offsets = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	elif listener_count == 3:
		offsets = [Vector2(-32, -12), Vector2(30, -16), Vector2(0, 24), Vector2(-23, 26), Vector2(28, 30)]
	elif listener_count == 4:
		offsets = [Vector2(-38, -10), Vector2(8, -30), Vector2(38, 4), Vector2(-6, 26), Vector2(28, 30)]
	var colors: Array[Color] = [Color("#be8066"), Color("#b89c58"), Color("#679391"), Color("#7c88aa"), Color("#caaf77")]
	# The homogeneous (non-profile) path sets listener_count directly with no
	# validate_profiles() pass; bound it to the authored offsets/colors too.
	if listener_count > offsets.size():
		push_error("A gathering supports at most %d listeners." % offsets.size())
		listener_count = offsets.size()
	for i in range(listener_count):
		var listener := Listener.new()
		listener.position = offsets[i]
		listener.merchant = npc_type == "merchant"
		listener.coat = colors[(i + coat_offset) % colors.size()]
		listener.phase = float(i)
		if Balance.dict("village.types").has(npc_type):
			listener.kind = npc_type
			listener.coat = Color(String(Balance.dict("village.types")[npc_type].coat)).lerp(colors[(i + coat_offset) % colors.size()], 0.25)
		if not listener_profiles.is_empty():
			listener.role = String(listener_profiles[i]["role"])
			listener.profile_type = String(listener_profiles[i]["npc_type"])
			listener.argument = listener_argument(i)
			listener.locked = not is_listener_eligible(i)
		add_child(listener)
		listeners.append(listener)


## Applies a village type's thresholds, rewards and habits; call before _ready.
func configure_village_type(type_id: String) -> void:
	var rules: Dictionary = Balance.dict("village.types")[type_id]
	npc_type = type_id
	conviction_required = float(rules.conviction)
	donation = int(rules.donation)
	rebuttals_per_visit = int(rules.rebuttals)
	decay_per_second = float(rules.decay)
	rebuttals_left = rebuttals_per_visit
	show_caption = false


## Interest a fair speaker needs here now; zero outside the fair.
func effective_distraction() -> int:
	return maxi(0, current_distraction - barker_cut) if distraction >= 0 else 0


## The hard threshold: one point short is the same as ten. `extra_cut` lets the
## Barker judge a group by the cut its own speaking would bring.
func hears(interest: int, extra_cut: int = 0) -> bool:
	return distraction < 0 or interest >= effective_distraction() - extra_cut


## `interest` and `still` apply only at the fair. Deaf phrases still sound and
## keep their rhythm, but add no conviction, bank no overflow, and the listener's
## partial conviction drains as if the cultist had walked away.
func tick_persuasion(delta: float, phrase_interval: float, conviction: float, interest: int = 0, still: bool = true) -> void:
	if first_unconverted() < 0:
		return
	_unattended = 0.0
	last_phrase_interval = maxf(phrase_interval, 0.05)
	# The rhythm never passes twenty phrases a second. At Rosecourt speech beyond
	# it still counts: each phrase carries the conviction of the ones it stands for.
	var burst: float = last_phrase_interval / phrase_interval if court != null and phrase_interval > 0.0 else 1.0
	phrase_elapsed += maxf(delta, 0.0)
	var heard: bool = hears(interest) and (still or not still_only)
	set_deaf(not heard)
	if not heard:
		_drain(maxf(delta, 0.0))
	while phrase_elapsed + TIME_EPSILON >= last_phrase_interval and first_unconverted() >= 0:
		phrase_elapsed = maxf(0.0, phrase_elapsed - last_phrase_interval)
		phrase_spoken.emit()
		if not heard:
			continue
		if rebuttals_left > 0:
			# An objection answered: the phrase is spent but adds no conviction.
			rebuttals_left -= 1
			continue
		# At Quillmoor a phrase also carries the faculty bonus of whoever it reaches.
		progress += (maxf(0.0, conviction) + listener_conviction_bonus(first_unconverted())) * burst
		var next: int = first_unconverted()
		while next >= 0 and progress + TIME_EPSILON >= listener_conviction_required(next):
			progress = maxf(0.0, progress - listener_conviction_required(next))
			recruit_listener(next, interest)
			next = first_unconverted()
	if recruits == listener_count:
		progress = 0.0
		phrase_elapsed = 0.0
	elif first_unconverted() < 0:
		# The last usable phrase ends at this boundary; surplus caller time
		# must not become stored work against a listener who is still locked.
		phrase_elapsed = 0.0
	queue_redraw()


## Active-round time the player spends speaking elsewhere. Devotees lose
## conviction and the watch readies its objections again.
func advance_unattended(delta: float) -> void:
	if delta <= 0.0:
		return
	_unattended += delta
	set_deaf(false)
	if decay_per_second > 0.0 and progress > 0.0:
		progress = maxf(0.0, progress - decay_per_second * delta)
		queue_redraw()
	_drain(delta)
	if _unattended >= Balance.number("village.rebuttal_reset_seconds") and rebuttals_left != rebuttals_per_visit:
		rebuttals_left = rebuttals_per_visit
		queue_redraw()


## Fair listeners do not keep their place: partial conviction runs out fast.
## Converted listeners stay converted; only progress toward the next one drains.
func _drain(delta: float) -> void:
	if drain_share <= 0.0 or progress <= 0.0 or delta <= 0.0:
		return
	var next: int = first_unconverted()
	var rate: float = drain_share * (listener_conviction_required(next) if next >= 0 else 0.0)
	progress = maxf(0.0, progress - rate * delta)
	queue_redraw()


## Conviction per second a helper's partial work loses here while it is deaf.
func drain_rate(index: int) -> float:
	return drain_share * listener_conviction_required(index) if drain_share > 0.0 else 0.0


func set_deaf(value: bool) -> void:
	if value == deaf:
		return
	deaf = value
	var next: int = first_unconverted()
	for index in range(listeners.size()):
		listeners[index].deaf = value and index == next
		listeners[index].queue_redraw()
	queue_redraw()


func set_performing(value: bool) -> void:
	if value == show_running:
		return
	show_running = value
	for listener in listeners:
		listener.performing = value
	queue_redraw()


## A performer group whose every approachable member has joined.
func act_won() -> bool:
	return not act_show.is_empty() and listener_count > 0 and first_unconverted() < 0 and recruits > 0


func first_unconverted() -> int:
	for index in range(listeners.size()):
		if not listeners[index].following and is_listener_eligible(index):
			return index
	return -1


## The recruitment authority: helpers pass their own Interest (and the Barker its
## cut) so no follower can win a listener who cannot hear them.
func recruit_listener(index: int, interest: int = 0, extra_cut: int = 0) -> bool:
	if index < 0 or index >= listeners.size() or listeners[index].following or not is_listener_eligible(index):
		return false
	if not hears(interest, extra_cut):
		return false
	var amount: int = listener_donation(index)
	listeners[index].following = true
	listeners[index].show_reward(amount)
	listeners[index].queue_redraw()
	recruits += 1
	if court != null:
		# Whoever won them, the cultist or a helper, their threads whisper now.
		court.on_converted(self, index)
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
	rebuttals_left = rebuttals_per_visit
	_unattended = 0.0
	is_listening = false
	is_nearby = false
	act_cancelled = false
	stolen_left = 0.0
	barker_cut = 0
	set_deaf(false)
	set_performing(false)
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
		if not profile.get("npc_type", "") in ["ordinary", "guild", "patron", "fairgoer", "stallholder", "performer", "fan", "student", "staff", "academic", "pupil", "servant", "courtier", "noble", "grandee"]:
			return "A market listener has an unsupported audience type."
		var argument: Variant = profile.get("argument", "")
		if not argument is String or (not argument.is_empty() and not argument in Progression.argument_ids()):
			return "A Quillmoor listener needs a known argument or none."
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
	if not requirement.is_empty() and (_market_progression == null or not _market_progression.has_unlock(requirement)):
		return false
	# A reserved Rosecourt noble listens only after someone they trust whispers.
	if bool(listener_profiles[index].get("reserved", false)) and (court == null or not court.is_whispered(self, index)):
		return false
	# The faculty rule: an academic hears only an argument prepared this round.
	var argument: String = listener_argument(index)
	return argument.is_empty() or (_market_progression != null and _market_progression.is_prepared(argument))


## The argument a Quillmoor academic needs prepared; empty for everyone else.
func listener_argument(index: int) -> String:
	if index < 0 or index >= listener_profiles.size():
		return ""
	return String(listener_profiles[index].get("argument", ""))


func listener_conviction_bonus(index: int) -> float:
	if court != null:
		return court.conviction_bonus(self, index)
	var argument: String = listener_argument(index)
	if argument.is_empty() or _market_progression == null:
		return 0.0
	return _market_progression.uni_argument_conviction([argument])


func listener_conviction_required(index: int) -> float:
	if listener_profiles.is_empty():
		return conviction_required
	if index < 0 or index >= listener_profiles.size():
		return INF
	if court != null:
		# A whispered guest's head start: part of their threshold is already won.
		return float(listener_profiles[index]["conviction_required"]) * court.required_share(self, index)
	return float(listener_profiles[index]["conviction_required"])


func listener_donation(index: int) -> int:
	if listener_profiles.is_empty():
		return donation
	if index < 0 or index >= listener_profiles.size():
		return 0
	var profile: Dictionary = listener_profiles[index]
	var amount: int = int(profile["donation"])
	if _market_progression == null:
		return amount
	return _market_progression.market_donation(String(profile["npc_type"]), amount) + _market_progression.uni_argument_donation(listener_argument(index))


func set_nearby(value: bool) -> void:
	if value != is_nearby:
		is_nearby = value
		queue_redraw()


func set_listening(value: bool) -> void:
	if value != is_listening:
		is_listening = value
		queue_redraw()


func _draw() -> void:
	if distraction >= 0 and listener_count > 0:
		_draw_fair_badge()
	if not is_listening and not is_nearby:
		return
	if not listener_profiles.is_empty():
		if show_caption:
			_draw_market_details()
		else:
			_draw_lone_market()
		return
	var lone: bool = listener_count == 1
	draw_arc(Vector2.ZERO, 34 if lone else 69, 0, TAU, 56, Color(1, 0.93, 0.62, 0.7), 2, true)
	_draw_progress(conviction_required)
	if not show_caption:
		return
	var font := ThemeDB.fallback_font
	var caption: String = "%s  %d/%d" % [group_name, recruits, listener_count]
	if rebuttals_left > 0 and first_unconverted() >= 0:
		caption += "  /  %d objection%s" % [rebuttals_left, "" if rebuttals_left == 1 else "s"]
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var caption_top: float = -112.0 if lone else -142.0
	draw_style_box(_caption_style(), Rect2(-width * 0.5 - 10, caption_top, width + 20, 30))
	draw_string(font, Vector2(-width * 0.5, caption_top + 21), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff1d0"))


func _draw_progress(required: float) -> void:
	draw_line(Vector2(-38, 58), Vector2(38, 58), Color("#55654e"), 5)
	draw_line(Vector2(-38, 58), Vector2(-38 + 76 * minf(progress / required, 1.0), 58), Color("#f3d98c"), 5)
	for i in range(3):
		var filled: bool = progress >= required * float(i + 1) / 3.0
		draw_circle(Vector2(-14 + i * 14, 69), 3, Color("#f3d98c") if filled else Color("#6d7353"))
	draw_line(Vector2(-22, 78), Vector2(22, 78), Color("#6d7353"), 2)
	draw_line(Vector2(-22, 78), Vector2(-22 + 44 * minf(phrase_elapsed / last_phrase_interval, 1.0), 78), Color("#c4b1df"), 2)


func _draw_market_details() -> void:
	var next: int = first_unconverted()
	var lines: Array[String] = ["%s  %d/%d" % [group_name, recruits, listener_count]]
	if next >= 0:
		var who: String = String(listener_profiles[next]["role"])
		if not listener_argument(next).is_empty():
			who += " (%s, prepared)" % ArgumentBadge.title(listener_argument(next))
		lines.append("%s: %.0f conviction / %d donations" % [who, listener_conviction_required(next), listener_donation(next)])
	else:
		lines.append("Everyone approachable has joined")
	if distraction >= 0 and next >= 0:
		lines.append("Distraction %d (%s) - your Interest %d" % [effective_distraction(), Balance.dict("fair.zones").get(zone, zone), viewer_interest])
		if still_only:
			lines.append("Listens only while you stand still")
		if rebuttals_per_visit > 0:
			lines.append("Honks back at your first phrase each visit")
	var locked_roles: Dictionary = {}
	for index in range(listeners.size()):
		if not is_listener_eligible(index) and not listeners[index].following:
			var key: String = String(listener_profiles[index].get("requires", ""))
			if not listener_argument(index).is_empty():
				key = "argument:" + listener_argument(index)
			var roles: Array = locked_roles.get(key, [])
			roles.append(listener_profiles[index]["role"])
			locked_roles[key] = roles
	for requirement in locked_roles:
		if String(requirement).begins_with("argument:"):
			lines.append("%s - needs %s (not prepared)" % [", ".join(locked_roles[requirement]), ArgumentBadge.title(String(requirement).trim_prefix("argument:"))])
		else:
			lines.append("%s: %s required" % [", ".join(locked_roles[requirement]), _introduction_name(requirement)])
	var font := ThemeDB.fallback_font
	var width: float = 0.0
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
	var top: float = -95.0 - float(lines.size()) * 20.0 - (22.0 if distraction >= 0 else 0.0)
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


## A lone market wanderer shows only its ring and bar, like Bramblewick's; one
## still waiting on an introduction names it instead.
func _draw_lone_market() -> void:
	var next: int = first_unconverted()
	if next >= 0:
		# A captionless salon keeps the full ring around all of its guests.
		draw_arc(Vector2.ZERO, 34 if listener_count == 1 else 69, 0, TAU, 56, Color(1, 0.93, 0.62, 0.7), 2, true)
		_draw_progress(listener_conviction_required(next))
		return
	if recruits > 0 or String(listener_profiles[0].get("npc_type", "")) in COURT_TYPES:
		return
	var font := ThemeDB.fallback_font
	var line: String = "%s required" % _introduction_name(String(listener_profiles[0].get("requires", "")))
	if not listener_argument(0).is_empty():
		line = "%s - needs %s (not prepared)" % [listener_profiles[0]["role"], ArgumentBadge.title(listener_argument(0))]
	var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_style_box(_caption_style(), Rect2(-width * 0.5 - 10, -118, width + 20, 28))
	draw_string(font, Vector2(-width * 0.5, -99), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff1d0"))


## Lantern pips under every fair audience: their Distraction, gold when the
## cultist's Interest reaches it, dim red when they will not hear. Performers
## sign their next show; a stolen crowd shows sparkles and a countdown ring.
func _draw_fair_badge() -> void:
	var font := ThemeDB.fallback_font
	var lone: bool = listener_count == 1
	# Above the heads, so stalls drawn in front never hide it.
	var top: float = -84.0 if lone else -104.0
	var level: int = effective_distraction()
	var lantern: Color = Color("f2c14e") if viewer_interest >= level else Color("b4564a")
	var suffix: String = ""
	if not act_show.is_empty():
		if act_cancelled:
			suffix = "act over"
		elif show_running:
			suffix = "SHOW!"
		elif next_show_in >= 0.0:
			suffix = "show in %ds" % ceili(next_show_in)
	var per_row: int = 10
	var rows: int = maxi(1, ceili(float(level) / per_row))
	var number: String = str(level)
	var number_width: float = font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var pip_width: float = float(mini(level, per_row)) * 7.0
	var suffix_width: float = font.get_string_size(suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 8.0 if not suffix.is_empty() else 0.0
	var width: float = number_width + pip_width + suffix_width + 16.0
	var left: float = -width * 0.5
	var style := _caption_style()
	style.bg_color = Color(0.17, 0.14, 0.2, 0.82)
	draw_style_box(style, Rect2(left, top, width, 8.0 + rows * 10.0))
	draw_string(font, Vector2(left + 6, top + 14), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, lantern.lightened(0.3))
	for index in range(level):
		draw_rect(Rect2(Vector2(left + 10 + number_width + (index % per_row) * 7.0, top + 5 + (index / per_row) * 10.0), Vector2(5, 7)), lantern)
	if not suffix.is_empty():
		draw_string(font, Vector2(left + 14 + number_width + pip_width, top + 14), suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffe9a8") if show_running else Color("e8dcc4"))
	if stolen_left > 0.0:
		var ring: float = 40.0 if lone else 76.0
		draw_arc(Vector2(0, -12), ring, -PI * 0.5, -PI * 0.5 + TAU * clampf(stolen_left / maxf(stolen_total, 0.01), 0.0, 1.0), 48, Color("ffe38a"), 3.0, true)
		for index in range(4):
			var spark := Vector2.from_angle(float(Time.get_ticks_msec()) * 0.004 + index * TAU / 4.0) * (ring - 8.0) + Vector2(0, -12)
			draw_line(spark + Vector2(-4, 0), spark + Vector2(4, 0), Color("fff4c4"), 1.5)
			draw_line(spark + Vector2(0, -4), spark + Vector2(0, 4), Color("fff4c4"), 1.5)


func _introduction_name(requirement: String) -> String:
	return "Guild Introduction" if requirement == "market_guild_unlock" else "Patron's Introduction"


func _caption_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.28, 0.22, 0.9)
	style.set_corner_radius_all(8)
	return style
