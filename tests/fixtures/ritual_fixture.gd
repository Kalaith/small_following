extends RefCounted
## Validation data only. These nodes are never offered in the playable catalog.
static func build() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ring in range(1, 13):
		for branch in range(12):
			var id: String = "fixture_%d_%d" % [ring, branch]
			var requirements: Array = []
			if ring > 1:
				requirements.append("fixture_%d_%d" % [ring - 1, branch])
			result.append({
				"id": id, "title": "Fixture %d.%d" % [ring, branch],
				"description": "Scale-validation node. Not production content.",
				"branch": "test_%d" % branch, "ring": ring,
				"angle_degrees": -90.0 + branch * 30.0 + ring * 2.0,
				"cost": 6, "requires": requirements,
				"effect": {"speech_speed_add": 0.2}
			})
	return result

