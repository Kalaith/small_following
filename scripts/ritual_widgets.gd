extends RefCounted
## Styled labels and buttons for the ritual screen, added to the parent the caller names.

const Style = preload("res://scripts/ritual_style.gd")


static func label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


static func button(parent: Node, value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Style.WHITE)
	button.add_theme_color_override("font_disabled_color", Style.MUTED)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("42265e") if primary else Color("20162f")
		style.border_color = Color("8b5fba") if primary else Color("49305f")
		if state == "hover":
			style.bg_color = Color("634184")
			style.border_color = Style.LILAC
		elif state == "pressed":
			style.bg_color = Color("8a59b9")
		elif state == "disabled":
			style.bg_color = Color("231a2e")
			style.border_color = Color("3a2b4b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state, style)
	parent.add_child(button)
	return button
