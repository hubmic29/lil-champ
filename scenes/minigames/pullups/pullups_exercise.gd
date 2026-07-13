## Pull-Up Bar — trains Back.
##
## Full range of motion: hold E/Space to pull up until the chin clears the
## bar, then release and lower all the way down to bank the rep. Every rep
## saps a little pull speed (down to a floor), so sets get slower and grittier.
extends BaseExercise

@onready var height_bar: ProgressBar = %HeightBar
@onready var character: AnimatedSprite2D = %Character
@onready var rep_label: Label = %RepLabel
@onready var message_label: Label = %MessageLabel

## Body position, 0 = dead hang, 100 = chin over the bar.
var height := 0.0
var reps := 0

var _cfg: PullUpsConfig
var _chinned := false
var _character_rest_y := 0.0


func _ready() -> void:
	super()
	_cfg = config as PullUpsConfig
	height_bar.max_value = 100.0
	_character_rest_y = character.position.y
	message_label.text = "Hold E / SPACE to pull up, release to lower!"
	_update_labels()


func _process(delta: float) -> void:
	if exhausted:
		return
	var held := Input.is_action_pressed("interaction") or Input.is_action_pressed("ui_accept")
	if held:
		height = minf(100.0, height + _pull_speed() * delta)
		if height >= 100.0 and not _chinned:
			_chinned = true
			AudioManager.play(&"good")
			message_label.text = "Chin over the bar — now lower down slowly!"
	else:
		height = maxf(0.0, height - _cfg.drop_speed * delta)
		if _chinned and height <= 0.0:
			_complete_rep()
	height_bar.value = height
	# The sprite climbs with the bar for a bit of feedback.
	character.position.y = _character_rest_y - 40.0 * height / 100.0


func _pull_speed() -> float:
	return maxf(
		_cfg.pull_speed_min,
		_cfg.pull_speed_start - reps * _cfg.pull_speed_loss_per_rep
	)


func _complete_rep() -> void:
	_chinned = false
	reps += 1
	AudioManager.play(&"rep")
	var at := character.position + Vector2(0, -90)
	award_xp(1.0 + reps * _cfg.xp_growth_per_rep, at)
	burst_particles(character.position)
	screen_shake(6.0, 0.25)
	message_label.text = "REP %d — full range of motion!" % reps
	_update_labels()


func _update_labels() -> void:
	rep_label.text = "Reps: %d" % reps
