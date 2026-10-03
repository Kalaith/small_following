extends Node2D
## Session-only typed gathering. Audiences reset each round.
signal recruited(donation: int)
signal phrase_spoken

const LISTENER_COUNT: int = 5
const CONVICTION_REQUIRED: float = 3.0
const DONATION: int = 3
const MERCHANT_COUNT: int = 2
const MERCHANT_CONVICTION: float = 9.0

var listener_count: int = LISTENER_COUNT
var conviction_required: float = CONVICTION_REQUIRED
var donation: int = DONATION
var npc_type: String = "villager"

var group_name: String = "Neighbours"
var recruits: int = 0
var progress: float = 0.0
var phrase_elapsed: float = 0.0
var last_phrase_interval: float = 1.0
var is_listening: bool = false
var listeners: Array[Node2D] = []


class Listener extends Node2D:
	var following: bool = false
	var coat: Color = Color("#9c695a")
	var phase: float = 0.0
	var merchant: bool = false

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
		if following:
			draw_line(Vector2(-4, -45), Vector2(-1, -42), Color("#fbf1b6"), 2)
			draw_line(Vector2(-1, -42), Vector2(5, -49), Color("#fbf1b6"), 2)


func _ready() -> void:
	y_sort_enabled = true
	var offsets: Array[Vector2] = [Vector2(-43, -13), Vector2(0, -29), Vector2(41, -8), Vector2(-23, 26), Vector2(28, 30)]
	var colors: Array[Color] = [Color("#be8066"), Color("#b89c58"), Color("#679391"), Color("#7c88aa"), Color("#caaf77")]
	for i in range(listener_count):
		var listener := Listener.new()
		listener.position = offsets[i]
		listener.merchant = npc_type == "merchant"
		listener.coat = colors[i]
		listener.phase = float(i)
		add_child(listener)
		listeners.append(listener)


func tick_persuasion(delta: float, phrase_interval: float, conviction: float) -> void:
	if recruits >= listener_count:
		return
	last_phrase_interval = maxf(phrase_interval, 0.05)
	phrase_elapsed += maxf(delta, 0.0)
	while phrase_elapsed + 0.000001 >= last_phrase_interval and recruits < listener_count:
		phrase_elapsed = maxf(0.0, phrase_elapsed - last_phrase_interval)
		phrase_spoken.emit()
		progress += maxf(0.0, conviction)
		while progress + 0.000001 >= conviction_required and recruits < listener_count:
			progress = maxf(0.0, progress - conviction_required)
			recruit_listener(first_unconverted())
	if recruits == listener_count:
		progress = 0.0
		phrase_elapsed = 0.0
	queue_redraw()


func first_unconverted() -> int:
	for index in range(listeners.size()):
		if not listeners[index].following:
			return index
	return -1


func recruit_listener(index: int) -> bool:
	if index < 0 or index >= listeners.size() or listeners[index].following:
		return false
	listeners[index].following = true
	listeners[index].queue_redraw()
	recruits += 1
	if recruits == listener_count:
		progress = 0.0
		phrase_elapsed = 0.0
	recruited.emit(donation)
	queue_redraw()
	return true


func reset_round() -> void:
	recruits = 0
	progress = 0.0
	phrase_elapsed = 0.0
	is_listening = false
	for listener in listeners:
		listener.following = false
	queue_redraw()


func set_listening(value: bool) -> void:
	if value != is_listening:
		is_listening = value
		queue_redraw()


func _draw() -> void:
	if not is_listening:
		if npc_type == "merchant":
			draw_string(ThemeDB.fallback_font, Vector2(-62, -65), "Merchants / +%d gold" % donation, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#594422"))
		return
	draw_arc(Vector2.ZERO, 69, 0, TAU, 56, Color(1, 0.93, 0.62, 0.7), 2, true)
	var font := ThemeDB.fallback_font
	var caption: String = "%s  %d/%d" % [group_name, recruits, listener_count]
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_style_box(_caption_style(), Rect2(-width * 0.5 - 10, -90, width + 20, 30))
	draw_string(font, Vector2(-width * 0.5, -69), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff1d0"))
	draw_line(Vector2(-38, 58), Vector2(38, 58), Color("#55654e"), 5)
	draw_line(Vector2(-38, 58), Vector2(-38 + 76 * progress / conviction_required, 58), Color("#f3d98c"), 5)
	for i in range(3):
		var filled: bool = progress >= conviction_required * float(i + 1) / 3.0
		draw_circle(Vector2(-14 + i * 14, 69), 3, Color("#f3d98c") if filled else Color("#6d7353"))
	draw_line(Vector2(-22, 78), Vector2(22, 78), Color("#6d7353"), 2)
	draw_line(Vector2(-22, 78), Vector2(-22 + 44 * phrase_elapsed / last_phrase_interval, 78), Color("#c4b1df"), 2)


func _caption_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.28, 0.22, 0.9)
	style.set_corner_radius_all(8)
	return style
