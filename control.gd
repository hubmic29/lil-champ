extends Control

func _ready():
	# Ustawiamy suwak na aktualną wartość z managera
	$MasterSlider.value = SettingsManager.settings["audio"]["master"]
	$FullscreenButton.button_pressed = SettingsManager.settings["video"]["fullscreen"]

func _on_master_slider_value_changed(value):
	# value jest od -40 do 0
	# Przeliczamy to na procenty:
	var percent = (value + 40) / 40 * 100 
	
	SettingsManager.update_setting("audio", "master", value)
func _on_fullscreen_button_toggled(toggled_on):
	SettingsManager.update_setting("video", "fullscreen", toggled_on)


func _on_save_button_pressed() -> void:
	# 1. Wymuszenie zapisu do pliku (dla pewności)
	SettingsManager.save_settings()
	
	# 2. Jeśli menu to osobna scena:
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
	# LUB: Jeśli menu to nakładka (CanvasLayer/Control) wewnątrz MainMenu:
	# self.hide()
