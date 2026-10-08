extends Node2D
## Bellmarket is authored from actual ground, Y-sorted props and mixed listeners.
## Artwork is original procedural geometry, reusing the village's prop language.

const Village = preload("res://scripts/village.gd")
const WORLD_SIZE := Vector2(1560, 1100)
const START_POSITION := Vector2(780, 680)
const ORDINARY_CONVICTION: float = 24.0
const ORDINARY_DONATION: int = 10
const GUILD_CONVICTION: float = 48.0
const GUILD_DONATION: int = 30
const PATRON_CONVICTION: float = 60.0
const PATRON_DONATION: int = 50

const BAKER = {"role": "Baker", "npc_type": "ordinary", "conviction_required": ORDINARY_CONVICTION, "donation": ORDINARY_DONATION, "requires": ""}
const PORTER = {"role": "Porter", "npc_type": "ordinary", "conviction_required": ORDINARY_CONVICTION, "donation": ORDINARY_DONATION, "requires": ""}
const SHOPPER = {"role": "Shopper", "npc_type": "ordinary", "conviction_required": ORDINARY_CONVICTION, "donation": ORDINARY_DONATION, "requires": ""}
const COOK = {"role": "Cook", "npc_type": "ordinary", "conviction_required": ORDINARY_CONVICTION, "donation": ORDINARY_DONATION, "requires": ""}
const COURIER = {"role": "Courier", "npc_type": "ordinary", "conviction_required": ORDINARY_CONVICTION, "donation": ORDINARY_DONATION, "requires": ""}
const ARTISAN = {"role": "Artisan", "npc_type": "guild", "conviction_required": GUILD_CONVICTION, "donation": GUILD_DONATION, "requires": "market_guild_unlock"}
const GUILDER = {"role": "Guildmaster", "npc_type": "guild", "conviction_required": GUILD_CONVICTION, "donation": GUILD_DONATION, "requires": "market_guild_unlock"}
const PATRON = {"role": "Patron", "npc_type": "patron", "conviction_required": PATRON_CONVICTION, "donation": PATRON_DONATION, "requires": "market_patron_unlock"}
const COLLECTOR = {"role": "Collector", "npc_type": "patron", "conviction_required": PATRON_CONVICTION, "donation": PATRON_DONATION, "requires": "market_patron_unlock"}

# The slot order deliberately intersperses introductions; a lock never blocks
# the ordinary person behind it. Independent gates affect several districts.
const GROUP_LAYOUT = [
	{"title": "Bread Court", "position": Vector2(565, 690), "profiles": [BAKER, PORTER, SHOPPER, COOK, COURIER]},
	{"title": "Cart Crossing", "position": Vector2(795, 470), "profiles": [PORTER, ARTISAN, SHOPPER, COURIER, BAKER]},
	{"title": "Guild Row", "position": Vector2(480, 440), "profiles": [ARTISAN, COURIER, GUILDER, PORTER, COOK]},
	{"title": "Silk Arcade", "position": Vector2(1045, 650), "profiles": [SHOPPER, PATRON, ARTISAN, PORTER, COURIER]},
	{"title": "Patron Steps", "position": Vector2(1080, 370), "profiles": [PATRON, BAKER, COLLECTOR, SHOPPER, COOK]},
]

# Every position is a feet origin. The square's center and district approaches
# stay open; the reused props add real layer-2 collision at their bases.
const PROP_LAYOUT = [
	{"kind": "house", "at": Vector2(260, 340), "variant": 1},
	{"kind": "house", "at": Vector2(705, 260), "variant": 2},
	{"kind": "house", "at": Vector2(1270, 260), "variant": 2},
	{"kind": "house", "at": Vector2(1290, 930), "variant": 0},
	{"kind": "house", "at": Vector2(270, 960), "variant": 0},
	{"kind": "market", "at": Vector2(340, 630)},
	{"kind": "market", "at": Vector2(535, 875)},
	{"kind": "market", "at": Vector2(1265, 595)},
	{"kind": "market", "at": Vector2(925, 285)},
	{"kind": "bench", "at": Vector2(1150, 865)},
	{"kind": "tree", "at": Vector2(125, 580), "variant": 1},
	{"kind": "tree", "at": Vector2(1400, 480), "variant": 1},
	{"kind": "tree", "at": Vector2(360, 160), "variant": 0},
	{"kind": "tree", "at": Vector2(1040, 1010), "variant": 0},
	{"kind": "flowers", "at": Vector2(1260, 330), "variant": 1},
	{"kind": "flowers", "at": Vector2(1380, 890), "variant": 0},
]

var _props_built: bool = false


func build_props(actors: Node2D) -> void:
	if _props_built:
		return
	_props_built = true
	for entry in PROP_LAYOUT:
		var prop = Village.VillageProp.new()
		prop.kind = String(entry["kind"])
		prop.variant = int(entry.get("variant", 0))
		prop.position = entry["at"]
		prop.name = "Market_%s_%d" % [prop.kind.capitalize(), actors.get_child_count()]
		actors.add_child(prop)
		prop.add_footprint()
	var bell := MarketBell.new()
	bell.position = Vector2(780, 825)
	actors.add_child(bell)
	bell.add_footprint()
	for entry in [{"at": Vector2(360, 390), "text": "GUILD ROW", "tint": Color("577e85")}, {"at": Vector2(1220, 440), "text": "PATRON STEPS", "tint": Color("8b6b95")}, {"at": Vector2(380, 790), "text": "BREAD COURT", "tint": Color("aa784d")}]:
		var signpost := DistrictSign.new()
		signpost.position = entry["at"]
		signpost.caption = entry["text"]
		signpost.tint = entry["tint"]
		actors.add_child(signpost)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("a4ae8d"))
	# A warm cobbled square, edged promenades and broad streets distinguish
	# Bellmarket from Bramblewick's rounded meadow clearing.
	draw_rect(Rect2(340, 300, 900, 570), Color("b2a58c"))
	draw_rect(Rect2(360, 316, 860, 538), Color("c6b89e"))
	draw_rect(Rect2(382, 334, 816, 502), Color("d1c4ab"))
	for lane in [Rect2(704, 0, 152, 340), Rect2(696, 820, 168, 280), Rect2(0, 508, 385, 120), Rect2(1200, 500, 360, 120)]:
		draw_rect(lane.grow(7), Color("b2a58c"))
		draw_rect(lane, Color("ccbea4"))
	for row in range(18):
		for column in range(24):
			var at := Vector2(394 + column * 34 + (row % 2) * 16, 346 + row * 27)
			var tint := Color("bfb59f") if (row + column) % 3 else Color("dbd0b8")
			draw_style_box(_paver_style(tint), Rect2(at, Vector2(29, 21)))
	# A floor compass indicates the three useful directions from the entrance.
	for radius in [49.0, 60.0]:
		draw_arc(Vector2(780, 680), radius, 0, TAU, 64, Color("b3a189"), 2, true)
	for direction in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT]:
		var tip: Vector2 = Vector2(780, 680) + direction * 60.0
		var side: Vector2 = direction.orthogonal() * 9.0
		draw_colored_polygon(PackedVector2Array([tip, tip - direction * 22 + side, tip - direction * 22 - side]), Color("aa9276"))
	# Raised paving is decorative floor only; the player retains free movement.
	for step in range(4):
		draw_rect(Rect2(986, 318 + step * 8, 174, 6), Color("b3a690"))
	_draw_bunting(Vector2(385, 238), Vector2(1115, 216))
	_draw_bunting(Vector2(925, 900), Vector2(1310, 818))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(673, 1020), "BELLMARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("716951"))


func _paver_style(tint: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(4)
	return style


func _draw_bunting(start: Vector2, end: Vector2) -> void:
	draw_line(start, end, Color("83765f"), 2, true)
	for index in range(15):
		var at: Vector2 = start.lerp(end, float(index + 1) / 16.0)
		var tint := Color("a9809c") if index % 2 == 0 else Color("d4ad71")
		draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 0), at + Vector2(8, 0), at + Vector2(0, 17)]), tint)


class DistrictSign extends Node2D:
	var caption: String = ""
	var tint := Color("577e85")

	func _draw() -> void:
		draw_line(Vector2.ZERO, Vector2(0, -63), Color("7c674e"), 6, true)
		var font := ThemeDB.fallback_font
		var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 18
		draw_rect(Rect2(-width * 0.5, -68, width, 22), tint)
		draw_string(font, Vector2(-width * 0.5 + 9, -52), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff0cc"))


class MarketBell extends Node2D:
	func add_footprint() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		var collision := CollisionShape2D.new()
		collision.name = "Shape"
		collision.add_to_group("helper_obstacle_shape")
		var shape := RectangleShape2D.new()
		shape.size = Vector2(72, 25)
		collision.shape = shape
		collision.position = Vector2(0, -8)
		body.add_child(collision)
		add_child(body)

	func _draw() -> void:
		draw_set_transform(Vector2(4, 3), 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 52, Color(0.25, 0.22, 0.18, 0.18))
		draw_set_transform(Vector2.ZERO)
		for x in [-30, 30]:
			draw_line(Vector2(x, 0), Vector2(x, -116), Color("806a50"), 9, true)
			draw_line(Vector2(x - 2, 0), Vector2(x - 2, -116), Color("b29a71"), 3, true)
		draw_line(Vector2(-39, -110), Vector2(39, -110), Color("806a50"), 10, true)
		draw_line(Vector2.ZERO + Vector2(0, -110), Vector2(0, -94), Color("756443"), 4)
		draw_colored_polygon(PackedVector2Array([Vector2(-13, -91), Vector2(13, -91), Vector2(19, -65), Vector2(-19, -65)]), Color("cba458"))
		draw_arc(Vector2(0, -87), 13, PI, TAU, 18, Color("e5c781"), 5, true)
		draw_rect(Rect2(-24, -66, 48, 7), Color("e5c781"))
		draw_circle(Vector2(0, -58), 5, Color("8e7143"))
		draw_line(Vector2(20, -65), Vector2(21, -26), Color("ead5a7"), 2, true)
