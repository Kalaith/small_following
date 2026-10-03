extends Node
signal preferences_changed
## Presentation only: never advances speech, movement, currency or progression.
const MUSIC = preload("res://assets/audio/village-score.ogg")
const STEPS: Array[AudioStream] = [
	preload("res://assets/audio/step-1.wav"), preload("res://assets/audio/step-2.wav"),
	preload("res://assets/audio/step-3.wav"), preload("res://assets/audio/step-4.wav"),
]
const MURMURS: Array[AudioStream] = [
	preload("res://assets/audio/murmur-1.wav"), preload("res://assets/audio/murmur-2.wav"),
	preload("res://assets/audio/murmur-3.wav"), preload("res://assets/audio/murmur-4.wav"),
	preload("res://assets/audio/murmur-5.wav"), preload("res://assets/audio/murmur-6.wav"),
]
const MUSIC_DB: float = -15.0
const STEP_DB: float = -9.0
const VOICE_DB: float = -15.0
const STEP_DISTANCE: float = 40.0
const MIN_STEP_SECONDS: float = 0.14
const MIN_VOICE_SECONDS: float = 0.65

var music := AudioStreamPlayer.new()
var footsteps := AudioStreamPlayer.new()
var voice := AudioStreamPlayer.new()
# Godot 4.2's headless Dummy driver retains unconsumed playback instances.
# Keep cue scheduling testable there without creating playback voices.
var output_enabled: bool = DisplayServer.get_name() != "headless"
var muted: bool = false
var voice_muted: bool = false
var volumes: Dictionary = {"master": 1.0, "music": 1.0, "footsteps": 1.0, "speech": 1.0}
var step_distance: float = 0.0
var step_cooldown: float = 0.0
var voice_cooldown: float = 0.0
var step_count: int = 0
var voice_count: int = 0


func _ready() -> void:
	music.name = "Music"
	footsteps.name = "Footsteps"
	voice.name = "Voice"
	for output in [music, footsteps, voice]:
		add_child(output)
		output.max_polyphony = 1
	# Duplicate so the imported shared resource remains unchanged.
	music.stream = MUSIC.duplicate()
	music.stream.loop = true
	_apply_levels()
	_play(music)


func _exit_tree() -> void:
	for output in [music, footsteps, voice]:
		output.stop()
		output.stream = null


func advance_time(delta: float) -> void:
	voice_cooldown = maxf(0.0, voice_cooldown - maxf(delta, 0.0))


func on_motion(distance: float, delta: float) -> void:
	step_cooldown = maxf(0.0, step_cooldown - maxf(delta, 0.0))
	if distance < 0.01:
		step_distance = 0.0
		return
	step_distance += distance
	if step_distance >= STEP_DISTANCE and step_cooldown <= 0.0:
		step_distance = fmod(step_distance, STEP_DISTANCE)
		step_cooldown = MIN_STEP_SECONDS
		if not muted:
			footsteps.stream = STEPS[step_count % STEPS.size()]
			footsteps.pitch_scale = 0.96 if step_count % 2 == 0 else 1.04
			_play(footsteps)
			step_count += 1


func on_phrase() -> void:
	# Drop excess cues; never queue a backlog or speed up the voice recording.
	if muted or voice_muted or voice_cooldown > 0.0:
		return
	voice.stream = MURMURS[voice_count % MURMURS.size()]
	_play(voice)
	voice_count += 1
	voice_cooldown = MIN_VOICE_SECONDS


func stop_speech() -> void:
	voice.stop()


func reset_motion() -> void:
	step_distance = 0.0
	step_cooldown = 0.0
	footsteps.stop()


func toggle_mute() -> void:
	muted = not muted
	_apply_levels()
	if muted:
		footsteps.stop()
		voice.stop()
	preferences_changed.emit()


func toggle_voice() -> void:
	voice_muted = not voice_muted
	_apply_levels()
	if voice_muted:
		voice.stop()
	preferences_changed.emit()


func set_volume(channel: String, value: float) -> void:
	if not volumes.has(channel) or not is_finite(value):
		return
	volumes[channel] = clampf(value, 0.0, 1.0)
	_apply_levels()
	preferences_changed.emit()


func apply_preferences(values: Dictionary) -> void:
	for channel in volumes:
		volumes[channel] = float(values[channel])
	muted = values.muted
	voice_muted = values.voice_muted
	_apply_levels()


func _apply_levels() -> void:
	music.volume_db = _level("music", MUSIC_DB, muted)
	footsteps.volume_db = _level("footsteps", STEP_DB, muted)
	voice.volume_db = _level("speech", VOICE_DB, muted or voice_muted)


func _level(channel: String, base_db: float, silent: bool) -> float:
	var gain: float = volumes.master * volumes[channel]
	return -80.0 if silent or gain <= 0.0 else maxf(-80.0, base_db + linear_to_db(gain))


func _play(output: AudioStreamPlayer) -> void:
	if output_enabled:
		output.play()
