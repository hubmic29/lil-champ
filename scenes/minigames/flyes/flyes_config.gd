## Tuning for the dumbbell flyes minigame (trains Chest).
class_name FlyesConfig
extends ExerciseConfig

## How fast the arms rise while the key is held, in % of the arc per second.
@export var raise_speed := 55.0
## How fast the arms drop back down after releasing, in %/s.
@export var lower_speed := 120.0
## The green release window on the arc, in percent. The start creeps toward
## the end as reps accumulate (see zone_shrink_per_rep).
@export var zone_start := 68.0
@export var zone_end := 92.0
## How much the window shrinks after each rep, and the narrowest it can get.
@export var zone_shrink_per_rep := 2.0
@export var zone_min_width := 8.0
## Extra XP fraction per completed rep.
@export var xp_growth_per_rep := 0.1
