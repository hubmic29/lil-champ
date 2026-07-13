## Tuning for the pull-up bar minigame (trains Back).
class_name PullUpsConfig
extends ExerciseConfig

## Climb speed while holding, in % of the bar height per second.
@export var pull_speed_start := 70.0
## Climb speed lost per completed rep (arm fatigue).
@export var pull_speed_loss_per_rep := 4.0
## The slowest the pull can ever get — keeps the bar always reachable.
@export var pull_speed_min := 30.0
## Descent speed while hanging (key released), in %/s.
@export var drop_speed := 90.0
## Extra XP fraction per completed rep.
@export var xp_growth_per_rep := 0.1
