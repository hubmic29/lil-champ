## Gym map HUD — the persistent progression panel.
##
## Rows are generated from PlayerStats.STATS at runtime, so adding a new stat
## to the singleton automatically shows up here; nothing is hardcoded.
extends CanvasLayer

@onready var panel: Panel = $StatsPanel

var _evolution_label: Label
var _gym_label: Label
var _money_label: Label
var _energy_bar: ProgressBar
var _buff_label: Label
var _level_labels := {}
var _xp_bars := {}


func _ready() -> void:
	_build_panel()
	# Refresh on every progression event instead of polling each frame.
	PlayerStats.xp_gained.connect(func(_s: StringName, _a: float) -> void: _refresh())
	PlayerStats.stat_leveled_up.connect(func(_s: StringName, _l: int) -> void: _refresh())
	PlayerStats.gym_level_changed.connect(func(_l: int) -> void: _refresh())
	PlayerStats.evolution_changed.connect(_on_evolution_changed)
	PlayerStats.energy_changed.connect(func(_v: float, _m: float) -> void: _refresh())
	PlayerStats.motivation_changed.connect(func(_a: bool) -> void: _refresh())
	PlayerStats.money_changed.connect(func(_m: int) -> void: _refresh())
	_refresh()


func _build_panel() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 8
	vbox.offset_right = -10
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_evolution_label = _add_label(vbox, 16, Color(1.0, 0.85, 0.3))
	_gym_label = _add_label(vbox, 13)
	_money_label = _add_label(vbox, 13, Color(0.65, 0.95, 0.55))
	vbox.add_child(HSeparator.new())

	for stat in PlayerStats.STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var name_label := Label.new()
		name_label.text = String(stat).capitalize()
		name_label.custom_minimum_size.x = 92
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override(
			"font_color", BaseExercise.STAT_COLORS.get(stat, Color.WHITE))
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
		vbox.add_child(row)
		_level_labels[stat] = level_label
		_xp_bars[stat] = bar

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
	_evolution_label.text = PlayerStats.evolution_tier_name()
	_gym_label.text = "Gym Level %d" % PlayerStats.gym_level
	_money_label.text = "$ %d" % PlayerStats.money
	for stat in PlayerStats.STATS:
		_level_labels[stat].text = "Lv %d" % PlayerStats.levels[stat]
		_xp_bars[stat].value = 100.0 * PlayerStats.xp[stat] \
			/ PlayerStats.xp_required(PlayerStats.levels[stat])
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
