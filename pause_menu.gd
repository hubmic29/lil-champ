extends CanvasLayer

func _ready():
	hide()

func _input(event):
	if event.is_action_pressed("pause_game"):
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	
	if get_tree().paused:
		show()
	else:
		hide()

func _on_continue_button_pressed():
	toggle_pause()

func _on_save_quit_button_pressed():
	PlayerStats.save_game()
	GameCalendar.save_state()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
