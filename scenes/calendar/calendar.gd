## End-of-day calendar screen.
##
## Shown when the player leaves the gym (and after every rest day): displays
## the in-game date, full player status (overall level & title, muscle size,
## energy, per-muscle exhaustion) and asks whether the NEXT day should be a
## training day or a rest day. Advancing past day 30 ends the game.
extends Control

const GYM_SCENE_PATH := "res://scenes/maps/gym_map.tscn"
const END_SCENE_PATH := "res://scenes/calendar/end_screen.tscn"
const CALENDAR_SCENE_PATH := "res://scenes/calendar/calendar.tscn"

@onready var panel: Panel = %Panel
@onready var day_label: Label = %DayLabel
@onready var date_label: Label = %DateLabel
@onready var status_label: Label = %StatusLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var exhaustion_box: VBoxContainer = %ExhaustionBox
@onready var train_button: Button = %TrainButton
@onready var rest_button: Button = %RestButton


func _ready() -> void:
	train_button.pressed.connect(_choose.bind(GameCalendar.DayType.TRAINING))
	rest_button.pressed.connect(_choose.bind(GameCalendar.DayType.REST))
	_fill_status()
	_animate_in()


func _fill_status() -> void:
	var type_name := "Training day" if GameCalendar.day_type == GameCalendar.DayType.TRAINING else "Rest day"
	day_label.text = "Day %d of %d" % [mini(GameCalendar.day, GameCalendar.TOTAL_DAYS), GameCalendar.TOTAL_DAYS]
	date_label.text = "%s  •  %s" % [GameCalendar.date_string(), type_name]
	status_label.text = "Level %d — %s\nMuscle size: %d   •   Money: $%d" % [
		PlayerStats.overall_level,
		PlayerStats.level_name(),
		PlayerStats.muscle_size(),
		PlayerStats.money,
	]
	energy_bar.max_value = PlayerStats.progression.max_energy
	energy_bar.value = PlayerStats.energy
	for stat in PlayerStats.STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.text = String(stat).capitalize()
		name_label.custom_minimum_size.x = 100
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override(
			"font_color", BaseExercise.STAT_COLORS.get(stat, Color.WHITE))
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = PlayerStats.progression.max_exhaustion
		bar.value = PlayerStats.exhaustion[stat]
		bar.custom_minimum_size = Vector2(0, 10)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.modulate = Color(1.0, 0.5, 0.45)
		row.add_child(bar)
		var pct := Label.new()
		pct.text = "%d%%" % int(PlayerStats.exhaustion[stat])
		pct.custom_minimum_size.x = 40
		pct.add_theme_font_size_override("font_size", 12)
		row.add_child(pct)
		exhaustion_box.add_child(row)


## Calendar page slides up and fades in.
func _animate_in() -> void:
	panel.pivot_offset = panel.size / 2.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	panel.position.y += 40.0
	var tween := create_tween().set_parallel()
	tween.tween_property(panel, "modulate:a", 1.0, 0.35)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", panel.position.y - 40.0, 0.35) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _choose(next_type: GameCalendar.DayType) -> void:
	train_button.disabled = true
	rest_button.disabled = true
	AudioManager.play(&"click")
	GameCalendar.advance_day(next_type)
	PlayerStats.save_game()
	if GameCalendar.is_game_over():
		SceneSwitcher.change_scene(END_SCENE_PATH)
	elif next_type == GameCalendar.DayType.TRAINING:
		SceneSwitcher.change_scene(GYM_SCENE_PATH)
	else:
		# Rest day: recovery already applied — flow straight back into the
		# calendar so the player sees the new day and picks the next one.
		SceneSwitcher.change_scene(CALENDAR_SCENE_PATH)
