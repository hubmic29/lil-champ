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
			anim.frame = 0   

	move_and_slide()

func _play_walk(dir: Vector2) -> void:
	var anim_name: String = ""
	
	# Sprawdzamy przekątne
	if dir.x > 0 and dir.y < 0:
		anim_name = "walk_up_right"
	elif dir.x > 0 and dir.y > 0:
		anim_name = "walk_down_right"
	elif dir.x < 0 and dir.y < 0:
		anim_name = "walk_up_left"
	elif dir.x < 0 and dir.y > 0:
		anim_name = "walk_down_left"
	elif dir.x > 0:
		anim_name = "walk_right"
	elif dir.x < 0:
		anim_name = "walk_left"
	elif dir.y > 0:
		anim_name = "walk_down"
	elif dir.y < 0:
		anim_name = "walk_up"

	if anim.animation != anim_name and anim_name != "":
		anim.play(anim_name)
