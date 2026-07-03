## Bench Press — trains Chest (plus a little Strength).
##
## Mash the interaction key (E), Space, or the left mouse button to fill the
## power bar before it drains. Filling it locks out one rep; every rep gets
## heavier and drains faster.
extends BaseExercise

## How far (px) the barbell travels between empty and full power.
const BAR_TRAVEL := 90.0
## Extra lockout overshoot for the rep animation, in pixels.
const LOCKOUT_OVERSHOOT := 14.0

@onready var power_bar: ProgressBar = %PowerBar
@onready var barbell: Control = %Barbell
@onready var weight_label: Label = %WeightLabel
@onready var rep_label: Label = %RepLabel
@onready var message_label: Label = %MessageLabel

var power := 0.0
var reps := 0
var current_weight := 0.0
var drain_speed := 0.0

var _cfg: BenchPressConfig
var _bar_rest_y := 0.0
var _animating := false


func _ready() -> void:
	super()
	_cfg = config as BenchPressConfig
	_bar_rest_y = barbell.position.y
	drain_speed = _cfg.initial_drain_speed
	current_weight = _cfg.starting_weight
	power_bar.max_value = 100.0
	message_label.text = "Mash E / SPACE / Left Click to lift!"
	_update_labels()


func _process(delta: float) -> void:
	if _animating or exhausted:
		return
	power = maxf(0.0, power - drain_speed * delta)
	_apply_power_visuals()
	if Input.is_action_just_pressed("interaction") \
			or Input.is_action_just_pressed("ui_accept"):
		_press()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if _animating or exhausted:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_press()


func _press() -> void:
	power = minf(100.0, power + _cfg.power_per_press)
	AudioManager.play(&"click", -12.0)
	_apply_power_visuals()
	if power >= 100.0:
		_complete_rep()


## The barbell rises from the chest toward lockout as power fills.
func _apply_power_visuals() -> void:
	power_bar.value = power
	barbell.position.y = _bar_rest_y - BAR_TRAVEL * power / 100.0


func _complete_rep() -> void:
	reps += 1
	_animating = true
	AudioManager.play(&"rep")
	var bar_center := barbell.position + barbell.size / 2.0
	award_xp(1.0 + reps * _cfg.xp_growth_per_rep, bar_center)
	burst_particles(bar_center)
	screen_shake(9.0, 0.35)  # heavy lift!
	current_weight += _cfg.weight_per_rep
	drain_speed += _cfg.drain_gain_per_rep
	message_label.text = "REP %d COMPLETE! %d kg loaded — keep going!" % [reps, int(current_weight)]
	_update_labels()
	# Lockout animation: overshoot at the top, then lower back to the chest.
	var tween := create_tween()
	tween.tween_property(
		barbell, "position:y", _bar_rest_y - BAR_TRAVEL - LOCKOUT_OVERSHOOT, 0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.25)
	tween.tween_property(barbell, "position:y", _bar_rest_y, 0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		power = 0.0
		_animating = false
		_apply_power_visuals()
	)


func _update_labels() -> void:
	weight_label.text = "Weight: %d kg" % int(current_weight)
	rep_label.text = "Reps: %d" % reps
