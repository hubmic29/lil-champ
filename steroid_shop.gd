extends Control

@onready var btn_basic = $Panel/BasicTextureButton 
@onready var btn_pro = $Panel/ProTextureButton
@onready var btn_god = $Panel/GodTextureButton
@onready var exit_button = $"Panel/ExitButton"
@onready var stat_display = get_node_or_null("StatDisplay")

func _ready():
	if stat_display == null:
		print("UWAGA: Nie znalazłem StatDisplay. Sprawdź nazwę w drzewie!")
	else:
		print("Sukces! StatDisplay znaleziony.")
	btn_basic.pressed.connect(_on_buy_button_pressed.bind("basic"))
	btn_pro.pressed.connect(_on_buy_button_pressed.bind("pro"))
	btn_god.pressed.connect(_on_buy_button_pressed.bind("god"))
	exit_button.pressed.connect(_on_exit_button_pressed)
	btn_basic.mouse_exited.connect(func(): if stat_display: stat_display.hide())
	_sort_cards_by_price()


## Rearranges the steroid cards left-to-right from cheapest to most expensive.
## Sorting happens at render time, so cards added to the scene later stay
## sorted automatically.
func _sort_cards_by_price() -> void:
	var cards: Array = []
	for child in $Panel.get_children():
		if "cost" in child and "bottle_texture" in child:
			cards.append(child)
	var slots: Array = cards.map(func(c): return c.position.x)
	slots.sort()
	cards.sort_custom(func(a, b): return a.cost < b.cost)
	for i in cards.size():
		cards[i].position.x = slots[i]

func _on_buy_button_pressed(type: String):
	var stats = {}
	match type:
		"basic": stats = {"cost": 50, "days": 1, "xp": 1.1, "energy": 0.9}
		"pro":   stats = {"cost": 100, "days": 3, "xp": 1.3, "energy": 0.7}
		"god":   stats = {"cost": 200, "days": 7, "xp": 1.5, "energy": 0.5}

	# spend_money automatycznie sprawdza czy stać gracza i aktualizuje HUD
	if PlayerStats.spend_money(stats.cost):
		PlayerStats.apply_steroids(type, stats.days, stats.xp, stats.energy)
	else:
		_show_no_money(stats.cost)
		
func _on_exit_button_pressed():
	SceneSwitcher.change_scene("res://scenes/maps/gym_map.tscn")
	
func show_stats(text):
	if stat_display:
		stat_display.text = text
		stat_display.show()
	
func buy_steroid(type, cost, days, xp, energy):
	# Analogicznie tutaj naprawiamy potrącanie gotówki
	if PlayerStats.spend_money(cost):
		PlayerStats.apply_steroids(type, days, xp, energy)
		AudioManager.play(&"good")
		SceneSwitcher.change_scene("res://scenes/maps/gym_map.tscn")
	else:
		_show_no_money(cost)


func _show_no_money(cost: int) -> void:
	AudioManager.play(&"miss")
	FloatingText.spawn(
		self,
		"Not enough money! Need $%d, you have $%d" % [cost, PlayerStats.money],
		Vector2(size.x / 2.0 - 220, size.y / 2.0),
		Color(1.0, 0.45, 0.45),
		24
	)
