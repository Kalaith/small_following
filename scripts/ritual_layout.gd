extends RefCounted
## Presentation only: authored constellations never alter catalog prerequisites.

const FIRST_RING: float = 112.0
const RING_STEP: float = 86.0
const SECTOR_ANGLES: Dictionary = {"talk": -90.0, "run": 180.0, "persuade": 0.0, "gather": 45.0, "helper": 135.0, "merchant": -135.0, "trial": -45.0, "faith": 90.0}
const BRANCH_TITLES: Dictionary = {"talk": "Words", "run": "Running", "persuade": "Creed", "gather": "Village", "helper": "Followers", "merchant": "Merchants", "trial": "Trials", "faith": "Faith"}
const FAN_HALF_ANGLE: float = 15.0
const MARKET_BRANCHES: Array[String] = ["market_run", "market_talk", "market_persuade", "market_guild", "market_patron"]
const MARKET_TITLES: Dictionary = {"market_run": "Routes", "market_talk": "Voice", "market_persuade": "Creed", "market_guild": "Guild", "market_patron": "Patrons"}
# The first three nodes retain their original petal positions. The next three
# turn down the petal's spare side, keeping six real steps inside the same seal.
const MARKET_TIER_ANGLES: Array[float] = [-13.0, 15.0, 0.0, -17.0, -24.0, -31.0]
const MARKET_TIER_RADII: Array[float] = [155.0, 265.0, 385.0, 345.0, 250.0, 195.0]

# The current village has deliberately unequal silhouettes, rather than eight
# copies of one radial formula. Stable IDs anchor art; catalog ring values still
# describe upgrade tiers. Unrecognized content uses the scalable layout below.
const VILLAGE_POSITIONS: Dictionary = {
	"talk_1": Vector2(-65, -150),
	"talk_2": Vector2(-125, -240),
	"talk_3": Vector2(-130, -350),
	"talk_4": Vector2(-50, -440),
	"talk_5": Vector2(75, -470),
	"talk_6": Vector2(195, -425),
	"run_1": Vector2(-150, 45),
	"run_2": Vector2(-245, 10),
	"run_3": Vector2(-360, 35),
	"run_4": Vector2(-450, 125),
	"run_5": Vector2(-450, 235),
	"run_6": Vector2(-360, 300),
	"beckon_1": Vector2(-255, 140),
	"persuade_1": Vector2(165, 25),
	"persuade_2": Vector2(280, 0),
	"persuade_3": Vector2(385, 60),
	"persuade_4": Vector2(460, 170),
	"persuade_5": Vector2(360, 245),
	"merchant_1": Vector2(-250, -220),
	"merchant_2": Vector2(-310, -330),
	"merchant_3": Vector2(-420, -280),
	"merchant_4": Vector2(-380, -170),
	"debate_1": Vector2(210, -180),
	"skeptic_1": Vector2(285, -265),
	"guard_1": Vector2(270, -385),
	"zealot_1": Vector2(420, -290),
	"resolve_1": Vector2(-110, 280),
	"priest_1": Vector2(100, 285),
	"sermon_1": Vector2(0, 425),
	"priest_2": Vector2(-80, 505),
	"meadow_1": Vector2(220, 350),
	"east_1": Vector2(320, 430),
	"helper_1": Vector2(-265, 385),
}

# Bellmarket's wanderer nodes sit in the gaps beside their parent petals.
const MARKET_POSITIONS: Dictionary = {
	"market_beckon_1": Vector2(205, -325),
	"market_crowd_1": Vector2(314, 102),
	"market_helper_1": Vector2(25, 365),
}

# Cross-branch requirements remain the same directed edges. These sparse bends
# keep their visible paths off unrelated upgrade icons and the central seal.
const EDGE_WAYPOINTS: Dictionary = {
	"meadow_1:run_4": [Vector2(-140, 320)],
	"talk_4:east_1": [Vector2(140, 80)],
	"meadow_1:merchant_1": [Vector2(80, 340)],
	"guard_1:resolve_1": [Vector2(-100, -40)],
	"zealot_1:resolve_1": [Vector2(180, -60)],
	"guard_1:priest_1": [Vector2(120, -100)],
	"zealot_1:priest_1": [Vector2(240, -20)],
	"debate_1:persuade_4": [Vector2(420, 20)],
	"debate_1:run_6": [Vector2(80, 80)],
}


static func edge_path(from_id: String, to_id: String, positions: Dictionary) -> PackedVector2Array:
	if not positions.has(from_id) or not positions.has(to_id):
		return PackedVector2Array()
	var points := PackedVector2Array([positions[from_id]])
	for waypoint in EDGE_WAYPOINTS.get(from_id + ":" + to_id, []):
		points.append(waypoint)
	points.append(positions[to_id])
	return points


static func satellite_seals(catalog: Array) -> Array[Dictionary]:
	var ids: Dictionary = {}
	for item in catalog:
		ids[str(item.get("id", ""))] = true
	var result: Array[Dictionary] = []
	if ids.has("merchant_1") and ids.has("merchant_4"):
		result.append({"center": Vector2(-335, -255), "radius": 112.0, "motif": "rings"})
	if ids.has("run_1") and ids.has("run_6"):
		result.append({"center": Vector2(-325, 150), "radius": 174.0, "motif": "spiral"})
	if ids.has("helper_1"):
		result.append({"center": Vector2(-265, 385), "radius": 66.0, "motif": "petals"})
	return result


static func branch_title(branch: String) -> String:
	return str(MARKET_TITLES.get(branch, BRANCH_TITLES.get(branch, branch.replace("_", " ").capitalize())))


static func build(catalog: Array) -> Dictionary:
	var branches: Array[String] = []
	var lanes: Dictionary = {}
	var first_angles: Dictionary = {}
	var tier_bounds: Dictionary = {}
	for item in catalog:
		var branch: String = str(item.get("branch", ""))
		var ring: int = maxi(1, int(item.get("ring", 1)))
		if not branches.has(branch):
			branches.append(branch)
			first_angles[branch] = float(item.get("angle_degrees", -90.0))
			tier_bounds[branch] = Vector2i(ring, ring)
		var bounds: Vector2i = tier_bounds[branch]
		tier_bounds[branch] = Vector2i(mini(bounds.x, ring), maxi(bounds.y, ring))
		var key: String = "%s:%d" % [branch, ring]
		if not lanes.has(key):
			lanes[key] = []
		lanes[key].append(item)
	var positions: Dictionary = {}
	for key in lanes:
		var row: Array = lanes[key]
		row.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("angle_degrees", 0.0)) < float(b.get("angle_degrees", 0.0)))
		for index in range(row.size()):
			var item: Dictionary = row[index]
			var branch: String = str(item.get("branch", ""))
			var angle: float = float(SECTOR_ANGLES.get(branch, first_angles[branch]))
			var ring: int = maxi(1, int(item.get("ring", 1)))
			var bounds: Vector2i = tier_bounds[branch]
			var half_width: float = _fan_half_width(branch, branches, first_angles)
			# Each branch sweeps smoothly across its sector as tiers move outward.
			# This spreads real nodes around the seal without inventing progress edges.
			var tier_fraction: float = float(ring - bounds.x) / float(bounds.y - bounds.x) if bounds.y > bounds.x else 0.5
			var sweep: float = half_width * 0.65 if row.size() > 1 else half_width
			angle += lerpf(-sweep, sweep, tier_fraction)
			# Siblings reserve lanes inside the same sector instead of overlapping a
			# neighboring branch. Single-tier branches stay centered in their sector.
			var lane_half_width: float = half_width - sweep if bounds.y > bounds.x else half_width
			if row.size() > 1:
				angle += lerpf(-lane_half_width, lane_half_width, float(index) / float(row.size() - 1))
			var radius: float = FIRST_RING + (ring - 1) * RING_STEP
			positions[str(item.get("id", ""))] = Vector2.from_angle(deg_to_rad(angle)) * radius
	for id in positions:
		if VILLAGE_POSITIONS.has(id):
			positions[id] = VILLAGE_POSITIONS[id]
		elif MARKET_POSITIONS.has(id):
			positions[id] = MARKET_POSITIONS[id]
		else:
			for branch_index in range(MARKET_BRANCHES.size()):
				for tier in range(1, MARKET_TIER_ANGLES.size() + 1):
					if id == "%s_%d" % [MARKET_BRANCHES[branch_index], tier]:
						# Five equally weighted paths sweep through a woven pentagonal seal.
						var angle: float = -90.0 + branch_index * 72.0 + MARKET_TIER_ANGLES[tier - 1]
						positions[id] = Vector2.from_angle(deg_to_rad(angle)) * MARKET_TIER_RADII[tier - 1]
	return positions


static func _fan_half_width(branch: String, branches: Array[String], first_angles: Dictionary) -> float:
	var center: float = float(SECTOR_ANGLES.get(branch, first_angles[branch]))
	var nearest: float = 180.0
	for other in branches:
		if other == branch:
			continue
		var other_center: float = float(SECTOR_ANGLES.get(other, first_angles[other]))
		nearest = minf(nearest, absf(wrapf(other_center - center, -180.0, 180.0)))
	# Unknown fixture branches keep their original sector; narrower sectors get
	# a proportionately smaller fan, leaving a gap for adjacent node silhouettes.
	return minf(FAN_HALF_ANGLE, nearest / 3.0)
