extends Control

@onready var punching_bag = $PunchingBag
@onready var target_button = $PunchingBag/TargetButton
@onready var score_label = $ScoreLabel
@onready var message_label = $MessageLabel
@onready var back_button = $BackButton

# Falling speed configuration (adjustable directly in the Inspector panel)
@export var FALL_SPEED: float = 250.0

func _ready() -> void:
	# Connecting target clicks and back button signals
	target_button.pressed.connect(_on_target_clicked)
	back_button.pressed.connect(_on_back_pressed)
	
	message_label.text = "Catch the falling targets on the bag!"
	update_ui()
	spawn_new_target()

func _process(delta: float) -> void:
	# 1. DOWNWARD MOVEMENT: Increase the Y position of the button each frame
	target_button.position.y += FALL_SPEED * delta
	
	# 2. LOSE CONDITION: Check if the target fell below the bottom edge of the punching bag
	var max_y = punching_bag.size.y - target_button.size.y
	if target_button.position.y >= max_y:
		_on_target_timeout() # Target escaped, handle as "Too slow"

func spawn_new_target() -> void:
	# Randomize X position (left/right) within the boundaries of the punching bag width
	var max_x = punching_bag.size.x - target_button.size.x
	var random_x = randf_range(0, max_x)
	
	# SPAWN AT THE TOP: Always reset the target to the very top of the bag (Y = 0)
	target_button.position = Vector2(random_x, 0)

func _on_target_clicked() -> void:
	# Success: Player clicked the target before it hit the bottom!
	message_label.text = "HIT! +15 EXP (AGI)"
	GlobalStats.player_exp += 15 
	
	# Increase speed by 15 with each hit to make the game progressively harder
	FALL_SPEED += 15.0
	
	update_ui()
	spawn_new_target()

func _on_target_timeout() -> void:
	# Failure: Target fell to the bottom
	message_label.text = "TOO SLOW!"
	
	# Reset speed back to baseline on miss so the game doesn't become impossible
	FALL_SPEED = 250.0
	
	spawn_new_target()

func update_ui() -> void:
	score_label.text = "Earned EXP: " + str(GlobalStats.player_exp)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/gym_map.tscn")
