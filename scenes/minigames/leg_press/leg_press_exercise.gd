## Leg Press — trains Quadriceps.
##
## Hold E/Space to drive the sled up the rail and release inside the green
## band near the top. Pushing past the band locks the knees and spills the
## rep; every success makes the sled faster, so the timing gets tighter.
extends BaseExercise

@onready var track: ColorRect = %Track
@onready var zone: ColorRect = %Zone
@onready var lockout: ColorRect = %Lockout
@onready var marker: ColorRect = %Marker
@onready var character: AnimatedSprite2D = %Character
@onready var rep_label: Label = %RepLabel
@onready var message_label: Label = %MessageLabel

## Sled position along the rail, 0..100.
var sled := 0.0
var reps := 0

var _cfg: LegPressConfig
var _pushing := false


func _ready() -> void:
	super()
	_cfg = config as LegPressConfig
	# Static rail markings from the configured windows.
	zone.position.x = track.size.x * _cfg.zone_start / 100.0
	zone.size.x = track.size.x * (_cfg.lockout_start - _cfg.zone_start) / 100.0
	lockout.position.x = track.size.x * _cfg.lockout_start / 100.0
	lockout.size.x = track.size.x * (100.0 - _cfg.lockout_start) / 100.0
	message_label.text = "Hold E / SPACE to press — release in the green!"
	_update_visuals()
	_update_labels()


func _process(delta: float) -> void:
	if exhausted:
		return
	var held := Input.is_action_pressed("interaction") or Input.is_action_pressed("ui_accept")
	if held:
		_pushing = true
		sled += _push_speed() * delta
		if sled >= _cfg.lockout_start:
			_lockout_fail()
	elif _pushing:
		_pushing = false
		_release()
	else:
		sled = maxf(0.0, sled - _cfg.return_speed * delta)
	_update_visuals()


func _push_speed() -> float:
	return minf(
		_cfg.push_speed_max,
		_cfg.push_speed_start + reps * _cfg.push_speed_gain_per_rep
	)


func _release() -> void:
	if sled >= _cfg.zone_start:
		_complete_rep()
	elif sled > 8.0:
		AudioManager.play(&"miss")
		message_label.text = "Half rep — drive it into the green band!"


func _lockout_fail() -> void:
	sled = 0.0
	_pushing = false
	AudioManager.play(&"miss")
	screen_shake(5.0, 0.25)
	message_label.text = "KNEES LOCKED — ease off before the red!"


func _complete_rep() -> void:
	reps += 1
	sled = 0.0
	AudioManager.play(&"rep")
	var at := Vector2(track.position.x + track.size.x / 2.0, track.position.y - 40.0)
	award_xp(1.0 + reps * _cfg.xp_growth_per_rep, at)
	burst_particles(character.position)
	screen_shake(8.0, 0.3)
	message_label.text = "REP %d — plates are flying!" % reps
	_update_labels()


func _update_visuals() -> void:
	marker.position.x = (track.size.x - marker.size.x) * sled / 100.0


func _update_labels() -> void:
	rep_label.text = "Reps: %d" % reps
