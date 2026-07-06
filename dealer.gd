extends StaticBody2D

@onready var anim = $AnimatedSprite2D
@onready var detection_area = $DetectionArea

var player_in_range = false

func _ready():
	anim.play("stay")
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		anim.play("sterid")

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		anim.play("stay")

func _input(event):
	if player_in_range and event.is_action_pressed("interaction"):
		print("Sklep otwarty!")
