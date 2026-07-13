
##
## Extends BaseExercise only for the shared plumbing (fade-in, Back/Escape,
## energy readout); it has no ExerciseConfig and awards no XP by itself.
## The inventory lives in shop.tres (ShopConfig with ShopItem entries).
extends BaseExercise

@export var shop_config: ShopConfig

@onready var money_label: Label = %MoneyLabel
@onready var items_box: VBoxContainer = %ItemsBox
@onready var message_label: Label = %MessageLabel

var _buy_buttons := {}


func _ready() -> void:
	super()
	_build_item_rows()
	PlayerStats.money_changed.connect(func(_m: int) -> void: _refresh())
	_refresh()


func _build_item_rows() -> void:
	for item in shop_config.items:
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		row.add_child(hbox)

		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.text = item.item_name
		name_label.add_theme_font_size_override("font_size", 18)
		text_box.add_child(name_label)
		var desc_label := Label.new()
		desc_label.text = item.description
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(desc_label)
		hbox.add_child(text_box)

		var price_label := Label.new()
		price_label.text = "$ %d" % item.price
		price_label.add_theme_font_size_override("font_size", 18)
		price_label.add_theme_color_override("font_color", Color(0.65, 0.95, 0.55))
		price_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(price_label)

		var buy := Button.new()
		buy.text = "Buy"
		buy.custom_minimum_size = Vector2(80, 0)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.pressed.connect(_buy.bind(item))
		hbox.add_child(buy)
		_buy_buttons[item] = buy
		items_box.add_child(row)


func _buy(item: ShopItem) -> void:
	if not PlayerStats.spend_money(item.price):
		AudioManager.play(&"miss")
		message_label.text = "Not enough money — win a competition first!"
		return
	AudioManager.play(&"good")
	match item.effect:
		ShopItem.Effect.RESTORE_ENERGY:
			PlayerStats.restore_energy(item.magnitude)
			message_label.text = "%s consumed: +%d energy!" % [item.item_name, int(item.magnitude)]
		ShopItem.Effect.MOTIVATION_BUFF:
			PlayerStats.apply_motivation_buff(item.duration)
			message_label.text = "%s kicks in: bonus XP for %d min!" % [item.item_name, int(item.duration / 60.0)]
		ShopItem.Effect.INSTANT_XP_ALL_STATS:
			_grant_xp_all_stats(item.magnitude)
			message_label.text = "%s absorbed: +%d XP to every muscle!" % [item.item_name, int(item.magnitude)]
	FloatingText.spawn(self, "-$%d" % item.price,
		Vector2(size.x / 2.0, 120), Color(0.65, 0.95, 0.55), 24)
	PlayerStats.save_game()


func _grant_xp_all_stats(amount: float) -> void:
	for stat in PlayerStats.STATS:
		PlayerStats.add_xp(stat, amount)


func _refresh() -> void:
	money_label.text = "Your wallet: $ %d" % PlayerStats.money
	for item in _buy_buttons:
		_buy_buttons[item].disabled = PlayerStats.money < item.price
