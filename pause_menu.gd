extends CanvasLayer


@onready var help_panel = get_node_or_null("HelpPanel") 
@onready var control_button = $VBoxContainer/ControlButton

func _ready():
	hide()
	if help_panel: help_panel.hide()
	
	if control_button:
		control_button.pressed.connect(_on_controls_button_pressed)

func _input(event):
	if event.is_action_pressed("pause_game"):
		toggle_pause()
	
	if event.is_action_pressed("ui_cancel") and help_panel and help_panel.visible:
		help_panel.hide()
		get_viewport().set_input_as_handled()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	
	if get_tree().paused:
		show()
	else:
		hide()
		if help_panel: help_panel.hide()

func _on_controls_button_pressed():
	if help_panel: 
		help_panel.show()

func _on_continue_button_pressed():
	toggle_pause()

func _on_save_quit_button_pressed():
	PlayerStats.save_game()
	GameCalendar.save_state()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
