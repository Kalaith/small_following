extends Node2D
## Rosecourt's whispered introductions. Threads ("rosecourt.threads") link a
## guest to guests in other salons; converting the source, by the cultist or a
## helper, whispers along each thread. A whispered guest starts part-way won
## (Lingering Whispers) and a reserved noble listens only once whispered to.
## Everything resets each round. The court lives on the garden's floor, so its
## threads are drawn on the ground beneath every guest.

signal king_whispered

const Balance = preload("res://scripts/balance.gd")
## Seconds a whisper takes to run along its thread; presentation only.
const PULSE_SECONDS: float = 0.7
const THREAD := Color("c2486a")

var progression: RefCounted = null
## Salon id -> its gathering, and gathering instance id -> salon id.
var salons: Dictionary = {}
var _salon_of: Dictionary = {}
## Endpoint keys ("salon:index") whispered to this round.
var whispered: Dictionary = {}
## High nobles whose whisper has reached the King this round.
var king_whispers: int = 0
var _pulses: Array[Dictionary] = []


func bind(groups: Dictionary, owner_progression: RefCounted) -> void:
	progression = owner_progression
	salons = groups
	_salon_of.clear()
	for id in salons:
		_salon_of[salons[id].get_instance_id()] = id
		salons[id].court = self
	reset_round()


## Clears every whisper, then Trusted Name's nobles start the round already
## whispered to, in "rosecourt.trusted" order.
func reset_round() -> void:
	whispered.clear()
	king_whispers = 0
	_pulses.clear()
	if progression != null:
		var trusted: Array = Balance.list("rosecourt.trusted")
		for index in range(mini(progression.rose_trusted_count(), trusted.size())):
			whispered[String(trusted[index])] = true
	_refresh()


func key(group: Node2D, index: int) -> String:
	return "%s:%d" % [_salon_of.get(group.get_instance_id(), "?"), index]


func is_whispered(group: Node2D, index: int) -> bool:
	return whispered.has(key(group, index))


## Share of a guest's threshold still to win: less once someone has whispered.
func required_share(group: Node2D, index: int) -> float:
	return 1.0 - progression.rose_head_start() if is_whispered(group, index) else 1.0


func conviction_bonus(group: Node2D, index: int) -> float:
	return progression.rose_whisper_conviction() if is_whispered(group, index) else 0.0


## The gathering reports every conversion; each live thread from that guest
## whispers once. A target already won this round gains nothing more.
func on_converted(group: Node2D, index: int) -> void:
	var source: String = key(group, index)
	for target in targets_of(source):
		_pulses.append({"from": source, "to": target, "t": 0.0})
		if target == "king":
			king_whispers += 1
			king_whispered.emit()
		else:
			whispered[target] = true
	_refresh()


## The guests a source whispers to now: its own threads plus as many of its
## wide ones as Wide Circles reaches.
func targets_of(source: String) -> Array[String]:
	var result: Array[String] = []
	for thread in Balance.list("rosecourt.threads"):
		if String(thread.from) != source:
			continue
		for target in thread.to:
			result.append(String(target))
		var wide: Array = thread.get("wide", [])
		for index in range(mini(progression.rose_reach() if progression != null else 0, wide.size())):
			result.append(String(wide[index]))
	return result


## Who can introduce this guest, by role and salon, for the HUD.
func introducers(group: Node2D, index: int) -> PackedStringArray:
	var target: String = key(group, index)
	var names: PackedStringArray = []
	for thread in Balance.list("rosecourt.threads"):
		if target in targets_of(String(thread.from)):
			var ends: PackedStringArray = String(thread.from).split(":")
			if salons.has(ends[0]):
				var salon: Node2D = salons[ends[0]]
				names.append("the %s (%s)" % [salon.listener_profiles[int(ends[1])].role, salon.group_name])
	return names


func _refresh() -> void:
	for id in salons:
		var group: Node2D = salons[id]
		for index in range(group.listeners.size()):
			group.listeners[index].whispered = whispered.has("%s:%d" % [id, index])
		if progression != null:
			group.configure_market(progression)
	queue_redraw()


func _process(delta: float) -> void:
	if _pulses.is_empty():
		return
	for pulse in _pulses:
		pulse.t += delta / PULSE_SECONDS
	_pulses = _pulses.filter(func(pulse: Dictionary) -> bool: return float(pulse.t) < 1.0)
	queue_redraw()


func _end(endpoint: String) -> Variant:
	if endpoint == "king":
		return Balance.vec(Balance.value("rosecourt.king.at"))
	var ends: PackedStringArray = endpoint.split(":")
	if not salons.has(ends[0]):
		return null
	var group: Node2D = salons[ends[0]]
	var index: int = int(ends[1])
	return group.listeners[index].global_position if index < group.listeners.size() else null


## Rose threads on the ground: bright toward a reserved noble, quieter toward
## an open guest (a head start only) and faded once spent (the source has joined).
func _draw() -> void:
	for thread in Balance.list("rosecourt.threads"):
		var source: String = String(thread.from)
		var from: Variant = _end(source)
		if from == null:
			continue
		var ends: PackedStringArray = source.split(":")
		var spent: bool = salons[ends[0]].listeners[int(ends[1])].following
		for target in targets_of(source):
			var to: Variant = _end(target)
			if to == null:
				continue
			# Threads that open a reserved noble matter most; head starts are quieter.
			var opens: bool = target == "king" or _reserved(target)
			var color := Color(THREAD, 0.1 if spent else 0.6 if opens else 0.28)
			_draw_thread(from, to, color, 1.5 if spent else 2.6 if opens else 1.8)
	for pulse in _pulses:
		var from: Variant = _end(String(pulse.from))
		var to: Variant = _end(String(pulse.to))
		if from != null and to != null:
			var at: Vector2 = (from as Vector2).lerp(to, float(pulse.t))
			draw_circle(at, 6.0, Color("f0a0b4"))
			draw_circle(at, 3.0, Color("fff1f4"))


func _reserved(endpoint: String) -> bool:
	var ends: PackedStringArray = endpoint.split(":")
	return salons.has(ends[0]) and bool(salons[ends[0]].listener_profiles[int(ends[1])].get("reserved", false))


## A gently sagging thread between two pairs of feet, with a dot at each end.
func _draw_thread(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var middle: Vector2 = (from + to) * 0.5 + Vector2(0, 18)
	var points := PackedVector2Array()
	for step in range(17):
		var t: float = step / 16.0
		points.append(from.lerp(middle, t).lerp(middle.lerp(to, t), t))
	draw_polyline(points, color, width, true)
	draw_circle(from, 3.0, color)
	draw_circle(to, 3.0, color)
