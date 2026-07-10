extends CanvasLayer

@onready var scroll = $ScrollContainer
@onready var texture = $ScrollContainer/TextureRect

func _ready():
	$InfoPanel.visible = false
func _input(event):
	if event.is_action_pressed("toggle_minimap"):
		get_tree().paused = false
		queue_free()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scale_map(1.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scale_map(0.9, event.position)

func scale_map(factor: float, mouse_pos: Vector2):
	var old_scale = texture.scale.x
	texture.scale *= factor
	texture.scale = texture.scale.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
	
	var new_scale = texture.scale.x
	var mouse_relative = (mouse_pos - scroll.global_position) / old_scale
	scroll.scroll_horizontal += (mouse_relative.x * (new_scale - old_scale))
	scroll.scroll_vertical += (mouse_relative.y * (new_scale - old_scale))
	
	
func _on_gym_zone_mouse_entered():
	$InfoPanel/TitleLabel.text = "Gym"
	$InfoPanel/DescriptionLabel.text = "Tutaj zwiększasz statystyki mięśniowe."
	$InfoPanel.visible = true
	$InfoPanel.z_index = 10

func _on_gym_zone_mouse_exited():
	$InfoPanel.visible = false
