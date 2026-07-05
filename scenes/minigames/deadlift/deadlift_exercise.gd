## Deadlift — trains Back & Hamstrings (plus a little Strength).
##
## Timing minigame: an indicator sweeps across a bar; press Space when it is
## inside the highlighted zone. Perfect / Good / Miss windows grant different
## XP, and the zone moves and the indicator speeds up after every success.
extends BaseExercise

@onready var belt: ColorRect = %Belt
@onready var good_zone: ColorRect = %GoodZone
@onready var perfect_zone: ColorRect = %PerfectZone
@onready var indicator: ColorRect = %Indicator
@onready var barbell: Control = %Barbell
@onready var character: AnimatedSprite2D = %Character
@onready var weight_label: Label = %WeightLabel
@onready var streak_label: Label = %StreakLabel
@onready var message_label: Label = %MessageLabel

var speed := 0.0
var direction := 1
var streak := 0
var current_weight := 0.0

var _cfg: DeadliftConfig
var _lifting := false
var _bar_rest_y := 0.0
var _character_rest_y := 0.0


func _ready() -> void:
	super()
	_cfg = config as DeadliftConfig
	speed = _cfg.indicator_speed_start
	current_weight = _cfg.starting_weight
	_bar_rest_y = barbell.position.y
	_character_rest_y = character.position.y
	good_zone.size.x = _cfg.good_zone_width
	perfect_zone.size.x = _cfg.perfect_zone_width
	message_label.text = "Press SPACE when the marker is in the zone!"
	_randomize_zone()
	_update_labels()


func _process(delta: float) -> void:
	if _lifting or exhausted:
		return
	indicator.position.x += speed * direction * delta
	if indicator.position.x >= belt.size.x - indicator.size.x:
		direction = -1
	elif indicator.position.x <= 0.0:
		direction = 1
	if Input.is_action_just_pressed("ui_accept"):
		_attempt_lift()


func _attempt_lift() -> void:
	var marker_x := indicator.position.x + indicator.size.x / 2.0
	if _is_inside(marker_x, perfect_zone):
		_succeed(_cfg.perfect_multiplier, "PERFECT LIFT!", &"perfect", 12.0)
	elif _is_inside(marker_x, good_zone):
		_succeed(1.0, "Good lift!", &"good", 6.0)
	else:
		streak = 0
		speed = _cfg.indicator_speed_start
		AudioManager.play(&"miss")
		message_label.text = "MISS — the bar didn't move!"
		_update_labels()


func _is_inside(marker_x: float, zone: ColorRect) -> bool:
	# Zones are children of the belt, so both sides are in belt-local space.
	var zone_start := zone.position.x + (good_zone.position.x if zone == perfect_zone else 0.0)
	return marker_x >= zone_start and marker_x <= zone_start + zone.size.x


func _succeed(multiplier: float, text: String, sound: StringName, shake: float) -> void:
	streak += 1
	AudioManager.play(sound)
	message_label.text = text
	var bar_center := barbell.position + barbell.size / 2.0
	award_xp(multiplier, bar_center)
	burst_particles(bar_center, Color(1.0, 0.85, 0.3), 14 if multiplier <= 1.0 else 26)
	screen_shake(shake, 0.3)
	current_weight += _cfg.weight_per_success
	speed += _cfg.indicator_speed_gain
	_update_labels()
	_play_lift_animation()
	_randomize_zone()


## Character and barbell rise from the floor to the hips and settle back down.
func _play_lift_animation() -> void:
	_lifting = true
	var tween := create_tween()
	tween.tween_property(barbell, "position:y", _bar_rest_y - 70.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(character, "position:y", _character_rest_y - 20.0, 0.25)
	tween.tween_interval(0.2)
	tween.tween_property(barbell, "position:y", _bar_rest_y, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(character, "position:y", _character_rest_y, 0.25)
	tween.tween_callback(func() -> void: _lifting = false)


## Moves the good zone somewhere new; the perfect zone stays centered in it.
func _randomize_zone() -> void:
	good_zone.position.x = randf_range(0.0, belt.size.x - good_zone.size.x)
	perfect_zone.position.x = (good_zone.size.x - perfect_zone.size.x) / 2.0


func _update_labels() -> void:
	weight_label.text = "Weight: %d kg" % int(current_weight)
	streak_label.text = "Streak: %d" % streak
