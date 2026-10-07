extends Node2D
## Editable, hand-drawn placeholder village. No mockup image is used in the scene.
## Main calls build_props(actors) so props and characters share one Y-sort parent.

const DrawShapes = preload("res://scripts/draw_shapes.gd")
const WORLD_SIZE: Vector2 = Vector2(1560.0, 1100.0)
const GRASS: Color = Color("a7b976")
const GRASS_LIGHT: Color = Color("b6c58a")
const PATH_EDGE: Color = Color("b8ab78")
const PATH: Color = Color("d4c293")
const PATH_LIGHT: Color = Color("dccb9e")

# Positions are ground anchors; house geometry extends upward from each anchor.
# Keep these footprints clear of spawn (780, 680) and the three NPC gatherings.
const PROP_LAYOUT = [
	{"kind": "house", "at": Vector2(245, 330), "variant": 0},
	{"kind": "house", "at": Vector2(1245, 285), "variant": 1},
	{"kind": "house", "at": Vector2(1360, 920), "variant": 2},
	{"kind": "house", "at": Vector2(260, 955), "variant": 1},
	{"kind": "well", "at": Vector2(780, 400)},
	{"kind": "market", "at": Vector2(1135, 725)},
	{"kind": "bench", "at": Vector2(400, 700)},
	{"kind": "bench", "at": Vector2(1090, 955)},
	{"kind": "tree", "at": Vector2(83, 200), "variant": 0},
	{"kind": "tree", "at": Vector2(475, 212), "variant": 1},
	{"kind": "tree", "at": Vector2(925, 155), "variant": 0},
	{"kind": "tree", "at": Vector2(1480, 495), "variant": 1},
	{"kind": "tree", "at": Vector2(130, 685), "variant": 0},
	{"kind": "tree", "at": Vector2(535, 1040), "variant": 1},
	{"kind": "tree", "at": Vector2(1460, 1040), "variant": 0},
	{"kind": "flowers", "at": Vector2(350, 350), "variant": 0},
	{"kind": "flowers", "at": Vector2(1120, 305), "variant": 1},
	{"kind": "flowers", "at": Vector2(380, 965), "variant": 0},
	{"kind": "flowers", "at": Vector2(1240, 925), "variant": 1},
]

var _props_built: bool = false


func build_props(actor_root: Node2D) -> void:
	if _props_built:
		return
	_props_built = true
	for entry in PROP_LAYOUT:
		var data: Dictionary = entry
		var prop: VillageProp = VillageProp.new()
		prop.kind = String(data["kind"])
		prop.variant = int(data.get("variant", 0))
		prop.position = Vector2(data["at"])
		prop.name = "%s_%d" % [prop.kind.capitalize(), actor_root.get_child_count()]
		actor_root.add_child(prop)
		prop.add_footprint()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), GRASS)
	# Broad rounded patches break up the grass without obscuring walkable space.
	_oval(Vector2(265, 205), Vector2(385, 285), GRASS_LIGHT)
	_oval(Vector2(1350, 870), Vector2(370, 320), Color("a1b470"))
	_oval(Vector2(715, 1110), Vector2(620, 205), Color("adbd7d"))
	_draw_paths()
	_draw_ground_texture()
	_draw_fence(Vector2(35, 75), 15, 103.0)
	_draw_fence(Vector2(50, 1070), 5, 100.0)
	_draw_fence(Vector2(1110, 1070), 5, 100.0)


func _draw_paths() -> void:
	var branches: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(780, 35), Vector2(770, 295), Vector2(790, 595)]),
		PackedVector2Array([Vector2(790, 595), Vector2(805, 850), Vector2(780, 1100)]),
		PackedVector2Array([Vector2(245, 355), Vector2(380, 395), Vector2(575, 570)]),
		PackedVector2Array([Vector2(1210, 310), Vector2(1130, 365), Vector2(1020, 500)]),
		PackedVector2Array([Vector2(285, 960), Vector2(405, 875), Vector2(580, 720)]),
		PackedVector2Array([Vector2(1340, 955), Vector2(1165, 900), Vector2(980, 745)]),
		PackedVector2Array([Vector2(1540, 630), Vector2(1205, 630), Vector2(1005, 630)]),
	]
	for branch in branches:
		draw_polyline(branch, PATH_EDGE, 102.0, true)
		draw_polyline(branch, PATH, 90.0, true)
		for point in branch:
			draw_circle(point, 45.0, PATH)
	_oval(Vector2(790, 625), Vector2(349, 230), PATH_EDGE)
	_oval(Vector2(790, 622), Vector2(342, 225), PATH)
	_oval(Vector2(790, 612), Vector2(313, 199), PATH_LIGHT)
	# A small, irregular ring of flat stones belongs to the well's ground plane.
	for i in range(15):
		var angle: float = float(i) * TAU / 15.0
		var at: Vector2 = Vector2(780, 400) + Vector2(cos(angle) * 73.0, sin(angle) * 42.0)
		_oval(at, Vector2(11.0, 6.0), Color("a8a48a"))
		_oval(at + Vector2(0, -1), Vector2(9.0, 4.0), Color("c6bfa2"))


func _draw_ground_texture() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 71422
	for i in range(550):
		var at: Vector2 = Vector2(rng.randf_range(40.0, 1520.0), rng.randf_range(100.0, 1040.0))
		if _is_path(at):
			if i % 4 == 0:
				_oval(at, Vector2(rng.randf_range(2.0, 5.0), 1.6), Color("bbad84"))
			continue
		var tint: Color = Color("8fA565") if i % 3 != 0 else Color("c3ce95")
		draw_line(at, at + Vector2(-3, -5), tint, 1.6, true)
		draw_line(at + Vector2(3, 0), at + Vector2(4, -7), tint, 1.6, true)
		if i % 13 == 0:
			draw_circle(at + Vector2(-3, -6), 2.6, Color("f5dc91"))
			draw_circle(at + Vector2(4, -8), 2.2, Color("f3e9bf"))
	# Doorstep stones reinforce entrances; these are floor marks, not obstacles.
	for at in [Vector2(245, 347), Vector2(1245, 302), Vector2(1360, 936), Vector2(260, 971)]:
		for row in range(3):
			_oval(at + Vector2(0, float(row) * 16.0), Vector2(16.0 - row * 2.0, 6.0), Color("b6b294"))


func _is_path(at: Vector2) -> bool:
	var plaza: Vector2 = (at - Vector2(790, 622)) / Vector2(352, 240)
	if plaza.length_squared() < 1.0:
		return true
	if absf(at.x - 790.0) < 60.0 or (at.x > 1000.0 and absf(at.y - 630.0) < 60.0):
		return true
	var links: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(245, 355), Vector2(575, 570)]),
		PackedVector2Array([Vector2(1210, 310), Vector2(1020, 500)]),
		PackedVector2Array([Vector2(285, 960), Vector2(580, 720)]),
		PackedVector2Array([Vector2(1340, 955), Vector2(980, 745)]),
	]
	for link in links:
		if at.distance_to(Geometry2D.get_closest_point_to_segment(at, link[0], link[1])) < 65.0:
			return true
	return false


func _draw_fence(origin: Vector2, count: int, spacing: float) -> void:
	var end: Vector2 = origin + Vector2(float(count - 1) * spacing, 0)
	draw_line(origin + Vector2(0, -6), end + Vector2(0, -6), Color("9b926d"), 5.0)
	draw_line(origin + Vector2(0, -19), end + Vector2(0, -19), Color("c3b58b"), 5.0)
	for i in range(count):
		var at: Vector2 = origin + Vector2(float(i) * spacing, 0)
		draw_line(at, at + Vector2(0, -29), Color("8d8161"), 8.0)
		draw_line(at + Vector2(-2, -1), at + Vector2(-2, -29), Color("d0bd91"), 3.0)


func _oval(center: Vector2, radii: Vector2, tint: Color) -> void:
	DrawShapes.oval(self, center, radii, tint)


class VillageProp:
	extends Node2D

	const INK: Color = Color("605548")
	const SHADOW: Color = Color(0.29, 0.34, 0.19, 0.17)
	var kind: String = "tree"
	var variant: int = 0


	func add_footprint() -> void:
		if kind == "flowers":
			return
		var body: StaticBody2D = StaticBody2D.new()
		body.name = "Footprint"
		body.collision_layer = 2
		body.collision_mask = 1
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.name = "Shape"
		collision.add_to_group("helper_obstacle_shape")
		if kind == "tree" or kind == "well":
			var circle: CircleShape2D = CircleShape2D.new()
			circle.radius = 17.0 if kind == "tree" else 43.0
			collision.shape = circle
			collision.position = Vector2(0, -9)
		else:
			var box: RectangleShape2D = RectangleShape2D.new()
			match kind:
				"house":
					box.size = Vector2(182, 70)
					collision.position = Vector2(0, -34)
				"market":
					box.size = Vector2(132, 42)
					collision.position = Vector2(0, -18)
				"bench":
					box.size = Vector2(85, 20)
					collision.position = Vector2(0, -8)
			collision.shape = box
		body.add_child(collision)
		add_child(body)


	func _draw() -> void:
		match kind:
			"house": _draw_house()
			"tree": _draw_tree()
			"well": _draw_well()
			"market": _draw_market()
			"bench": _draw_bench()
			"flowers": _draw_flowers()


	func _draw_house() -> void:
		var roof: Color = Color("ae7057")
		var roof_light: Color = Color("c88a67")
		if variant == 1:
			roof = Color("768d7a")
			roof_light = Color("94a28a")
		elif variant == 2:
			roof = Color("b28c56")
			roof_light = Color("cca771")
		_oval(Vector2(12, 8), Vector2(118, 24), SHADOW)
		draw_rect(Rect2(-90, -101, 180, 102), INK)
		draw_rect(Rect2(-85, -99, 170, 96), Color("ebd9ad"))
		draw_rect(Rect2(62, -95, 23, 93), Color("d0bb92"))
		draw_rect(Rect2(-85, -15, 170, 13), Color("bab395"))
		# Chimney, roof slab, and subtle broad tiles use a shared warm outline.
		draw_rect(Rect2(49, -162, 22, 45), INK)
		draw_rect(Rect2(53, -160, 14, 44), Color("bbae92"))
		draw_rect(Rect2(45, -167, 30, 9), Color("8d846e"))
		var roof_outline: PackedVector2Array = PackedVector2Array([Vector2(-112, -98), Vector2(-23, -173), Vector2(33, -173), Vector2(113, -98), Vector2(108, -86), Vector2(-107, -86)])
		draw_polygon(roof_outline, PackedColorArray([INK]))
		draw_polygon(PackedVector2Array([Vector2(-103, -98), Vector2(-21, -168), Vector2(32, -168), Vector2(104, -98)]), PackedColorArray([roof]))
		draw_polygon(PackedVector2Array([Vector2(-103, -98), Vector2(-21, -168), Vector2(3, -168), Vector2(-65, -98)]), PackedColorArray([roof_light]))
		for row in range(3):
			var roof_y: float = -112.0 - float(row) * 17.0
			var roof_half: float = 87.0 - float(row) * 20.0
			draw_line(Vector2(-roof_half, roof_y), Vector2(roof_half, roof_y), Color(0.32, 0.27, 0.22, 0.16), 2.0, true)
		draw_line(Vector2(-105, -92), Vector2(107, -92), roof_light, 4.0, true)
		# An arched door and round brass latch give even placeholder homes a face.
		draw_rect(Rect2(-21, -54, 42, 52), INK)
		draw_circle(Vector2(0, -54), 21, INK)
		draw_rect(Rect2(-17, -53, 34, 50), Color("9e8057"))
		draw_circle(Vector2(0, -53), 17, Color("9e8057"))
		for x in [-10, 0, 10]:
			draw_line(Vector2(x, -64), Vector2(x, -5), Color("876d4e"), 1.5)
		draw_circle(Vector2(10, -29), 3, Color("e5c784"))
		_draw_window(Vector2(-57, -58))
		_draw_window(Vector2(55, -58))
		draw_rect(Rect2(-95, -5, 190, 7), Color("8e8971"))


	func _draw_window(at: Vector2) -> void:
		draw_rect(Rect2(at - Vector2(18, 20), Vector2(36, 39)), Color("95794f"))
		draw_rect(Rect2(at - Vector2(13, 15), Vector2(26, 27)), Color("697b76"))
		draw_rect(Rect2(at - Vector2(11, 13), Vector2(9, 23)), Color("91a49a"))
		draw_line(at + Vector2(0, -15), at + Vector2(0, 13), Color("d7be86"), 3.0)
		draw_line(at + Vector2(-13, -1), at + Vector2(13, -1), Color("d7be86"), 3.0)
		draw_line(at + Vector2(-21, 20), at + Vector2(21, 20), Color("b0996e"), 5.0)


	func _draw_tree() -> void:
		var dark: Color = Color("66815a") if variant == 0 else Color("7d905d")
		var light: Color = Color("8fa66e") if variant == 0 else Color("a4b77b")
		_oval(Vector2(8, 5), Vector2(62, 19), SHADOW)
		draw_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(-8, -83), Vector2(11, -83), Vector2(16, 0)]), PackedColorArray([Color("897352")]))
		draw_line(Vector2(-4, -5), Vector2(-1, -76), Color("b49a68"), 5.0, true)
		draw_line(Vector2(2, -40), Vector2(32, -77), Color("897352"), 9.0, true)
		draw_line(Vector2(0, -52), Vector2(-25, -80), Color("897352"), 8.0, true)
		_oval(Vector2(0, -89), Vector2(66, 55), dark)
		draw_circle(Vector2(-32, -103), 34, dark)
		draw_circle(Vector2(31, -107), 35, dark)
		draw_circle(Vector2(0, -127), 39, dark)
		draw_circle(Vector2(-19, -124), 33, light)
		draw_circle(Vector2(15, -128), 27, light)
		draw_circle(Vector2(-37, -104), 25, light)
		draw_circle(Vector2(16, -91), 31, light)
		for leaf in [Vector2(-35, -119), Vector2(-13, -143), Vector2(19, -132), Vector2(31, -96), Vector2(-2, -102)]:
			draw_arc(leaf, 8.0, 3.6, 5.4, 8, Color(0.86, 0.89, 0.60, 0.35), 3.0, true)


	func _draw_well() -> void:
		_oval(Vector2(7, 6), Vector2(63, 23), SHADOW)
		# Stone barrel with a dark, visibly open top.
		draw_rect(Rect2(-46, -35, 92, 31), Color("999e91"))
		_oval(Vector2(0, -5), Vector2(46, 20), Color("929a8b"))
		_oval(Vector2(0, -33), Vector2(49, 26), Color("d1ceb6"))
		_oval(Vector2(0, -33), Vector2(35, 16), Color("687e76"))
		_oval(Vector2(0, -29), Vector2(28, 10), Color("809b94"))
		draw_arc(Vector2(-6, -27), 13.0, 0.1, 2.2, 14, Color("bad0bf"), 2.0, true)
		draw_line(Vector2(-40, -16), Vector2(40, -16), Color("7d897d"), 2.0, true)
		for x in [-28, -1, 27]:
			draw_line(Vector2(x, -13), Vector2(x + 2, 8), Color("7c887c"), 2.0, true)
		for x in [-52, 52]:
			draw_line(Vector2(x, -12), Vector2(x, -110), INK, 8.0, true)
			draw_line(Vector2(x - 1, -18), Vector2(x - 1, -108), Color("b2986c"), 4.0, true)
		draw_line(Vector2(-52, -81), Vector2(52, -81), Color("887152"), 7.0, true)
		draw_line(Vector2(0, -81), Vector2(0, -35), Color("d2bd8b"), 2.0, true)
		draw_polygon(PackedVector2Array([Vector2(-68, -101), Vector2(0, -144), Vector2(68, -101), Vector2(65, -93), Vector2(-65, -93)]), PackedColorArray([INK]))
		draw_polygon(PackedVector2Array([Vector2(-60, -101), Vector2(0, -137), Vector2(60, -101)]), PackedColorArray([Color("bf8261")]))
		draw_line(Vector2(-58, -99), Vector2(58, -99), Color("d39a73"), 4.0, true)


	func _draw_market() -> void:
		_oval(Vector2(10, 7), Vector2(90, 20), SHADOW)
		for x in [-67, 67]:
			draw_line(Vector2(x, 0), Vector2(x, -116), INK, 7.0, true)
			draw_line(Vector2(x - 1, -2), Vector2(x - 1, -110), Color("bda273"), 3.0, true)
		draw_rect(Rect2(-71, -35, 142, 36), Color("977953"))
		draw_rect(Rect2(-69, -30, 138, 23), Color("b69a6a"))
		for x in [-48, -24, 0, 24, 48]:
			draw_line(Vector2(x, -29), Vector2(x, -6), Color("977953"), 2.0)
		draw_rect(Rect2(-76, -44, 152, 12), Color("6e654e"))
		draw_rect(Rect2(-74, -44, 148, 7), Color("d1b17a"))
		for i in range(6):
			var x: float = -78.0 + float(i) * 26.0
			var tint: Color = Color("e7d8ab") if i % 2 == 0 else Color("b88466")
			draw_polygon(PackedVector2Array([Vector2(x + 10, -120), Vector2(x + 32, -120), Vector2(x + 26, -76), Vector2(x, -76)]), PackedColorArray([tint]))
			draw_rect(Rect2(x, -76, 26, 10), tint)
			_oval(Vector2(x + 13, -66), Vector2(13, 6), tint)
		draw_line(Vector2(-68, -121), Vector2(64, -121), INK, 3.0, true)
		for i in range(8):
			var at: Vector2 = Vector2(-50.0 + float(i % 4) * 12.0, -47.0 - floorf(float(i) / 4.0) * 10.0)
			draw_circle(at, 6.0, Color("c19055"))
			draw_line(at + Vector2(0, -5), at + Vector2(2, -8), Color("718455"), 2.0)
		for i in range(3):
			_oval(Vector2(29.0 + float(i) * 12.0, -49), Vector2(7, 11), Color("d5b880"))


	func _draw_bench() -> void:
		_oval(Vector2(4, 6), Vector2(53, 13), SHADOW)
		for x in [-32, 32]:
			draw_line(Vector2(x, 1), Vector2(x, -35), Color("78674c"), 6.0, true)
		draw_rect(Rect2(-46, -39, 92, 10), Color("b7a276"))
		draw_line(Vector2(-44, -37), Vector2(43, -37), Color("d5bd87"), 2.0)
		draw_rect(Rect2(-48, -18, 96, 12), Color("a58c60"))
		draw_line(Vector2(-47, -17), Vector2(47, -17), Color("d2b785"), 3.0)


	func _draw_flowers() -> void:
		_oval(Vector2.ZERO, Vector2(38, 13), Color("8d9c65"))
		for i in range(9):
			var at: Vector2 = Vector2(-30.0 + float(i) * 7.5, -4.0 - float(i % 3) * 5.0)
			draw_line(at + Vector2(0, 6), at + Vector2(0, -7), Color("748857"), 2.0)
			var tint: Color = Color("ebcb87") if variant == 0 else Color("e6bdac")
			draw_circle(at + Vector2(-3, -8), 3.5, tint)
			draw_circle(at + Vector2(3, -8), 3.5, tint)
			draw_circle(at + Vector2(0, -12), 3.5, tint)
			draw_circle(at + Vector2(0, -8), 2.0, Color("f2e7b6"))


	func _oval(center: Vector2, radii: Vector2, tint: Color) -> void:
		DrawShapes.oval(self, center, radii, tint)
