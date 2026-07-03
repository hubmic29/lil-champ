## Reusable floating text label (XP numbers, "PERFECT!", level-ups...).
## Spawns, drifts upward while fading out, then frees itself.
class_name FloatingText
extends Label


## Creates and animates a floating label. `at` is in `parent` local space.
static func spawn(parent: Node, text_value: String, at: Vector2,
		color := Color.WHITE, font_size := 20) -> void:
	var label := FloatingText.new()
	label.text = text_value
	label.position = at
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	parent.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(
		label, "position", at + Vector2(randf_range(-24, 24), -70), 0.9
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
