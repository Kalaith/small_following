extends Control
## The village HUD: one status card top-right, the context card bottom-left and
## the between-round buttons. Main owns the round; this only shows it.
const Keys = preload("res://addons/hatchery/input/key_bindings.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Fair = preload("res://scripts/fair.gd")
const FairHud = preload("res://scripts/fair_hud.gd")
const University = preload("res://scripts/university.gd")
const UniHud = preload("res://scripts/uni_hud.gd")
const Rosecourt = preload("res://scripts/rosecourt.gd")
const Balance = preload("res://addons/hatchery/core/balance.gd")
const ArgumentBadge = preload("res://scripts/argument_badge.gd")
## Village HUD frame: screen margin, gap between cards and the corner settings button.
const HUD_MARGIN: float = 26.0
const HUD_GAP: float = 10.0
const HUD_BUTTON_WIDTH: float = 214.0
const SETTINGS_SIZE: float = 48.0

var game: Node2D
var area_label: Label
var stats_label: Label
var round_label: Label
var context_label: Label
var walk_hint_label: Label
var save_label: Label
var ritual_button: Button
var next_round_button: Button
var fair_hud: Control
var uni_hud: Control
## Cards and buttons that a village tap must not walk through.
var blockers: Array[Control] = []


func build(owner_game: Node2D) -> void:
	game = owner_game
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# One status card in the top-right corner, left of the settings button; the
	# top-left stays clear for the map's own signs.
	var status := _panel()
	blockers.append(status)
	add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	status.offset_left = -HUD_MARGIN - SETTINGS_SIZE - HUD_GAP
	status.offset_right = status.offset_left
	status.offset_top = HUD_MARGIN
	var status_rows := VBoxContainer.new()
	status_rows.add_theme_constant_override("separation", 2)
	status.add_child(status_rows)
	area_label = _label("", 12, Color("#c9d6b4"))
	stats_label = _label("", 19)
	round_label = _label("", 14, Color("#d9dfc2"))
	status_rows.add_child(area_label)
	status_rows.add_child(stats_label)
	status_rows.add_child(round_label)
	fair_hud = FairHud.new()
	status_rows.add_child(fair_hud)
	uni_hud = UniHud.new()
	status_rows.add_child(uni_hud)
	var help_panel := _panel()
	blockers.append(help_panel)
	add_child(help_panel)
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help_panel.offset_left = HUD_MARGIN
	help_panel.offset_top = -HUD_MARGIN
	help_panel.offset_bottom = -HUD_MARGIN
	var help_rows := VBoxContainer.new()
	help_rows.add_theme_constant_override("separation", 2)
	help_panel.add_child(help_rows)
	context_label = _label("", 17)
	help_rows.add_child(context_label)
	# Shown only until the first recruit; after that the player knows how to walk.
	walk_hint_label = _label("Tap / click to walk; tap yourself to stop. Keys / stick also work.", 13, Color("#d9dfc2"))
	help_rows.add_child(walk_hint_label)
	save_label = _label("", 13, Color("#ffe4a1"))
	help_rows.add_child(save_label)
	next_round_button = _village_button(true)
	next_round_button.offset_right = -HUD_MARGIN
	next_round_button.pressed.connect(game.start_next_round)
	ritual_button = _village_button(false)
	ritual_button.offset_right = -HUD_MARGIN - HUD_BUTTON_WIDTH - HUD_GAP
	ritual_button.pressed.connect(game.set_ritual_visible.bind(true))
	for button in [next_round_button, ritual_button]:
		button.offset_left = button.offset_right - HUD_BUTTON_WIDTH


func _village_button(primary: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#fff1d0"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.31, 0.22, 0.42, 0.96) if primary else Color(0.19, 0.26, 0.21, 0.94)
		style.border_color = Color("#c6a6ea") if primary else Color("#8fa483")
		if state == "hover":
			style.bg_color = style.bg_color.lightened(0.12)
			style.border_color = Color("#fff1d0")
		elif state == "pressed":
			style.bg_color = style.bg_color.darkened(0.15)
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		button.add_theme_stylebox_override(state, style)
	add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_top = -HUD_MARGIN - 56
	button.offset_bottom = -HUD_MARGIN
	blockers.append(button)
	return button


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.26, 0.21, 0.94)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	return panel


func _label(value: String, font_size: int, color: Color = Color("#fff1d0")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _fair_context() -> String:
	if not game.round_active:
		if game.progression.fair_complete():
			return "The Lantern Fair is won!"
		return "Round complete."
	if is_instance_valid(game.fair_boss) and not game.fair_boss.defeated and game.fair_boss.listening:
		var boss: Dictionary = game.fair_boss.profile()
		if game.fair_boss.deaf:
			if game.fair_director.interest < game.fair_boss.distraction():
				return "%s can't hear you: Distraction %d, your Interest %d" % [boss.title, game.fair_boss.distraction(), game.fair_director.interest]
			if game.fair_boss.show_on:
				return "%s is performing - wait for the act to end" % boss.title
			if boss.has("hoops"):
				return "Run through the lit hoop for a Bravo!"
			return "%s only listens while you stand completely still" % boss.title
		return "Convincing %s..." % boss.title
	if is_instance_valid(game.nearest_group):
		if game.nearest_group.deaf:
			return "Deaf ears: %s Distraction %d, your Interest %d" % [game.nearest_group.group_name, game.nearest_group.effective_distraction(), game.fair_director.interest]
		return "Speaking with %s..." % game.nearest_group.group_name
	if game.fair_director.on_stage >= 0:
		return "On the %s: +%d Interest and a longer reach" % [game.fair_director.stage_title(), game.fair_director.interest - game.progression.fair_interest()]
	if game.progression.fair_complete():
		return "The Lantern Fair is won!  Enjoy the fair."
	if is_instance_valid(game.fair_boss):
		return "%s waits at the fair - Distraction %d" % [game.fair_boss.profile().title, game.fair_boss.distraction()]
	return "Find someone who can hear you over the fair."


func _uni_context() -> String:
	if not game.round_active:
		if game.progression.uni_complete():
			return "Quillmoor is won!"
		return "Round complete. Prepare arguments in the ritual circle."
	if is_instance_valid(game.uni_boss) and not game.uni_boss.defeated and game.uni_boss.listening:
		var boss: Dictionary = game.uni_boss.profile()
		if game.uni_boss.rebutting:
			var missing: PackedStringArray = []
			for argument in game.uni_boss.missing:
				missing.append(ArgumentBadge.title(String(argument)))
			return "%s rebuts everything: prepare %s" % [boss.title, " and ".join(missing)]
		return "Debating %s..." % boss.title
	if is_instance_valid(game.nearest_group):
		return "Speaking with %s..." % game.nearest_group.group_name
	if game.progression.uni_loadout.is_empty():
		return "No arguments prepared: only students and staff will listen."
	if game.progression.uni_complete():
		return "Quillmoor is won!  Enjoy the cloisters."
	if is_instance_valid(game.uni_boss):
		return "%s waits in the %s" % [game.uni_boss.profile().title, University.zone_title(String(game.uni_boss.profile().zone))]
	return "Find someone your prepared arguments can win."


func _rose_context() -> String:
	if not game.round_active:
		if game.progression.rose_king_won:
			return "The King's approval is yours: the Pope will receive you."
		return "Round complete."
	var king: Node2D = game.rose_king
	if is_instance_valid(king) and king.listening:
		if king.reserved():
			return "The King listens only once every grandee is won this round (%d/%d whispered)" % [king.whispers, king.whispers_needed]
		return "Winning the King's approval... %d%%" % floori(100.0 * king.progress / king.conviction())
	if is_instance_valid(game.nearest_group):
		# Salons carry no text in the garden, so the guest being won is named here.
		var group: Node2D = game.nearest_group
		var next: int = group.first_unconverted()
		if next >= 0:
			var whisper: String = "  (whispered: %d%% won)" % roundi(game.progression.rose_head_start() * 100.0) if game.rose_court.is_whispered(group, next) else ""
			return "%s: %s, %.0f conviction / %d gold%s" % [group.group_name, group.listener_profiles[next].role, group.listener_conviction_required(next), group.listener_donation(next), whisper]
		return "Speaking with %s..." % group.group_name
	var waiting: String = _reserved_near()
	if not waiting.is_empty():
		return waiting
	if game.progression.rose_king_won:
		return "The King's approval is yours.  Enjoy the garden party."
	if is_instance_valid(king) and not king.present and game.player.global_position.distance_to(king.global_position) <= game.player.speaking_radius + 60.0:
		return "The throne is empty: the King arrives once %d rose ranks are yours" % Balance.integer("rosecourt.king.arrive_ranks")
	return "Win guests in the right order: who you talk to first opens who listens next."


## A reserved noble in the salon beside the cultist, and who can introduce them.
func _reserved_near() -> String:
	if not is_instance_valid(game.rose_court):
		return ""
	for group in game.groups:
		if game.player.global_position.distance_to(group.global_position) > game.player.speaking_radius + 30.0:
			continue
		for index in range(group.listeners.size()):
			if group.listeners[index].following or group.is_listener_eligible(index) or not bool(group.listener_profiles[index].get("reserved", false)):
				continue
			var by: PackedStringArray = game.rose_court.introducers(group, index)
			return "%s waits for an introduction from %s" % [group.listener_profiles[index].role, " or ".join(by) if not by.is_empty() else "someone they trust"]
	return ""


func refresh() -> void:
	area_label.text = {"bellmarket": "BELLMARKET", Fair.AREA_ID: "THE LANTERN FAIR", University.AREA_ID: "QUILLMOOR", Rosecourt.AREA_ID: "ROSECOURT"}.get(game.progression.active_area, "BRAMBLEWICK")
	fair_hud.visible = game.progression.active_area == Fair.AREA_ID
	uni_hud.visible = game.progression.active_area == University.AREA_ID
	if uni_hud.visible:
		uni_hud.show_loadout(game.progression.uni_loadout, game.progression.argument_slots())
	ritual_button.visible = not game.round_active
	next_round_button.visible = not game.round_active
	ritual_button.text = "Ritual circle  ·  Tab"
	next_round_button.text = "Next round  ·  %s" % Keys.hint("next_round")
	stats_label.text = "%d donations / %d recruits available" % [game.coins, game.progression.available_recruits]
	round_label.text = "Round %d   ·   %.1fs left" % [game.round_number, game.seconds_left]
	walk_hint_label.visible = game.progression.total_recruits == 0
	save_label.text = "Progress notice: see the ritual screen." if not game.progression.last_error.is_empty() else ""
	save_label.visible = not save_label.text.is_empty()
	if game.progression.active_area == Fair.AREA_ID:
		context_label.text = _fair_context()
	elif game.progression.active_area == University.AREA_ID:
		context_label.text = _uni_context()
	elif game.progression.active_area == Rosecourt.AREA_ID:
		context_label.text = _rose_context()
	elif game.progression.active_area == "bellmarket" and game.progression.is_circle_complete():
		context_label.text = "Bellmarket circle complete!  Keep exploring or return to Bramblewick."
	elif game.progression.active_area == "bramblewick" and game.progression.map_complete():
		context_label.text = "Bramblewick complete!" + ("" if not game.round_active else "  Enjoy the village.")
	elif not game.round_active:
		context_label.text = "Round complete."
	elif is_instance_valid(game.encounter) and not game.encounter.defeated:
		context_label.text = "Convince %s in the town center" % Encounter.profiles()[game.encounter.stage].title
	elif is_instance_valid(game.nearest_group):
		context_label.text = "Speaking with %s..." % game.nearest_group.group_name
	else:
		context_label.text = "Walk around props; stand near a gathering to speak."


## True when a visible card or button covers the point.
func blocks(at: Vector2) -> bool:
	for control in blockers:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(at):
			return true
	return false
