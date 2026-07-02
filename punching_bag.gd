extends Area2D

# Allows you to easily choose the minigame scene directly in the Inspector panel
@export var minigame_path: String = "res://scenes/test/boxing_minigame.tscn"

var player_in_range: bool = false

func _ready() -> void:
	# Connecting Godot's built-in signals for collision detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Checks if the player is close enough AND pressed the interaction key (E)
	if player_in_range and Input.is_action_just_pressed("interaction"):
		start_minigame()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		
		# Displays current global stats in the console when approaching the station
		print("--- TRAINING STATION ---")
		print("Your current saved EXP: ", GlobalStats.player_exp)
		print("Press E to start training.")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		print("Player left the station range.")

func start_minigame() -> void:
	if minigame_path != "":
		# Smooth transition to the selected training screen
		get_tree().change_scene_to_file(minigame_path)
	else:
		print("ERROR: Minigame scene path is not assigned!")
