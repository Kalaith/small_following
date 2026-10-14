extends Node2D
## One person in a gathering: their look, role accessories and reward popup.
## The gathering owns who is eligible; this only draws what it is told.
const DonationPopup = preload("res://scripts/donation_popup.gd")
const Badge = preload("res://scripts/argument_badge.gd")

var following: bool = false
var coat: Color = Color("#9c695a")
var phase: float = 0.0
var merchant: bool = false
## Village type accessory (doubter / watch / devotee); empty for ordinary listeners.
var kind: String = ""
var role: String = ""
var profile_type: String = "ordinary"
var locked: bool = false
## Quillmoor academics need this argument prepared; empty for everyone else.
var argument: String = ""
## Phrases fall on deaf ears: a "..." and a glance away.
var deaf: bool = false
var performing: bool = false
var reward_label: Label

func show_reward(amount: int) -> void:
	clear_reward()
	reward_label = DonationPopup.new()
	reward_label.amount = amount
	reward_label.position.y = -64
	add_child(reward_label)

func clear_reward() -> void:
	if is_instance_valid(reward_label):
		reward_label.hide()
		reward_label.queue_free()
		reward_label = null

func _process(delta: float) -> void:
	phase += delta * 1.8
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 0), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 12, Color(0.22, 0.27, 0.2, 0.17))
	draw_set_transform(Vector2.ZERO)
	var bob: float = sin(phase) * 0.65
	var tint: Color = Color("#9780a7") if following else coat
	draw_line(Vector2(-4, -9), Vector2(-5, 0), Color("#625648"), 4)
	draw_line(Vector2(4, -9), Vector2(5, 0), Color("#625648"), 4)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -23 + bob), Vector2(8, -23 + bob), Vector2(12, -6), Vector2(-11, -6)]), tint)
	draw_circle(Vector2(0, -29 + bob), 9, Color("#eac49a"))
	draw_arc(Vector2(0, -31 + bob), 9, PI, TAU, 12, Color("#75604a"), 4, true)
	# A deaf listener glances away toward the fun instead of at the cultist.
	var glance: float = 2.5 if deaf and not following else 0.0
	draw_circle(Vector2(-3 + glance, -29 + bob), 1.1, Color("#4e4944"))
	draw_circle(Vector2(3 + glance, -29 + bob), 1.1, Color("#4e4944"))
	if merchant:
		draw_rect(Rect2(-12, -40 + bob, 24, 5), Color("#75562d"))
		draw_rect(Rect2(-7, -48 + bob, 14, 10), Color("#b38c3c"))
		draw_circle(Vector2(12, -12), 6, Color("#e2b953"))
		draw_line(Vector2(12, -16), Vector2(12, -8), Color("#765923"), 2)
	if not role.is_empty():
		_draw_role(bob)
	elif not kind.is_empty():
		_draw_kind(bob)
	if not argument.is_empty():
		# The faculty badge on the gown, shape first; dim while unprepared.
		Badge.draw(self, Vector2(-7, -15 + bob), argument, 5.0, locked and not following)
		if locked and not following:
			# An unprepared academic rebuts everything: a struck-through bubble.
			Badge.draw_rebuttal(self, Vector2(2, -76), argument)
	elif locked and not following:
		draw_rect(Rect2(-5, -60, 10, 9), Color("#f3ddb0"))
		draw_arc(Vector2(0, -60), 4, PI, TAU, 10, Color("#f3ddb0"), 2, true)
		draw_circle(Vector2(0, -56), 1.2, Color("#514b58"))
	if following:
		draw_line(Vector2(-4, -45), Vector2(-1, -42), Color("#fbf1b6"), 2)
		draw_line(Vector2(-1, -42), Vector2(5, -49), Color("#fbf1b6"), 2)
	elif deaf:
		draw_style_box(_bubble(), Rect2(4, -66, 26, 15))
		for dot in range(3):
			draw_circle(Vector2(11 + dot * 6, -58), 1.6, Color("#6a6070"))

func _bubble() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f6efe0")
	style.set_corner_radius_all(7)
	return style

func _draw_kind(bob: float) -> void:
	match kind:
		"doubter": # Spectacles and a closed book, like the Skeptic.
			draw_arc(Vector2(-3, -29 + bob), 3.2, 0, TAU, 12, Color("493f3e"), 1.0, true)
			draw_arc(Vector2(3, -29 + bob), 3.2, 0, TAU, 12, Color("493f3e"), 1.0, true)
			draw_rect(Rect2(-14, -19, 10, 12), Color("634d78"))
		"watch": # Round helmet and a short spear, like the Town Guard.
			draw_arc(Vector2(0, -32 + bob), 9, PI, TAU, 14, Color("aab9bd"), 5, true)
			draw_line(Vector2(13, 0), Vector2(13, -40), Color("7a6448"), 2)
			draw_colored_polygon(PackedVector2Array([Vector2(10, -40), Vector2(16, -40), Vector2(13, -47)]), Color("c9d2d4"))
		"devotee": # Pointed red hood and sun medallion, like the Zealot.
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -34 + bob), Vector2(0, -48 + bob), Vector2(10, -34 + bob)]), coat)
			draw_circle(Vector2(0, -16 + bob), 3.5, Color("f3d075"))

func _draw_role(bob: float) -> void:
	if profile_type in ["fairgoer", "stallholder", "performer", "fan"]:
		_draw_fair_role(bob)
	elif profile_type in ["student", "staff", "academic", "pupil"]:
		_draw_university_role(bob)
	elif profile_type == "guild":
		# A square cap, apron and tool belt identify guild tradespeople.
		draw_rect(Rect2(-10, -41 + bob, 20, 6), Color("#466d75"))
		draw_rect(Rect2(-5, -23 + bob, 10, 15), Color("#d2c39b"))
		draw_line(Vector2(-9, -13), Vector2(10, -13), Color("#6a5136"), 3)
		draw_line(Vector2(12, -25), Vector2(12, -8), Color("#856f4d"), 3)
		draw_line(Vector2(7, -25), Vector2(17, -25), Color("#bcc2b1"), 4)
	elif profile_type == "patron":
		# A broad hat, feather and fan give patrons a richer silhouette.
		draw_rect(Rect2(-14, -40 + bob, 28, 4), Color("#85628f"))
		draw_rect(Rect2(-8, -46 + bob, 16, 8), Color("#a07aae"))
		draw_line(Vector2(6, -44 + bob), Vector2(13, -53 + bob), Color("#f1dfb1"), 3)
		draw_colored_polygon(PackedVector2Array([Vector2(11, -11), Vector2(6, -23), Vector2(19, -23)]), Color("#e3c587"))
	elif role == "Porter" or role == "Courier":
		draw_rect(Rect2(5, -23, 14, 13), Color("#b99361"))
		draw_line(Vector2(12, -23), Vector2(12, -10), Color("#e8d6a4"), 2)
	elif role == "Baker" or role == "Cook":
		draw_rect(Rect2(-6, -22 + bob, 12, 15), Color("#efdeb0"))
		draw_circle(Vector2(0, -41 + bob), 7, Color("#efdeb0"))
	else:
		draw_arc(Vector2(13, -17), 5, PI, TAU, 10, Color("#8f744e"), 2, true)
		draw_rect(Rect2(7, -17, 12, 9), Color("#c9a771"))

## Fair costumes: performers read at a glance; a performing act bobs its props.
func _draw_fair_role(bob: float) -> void:
	var lift: float = sin(phase * 4.0) * 6.0 if performing and not following else 0.0
	match role:
		"Clown", "Clown fan":
			draw_circle(Vector2(0, -27 + bob), 2.6, Color("#d8423c"))
			draw_colored_polygon(PackedVector2Array([Vector2(-7, -36 + bob), Vector2(0, -52 + bob + lift * 0.3), Vector2(7, -36 + bob)]), Color("#e9c34f") if role == "Clown" else Color("#d8423c"))
			for x in [-8, 0, 8]:
				draw_circle(Vector2(x, -21 + bob), 3.4, Color("#f4eee2"))
		"Juggler":
			for index in range(3):
				var angle: float = phase * 3.0 + index * TAU / 3.0
				draw_circle(Vector2(cos(angle) * 10.0, -52 + sin(angle) * 5.0 - absf(lift)), 3.0, [Color("#e05b4f"), Color("#f2c84b"), Color("#5f9bd1")][index])
		"Acrobat":
			draw_line(Vector2(-9, -20 + bob), Vector2(10, -10), Color("#f2c84b"), 3)
			draw_line(Vector2(-12, -34 + bob - absf(lift)), Vector2(-16, -46 + bob - absf(lift)), Color("#eac49a"), 3)
			draw_line(Vector2(12, -34 + bob - absf(lift)), Vector2(16, -46 + bob - absf(lift)), Color("#eac49a"), 3)
		"Stilt-walker":
			draw_line(Vector2(-4, 0), Vector2(-4, 14), Color("#6a5136"), 3)
			draw_line(Vector2(4, 0), Vector2(4, 14), Color("#6a5136"), 3)
			draw_rect(Rect2(-8, -46 + bob, 16, 7), Color("#3c3a4a"))
			draw_rect(Rect2(-5, -56 + bob, 10, 11), Color("#3c3a4a"))
		"Mime watcher":
			draw_line(Vector2(-9, -24 + bob), Vector2(9, -24 + bob), Color("#2f2f36"), 2)
			draw_line(Vector2(-9, -18 + bob), Vector2(9, -18 + bob), Color("#2f2f36"), 2)
		"Busker's fan":
			draw_line(Vector2(10, -20 + bob), Vector2(16, -40 + bob - absf(lift)), Color("#eac49a"), 2)
			draw_circle(Vector2(16, -42 + bob), 2.5, Color("#f2c84b"))
		"Pie seller", "Cider seller":
			draw_rect(Rect2(-6, -22 + bob, 12, 15), Color("#efdeb0"))
			draw_circle(Vector2(12, -14), 5, Color("#c98a4a") if role == "Pie seller" else Color("#c9a63a"))
		"Ring-toss keeper", "Coconut keeper", "Lantern seller":
			draw_rect(Rect2(-10, -40 + bob, 20, 4), Color("#6a4e7a"))
			if role == "Lantern seller":
				draw_line(Vector2(12, -8), Vector2(12, -30), Color("#6a5136"), 2)
				draw_rect(Rect2(8, -38, 8, 9), Color("#f2b84b"))
			else:
				draw_arc(Vector2(13, -16), 5, 0, TAU, 12, Color("#c9a771"), 2, true)
		"Child":
			draw_circle(Vector2(8, -44 + bob), 4, Color("#e05b4f"))
			draw_line(Vector2(8, -40 + bob), Vector2(9, -26), Color("#f4eee2"), 1)
		"Sweetheart":
			draw_circle(Vector2(-6, -37 + bob), 3, Color("#e98aa0"))
		"Farmhand":
			draw_rect(Rect2(-11, -39 + bob, 22, 4), Color("#c9a65a"))
			draw_rect(Rect2(-6, -45 + bob, 12, 7), Color("#c9a65a"))
		_:
			pass

## Quillmoor dress: gowns and mortarboards for academics, short gowns and
## scarves for students, caps for porters; a few props name the trade.
func _draw_university_role(bob: float) -> void:
	match profile_type:
		"academic":
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -23 + bob), Vector2(9, -23 + bob), Vector2(14, -3), Vector2(-13, -3)]), Color("2f2a3a"))
			draw_line(Vector2(-3, -23 + bob), Vector2(-5, -5), coat.lightened(0.2), 3)
			draw_line(Vector2(3, -23 + bob), Vector2(5, -5), coat.lightened(0.2), 3)
			draw_colored_polygon(PackedVector2Array([Vector2(-12, -40 + bob), Vector2(0, -45 + bob), Vector2(12, -40 + bob), Vector2(0, -35 + bob)]), Color("26212e"))
			draw_line(Vector2(9, -40 + bob), Vector2(11, -31 + bob), Color("d9b45a"), 1.5)
		"pupil", "student":
			draw_line(Vector2(-8, -22 + bob), Vector2(8, -22 + bob), Color("7a2f3a") if profile_type == "student" else Color("3c4c78"), 4)
			draw_line(Vector2(6, -22 + bob), Vector2(7, -12 + bob), Color("7a2f3a") if profile_type == "student" else Color("3c4c78"), 3)
			draw_rect(Rect2(9, -18, 9, 11), Color("8a6a43"))
		"staff":
			draw_rect(Rect2(-9, -41 + bob, 18, 6), Color("2f3b2f"))
			draw_rect(Rect2(-11, -37 + bob, 22, 2), Color("2f3b2f"))
	match role:
		"Bookseller":
			for index in range(3):
				draw_rect(Rect2(8, -9 - index * 5, 12, 4), [Color("8a4b3a"), Color("3c5a78"), Color("6b7a3a")][index])
		"Astronomer", "Stargazer":
			draw_line(Vector2(10, -6), Vector2(20, -22), Color("b9a06a"), 3)
		"Alchemist":
			draw_circle(Vector2(14, -12), 4, Color("7fbf8a"))
			draw_line(Vector2(14, -16), Vector2(14, -20), Color("d8e8d0"), 2)
		"Chaplain", "Theologian":
			draw_rect(Rect2(-2, -22 + bob, 4, 10), Color("f2e6c8"))
		"Orator", "Debater", "Debating student":
			draw_line(Vector2(10, -20 + bob), Vector2(17, -33 + bob), Color("eac49a"), 3)
