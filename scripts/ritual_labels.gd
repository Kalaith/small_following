extends RefCounted
## Places node labels without overlap, selection and hover first, then draws them.

const Style = preload("res://scripts/ritual_style.gd")

var font: Font = ThemeDB.fallback_font
## Label rectangles in screen coordinates, by node ID.
var rects: Dictionary = {}
var model: Array[Dictionary] = []

var screen: Control


func _init(owner_screen: Control) -> void:
	screen = owner_screen


func _point(world: Vector2) -> Vector2:
	return screen.graph_point(world)


func _compact_title(item: Dictionary) -> String:
	return str(item.get("title", item.get("id", ""))).replace("Quickened Words", "Words").replace("Compelling Creed", "Creed").replace("Fleet Footsteps", "Run").replace(" Invitations", "")


func prepare() -> void:
	rects.clear()
	model.clear()
	if not is_instance_valid(screen.graph) or not is_instance_valid(font):
		return
	var candidates: Array = screen.catalog.duplicate()
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _label_priority(a) > _label_priority(b))
	var visible_bounds := Rect2(Vector2(4, 4), screen.graph.size - Vector2(8, 8))
	var radius: float = screen.node_radius()
	for item in candidates:
		var id: String = str(item.get("id", ""))
		var selected: bool = id == screen.selected_id or id == screen.hovered_id
		var major: bool = str(item.get("branch", "")) in ["gather", "helper"]
		# At distant scale reveal major unlocks and focus; every other node remains
		# visible/pickable and listed by branch in the stationary browser.
		if screen.zoom < 0.45 and not selected and not major:
			continue
		var point: Vector2 = _point(screen.node_positions[id])
		if not visible_bounds.has_point(point):
			continue
		var text: String = str(item.get("title", id)) if screen.zoom >= 1.15 else _compact_title(item)
		var font_size: int = 14 if screen.zoom >= 1.15 else 12
		var rank_text: String = "RANK %d/%d" % [screen.rank_of(id), screen.max_rank_of(id)] if screen.zoom >= 0.8 else ""
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8.0
		if not rank_text.is_empty():
			width = maxf(width, font.get_string_size(rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 8.0)
		var height: float = font_size + 6.0 + (15.0 if not rank_text.is_empty() else 0.0)
		var offsets: Array[Vector2] = [Vector2(radius + 10, -height * 0.5), Vector2(-width * 0.5, -radius - height - 8), Vector2(-width * 0.5, radius + 8), Vector2(-radius - width - 10, -height * 0.5)]
		if str(item.get("branch", "")) in ["run", "persuade"]:
			offsets = [offsets[1], offsets[2], offsets[0], offsets[3]]
		for offset in offsets:
			var bounds := Rect2(point + offset, Vector2(width, height))
			if not visible_bounds.encloses(bounds) or _label_collides(bounds, id, radius):
				continue
			var color: Color = Style.WHITE if selected else Style.LILAC if screen.rank_of(id) > 0 or screen.state_of(id) == "affordable" else Style.MUTED
			model.append({"id": id, "rect": bounds, "text": text, "rank_text": rank_text, "font_size": font_size, "color": color})
			rects[id] = Rect2(bounds.position + screen.graph.global_position, bounds.size)
			break


func _label_priority(item: Dictionary) -> int:
	var id: String = str(item.get("id", ""))
	if id == screen.hovered_id:
		return 1000
	if id == screen.selected_id:
		return 900
	if str(item.get("branch", "")) in ["gather", "helper"]:
		return 500 - int(item.get("ring", 1))
	return 100 - int(item.get("ring", 1))


func _label_collides(bounds: Rect2, own_id: String, radius: float) -> bool:
	var core_radius: float = Style.CORE_ORNAMENT_RADIUS * screen.zoom + 4.0
	if bounds.intersects(Rect2(_point(Vector2.ZERO) - Vector2.ONE * core_radius, Vector2.ONE * core_radius * 2.0)):
		return true
	for label in model:
		if bounds.grow(3.0).intersects(label.rect):
			return true
	for id in screen.node_positions:
		if str(id) == own_id:
			continue
		var at: Vector2 = _point(screen.node_positions[id])
		if bounds.grow(3.0).intersects(Rect2(at - Vector2.ONE * (radius + 3.0), Vector2.ONE * (radius + 3.0) * 2.0)):
			return true
	return false


func draw(canvas: Control) -> void:
	prepare()
	for label in model:
		var bounds: Rect2 = label.rect
		canvas.draw_rect(bounds, Color(Style.INK, 0.96))
		canvas.draw_string(font, bounds.position + Vector2(4, label.font_size + 1), label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size, label.color)
		if not str(label.rank_text).is_empty():
			canvas.draw_string(font, bounds.position + Vector2(4, label.font_size + 16), label.rank_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Style.MUTED)
