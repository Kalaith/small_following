extends RefCounted
## Shared placeholder-art primitives, usable from any CanvasItem's _draw().

static func oval(canvas: CanvasItem, center: Vector2, radii: Vector2, tint: Color) -> void:
	canvas.draw_set_transform(center, 0.0, radii)
	canvas.draw_circle(Vector2.ZERO, 1.0, tint)
	canvas.draw_set_transform(Vector2.ZERO)
