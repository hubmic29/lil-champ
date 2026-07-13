## One purchasable shop item (nutrient, supplement, steroid...).
## Items are data-only; the shop scene applies the effect via PlayerStats.
class_name ShopItem
extends Resource

enum Effect {
	RESTORE_ENERGY,       ## magnitude = energy points restored
	MOTIVATION_BUFF,      ## duration = buff length in seconds
	INSTANT_XP_ALL_STATS, ## magnitude = XP granted to every stat
}

@export var item_name := ""
@export_multiline var description := ""
@export var price := 10
@export var effect: Effect = Effect.RESTORE_ENERGY
@export var magnitude := 0.0
@export var duration := 0.0
