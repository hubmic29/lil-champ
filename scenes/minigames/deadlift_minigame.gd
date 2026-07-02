extends Control

@onready var power_bar: ProgressBar = $PowerBar
@onready var weight_label: Label = $WeightLabel
@onready var rep_label: Label = $RepLabel
@onready var exp_label: Label = $EXPLabel
@onready var message_label: Label = $MessageLabel
@onready var back_button: Button = $BackButton

@export var initial_drain_speed: float = 15.0
@export var power_per_press: float = 10.0

var power: float = 0.0
var reps: int = 0
var current_weight: float = 100.0
var drain_speed: float = 15.0

func _ready() -> void:
	power_bar.max_value = 100.0
	power_bar.value = 0.0
	drain_speed = initial_drain_speed
	message_label.text = "Mash SPACE to lift the bar!"
	back_button.pressed.connect(_on_back_pressed)
	update_ui()

func _process(delta: float) -> void:
	power = max(0.0, power - drain_speed * delta)
	power_bar.value = power

	if Input.is_action_just_pressed("ui_accept"):
		_on_press()

func _on_press() -> void:
	power = min(100.0, power + power_per_press)
	power_bar.value = power

	if power >= 100.0:
		_complete_rep()

func _complete_rep() -> void:
	reps += 1
	GlobalStats.player_exp += 10
	current_weight += 10.0
	drain_speed += 2.0
	power = 0.0
	message_label.text = "REP COMPLETE! +10 EXP (STR) — Keep going!"
	update_ui()

func update_ui() -> void:
	weight_label.text = "Weight: " + str(int(current_weight)) + " kg"
	rep_label.text = "Reps: " + str(reps)
	exp_label.text = "Earned EXP: " + str(GlobalStats.player_exp)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/gym_map.tscn")
