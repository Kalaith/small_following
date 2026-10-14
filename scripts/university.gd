extends Node2D
## Quillmoor University: a gatehouse lawn below, Old Court to the west, New Court
## to the east, the Library Walk between them and the observatory above. Courts,
## lawns and the walk are floor drawing; the observatory, chapel, debating
## chamber, bookcases and lamps are Y-sorted props with real layer-2 footprints.
## Artwork is original procedural geometry. People and bosses are balance data
## ("university.*"); academics hear only a prepared argument.

const Village = preload("res://scripts/village.gd")
const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
const Balance = preload("res://addons/hatchery/core/balance.gd")
const WORLD_SIZE := Vector2(1560, 1100)
const AREA_ID: String = "university"

const PROP_LAYOUT = [
	{"kind": "observatory", "at": Vector2(780, 190)},
	{"kind": "chapel", "at": Vector2(1330, 330)},
	{"kind": "hall", "at": Vector2(260, 245)},
	{"kind": "shelf", "at": Vector2(620, 535)},
	{"kind": "shelf", "at": Vector2(940, 535)},
	{"kind": "shelf", "at": Vector2(620, 790)},
	{"kind": "shelf", "at": Vector2(940, 790)},
	{"kind": "sundial", "at": Vector2(1140, 590)},
	{"kind": "lamp", "at": Vector2(668, 1010)},
	{"kind": "lamp", "at": Vector2(892, 1010)},
	{"kind": "lamp", "at": Vector2(420, 460)},
	{"kind": "tree", "at": Vector2(70, 620), "variant": 0},
	{"kind": "tree", "at": Vector2(560, 140), "variant": 1},
	{"kind": "tree", "at": Vector2(1480, 560), "variant": 0},
	{"kind": "tree", "at": Vector2(300, 1040), "variant": 1},
	{"kind": "flowers", "at": Vector2(1180, 990), "variant": 1},
	{"kind": "flowers", "at": Vector2(980, 160), "variant": 0},
	{"kind": "bench", "at": Vector2(1460, 950)},
]

var _props_built: bool = false


## One Quillmoor listener's profile: the role a person plays sets the threshold
## and gift; the person sets the argument they need ("" listens to anyone).
static func profile(person: String) -> Dictionary:
	var entry: Dictionary = Balance.dict("university.people")[person]
	var role: Dictionary = Balance.dict("university.roles")[String(entry.role)]
	return {"role": person, "npc_type": String(entry.role), "conviction_required": float(role.conviction), "donation": int(role.donation), "requires": "", "argument": String(entry.argument)}


static func profiles(people: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for person in people:
		result.append(profile(String(person)))
	return result


static func start_position() -> Vector2:
	return Balance.vec(Balance.value("university.start"))


static func zone_title(zone: String) -> String:
	return String(Balance.dict("university.zones").get(zone, zone))


## Academics in the university's groups who need `argument`, counting the
## followers of every boss convinced so far; shown on the ritual screen's cards.
static func academics_needing(argument: String, stage: int) -> int:
	var count: int = 0
	var groups: Array = Balance.list("university.groups").duplicate()
	for entry in Balance.list("university.follower_groups"):
		if stage >= int(entry.stage):
			groups.append(entry)
	for group in groups:
		for person in group.people:
			if String(Balance.dict("university.people")[String(person)].argument) == argument:
				count += 1
	return count


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
			prop = UniversityProp.new()
			prop.kind = kind
		prop.position = entry["at"]
		prop.name = "University_%s_%d" % [kind.capitalize(), actors.get_child_count()]
		actors.add_child(prop)
		prop.add_footprint()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("93a573"))
	# Gatehouse Lawn: a striped, mown lawn and the gravel drive from the gate.
	draw_rect(Rect2(0, 840, 1560, 260), Color("9db37a"))
	for stripe in range(0, 1560, 120):
		draw_rect(Rect2(stripe, 840, 60, 260), Color("a5bb82"))
	_draw_paving(Rect2(130, 400, 520, 420), Color("b9ad93"), Color("c9bea6"))
	_draw_paving(Rect2(920, 380, 540, 440), Color("b4ab95"), Color("c5bda9"))
	# The Library Walk: a long covered colonnade linking the two courts.
	draw_rect(Rect2(560, 560, 440, 200), Color("8a7a62"))
	draw_rect(Rect2(570, 570, 420, 180), Color("a8977a"))
	for index in range(12):
		draw_rect(Rect2(580 + index * 35, 575, 22, 170), Color("b3a385"))
	var walks: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(780, 1100), Vector2(780, 860), Vector2(780, 760)]),
		PackedVector2Array([Vector2(780, 560), Vector2(780, 300)]),
		PackedVector2Array([Vector2(640, 870), Vector2(400, 820)]),
		PackedVector2Array([Vector2(920, 870), Vector2(1180, 820)]),
		PackedVector2Array([Vector2(390, 400), Vector2(390, 300), Vector2(330, 260)]),
	]
	for walk in walks:
		draw_polyline(walk, Color("b5a685"), 70.0, true)
		draw_polyline(walk, Color("d2c4a2"), 60.0, true)
		for point in walk:
			draw_circle(point, 30.0, Color("d2c4a2"))
	# The observatory's round terrace and its brass meridian line.
	DrawShapes.oval(self, Vector2(780, 290), Vector2(150, 70), Color("a89c86"))
	DrawShapes.oval(self, Vector2(780, 290), Vector2(138, 62), Color("c6bba3"))
	draw_line(Vector2(650, 290), Vector2(910, 290), Color("b8913f"), 3.0, true)
	# Quillmoor's gate: two stone piers at the bottom of the drive.
	for x in [700.0, 860.0]:
		draw_rect(Rect2(x - 18, 1040, 36, 60), Color("8d826e"))
		draw_rect(Rect2(x - 22, 1032, 44, 12), Color("a69a83"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(683, 1088), "QUILLMOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("4d4a3a"))
	for zone in [["OLD COURT", Vector2(150, 395)], ["NEW COURT", Vector2(1290, 375)], ["LIBRARY WALK", Vector2(718, 553)]]:
		draw_string(font, zone[1], zone[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("5d5644"))


## A quadrangle of flagstones with a lighter cross path through its middle.
func _draw_paving(area: Rect2, edge: Color, stone: Color) -> void:
	draw_rect(area.grow(8), edge)
	draw_rect(area, stone)
	for row in range(int(area.size.y / 36.0)):
		for column in range(int(area.size.x / 48.0)):
			var at := area.position + Vector2(column * 48 + (row % 2) * 24, row * 36)
			if at.x + 44 <= area.end.x:
				draw_rect(Rect2(at + Vector2(2, 2), Vector2(44, 32)), stone.lightened(0.05 if (row + column) % 3 else 0.12))
	draw_rect(Rect2(area.position.x, area.get_center().y - 22, area.size.x, 44), stone.lightened(0.16))
	draw_rect(Rect2(area.get_center().x - 22, area.position.y, 44, area.size.y), stone.lightened(0.16))


class UniversityProp extends Node2D:
	const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
	var kind: String = "shelf"

	func visual_rect() -> Rect2:
		match kind:
			"observatory": return Rect2(-95, -190, 190, 205)
			"chapel": return Rect2(-120, -215, 240, 230)
			"hall": return Rect2(-125, -175, 250, 190)
			"shelf": return Rect2(-40, -82, 80, 90)
			"sundial": return Rect2(-22, -40, 44, 48)
			"lamp": return Rect2(-12, -130, 24, 136)
		return Rect2()

	func add_footprint() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		var collision := CollisionShape2D.new()
		collision.name = "Shape"
		collision.add_to_group("helper_obstacle_shape")
		match kind:
			"observatory", "sundial", "lamp":
				var circle := CircleShape2D.new()
				circle.radius = {"observatory": 70.0, "sundial": 14.0, "lamp": 7.0}[kind]
				collision.shape = circle
				collision.position = Vector2(0, -20) if kind == "observatory" else Vector2.ZERO
			_:
				var box := RectangleShape2D.new()
				box.size = {"chapel": Vector2(210, 60), "hall": Vector2(220, 60), "shelf": Vector2(70, 22)}[kind]
				collision.shape = box
				collision.position = Vector2(0, -24) if kind != "shelf" else Vector2(0, -8)
		body.add_child(collision)
		add_child(body)

	func _draw() -> void:
		match kind:
			"observatory": _draw_observatory()
			"chapel": _draw_chapel()
			"hall": _draw_hall()
			"shelf": _draw_shelf()
			"sundial": _draw_sundial()
			"lamp": _draw_lamp()

	func _draw_observatory() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(92, 22), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-72, -110, 144, 110), Color("9a8f7c"))
		draw_rect(Rect2(-66, -106, 132, 102), Color("b7ac96"))
		for row in range(5):
			draw_line(Vector2(-66, -86 + row * 20), Vector2(66, -86 + row * 20), Color("a3977f"), 2.0)
		draw_rect(Rect2(-16, -52, 32, 52), Color("4a3d30"))
		draw_arc(Vector2(0, -52), 16, PI, TAU, 16, Color("4a3d30"), 2.0, true)
		# A copper dome with its open shutter and a telescope looking out.
		draw_colored_polygon(PackedVector2Array([Vector2(-80, -110), Vector2(80, -110), Vector2(64, -150), Vector2(32, -176), Vector2(0, -184), Vector2(-32, -176), Vector2(-64, -150)]), Color("5f8f86"))
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -110), Vector2(10, -110), Vector2(8, -182), Vector2(-8, -182)]), Color("2f3a46"))
		draw_line(Vector2(0, -150), Vector2(34, -186), Color("c9a24f"), 6.0, true)
		draw_line(Vector2(-80, -110), Vector2(80, -110), Color("7a6a52"), 4.0)

	func _draw_chapel() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(118, 22), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-100, -120, 200, 120), Color("c8bea7"))
		draw_colored_polygon(PackedVector2Array([Vector2(-112, -118), Vector2(0, -170), Vector2(112, -118)]), Color("6d5f78"))
		draw_rect(Rect2(-24, -200, 48, 82), Color("bfb49c"))
		draw_colored_polygon(PackedVector2Array([Vector2(-30, -198), Vector2(0, -230), Vector2(30, -198)]), Color("5d4f68"))
		draw_line(Vector2(0, -230), Vector2(0, -246), Color("c9a24f"), 3.0)
		draw_line(Vector2(-6, -240), Vector2(6, -240), Color("c9a24f"), 3.0)
		for x in [-70, -36, 36, 70]:
			draw_rect(Rect2(x - 9, -96, 18, 40), Color("6f88a6"))
			draw_arc(Vector2(x, -96), 9, PI, TAU, 10, Color("6f88a6"), 4.0, true)
		draw_rect(Rect2(-16, -56, 32, 56), Color("5a4334"))
		draw_arc(Vector2(0, -56), 16, PI, TAU, 16, Color("5a4334"), 3.0, true)

	func _draw_hall() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(122, 22), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-110, -110, 220, 110), Color("b98f6b"))
		for x in range(-96, 100, 32):
			draw_rect(Rect2(x, -100, 10, 100), Color("e6d8bc"))
		draw_colored_polygon(PackedVector2Array([Vector2(-122, -108), Vector2(0, -170), Vector2(122, -108)]), Color("8a3b46"))
		draw_colored_polygon(PackedVector2Array([Vector2(-90, -114), Vector2(0, -158), Vector2(90, -114)]), Color("e6d8bc"))
		draw_circle(Vector2(0, -132), 9, Color("8a3b46"))
		draw_rect(Rect2(-20, -60, 40, 60), Color("4a3328"))

	func _draw_shelf() -> void:
		DrawShapes.oval(self, Vector2(4, 4), Vector2(40, 9), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-36, -80, 72, 80), Color("5f4530"))
		for row in range(4):
			draw_rect(Rect2(-32, -74 + row * 19, 64, 3), Color("7a5a3e"))
			for book in range(8):
				var tint: Color = [Color("8a3b46"), Color("3c5a78"), Color("6b7a3a"), Color("b8913f")][(book + row) % 4]
				draw_rect(Rect2(-31 + book * 8, -88 + (row + 1) * 19, 6, 15 - (book % 3)), tint)

	func _draw_sundial() -> void:
		DrawShapes.oval(self, Vector2(2, 2), Vector2(20, 7), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-8, -26, 16, 26), Color("a69a83"))
		DrawShapes.oval(self, Vector2(0, -28), Vector2(20, 8), Color("c9bea6"))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -28), Vector2(10, -28), Vector2(-2, -40)]), Color("b8913f"))

	func _draw_lamp() -> void:
		draw_line(Vector2.ZERO, Vector2(0, -118), Color("3a3640"), 5, true)
		draw_circle(Vector2(0, -124), 12, Color(0.95, 0.85, 0.5, 0.25))
		draw_rect(Rect2(-7, -132, 14, 16), Color("f2d58a"))
		draw_rect(Rect2(-9, -135, 18, 4), Color("3a3640"))
