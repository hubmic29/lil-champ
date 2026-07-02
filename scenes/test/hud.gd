extends CanvasLayer

@onready var exp_label = $ExpLabel

func _process(_delta: float) -> void:
	exp_label.text = "EXP: " + str(GlobalStats.player_exp)
