## Tuning for the punching bag minigame (trains Stamina / Conditioning).
class_name PunchingBagConfig
extends ExerciseConfig

## Diameter of the clickable hit zone, in pixels.
@export var target_size := 56.0
## How long a hit zone stays up before it counts as a miss, in seconds.
@export var target_lifetime := 2.0
## Lower bound for the lifetime once the combo shortens it.
@export var target_lifetime_min := 0.7
## Seconds shaved off the lifetime per combo step (difficulty ramp).
@export var target_lifetime_decay := 0.05
## Extra XP fraction per combo step (0.05 = +5% per hit in a row).
@export var combo_bonus := 0.05
## Combo steps that keep granting a bonus (caps the multiplier).
@export var max_combo_for_bonus := 20
