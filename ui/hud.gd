## Gym map HUD — the persistent progression panel.
##
## Rows are generated from PlayerStats.STATS at runtime, so adding a new stat
## to the singleton automatically shows up here; nothing is hardcoded.
extends CanvasLayer

@onready var panel: PanelContainer = $StatsPanel

var _evolution_label: Label
var _money_label: Label
var _day_label: Label
var _energy_bar: ProgressBar
var _buff_label: Label
var _level_labels := {}
var _xp_bars := {}
var _fatigue_bars := {}
var _steroid_label: Label
var _days_label: Label
var _xp_label: Label


func _ready() -> void:
	# The gym is only playable on training days; if the scene loads on a rest
	# day (e.g. after quitting mid-calendar) or a finished run, route away.
	if get_tree().current_scene.name == "MainMenu":
		hide()
	else:
		show()
	if GameCalendar.is_game_over():
		SceneSwitcher.change_scene.call_deferred("res://scenes/calendar/end_screen.tscn")
		return
	if GameCalendar.day_type == GameCalendar.DayType.REST:
		SceneSwitcher.change_scene.call_deferred("res://scenes/calendar/calendar.tscn")
		return
	_build_panel()
	# Refresh on every progression event instead of polling each frame.
	PlayerStats.xp_gained.connect(func(_s: StringName, _a: float) -> void: _refresh())
	PlayerStats.stat_leveled_up.connect(func(_s: StringName, _l: int) -> void: _refresh())
	PlayerStats.overall_level_changed.connect(func(_l: int, _n: String) -> void: _refresh())
	PlayerStats.evolution_changed.connect(_on_evolution_changed)
	PlayerStats.energy_changed.connect(func(_v: float, _m: float) -> void: _refresh())
	PlayerStats.motivation_changed.connect(func(_a: bool) -> void: _refresh())
	PlayerStats.money_changed.connect(func(_m: int) -> void: _refresh())
	PlayerStats.exhaustion_changed.connect(func(_s: StringName, _v: float) -> void: _refresh())
	GameCalendar.sessions_changed.connect(func(_l: int) -> void: _refresh())
	GameCalendar.day_changed.connect(_on_calendar_day_changed)
	GameCalendar.day_changed.connect(func(_d, _t): update_steroid_ui())
	PlayerStats.steroids_changed.connect(update_steroid_ui)
	get_tree().root.child_entered_tree.connect(_on_scene_changed)
	update_steroid_ui() # Aktualizacja na start
	_refresh()



func _build_panel() -> void:
	for child in panel.get_children():
		child.queue_free()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	vbox.add_child(HSeparator.new())
	_steroid_label = _add_label(vbox, 12, Color(0.6, 0.8, 1.0))
	_days_label = _add_label(vbox, 12, Color(0.6, 0.8, 1.0))
	_xp_label = _add_label(vbox, 12, Color(0.6, 0.8, 1.0))

	_evolution_label = _add_label(vbox, 16, Color(1.0, 0.85, 0.3))
	_money_label = _add_label(vbox, 13, Color(0.65, 0.95, 0.55))
	_day_label = _add_label(vbox, 13, Color(0.8, 0.85, 1.0))
	vbox.add_child(HSeparator.new())

	for stat in PlayerStats.STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		
		var name_label := Label.new()
		name_label.text = String(stat).capitalize()
		name_label.custom_minimum_size.x = 92
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", BaseExercise.STAT_COLORS.get(stat, Color.WHITE))
		row.add_child(name_label)
		
		var level_label := Label.new()
		level_label.custom_minimum_size.x = 36
		level_label.add_theme_font_size_override("font_size", 12)
		row.add_child(level_label)
		
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		
		var fatigue := ProgressBar.new()
		fatigue.show_percentage = false
		fatigue.custom_minimum_size = Vector2(42, 8)
		fatigue.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fatigue.modulate = Color(1.0, 0.5, 0.45)
		row.add_child(fatigue)
		
		vbox.add_child(row)
		_level_labels[stat] = level_label
		_xp_bars[stat] = bar
		_fatigue_bars[stat] = fatigue

	vbox.add_child(HSeparator.new())
	var energy_title := _add_label(vbox, 11)
	energy_title.text = "ENERGY"
	_energy_bar = ProgressBar.new()
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(_energy_bar)
	
	_buff_label = _add_label(vbox, 12, Color(1.0, 0.85, 0.3))
	_buff_label.text = "MOTIVATED! (bonus XP)"


func _add_label(parent: Node, font_size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _refresh() -> void:
	_evolution_label.text = "Lv %d — %s" % [PlayerStats.overall_level, PlayerStats.level_name()]
	_money_label.text = "$ %d" % PlayerStats.money
	_day_label.text = "Day %d/%d  •  Sessions left: %d" % [
		GameCalendar.day, GameCalendar.TOTAL_DAYS, GameCalendar.sessions_left()]
	for stat in PlayerStats.STATS:
		_level_labels[stat].text = "Lv %d" % PlayerStats.levels[stat]
		_xp_bars[stat].value = 100.0 * PlayerStats.xp[stat] \
			/ PlayerStats.xp_required(PlayerStats.levels[stat])
		_fatigue_bars[stat].max_value = PlayerStats.progression.max_exhaustion
		_fatigue_bars[stat].value = PlayerStats.exhaustion[stat]
	_energy_bar.max_value = PlayerStats.progression.max_energy
	_energy_bar.value = PlayerStats.energy
	_buff_label.visible = PlayerStats.is_motivated()


func _on_evolution_changed(_tier: int, tier_name: String) -> void:
	_refresh()
	FloatingText.spawn(
		panel,
		"EVOLVED: %s!" % tier_name.to_upper(),
		Vector2(panel.size.x / 2.0, -10),
		Color(1.0, 0.85, 0.3),
		24
	)
	AudioManager.play(&"level_up")
	
	
func update_steroid_ui():
	if not is_instance_valid(_steroid_label):
		return
	
	if PlayerStats.active_steroid_type != "":
		_steroid_label.show()
		_days_label.show()
		_xp_label.show()
		
		_steroid_label.text = "Sterydy: " + PlayerStats.active_steroid_type.capitalize()
		var days_left = PlayerStats.steroid_expires_at - GameCalendar.day
		_days_label.text = "Pozostało: " + str(days_left) + " dni"
		_xp_label.text = "Bonus XP: x" + str(PlayerStats.steroid_bonus)
		
	else:
		_steroid_label.hide()
		_days_label.hide()
		_xp_label.hide()
		
func _on_calendar_day_changed(_day: int, _type: GameCalendar.DayType) -> void:
	_refresh()
	update_steroid_ui()
	
func _on_scene_changed(_node):
	var current_scene = get_tree().current_scene.name
	
	if current_scene == "MainMenu": 
		hide()
	else:
		show()
