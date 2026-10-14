extends Control
## Quillmoor's argument cards beside the circle: one per argument, showing its
## faculty badge, whether it is prepared and how many academics it opens. A card
## only asks for a change (`toggled`); progression decides the loadout.
## Mouse and touch press the cards; keys 1-4 toggle one directly, and a pad's
## bumpers move the highlight while Y toggles it (see ritual_screen.gd).

signal toggled(argument: String)

const Style = preload("res://scripts/ritual_style.gd")
const Widgets = preload("res://scripts/ritual_widgets.gd")
const ArgumentBadge = preload("res://scripts/argument_badge.gd")
const University = preload("res://scripts/university.gd")
const Progression = preload("res://scripts/progression.gd")


class Card extends Button:
	var argument: String = ""
	var prepared: bool = false
	var highlighted: bool = false

	func _draw() -> void:
		ArgumentBadge.draw(self, Vector2(18, size.y * 0.5), argument, 9.0, not prepared)
		if highlighted:
			draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Style.LILAC, false, 2.0)


var cards: Array[Card] = []
## The card a pad's bumpers have moved to.
var cursor: int = 0
var _heading: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_heading = Widgets.label(self, "", 12, Style.VIOLET)
	for argument in Progression.argument_ids():
		var card := Card.new()
		card.argument = argument
		card.toggle_mode = true
		card.focus_mode = Control.FOCUS_NONE
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 12)
		card.add_theme_color_override("font_color", Style.MUTED)
		card.add_theme_color_override("font_pressed_color", Style.WHITE)
		card.add_theme_color_override("font_hover_color", Style.WHITE)
		card.add_theme_color_override("font_hover_pressed_color", Style.WHITE)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("3d2457") if state.contains("pressed") else Color("1b1328")
			box.border_color = Style.VIOLET if state.contains("pressed") else Color("49305f")
			if state.begins_with("hover"):
				box.border_color = Style.LILAC
			box.set_border_width_all(2 if state.contains("pressed") else 1)
			box.set_corner_radius_all(6)
			box.content_margin_left = 36
			box.content_margin_right = 8
			card.add_theme_stylebox_override(state, box)
		card.pressed.connect(func() -> void: toggled.emit(card.argument))
		add_child(card)
		cards.append(card)
	resized.connect(_layout)


func refresh(progression) -> void:
	if progression == null:
		return
	var slots: int = progression.argument_slots()
	_heading.text = "PREPARE YOUR CASE  /  %d of %d slot%s filled  /  keys 1-4, or bumpers + Y" % [progression.uni_loadout.size(), slots, "" if slots == 1 else "s"]
	for index in range(cards.size()):
		var card: Card = cards[index]
		card.prepared = progression.is_prepared(card.argument)
		card.set_pressed_no_signal(card.prepared)
		card.highlighted = index == cursor
		var opens: int = University.academics_needing(card.argument, progression.uni_stage)
		card.text = "%s%s\n%s / opens %d" % [ArgumentBadge.title(card.argument).to_upper(), "  - PREPARED" if card.prepared else "", ArgumentBadge.faculty(card.argument), opens]
		card.tooltip_text = "%s moves %s's academics: %d in the university." % [ArgumentBadge.title(card.argument), ArgumentBadge.faculty(card.argument), opens]
		card.queue_redraw()


func move_cursor(step: int) -> void:
	cursor = wrapi(cursor + step, 0, cards.size())
	for index in range(cards.size()):
		cards[index].highlighted = index == cursor
		cards[index].queue_redraw()


func toggle_at(index: int) -> void:
	if index >= 0 and index < cards.size():
		cursor = index
		toggled.emit(cards[index].argument)


func _layout() -> void:
	_heading.position = Vector2(2, 0)
	_heading.size = Vector2(size.x, 18)
	var gap: float = 8.0
	var width: float = (size.x - gap * (cards.size() - 1)) / maxf(1.0, cards.size())
	for index in range(cards.size()):
		cards[index].position = Vector2(index * (width + gap), 20)
		cards[index].size = Vector2(width, size.y - 20)
