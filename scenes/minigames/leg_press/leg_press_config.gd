## Tuning for the leg press minigame (trains Quadriceps).
class_name LegPressConfig
extends ExerciseConfig

## Sled speed while pushing, in % of the rail per second, at the start.
@export var push_speed_start := 45.0
## Sled speed gained per rep and the fastest the sled can get — a faster
## sled makes the release window pass quicker.
@export var push_speed_gain_per_rep := 5.0
@export var push_speed_max := 110.0
## Sled slide-back speed while not pushing, in %/s.
@export var return_speed := 80.0
## The green release band on the rail, in percent.
@export var zone_start := 76.0
## Pushing past this while still holding locks the knees and fails the rep.
@export var lockout_start := 94.0
## Extra XP fraction per completed rep.
@export var xp_growth_per_rep := 0.1
