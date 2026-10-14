extends Node2D
## The Lantern Fair: radial lanes around the big top. Ground, stages and the
## ring's hoop markers are floor drawing; carousel, tent and stalls are Y-sorted
## props with real layer-2 footprints. Artwork is original procedural geometry.
## People, Distraction and shows are balance data ("fair.*").

const Village = preload("res://scripts/village.gd")
const DrawShapes = preload("res://scripts/draw_shapes.gd")
const Balance = preload("res://scripts/balance.gd")
const WORLD_SIZE := Vector2(1560, 1100)
const AREA_ID: String = "lantern_fair"

const PROP_LAYOUT = [
	{"kind": "carousel", "at": Vector2(390, 300)},
	{"kind": "bigtop", "at": Vector2(780, 268)},
	{"kind": "stall", "at": Vector2(330, 735), "tint": Color("c9705a")},
	{"kind": "stall", "at": Vector2(95, 700), "tint": Color("b9934b")},
	{"kind": "stall", "at": Vector2(1165, 700), "tint": Color("5f8db0")},
	{"kind": "stall", "at": Vector2(1460, 560), "tint": Color("a46aa0")},
	{"kind": "post", "at": Vector2(668, 1012)},
	{"kind": "post", "at": Vector2(892, 1012)},
	{"kind": "post", "at": Vector2(1040, 470)},
	{"kind": "post", "at": Vector2(520, 610)},
	{"kind": "tree", "at": Vector2(85, 175), "variant": 0},
	{"kind": "tree", "at": Vector2(1480, 175), "variant": 1},
	{"kind": "tree", "at": Vector2(95, 925), "variant": 1},
	{"kind": "tree", "at": Vector2(1480, 960), "variant": 0},
	{"kind": "flowers", "at": Vector2(1290, 980), "variant": 1},
	{"kind": "flowers", "at": Vector2(250, 1010), "variant": 0},
	{"kind": "bench", "at": Vector2(1000, 990)},
]

var _props_built: bool = false
## Index of the stage the cultist stands on, or -1; set by the fair director.
var active_stage: int = -1
## Ringmaster's hoops: positions, the lit index (-1 hides them) and a Bravo flash.
var hoops: Array[Vector2] = []
var lit_hoop: int = -1
var bravo_left: float = 0.0
## Active shows: [{at, radius}] so their reach glows on the ground.
var show_rings: Array[Dictionary] = []


static func profile(person: String) -> Dictionary:
	var npc_type: String = String(Balance.dict("fair.people")[person])
	var role: Dictionary = Balance.dict("fair.roles")[npc_type]
	return {"role": person, "npc_type": npc_type, "conviction_required": float(role.conviction), "donation": int(role.donation), "requires": ""}


static func profiles(people: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for person in people:
		result.append(profile(String(person)))
	return result


static func start_position() -> Vector2:
	return Balance.vec(Balance.value("fair.start"))


static func zone_title(zone: String) -> String:
	return String(Balance.dict("fair.zones").get(zone, zone))


## Whether a show with this schedule is running `clock` seconds into the round.
static func show_running(show: Dictionary, clock: float) -> bool:
	var start: float = float(show.start)
	if clock < start:
		return false
	return fmod(clock - start, float(show.period)) < float(show.seconds)


## Seconds until this schedule's next bell, from `clock`.
static func next_bell(show: Dictionary, clock: float) -> float:
	var start: float = float(show.start)
	if clock < start:
		return start - clock
	var period: float = float(show.period)
	return period - fmod(clock - start, period)


func build_props(actors: Node2D) -> void:
	if _props_built:
		return
	_props_built = true
	for entry in PROP_LAYOUT:
		var prop: Node2D
		var kind: String = String(entry["kind"])
		if kind in ["tree", "flowers", "bench"]:
			prop = Village.VillageProp.new()
			prop.kind = kind
			prop.variant = int(entry.get("variant", 0))
		else:
			prop = FairProp.new()
			prop.kind = kind
			prop.tint = entry.get("tint", Color("c9705a"))
		prop.position = entry["at"]
		prop.name = "Fair_%s_%d" % [kind.capitalize(), actors.get_child_count()]
		actors.add_child(prop)
		prop.add_footprint()


func set_stage(index: int) -> void:
	if index != active_stage:
		active_stage = index
		queue_redraw()


func set_hoops(points: Array[Vector2], lit: int, bravo: float) -> void:
	if lit != lit_hoop or points.size() != hoops.size() or not is_equal_approx(bravo, bravo_left):
		hoops = points
		lit_hoop = lit
		bravo_left = bravo
		queue_redraw()


func set_show_rings(rings: Array[Dictionary]) -> void:
	if rings != show_rings:
		show_rings = rings
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("8f9f6c"))
	DrawShapes.oval(self, Vector2(300, 200), Vector2(360, 230), Color("98a874"))
	DrawShapes.oval(self, Vector2(1260, 900), Vector2(380, 260), Color("879863"))
	# Trodden lanes radiate from the gate to every attraction.
	var lanes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(780, 1100), Vector2(780, 860), Vector2(780, 600)]),
		PackedVector2Array([Vector2(780, 820), Vector2(520, 760), Vector2(240, 680)]),
		PackedVector2Array([Vector2(780, 820), Vector2(1040, 760), Vector2(1350, 650)]),
		PackedVector2Array([Vector2(700, 560), Vector2(470, 450), Vector2(260, 420)]),
		PackedVector2Array([Vector2(860, 560), Vector2(1080, 380), Vector2(1280, 300)]),
		PackedVector2Array([Vector2(240, 680), Vector2(350, 900), Vector2(500, 1000)]),
	]
	for lane in lanes:
		draw_polyline(lane, Color("ad9c72"), 96.0, true)
		draw_polyline(lane, Color("c8b88d"), 84.0, true)
		for point in lane:
			draw_circle(point, 42.0, Color("c8b88d"))
	# Sawdust ring of the big top, open to the lanes in front of the tent.
	DrawShapes.oval(self, Vector2(780, 440), Vector2(176, 120), Color("a98a5d"))
	DrawShapes.oval(self, Vector2(780, 440), Vector2(164, 110), Color("d8bf8a"))
	DrawShapes.oval(self, Vector2(780, 440), Vector2(150, 100), Color("e2cd9c"))
	var kerb := PackedVector2Array()
	for index in range(73):
		kerb.append(Vector2(780, 440) + Vector2.from_angle(index * TAU / 72.0) * Vector2(158, 106))
	draw_polyline(kerb, Color("b04a45"), 3.0, true)
	_draw_juggling_boards(Vector2(1275, 255))
	for index in range(Balance.list("fair.stages").size()):
		_draw_stage(index, Balance.list("fair.stages")[index])
	for ring in show_rings:
		draw_circle(ring.at, float(ring.radius), Color(1.0, 0.86, 0.45, 0.07))
		draw_arc(ring.at, float(ring.radius), 0, TAU, 72, Color(1.0, 0.82, 0.38, 0.45), 2.0, true)
	_draw_hoops()
	_draw_lanterns(PackedVector2Array([Vector2(668, 980), Vector2(780, 940), Vector2(892, 980)]))
	_draw_lanterns(PackedVector2Array([Vector2(240, 600), Vector2(470, 640), Vector2(700, 600)]))
	_draw_lanterns(PackedVector2Array([Vector2(860, 600), Vector2(1040, 440), Vector2(1220, 430), Vector2(1420, 470)]))
	_draw_lanterns(PackedVector2Array([Vector2(160, 520), Vector2(380, 470), Vector2(640, 520)]))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(706, 1080), "LANTERN FAIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("5f5a3e"))


func _draw_juggling_boards(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-95, -40), Vector2(190, 80)), Color("6f5338"))
	draw_rect(Rect2(at + Vector2(-90, -36), Vector2(180, 70)), Color("a37c52"))
	for row in range(4):
		draw_line(at + Vector2(-90, -36 + row * 18), at + Vector2(90, -36 + row * 18), Color("8c6a45"), 2.0)
	_draw_bunting(at + Vector2(-95, -44), at + Vector2(95, -44))


func _draw_stage(index: int, stage: Dictionary) -> void:
	var at: Vector2 = Balance.vec(stage.at)
	var radius: float = float(stage.radius)
	var lit: bool = index == active_stage
	DrawShapes.oval(self, at + Vector2(0, 5), Vector2(radius + 6, (radius + 6) * 0.55), Color(0.2, 0.16, 0.1, 0.25))
	match String(stage.title):
		"Crate":
			for offset in [Vector2(-22, -6), Vector2(16, -10), Vector2(-2, 10)]:
				draw_rect(Rect2(at + offset - Vector2(18, 12), Vector2(36, 24)), Color("8a6a43"))
				draw_rect(Rect2(at + offset - Vector2(15, 9), Vector2(30, 18)), Color("b48c5a"))
				draw_line(at + offset - Vector2(15, 0), at + offset + Vector2(15, 0), Color("8a6a43"), 2.0)
		"Bandstand":
			DrawShapes.oval(self, at, Vector2(radius, radius * 0.6), Color("7a5a3c"))
			DrawShapes.oval(self, at + Vector2(0, -4), Vector2(radius - 4, (radius - 4) * 0.6), Color("c39a64"))
			for spoke in range(8):
				var direction := Vector2.from_angle(spoke * TAU / 8.0)
				draw_line(at + Vector2(0, -4), at + Vector2(0, -4) + Vector2(direction.x * (radius - 6), direction.y * (radius - 6) * 0.6), Color("a07a4c"), 2.0)
		_:
			DrawShapes.oval(self, at, Vector2(radius, radius * 0.6), Color("8c3e4a"))
			DrawShapes.oval(self, at, Vector2(radius - 7, (radius - 7) * 0.6), Color("c96a63"))
			draw_arc(at, radius * 0.45, 0, TAU, 24, Color("efc77b"), 2.0, true)
	if lit:
		draw_arc(at, radius + 10, 0, TAU, 48, Color("ffe08a"), 3.0, true)
	var font := ThemeDB.fallback_font
	var caption: String = String(stage.title).to_upper() + " / STAGE"
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, at + Vector2(-width * 0.5, radius * 0.6 + 20), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("fff1c9") if lit else Color("5f4a33"))


func _draw_hoops() -> void:
	if lit_hoop < 0:
		return
	for index in range(hoops.size()):
		var at: Vector2 = hoops[index]
		var lit: bool = index == lit_hoop
		var tint := Color("ffcf5a") if lit else Color("8d6a4b")
		DrawShapes.oval(self, at, Vector2(26, 13), Color(0.18, 0.12, 0.06, 0.25))
		draw_arc(at + Vector2(0, -26), 24.0, 0, TAU, 36, tint, 5.0 if lit else 3.0, true)
		if lit:
			draw_arc(at + Vector2(0, -26), 31.0, 0, TAU, 36, Color(1.0, 0.86, 0.4, 0.45), 2.0, true)
	if bravo_left > 0.0:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(735, 330), "Bravo!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("fff0b0"))


func _draw_lanterns(points: PackedVector2Array) -> void:
	# Strings of lanterns drape between poles; drawn as ground-plane decoration.
	for index in range(points.size() - 1):
		var start: Vector2 = points[index] + Vector2(0, -150)
		var end: Vector2 = points[index + 1] + Vector2(0, -150)
		var previous: Vector2 = start
		for step in range(1, 13):
			var t: float = step / 12.0
			var at: Vector2 = start.lerp(end, t) + Vector2(0, sin(t * PI) * 34.0)
			draw_line(previous, at, Color("4f4636"), 1.5, true)
			previous = at
			if step % 2 == 0 and step < 12:
				var glow: Color = [Color("f2b84b"), Color("e86f4f"), Color("f6d77a")][step % 3]
				draw_circle(at + Vector2(0, 8), 9.0, Color(glow, 0.25))
				draw_rect(Rect2(at + Vector2(-4, 2), Vector2(8, 11)), glow)


func _draw_bunting(start: Vector2, end: Vector2) -> void:
	draw_line(start, end, Color("6b5a43"), 2, true)
	for index in range(11):
		var at: Vector2 = start.lerp(end, float(index + 1) / 12.0)
		var tint := Color("d65a4a") if index % 2 == 0 else Color("f0d27a")
		draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 0), at + Vector2(7, 0), at + Vector2(0, 14)]), tint)


class FairProp extends Node2D:
	const DrawShapes = preload("res://scripts/draw_shapes.gd")
	var kind: String = "stall"
	var tint := Color("c9705a")
	var _phase: float = 0.0

	func visual_rect() -> Rect2:
		match kind:
			"carousel": return Rect2(-125, -205, 250, 220)
			"bigtop": return Rect2(-215, -215, 430, 225)
			"stall": return Rect2(-82, -128, 164, 143)
			"post": return Rect2(-12, -160, 24, 166)
		return Rect2()

	func add_footprint() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		var collision := CollisionShape2D.new()
		collision.name = "Shape"
		collision.add_to_group("helper_obstacle_shape")
		match kind:
			"carousel":
				var circle := CircleShape2D.new()
				circle.radius = 78.0
				collision.shape = circle
				collision.position = Vector2(0, -24)
			"post":
				var circle := CircleShape2D.new()
				circle.radius = 7.0
				collision.shape = circle
			_:
				var box := RectangleShape2D.new()
				box.size = Vector2(390, 40) if kind == "bigtop" else Vector2(132, 40)
				collision.shape = box
				collision.position = Vector2(0, -18)
		body.add_child(collision)
		add_child(body)

	func _process(delta: float) -> void:
		if kind == "carousel":
			_phase += delta
			queue_redraw()

	func _draw() -> void:
		match kind:
			"carousel": _draw_carousel()
			"bigtop": _draw_bigtop()
			"stall": _draw_stall()
			"post": _draw_post()

	func _draw_carousel() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(124, 30), Color(0.2, 0.18, 0.1, 0.2))
		DrawShapes.oval(self, Vector2(0, -10), Vector2(112, 30), Color("6d4a35"))
		DrawShapes.oval(self, Vector2(0, -16), Vector2(108, 28), Color("d9b77d"))
		draw_line(Vector2(0, -16), Vector2(0, -150), Color("caa45c"), 8, true)
		# Horses ride round on their poles, a gentle bob each.
		for index in range(6):
			var angle: float = _phase * 0.9 + index * TAU / 6.0
			var at := Vector2(cos(angle) * 84.0, -24 + sin(angle) * 20.0)
			var bob: float = sin(_phase * 3.0 + index) * 4.0
			draw_line(at + Vector2(0, -122), at + Vector2(0, -10), Color("e8d29a"), 2, true)
			var coat: Color = [Color("f2ece0"), Color("c88b5a"), Color("6f6a7a")][index % 3]
			draw_rect(Rect2(at + Vector2(-13, -48 + bob), Vector2(26, 12)), coat)
			draw_rect(Rect2(at + Vector2(9, -60 + bob), Vector2(7, 14)), coat)
			draw_line(at + Vector2(-9, -36 + bob), at + Vector2(-11, -24 + bob), coat.darkened(0.3), 2)
			draw_line(at + Vector2(9, -36 + bob), at + Vector2(11, -24 + bob), coat.darkened(0.3), 2)
		var roof := PackedVector2Array([Vector2(-122, -140), Vector2(0, -200), Vector2(122, -140)])
		draw_colored_polygon(roof, Color("9d3b3f"))
		for stripe in range(6):
			var x0: float = -122.0 + stripe * 40.7
			if stripe % 2 == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(x0, -140), Vector2(0, -200), Vector2(x0 + 40.7, -140)]), Color("efe1c0"))
		for scallop in range(8):
			draw_circle(Vector2(-107 + scallop * 30.5, -140), 15.0, Color("9d3b3f") if scallop % 2 else Color("efe1c0"))
		draw_circle(Vector2(0, -204), 7, Color("f0c75e"))

	func _draw_bigtop() -> void:
		DrawShapes.oval(self, Vector2(0, 6), Vector2(214, 20), Color(0.2, 0.15, 0.1, 0.22))
		var wall := PackedVector2Array([Vector2(-200, 0), Vector2(-185, -110), Vector2(185, -110), Vector2(200, 0)])
		draw_colored_polygon(wall, Color("b8433f"))
		for stripe in range(10):
			if stripe % 2 == 0:
				var x0: float = -200.0 + stripe * 40.0
				draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 2, -110), Vector2(x0 + 38, -110), Vector2(x0 + 40, 0)]), Color("f1e3c4"))
		# The entrance flaps are drawn open, framing the ring in front.
		draw_colored_polygon(PackedVector2Array([Vector2(-50, 0), Vector2(0, -95), Vector2(50, 0)]), Color("3a2630"))
		draw_colored_polygon(PackedVector2Array([Vector2(-210, -100), Vector2(0, -205), Vector2(210, -100)]), Color("a73a3a"))
		for stripe in range(7):
			if stripe % 2 == 1:
				var x0: float = -210.0 + stripe * 60.0
				draw_colored_polygon(PackedVector2Array([Vector2(x0, -100), Vector2(0, -205), Vector2(x0 + 60, -100)]), Color("f1e3c4"))
		draw_line(Vector2(0, -205), Vector2(0, -235), Color("6b5a43"), 4)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -235), Vector2(26, -228), Vector2(0, -220)]), Color("f0c75e"))

	func _draw_stall() -> void:
		DrawShapes.oval(self, Vector2(8, 6), Vector2(88, 18), Color(0.2, 0.18, 0.1, 0.2))
		for x in [-66, 66]:
			draw_line(Vector2(x, 0), Vector2(x, -112), Color("5f4a35"), 6, true)
		draw_rect(Rect2(-72, -38, 144, 38), Color("7d5c3b"))
		draw_rect(Rect2(-68, -34, 136, 26), Color("b08a5a"))
		for index in range(6):
			var x: float = -78.0 + index * 26.0
			var cloth: Color = tint if index % 2 == 0 else Color("f1e3c4")
			draw_colored_polygon(PackedVector2Array([Vector2(x + 8, -124), Vector2(x + 34, -124), Vector2(x + 28, -82), Vector2(x, -82)]), cloth)
			DrawShapes.oval(self, Vector2(x + 13, -80), Vector2(13, 6), cloth)
		for index in range(4):
			draw_circle(Vector2(-40 + index * 26, -44), 7, Color("e9c46a") if index % 2 else Color("d9776a"))

	func _draw_post() -> void:
		draw_line(Vector2.ZERO, Vector2(0, -150), Color("5f4a35"), 6, true)
		draw_line(Vector2(-2, -2), Vector2(-2, -148), Color("9a7a52"), 2, true)
		draw_circle(Vector2(0, -150), 11, Color(0.95, 0.75, 0.35, 0.3))
		draw_rect(Rect2(-6, -158, 12, 15), Color("f2b84b"))
