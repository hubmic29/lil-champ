extends Control

@onready var chat_container = $Phone/ScrollContainer/VBoxContainer
@onready var scroll_container = $Phone/ScrollContainer
@onready var skip_scene_btn = $SkipSceneBtn
@onready var message_sound = $MessageSound
@onready var typing_sound = $TypingSound
@export var custom_font: Font

var current_scene = 0
var active_typing_indicator: Node = null 
var top_bar: PanelContainer

# Time tracking in minutes (e.g., 18:30 = 1110)
var current_time_minutes = 1110 

var display_names = {
	"me": "Me",
	"ex": "My Ex",
	"bro": "Gym Bro"
}

var dialogs = [
	[
		{"who": "ex", "text": "We need to talk..."},
		{"who": "me", "text": "What's wrong? Did something happen?"},
		{"who": "ex", "text": "It's over. Don't be mad, but I need a guy who takes care of himself and has some ambition."},
		{"who": "me", "text": "Are you kidding? I just hit platinum rank yesterday!"},
		{"who": "ex", "text": "That's exactly what I'm talking about. Goodbye. 👋"}
	],
	[
		{"who": "bro", "text": "Bro, I heard what happened. You holding up?"},
		{"who": "me", "text": "I'm devastated..."},
		{"who": "bro", "text": "Stop feeling sorry for yourself. See you at the gym tomorrow at 6:00 AM."},
		{"who": "bro", "text": "We're gonna turn you into a beast. She'll be begging to come back. 🐗"},
		{"who": "me", "text": "You're right. Time to get my act together."}
	]
]

func _ready() -> void:
	chat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_scene_btn.add_theme_font_override("font", custom_font)
	await get_tree().process_frame
	
	play_scene(current_scene)

func play_scene(index: int) -> void:
	skip_scene_btn.text = "Skip conversation >>"
	typing_sound.stop()
	
	current_time_minutes += randi_range(60, 120) 
	
	for child in chat_container.get_children():
		child.queue_free()
		
	var main_contact = "ex" if index == 0 else "bro"
	var is_blocked = (index == 0)
	_setup_top_bar(main_contact, false)
	
	var messages = dialogs[index]
	
	for msg in messages:
		if index != current_scene:
			return
			
		var is_me = (msg["who"] == "me")
		var delay = 2.5 if is_me else randf_range(4.0, 8.0)
		
		current_time_minutes += randi_range(1, 3)
		var time_str = "%02d:%02d" % [floori(current_time_minutes / 60.0), current_time_minutes % 60]
		
		active_typing_indicator = _create_typing_indicator(msg["who"])
		chat_container.add_child(active_typing_indicator)
		_scroll_to_bottom()
		
		if not is_me:
			typing_sound.play()
		
		await get_tree().create_timer(delay).timeout
		
		typing_sound.stop()
		
		if index != current_scene:
			return
			
		if is_instance_valid(active_typing_indicator):
			active_typing_indicator.queue_free()
			
		_add_message_bubble(msg["who"], msg["text"], time_str)
		_scroll_to_bottom()
		message_sound.play()
	if is_blocked:
		await get_tree().create_timer(1.0).timeout
		_add_blocked_notice()
		_update_top_bar_to_blocked()
		_scroll_to_bottom()
		
	if index == current_scene:
		if index == 0:
			skip_scene_btn.text = "Next day ->"
		else:
			skip_scene_btn.text = "Start training!"

# UI BUILDING 

func _setup_top_bar(who: String, is_blocked: bool = false) -> void:
	if is_instance_valid(top_bar):
		top_bar.queue_free()
		
	top_bar = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.642, 0.642, 0.642, 1.0) 
	style.border_width_bottom = 1
	style.border_color = Color(0.642, 0.642, 0.642, 1.0) 
	top_bar.add_theme_stylebox_override("panel", style)
	
	$Phone.add_child(top_bar)
	
	top_bar.position = scroll_container.position
	top_bar.size = Vector2(scroll_container.size.x, 55)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 55
	chat_container.add_child(top_spacer)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	top_bar.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(hbox)
	
	var back = Label.new()
	back.text = "<"
	back.add_theme_font_override("font", custom_font)
	back.add_theme_font_size_override("font_size", 22)
	back.add_theme_color_override("font_color", Color("0084ff")) 
	hbox.add_child(back)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.x = 8
	hbox.add_child(spacer1)
	
	var avatar = Panel.new()
	avatar.custom_minimum_size = Vector2(36, 36)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var av_style = StyleBoxFlat.new()
	av_style.corner_radius_top_left = 18
	av_style.corner_radius_top_right = 18
	av_style.corner_radius_bottom_left = 18
	av_style.corner_radius_bottom_right = 18
	av_style.bg_color = Color("f38ba8") if who == "ex" else Color("89b4fa")
	avatar.add_theme_stylebox_override("panel", av_style)
	hbox.add_child(avatar)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.x = 8
	hbox.add_child(spacer2)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", -2)
	hbox.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = display_names.get(who, "")
	name_lbl.add_theme_font_override("font", custom_font)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color.BLACK)
	vbox.add_child(name_lbl)
	
	var status_hbox = HBoxContainer.new()
	vbox.add_child(status_hbox)
	
	var dot = Panel.new()
	dot.name = "Dot"
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot_style = StyleBoxFlat.new()
	dot_style.bg_color = Color("31a24c")
	dot_style.corner_radius_top_left = 4
	dot_style.corner_radius_top_right = 4
	dot_style.corner_radius_bottom_left = 4
	dot_style.corner_radius_bottom_right = 4
	dot.add_theme_stylebox_override("panel", dot_style)
	status_hbox.add_child(dot)
	
	var status_lbl = Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = " Active now"
		
	if is_blocked:
		status_lbl.text = " Blocked"
		dot.modulate = Color.RED
	else:
		status_lbl.text = " Active now"
		dot.modulate = Color.WHITE
		
	status_lbl.add_theme_font_override("font", custom_font)
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	status_hbox.add_child(status_lbl)
	
func _update_top_bar_to_blocked() -> void:
	var status_lbl = top_bar.find_child("StatusLabel", true, false)
	var dot = top_bar.find_child("Dot", true, false)
	
	if status_lbl and dot:
		status_lbl.text = " Blocked"
		dot.modulate = Color.RED

func _add_message_bubble(who: String, text: String, time_str: String) -> void:
	var layout = _create_base_layout(who)
	var root_hbox = layout["root"]
	var panel = layout["panel"]
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	
	var bubble_vbox = VBoxContainer.new()
	bubble_vbox.add_theme_constant_override("separation", 4)
	
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", custom_font)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = scroll_container.size.x * 0.65 
	label.add_theme_color_override("font_color", Color.WHITE if who != "me" else Color.BLACK)
	bubble_vbox.add_child(label)
	
	var time_label = Label.new()
	time_label.text = time_str
	time_label.add_theme_font_override("font", custom_font)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 9)
	time_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7) if who != "me" else Color(0, 0, 0, 0.5))
	bubble_vbox.add_child(time_label)
	
	margin.add_child(bubble_vbox)
	panel.add_child(margin)
	
	chat_container.add_child(root_hbox)

func _create_typing_indicator(who: String) -> Control:
	var layout = _create_base_layout(who)
	var root_hbox = layout["root"]
	var panel = layout["panel"]
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	
	var dots_box = HBoxContainer.new()
	dots_box.add_theme_constant_override("separation", 5)
	
	for i in 3:
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = Color.WHITE if who != "me" else Color.BLACK
		dots_box.add_child(dot)
		
		var tween = dot.create_tween().set_loops()
		tween.tween_interval(i * 0.2) 
		tween.tween_property(dot, "modulate:a", 0.2, 0.4)
		tween.tween_property(dot, "modulate:a", 1.0, 0.4)
		
	margin.add_child(dots_box)
	panel.add_child(margin)
	return root_hbox

func _create_base_layout(who: String) -> Dictionary:
	var is_me = (who == "me")
	
	var row_margin = MarginContainer.new()
	row_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_margin.add_theme_constant_override("margin_left", 15) 
	row_margin.add_theme_constant_override("margin_right", 15) 
	
	var root_hbox = HBoxContainer.new()
	root_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if is_me:
		root_hbox.alignment = BoxContainer.ALIGNMENT_END
	else:
		root_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	row_margin.add_child(root_hbox)
	
	var avatar_margin = MarginContainer.new()
	avatar_margin.add_theme_constant_override("margin_top", 16)
	avatar_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN 
	
	var avatar = Panel.new()
	avatar.custom_minimum_size = Vector2(28, 28)
	var av_style = StyleBoxFlat.new()
	av_style.corner_radius_top_left = 14
	av_style.corner_radius_top_right = 14
	av_style.corner_radius_bottom_left = 14
	av_style.corner_radius_bottom_right = 14
	av_style.bg_color = Color("f38ba8") if who == "ex" else Color("89b4fa")
	avatar.add_theme_stylebox_override("panel", av_style)
	avatar_margin.add_child(avatar)
	
	var msg_vbox = VBoxContainer.new()
	msg_vbox.add_theme_constant_override("separation", 2)
	
	var name_label = Label.new()
	name_label.text = display_names.get(who, "")
	name_label.add_theme_font_override("font", custom_font)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2)) 
	name_label.add_theme_font_size_override("font_size", 10) 
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_me else HORIZONTAL_ALIGNMENT_LEFT
	msg_vbox.add_child(name_label)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("a6e3a1") if is_me else (Color("f38ba8") if who == "ex" else Color("89b4fa"))
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15 if is_me else 0
	style.corner_radius_bottom_right = 0 if is_me else 15
	panel.add_theme_stylebox_override("panel", style)
	msg_vbox.add_child(panel)
	
	if is_me:
		root_hbox.add_child(msg_vbox)
	else:
		root_hbox.add_child(avatar_margin)
		root_hbox.add_child(msg_vbox)
		
	return {"root": row_margin, "panel": panel}

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

# BUTTONS

func _on_skip_scene_btn_pressed() -> void:
	typing_sound.stop()
	current_scene += 1
	
	if current_scene < dialogs.size():
		play_scene(current_scene)
	else:
		_on_skip_all_btn_pressed()

func _on_skip_all_btn_pressed() -> void:
	typing_sound.stop()
	current_scene = 999 
	PlayerStats.intro_seen = true
	PlayerStats.save_game() 
	get_tree().change_scene_to_file("res://scenes/maps/gym_map.tscn")
	
func _add_blocked_notice() -> void:
	var label = Label.new()
	label.text = "You have blocked this user."
	label.add_theme_font_override("font", custom_font)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(label)
	
	chat_container.add_child(margin)
