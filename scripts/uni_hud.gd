extends Control
## The prepared arguments at Quillmoor, drawn as the same faculty badges the
## academics wear, with their names and the slots still empty.

const ArgumentBadge = preload("res://scripts/argument_badge.gd")

var loadout: Array[String] = []
var slots: int = 1


func _init() -> void:
	custom_minimum_size = Vector2(330, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_loadout(prepared: Array[String], owned: int) -> void:
	if prepared == loadout and owned == slots:
		return
	loadout = prepared.duplicate()
	slots = owned
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var x: float = 0.0
	var label: String = "Arguments" if not loadout.is_empty() else "No arguments prepared"
	draw_string(font, Vector2(0, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe4a1"))
	x = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 12.0
	for argument in loadout:
		ArgumentBadge.draw(self, Vector2(x + 7, 11), argument, 7.0)
		var name: String = ArgumentBadge.title(argument)
		draw_string(font, Vector2(x + 18, 16), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff1d0"))
		x += 26.0 + font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	for index in range(maxi(0, slots - loadout.size())):
		draw_arc(Vector2(x + 7, 11), 7.0, 0, TAU, 20, Color("d9dfc2"), 1.2, true)
		x += 20.0
