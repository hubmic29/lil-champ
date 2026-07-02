extends Control
@onready var training_screen: Control = $"."
@onready var background_belt: ColorRect = $BackgroundBelt


@onready var sweet_spot = $BackgroundBelt/SweetSpot
@onready var wskaznik = $BackgroundBelt/Wskaznik
@onready var komunikat_label = $KomunikatLabel
@onready var stats_label = $StatsLabel
@onready var powrot_button = $PowrotButton

# Zmienne mechaniki suwaka
var predkosc: float = 400.0
var kierunek: int = 1

# Statystyki gracza (zgodnie z GDD)
var punkty_exp: int = 0

func _ready() -> void:
	# Czyszczenie tekstów na start
	komunikat_label.text = "Naciśnij SPACJĘ w zielonej strefie!"
	aktualizuj_statystyki()
	
	# Podłączamy kliknięcie przycisku powrotu
	powrot_button.text = "Wróć na siłownię"
	powrot_button.pressed.connect(_on_powrot_pressed)

func _process(delta: float) -> void:
	# 1. RUCH WSKAŹNIKA
	wskaznik.position.x += predkosc * kierunek * delta
	
	# Odbijanie od krawędzi paska
	if wskaznik.position.x >= background_belt.size.x:
		kierunek = -1
	elif wskaznik.position.x <= 0:
		kierunek = 1
		
	# 2. KLIKNIĘCIE SPACJI
	if Input.is_action_just_pressed("ui_accept"): # Domyślnie SPACJA
		sprawdz_trafienie()

func sprawdz_trafienie() -> void:
	var x_wsk = wskaznik.position.x
	var x_zielony_start = sweet_spot.position.x
	var x_zielony_koniec = sweet_spot.position.x + sweet_spot.size.x
	
	# Sprawdzanie czy wskaźnik jest w zielonym prostokącie
	if x_wsk >= x_zielony_start and x_wsk <= x_zielony_koniec:
		var srodek = x_zielony_start + (sweet_spot.size.x / 2.0)
			
			# Trafienie idealnie w środek (margines 15 pikseli)
		if abs(x_wsk - srodek) < 15.0:
			komunikat_label.text = "Juice! PERFECT! (+200% EXP)"
			punkty_exp += 20
		else:
			komunikat_label.text = "GOOD! (+100% EXP)"
			punkty_exp += 10
			
		# Jeśli wskaźnik był całkowicie poza zieloną strefą:
		if not (x_wsk >= x_zielony_start and x_wsk <= x_zielony_koniec):
			komunikat_label.text = "MISS! Postać się potknęła..."
			# Tutaj w przyszłości odejmiemy staminę
			
		aktualizuj_statystyki()

func aktualizuj_statystyki() -> void:
	stats_label.text = "Zdobyty EXP: " + str(punkty_exp)

func _on_powrot_pressed() -> void:
	# Powrót do głównej mapy siłowni
	get_tree().change_scene_to_file("res://scenes/test/test_map.tscn")
