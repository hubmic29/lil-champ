extends Control

# Przeciągnij te przyciski z drzewa sceny, trzymając Ctrl, aby mieć 100% pewności co do ścieżki
@onready var btn_basic = $Panel/BasicTextureButton 
@onready var btn_pro = $Panel/ProTextureButton
@onready var btn_god = $Panel/GodTextureButton
@onready var exit_button = $"Panel/ExitButton"
@onready var stat_display = get_node_or_null("StatDisplay")

func _ready():
	if stat_display == null:
		print("UWAGA: Nie znalazłem StatDisplay. Sprawdź nazwę w drzewie!")
	else:
		print("Sukces! StatDisplay znaleziony.")
	btn_basic.pressed.connect(_on_buy_button_pressed.bind("basic"))
	btn_pro.pressed.connect(_on_buy_button_pressed.bind("pro"))
	btn_god.pressed.connect(_on_buy_button_pressed.bind("god"))
	exit_button.pressed.connect(_on_exit_button_pressed)
	btn_basic.mouse_exited.connect(func(): $StatDisplay.hide())

func _on_buy_button_pressed(type: String):
	var stats = {}
	match type:
		"basic": stats = {"cost": 200, "days": 1, "xp": 1.1, "energy": 0.9}
		"pro":   stats = {"cost": 500, "days": 3, "xp": 1.3, "energy": 0.7}
		"god":   stats = {"cost": 1000, "days": 7, "xp": 1.5, "energy": 0.5}

	if PlayerStats.money >= stats.cost:
		PlayerStats.money -= stats.cost
		PlayerStats.apply_steroids(type, stats.days, stats.xp, stats.energy)
		print("Kupiono: ", type)
		
func _on_exit_button_pressed():
	SceneSwitcher.change_scene("res://scenes/maps/gym_map.tscn")
	
func show_stats(text):
	$StatDisplay.text = text
	$StatDisplay.show()
	
func buy_steroid(type, cost, days, xp, energy):
	if PlayerStats.money >= cost:
		PlayerStats.money -= cost
		PlayerStats.apply_steroids(type, days, xp, energy)
		print("Kupiono: ", type)
		SceneSwitcher.change_scene("res://scenes/maps/gym_map.tscn")
	else:
		print("Za mało kasy!")
