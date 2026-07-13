## Leg Curl — trains Hamstrings.
##
## Rhythm minigame: the beat bar fills once per metronome beat; press E/Space
## right as it tops out (small window either side of the beat). On-beat curls
## build a combo and speed the metronome up, missing the timing resets it.
extends BaseExercise

@onready var beat_bar: ProgressBar = %BeatBar
@onready var character: AnimatedSprite2D = %Character
@onready var rep_label: Label = %RepLabel
@onready var combo_label: Label = %ComboLabel
@onready var message_label: Label = %MessageLabel

var reps := 0
var combo := 0
## Seconds since the last beat.
var phase := 0.0

var _cfg: LegCurlConfig
var _character_rest_y := 0.0


func _ready() -> void:
	super()
	_cfg = config as LegCurlConfig
	beat_bar.max_value = 1.0
	_build_hit_window_overlay()
	_character_rest_y = character.position.y
	message_label.text = "Curl on the beat — press E / SPACE as the bar fills!"
	_update_labels()


func _process(delta: float) -> void:
	if exhausted:
		return
	var period := _beat_period()
	phase += delta
	if phase >= period:
		phase -= period
		AudioManager.play(&"click", -18.0)  # soft metronome tick
	beat_bar.value = phase / period
	if Input.is_action_just_pressed("interaction") \
			or Input.is_action_just_pressed("ui_accept"):
		_attempt_curl(period)


## Green limit zones on the beat bar showing exactly where a press counts:
## the strip before the bar tops out and the carry-over right after the beat.
func _build_hit_window_overlay() -> void:
	var window_px := beat_bar.size.x * _cfg.timing_window
	for x in [beat_bar.size.x - window_px, 0.0]:
		var strip := ColorRect.new()
		strip.color = Color(0.0, 0.75, 0.3, 0.45)
		strip.position = Vector2(x, 0)
		strip.size = Vector2(window_px, beat_bar.size.y)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		beat_bar.add_child(strip)


func _beat_period() -> float:
	return maxf(_cfg.beat_period_min, _cfg.beat_period_start - reps * _cfg.beat_period_step)


func _attempt_curl(period: float) -> void:
	# Cyclic distance to the nearest beat: right after it or right before the next.
	var distance := minf(phase, period - phase)
	if distance <= _cfg.timing_window * period:
		_complete_rep()
	else:
		combo = 0
		AudioManager.play(&"miss")
		message_label.text = "Off beat — the weight stack slams down!"
		_update_labels()


func _complete_rep() -> void:
	reps += 1
	combo += 1
	AudioManager.play(&"rep")
	var multiplier := (1.0 + reps * _cfg.xp_growth_per_rep) \
		* (1.0 + mini(combo, _cfg.max_combo_for_bonus) * _cfg.combo_bonus)
	award_xp(multiplier, character.position + Vector2(0, -90))
	burst_particles(character.position)
	screen_shake(5.0, 0.2)
	message_label.text = "REP %d — smooth on the beat!" % reps
	_kick_character()
	_update_labels()


## Quick heel-kick tween per curl.
func _kick_character() -> void:
	var tween := create_tween()
	tween.tween_property(character, "position:y", _character_rest_y - 10.0, 0.08)
	tween.tween_property(character, "position:y", _character_rest_y, 0.12)


func _update_labels() -> void:
	rep_label.text = "Reps: %d" % reps
	combo_label.text = "Combo: %d" % combo
