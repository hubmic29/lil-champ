## Tuning for the crunches minigame (trains Abdominals).
class_name CrunchesConfig
extends ExerciseConfig

## Fastest allowed half-rep, in seconds; pressing sooner is sloppy form.
@export var min_interval := 0.25
## Slowest half-rep that still keeps the tempo streak alive, in seconds.
@export var max_interval := 1.6
## Tempo streak bonus per rep and its cap.
@export var streak_bonus := 0.06
@export var max_streak_for_bonus := 10
## Extra XP fraction per completed rep.
@export var xp_growth_per_rep := 0.1
