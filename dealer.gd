extends StaticBody2D

@onready var anim = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var psst_label: Label = $PsstLabel

var player_in_range = false

func _ready():
	anim.play("stay")
	psst_label.hide()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		psst_label.show()
		anim.play("sterid")

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		psst_label.hide()
		anim.play("stay")

func _input(event):
	if player_in_range and event.is_action_pressed("interaction"):
		print("Open Shop!")
		
func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interaction"):
		_open_shop()
		set_process(false)
		
func _open_shop():
	var path = "res://steroid_shop.tscn" 
	
	if ResourceLoader.exists(path):
		var err = get_tree().change_scene_to_file(path)
		if err != OK:
			print("Błąd zmiany sceny: ", err)
	else:
		print("BŁĄD: Nie znaleziono pliku pod: ", path)
