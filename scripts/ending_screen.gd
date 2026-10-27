extends Control
## The campaign's ending, shown once the Pope has heard the cultist. A quiet
## full-screen page over the ritual screen; the player walks on from it.

signal closed

const INK := Color("110d1c")
const LILAC := Color("d7b9ff")
const WHITE := Color("f1e5ff")
const MUTED := Color("aa96bb")
const GOLD := Color("dbb879")
const STORY: Array[String] = [
	"Before the great doors of the abbey the Pope raised one hand, and the whole hillside fell quiet.",
	"Pilgrims, brothers and cardinals stood beside the little robed cultist whom no one had thought to take seriously. And behind them stood every follower who had ever walked the long road: the helper in teal, the market hand, the barker, the page.",
	"\"I am asked to hear many voices,\" said the Pope. \"I was not asked to hear all of them at once.\"",
	"A following that began as one small voice in a village square was no longer small.",
]

var _stats_label: Label
var _button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.custom_minimum_size = Vector2(760, 0)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(column)
	column.add_child(_label("THE POPE HAS HEARD YOU", 40, WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_label("THE END", 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	for paragraph in STORY:
		var line: Label = _label(paragraph, 20, LILAC, HORIZONTAL_ALIGNMENT_CENTER)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(line)
	_stats_label = _label("", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_stats_label)
	_button = Button.new()
	_button.text = "Walk on in the abbey"
	_button.custom_minimum_size = Vector2(280, 54)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override("font_size", 19)
	_button.pressed.connect(close)
	column.add_child(_button)


## `rounds` and `followers` are the whole campaign's.
func open(rounds: int, followers: int, donations: int) -> void:
	_stats_label.text = "%d rounds   ·   %d followers   ·   %d donations" % [rounds, followers, donations]
	show()
	_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _label(value: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
