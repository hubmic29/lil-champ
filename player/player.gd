extends CharacterBody2D

@export var SPEED: float = 300.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO

	if Input.is_key_pressed(KEY_D): input_vector.x += 1
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1
	if Input.is_key_pressed(KEY_S): input_vector.y += 1
	if Input.is_key_pressed(KEY_W): input_vector.y -= 1

	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * SPEED
		_play_walk(input_vector)
	else:
		velocity = Vector2.ZERO
		if anim.is_playing():
			anim.stop()
			anim.frame = 0   # snap to neutral standing pose

	move_and_slide()

func _play_walk(dir: Vector2) -> void:
	var name: String
	# Horizontal axis takes priority for diagonals (feels more responsive)
	if abs(dir.x) >= abs(dir.y):
		name = "walk_right" if dir.x > 0 else "walk_left"
	else:
		name = "walk_down" if dir.y > 0 else "walk_up"

	if anim.animation != name:
		anim.play(name)
