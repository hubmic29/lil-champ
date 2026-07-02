extends Area2D

# Ta linijka pozwoli Ci łatwo wybrać scenę minigierki w oknie edytora!
var sciezka_do_minigierki: String = "res://scenes/test/training_screen.tscn"

var gracz_w_zasiegu: bool = false

func _ready() -> void:
	# Podłączamy wbudowane sygnały Godota, które wykrywają wejście i wyjście obiektów
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Jeśli gracz jest blisko I wcisnął klawisz E (czyli naszą "interakcję")
	if gracz_w_zasiegu and Input.is_action_just_pressed("iteraction"):
		odpal_minigierke()

func _on_body_entered(body: Node2D) -> void:
	# Sprawdzamy, czy obiekt, który wszedł w strefę, nazywa się "Gracz"
	if body.name == "Player":
		gracz_w_zasiegu = true
		print("Gracz w zasięgu! Naciśnij E, aby trenować.")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		gracz_w_zasiegu = false
		print("Gracz wyszedł z zasięgu.")

func odpal_minigierke() -> void:
	if sciezka_do_minigierki != "":
		# Zmiana sceny na minigierkę treningową
		get_tree().change_scene_to_file(sciezka_do_minigierki)
	else:
		print("BŁĄD: Nie przypisałeś sceny minigierki w Inspectorze!")
