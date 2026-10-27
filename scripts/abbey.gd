extends Node2D
## The hilltop abbey: the Pilgrim Gate and camp at the foot, the cloister with
## its well, scriptorium and herb garden in the middle, and the Abbey Terrace
## above a processional stair, where the Pope sits before the church doors.
## Lawns, gravel and terraces are floor drawing; walls, arcades, the well, the
## church, towers and cypresses are Y-sorted props with real layer-2 footprints.
## Artwork is original procedural geometry. People are balance data ("abbey.*").

const Village = preload("res://scripts/village.gd")
const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
const Balance = preload("res://addons/hatchery/core/balance.gd")
## As large as Rosecourt, so the terrace has room for a whole procession.
const WORLD_SIZE := Vector2(2240, 1560)
const AREA_ID: String = "abbey"
## Huddles stand tighter than the older maps' crowds.
const HUDDLE: float = 0.7

## Walls are long rows; the gaps between them are the gate and the processional
## stair, each wide enough for the helper's grid.
const PROP_LAYOUT = [
	{"kind": "church", "at": Vector2(1120, 250)},
	{"kind": "tower", "at": Vector2(610, 262)},
	{"kind": "tower", "at": Vector2(1630, 262)},
	{"kind": "well", "at": Vector2(1120, 830)},
	{"kind": "hall", "at": Vector2(300, 760), "variant": 0},
	{"kind": "hall", "at": Vector2(1960, 800), "variant": 1},
	{"kind": "wall", "at": Vector2(500, 1150), "length": 760},
	{"kind": "wall", "at": Vector2(1740, 1150), "length": 760},
	{"kind": "wall", "at": Vector2(550, 580), "length": 820},
	{"kind": "wall", "at": Vector2(1690, 580), "length": 820},
	{"kind": "arcade", "at": Vector2(820, 1000), "length": 330},
	{"kind": "arcade", "at": Vector2(1440, 1020), "length": 300},
	{"kind": "cypress", "at": Vector2(1020, 1120)},
	{"kind": "cypress", "at": Vector2(1220, 1120)},
	{"kind": "cypress", "at": Vector2(950, 567)},
	{"kind": "cypress", "at": Vector2(1290, 567)},
	{"kind": "cypress", "at": Vector2(380, 1440)},
	{"kind": "cypress", "at": Vector2(1860, 1440)},
	{"kind": "cross", "at": Vector2(1850, 1250)},
	{"kind": "cross", "at": Vector2(260, 1030)},
	{"kind": "cross", "at": Vector2(2010, 480)},
	{"kind": "statue", "at": Vector2(180, 470)},
	{"kind": "tent", "at": Vector2(380, 1370)},
	{"kind": "tent", "at": Vector2(740, 1420)},
	{"kind": "tent", "at": Vector2(1400, 1420)},
	{"kind": "tree", "at": Vector2(115, 200), "variant": 0},
	{"kind": "tree", "at": Vector2(2125, 213), "variant": 1},
	{"kind": "tree", "at": Vector2(100, 1432), "variant": 1},
	{"kind": "tree", "at": Vector2(2140, 1418), "variant": 0},
	{"kind": "tree", "at": Vector2(2110, 908), "variant": 1},
	{"kind": "tree", "at": Vector2(110, 1020), "variant": 0},
	{"kind": "bench", "at": Vector2(1752, 1078)},
	{"kind": "bench", "at": Vector2(300, 1260)},
	{"kind": "flowers", "at": Vector2(1000, 1475), "variant": 0},
	{"kind": "flowers", "at": Vector2(1250, 1475), "variant": 1},
	{"kind": "flowers", "at": Vector2(1830, 300), "variant": 0},
]

var _props_built: bool = false


## One person's profile: the role sets the threshold, the gift and the plea.
static func profile(person: String) -> Dictionary:
	var role_id: String = String(Balance.dict("abbey.people")[person])
	var role: Dictionary = Balance.dict("abbey.roles")[role_id]
	return {"role": person, "npc_type": role_id, "conviction_required": float(role.conviction), "donation": int(role.donation), "requires": "", "argument": "", "reserved": false}


static func profiles(people: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for person in people:
		result.append(profile(String(person)))
	return result


static func start_position() -> Vector2:
	return Balance.vec(Balance.value("abbey.start"))


static func zone_title(zone: String) -> String:
	return String(Balance.dict("abbey.zones").get(zone, zone))


## Where the won stand to plead before the Pope, nearest the throne first: rows
## of "abbey.procession.rows.step" spacing, each row a little wider than the last.
static func plea_slots() -> Array[Vector2]:
	var rows: Dictionary = Balance.dict("abbey.procession.rows")
	var centre: float = Balance.vec(Balance.value("abbey.pope.at")).x
	var slots: Array[Vector2] = []
	for row in range(rows.counts.size()):
		var count: int = int(rows.counts[row])
		for index in range(count):
			slots.append(Vector2(centre + (index - (count - 1) * 0.5) * float(rows.step), float(rows.y) + row * float(rows.gap)))
	var throne: Vector2 = Balance.vec(Balance.value("abbey.pope.at"))
	slots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(throne) < b.distance_to(throne))
	return slots


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
			prop = AbbeyProp.new()
			prop.kind = kind
			prop.length = float(entry.get("length", 0.0))
			prop.variant = int(entry.get("variant", 0))
		prop.position = entry["at"]
		prop.name = "Abbey_%s_%d" % [kind.capitalize(), actors.get_child_count()]
		actors.add_child(prop)
		prop.add_footprint()


func _draw() -> void:
	# The terrace is pale paving; the cloister and the pilgrim yard are mown grass.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("8fa66c"))
	draw_rect(Rect2(0, 0, WORLD_SIZE.x, 570), Color("c9c6bd"))
	for row in range(0, 570, 40):
		draw_line(Vector2(0, row), Vector2(WORLD_SIZE.x, row), Color("bdbab0"), 1.0)
	for column in range(0, int(WORLD_SIZE.x), 120):
		draw_line(Vector2(column, 0), Vector2(column, 570), Color("c2bfb5"), 1.0)
	draw_rect(Rect2(0, 570, WORLD_SIZE.x, 580), Color("94ad70"))
	draw_rect(Rect2(0, 1150, WORLD_SIZE.x, 410), Color("a39b6c"))
	for stripe in range(0, int(WORLD_SIZE.x), 130):
		draw_rect(Rect2(stripe, 1150, 65, 410), Color("a9a173"))
	# The Pilgrim Way: a gravel road from the gate to the well and on up the stair.
	draw_rect(Rect2(1050, 570, 140, 990), Color("b8a98a"))
	draw_rect(Rect2(1060, 570, 120, 990), Color("d6c9a8"))
	for y in range(590, 1560, 46):
		draw_rect(Rect2(1048, y, 6, 6), Color("8d826e"))
		draw_rect(Rect2(1186, y + 23, 6, 6), Color("8d826e"))
	# The well court: a round of flagstones.
	DrawShapes.oval(self, Vector2(1120, 830), Vector2(270, 160), Color("b4a88c"))
	DrawShapes.oval(self, Vector2(1120, 830), Vector2(258, 150), Color("d2c7ac"))
	# Paths out to the scriptorium and the herb garden.
	draw_rect(Rect2(450, 890, 420, 60), Color("d6c9a8"))
	draw_rect(Rect2(1370, 870, 470, 60), Color("d6c9a8"))
	# The processional stair, the violet runner and the floor where the won plead.
	draw_rect(Rect2(1030, 280, 180, 290), Color("e2dccd"))
	for step in range(5):
		draw_line(Vector2(1030, 310 + step * 52), Vector2(1210, 310 + step * 52), Color("c9c2b2"), 2.0)
	draw_rect(Rect2(1095, 280, 50, 290), Color("5b3f8a"))
	DrawShapes.oval(self, Vector2(1120, 430), Vector2(460, 170), Color("bcb8ac"))
	DrawShapes.oval(self, Vector2(1120, 430), Vector2(446, 160), Color("d8d4c8"))
	# The pilgrim gate.
	for x in [1020.0, 1220.0]:
		draw_rect(Rect2(x - 16, 1500, 32, 60), Color("8d826e"))
		draw_rect(Rect2(x - 20, 1494, 40, 8), Color("c9c2b2"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(1040, 1552), "THE ABBEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("4a3a5e"))
	for zone in [["PILGRIM GATE", Vector2(80, 1200)], ["SCRIPTORIUM", Vector2(80, 850)], ["CLOISTER", Vector2(1420, 680)], ["ABBEY TERRACE", Vector2(200, 50)]]:
		draw_string(font, zone[1], zone[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("5d4a44"))


class AbbeyProp extends Node2D:
	const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
	var kind: String = "wall"
	## A wall's or arcade's width in pixels; other props ignore it.
	var length: float = 0.0
	## Which hall: 0 the scriptorium, 1 the infirmary.
	var variant: int = 0

	func visual_rect() -> Rect2:
		match kind:
			"church": return Rect2(-270, -300, 540, 320)
			"tower": return Rect2(-50, -250, 100, 262)
			"well": return Rect2(-70, -90, 140, 120)
			"hall": return Rect2(-140, -170, 280, 185)
			"wall": return Rect2(-length * 0.5, -46, length, 56)
			"arcade": return Rect2(-length * 0.5, -96, length, 106)
			"cypress": return Rect2(-20, -110, 40, 116)
			"cross": return Rect2(-18, -64, 36, 70)
			"statue": return Rect2(-22, -96, 44, 104)
			"tent": return Rect2(-50, -70, 100, 78)
		return Rect2()

	func add_footprint() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		var collision := CollisionShape2D.new()
		collision.name = "Shape"
		collision.add_to_group("helper_obstacle_shape")
		match kind:
			"well", "cypress", "cross", "statue":
				var circle := CircleShape2D.new()
				circle.radius = {"well": 56.0, "cypress": 14.0, "cross": 14.0, "statue": 16.0}[kind]
				collision.shape = circle
				collision.position = Vector2(0, -14) if kind == "well" else Vector2.ZERO
			_:
				var box := RectangleShape2D.new()
				var sizes: Dictionary = {"church": Vector2(520, 60), "tower": Vector2(80, 50), "hall": Vector2(250, 56), "wall": Vector2(length, 26), "arcade": Vector2(length, 30), "tent": Vector2(84, 30)}
				box.size = sizes[kind]
				collision.shape = box
				collision.position = Vector2(0, -24) if kind in ["church", "hall", "tower"] else Vector2(0, -8)
		body.add_child(collision)
		add_child(body)

	func _draw() -> void:
		match kind:
			"church": _draw_church()
			"tower": _draw_tower()
			"well": _draw_well()
			"hall": _draw_hall()
			"wall": _draw_wall()
			"arcade": _draw_arcade()
			"cypress": _draw_cypress()
			"cross": _draw_cross()
			"statue": _draw_statue()
			"tent": _draw_tent()

	func _draw_church() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(270, 24), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-260, -24, 520, 24), Color("d8d2c2"))
		draw_rect(Rect2(-250, -190, 500, 168), Color("e8e2d2"))
		# The nave's gable and the great rose window above the doors.
		draw_colored_polygon(PackedVector2Array([Vector2(-250, -190), Vector2(0, -290), Vector2(250, -190)]), Color("d9d2bf"))
		draw_polyline(PackedVector2Array([Vector2(-250, -190), Vector2(0, -290), Vector2(250, -190)]), Color("b9b19c"), 3.0)
		draw_circle(Vector2(0, -196), 44, Color("c2486a"))
		draw_circle(Vector2(0, -196), 36, Color("5b3f8a"))
		for petal in range(8):
			draw_line(Vector2(0, -196), Vector2(0, -196) + Vector2.from_angle(petal * TAU / 8.0) * 36.0, Color("e0c06a"), 2.0)
		draw_arc(Vector2(0, -196), 36, 0, TAU, 32, Color("e0c06a"), 2.0, true)
		# Pillars and tall windows either side of the great doors.
		for x in [-200, -150, 150, 200]:
			draw_rect(Rect2(x - 16, -150, 32, 70), Color("5b3f8a"))
			draw_arc(Vector2(x, -150), 16, PI, TAU, 12, Color("5b3f8a"), 10.0, true)
		draw_rect(Rect2(-56, -126, 112, 104), Color("6b5236"))
		draw_arc(Vector2(0, -126), 56, PI, TAU, 24, Color("6b5236"), 10.0, true)
		draw_line(Vector2(0, -170), Vector2(0, -22), Color("3f2f1e"), 3.0)
		draw_line(Vector2(0, -330), Vector2(0, -290), Color("c9a24f"), 4.0)
		draw_line(Vector2(-12, -318), Vector2(12, -318), Color("c9a24f"), 4.0)

	func _draw_tower() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(54, 14), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-40, -200, 80, 200), Color("d9d2bf"))
		draw_rect(Rect2(-40, -200, 14, 200), Color("c8c0aa"))
		for y in range(-180, 0, 40):
			draw_line(Vector2(-40, y), Vector2(40, y), Color("b9b19c"), 1.0)
		draw_rect(Rect2(-18, -170, 36, 56), Color("3f2f4a"))
		draw_arc(Vector2(0, -170), 18, PI, TAU, 12, Color("3f2f4a"), 8.0, true)
		draw_circle(Vector2(0, -150), 8, Color("c9a24f"))
		draw_colored_polygon(PackedVector2Array([Vector2(-48, -200), Vector2(0, -250), Vector2(48, -200)]), Color("7a4a5e"))

	func _draw_well() -> void:
		DrawShapes.oval(self, Vector2(4, 4), Vector2(74, 22), Color(0.2, 0.18, 0.12, 0.2))
		DrawShapes.oval(self, Vector2(0, -12), Vector2(64, 24), Color("a69a83"))
		DrawShapes.oval(self, Vector2(0, -16), Vector2(52, 18), Color("4f6a7a"))
		for x in [-44, 44]:
			draw_line(Vector2(x, -14), Vector2(x, -74), Color("6b5a44"), 5.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-56, -72), Vector2(0, -96), Vector2(56, -72)]), Color("7a4a5e"))
		draw_line(Vector2(0, -80), Vector2(0, -38), Color("8a7a60"), 2.0)
		draw_rect(Rect2(-6, -40, 12, 10), Color("6b5a44"))

	func _draw_hall() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(140, 22), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-130, -26, 260, 26), Color("c9bea6"))
		draw_rect(Rect2(-124, -120, 248, 96), Color("e2dccd") if variant == 0 else Color("e8dccf"))
		draw_colored_polygon(PackedVector2Array([Vector2(-136, -120), Vector2(-100, -160), Vector2(100, -160), Vector2(136, -120)]), Color("8a5a46") if variant == 0 else Color("6e7f8e"))
		for x in range(-100, 110, 50):
			draw_rect(Rect2(x - 12, -96, 24, 46), Color("4a3f5a"))
			draw_arc(Vector2(x, -96), 12, PI, TAU, 10, Color("4a3f5a"), 6.0, true)
		if variant == 0:
			# A lectern and a sheaf of pages in the doorway.
			draw_rect(Rect2(-12, -52, 24, 28), Color("6b5236"))
			draw_rect(Rect2(-9, -62, 18, 10), Color("f4efe0"))
		else:
			# A red cross on the infirmary wall.
			draw_rect(Rect2(-6, -108, 12, 36), Color("b2384a"))
			draw_rect(Rect2(-18, -96, 36, 12), Color("b2384a"))

	func _draw_wall() -> void:
		var half: float = length * 0.5
		DrawShapes.oval(self, Vector2(0, 4), Vector2(half + 6, 12), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-half, -44, length, 46), Color("bdb5a0"))
		draw_rect(Rect2(-half, -48, length, 10), Color("d3ccb8"))
		for x in range(int(-half) + 20, int(half), 40):
			draw_line(Vector2(x, -38), Vector2(x, 0), Color("a9a18c"), 1.0)

	func _draw_arcade() -> void:
		var half: float = length * 0.5
		DrawShapes.oval(self, Vector2(0, 4), Vector2(half + 6, 12), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-half, -30, length, 32), Color("d3ccb8"))
		draw_rect(Rect2(-half - 4, -96, length + 8, 12), Color("a9805e"))
		for x in range(int(-half) + 20, int(half), 40):
			draw_rect(Rect2(x - 5, -86, 10, 58), Color("ece6d6"))
			draw_arc(Vector2(x + 20, -84), 15, PI, TAU, 10, Color("ece6d6"), 4.0, true)

	func _draw_cypress() -> void:
		DrawShapes.oval(self, Vector2(2, 2), Vector2(16, 6), Color(0.2, 0.18, 0.12, 0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -6), Vector2(-9, -60), Vector2(0, -112), Vector2(9, -60), Vector2(14, -6)]), Color("2f5030"))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -20), Vector2(-4, -64), Vector2(0, -96), Vector2(3, -60), Vector2(6, -20)]), Color("3f6b3a"))

	func _draw_cross() -> void:
		DrawShapes.oval(self, Vector2(2, 2), Vector2(18, 6), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-14, -10, 28, 10), Color("bdb3a0"))
		draw_rect(Rect2(-4, -62, 8, 54), Color("d8d2c2"))
		draw_rect(Rect2(-16, -50, 32, 8), Color("d8d2c2"))

	func _draw_statue() -> void:
		DrawShapes.oval(self, Vector2(2, 2), Vector2(20, 7), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-18, -24, 36, 24), Color("bdb3a0"))
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -24), Vector2(10, -24), Vector2(7, -72), Vector2(-7, -72)]), Color("e2dccd"))
		draw_circle(Vector2(0, -80), 9, Color("e2dccd"))
		draw_arc(Vector2(0, -82), 14, PI * 1.1, PI * 1.9, 8, Color("e0c06a"), 2.0, true)

	func _draw_tent() -> void:
		DrawShapes.oval(self, Vector2(4, 4), Vector2(54, 12), Color(0.2, 0.18, 0.12, 0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-48, 0), Vector2(0, -68), Vector2(48, 0)]), Color("b99361"))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(0, -34), Vector2(14, 0)]), Color("5a4630"))
		draw_line(Vector2(0, -68), Vector2(0, -78), Color("6b5a44"), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -78), Vector2(16, -73), Vector2(0, -68)]), Color("c2486a"))
