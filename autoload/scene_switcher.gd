## SceneSwitcher (autoload) — smooth fade-to-black scene transitions.
## Use SceneSwitcher.change_scene(path) anywhere instead of
## get_tree().change_scene_to_file(path).

extends CanvasLayer


const FADE_OUT_SECONDS := 0.2
const FADE_IN_SECONDS := 0.3

var _rect: ColorRect
var _busy := false
var player_return_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func change_scene(path: String, pos: Vector2 = Vector2.ZERO) -> void:
	if _busy:
		return
	if pos != Vector2.ZERO:
		player_return_position = pos
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # swallow clicks mid-fade
	var fade_out := create_tween()
	fade_out.tween_property(_rect, "color:a", 1.0, FADE_OUT_SECONDS)
	await fade_out.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame  # let the new scene enter the tree
	var fade_in := create_tween()
	fade_in.tween_property(_rect, "color:a", 0.0, FADE_IN_SECONDS)
	await fade_in.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	
var map_scene = preload("res://ui/world_map.tscn")
var map_instance = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_minimap"):
		if map_instance == null:
			map_instance = map_scene.instantiate()
			add_child(map_instance)
			get_tree().paused = true
		else:
			map_instance.queue_free()
			map_instance = null
			get_tree().paused = false
		
		get_viewport().set_input_as_handled()
