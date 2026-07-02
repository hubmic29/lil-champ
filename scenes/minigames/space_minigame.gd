extends Control
@onready var training_screen: Control = $"."
@onready var background_belt: ColorRect = $BackgroundBelt

@onready var sweet_spot = $BackgroundBelt/SweetSpot
@onready var indicator = $BackgroundBelt/Indicator
@onready var message_label = $MessageLabel
@onready var stats_label = $StatsLabel
@onready var back_button = $BackButton

# Slider mechanic variables
@export var speed: float = 400.0
var direction: int = 1

func _ready() -> void:
	# Clear/set initial text on start
	message_label.text = "Press SPACE in the green zone!"
	update_stats()
	
	# Connect back button click signal
	back_button.text = "Back to Gym"
	back_button.pressed.connect(_on_back_pressed)

func _process(delta: float) -> void:
	# 1. INDICATOR MOVEMENT
	indicator.position.x += speed * direction * delta
	
	# Bounce off the edges of the belt
	if indicator.position.x >= background_belt.size.x:
		direction = -1
	elif indicator.position.x <= 0:
		direction = 1
		
	# 2. SPACEBAR CLICK DETECTION
	if Input.is_action_just_pressed("ui_accept"): # Default is SPACE / ENTER
		check_hit()

func check_hit() -> void:
	var x_indicator = indicator.position.x
	var x_green_start = sweet_spot.position.x
	var x_green_end = sweet_spot.position.x + sweet_spot.size.x
	
	# Check if the indicator is within the green rectangle
	if x_indicator >= x_green_start and x_indicator <= x_green_end:
		var center = x_green_start + (sweet_spot.size.x / 2.0)
		
		# Perfect hit right in the center (15 pixels margin)
		if abs(x_indicator - center) < 15.0:
			message_label.text = "Juice! PERFECT! (+200% EXP)"
			GlobalStats.player_exp += 20 # GLOBAL SAVE
		else:
			message_label.text = "GOOD! (+100% EXP)"
			GlobalStats.player_exp += 10 # GLOBAL SAVE
		speed += 30.0
	else:
		# Miss condition: If the indicator was completely outside the green zone
		message_label.text = "MISS! The character stumbled..."
		speed = 400.0
			
	update_stats()

func update_stats() -> void:
	# Fetch points directly from the global Autoload
	stats_label.text = "Earned EXP: " + str(GlobalStats.player_exp)

func _on_back_pressed() -> void:
	# Return to the main gym map
	get_tree().change_scene_to_file("res://scenes/maps/gym_map.tscn")
