## Sauna — recovery and social space; no skill gameplay.
##
## Sitting here restores energy every second, plays ambient music and steam,
## shows random small talk from gym friends, and after a while grants a
## temporary motivation buff (bonus XP on all training).
extends BaseExercise

@onready var dialogue_label: Label = %DialogueLabel
@onready var info_label: Label = %InfoLabel
@onready var sitters: Node2D = %Sitters

var _cfg: SaunaConfig
var _time_inside := 0.0
var _buff_granted := false
var _dialogue_timer: Timer


func _ready() -> void:
	super()
	_cfg = config as SaunaConfig
	AudioManager.play_music(&"sauna_ambient")
	for steam in get_tree().get_nodes_in_group("steam"):
		_setup_steam(steam)
	_start_idle_bobbing()
	_dialogue_timer = Timer.new()
	_dialogue_timer.one_shot = true
	_dialogue_timer.timeout.connect(_show_random_dialogue)
	add_child(_dialogue_timer)
	_dialogue_timer.start(2.0)
	dialogue_label.modulate.a = 0.0


func _process(delta: float) -> void:
	_time_inside += delta
	PlayerStats.restore_energy(_cfg.recovery_per_second * delta)
	info_label.text = "Relaxing... Energy +%.0f/s" % _cfg.recovery_per_second
	if not _buff_granted and _time_inside >= _cfg.buff_after_seconds:
		_grant_motivation_buff()


func _grant_motivation_buff() -> void:
	_buff_granted = true
	PlayerStats.apply_motivation_buff(_cfg.buff_duration_seconds)
	AudioManager.play(&"level_up")
	var bonus := int((PlayerStats.progression.motivation_xp_multiplier - 1.0) * 100.0)
	FloatingText.spawn(
		self,
		"MOTIVATED! +%d%% XP for %d min" % [bonus, int(_cfg.buff_duration_seconds / 60.0)],
		size / 2.0 - Vector2(0, 120),
		Color(1.0, 0.85, 0.3),
		30
	)


func _show_random_dialogue() -> void:
	if not _cfg.dialogue_lines.is_empty():
		dialogue_label.text = "\"%s\"" % _cfg.dialogue_lines.pick_random()
		var tween := create_tween()
		tween.tween_property(dialogue_label, "modulate:a", 1.0, 0.4)
		tween.tween_interval(2.5)
		tween.tween_property(dialogue_label, "modulate:a", 0.0, 0.6)
	_dialogue_timer.start(randf_range(_cfg.dialogue_interval_min, _cfg.dialogue_interval_max))


## Gentle breathing/bobbing loop for everyone sitting on the bench.
func _start_idle_bobbing() -> void:
	var i := 0
	for sitter in sitters.get_children():
		var tween := create_tween().set_loops()
		tween.tween_interval(i * 0.4)  # desync the group
		tween.tween_property(sitter, "position:y", sitter.position.y - 4.0, 1.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sitter, "position:y", sitter.position.y, 1.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		i += 1


## Steam emitters are plain CPUParticles2D nodes in the scene (group "steam");
## the full look is configured here to keep the .tscn small.
func _setup_steam(steam: CPUParticles2D) -> void:
	steam.amount = 24
	steam.lifetime = 3.0
	steam.preprocess = 2.0
	steam.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	steam.emission_sphere_radius = 30.0
	steam.direction = Vector2.UP
	steam.spread = 20.0
	steam.gravity = Vector2(0, -30)
	steam.initial_velocity_min = 20.0
	steam.initial_velocity_max = 50.0
	steam.scale_amount_min = 6.0
	steam.scale_amount_max = 14.0
	steam.color = Color(1, 1, 1, 0.12)
	steam.emitting = true


func finish_exercise() -> void:
	AudioManager.stop_music()
	super()
