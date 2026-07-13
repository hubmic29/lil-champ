## Tuning for the leg curl minigame (trains Hamstrings).
class_name LegCurlConfig
extends ExerciseConfig

## Seconds per metronome beat at the start of a set.
@export var beat_period_start := 1.4
## Seconds shaved off the period per successful curl, and the fastest beat.
@export var beat_period_step := 0.05
@export var beat_period_min := 0.7
## Fraction of the beat period around each beat that counts as on time.
@export var timing_window := 0.18
## Combo bonus per consecutive on-beat curl, and its cap.
@export var combo_bonus := 0.05
@export var max_combo_for_bonus := 10
## Extra XP fraction per completed rep.
@export var xp_growth_per_rep := 0.08
