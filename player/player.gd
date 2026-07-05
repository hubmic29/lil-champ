extends CharacterBody2D

@export var SPEED: float = 300.0
@export var evolution_frames: Array[SpriteFrames] 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_anim: String = "walk_down"

func _ready() -> void:
	PlayerStats.evolution_changed.connect(_on_evolution_changed)
	_update_appearance(PlayerStats.evolution_tier)

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
		anim.animation = last_anim
		anim.stop()
		anim.frame = 0 

	move_and_slide()

func _play_walk(dir: Vector2) -> void:
	var anim_name: String = ""
	
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

	if anim_name != "":
		if anim.animation != anim_name or not anim.is_playing():
			anim.play(anim_name)
			last_anim = anim_name

# ---- evolution func -------
func _on_evolution_changed(tier_index: int, _tier_name: String) -> void:
	_update_appearance(tier_index)

func _update_appearance(tier_index: int) -> void:
	if tier_index < evolution_frames.size() and evolution_frames[tier_index] != null:
		anim.sprite_frames = evolution_frames[tier_index]
		
		if anim.is_playing():
			anim.play(anim.animation)
