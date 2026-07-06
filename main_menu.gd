extends Control

@onready var main_music: AudioStreamPlayer = $MainMusic
@onready var grow_sound: AudioStreamPlayer = $GrowSound
@onready var shrink_sound: AudioStreamPlayer = $ShrinkSound
@onready var red_dot: ColorRect = $RedDot

const GYM_SCENE_PATH := "res://scenes/maps/gym_map.tscn"
const MENU_FONT_PATH := "res://assets/Pixelify_Sans/static/PixelifySans-Regular.ttf"

var obroty = 0
var oryginalna_skala = Vector2.ONE

# Save slot selection UI (built in code; see _build_slots_panel).
var _slots_panel: Panel
var _slots_title: Label
var _slots_box: VBoxContainer
var _new_game_mode := false
var _pending_overwrite := -1
var _menu_font: Font

func _ready():
	oryginalna_skala = $AnimatedSprite2D.scale
	$AnimatedSprite2D.play("s_spin")
	main_music.play()

	if red_dot != null:
		var dot_tween = create_tween().set_loops()

		dot_tween.tween_property(red_dot, "modulate:a", 0.0, 0.5)
		dot_tween.tween_property(red_dot, "modulate:a", 1.0, 0.5)

	_menu_font = load(MENU_FONT_PATH)
	_build_slots_panel()

func _on_animated_sprite_2d_animation_looped():
	obroty += 1
	

	if obroty == 2:
		obroty = 0 
	
		var tween = create_tween()
		
		if $AnimatedSprite2D.animation == "s_spin":
			grow_sound.play() 
			$AnimatedSprite2D.play("m_spin")
			$AnimatedSprite2D.scale = oryginalna_skala * 0.7
			tween.tween_property($AnimatedSprite2D, "scale", oryginalna_skala * 1.3, 0.6).set_trans(Tween.TRANS_BOUNCE)
			
		elif $AnimatedSprite2D.animation == "m_spin":
			grow_sound.play()
			$AnimatedSprite2D.play("l_spin")
			$AnimatedSprite2D.scale = oryginalna_skala * 1.0
			tween.tween_property($AnimatedSprite2D, "scale", oryginalna_skala * 1.8, 0.6).set_trans(Tween.TRANS_BOUNCE)
			
		elif $AnimatedSprite2D.animation == "l_spin":
			shrink_sound.play()
			$AnimatedSprite2D.play("s_spin")
			tween.tween_property($AnimatedSprite2D, "scale", oryginalna_skala, 0.5).set_trans(Tween.TRANS_SINE)


func _on_button_pressed() -> void:
	_open_slots(false)  # START = continue a slot


func _on_button_2_pressed() -> void:
	_open_slots(true)  # NEW GAME = pick a slot to (re)start


func _on_button_4_pressed() -> void:
	get_tree().quit()


# ---------------------------------------------------------------------------
# Save slots
# ---------------------------------------------------------------------------

func _build_slots_panel() -> void:
	_slots_panel = Panel.new()
	_slots_panel.offset_left = 276.0
	_slots_panel.offset_top = 90.0
	_slots_panel.offset_right = 876.0
	_slots_panel.offset_bottom = 560.0
	_slots_panel.visible = false
	add_child(_slots_panel)

	_slots_title = Label.new()
	_slots_title.offset_top = 16.0
	_slots_title.offset_right = 600.0
	_slots_title.offset_bottom = 50.0
	_slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots_title.add_theme_font_override("font", _menu_font)
	_slots_title.add_theme_font_size_override("font_size", 26)
	_slots_panel.add_child(_slots_title)

	_slots_box = VBoxContainer.new()
	_slots_box.offset_left = 30.0
	_slots_box.offset_top = 62.0
	_slots_box.offset_right = 570.0
	_slots_box.offset_bottom = 390.0
	_slots_box.add_theme_constant_override("separation", 12)
	_slots_panel.add_child(_slots_box)

	var cancel := Button.new()
	cancel.text = "BACK"
	cancel.offset_left = 220.0
	cancel.offset_top = 405.0
	cancel.offset_right = 380.0
	cancel.offset_bottom = 450.0
	cancel.add_theme_font_override("font", _menu_font)
	cancel.add_theme_font_size_override("font_size", 20)
	cancel.pressed.connect(func() -> void: _slots_panel.hide())
	_slots_panel.add_child(cancel)


func _open_slots(new_game: bool) -> void:
	_new_game_mode = new_game
	_pending_overwrite = -1
	_slots_title.text = "NEW GAME — PICK A SLOT" if new_game else "SELECT SLOT"
	_refresh_slots()
	_slots_panel.show()


func _refresh_slots() -> void:
	for child in _slots_box.get_children():
		child.queue_free()
	for slot in range(1, SaveSlots.SLOT_COUNT + 1):
		_slots_box.add_child(_make_slot_row(slot))


## One row per slot: name + save summary on the left, action button on the right.
func _make_slot_row(slot: int) -> Control:
	var info: Dictionary = SaveSlots.peek(slot)
	var row := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	row.add_child(hbox)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	var status := ""
	if info["exists"] and info["won"]:
		status = "  —  CHAMPION!"
	elif info["exists"] and info["over"]:
		status = "  —  RUN OVER"
	title.text = "SLOT %d%s" % [slot, status]
	title.add_theme_font_override("font", _menu_font)
	title.add_theme_font_size_override("font_size", 20)
	text_box.add_child(title)
	var summary := Label.new()
	if info["exists"]:
		summary.text = "Day %d/%d (%d days left)\nLv %d — %s  •  Size %d  •  $%d" % [
			mini(info["day"], GameCalendar.TOTAL_DAYS), GameCalendar.TOTAL_DAYS,
			info["days_left"], info["level"], info["level_name"],
			info["muscle_size"], info["money"],
		]
	else:
		summary.text = "Empty"
	summary.add_theme_font_override("font", _menu_font)
	summary.add_theme_font_size_override("font_size", 14)
	summary.modulate = Color(0.85, 0.85, 0.85)
	text_box.add_child(summary)
	hbox.add_child(text_box)

	var action := Button.new()
	action.custom_minimum_size = Vector2(150, 0)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.add_theme_font_override("font", _menu_font)
	action.add_theme_font_size_override("font_size", 17)
	if _new_game_mode and info["exists"]:
		action.text = "SURE?" if _pending_overwrite == slot else "OVERWRITE"
	elif info["exists"]:
		action.text = "PLAY"
	else:
		action.text = "START"
	action.pressed.connect(_on_slot_pressed.bind(slot))
	hbox.add_child(action)
	return row


func _on_slot_pressed(slot: int) -> void:
	# Overwriting an existing run needs a second click as confirmation.
	if _new_game_mode and SaveSlots.slot_exists(slot) and _pending_overwrite != slot:
		_pending_overwrite = slot
		_refresh_slots()
		return
	# Continuing an empty slot simply starts a fresh run in it.
	var fresh: bool = _new_game_mode or not SaveSlots.slot_exists(slot)
	SaveSlots.select_slot(slot, fresh)
	AudioManager.play(&"click")
	# Fresh runs (or saves that never finished it) get the intro cutscene;
	# otherwise the gym HUD reroutes finished runs / rest days as needed.
	if PlayerStats.intro_seen:
		SceneSwitcher.change_scene(GYM_SCENE_PATH)
	else:
		SceneSwitcher.change_scene("res://intro.tscn")
