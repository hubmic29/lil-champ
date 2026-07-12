extends CanvasLayer

@onready var tekst_instrukcji: RichTextLabel = $RichTextLabel
@onready var exit_button: Button = $ExitButton 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if exit_button:
		exit_button.pressed.connect(_go_to_menu)
		
	display_instructions()

func display_instructions() -> void:
	tekst_instrukcji.bbcode_enabled = true
	var text = "[center][b][color=yellow]STEROWANIE I INSTRUKCJA[/color][/b][/center]\n\n"
	text += "• [color=cyan]Ruch:[/color] W, A, S, D lub Strzałki\n"
	text += "• [color=cyan]Mapa:[/color] Klawisz [b]M[/b]\n"
	text += "• [color=cyan]Zapis gry:[/color] Klawisz [b]Esc[/b]\n"
	text += "• [color=cyan]Interakcja:[/color] Klawisz [b]E[/b]\n\n"
	text += "[center][i]Powodzenia![/i][/center]"
	tekst_instrukcji.text = text
	
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
