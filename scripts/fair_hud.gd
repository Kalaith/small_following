extends Control
## The cultist's Interest at the fair, drawn as lantern pips like every
## audience's Distraction: fewer lanterns than theirs and they will not hear.

var interest: int = 0
var stage_bonus: int = 0
var stage_title: String = ""


func _init() -> void:
	custom_minimum_size = Vector2(330, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_interest(value: int, bonus: int, title: String) -> void:
	if value == interest and bonus == stage_bonus and title == stage_title:
		return
	interest = value
	stage_bonus = bonus
	stage_title = title
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var label: String = "Interest %d" % interest
	draw_string(font, Vector2(0, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe4a1"))
	var x: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 8.0
	for index in range(interest):
		var stage_pip: bool = index >= interest - stage_bonus
		draw_rect(Rect2(Vector2(x + (index % 20) * 7.0, 4 + (index / 20) * 9.0), Vector2(5, 7)), Color("fff1b0") if stage_pip else Color("f2c14e"))
	if not stage_title.is_empty():
		var note: String = "+%d on stage" % stage_bonus
		draw_string(font, Vector2(x + mini(interest, 20) * 7.0 + 6.0, 16), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1b0"))
