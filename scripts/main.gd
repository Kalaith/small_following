extends Node2D
## Movement remains independent of round state and the ritual overlay.
const Gathering = preload("res://scripts/gathering.gd")
const Progression = preload("res://scripts/progression.gd")
const RitualScreen = preload("res://scripts/ritual_screen.gd")
const Encounter = preload("res://scripts/encounter.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const SettingsStore = preload("res://scripts/settings_store.gd")
const DonationPopup = preload("res://scripts/donation_popup.gd")
const Market = preload("res://scripts/market.gd")
const TitleScreen = preload("res://scripts/title_screen.gd")
const Wanderers = preload("res://scripts/wanderers.gd")
const Balance = preload("res://addons/hatchery/core/balance.gd")
const Fair = preload("res://scripts/fair.gd")
const FairBoss = preload("res://scripts/fair_boss.gd")
const FairDirector = preload("res://scripts/fair_director.gd")
const University = preload("res://scripts/university.gd")
const UniBoss = preload("res://scripts/uni_boss.gd")
const Rosecourt = preload("res://scripts/rosecourt.gd")
const VillageHud = preload("res://scripts/village_hud.gd")
const AreaBuilder = preload("res://scripts/area_builder.gd")
const HelperCrew = preload("res://scripts/helper_crew.gd")
const BossRoster = preload("res://scripts/boss_roster.gd")
const SettingsWiring = preload("res://scripts/settings_wiring.gd")
const START_POSITION := Vector2(780, 680)
## Gatherings, merchants, opponents' villagers and the round length are balance
## data in data/balance.json; Bramblewick crowds are small huddles of three or
## four. Indices of the opening three are stable for tests/tools.

@export var show_title_on_start: bool = false
var title_screen: Control
var title_active: bool = false
var persistence_enabled: bool = true
var save_path_override: String = ""
var catalog_ready: bool = false
var progression = Progression.new()
var game_audio = GameAudio.new()
var settings = SettingsStore.new()
var settings_path_override: String = ""
var settings_screen: Control
var settings_button: Button
## Settings screen signals, the debounced preferences save and rebinding.
var settings_wiring: Node
## Builds each area's world and audiences into the lists below.
var area: AreaBuilder
## Hires, places and tunes the helpers for the active area.
var crew: HelperCrew
## Places each round's boss and pays out when one is convinced.
var bosses: BossRoster
var groups: Array[Node2D] = []
## One-listener gatherings kept apart from `groups` so group indices stay stable.
var wanderers: Array[Node2D] = []
## Nonzero seeds make wanderer placement reproducible for tests and captures.
var wanderer_seed: int = 0
var _wanderer_rng := RandomNumberGenerator.new()
var _footprints: Array[Node] = []
var added_gatherings: Dictionary = {}
var encounter: Node2D = null
var helper: Node2D = null
## Bellmarket's second, amber-robed helper (Market Hand).
var market_helper: Node2D = null
## The fair's moss-green Barker.
var fair_helper: Node2D = null
## The fair's round state (shows, stages, Distraction) and current headliner.
var fair_director = FairDirector.new()
var fair_boss: Node2D = null
## Quillmoor's current boss and the HUD strip of prepared arguments.
var uni_boss: Node2D = null
## Rosecourt's whispered introductions (threads, reserved nobles, head starts).
var rose_court: Node2D = null
## The King of Rosecourt, on his throne once he has arrived.
var rose_king: Node2D = null
var seconds_left: float = Balance.number("round.seconds")
var round_active: bool = true
var round_recruits: int = 0
var nearest_group: Node2D = null
var coins: int:
	get:
		return progression.coins
var total_recruits: int:
	get:
		return progression.total_recruits
var round_number: int:
	get:
		return progression.round_number

@onready var player = $Actors/Player
var hud_layout: VillageHud
var ritual_screen: Control
var village_input: Node


func _ready() -> void:
	area = AreaBuilder.new(self)
	crew = HelperCrew.new(self)
	bosses = BossRoster.new(self)
	settings_wiring = SettingsWiring.new(self)
	# Existing isolated scene tests must also avoid the normal preferences file.
	settings.save_enabled = persistence_enabled and (save_path_override.is_empty() or not settings_path_override.is_empty())
	if not settings_path_override.is_empty():
		settings.path = settings_path_override
	settings.load_settings()
	settings.apply_bindings()
	game_audio.apply_preferences(settings.values)
	DonationPopup.reduce_motion = settings.values.reduce_motion
	player.reduce_motion = settings.values.reduce_motion
	game_audio.name = "GameAudio"
	add_child(game_audio)
	game_audio.preferences_changed.connect(settings_wiring.audio_preferences_changed)
	player.moved.connect(game_audio.on_motion)
	progression.save_enabled = persistence_enabled
	if not save_path_override.is_empty():
		progression.save_path = save_path_override
	catalog_ready = progression.load_catalog()
	if persistence_enabled and catalog_ready:
		progression.load_progress()
	if not catalog_ready:
		progression.save_enabled = false
		round_active = false
	area.rebuild()
	_build_hud()
	_build_ritual()
	settings_wiring.build()
	_build_title()
	village_input = preload("res://scripts/village_input.gd").new()
	add_child(village_input)
	if settings.values.fullscreen and not OS.has_feature("web"):
		settings_wiring.set_fullscreen(true)
	apply_upgrades()
	_reset_encounter()
	_update_hud()
	if not catalog_ready:
		set_ritual_visible(true)
	if show_title_on_start:
		show_title()
	print("Small Following: starter scene ready.")


func area_start_position() -> Vector2:
	if progression.active_area == Fair.AREA_ID:
		return Fair.start_position()
	if progression.active_area == University.AREA_ID:
		return University.start_position()
	if progression.active_area == Rosecourt.AREA_ID:
		return Rosecourt.start_position()
	return Market.START_POSITION if progression.active_area == "bellmarket" else START_POSITION


func travel_to(area_id: String, bypass_unlock: bool = false) -> bool:
	if round_active or not catalog_ready:
		return false
	var layouts: Array[Dictionary] = []
	if area_id == "bellmarket":
		layouts = Market.group_layout()
	elif area_id == Fair.AREA_ID:
		for entry in Balance.list("fair.groups") + Balance.list("fair.fan_groups"):
			layouts.append({"profiles": Fair.profiles(entry.people)})
	elif area_id == University.AREA_ID:
		for entry in Balance.list("university.groups") + Balance.list("university.follower_groups"):
			layouts.append({"profiles": University.profiles(entry.people)})
	elif area_id == Rosecourt.AREA_ID:
		for entry in Balance.list("rosecourt.salons"):
			layouts.append({"profiles": Rosecourt.profiles(entry.people)})
	if not layouts.is_empty():
		for entry in layouts:
			var probe := Gathering.new()
			probe.listener_profiles.assign(entry.profiles)
			var error: String = probe.validate_profiles()
			probe.free()
			if not error.is_empty():
				progression.last_error = error
				return false
	if not progression.try_travel(area_id, bypass_unlock):
		# Reveal the existing error panel instead of leaving it behind the travel modal.
		ritual_screen.dismiss_demo_message()
		ritual_screen.update_state(round_recruits)
		_update_hud()
		return false
	area.rebuild()
	seconds_left = Balance.number("round.seconds")
	round_recruits = 0
	apply_upgrades()
	_reset_encounter()
	game_audio.reset_motion()
	game_audio.stop_speech()
	ritual_screen.configure(progression.catalog, progression)
	_configure_destination()
	set_ritual_visible(true)
	_update_hud()
	return true


## Each completed circle opens the next area; every later area can return to the one before.
func _configure_destination() -> void:
	var index: int = Progression.AREA_IDS.find(progression.active_area)
	if index + 1 < Progression.AREA_IDS.size() and not progression.catalog_for_area(Progression.AREA_IDS[index + 1]).is_empty():
		var next: String = Progression.AREA_IDS[index + 1]
		ritual_screen.configure_destination(next, Progression.AREA_TITLES[next])
	else:
		ritual_screen.configure_destination()
	if index > 0:
		ritual_screen.configure_return(Progression.AREA_IDS[index - 1], Progression.AREA_TITLES[Progression.AREA_IDS[index - 1]])
	else:
		ritual_screen.configure_return()


func _build_title() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Title"
	canvas.layer = 8
	add_child(canvas)
	title_screen = TitleScreen.new()
	canvas.add_child(title_screen)
	title_screen.continue_requested.connect(continue_from_title)
	title_screen.level_requested.connect(_start_selected_level)
	title_screen.settings_requested.connect(set_settings_visible.bind(true))
	title_screen.new_game_requested.connect(start_new_game)
	title_screen.hide()


func show_title() -> void:
	set_settings_visible(false)
	progression.save_progress()
	round_active = false
	for each in helpers():
		each.set_active(false)
	game_audio.stop_speech()
	player.clear_walk_target()
	player.set_physics_process(false)
	title_active = true
	set_ritual_visible(false)
	hud_layout.hide()
	settings_button.hide()
	title_screen.unlocked = title_screen.unlocked or progression.level_select_unlocked
	title_screen.configure(progression.active_area, progression.is_area_unlocked("bellmarket"), progression.has_progress(), progression.is_area_unlocked(Fair.AREA_ID), progression.is_area_unlocked(University.AREA_ID), progression.is_area_unlocked(Rosecourt.AREA_ID))
	title_screen.show()
	if not progression.last_error.is_empty():
		title_screen.show_error(progression.last_error)


func _leave_title() -> void:
	title_active = false
	title_screen.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	player.set_physics_process(true)
	settings_button.show()
	hud_layout.show()


func continue_from_title() -> void:
	if not catalog_ready:
		title_screen.show_error(progression.last_error)
		return
	_leave_title()
	_begin_round(false)


## Title-only: wipes progression to a fresh save, rebuilds Bramblewick and
## begins round 1. A failed save keeps the current game and shows why.
func start_new_game() -> void:
	if not title_active:
		return
	if not catalog_ready or not progression.start_new_game():
		title_screen.show_error(progression.last_error)
		return
	area.rebuild()
	round_recruits = 0
	apply_upgrades()
	ritual_screen.configure(progression.catalog, progression)
	_configure_destination()
	game_audio.reset_motion()
	game_audio.stop_speech()
	_leave_title()
	_begin_round(false)


func _start_selected_level(area_id: String) -> void:
	if not title_active:
		return
	if not travel_to(area_id, title_screen.unlocked):
		title_screen.show_error(progression.last_error)
		return
	_leave_title()
	_begin_round(false)


## Every speakable audience: fixed groups first, then lone wanderers.
func audiences() -> Array[Node2D]:
	var result: Array[Node2D] = groups.duplicate()
	result.append_array(wanderers)
	return result


func _process(delta: float) -> void:
	advance_round(delta)
	_update_hud()
	if DisplayServer.get_name() != "headless" and settings.values.fullscreen != settings_wiring.is_fullscreen():
		settings.values.fullscreen = settings_wiring.is_fullscreen()
		settings_wiring.queue_save()
	if settings_screen.visible:
		settings_wiring.refresh()


func _input(event: InputEvent) -> void:
	if settings_screen.visible and settings_screen.capture_key(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if title_active and not settings_screen.visible:
		# The LineEdit owns typed characters, including remapped game shortcuts.
		return
	if event.is_action_pressed("toggle_settings"):
		if ritual_screen.demo_message_visible():
			ritual_screen.dismiss_demo_message()
		else:
			set_settings_visible(not settings_screen.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_fullscreen"):
		settings_wiring.set_fullscreen(not settings_wiring.is_fullscreen())
		get_viewport().set_input_as_handled()
	elif settings_screen.visible and event.is_action_pressed("toggle_ritual") and not round_active:
		set_settings_visible(false)
		set_ritual_visible(false)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if title_active:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_audio"):
		game_audio.toggle_mute()
	elif event.is_action_pressed("toggle_voice"):
		game_audio.toggle_voice()
	elif settings_screen.visible:
		return
	elif event.is_action_pressed("next_round"):
		start_next_round()
	elif event.is_action_pressed("buy_upgrade") and ritual_screen.visible:
		purchase_upgrade(ritual_screen.selected_id, ritual_screen.get_selected_rank())
	elif event.is_action_pressed("toggle_ritual") and not round_active:
		set_ritual_visible(not ritual_screen.visible)


func set_settings_visible(value: bool) -> void:
	if is_instance_valid(village_input):
		village_input.cancel_gesture()
	settings_screen.cancel_capture()
	ritual_screen.set_pointer_input_enabled(not value)
	if value:
		ritual_screen.dismiss_demo_message()
	settings_screen.visible = value
	settings_button.visible = not value and not title_active
	if value:
		settings_wiring.refresh()
		settings_screen.focus_first()
	elif not settings_wiring.settings_timer.is_stopped():
		settings_wiring.save_now()


func _exit_tree() -> void:
	if is_instance_valid(settings_wiring.settings_timer) and not settings_wiring.settings_timer.is_stopped():
		settings.save_settings()


func exit_game() -> void:
	if OS.has_feature("web"):
		return
	settings_wiring.save_now()
	progression.save_progress()
	get_tree().quit()


func advance_round(delta: float) -> void:
	game_audio.advance_time(delta)
	if title_active:
		return
	nearest_group = null
	var fair: bool = progression.active_area == Fair.AREA_ID
	var all_audiences: Array[Node2D] = audiences()
	var usable_delta: float = minf(maxf(delta, 0.0), seconds_left) if round_active else 0.0
	var speak_radius: float = player.speaking_radius
	var still: bool = _player_still()
	if fair:
		# Stage, Interest and every Distraction are current before anyone speaks.
		fair_director.update_speaker(progression, player.global_position, player.speaking_radius)
		speak_radius = fair_director.reach
		fair_director.advance(usable_delta, progression, all_audiences, fair_boss, _footprints, get_node_or_null("Village"))
		hud_layout.fair_hud.show_interest(fair_director.interest, fair_director.interest - progression.fair_interest(), fair_director.stage_title())
	elif round_active and not wanderers.is_empty():
		# Beckoning Call (Market Call in Bellmarket) draws lone wanderers in during
		# the round's usable time only.
		var reach: float = progression.market_beckon_reach() if progression.active_area == "bellmarket" else progression.beckon_reach()
		Wanderers.pull(wanderers, player.global_position, reach, usable_delta, _footprints)
	var closest_distance: float = speak_radius
	var nearby_group: Node2D = null
	var nearby_distance: float = speak_radius + 30.0
	# At the fair the nearest group that can hear you is chosen first, so a deaf
	# crowd close by never steals speech from a quiet group in range.
	var heard_group: Node2D = null
	var heard_distance: float = speak_radius
	for group in all_audiences:
		var distance: float = player.global_position.distance_to(group.global_position)
		if distance <= nearby_distance:
			nearby_distance = distance
			nearby_group = group
		if distance <= closest_distance and group.first_unconverted() >= 0:
			closest_distance = distance
			nearest_group = group
		if fair and distance <= heard_distance and group.first_unconverted() >= 0 and group.hears(fair_director.interest) and (still or not group.still_only):
			heard_distance = distance
			heard_group = group
		group.set_listening(false)
		group.set_nearby(false)
	if is_instance_valid(heard_group):
		nearest_group = heard_group
	if is_instance_valid(nearby_group):
		nearby_group.set_nearby(true)
	if not round_active:
		for group in all_audiences:
			group.set_deaf(false)
		game_audio.stop_speech()
		return
	var speaking_to_opponent: bool = false
	if is_instance_valid(encounter) and not encounter.defeated:
		var speech_delta: float = encounter.advance_arrival(usable_delta)
		speaking_to_opponent = encounter.arrived and player.global_position.distance_to(encounter.global_position) <= player.speaking_radius
		encounter.advance_speech(speech_delta, speaking_to_opponent, progression.speech_interval(), progression.encounter_conviction(str(Encounter.profiles()[encounter.stage].id)))
	if is_instance_valid(fair_boss) and not fair_boss.defeated:
		# A headliner who can hear you comes first. A deaf one yields to any group
		# that can; with no such group nearby he still gets your unheard phrases.
		var in_range: bool = player.global_position.distance_to(fair_boss.global_position) <= speak_radius
		speaking_to_opponent = in_range and (fair_boss.hears(fair_director.interest, still) or not is_instance_valid(heard_group))
		fair_boss.drain_multiplier = progression.fair_drain_multiplier()
		fair_boss.advance(usable_delta, speaking_to_opponent, progression.speech_interval(), progression.conviction_per_phrase(), fair_director.interest, still, player.global_position)
	if is_instance_valid(uni_boss) and not uni_boss.defeated:
		# A boss whose arguments are prepared comes first. One that would rebut
		# yields to any group you can win; with none nearby it rebuts your phrases.
		uni_boss.prepared_from(progression)
		var boss_in_range: bool = uni_boss.arrived() and player.global_position.distance_to(uni_boss.global_position) <= speak_radius
		speaking_to_opponent = boss_in_range and (uni_boss.prepared or not is_instance_valid(nearest_group))
		uni_boss.advance(usable_delta, speaking_to_opponent, progression.speech_interval(), progression.conviction_per_phrase() + progression.uni_argument_conviction(uni_boss.needs()))
	if is_instance_valid(rose_king) and rose_king.present and not rose_king.defeated:
		# A reserved King yields to any guest you can win; with none nearby he
		# still takes your phrases, and ignores them until his grandees whisper.
		var king_in_range: bool = player.global_position.distance_to(rose_king.global_position) <= speak_radius
		speaking_to_opponent = king_in_range and (not rose_king.reserved() or not is_instance_valid(nearest_group))
		rose_king.advance(usable_delta, speaking_to_opponent, progression.speech_interval(), progression.conviction_per_phrase())
	if speaking_to_opponent:
		nearest_group = null
	if is_instance_valid(nearest_group):
		nearest_group.set_listening(true)
		nearest_group.tick_persuasion(usable_delta, progression.speech_interval(), progression.conviction_for(nearest_group.npc_type), fair_director.interest if fair else 0, still)
	elif not speaking_to_opponent:
		game_audio.stop_speech()
	for group in all_audiences:
		if group != nearest_group:
			group.advance_unattended(usable_delta)
	if fair:
		_apply_barker_cut(all_audiences)
	for each in helpers():
		each.set_active(true)
		each.advance(usable_delta, all_audiences)
	seconds_left = maxf(0.0, seconds_left - usable_delta)
	if seconds_left <= 0.0:
		round_active = false
		game_audio.stop_speech()
		for each in helpers():
			each.set_active(false)
		for group in all_audiences:
			group.set_listening(false)
		progression.save_progress()
		set_ritual_visible(true)


## The Mime (and his watchers) hear only a cultist standing completely still.
func _player_still() -> bool:
	return player.velocity.length_squared() < 1.0


## The group the Barker is speaking to is less distracted for everyone there.
func _apply_barker_cut(all_audiences: Array[Node2D]) -> void:
	for group in all_audiences:
		group.barker_cut = 0
	if is_instance_valid(fair_helper) and fair_helper.speaking and is_instance_valid(fair_helper.target_group):
		fair_helper.target_group.barker_cut = fair_helper.distraction_cut


func _reset_encounter() -> void:
	bosses.reset()


## A tapped argument card between rounds. Progression decides the loadout; the
## groups then re-check who can hear it, and the cards and HUD redraw.
func toggle_argument(argument: String) -> bool:
	if round_active or progression.active_area != University.AREA_ID:
		return false
	var changed: bool = progression.toggle_argument(argument)
	_refresh_faculty_rule()
	ritual_screen.update_state(round_recruits)
	_update_hud()
	return changed


func _refresh_faculty_rule() -> void:
	for group in audiences():
		group.configure_market(progression)
	if is_instance_valid(uni_boss):
		uni_boss.prepared_from(progression)
		uni_boss.queue_redraw()


func _on_recruited(donation: int) -> void:
	progression.add_donation(donation, 1)
	round_recruits += 1


func purchase_upgrade(id: String, expected_rank: int = -1) -> bool:
	if round_active:
		return false
	var purchased: bool = progression.try_purchase(id, expected_rank)
	if purchased:
		apply_upgrades()
	ritual_screen.update_state(round_recruits)
	_update_hud()
	return purchased


func apply_upgrades() -> void:
	player.movement_speed = Balance.number("round.base_run_speed") * progression.run_multiplier()
	if progression.active_area == Fair.AREA_ID:
		var group_count: int = groups.size()
		area.add_stage_gatherings()
		if groups.size() != group_count:
			area.scatter_wanderers()
		_apply_helper()
		return
	if progression.active_area == University.AREA_ID:
		var group_count: int = groups.size()
		area.add_stage_gatherings()
		if groups.size() != group_count:
			area.scatter_wanderers()
		# A new slot never changes the loadout, but locks are re-read anyway.
		_refresh_faculty_rule()
		_apply_helper()
		return
	if progression.active_area == Rosecourt.AREA_ID:
		# Ranks change head starts, threads and who is trusted, so locks are re-read.
		for group in audiences():
			group.configure_market(progression)
		if is_instance_valid(rose_court):
			rose_court.reset_round()
		_apply_helper()
		return
	if progression.active_area == "bellmarket":
		for group in groups:
			group.configure_market(progression)
		for wanderer in wanderers:
			wanderer.configure_market(progression)
		area.sync_market_wanderers()
		_apply_helper()
		return
	var group_count: int = groups.size()
	for entry in Balance.list("village.invited_gatherings"):
		if progression.has_unlock(entry.key) and not added_gatherings.has(entry.key):
			area.add_gathering(entry.title, Balance.vec(entry.at), false, int(entry.count))
			added_gatherings[entry.key] = true
	if progression.has_unlock("merchant_unlock") and not added_gatherings.has("merchant_unlock"):
		var merchants: Dictionary = Balance.dict("village.merchants")
		area.add_gathering(merchants.title, Balance.vec(merchants.at), true)
		added_gatherings["merchant_unlock"] = true
	area.add_stage_gatherings()
	# Purchases happen between rounds, so moving wanderers off a new group is safe.
	if groups.size() != group_count:
		area.scatter_wanderers()
	for group in groups:
		if group.npc_type == "merchant":
			group.donation = progression.merchant_donation()
	_apply_helper()


func _apply_helper() -> void:
	crew.apply()


## Every helper present in this area, original first.
func helpers() -> Array[Node2D]:
	return crew.members()


func set_ritual_visible(value: bool) -> void:
	if is_instance_valid(village_input):
		village_input.cancel_gesture()
	ritual_screen.visible = value and not round_active and not title_active
	hud_layout.visible = not ritual_screen.visible and not title_active
	if ritual_screen.visible:
		ritual_screen.update_state(round_recruits)


func start_next_round() -> void:
	if round_active or not catalog_ready or title_active:
		return
	_begin_round(true)


func _begin_round(increment: bool) -> void:
	if increment:
		progression.round_number += 1
	progression.save_progress()
	seconds_left = Balance.number("round.seconds")
	round_recruits = 0
	nearest_group = null
	round_active = true
	# Opponents convinced last round send their villagers from this round on.
	area.add_stage_gatherings()
	for group in audiences():
		group.reset_round()
	if is_instance_valid(rose_court):
		rose_court.reset_round()
	fair_director.reset_round()
	area.scatter_wanderers()
	# Every round uses the same entrance; walking in menus does not grant a head start.
	player.clear_walk_target()
	player.position = area_start_position()
	game_audio.reset_motion()
	game_audio.stop_speech()
	for each in helpers():
		each.reset_round(area_start_position())
	_reset_encounter()
	player.get_node("Camera2D").reset_smoothing()
	set_ritual_visible(false)
	_update_hud()


func _build_ritual() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Ritual"
	canvas.layer = 5
	add_child(canvas)
	ritual_screen = RitualScreen.new()
	canvas.add_child(ritual_screen)
	ritual_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ritual_screen.configure(progression.catalog, progression)
	_configure_destination()
	ritual_screen.travel_requested.connect(travel_to)
	ritual_screen.argument_toggled.connect(toggle_argument)
	ritual_screen.purchase_requested.connect(purchase_upgrade)
	ritual_screen.next_round_requested.connect(start_next_round)
	ritual_screen.return_to_village_requested.connect(set_ritual_visible.bind(false))
	ritual_screen.hide()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	hud_layout = VillageHud.new()
	canvas.add_child(hud_layout)
	hud_layout.build(self)


func _update_hud() -> void:
	hud_layout.refresh()


## The node every actor, prop and audience lives under.
func actors() -> Node2D:
	return $Actors


func village_tap_available(at: Vector2) -> bool:
	if title_active or ritual_screen.visible or settings_screen.visible:
		return false
	if settings_button.is_visible_in_tree() and settings_button.get_global_rect().has_point(at):
		return false
	if hud_layout.blocks(at):
		return false
	return get_viewport().get_visible_rect().has_point(at)

