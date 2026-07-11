extends BaseExercise

enum State { MENU, POSING, RESULTS }

@onready var menu_panel: Panel = %MenuPanel
@onready var tournament_list: VBoxContainer = %TournamentList
@onready var stage_ui: Control = %StageUI
@onready var good_zone: ColorRect = %GoodZone
@onready var score_label: Label = %ScoreLabel
@onready var results_panel: Panel = %ResultsPanel
@onready var results_title: Label = %ResultsTitle
@onready var results_list: VBoxContainer = %ResultsList
@onready var continue_button: Button = %ContinueButton
@onready var character: AnimatedSprite2D = %Character

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
	
	if spawn_timer > 1.0:
		print("Spawn timer działa, spawned_count: ", spawned_count)
		
	if spawned_count < 10 and spawn_timer > 1.2:
		print("Próba spawnu nuty!")
		_spawn_falling_note()
		spawned_count += 1
		spawn_timer = 0
	
	# 1. Spadanie nut
	for child in get_children():
		if child.name.begins_with("Note_"):
			child.position.y += 300 * delta
			
			if child.global_position.y > good_zone.global_position.y + 50:
				child.queue_free()
				active_notes -= 1
				_handle_miss()
				_check_game_over()

func _spawn_falling_note() -> void:
	var note = note_scene.instantiate()
	note.name = "Note_" + str(Time.get_ticks_msec())
	
	
	var random_x = randf_range(20, 1000)
	note.position = Vector2(random_x, -50)

	var label = note.get_node_or_null("ColorRect/Label")
	if label:
		label.text = _cfg.qte_keys.pick_random()
	
	add_child(note)
	active_notes += 1

func _unhandled_key_input(event: InputEvent) -> void:
	if state != State.POSING or not event is InputEventKey or not event.pressed: return
	var pressed_key = OS.get_keycode_string(event.physical_keycode)
	
	for child in get_children():
		if child.name.begins_with("Note_"):
			var dist = abs(child.global_position.y - good_zone.global_position.y)
			
			if dist < 80: 
				var label = child.get_node_or_null("ColorRect/Label")
				if label and label.text == pressed_key:
					_handle_hit(dist < 20) 
					child.queue_free()
					active_notes -= 1
					return
				elif dist < 60:
					_handle_miss()

func _handle_hit(is_perfect: bool) -> void:
	_trigger_flash(Color.GREEN if is_perfect else Color.YELLOW)
	player_score += 100 if is_perfect else 50
	hits_in_a_row += 1
	if hits_in_a_row >= 2:
		_update_character_pose()
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
func _trigger_flash(color: Color):
	var flash = ColorRect.new()
	flash.size = Vector2(1550, 660)
	flash.color = color
	flash.modulate.a = 0.3
	flash.z_index = 5 
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
	
func _handle_miss() -> void:
	hits_in_a_row = 0
	var flash = ColorRect.new()
	flash.size = Vector2(1550, 660)
	flash.color = Color.RED
	flash.modulate.a = 0.3
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)
	
	
func _update_character_pose() -> void:
	$Character/CPUParticles2D.restart()
	$Character/CPUParticles2D.emitting = true
	var tier = PlayerStats.evolution_tier
	var prefix = "small_"
	match tier:
		0: prefix = "small_"
		1: prefix = "med_"
		2: prefix = "big_"
	
	var available_anims = []
	var all_anims = character.sprite_frames.get_animation_names()
	print("Dostępne animacje: ", all_anims)
	
	for anim in all_anims:
		if anim.begins_with(prefix) and "pose" in anim:
			available_anims.append(anim)
	
	print("Znaleziono pasujących do '", prefix, "': ", available_anims)
	
	if not available_anims.is_empty():
		var chosen = available_anims.pick_random()
		print("Wybieram animację: ", chosen)
		character.play(chosen)
	else:
		print("BŁĄD: Nie znaleziono żadnej animacji z przedrostkiem ", prefix)
	if not available_anims.is_empty():
		var chosen = available_anims.pick_random()
		character.play(chosen)
		
		var tween = create_tween().set_parallel(true)
		
		character.modulate = Color(2, 2, 2)
		tween.tween_property(character, "modulate", Color.WHITE, 0.3)
		
		character.scale = Vector2(1.1, 1.1)
		tween.tween_property(character, "scale", Vector2(2.0, 2.0), 0.1).set_trans(Tween.TRANS_ELASTIC)
		
		var pos_start = character.position
		tween.tween_property(character, "position:x", pos_start.x + 5, 0.05).set_delay(0.1)
		tween.tween_property(character, "position:x", pos_start.x - 5, 0.05).set_delay(0.15)
		tween.tween_property(character, "position:x", pos_start.x, 0.05).set_delay(0.2)
