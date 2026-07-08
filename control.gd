extends Control

func _ready():
	$MasterSlider.value = SettingsManager.settings["audio"]["master"]
	$FullscreenButton.button_pressed = SettingsManager.settings["video"]["fullscreen"]

func _on_master_slider_value_changed(value):
	var percent = (value + 40) / 40 * 100 
	
	SettingsManager.update_setting("audio", "master", value)
func _on_fullscreen_button_toggled(toggled_on):
	SettingsManager.update_setting("video", "fullscreen", toggled_on)


func _on_save_button_pressed() -> void:
	SettingsManager.save_settings()

	get_tree().change_scene_to_file("res://main_menu.tscn")
