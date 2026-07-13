## Dumbbell Flyes — trains Chest.
##
## Charge-and-release: hold E/Space to sweep the dumbbells up the arc, then
## let go inside the green window. Overshooting the top of the arc while
## still holding spills the rep; the window narrows with every success.
extends BaseExercise

@onready var track: ColorRect = %Track
@onready var zone: ColorRect = %Zone
@onready var marker: ColorRect = %Marker
@onready var character: AnimatedSprite2D = %Character
@onready var rep_label: Label = %RepLabel
@onready var message_label: Label = %MessageLabel

## Arm position along the arc, 0..100.
var arc := 0.0
var reps := 0

var _cfg: FlyesConfig
var _holding := false


func _ready() -> void:
	super()
	_cfg = config as FlyesConfig
	message_label.text = "Hold E / SPACE to raise — release in the green!"
	_refresh_zone()
	_update_visuals()
	_update_labels()


func _process(delta: float) -> void:
	if exhausted:
		return
	var held := Input.is_action_pressed("interaction") or Input.is_action_pressed("ui_accept")
	if held:
		_holding = true
		arc += _cfg.raise_speed * delta
		if arc >= 100.0:
			_overshoot()
	elif _holding:
		_holding = false
		_release()
	else:
		arc = maxf(0.0, arc - _cfg.lower_speed * delta)
	_update_visuals()


func _release() -> void:
	if arc >= _zone_start() and arc <= _cfg.zone_end:
		_complete_rep()
	elif arc > 8.0:  # ignore tiny accidental taps
		AudioManager.play(&"miss")
		message_label.text = "Released too early — no squeeze, no growth!"


func _overshoot() -> void:
	arc = 0.0
	_holding = false
	AudioManager.play(&"miss")
	screen_shake(5.0, 0.25)
	message_label.text = "TOO FAR — the dumbbells clank overhead!"


func _complete_rep() -> void:
	reps += 1
	arc = 0.0
	AudioManager.play(&"rep")
	var at := Vector2(track.position.x + track.size.x / 2.0, track.position.y - 40.0)
	award_xp(1.0 + reps * _cfg.xp_growth_per_rep, at)
	burst_particles(character.position)
	screen_shake(7.0, 0.3)
	message_label.text = "REP %d — perfect squeeze!" % reps
	_refresh_zone()
	_update_labels()


func _zone_start() -> float:
	return minf(
		_cfg.zone_start + reps * _cfg.zone_shrink_per_rep,
		_cfg.zone_end - _cfg.zone_min_width
	)


func _refresh_zone() -> void:
	var start_frac := _zone_start() / 100.0
	var end_frac := _cfg.zone_end / 100.0
	zone.position.x = track.size.x * start_frac
	zone.size.x = track.size.x * (end_frac - start_frac)


func _update_visuals() -> void:
	marker.position.x = (track.size.x - marker.size.x) * arc / 100.0
	character.rotation = -0.2 * arc / 100.0  # lean into the squeeze


func _update_labels() -> void:
	rep_label.text = "Reps: %d" % reps
