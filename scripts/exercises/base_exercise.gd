## Base class for every gym exercise scene.
##
## Provides everything a minigame needs so concrete exercises only implement
## their own mechanic:
##  - config-driven XP awarding to one or more stats (with floating numbers),
##  - screen shake, particle bursts and level-up fanfare,
##  - fade-in, Back button / Escape handling and returning to the gym map.
##
## To add a new exercise: create a config script extending ExerciseConfig,
## a .tres for it, and a Control scene whose root script extends BaseExercise.
class_name BaseExercise
extends Control

const GYM_SCENE_PATH := "res://scenes/maps/gym_map.tscn"

## UI accent color per stat, shared by floating numbers and the HUD.
const STAT_COLORS := {
	&"strength": Color(1.0, 0.55, 0.3),
	&"chest": Color(1.0, 0.4, 0.45),
	&"back": Color(0.5, 0.75, 1.0),
	&"quadriceps": Color(0.7, 1.0, 0.5),
	&"hamstrings": Color(0.45, 0.9, 0.75),
	&"stamina": Color(1.0, 0.9, 0.4),
}

## Balancing resource for this exercise (assign the matching .tres).
@export var config: ExerciseConfig

## True once the player has run out of energy; minigames must stop accepting
## gameplay input while this is set (the Back button keeps working).
var exhausted := false

var _requires_energy := false
var _shake_tween: Tween
var _back_button: Button
var _energy_bar: ProgressBar


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	PlayerStats.stat_leveled_up.connect(_on_stat_leveled_up)
	_back_button = find_child("BackButton", true, false) as Button
	if _back_button:
		_back_button.pressed.connect(finish_exercise)
	_requires_energy = config != null and config.energy_cost_per_action > 0.0
	_build_energy_ui()
	PlayerStats.energy_changed.connect(_on_energy_changed)
	_refresh_energy_ui()
	if _requires_energy and PlayerStats.is_exhausted():
		_trigger_exhaustion()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		finish_exercise()


## Grants XP for one successful action: every stat in config.stat_rewards
## receives base_xp * weight * quality_multiplier. Spawns floating XP numbers
## at `at` and drains energy. Returns the total XP actually gained.
func award_xp(quality_multiplier := 1.0, at := Vector2.ZERO) -> float:
	if config == null:
		push_warning("%s: no ExerciseConfig assigned." % name)
		return 0.0
	if at == Vector2.ZERO:
		at = size / 2.0
	if _requires_energy and PlayerStats.is_exhausted():
		return 0.0  # safety net: no XP without fuel
	var total := 0.0
	var row := 0
	for stat_key in config.stat_rewards:
		var stat := StringName(stat_key)
		var weight := float(config.stat_rewards[stat_key])
		var gained := PlayerStats.add_xp(stat, config.base_xp * weight * quality_multiplier)
		if gained > 0.0:
			FloatingText.spawn(
				self,
				"+%.0f %s" % [gained, String(stat).capitalize()],
				at + Vector2(randf_range(-12, 12), -row * 24.0),
				STAT_COLORS.get(stat, Color.WHITE)
			)
			total += gained
			row += 1
	PlayerStats.spend_exercise_energy(config.energy_cost_per_action)
	return total


## Quick decaying camera-style shake of the whole exercise UI.
func screen_shake(strength := 8.0, duration := 0.3) -> void:
	if _shake_tween:
		_shake_tween.kill()
	position = Vector2.ZERO
	_shake_tween = create_tween()
	var steps := 6
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * falloff
		_shake_tween.tween_property(self, "position", offset, duration / (steps + 1))
	_shake_tween.tween_property(self, "position", Vector2.ZERO, duration / (steps + 1))


## One-shot particle burst at a local position (success feedback).
func burst_particles(at: Vector2, color := Color(1.0, 0.85, 0.3), amount := 18) -> void:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.one_shot = true
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 260.0
	particles.gravity = Vector2(0, 500)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	add_child(particles)
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)


## Saves progress and fades back to the gym map.
func finish_exercise() -> void:
	AudioManager.play(&"click")
	PlayerStats.save_game()
	SceneSwitcher.change_scene(GYM_SCENE_PATH)


# ---------------------------------------------------------------------------
# Energy & exhaustion
# ---------------------------------------------------------------------------

## Small always-visible energy readout in the top-right corner.
func _build_energy_ui() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -246.0
	box.offset_top = 14.0
	box.offset_right = -16.0
	box.offset_bottom = 64.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = "ENERGY"
	title.add_theme_font_size_override("font_size", 12)
	box.add_child(title)
	_energy_bar = ProgressBar.new()
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size = Vector2(0, 14)
	_energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_energy_bar)
	add_child(box)


func _refresh_energy_ui() -> void:
	_energy_bar.max_value = PlayerStats.progression.max_energy
	_energy_bar.value = PlayerStats.energy
	var tired := PlayerStats.energy <= PlayerStats.progression.tired_threshold
	_energy_bar.modulate = Color(1.0, 0.45, 0.45) if tired else Color.WHITE


func _on_energy_changed(_value: float, _max_value: float) -> void:
	_refresh_energy_ui()
	if _requires_energy and not exhausted and PlayerStats.is_exhausted():
		_trigger_exhaustion()


## Locks the minigame and tells the player to go recover in the sauna.
func _trigger_exhaustion() -> void:
	exhausted = true
	AudioManager.play(&"miss")
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var label := Label.new()
	label.text = "EXHAUSTED!\nVisit the sauna to recover energy."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	overlay.add_child(label)
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.4)
	if _back_button:
		_back_button.move_to_front()  # keep it clickable above the dim layer
	_on_exhausted()


## Virtual hook for minigames that need to pause timers/hide targets when the
## player runs out of energy.
func _on_exhausted() -> void:
	pass


func _on_stat_leveled_up(stat: StringName, new_level: int) -> void:
	AudioManager.play(&"level_up")
	screen_shake(10.0, 0.4)
	FloatingText.spawn(
		self,
		"%s LEVEL %d!" % [String(stat).to_upper(), new_level],
		size / 2.0 - Vector2(0, 100),
		STAT_COLORS.get(stat, Color.GOLD),
		34
	)
