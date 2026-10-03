extends Label
## One numeric payout, sized to its digits and removed after the animation.
const DURATION: float = 0.9
const RISE: float = 12.0

var amount: int = 0


func _ready() -> void:
	text = str(amount)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color("#fff1b6"))
	add_theme_color_override("font_outline_color", Color("#493545"))
	add_theme_constant_override("outline_size", 5)
	z_index = 10
	position.x -= get_minimum_size().x * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	tween.chain().tween_callback(queue_free)
