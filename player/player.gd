extends CharacterBody2D

@export var SPEED: float = 300.0

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	# Basic movement directions
	if Input.is_key_pressed(KEY_D):  # Right
		input_vector.x += 1
	if Input.is_key_pressed(KEY_A):  # Left
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_S):  # Down
		input_vector.y += 1
	if Input.is_key_pressed(KEY_W):  # Up
		input_vector.y -= 1
		
	if input_vector != Vector2.ZERO:
		# Normalize vector to prevent faster diagonal movement
		velocity = input_vector.normalized() * SPEED
	else:
		# Stop movement when no keys are pressed
		velocity = Vector2.ZERO

	# Apply movement and handle wall collisions
	move_and_slide()
