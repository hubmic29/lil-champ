extends Node

const SAVE_PATH = "user://settings.cfg"

var config = ConfigFile.new()

# Domyślne wartości
var settings = {
	"audio": {
		"master": 0.1,
		"music": 0.1,
		"sfx": 0.1
	},
	"video": {
		"fullscreen": true,
		"vsync": true
	}
}

func _ready():
	load_settings()
	apply_settings()
	# TEST: Wymuszenie ciszy po 2 sekundach
	await get_tree().create_timer(2.0).timeout
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -40)
	print("Test dźwięku wykonany: powinno być cicho!")
	
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
	# Sterujemy tylko Masterem - to na pewno zadziała, bo ta szyna istnieje zawsze
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), clamp(settings["audio"]["master"], -40, 0))
# Funkcje do wywoływania z Twojego menu UI
func update_setting(section, key, value):
	settings[section][key] = value
	print("Zmieniam ustawienie ", key, " na wartość: ", value)
	apply_settings()
	save_settings()
