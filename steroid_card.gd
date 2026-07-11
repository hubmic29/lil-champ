extends VBoxContainer

@export var type: String = "basic"
@export var cost: int = 200
@export var days: int = 1
@export var xp: float = 1.1
@export var energy: float = 0.9
@export var bottle_texture: Texture2D

@onready var texture_button = $PanelContainer/TextureButton
@onready var info_label = $InfoLabel
@onready var label_2 = $Label2

func _ready():
	label_2.text = "BUY"
	label_2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	texture_button.pivot_offset = texture_button.size / 2
	
	if bottle_texture:
		texture_button.texture_normal = bottle_texture
	
	texture_button.pressed.connect(_on_buy_pressed)
	texture_button.mouse_entered.connect(_on_mouse_entered)
	texture_button.mouse_exited.connect(_on_mouse_exited)
	
	
	info_label.size = Vector2(100, 50)
	info_label.text = "DAY : %d  |  XP : x%.1f  |  ENERGY : %.1f" % [days, xp, energy]
	info_label.hide()

func _on_mouse_entered():
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(texture_button, "scale", Vector2(1.2, 1.2), 0.2)
	info_label.show()

func _on_mouse_exited():
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(texture_button, "scale", Vector2(1.0, 1.0), 0.2)
	info_label.hide()

func _on_buy_pressed():
	var shop = get_tree().root.find_child("SteroidShop", true, false)
	if shop:
		shop.buy_steroid(type, cost, days, xp, energy)
