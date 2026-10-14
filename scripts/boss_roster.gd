extends RefCounted
## Places the active area's boss each round (Bramblewick's debate opponent, a
## fair headliner, a Quillmoor boss or Rosecourt's King) and pays out when one
## is convinced. The bosses themselves stay on main, where area travel clears them.
const Balance = preload("res://scripts/balance.gd")
const DonationPopup = preload("res://scripts/donation_popup.gd")
const Encounter = preload("res://scripts/encounter.gd")
const FairBoss = preload("res://scripts/fair_boss.gd")
const UniBoss = preload("res://scripts/uni_boss.gd")
const RoseKing = preload("res://scripts/rose_king.gd")
const Fair = preload("res://scripts/fair.gd")
const University = preload("res://scripts/university.gd")
const Rosecourt = preload("res://scripts/rosecourt.gd")

var game: Node2D


func _init(owner_game: Node2D) -> void:
	game = owner_game


func reset() -> void:
	for key in ["encounter", "fair_boss", "uni_boss", "rose_king"]:
		var boss: Node2D = game.get(key)
		if is_instance_valid(boss):
			boss.get_parent().remove_child(boss)
			boss.queue_free()
		game.set(key, null)
	var progression = game.progression
	if progression.active_area == Rosecourt.AREA_ID:
		var king := RoseKing.new()
		king.present = progression.rose_king_present()
		king.defeated = progression.rose_king_won
		king.convinced.connect(_on_king_convinced)
		king.phrase_spoken.connect(game.game_audio.on_phrase)
		if is_instance_valid(game.rose_court):
			game.rose_court.king_whispered.connect(king.hear_whisper)
			game.rose_court.king_present = king.present and not king.defeated
			game.rose_court.queue_redraw()
		game.actors().add_child(king)
		game.rose_king = king
		return
	if progression.active_area == University.AREA_ID:
		if not progression.uni_complete():
			var uni_boss := UniBoss.new()
			uni_boss.stage = progression.uni_stage
			uni_boss.prepared_from(progression)
			uni_boss.convinced.connect(_on_uni_boss_convinced)
			uni_boss.phrase_spoken.connect(game.game_audio.on_phrase)
			game.actors().add_child(uni_boss)
			game.uni_boss = uni_boss
		return
	if progression.active_area == Fair.AREA_ID:
		if not progression.fair_complete():
			var fair_boss := FairBoss.new()
			fair_boss.stage = progression.fair_stage
			fair_boss.convinced.connect(_on_fair_boss_convinced)
			fair_boss.phrase_spoken.connect(game.game_audio.on_phrase)
			game.actors().add_child(fair_boss)
			game.fair_boss = fair_boss
		return
	if progression.active_area != "bramblewick" or not progression.has_unlock("encounter_unlock") or progression.map_complete():
		return
	var encounter := Encounter.new()
	encounter.stage = progression.encounter_stage
	encounter.convinced.connect(_on_encounter_convinced)
	encounter.phrase_spoken.connect(game.game_audio.on_phrase)
	game.actors().add_child(encounter)
	game.encounter = encounter


func _reward(boss: Node2D, amount: int) -> void:
	game.round_recruits += 1
	var popup := DonationPopup.new()
	popup.amount = amount
	popup.position = Vector2(52, -80)
	boss.add_child(popup)


func _on_encounter_convinced(stage: int) -> void:
	if game.round_active and game.progression.complete_encounter(stage):
		_reward(game.encounter, int(Encounter.profiles()[stage].reward))


func _on_fair_boss_convinced(stage: int) -> void:
	if game.round_active and game.progression.complete_fair_boss(stage):
		_reward(game.fair_boss, int(FairBoss.profiles()[stage].reward))


func _on_uni_boss_convinced(stage: int) -> void:
	if game.round_active and game.progression.complete_uni_boss(stage):
		_reward(game.uni_boss, int(UniBoss.profiles()[stage].reward))


func _on_king_convinced() -> void:
	if game.round_active and game.progression.complete_rose_king():
		_reward(game.rose_king, int(RoseKing.rules().reward))
