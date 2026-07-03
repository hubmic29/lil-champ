## SceneSwitcher (autoload) — smooth fade-to-black scene transitions.
## Use SceneSwitcher.change_scene(path) anywhere instead of
## get_tree().change_scene_to_file(path).
extends CanvasLayer

const FADE_OUT_SECONDS := 0.2
const FADE_IN_SECONDS := 0.3

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func change_scene(path: String) -> void:
	if _busy:
		return
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
