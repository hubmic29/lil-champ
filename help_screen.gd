extends CanvasLayer

@onready var tekst_instrukcji: RichTextLabel = $RichTextLabel
@onready var exit_button: TextureButton = $ExitButton 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if exit_button:
		exit_button.pressed.connect(_go_to_menu)
		
func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _close_help() -> void:
	get_tree().paused = false
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_help()
		get_viewport().set_input_as_handled()
