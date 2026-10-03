extends RefCounted
## Presentation only: branch sectors and outward tiers never alter catalog prerequisites.

const FIRST_RING: float = 112.0
const RING_STEP: float = 86.0
const SECTOR_ANGLES: Dictionary = {"talk": -90.0, "run": 180.0, "persuade": 0.0, "gather": 65.0, "helper": 120.0}
const BRANCH_TITLES: Dictionary = {"talk": "Words", "run": "Running", "persuade": "Creed", "gather": "Village", "helper": "Followers"}


static func branch_title(branch: String) -> String:
	return str(BRANCH_TITLES.get(branch, branch.replace("_", " ").capitalize()))


static func build(catalog: Array) -> Dictionary:
	var branches: Array[String] = []
	var lanes: Dictionary = {}
	var first_angles: Dictionary = {}
	for item in catalog:
		var branch: String = str(item.get("branch", ""))
		if not branches.has(branch):
			branches.append(branch)
			first_angles[branch] = float(item.get("angle_degrees", -90.0))
		var key: String = "%s:%d" % [branch, int(item.get("ring", 1))]
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
			# Sibling lanes stay within their sector. Independent fixture branches retain
			# their initial angle, without the old twist applied on every successive ring.
			var lane_step: float = minf(18.0, 44.0 / maxf(1.0, row.size() - 1.0))
			angle += (index - (row.size() - 1) * 0.5) * lane_step
			var radius: float = FIRST_RING + (maxi(1, int(item.get("ring", 1))) - 1) * RING_STEP
			positions[str(item.get("id", ""))] = Vector2.from_angle(deg_to_rad(angle)) * radius
	return positions
