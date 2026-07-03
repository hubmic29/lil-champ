## Interactive gym station. Walk into range and press the "interaction"
## action (E) to open the exercise scene assigned in the Inspector.
## All stations (bench, deadlift, punching bag, squats, sauna...) reuse this
## script — a new station only needs a scene with a sprite and a path.
extends Area2D

@export var station_name := "Training Station"
## Shown under the name, e.g. "Trains: Chest, Strength".
@export var trains_hint := ""
## Interaction line of the prompt, e.g. "[E] Compete" or "[E] Browse".
@export var action_hint := "[E] Train"
@export_file("*.tscn") var minigame_path: String = ""
## Stations that cost energy refuse to start while the player is exhausted.
## Turn off for recovery stations like the sauna.
@export var requires_energy := true

var _player_in_range := false
var _prompt: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	PlayerStats.energy_changed.connect(_on_energy_changed)
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(-100, -92)
	_prompt.size = Vector2(200, 48)
	_prompt.add_theme_font_size_override("font_size", 11)
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.visible = false
	add_child(_prompt)
	_refresh_prompt()


func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interaction"):
		start_minigame()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		_player_in_range = true
		_refresh_prompt()
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_player_in_range = false
		_prompt.visible = false


func _on_energy_changed(_value: float, _max_value: float) -> void:
	if _player_in_range:
		_refresh_prompt()


func _refresh_prompt() -> void:
	var lines: Array[String] = [station_name]
	if not trains_hint.is_empty():
		lines.append(trains_hint)
	if _is_blocked():
		lines.append("Too exhausted — rest in the sauna!")
		_prompt.modulate = Color(1.0, 0.55, 0.55)
	else:
		lines.append(action_hint)
		_prompt.modulate = Color.WHITE
	_prompt.text = "\n".join(lines)


func _is_blocked() -> bool:
	return requires_energy and PlayerStats.is_exhausted()


func start_minigame() -> void:
	if minigame_path.is_empty():
		push_warning("%s: no minigame scene assigned!" % name)
		return
	if _is_blocked():
		AudioManager.play(&"miss")
		return
	AudioManager.play(&"click")
	SceneSwitcher.change_scene(minigame_path)
