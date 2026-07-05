extends Control

var obroty = 0
var oryginalna_skala = Vector2.ONE # Zmienna do zapamiętania początkowego rozmiaru

func _ready():
	# Zapisujemy oryginalną wielkość przy uruchomieniu gry, żeby do niej wracać
	oryginalna_skala = $AnimatedSprite2D.scale
	$AnimatedSprite2D.play("s_spin")




func _on_animated_sprite_2d_animation_looped():
	obroty += 1
	
	# Kiedy skończą się 2 obroty
	if obroty == 2:
		obroty = 0 # Zerujemy licznik dla kolejnego etapu
		
		var tween = get_tree().create_tween()
		
		# Etap 1 -> Etap 2 (Średnia forma)
		if $AnimatedSprite2D.animation == "s_spin":
			$AnimatedSprite2D.play("m_spin")
			$AnimatedSprite2D.scale = oryginalna_skala * 0.7 # Chwilowe skurczenie
			# Powiększenie do 1.3
			tween.tween_property($AnimatedSprite2D, "scale", oryginalna_skala * 1.3, 0.6).set_trans(Tween.TRANS_BOUNCE)
			
		# Etap 2 -> Etap 3 (Absolutny Dzik)
		elif $AnimatedSprite2D.animation == "m_spin":
			$AnimatedSprite2D.play("l_spin")
			$AnimatedSprite2D.scale = oryginalna_skala * 1.0 # Chwilowe skurczenie
			# Potężne powiększenie do 1.8
			tween.tween_property($AnimatedSprite2D, "scale", oryginalna_skala * 1.8, 0.6).set_trans(Tween.TRANS_BOUNCE)
			
		# Etap 3 -> Powrót do Etapu 1 (Reset)
		elif $AnimatedSprite2D.animation == "l_spin":
			$AnimatedSprite2D.play("s_spin")
			# Płynne, łagodniejsze skurczenie z powrotem do oryginalnego rozmiaru
			tween.tween_property($AnimatedSprite2D, "scale", oryginalna_skala, 0.5).set_trans(Tween.TRANS_SINE)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/gym_map.tscn")


func _on_button_4_pressed() -> void:
	get_tree().quit()
