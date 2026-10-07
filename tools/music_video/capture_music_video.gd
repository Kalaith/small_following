extends SceneTree
## Music video takes: real gameplay plus labelled, beat-timed staged scenes.
##
## Renders off-screen in a 1920x1080 SubViewport (the game's 800-unit-tall view,
## widened to 16:9), steps physics at 60 Hz and saves every second step for
## 30 fps. Persistence is disabled before each scene enters the tree, so the
## player's save and preferences are never read or written.
##
## No game script or scene is edited. Staging only sets public properties,
## instantiates the game's own classes (listeners, the helper) and adds
## capture-only props from tools/music_video/mv_set.gd. Real takes assert
## their outcomes; each take writes events.json for the editor.
##
## Usage: Godot --fixed-fps 60 --path . --script res://tools/music_video/capture_music_video.gd
##        -- [--capture-dir=PATH] [--takes=a,b] [--preview]

const STEP: float = 1.0 / 60.0
const BEAT: int = 28            # physics steps per beat (14 video frames at 30 fps)
const BAR: int = 4 * BEAT
const HANDLE: int = 2 * BEAT    # two beats before and after each staged take
const SIZE := Vector2i(1920, 1080)
const GAME_VIEW := Vector2i(1422, 800)
const Gathering = preload("res://scripts/gathering.gd")
const Helper = preload("res://scripts/helper.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Village = preload("res://scripts/village.gd")
const MvSet = preload("res://tools/music_video/mv_set.gd")
const HQ := Vector2(330, 610)
const SQUARE := Vector2(788, 626)
const ORDER: Array[String] = ["hq_wake", "opening", "coins_pie", "ritual_first", "chorus_hq",
	"full_core_dance", "stall_teal", "constellation_tour", "crowd", "crowd_wide", "debate",
	"bellmarket_procession", "bellmarket", "clipboard", "password", "hq_humble", "hq_final", "pullback"]

var destination: String = "res://exports/music_video/capture"
var only: PackedStringArray = []
var preview: bool = false
var view: SubViewport
var scene: Node2D
var camera: Camera2D
var failures: int = 0
var take: String = ""
var take_staged: bool = false
var take_timed: bool = false  # beat-timed with handles (all staged takes, plus timed real UI takes)
var take_events: Array = []
var take_checks: Dictionary = {}
var take_steps: int = 0
var step: int = 0
var saved: int = 0
var song_bars: Dictionary = {}
var rng := RandomNumberGenerator.new()
var recruit_count: int = 0
var route_stop: int = 0
var route_pause: int = 12
var captured: Array[String] = []
var own_camera: bool = false


func _initialize() -> void:
	_run.call_deferred()


# --- scaffolding ----------------------------------------------------------------------

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			destination = argument.trim_prefix("--capture-dir=")
		elif argument.begins_with("--takes="):
			only = argument.trim_prefix("--takes=").split(",", false)
		elif argument == "--preview":
			preview = true
	var song: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/music_video/song.json"))
	for shot in song.shots:
		if shot.has("take"):
			var bars: Array = song_bars.get(shot.take, [999, 0])
			song_bars[shot.take] = [mini(bars[0], int(shot.bars[0])), maxi(bars[1], int(shot.bars[1]))]
	for name in song.takes:
		if not name in ORDER:
			fail("song.json take %s has no capture" % name)
	view = SubViewport.new()
	view.size = SIZE
	view.size_2d_override = GAME_VIEW
	view.size_2d_override_stretch = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	# Mirror the off-screen frames in the window, so the capture is visible while it runs.
	var monitor := TextureRect.new()
	monitor.texture = view.get_texture()
	monitor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monitor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monitor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(monitor)
	DisplayServer.window_set_title("Small Following - music video capture (leave open)")
	DirAccess.make_dir_recursive_absolute(destination)
	for name in ORDER:
		if only.is_empty() or name in only:
			await _take(name)
	print("MUSIC VIDEO CAPTURE COMPLETE: %d takes, %d frames saved, %d failures" % [captured.size(), saved, failures])
	quit(0 if failures == 0 else 1)


func _take(name: String) -> void:
	match name:
		"hq_wake": await take_hq_wake()
		"opening": await take_opening()
		"coins_pie": await take_coins_pie()
		"ritual_first": await take_ritual_first()
		"chorus_hq": await take_chorus_hq()
		"full_core_dance": await take_full_core_dance()
		"stall_teal": await take_stall_teal()
		"constellation_tour": await take_constellation_tour()
		"crowd": await take_crowd(false)
		"crowd_wide": await take_crowd(true)
		"debate": await take_debate()
		"bellmarket_procession": await take_procession()
		"bellmarket": await take_bellmarket()
		"clipboard": await take_clipboard()
		"password": await take_password()
		"hq_humble": await take_hq_humble()
		"hq_final": await take_hq_final()
		"pullback": await take_pullback()


func fail(message: String) -> void:
	failures += 1
	push_error("MUSIC VIDEO CAPTURE: " + message)


func check(condition: bool, description: String) -> void:
	take_checks[description] = condition
	if not condition:
		fail("%s: %s" % [take, description])


func setup(purchases: int = 0) -> void:
	## A fresh game scene; purchases > 0 buys that many catalog nodes, -1 the whole circle.
	if is_instance_valid(scene):
		view.remove_child(scene)
		scene.queue_free()
	scene = load("res://scenes/main.tscn").instantiate()
	scene.persistence_enabled = false
	view.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	if not scene.game_audio.muted:
		scene.game_audio.toggle_mute()
	if purchases != 0:
		var count: int = scene.progression.catalog.size() if purchases < 0 else purchases
		scene.round_active = false
		scene.progression.coins = 1000000
		scene.progression.total_recruits = 1000000  # a save may never spend more recruits than it earned
		scene.progression.available_recruits = 1000000
		# Buy in passes, so nodes whose prerequisites come later in the catalog still land.
		var wanted: Array = scene.progression.catalog.slice(0, count)
		for attempt in range(wanted.size() + 1):
			var progress: bool = false
			for item in wanted:
				while scene.progression.rank(item.id) < scene.progression.max_rank(item.id):
					if not scene.purchase_upgrade(item.id, scene.progression.rank(item.id)):
						break
					progress = true
			if not progress:
				break
		for item in wanted:
			if scene.progression.rank(item.id) < scene.progression.max_rank(item.id):
				fail("%s: setup could not buy %s: %s" % [take, item.id, scene.progression.last_error])
		# Funded build setup is cut away; each visible take starts with nothing in hand.
		scene.progression.coins = 0
		scene.progression.available_recruits = 0
		scene.progression.total_recruits = 0
		scene.start_next_round()
	# Staged scenes pose their own helpers; the game's idle one would stand around "resting".
	if take_staged and is_instance_valid(scene.helper):
		scene.helper.hide()
	camera = Camera2D.new()
	scene.add_child(camera)
	own_camera = false
	rng.seed = hash(take)
	recruit_count = 0
	route_stop = 0
	route_pause = 12
	await physics_frame
	await physics_frame


func begin(name: String, steps: int, staged: bool, timed: bool = staged) -> void:
	take = name
	take_staged = staged
	take_timed = timed
	take_steps = steps
	take_events = []
	take_checks = {}
	DirAccess.make_dir_recursive_absolute(destination.path_join(name))


func staged_steps(name: String, extra_bars: int = 0) -> int:
	var bars: Array = song_bars[name]
	return HANDLE * 2 + (bars[1] - bars[0] + 1 + extra_bars) * BAR


func beat_of(s: int) -> float:
	## Beats since the take's first musical bar (negative in the opening handle).
	return float(s - HANDLE) / BEAT


func on_beat(s: int, b: float) -> bool:
	return s == HANDLE + int(round(b * BEAT))


func mark(name: String) -> void:
	take_events.append({"name": name, "frame": step / 2})


func finish_step(s: int, keep_ritual: bool = false) -> void:
	step = s
	if s % 2 == 0:
		return
	if own_camera and not camera.is_current():
		camera.make_current()
	scene.hud_layout.hide()
	scene.settings_button.hide()
	if not keep_ritual:
		scene.ritual_screen.hide()
	var frame: int = s / 2
	await RenderingServer.frame_post_draw
	if preview and frame % 8 != 0:
		return
	var image: Image = view.get_texture().get_image()
	if image.get_size() != SIZE:
		fail("%s frame %d is %s" % [take, frame, image.get_size()])
	if image.save_png(destination.path_join(take).path_join("%05d.png" % frame)) != OK:
		fail("%s frame %d could not be saved" % [take, frame])
	saved += 1


func end() -> void:
	var bars: Array = song_bars.get(take, [0, 0])
	var record := {
		"take": take, "frames": take_steps / 2, "fps": 30, "size": [SIZE.x, SIZE.y],
		"staged": take_staged, "first_bar": bars[0], "last_bar": bars[1],
		"timed": take_timed, "handle_frames": HANDLE / 2 if take_timed else 0,
		"events": take_events, "checks": take_checks, "preview": preview,
	}
	var file := FileAccess.open(destination.path_join(take).path_join("events.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(record, "  "))
	file.close()
	captured.append(take)
	var passed: int = take_checks.values().count(true)
	print("TAKE %s: %d frames, %d events, checks %d/%d" % [take, take_steps / 2, take_events.size(), passed, take_checks.size()])


# --- staging helpers -------------------------------------------------------------------

func actors() -> Node2D:
	return scene.get_node("Actors")


func prop(kind: String, at: Vector2, options: Dictionary = {}) -> Node2D:
	var node: Node2D = MvSet.new()
	node.kind = kind
	node.position = at
	for key in options:
		node.set(key, options[key])
	actors().add_child(node)
	return node


func person(at: Vector2, following: bool = true, coat: Color = Color("#9c695a")) -> Node2D:
	var listener = Gathering.Listener.new()
	listener.position = at
	listener.following = following
	listener.coat = coat
	listener.phase = rng.randf() * TAU
	actors().add_child(listener)
	return listener


func gerald(at: Vector2) -> Node2D:
	var him: Node2D = person(at, false, Color("#9c695a"))
	var pie: Node2D = MvSet.new()
	pie.kind = "pie"
	pie.name = "Pie"
	pie.position = Vector2(14, -6)
	him.add_child(pie)
	var tag: Node2D = MvSet.new()
	tag.kind = "nametag"
	tag.text = "Gerald"
	tag.position = Vector2(0, -58)
	him.add_child(tag)
	return him


func teal(at: Vector2) -> Node2D:
	## The game's own teal helper, posed for a staged scene (it does not recruit here).
	var helper = Helper.new()
	actors().add_child(helper)
	helper.active = true
	helper.position = at
	return helper


func bearers(count: int = 4) -> Array:
	var people: Array = []
	for i in range(count):
		people.append(person(Vector2(-1000, -1000)))
	return people


func carry(burden: Node2D, team: Array, at: Vector2, raised: float) -> void:
	## Staged: followers lift a statue onto their shoulders (raised 0..1) and carry it.
	burden.position = at
	burden.lift = 34.0 * clampf(raised, 0.0, 1.0)
	burden.carried = true
	burden.queue_redraw()
	for i in range(team.size()):
		var side: float = -30.0 if i % 2 == 0 else 30.0
		var row: float = -10.0 if i < 2 else 12.0
		team[i].position = at + Vector2(side, row)


func look(at: Vector2, zoom: float) -> void:
	## A staged camera, kept inside the map so no frame shows the void past its edge.
	var half: Vector2 = Vector2(GAME_VIEW) / (2.0 * zoom)
	var world: Vector2 = Village.WORLD_SIZE
	at.x = world.x * 0.5 if half.x * 2.0 >= world.x else clampf(at.x, half.x, world.x - half.x)
	at.y = world.y * 0.5 if half.y * 2.0 >= world.y else clampf(at.y, half.y, world.y - half.y)
	camera.position = at
	camera.zoom = Vector2(zoom, zoom)
	camera.make_current()
	own_camera = true


func follow_player() -> void:
	own_camera = false
	scene.player.get_node("Camera2D").make_current()


func smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func idle() -> void:
	scene.player.step_motion(Vector2.ZERO, STEP)


func walk_toward(target: Vector2, stop: float = 4.0) -> void:
	var player = scene.player
	var direction := Vector2.ZERO
	if player.position.distance_to(target) > stop:
		direction = player.position.direction_to(target)
	player.step_motion(direction, STEP)


func sway(people: Array, s: int, amount: float = 0.07) -> void:
	## Staged: followers rock on the beat.
	var angle: float = amount * sin(PI * beat_of(s))
	for i in range(people.size()):
		people[i].rotation = angle if i % 2 == 0 else -angle


func build_hq(final: bool) -> Dictionary:
	## The folding-table HQ on the grass west of the square; `final` is the not-humble one.
	var set := {}
	if final:
		prop("rug", HQ + Vector2(0, -10), {"size_scale": 1.6})
		prop("banner", HQ + Vector2(0, -96), {"text": "SMALL FOLLOWING", "tint": MvSet.LILAC_DARK})
		for x in [-230.0, -150.0, 150.0, 230.0]:
			prop("flag", HQ + Vector2(x, -70), {"tint": MvSet.GOLD if int(x) % 3 == 0 else MvSet.LILAC})
		for x in [-150.0, 150.0]:
			prop("table", HQ + Vector2(x, 30), {"tint": MvSet.WOOD_LIGHT})
			prop("candle", HQ + Vector2(x - 20, 31), {"lift": 46.0})
			prop("candle", HQ + Vector2(x + 24, 31), {"lift": 46.0})
		for i in range(8):
			prop("chair", HQ + Vector2(-260 + i * 74, 70), {"tint": [Color("7c88aa"), Color("b89c58"), Color("be8066")][i % 3]})
		prop("robe_rack", HQ + Vector2(-250, -30))
		set["tin"] = prop("tin", HQ + Vector2(250, 10), {"size_scale": 3.4, "tint": Color("b8423f"), "count": 9, "text": "BISCUITS"})
	set["table"] = prop("table", HQ, {"tint": MvSet.WOOD_LIGHT})
	set["candle"] = prop("candle", HQ + Vector2(-34, 1), {"lift": 46.0})
	if not final:
		set["tin"] = prop("tin", HQ + Vector2(32, 1), {"lift": 46.0, "tint": Color("b8423f"), "count": -1})
	prop("sign", HQ + Vector2(-100, -4), {"text": "CULT HQ", "tint": MvSet.WOOD})
	prop("robe_hook", HQ + Vector2(100, -14))
	prop("chair", HQ + Vector2(0, -27), {"tint": Color("7c88aa")})
	prop("chair", HQ + Vector2(-56, -18), {"tint": Color("b89c58")})
	prop("chair", HQ + Vector2(70, 22), {"tint": Color("be8066")})
	return set


func seat_cultist() -> void:
	scene.player.position = HQ + Vector2(0, -24)
	scene.player.rotation = 0.0


func avoid(at: Vector2, clearings: Array) -> bool:
	for entry in Village.PROP_LAYOUT:
		var anchor: Vector2 = entry["at"]
		var radius: float = {"house": 150.0, "tree": 80.0, "well": 105.0, "market": 110.0, "bench": 55.0, "flowers": 0.0}[entry["kind"]]
		var centre: Vector2 = anchor + (Vector2(0, -60) if entry["kind"] == "house" else Vector2.ZERO)
		if at.distance_to(centre) < radius:
			return true
	for group in scene.groups:
		if at.distance_to(group.position) < 75.0:
			return true
	for clearing in clearings:  # [centre, radii]
		var d: Vector2 = (at - clearing[0]) / clearing[1]
		if d.length() < 1.0:
			return true
	return false


func crowd(region: Rect2, spacing: Vector2, clearings: Array) -> Array:
	## Staged: hundreds of lilac followers on a jittered grid (never counted as recruits).
	var people: Array = []
	var y: float = region.position.y
	while y < region.end.y:
		var x: float = region.position.x + (spacing.x * 0.5 if int(y / spacing.y) % 2 == 0 else 0.0)
		while x < region.end.x:
			var at := Vector2(x + rng.randf_range(-7, 7), y + rng.randf_range(-6, 6))
			if not avoid(at, clearings):
				people.append(person(at))
			x += spacing.x
		y += spacing.y
	return people


func watch_recruits() -> void:
	for group in scene.groups:
		group.recruited.connect(_on_recruited)


func _on_recruited(_donation: int) -> void:
	recruit_count += 1
	mark("recruit")
	mark("recruit_%d" % recruit_count)
	if recruit_count == 3:
		mark("third_recruit")


func drive_route(order: Array, boss: bool = false) -> void:
	## The promo's real route: walk to each gathering until it is fully persuaded.
	var target: Vector2 = Encounter.CENTER
	if not boss:
		var group = scene.groups[order[route_stop]]
		if group.first_unconverted() < 0 and route_stop + 1 < order.size():
			route_stop += 1
			group = scene.groups[order[route_stop]]
			route_pause = 6
		target = group.position
	var direction := Vector2.ZERO
	if route_pause > 0:
		route_pause -= 1
	elif scene.player.position.distance_to(target) > (85.0 if boss else 95.0):
		direction = scene.player.position.direction_to(target)
	scene.player.step_motion(direction, STEP)
	scene.advance_round(STEP)


func play_round_offscreen(order: Array) -> void:
	## A real round played without saving frames (setup that the video cuts away).
	for s in range(int(Village.WORLD_SIZE.x)):  # comfortably more than 11 s of steps
		await physics_frame
		if not scene.round_active:
			return
		drive_route(order)


func travel_to_bellmarket() -> void:
	## The real unlock: a completed Bramblewick circle opens travel.
	await setup(-1)
	scene.round_active = false
	check(scene.progression.is_area_unlocked("bellmarket"), "completed Bramblewick circle unlocks Bellmarket")
	check(scene.travel_to("bellmarket"), "travel to Bellmarket succeeds")
	check(scene.groups.size() == 5, "Bellmarket has its five districts")
	if take_staged and is_instance_valid(scene.helper):
		scene.helper.hide()  # travel builds a fresh idle helper; staged scenes pose their own
	await physics_frame


# --- real gameplay takes -------------------------------------------------------------------

func take_opening() -> void:
	begin("opening", (11 * 60) + 150, false)
	await setup()
	watch_recruits()
	follow_player()
	for s in range(take_steps):
		await physics_frame
		step = s
		if scene.round_active:
			drive_route([2])
		else:
			idle()
		await finish_step(s)
	check(scene.round_recruits == 3, "opening round earns 3 recruits")
	check(scene.coins == 9, "opening round earns 9 donations")
	end()


func take_full_core_dance() -> void:
	## A real expanded round with the helper unlocked; the camera keeps both in frame.
	begin("full_core_dance", (11 * 60) + 120, false)
	await setup(16)
	watch_recruits()
	var helper = scene.helper
	check(is_instance_valid(helper), "the helper is unlocked for this round")
	var helped: int = 0
	var frame_at: Vector2 = scene.player.position
	var frame_zoom: float = 1.0
	for s in range(take_steps):
		await physics_frame
		step = s
		if scene.round_active:
			drive_route([3, 0, 1, 4, 2])
		else:
			idle()
		if is_instance_valid(helper):
			if helper.completed_recruits > helped:
				helped = helper.completed_recruits
				mark("helper_recruit")
			var span: Vector2 = (scene.player.position - helper.position).abs()
			var want: float = clampf(minf(1422.0 / (span.x + 520.0), 800.0 / (span.y + 380.0)), 0.92, 1.3)
			frame_at = frame_at.lerp((scene.player.position + helper.position) * 0.5 + Vector2(0, -20), 0.06)
			frame_zoom = lerpf(frame_zoom, want, 0.04)
			look(frame_at, frame_zoom)
		await finish_step(s)
	check(helped >= 1, "the helper really recruits")
	check(scene.round_recruits >= 15, "the expanded round recruits at least 15")
	end()


func take_ritual_first() -> void:
	begin("ritual_first", staged_steps("ritual_first"), false, true)
	await setup()
	await play_round_offscreen([2])
	check(scene.coins == 9, "the real opening donations are in hand")
	scene.ritual_screen.clear_selection()
	scene.ritual_screen.reset_view()
	for s in range(take_steps):
		await physics_frame
		step = s
		idle()
		if on_beat(s, 1.0):
			scene.ritual_screen.select_node("talk_1")
		if on_beat(s, 8.0):  # bar 15: "Talking One, inscribed"
			scene.ritual_screen.purchase_button.pressed.emit()
			if scene.progression.rank("talk_1") == 1:
				mark("purchase")
		if on_beat(s, 10.0):
			scene.ritual_screen.focus_node("talk_1")
		if on_beat(s, 14.0):
			scene.ritual_screen.reset_view()
		await finish_step(s, true)
	check(scene.progression.rank("talk_1") == 1, "first talking rank (Quickened Words I) bought with real donations")
	end()


func take_constellation_tour() -> void:
	begin("constellation_tour", staged_steps("constellation_tour"), false, true)
	await setup(32)
	scene.round_active = false
	scene.set_ritual_visible(true)
	scene.ritual_screen.clear_selection()
	scene.ritual_screen.reset_view()
	var ranks: int = 0
	for item in scene.progression.catalog.slice(0, 32):
		ranks += 1 if scene.progression.rank(item.id) > 0 else 0
	check(ranks == 32, "the circle really has 32 inscribed nodes")
	var start_zoom: float = scene.ritual_screen.zoom
	for s in range(take_steps):
		await physics_frame
		step = s
		idle()
		# A slow push into the real circle (the ritual screen's own zoom).
		scene.ritual_screen.zoom = start_zoom * (1.0 + 0.35 * smooth(float(s) / take_steps))
		scene.ritual_screen.graph.queue_redraw()
		await finish_step(s, true)
	end()


func take_debate() -> void:
	## Real Priest encounter (3 objections, 240 conviction) on a staged set.
	var pre: int = 270
	begin("debate", pre + 11 * 60 + 90, false)
	await setup(32)
	scene.round_active = false
	prop("lectern", Vector2(720, 668))
	prop("bell", Vector2(905, 520))
	var him: Node2D = gerald(Vector2(625, 610))
	var dim := CanvasModulate.new()
	dim.color = Color(0.78, 0.72, 0.86)
	scene.add_child(dim)
	look(Vector2(800, 600), 1.45)
	var rebuttals: int = -1
	for s in range(take_steps):
		await physics_frame
		step = s
		if s == pre:
			scene.progression.encounter_stage = 3
			scene.start_next_round()
			scene.encounter.convinced.connect(func(_stage: int) -> void: mark("priest_convinced"))
			rebuttals = scene.encounter.rebuttals_left
			mark("round_start")
		if s >= pre and scene.round_active:
			drive_route([], true)
			if is_instance_valid(scene.encounter) and scene.encounter.rebuttals_left < rebuttals:
				rebuttals = scene.encounter.rebuttals_left
				mark("objection")
		else:
			idle()
		him.rotation = 0.0
		await finish_step(s)
	check(scene.progression.map_complete(), "the Priest is really convinced")
	end()


func take_bellmarket() -> void:
	begin("bellmarket", 7 * 60, false)
	await travel_to_bellmarket()
	scene.start_next_round()
	watch_recruits()
	follow_player()
	for s in range(take_steps):
		await physics_frame
		step = s
		if scene.round_active:
			drive_route([0, 3])
		else:
			idle()
		await finish_step(s)
	check(scene.progression.active_area == "bellmarket", "the take is in Bellmarket")
	end()


func take_password() -> void:
	## The real title screen and seal; the field is unmasked (staged) so letters read.
	begin("password", staged_steps("password", 1), true)
	await setup()
	scene.show_title()
	var title = scene.title_screen
	var field: LineEdit = title.password_input
	field.secret = false
	var wrong: String = "SKTKZLP"   # the note, held upside down
	var right: String = "PLZKTKS"
	for s in range(take_steps):
		await physics_frame
		step = s
		for k in range(wrong.length()):
			if on_beat(s, 1.0 + k):
				field.text = wrong.substr(0, k + 1)
				field.caret_column = k + 1
		if on_beat(s, 8.0):  # bar 63: the real seal error
			field.text_submitted.emit(field.text)
			mark("wrong_password")
			check(not title.unlocked, "the upside-down entry does not open the seal")
		if on_beat(s, 14.0):  # bar 64, beat 3: "Not that one."
			field.clear()
		for k in range(right.length()):
			if on_beat(s, 16.0 + k):  # bars 65-66: one letter per shouted beat
				field.text = right.substr(0, k + 1)
				field.caret_column = k + 1
				mark("letter_%s" % right[k])
		if on_beat(s, 28.0):  # bar 68: the real seal opens
			field.text_submitted.emit(field.text)
			mark("seal_open")
			check(title.unlocked, "PLZKTKS opens the seal")
		if on_beat(s, 31.0):
			title.level_two_button.pressed.emit()
			mark("travel")
		await finish_step(s)
	check(scene.progression.active_area == "bellmarket" and not scene.title_active, "level 2 travels to Bellmarket")
	end()


# --- staged takes ----------------------------------------------------------------------------

func take_hq_wake() -> void:
	begin("hq_wake", staged_steps("hq_wake"), true)
	await setup()
	build_hq(false)
	seat_cultist()
	var player = scene.player
	player.rotation = 0.55   # face down on the desk
	var zzz: Node2D = prop("zzz", HQ + Vector2(18, -60))
	look(HQ + Vector2(0, -48), 2.2)
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		if on_beat(s, 8.0):  # bar 3: awake, the countdown starts
			player.rotation = 0.0
			zzz.hide()
			mark("wake")
		if b >= 8.0 and b < 8.25:
			player.position.y = HQ.y - 24 - 9.0 * sin(PI * (b - 8.0) / 0.25)
		if b >= 9.0 and b < 15.5:
			var jitter: float = 1.0 if int(b * 2.0) % 2 == 0 else -1.0
			player.step_motion(Vector2(jitter * 0.12, 0), STEP)  # panicked fidgets
		elif b >= 16.0:  # bar 5: rush outside
			if on_beat(s, 16.0):
				mark("rush")
			player.step_motion(Vector2(1, 0.15).normalized(), STEP)
		else:
			idle()
		await finish_step(s)
	end()


func take_coins_pie() -> void:
	begin("coins_pie", staged_steps("coins_pie"), true)
	await setup()
	build_hq(false)
	seat_cultist()
	var bowl: Node2D = prop("bowl", HQ + Vector2(0, 2), {"lift": 46.0})
	var coin: Node2D = prop("coin", HQ + Vector2(0, 3), {"lift": 130.0})
	coin.hide()
	var him: Node2D = gerald(HQ + Vector2(190, 12))
	var table_pie: Node2D = prop("pie", HQ + Vector2(40, 2), {"lift": 46.0})
	table_pie.hide()
	look(HQ + Vector2(30, -48), 2.2)
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		# Bars 9-10: the nine real opening donations drop into the bowl.
		for k in range(9):
			var drop: float = 8.0 * k / 9.0
			if b >= drop and b < drop + 0.4:
				coin.show()
				coin.lift = lerpf(130.0, 52.0, (b - drop) / 0.4)
			if on_beat(s, drop + 0.4):
				coin.hide()
				bowl.count = k + 1
				bowl.queue_redraw()
		if b >= 4.0 and b < 8.0:  # counted twice
			scene.player.rotation = 0.12 * sin(PI * (b - 4.0))
		else:
			scene.player.rotation = 0.0
		# Bars 11-12: Gerald brings a pie.
		if b >= 8.0 and b < 10.0:
			him.position = (HQ + Vector2(190, 12)).lerp(HQ + Vector2(70, 10), smooth((b - 8.0) / 2.0))
		if on_beat(s, 10.5):
			him.get_node("Pie").hide()
			table_pie.show()
			mark("pie_down")
		idle()
		await finish_step(s)
	check(bowl.count == 9, "nine coins, as the opening round really pays")
	end()


func take_chorus_hq() -> void:
	begin("chorus_hq", staged_steps("chorus_hq"), true)
	await setup()
	var set: Dictionary = build_hq(false)
	set["tin"].count = 1   # one biscuit left
	prop("fire", HQ + Vector2(-20, -78))
	seat_cultist()
	var people: Array = [person(HQ + Vector2(-66, -12)), person(HQ + Vector2(64, -10)), teal(HQ + Vector2(-8, 42))]
	look(HQ + Vector2(0, -40), 2.2)
	for s in range(take_steps):
		await physics_frame
		step = s
		sway(people, s)
		idle()
		await finish_step(s)
	end()


func take_stall_teal() -> void:
	begin("stall_teal", staged_steps("stall_teal"), true)
	await setup()
	var stall := Vector2(1135, 725)
	scene.player.position = stall + Vector2(0, 52)
	var people: Array = []
	for i in range(6):
		people.append(person(stall + Vector2(-110 + i * 44, 92)))
	for i in range(5):
		people.append(person(stall + Vector2(-88 + i * 44, 126)))
	var helper = Helper.new()
	actors().add_child(helper)
	helper.active = true
	var formation: Vector2 = stall + Vector2(132, 126)
	helper.position = formation
	var spot: Vector2 = stall + Vector2(0, 168)
	var cone: Node2D = prop("cone", spot + Vector2(0, 4))
	cone.hide()
	look(stall + Vector2(0, 60), 1.55)
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		if b < 12.0:
			sway(people, s, 0.04)
		if on_beat(s, 12.0):  # bar 28: the teal helper steps into the spotlight
			cone.show()
			mark("teal_step_forward")
		if b >= 12.0 and b < 16.0:
			var t: float = smooth((b - 12.0) / 0.4)
			helper.position = formation.lerp(spot, t) + Vector2(0, -7.0 * absf(sin(TAU * b)))
			helper.rotation = 0.0
		if on_beat(s, 16.0):  # bar 29, "That's enough": back in formation, slumped
			cone.hide()
			helper.position = formation + Vector2(0, 5)
			helper.rotation = 0.42
			mark("teal_slump")
		helper.queue_redraw()
		idle()
		await finish_step(s)
	end()


func take_crowd(wide: bool) -> void:
	var name: String = "crowd_wide" if wide else "crowd"
	begin(name, staged_steps(name), true)
	await setup()
	rng.seed = hash("crowd")  # the same crowd in the tight and wide takes, across the smash cut
	scene.player.position = SQUARE + Vector2(0, 40)
	prop("banner", SQUARE + Vector2(0, -24), {"text": "NOTHING ALARMING", "tint": MvSet.LILAC_DARK})
	prop("robe_rack", SQUARE + Vector2(-120, 12))
	prop("robe_rack", SQUARE + Vector2(120, 12))
	var tables: Array = []
	for i in range(14):
		var at := Vector2(rng.randf_range(120, 1440), rng.randf_range(380, 1020))
		if not avoid(at, [[SQUARE + Vector2(0, 10), Vector2(330, 190)]]):
			tables.append(at)
			prop("table", at, {"tint": MvSet.WOOD_LIGHT})
	var clearings: Array = [[SQUARE + Vector2(0, 10), Vector2(320, 185)]]
	for at in tables:
		clearings.append([at, Vector2(70, 34)])
	var people: Array = crowd(Rect2(60, 330, 1440, 740), Vector2(38, 32), clearings)
	for i in range(4):  # the few people the tight shot admits to
		people.append(person(SQUARE + Vector2(-70 + i * 46, 96)))
	gerald(SQUARE + Vector2(190, 130))
	people.append(teal(SQUARE + Vector2(52, 46)))
	print("  crowd: %d staged followers, %d tables" % [people.size(), tables.size()])
	if wide:
		look(SQUARE + Vector2(0, -6), 0.95)
	else:
		look(SQUARE + Vector2(0, 0), 2.4)
	for s in range(take_steps):
		await physics_frame
		step = s
		sway(people, s, 0.05)
		idle()
		await finish_step(s)
	end()


func take_procession() -> void:
	begin("bellmarket_procession", staged_steps("bellmarket_procession"), true)
	await travel_to_bellmarket()
	scene.round_active = false
	var lane: float = 690.0
	var marchers: Array = []
	for i in range(18):
		marchers.append(person(Vector2(lane + (-22 if i % 2 == 0 else 22), 1180 + (i / 2) * 40)))
	var statue: Node2D = prop("statue", Vector2(lane, 1180 + 9 * 40 + 30))
	var team: Array = bearers()
	var helper: Node2D = teal(Vector2(lane + 48, 1100))
	scene.player.position = Vector2(lane, 1120)
	for s in range(take_steps):
		await physics_frame
		step = s
		var t: float = clampf(beat_of(s) / 16.0, 0.0, 1.0)
		var lead_y: float = lerpf(1060.0, 600.0, t)
		scene.player.position = Vector2(lane, lead_y)
		scene.player.step_motion(Vector2(0, -0.0001), STEP)
		for i in range(marchers.size()):
			marchers[i].position = Vector2(lane + (-22 if i % 2 == 0 else 22), lead_y + 60 + (i / 2) * 40)
		var raised: float = smooth(beat_of(s) / 2.0)  # they lift it up as the bar begins
		if on_beat(s, 0.0):
			mark("statue_lifted")
		carry(statue, team, Vector2(lane, lead_y + 60 + 9 * 40 + 34), raised)
		helper.position = Vector2(lane + 50, lead_y + 30)
		look(Vector2(lane + 60, lead_y + 130), 1.1)
		await finish_step(s)
	end()


func take_clipboard() -> void:
	begin("clipboard", staged_steps("clipboard"), true)
	await travel_to_bellmarket()
	scene.round_active = false
	var at := Vector2(700, 620)
	scene.player.position = at + Vector2(-52, -6)
	var counter: Node2D = person(at)
	var board: Node2D = MvSet.new()
	board.kind = "clipboard"
	board.position = Vector2(14, -3)
	board.size_scale = 0.6
	counter.add_child(board)
	look(at + Vector2(-14, -34), 3.0)
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		if b >= 0.0 and b < 4.0:
			board.count = 6 + int(b * 4.0)   # tallying while the lyric insists it is not many
			board.queue_redraw()
		if on_beat(s, 4.0):  # bar 60, "stop counting": face-down
			board.flipped = true
			board.queue_redraw()
			mark("flip")
		idle()
		await finish_step(s)
	end()


func take_hq_humble() -> void:
	begin("hq_humble", staged_steps("hq_humble"), true)
	await setup()
	build_hq(false)
	seat_cultist()
	var chair := HQ + Vector2(70, 24)
	teal(HQ + Vector2(-56, -14))
	var him: Node2D = gerald(HQ + Vector2(200, 16))
	var table_pie: Node2D = prop("pie", HQ + Vector2(40, 2), {"lift": 46.0})
	table_pie.hide()
	look(HQ + Vector2(30, -46), 2.2)
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		if b >= 0.0 and b < 3.0:
			him.position = (HQ + Vector2(200, 16)).lerp(chair, smooth(b / 3.0))
		if on_beat(s, 3.0):  # Gerald sits down; the pie stays untouched
			him.position = chair + Vector2(0, 2)
			him.scale = Vector2(1.0, 0.92)
			him.get_node("Pie").hide()
			table_pie.show()
			mark("gerald_sits")
		idle()
		await finish_step(s)
	end()


func take_hq_final() -> void:
	begin("hq_final", staged_steps("hq_final"), true)
	await setup()
	var set: Dictionary = build_hq(true)
	seat_cultist()
	var people: Array = []
	for i in range(8):
		people.append(person(HQ + Vector2(-260 + i * 74, 74)))
	for x in [-190.0, -110.0, 110.0, 190.0]:
		people.append(person(HQ + Vector2(x, 0)))
	var idol: Node2D = prop("idol", HQ + Vector2(-330, 110))
	var team: Array = bearers()
	var helper: Node2D = teal(HQ + Vector2(-380, 112))
	carry(idol, team, HQ + Vector2(-330, 110), 1.0)
	var tin: Node2D = set["tin"]
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		sway(people, s, 0.05)
		if b >= 4.0 and b < 14.0:  # the golden idol squeezes past
			if on_beat(s, 4.0):
				mark("idol_pass")
			var at: Vector2 = (HQ + Vector2(-330, 110)).lerp(HQ + Vector2(330, 110), (b - 4.0) / 10.0)
			carry(idol, team, at, 1.0)
			helper.position = at + Vector2(-62, 4)
		var to_tin: float = smooth((b - 23.5) / 1.0)  # bars 91-92: the industrial biscuit tin
		if on_beat(s, 24.0):
			mark("tin")
		var wide := HQ + Vector2(0, -36)
		var close: Vector2 = tin.position + Vector2(-30, -60)
		look(wide.lerp(close, to_tin), lerpf(1.45, 2.6, to_tin))
		idle()
		await finish_step(s)
	end()


func take_pullback() -> void:
	begin("pullback", staged_steps("pullback"), true)
	await setup()
	build_hq(true)
	seat_cultist()
	# Keep the square's south road clear where the closing column forms up.
	var clearings: Array = [[HQ + Vector2(0, 10), Vector2(330, 130)], [Vector2(805, 800), Vector2(70, 290)]]
	var people: Array = crowd(Rect2(60, 330, 1440, 740), Vector2(36, 30), clearings)
	for i in range(8):
		people.append(person(HQ + Vector2(-260 + i * 74, 74)))
	print("  pullback: %d staged followers" % people.size())
	# Bars 93-95: a column leaves north along the village road.
	var column: Array = []
	# Around the east side of the village well (780, 400), never through it.
	var road: Array[Vector2] = [Vector2(805, 580), Vector2(915, 480), Vector2(920, 300), Vector2(855, 120), Vector2(840, -140)]
	for i in range(30):
		column.append(person(_along(road, -(30 + (i / 2) * 26)) + Vector2(-16 if i % 2 == 0 else 16, 0)))
	var statue: Node2D = prop("statue", _along(road, -(30 + 15 * 26 + 40)))
	var team: Array = bearers()
	carry(statue, team, statue.position, 0.0)
	var helpers: Array = [teal(_along(road, -6) + Vector2(-14, 0)), teal(_along(road, -6) + Vector2(14, 0))]
	for s in range(take_steps):
		await physics_frame
		step = s
		var b: float = beat_of(s)
		sway(people, s, 0.05)
		var t: float = smooth(b / 8.0)  # bars 89-90: pull back from the table to the square
		look((HQ + Vector2(0, -40)).lerp(Vector2(780, 560), t), lerpf(2.4, 0.95, t))
		if b >= 16.0:
			if on_beat(s, 16.0):
				mark("procession")
			# They lift the statue onto their shoulders over the first beat, then walk.
			var raised: float = smooth(b - 16.0)
			var travelled: float = maxf(0.0, b - 17.0) * 36.0
			for i in range(column.size()):
				var offset: float = travelled - (30 + (i / 2) * 26)
				column[i].position = _along(road, offset) + Vector2(-16 if i % 2 == 0 else 16, 0)
			carry(statue, team, _along(road, travelled - (30 + 15 * 26 + 40)), raised)
			helpers[0].position = _along(road, travelled - 6) + Vector2(-14, 0)
			helpers[1].position = _along(road, travelled - 6) + Vector2(14, 0)
		idle()
		await finish_step(s)
	end()


func _along(path: Array[Vector2], distance: float) -> Vector2:
	## A point `distance` along a polyline (negative = behind its start).
	if distance <= 0.0:
		return path[0] + (path[0] - path[1]).normalized() * -distance
	for i in range(path.size() - 1):
		var length: float = path[i].distance_to(path[i + 1])
		if distance <= length:
			return path[i].lerp(path[i + 1], distance / length)
		distance -= length
	return path[-1]
