extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var settings = {
	"audio": {
		"master": 1.0,
		"music": 1.0,
		"sfx": 1.0
	},
	"video": {
		"fullscreen": true,
		"vsync": true
	}
}

func _ready():
	load_settings()
	apply_settings()
	
func save_settings():
	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err == OK:
		for section in settings:
			for key in settings[section]:
				settings[section][key] = config.get_value(section, key, settings[section][key])

func apply_settings():
	_set_bus_volume("Master", settings["audio"]["master"])
	_set_bus_volume("Music", settings["audio"]["music"])
	_set_bus_volume("SFX", settings["audio"]["sfx"])

func _set_bus_volume(bus_name: String, value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var volume_db = linear_to_db(clamp(value, 0.001, 1.0))
		AudioServer.set_bus_volume_db(bus_index, volume_db)

func update_setting(section, key, value):
	settings[section][key] = value
	apply_settings()
	save_settings()
