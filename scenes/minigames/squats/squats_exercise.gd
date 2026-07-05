## Squats — trains Quadriceps (plus a little Strength).
##
## Balance minigame: a random wobble pushes the marker off center; counter it
## with A/D or Left/Right. Staying inside the green zone long enough completes
## a rep. Instability grows over time and with every rep; hitting the edge of
## the meter means a stumble.
extends BaseExercise

@onready var track: ColorRect = %Track
@onready var zone: ColorRect = %Zone
@onready var marker: ColorRect = %Marker
@onready var hold_bar: ProgressBar = %HoldBar
@onready var character: AnimatedSprite2D = %Character
@onready var rep_label: Label = %RepLabel
@onready var message_label: Label = %MessageLabel

var reps := 0
## Balance state in [-1, 1]; 0 is perfectly centered, ±1 is a stumble.
var balance := 0.0
var drift_velocity := 0.0
var instability := 0.0
var hold := 0.0

var _cfg: SquatsConfig
var _animating := false
var _character_rest_y := 0.0


func _ready() -> void:
	super()
	_cfg = config as SquatsConfig
	instability = _cfg.instability_start
	_character_rest_y = character.position.y
	# Size the green zone from the configured success window.
	zone.size.x = track.size.x * _cfg.success_zone * 2.0
	zone.position.x = (track.size.x - zone.size.x) / 2.0
	hold_bar.max_value = 100.0
	message_label.text = "Hold A/D or Left/Right to stay balanced!"
	_update_labels()


func _process(delta: float) -> void:
	if _animating or exhausted:
		return
	# Random walk on the drift makes the wobble feel organic; it gets rougher
	# the longer the set goes on.
	instability += _cfg.instability_gain_per_second * delta
	drift_velocity += randf_range(-1.0, 1.0) * instability * delta * 6.0
	balance += drift_velocity * delta
	balance += Input.get_axis("ui_left", "ui_right") * _cfg.correction_strength * delta
	balance = clampf(balance, -1.0, 1.0)
	_apply_balance_visuals()

	if absf(balance) >= 1.0:
		_stumble()
		return
	if absf(balance) <= _cfg.success_zone:
		hold += delta
		if hold >= _cfg.hold_time_per_rep:
			_complete_rep()
	else:
		hold = maxf(0.0, hold - delta * _cfg.hold_decay)
	hold_bar.value = 100.0 * hold / _cfg.hold_time_per_rep


func _apply_balance_visuals() -> void:
	var half_travel := track.size.x / 2.0 - marker.size.x / 2.0
	marker.position.x = track.size.x / 2.0 - marker.size.x / 2.0 + balance * half_travel
	character.rotation = balance * 0.25  # lean with the wobble


func _complete_rep() -> void:
	reps += 1
	hold = 0.0
	instability += _cfg.instability_gain_per_rep
	AudioManager.play(&"rep")
	var at := Vector2(track.position.x + track.size.x / 2.0, track.position.y - 40.0)
	award_xp(1.0 + reps * _cfg.xp_growth_per_rep, at)
	burst_particles(character.position)
	screen_shake(7.0, 0.3)
	message_label.text = "REP %d — deep squat!" % reps
	_update_labels()
	_play_squat_animation()


func _stumble() -> void:
	balance = 0.0
	drift_velocity = 0.0
	hold = 0.0
	# Losing balance eases the difficulty a little so recovery feels fair.
	instability = maxf(_cfg.instability_start, instability * 0.7)
	AudioManager.play(&"miss")
	screen_shake(4.0, 0.2)
	message_label.text = "You stumbled! Reset and try again."
	_apply_balance_visuals()


## Dip down and drive back up; the offset keeps the feet planted while scaling.
func _play_squat_animation() -> void:
	_animating = true
	var tween := create_tween()
	tween.tween_property(character, "scale:y", character.scale.y * 0.7, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(character, "position:y", _character_rest_y + 19.0, 0.18)
	tween.tween_property(character, "scale:y", character.scale.y, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(character, "position:y", _character_rest_y, 0.22)
	tween.tween_callback(func() -> void: _animating = false)


func _update_labels() -> void:
	rep_label.text = "Reps: %d" % reps
