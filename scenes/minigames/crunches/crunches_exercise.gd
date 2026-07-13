## Crunches — trains Abdominals.
##
## Rep-counting minigame: press W/Up to crunch up, then S/Down to lower back
## down; each full up-down cycle is one rep. Rushing a half-rep is sloppy
## form and breaks the tempo streak, resting too long between reps drops it.
extends BaseExercise

@onready var character: AnimatedSprite2D = %Character
@onready var rep_label: Label = %RepLabel
@onready var streak_label: Label = %StreakLabel
@onready var message_label: Label = %MessageLabel

var reps := 0
var streak := 0
## True while crunched up (waiting for the lower).
var up := false

var _cfg: CrunchesConfig
var _last_press_msec := -1
var _character_rest_y := 0.0


func _ready() -> void:
	super()
	_cfg = config as CrunchesConfig
	_character_rest_y = character.position.y
	message_label.text = "W/Up to crunch, S/Down to lower — steady tempo!"
	_update_labels()


func _process(_delta: float) -> void:
	if exhausted:
		return
	if Input.is_action_just_pressed("ui_up") and not up:
		_half_rep(true)
	elif Input.is_action_just_pressed("ui_down") and up:
		_half_rep(false)


func _half_rep(crunching_up: bool) -> void:
	var now := Time.get_ticks_msec()
	var interval := (now - _last_press_msec) / 1000.0 if _last_press_msec >= 0 else 1.0
	_last_press_msec = now
	if interval < _cfg.min_interval:
		streak = 0
		AudioManager.play(&"miss")
		message_label.text = "Sloppy form — slow down and control it!"
		_update_labels()
		return
	if interval > _cfg.max_interval:
		streak = 0  # rested too long; the tempo bonus starts over
	up = crunching_up
	AudioManager.play(&"click", -14.0)
	_animate(crunching_up)
	if not crunching_up:
		_complete_rep()


func _complete_rep() -> void:
	reps += 1
	streak += 1
	AudioManager.play(&"rep")
	var multiplier := (1.0 + reps * _cfg.xp_growth_per_rep) \
		* (1.0 + mini(streak, _cfg.max_streak_for_bonus) * _cfg.streak_bonus)
	award_xp(multiplier, character.position + Vector2(0, -90))
	burst_particles(character.position)
	screen_shake(5.0, 0.2)
	message_label.text = "REP %d — feel the burn!" % reps
	_update_labels()


## Curl forward on the way up, flatten back out on the way down.
func _animate(crunching_up: bool) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if crunching_up:
		tween.tween_property(character, "rotation", -0.35, 0.12)
		tween.parallel().tween_property(character, "position:y", _character_rest_y - 14.0, 0.12)
	else:
		tween.tween_property(character, "rotation", 0.0, 0.15)
		tween.parallel().tween_property(character, "position:y", _character_rest_y, 0.15)


func _update_labels() -> void:
	rep_label.text = "Reps: %d" % reps
	streak_label.text = "Tempo streak: %d" % streak
