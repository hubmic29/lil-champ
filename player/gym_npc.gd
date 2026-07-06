extends CharacterBody2D

@export var speed: float = 50.0

# Dialogs
@export var messages: Array[String] = [
	"Hey bro, great form!",
	"Leg day today, or chest again?",
	"Did you leave your towel on the bench?",
	"Don't forget your protein after the workout.",
	"Light weight, right? Time to add some iron!",
	"Remember: water, diet, sleep. That's the holy trinity.",
	"Just don't round your back on deadlifts, or your spine will explode.",
	"Oh, Mr. 'Summer Body' is here. We'll see in August!",
	"Someone's cheating on their reps... I saw that!",
	"Got any chalk to spare? My hands are slipping."
]

@onready var anim = $AnimatedSprite2D
@onready var bubble_anchor = $BubbleAnchor
@onready var label = $BubbleAnchor/PanelContainer/Label
@onready var wander_timer = $WanderTimer

var current_state: String = "wander"
var target_direction: Vector2 = Vector2.ZERO
var player_target: Node2D = null

func _ready() -> void:
	bubble_anchor.hide()
	_pick_random_direction()
	wander_timer.start(randf_range(2.0, 4.0))

func _physics_process(_delta: float) -> void:
	if current_state == "wander":
		velocity = target_direction * speed
		_play_animation(target_direction)
	elif current_state == "talk":
		velocity = Vector2.ZERO
		anim.stop()
		anim.frame = 0

	move_and_slide()

	# WALL STOPPING SYSTEM

	if current_state == "wander" and get_slide_collision_count() > 0:
		target_direction = Vector2.ZERO
		anim.stop()
		anim.frame = 0

func _pick_random_direction() -> void:
	if current_state == "talk":
		return
		
	if randf() < 0.25:
		target_direction = Vector2.ZERO
		anim.stop()
		anim.frame = 0
	else:
		target_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _on_wander_timer_timeout() -> void:
	_pick_random_direction()
	wander_timer.start(randf_range(2.0, 5.0))

#MODIFIED DIALOG SYSTEM (WITH DEBUGGING) 

func _on_detection_zone_body_entered(body: Node2D) -> void:
	print("DETECTION TEST: Something entered the NPC zone. Object name: ", body.name)
	
	if body.is_in_group("Player"):
		print("SUCCESS: It's the Player! Displaying dialog.")
		player_target = body
		current_state = "talk"
		label.text = messages.pick_random()
		bubble_anchor.show()

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == player_target:
		print("END: Player left. Hiding dialog.")
		player_target = null
		current_state = "wander"
		bubble_anchor.hide()
		_pick_random_direction()

func _play_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO: 
		return
		
	var anim_name: String = ""
	
	# Check diagonal directions
	if dir.x > 0 and dir.y < 0:
		anim_name = "walk_up_right"
	elif dir.x > 0 and dir.y > 0:
		anim_name = "walk_down_right"
	elif dir.x < 0 and dir.y < 0:
		anim_name = "walk_up_left"
	elif dir.x < 0 and dir.y > 0:
		anim_name = "walk_down_left"
	# Check straight directions
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
