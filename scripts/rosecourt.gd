extends Node2D
## Rosecourt, the King's garden: the Lower Lawn at the gate, the Rose Walk up
## between clipped hedges, the Fountain Terrace with the Orangery on its west
## flank and the King's Pavilion on the top terrace. Lawns, gravel and terraces
## are floor drawing; hedges, the fountain, the orangery, the pavilion, arches
## and topiary are Y-sorted props with real layer-2 footprints. Artwork is
## original procedural geometry. Guests are balance data ("rosecourt.*").

const Village = preload("res://scripts/village.gd")
const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
const Balance = preload("res://addons/hatchery/core/balance.gd")
## Larger than the other maps, so the salons stand well apart.
const WORLD_SIZE := Vector2(2240, 1560)
const AREA_ID: String = "rosecourt"
## Salon huddles stand this much tighter than other maps' crowds.
const HUDDLE: float = 0.7

## Hedges are long rows; the gaps between them are the routes up the garden,
## each wide enough for the helper's grid.
const PROP_LAYOUT = [
	{"kind": "pavilion", "at": Vector2(1120, 240)},
	{"kind": "fountain", "at": Vector2(1120, 830)},
	{"kind": "orangery", "at": Vector2(290, 740)},
	{"kind": "arch", "at": Vector2(1850, 795)},
	{"kind": "hedge", "at": Vector2(565, 1150), "length": 670},
	{"kind": "hedge", "at": Vector2(1675, 1150), "length": 670},
	{"kind": "hedge", "at": Vector2(675, 580), "length": 430},
	{"kind": "hedge", "at": Vector2(1565, 580), "length": 430},
	{"kind": "topiary", "at": Vector2(1020, 1120)},
	{"kind": "topiary", "at": Vector2(1220, 1120)},
	{"kind": "topiary", "at": Vector2(1000, 567)},
	{"kind": "topiary", "at": Vector2(1240, 567)},
	{"kind": "topiary", "at": Vector2(380, 1420)},
	{"kind": "roses", "at": Vector2(1030, 1276)},
	{"kind": "roses", "at": Vector2(1210, 1276)},
	{"kind": "roses", "at": Vector2(1867, 993)},
	{"kind": "roses", "at": Vector2(230, 425)},
	{"kind": "roses", "at": Vector2(1900, 1420)},
	{"kind": "roses", "at": Vector2(1500, 330)},
	{"kind": "statue", "at": Vector2(2010, 510)},
	{"kind": "statue", "at": Vector2(300, 1040)},
	{"kind": "tree", "at": Vector2(115, 200), "variant": 0},
	{"kind": "tree", "at": Vector2(2125, 213), "variant": 1},
	{"kind": "tree", "at": Vector2(100, 1432), "variant": 1},
	{"kind": "tree", "at": Vector2(2140, 1418), "variant": 0},
	{"kind": "tree", "at": Vector2(2110, 908), "variant": 1},
	{"kind": "tree", "at": Vector2(110, 1020), "variant": 0},
	{"kind": "bench", "at": Vector2(1752, 1078)},
	{"kind": "bench", "at": Vector2(300, 1260)},
	{"kind": "flowers", "at": Vector2(804, 1475), "variant": 0},
	{"kind": "flowers", "at": Vector2(1436, 1475), "variant": 1},
	{"kind": "flowers", "at": Vector2(546, 284), "variant": 1},
	{"kind": "flowers", "at": Vector2(1780, 300), "variant": 0},
]

var _props_built: bool = false


## One Rosecourt guest's profile: the role sets the threshold, the gift and
## whether the guest is reserved (waits for a whispered introduction).
static func profile(person: String) -> Dictionary:
	var role_id: String = String(Balance.dict("rosecourt.people")[person])
	var role: Dictionary = Balance.dict("rosecourt.roles")[role_id]
	return {"role": person, "npc_type": role_id, "conviction_required": float(role.conviction), "donation": int(role.donation), "requires": "", "argument": "", "reserved": bool(role.reserved)}


static func profiles(people: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for person in people:
		result.append(profile(String(person)))
	return result


static func start_position() -> Vector2:
	return Balance.vec(Balance.value("rosecourt.start"))


static func zone_title(zone: String) -> String:
	return String(Balance.dict("rosecourt.zones").get(zone, zone))


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
			prop = GardenProp.new()
			prop.kind = kind
			prop.length = float(entry.get("length", 0.0))
		prop.position = entry["at"]
		prop.name = "Rosecourt_%s_%d" % [kind.capitalize(), actors.get_child_count()]
		actors.add_child(prop)
		prop.add_footprint()


func _draw() -> void:
	# The top terrace is pale gravel; the middle terrace and the Lower Lawn are mown grass.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("8fa66c"))
	draw_rect(Rect2(0, 0, WORLD_SIZE.x, 570), Color("cfc4a8"))
	for row in range(0, 570, 40):
		draw_line(Vector2(0, row), Vector2(WORLD_SIZE.x, row), Color("c6baa0"), 1.0)
	draw_rect(Rect2(0, 570, WORLD_SIZE.x, 580), Color("94ad70"))
	draw_rect(Rect2(0, 1150, WORLD_SIZE.x, 410), Color("9ab575"))
	for stripe in range(0, int(WORLD_SIZE.x), 130):
		draw_rect(Rect2(stripe, 1150, 65, 410), Color("a3bd7e"))
	# The Rose Walk: a gravel path from the gate to the fountain and on up to the pavilion.
	draw_rect(Rect2(1050, 570, 140, 990), Color("b8a98a"))
	draw_rect(Rect2(1060, 570, 120, 990), Color("d6c9a8"))
	for y in range(590, 1560, 46):
		draw_circle(Vector2(1052, y), 7.0, Color("c2486a"))
		draw_circle(Vector2(1188, y + 23), 7.0, Color("c2486a"))
	# The Fountain Terrace: a round of flagstones.
	DrawShapes.oval(self, Vector2(1120, 830), Vector2(270, 160), Color("b4a88c"))
	DrawShapes.oval(self, Vector2(1120, 830), Vector2(258, 150), Color("d2c7ac"))
	# Paths out to the Orangery and the Rose arbour.
	draw_rect(Rect2(450, 890, 420, 60), Color("d6c9a8"))
	draw_rect(Rect2(1370, 870, 470, 60), Color("d6c9a8"))
	# The pavilion's stair and the red carpet up to the throne.
	draw_rect(Rect2(1030, 280, 180, 290), Color("e2d9c2"))
	for step in range(5):
		draw_line(Vector2(1030, 310 + step * 52), Vector2(1210, 310 + step * 52), Color("c9bea4"), 2.0)
	draw_rect(Rect2(1095, 280, 50, 290), Color("9b2f45"))
	# The garden gate.
	for x in [1020.0, 1220.0]:
		draw_rect(Rect2(x - 16, 1500, 32, 60), Color("8d826e"))
		DrawShapes.oval(self, Vector2(x, 1496), Vector2(20, 8), Color("c9a24f"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(1040, 1552), "ROSECOURT", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("5a2a3a"))
	for zone in [["LOWER LAWN", Vector2(80, 1200)], ["ORANGERY", Vector2(80, 850)], ["FOUNTAIN TERRACE", Vector2(1420, 680)], ["THE KING'S PAVILION", Vector2(200, 50)]]:
		draw_string(font, zone[1], zone[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("5d4a44"))


class GardenProp extends Node2D:
	const DrawShapes = preload("res://addons/hatchery/draw/shapes.gd")
	var kind: String = "hedge"
	## A hedge row's width in pixels; other props ignore it.
	var length: float = 0.0

	func visual_rect() -> Rect2:
		match kind:
			"pavilion": return Rect2(-150, -165, 300, 180)
			"fountain": return Rect2(-95, -95, 190, 130)
			"orangery": return Rect2(-140, -170, 280, 185)
			"arch": return Rect2(-50, -110, 100, 118)
			"hedge": return Rect2(-length * 0.5, -46, length, 56)
			"topiary": return Rect2(-22, -70, 44, 76)
			"roses": return Rect2(-24, -26, 48, 32)
			"statue": return Rect2(-22, -96, 44, 104)
		return Rect2()

	func add_footprint() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		var collision := CollisionShape2D.new()
		collision.name = "Shape"
		collision.add_to_group("helper_obstacle_shape")
		match kind:
			"fountain", "topiary", "roses", "statue":
				var circle := CircleShape2D.new()
				circle.radius = {"fountain": 82.0, "topiary": 16.0, "roses": 18.0, "statue": 16.0}[kind]
				collision.shape = circle
				collision.position = Vector2(0, -18) if kind == "fountain" else Vector2.ZERO
			_:
				var box := RectangleShape2D.new()
				var sizes: Dictionary = {"pavilion": Vector2(260, 60), "orangery": Vector2(250, 56), "arch": Vector2(90, 16), "hedge": Vector2(length, 26)}
				box.size = sizes[kind]
				collision.shape = box
				collision.position = Vector2(0, -24) if kind in ["pavilion", "orangery"] else Vector2(0, -8)
		body.add_child(collision)
		add_child(body)

	func _draw() -> void:
		match kind:
			"pavilion": _draw_pavilion()
			"fountain": _draw_fountain()
			"orangery": _draw_orangery()
			"arch": _draw_arch()
			"hedge": _draw_hedge()
			"topiary": _draw_topiary()
			"roses": _draw_roses(Vector2.ZERO)
			"statue": _draw_statue()

	func _draw_pavilion() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(150, 22), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-140, -24, 280, 24), Color("e8e0cc"))
		for x in [-120, -70, 70, 120]:
			draw_rect(Rect2(x - 9, -120, 18, 98), Color("f2ecdc"))
			draw_rect(Rect2(x - 12, -124, 24, 6), Color("d8cfb8"))
		# A white dome with gold finial over the throne's canopy.
		draw_rect(Rect2(-140, -136, 280, 14), Color("d8cfb8"))
		draw_colored_polygon(PackedVector2Array([Vector2(-130, -136), Vector2(-96, -152), Vector2(-48, -162), Vector2(0, -165), Vector2(48, -162), Vector2(96, -152), Vector2(130, -136)]), Color("f2ecdc"))
		draw_line(Vector2(0, -165), Vector2(0, -182), Color("c9a24f"), 4.0)
		draw_circle(Vector2(0, -186), 5, Color("e0c06a"))
		# Rose garlands between the columns.
		for x in [-95, 95]:
			draw_arc(Vector2(x, -118), 22, 0.15, PI - 0.15, 12, Color("5f8a4a"), 3.0, true)
			for dot in range(3):
				draw_circle(Vector2(x - 14 + dot * 14, -100 + (4 if dot == 1 else 0)), 3.5, Color("c2486a"))
		draw_rect(Rect2(-40, -108, 80, 84), Color("7a2234"))
		draw_rect(Rect2(-34, -100, 68, 70), Color("9b2f45"))

	func _draw_fountain() -> void:
		DrawShapes.oval(self, Vector2(4, 4), Vector2(94, 30), Color(0.2, 0.18, 0.12, 0.2))
		DrawShapes.oval(self, Vector2(0, -12), Vector2(90, 34), Color("a69a83"))
		DrawShapes.oval(self, Vector2(0, -16), Vector2(80, 28), Color("6f9fb4"))
		DrawShapes.oval(self, Vector2(0, -18), Vector2(66, 20), Color("8ab8c9"))
		draw_rect(Rect2(-10, -62, 20, 46), Color("c9bea6"))
		DrawShapes.oval(self, Vector2(0, -62), Vector2(30, 10), Color("c9bea6"))
		for side in [-1.0, 1.0]:
			draw_arc(Vector2(side * 18, -62), 18, PI, PI * 1.5 if side < 0 else TAU, 10, Color(0.85, 0.94, 1.0, 0.8), 2.0, true)
		draw_line(Vector2(0, -64), Vector2(0, -88), Color(0.85, 0.94, 1.0, 0.8), 3.0)

	func _draw_orangery() -> void:
		DrawShapes.oval(self, Vector2(6, 4), Vector2(140, 22), Color(0.2, 0.18, 0.12, 0.22))
		draw_rect(Rect2(-130, -26, 260, 26), Color("c9bea6"))
		# Tall glass panes in white frames, orange trees inside.
		draw_rect(Rect2(-124, -130, 248, 106), Color(0.78, 0.9, 0.9, 0.85))
		for x in range(-124, 128, 31):
			draw_line(Vector2(x, -130), Vector2(x, -24), Color("f4f0e6"), 3.0)
		draw_line(Vector2(-124, -78), Vector2(124, -78), Color("f4f0e6"), 2.0)
		for x in [-80, 0, 80]:
			draw_circle(Vector2(x, -56), 16, Color("5f8a4a"))
			for dot in range(3):
				draw_circle(Vector2(x - 7 + dot * 7, -58 + (dot % 2) * 6), 3.0, Color("e8902e"))
		draw_colored_polygon(PackedVector2Array([Vector2(-132, -130), Vector2(-90, -168), Vector2(90, -168), Vector2(132, -130)]), Color(0.82, 0.92, 0.92, 0.9))
		draw_polyline(PackedVector2Array([Vector2(-132, -130), Vector2(-90, -168), Vector2(90, -168), Vector2(132, -130)]), Color("f4f0e6"), 3.0)

	func _draw_arch() -> void:
		for x in [-40, 40]:
			draw_line(Vector2(x, 0), Vector2(x, -70), Color("6b5a44"), 5.0)
		draw_arc(Vector2(0, -70), 40, PI, TAU, 18, Color("5f8a4a"), 9.0, true)
		for index in range(7):
			var at: Vector2 = Vector2(0, -70) + Vector2.from_angle(PI + index * PI / 6.0) * 40.0
			draw_circle(at, 5.0, Color("c2486a"))
		for x in [-40, 40]:
			_draw_roses(Vector2(x, -14))

	func _draw_hedge() -> void:
		var half: float = length * 0.5
		DrawShapes.oval(self, Vector2(0, 4), Vector2(half + 6, 12), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-half, -44, length, 46), Color("3f6b3a"))
		draw_rect(Rect2(-half, -46, length, 10), Color("4f7f45"))
		for x in range(int(-half) + 14, int(half), 28):
			draw_circle(Vector2(x, -26), 3.0, Color("355c31"))

	func _draw_topiary() -> void:
		DrawShapes.oval(self, Vector2(2, 2), Vector2(18, 6), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-14, -14, 28, 14), Color("a2593f"))
		draw_circle(Vector2(0, -32), 18, Color("3f6b3a"))
		draw_circle(Vector2(0, -56), 12, Color("4f7f45"))

	func _draw_roses(at: Vector2) -> void:
		DrawShapes.oval(self, at + Vector2(2, 2), Vector2(22, 7), Color(0.2, 0.18, 0.12, 0.2))
		DrawShapes.oval(self, at + Vector2(0, -10), Vector2(22, 14), Color("4f7f45"))
		for offset in [Vector2(-10, -14), Vector2(4, -18), Vector2(12, -8), Vector2(-2, -6)]:
			draw_circle(at + offset, 4.5, Color("c2486a"))
			draw_circle(at + offset, 2.0, Color("e8829a"))

	func _draw_statue() -> void:
		DrawShapes.oval(self, Vector2(2, 2), Vector2(20, 7), Color(0.2, 0.18, 0.12, 0.2))
		draw_rect(Rect2(-18, -24, 36, 24), Color("bdb3a0"))
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -24), Vector2(10, -24), Vector2(7, -72), Vector2(-7, -72)]), Color("e2dccd"))
		draw_circle(Vector2(0, -80), 9, Color("e2dccd"))
		draw_line(Vector2(7, -64), Vector2(18, -88), Color("e2dccd"), 4.0)
