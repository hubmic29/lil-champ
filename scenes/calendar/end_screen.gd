## Run-over screen: victory if Mr. Universe was won within 30 days,
## otherwise game over. Restart wipes all progress and begins day 1.
extends Control

const GYM_SCENE_PATH := "res://scenes/maps/gym_map.tscn"

@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	restart_button.pressed.connect(_restart)
	if GameCalendar.universe_won:
		title_label.text = "YOU ARE MR. UNIVERSE!"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		summary_label.text = "From couch potato to absolute unit in %d days.\nLevel %d — %s  •  Muscle size %d  •  $%d in the bank" % [
			mini(GameCalendar.day, GameCalendar.TOTAL_DAYS),
			PlayerStats.overall_level,
			PlayerStats.level_name(),
			PlayerStats.muscle_size(),
			PlayerStats.money,
		]
		AudioManager.play(&"level_up")
	else:
		title_label.text = "30 DAYS ARE OVER..."
		title_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		summary_label.text = "You never won Mr. Universe. The gym forgets quickly.\nFinal form: Level %d — %s  •  Muscle size %d" % [
			PlayerStats.overall_level,
			PlayerStats.level_name(),
			PlayerStats.muscle_size(),
		]
		AudioManager.play(&"miss")


func _restart() -> void:
	AudioManager.play(&"click")
	PlayerStats.reset_progress()
	GameCalendar.reset()
	SceneSwitcher.change_scene(GYM_SCENE_PATH)
