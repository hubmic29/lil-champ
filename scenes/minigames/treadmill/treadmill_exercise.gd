## Treadmill Run — trains Stamina.
##
## Alternate the left and right stride keys (A/D or Left/Right) to run.
## A steady rhythm builds the pace bar; every stretch of distance pays out
## XP, worth more the higher the pace is when the payout lands.
extends BaseExercise

@onready var pace_bar: ProgressBar = %PaceBar
@onready var character: AnimatedSprite2D = %Character
@onready var distance_label: Label = %DistanceLabel
@onready var message_label: Label = %MessageLabel

var distance := 0.0
var pace := 0.0
var rewards := 0

var _cfg: TreadmillConfig
var _next_reward_at := 0.0
## -1 = last stride was the left foot, 1 = right, 0 = not started yet.
var _last_foot := 0
var _character_rest_y := 0.0


func _ready() -> void:
	super()
	_cfg = config as TreadmillConfig
	pace_bar.max_value = 100.0
	_next_reward_at = _cfg.meters_per_reward
	_character_rest_y = character.position.y
	message_label.text = "Alternate A / D (or Left/Right) to run!"
	_update_labels()


func _process(delta: float) -> void:
	if exhausted:
		return
	pace = maxf(0.0, pace - _cfg.pace_decay * delta)
	pace_bar.value = pace
	var foot := 0
	if Input.is_action_just_pressed("ui_left"):
		foot = -1
	elif Input.is_action_just_pressed("ui_right"):
		foot = 1
	if foot == 0:
		return
	if foot == _last_foot:
		pace = 0.0
		AudioManager.play(&"miss")
		screen_shake(3.0, 0.15)
		message_label.text = "You tripped — alternate your feet!"
		_update_labels()
		return
	_last_foot = foot
	_stride()


func _stride() -> void:
	distance += _cfg.stride_length
	pace = minf(100.0, pace + _cfg.pace_per_stride)
	AudioManager.play(&"click", -14.0)
	_bounce_character()
	if distance >= _next_reward_at:
		_reward()
	_update_labels()


func _reward() -> void:
	rewards += 1
	_next_reward_at += _cfg.meters_per_reward
	AudioManager.play(&"rep")
	var multiplier := (1.0 + pace / 100.0 * _cfg.pace_bonus) \
		* (1.0 + rewards * _cfg.xp_growth_per_reward)
	award_xp(multiplier, character.position + Vector2(0, -90))
	burst_particles(character.position)
	screen_shake(6.0, 0.25)
	message_label.text = "%d m down — keep that pace up!" % int(distance)


## Small hop with every stride so the run feels alive.
func _bounce_character() -> void:
	var tween := create_tween()
	tween.tween_property(character, "position:y", _character_rest_y - 8.0, 0.06)
	tween.tween_property(character, "position:y", _character_rest_y, 0.08)


func _update_labels() -> void:
	distance_label.text = "Distance: %d m" % int(distance)
