extends CanvasLayer

@onready var exp_label: Label = $StatsPanel/EXPLabel
@onready var str_label: Label = $StatsPanel/STRLabel
@onready var end_label: Label = $StatsPanel/ENDLabel
@onready var agi_label: Label = $StatsPanel/AGILabel
@onready var dex_label: Label = $StatsPanel/DEXLabel

func _process(_delta: float) -> void:
	exp_label.text = "EXP:  " + str(GlobalStats.player_exp)
	str_label.text = "STR:  " + str(GlobalStats.strength_STR)
	end_label.text = "END:  " + str(GlobalStats.endurance_END)
	agi_label.text = "AGI:  " + str(GlobalStats.agility_AGI)
	dex_label.text = "DEX:  " + str(GlobalStats.dexterity_DEX)
