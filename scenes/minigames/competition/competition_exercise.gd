extends BaseExercise

enum State { MENU, POSING, RESULTS }

@onready var menu_panel: Panel = %MenuPanel
@onready var tournament_list: VBoxContainer = %TournamentList
@onready var stage_ui: Control = %StageUI
@onready var good_zone: ColorRect = %GoodZone
@onready var score_label: Label = %ScoreLabel
@onready var character: AnimatedSprite2D = %Character
@onready var results_panel: Panel = %ResultsPanel
@onready var results_title: Label = %ResultsTitle
@onready var results_list: VBoxContainer = %ResultsList
@onready var continue_button: Button = %ContinueButton

var state := State.MENU
var player_score := 0.0
var hits_in_a_row := 0
var spawned_count := 0
var active_notes := 0
var _cfg: CompetitionConfig
var note_scene = preload("res://scenes/minigames/competition/falling_note.tscn")
var spawn_timer := 0.0

func _ready() -> void:
	super()
	_cfg = config as CompetitionConfig
	if continue_button:
		continue_button.pressed.connect(_show_menu)
	_show_menu()

func _process(delta: float) -> void:
	if state != State.POSING: return
	
	spawn_timer += delta
	if spawned_count < 10 and spawn_timer > 1.2:
		_spawn_falling_note()
		spawned_count += 1
		spawn_timer = 0
	
	for child in get_children():
		if child.name.begins_with("Note_"):
			child.position.y += 150 * delta
			if child.global_position.y > good_zone.global_position.y + 60:
				child.queue_free()
				active_notes -= 1
				_check_game_over()

func _spawn_falling_note() -> void:
	var note = note_scene.instantiate()
	note.name = "Note_" + str(Time.get_ticks_msec())
	note.position = Vector2(randf_range(100, 700), -50)
	# Upewnij się, że w scenie falling_note.tscn Label nazywa się dokładnie "Label"
	if note.has_node("Label"):
		note.get_node("Label").text = _cfg.qte_keys.pick_random()
	add_child(note)
	active_notes += 1

func _unhandled_key_input(event: InputEvent) -> void:
	if state != State.POSING or not event is InputEventKey or not event.pressed: return
	var pressed_key = OS.get_keycode_string(event.physical_keycode)
	
	for child in get_children():
		if child.name.begins_with("Note_"):
			if abs(child.global_position.y - good_zone.global_position.y) < 60:
				if child.has_node("Label") and child.get_node("Label").text == pressed_key:
					_handle_hit()
					child.queue_free()
					active_notes -= 1
					_check_game_over()
					return

func _handle_hit() -> void:
	player_score += 100
	hits_in_a_row += 1
	if hits_in_a_row >= 2:
		_change_random_pose()
		player_score += 200
		hits_in_a_row = 0
	score_label.text = "Score: %d" % int(player_score)
	if AudioManager.has_method("play"): AudioManager.play("perfect")

func _check_game_over() -> void:
	if spawned_count >= 10 and active_notes <= 0:
		state = State.RESULTS
		stage_ui.hide()
		results_panel.show()
		results_title.text = "Wynik końcowy: %d" % int(player_score)

func _change_random_pose() -> void:
	var anims = Array(character.sprite_frames.get_animation_names())
	character.play(anims.pick_random())
	var tween = create_tween()
	character.modulate = Color(2, 2, 2)
	tween.tween_property(character, "modulate", Color.WHITE, 0.2)

func _show_menu() -> void:
	state = State.MENU
	menu_panel.show()
	results_panel.hide()
	stage_ui.hide()
	for child in tournament_list.get_children():
		child.queue_free()
	for i in _cfg.tournament_names.size():
		var button := Button.new()
		button.text = "%s ($%d)" % [_cfg.tournament_names[i], _cfg.entry_fees[i]]
		button.pressed.connect(_start_tournament.bind(i))
		tournament_list.add_child(button)

func _start_tournament(_index: int) -> void:
	state = State.POSING
	menu_panel.hide()
	stage_ui.show()
	spawned_count = 0
	active_notes = 0
	spawn_timer = 0
	player_score = 0
	hits_in_a_row = 0
