extends CharacterBody2D

@export var SPEED: float = 300.0

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	# Klasyczne, proste kierunki na ekranie
	if Input.is_key_pressed(KEY_D):  # Prawo
		input_vector.x += 1
	if Input.is_key_pressed(KEY_A):  # Lewo
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_S):  # Dół
		input_vector.y += 1
	if Input.is_key_pressed(KEY_W):  # Góra
		input_vector.y -= 1
		
	if input_vector != Vector2.ZERO:
		# Zabezpieczenie, żeby postać nie biegała szybciej na skosach
		velocity = input_vector.normalized() * SPEED
	else:
		# Zatrzymanie postaci po puszczeniu klawiszy
		velocity = Vector2.ZERO

	# Wykonanie klasycznego ruchu i obsługa kolizji ze ścianami
	move_and_slide()
