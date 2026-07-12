extends CanvasLayer

func _ready() -> void:
	# Podpinamy sygnały dla wszystkich stref (Area2D) znajdujących się w TextureRect
	for child in $TextureRect.get_children():
		if child is Area2D:
			child.mouse_entered.connect(_on_zone_entered.bind(child))
			child.mouse_exited.connect(_on_zone_exited.bind(child))
			
			# Upewnij się, że HighLight i Label są ukryte na start
			var hl = child.get_node_or_null("HighLight")
			if hl: hl.modulate.a = 0.0
			
			# Znajdź odpowiedni label (np. GymZone -> GymLabel)
			var label_name = child.name.replace("Zone", "Label")
			var label = child.get_node_or_null("../" + label_name)
			if label: label.visible = false

func _on_zone_entered(zone_node: Area2D) -> void:
	# Podświetlenie (HighLight wewnątrz strefy)
	var hl = zone_node.get_node_or_null("HighLight")
	if hl: hl.modulate.a = 0.5 
	
	# Napis (GymLabel wewnątrz WorldMap)
	var label_name = zone_node.name.replace("Zone", "Label")
	var label = zone_node.get_parent().get_node_or_null(label_name)
	if label:
		label.visible = true
		label.text = zone_node.name.replace("Zone", "")

func _on_zone_exited(zone_node: Area2D) -> void:
	# Wyłączenie podświetlenia
	var hl = zone_node.get_node_or_null("HighLight")
	if hl: hl.modulate.a = 0.0
	
	# Wyłączenie napisu
	var label_name = zone_node.name.replace("Zone", "Label")
	var label = zone_node.get_parent().get_node_or_null(label_name)
	if label: label.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_minimap"):
		# 1. Odpałzuj grę
		get_tree().paused = false 
		
		# 2. Oznacz zdarzenie jako obsłużone
		get_viewport().set_input_as_handled()
		
		# 3. Usuń mapę
		queue_free()
