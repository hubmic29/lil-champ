extends Control

@onready var main_music: AudioStreamPlayer = $MainMusic
@onready var grow_sound: AudioStreamPlayer = $GrowSound
@onready var shrink_sound: AudioStreamPlayer = $ShrinkSound
@onready var red_dot: ColorRect = $RedDot

var obroty = 0
var oryginalna_skala = Vector2.ONE

func _ready():
	oryginalna_skala = $AnimatedSprite2D.scale
	$AnimatedSprite2D.play("s_spin")
	main_music.play()
	
	if red_dot != null:
		var dot_tween = create_tween().set_loops()
		
		dot_tween.tween_property(red_dot, "modulate:a", 0.0, 0.5)
		dot_tween.tween_property(red_dot, "modulate:a", 1.0, 0.5)

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
	get_tree().change_scene_to_file("res://scenes/maps/gym_map.tscn")


func _on_button_4_pressed() -> void:
	get_tree().quit()
