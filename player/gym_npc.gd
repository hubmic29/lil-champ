extends CharacterBody2D

@export var speed: float = 50.0
@export var talk_frequency: int = 3 # Co które wejście ma zagadać

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
@onready var col_shape = $CollisionShape2D

var visit_count: int = 0
var current_state: String = "wander"
var target_direction: Vector2 = Vector2.ZERO
var player_target: Node2D = null

func _ready() -> void:
	bubble_anchor.hide()
	_pick_random_direction()
	wander_timer.start(randf_range(2.0, 4.0))

func _physics_process(_delta: float) -> void:
	if current_state == "wander":
		col_shape.disabled = false
		velocity = target_direction * speed
		_play_animation(target_direction)
		move_and_slide()
	elif current_state == "talk":
		col_shape.disabled = true
		velocity = Vector2.ZERO
		anim.stop()
		anim.frame = 0

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		visit_count += 1
		if visit_count >= talk_frequency:
			visit_count = 0
			player_target = body
			current_state = "talk"
			label.text = messages.pick_random()
			bubble_anchor.show()
		else:
			print("NPC ignoruje Cię tym razem...")

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == player_target:
		player_target = null
		current_state = "wander"
		bubble_anchor.hide()
		_pick_random_direction()
		if wander_timer.is_stopped():
			wander_timer.start(randf_range(2.0, 5.0))

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

func _play_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO: return
	var anim_name: String = ""
	if dir.x > 0 and dir.y < 0: anim_name = "walk_up_right"
	elif dir.x > 0 and dir.y > 0: anim_name = "walk_down_right"
	elif dir.x < 0 and dir.y < 0: anim_name = "walk_up_left"
	elif dir.x < 0 and dir.y > 0: anim_name = "walk_down_left"
	elif dir.x > 0: anim_name = "walk_right"
	elif dir.x < 0: anim_name = "walk_left"
	elif dir.y > 0: anim_name = "walk_down"
	elif dir.y < 0: anim_name = "walk_up"

	if anim_name != "":
		if anim.animation != anim_name or not anim.is_playing():
			anim.play(anim_name)
