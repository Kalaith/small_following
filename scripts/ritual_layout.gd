extends RefCounted
## Presentation only: branch sectors and outward tiers never alter catalog prerequisites.

const FIRST_RING: float = 112.0
const RING_STEP: float = 86.0
const SECTOR_ANGLES: Dictionary = {"talk": -90.0, "run": 180.0, "persuade": 0.0, "gather": 45.0, "helper": 135.0, "merchant": -135.0, "trial": -45.0, "faith": 90.0}
const BRANCH_TITLES: Dictionary = {"talk": "Words", "run": "Running", "persuade": "Creed", "gather": "Village", "helper": "Followers", "merchant": "Merchants", "trial": "Trials", "faith": "Faith"}
const FAN_HALF_ANGLE: float = 15.0


static func branch_title(branch: String) -> String:
	return str(BRANCH_TITLES.get(branch, branch.replace("_", " ").capitalize()))


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
