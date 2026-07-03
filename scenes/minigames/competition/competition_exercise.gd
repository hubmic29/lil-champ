## Bodybuilding Competition — pose-off against AI bodybuilders for prize money.
##
## Pick a tournament tier, pay the entry fee, then perform a posing routine
## of Quick Time Events: a random key is shown and the sweeping indicator
## must be inside the highlighted window when you press it (Perfect / Good /
## Miss). Your pose scores get a bonus from total muscle levels; opponents
## roll scores from their tier's range, so top tiers are only winnable with
## near-perfect timing on a well-trained body. Placements 1-3 pay out cash.
extends BaseExercise

enum State { MENU, POSING, RESULTS }

@onready var menu_panel: Panel = %MenuPanel
@onready var tournament_list: VBoxContainer = %TournamentList
@onready var menu_money_label: Label = %MenuMoneyLabel
@onready var stage_ui: Control = %StageUI
@onready var belt: ColorRect = %Belt
@onready var good_zone: ColorRect = %GoodZone
@onready var perfect_zone: ColorRect = %PerfectZone
@onready var indicator: ColorRect = %Indicator
@onready var key_label: Label = %KeyLabel
@onready var pose_label: Label = %PoseLabel
@onready var score_label: Label = %ScoreLabel
@onready var bonus_label: Label = %BonusLabel
@onready var message_label: Label = %MessageLabel
@onready var character: Sprite2D = %Character
@onready var opponents_row: Node2D = %Opponents
@onready var results_panel: Panel = %ResultsPanel
@onready var results_title: Label = %ResultsTitle
@onready var results_list: VBoxContainer = %ResultsList
@onready var continue_button: Button = %ContinueButton

var state := State.MENU
var tournament := 0
var pose_index := 0
var player_score := 0.0
var opponents: Array[Dictionary] = []

var _cfg: CompetitionConfig
var _pose_active := false
var _target_keycode := KEY_NONE
var _speed := 0.0


func _ready() -> void:
	super()
	_cfg = config as CompetitionConfig
	good_zone.size.x = _cfg.good_zone_width
	perfect_zone.size.x = _cfg.perfect_zone_width
	continue_button.pressed.connect(_show_menu)
	_show_menu()


func _process(delta: float) -> void:
	if state != State.POSING or not _pose_active:
		return
	indicator.position.x += _speed * delta
	if indicator.position.x >= belt.size.x - indicator.size.x:
		_resolve_pose(0.0, "Too slow!")


func _unhandled_key_input(event: InputEvent) -> void:
	if state != State.POSING or not _pose_active:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == _target_keycode or key.keycode == _target_keycode:
		_judge_timing()
	elif _is_pool_key(key):
		_resolve_pose(0.0, "Wrong pose!")


# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------

func _show_menu() -> void:
	state = State.MENU
	menu_panel.show()
	results_panel.hide()
	stage_ui.hide()
	message_label.text = "Choose a tournament!"
	menu_money_label.text = "Your wallet: $ %d" % PlayerStats.money
	for child in tournament_list.get_children():
		child.queue_free()
	for i in _cfg.tournament_names.size():
		var button := Button.new()
		button.text = "%s   —   Entry $%d  •  1st prize $%d" % [
			_cfg.tournament_names[i], _cfg.entry_fees[i], _cfg.first_prizes[i],
		]
		button.disabled = PlayerStats.money < _cfg.entry_fees[i]
		button.pressed.connect(_start_tournament.bind(i))
		tournament_list.add_child(button)


# ---------------------------------------------------------------------------
# Posing routine
# ---------------------------------------------------------------------------

func _start_tournament(index: int) -> void:
	if not PlayerStats.spend_money(_cfg.entry_fees[index]):
		AudioManager.play(&"miss")
		return
	AudioManager.play(&"click")
	tournament = index
	player_score = 0.0
	pose_index = 0
	_speed = _cfg.indicator_speeds[index]
	_generate_opponents()
	state = State.POSING
	menu_panel.hide()
	stage_ui.show()
	bonus_label.text = "Muscle bonus: +%d%%" % int(_muscle_bonus() * 100.0)
	_start_pose()


## Each rival rolls their whole routine up front from the tier's range.
func _generate_opponents() -> void:
	opponents.clear()
	var names := _cfg.opponent_names.duplicate()
	names.shuffle()
	for i in _cfg.opponent_counts[tournament]:
		var total := 0.0
		for p in _cfg.poses_per_tournament:
			total += randf_range(
				_cfg.opponent_pose_min[tournament], _cfg.opponent_pose_max[tournament])
		opponents.append({"name": names[i % names.size()], "score": total})
	_spawn_opponent_sprites()


func _spawn_opponent_sprites() -> void:
	for child in opponents_row.get_children():
		child.queue_free()
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/human.png")
	atlas.region = Rect2(0, 0, 32, 32)
	for i in opponents.size():
		var rival := Sprite2D.new()
		rival.texture = atlas
		rival.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rival.scale = Vector2(3, 3)
		rival.position = Vector2(i * 90.0, 0)
		rival.modulate = Color(randf_range(0.6, 1.0), randf_range(0.6, 1.0), randf_range(0.6, 1.0))
		opponents_row.add_child(rival)


func _start_pose() -> void:
	if state != State.POSING:
		return
	pose_label.text = "Pose %d / %d" % [pose_index + 1, _cfg.poses_per_tournament]
	score_label.text = "Score: %d" % int(player_score)
	var letter: String = _cfg.qte_keys.pick_random()
	_target_keycode = OS.find_keycode_from_string(letter)
	key_label.text = letter
	good_zone.position.x = randf_range(0.0, belt.size.x - good_zone.size.x)
	perfect_zone.position.x = (good_zone.size.x - perfect_zone.size.x) / 2.0
	indicator.position.x = 0.0
	_pose_active = true


func _judge_timing() -> void:
	var marker_x := indicator.position.x + indicator.size.x / 2.0
	var good_start := good_zone.position.x
	var perfect_start := good_start + perfect_zone.position.x
	if marker_x >= perfect_start and marker_x <= perfect_start + perfect_zone.size.x:
		_resolve_pose(_cfg.perfect_points, "PERFECT POSE!")
	elif marker_x >= good_start and marker_x <= good_start + good_zone.size.x:
		_resolve_pose(_cfg.good_points, "Good pose!")
	else:
		_resolve_pose(0.0, "Missed the timing!")


func _resolve_pose(points: float, msg: String) -> void:
	_pose_active = false
	message_label.text = msg
	if points > 0.0:
		var scored := points * (1.0 + _muscle_bonus())
		player_score += scored
		var is_perfect := points >= _cfg.perfect_points
		AudioManager.play(&"perfect" if is_perfect else &"good")
		screen_shake(8.0 if is_perfect else 4.0, 0.25)
		burst_particles(character.position, Color(1.0, 0.85, 0.3), 24 if is_perfect else 12)
		FloatingText.spawn(self, "+%d pts" % int(scored),
			character.position + Vector2(-30, -90), Color(1.0, 0.85, 0.3), 26)
		award_xp(points / _cfg.perfect_points, character.position)
		_play_pose_animation()
	else:
		AudioManager.play(&"miss")
	score_label.text = "Score: %d" % int(player_score)
	pose_index += 1
	if pose_index >= _cfg.poses_per_tournament:
		get_tree().create_timer(1.0).timeout.connect(_finish_tournament)
	else:
		get_tree().create_timer(0.8).timeout.connect(_start_pose)


func _muscle_bonus() -> float:
	return PlayerStats.total_stat_levels() * _cfg.muscle_bonus_per_level


## Random flex: quick lean / grow tween, back to neutral.
func _play_pose_animation() -> void:
	var tween := create_tween()
	match randi() % 3:
		0:  # front double biceps: puff up
			tween.tween_property(character, "scale", Vector2(4.6, 4.6), 0.15)
		1:  # side chest: lean right
			tween.tween_property(character, "rotation", 0.3, 0.15)
		2:  # side triceps: lean left
			tween.tween_property(character, "rotation", -0.3, 0.15)
	tween.tween_interval(0.3)
	tween.tween_property(character, "scale", Vector2(4, 4), 0.15)
	tween.parallel().tween_property(character, "rotation", 0.0, 0.15)


func _is_pool_key(key: InputEventKey) -> bool:
	for letter in _cfg.qte_keys:
		var code := OS.find_keycode_from_string(letter)
		if key.physical_keycode == code or key.keycode == code:
			return true
	return false


# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------

## Prize money for a placement in the current tournament (0 below top 3).
func _prize_for(placement: int) -> int:
	var first := _cfg.first_prizes[tournament]
	match placement:
		1:
			return first
		2:
			return roundi(first * _cfg.second_place_fraction)
		3:
			return roundi(first * _cfg.third_place_fraction)
		_:
			return 0


func _finish_tournament() -> void:
	state = State.RESULTS
	stage_ui.hide()
	results_panel.show()
	var standings: Array[Dictionary] = opponents.duplicate()
	standings.append({"name": "YOU", "score": player_score, "is_player": true})
	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["score"] > b["score"])
	var placement := 0
	for i in standings.size():
		if standings[i].get("is_player", false):
			placement = i + 1
			break
	var prize := _prize_for(placement)
	if prize > 0:
		PlayerStats.add_money(prize)
	match placement:
		1:
			results_title.text = "CHAMPION of the %s!  +$%d" % [_cfg.tournament_names[tournament], prize]
			AudioManager.play(&"level_up")
			screen_shake(10.0, 0.4)
			burst_particles(size / 2.0, Color(1.0, 0.85, 0.3), 40)
		2, 3:
			results_title.text = "%s place!  +$%d" % ["2nd" if placement == 2 else "3rd", prize]
			AudioManager.play(&"good")
		_:
			results_title.text = "Only %dth place... Train harder and come back!" % placement
			AudioManager.play(&"miss")
	for child in results_list.get_children():
		child.queue_free()
	for i in standings.size():
		var row := Label.new()
		row.text = "%d.  %s — %d pts" % [i + 1, standings[i]["name"], int(standings[i]["score"])]
		row.add_theme_font_size_override("font_size", 16)
		if standings[i].get("is_player", false):
			row.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		results_list.add_child(row)
	PlayerStats.save_game()
