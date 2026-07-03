## Tuning for the squats balance minigame (trains Quadriceps).
class_name SquatsConfig
extends ExerciseConfig

## Random wobble force at the start of a session (units of balance/s²).
@export var instability_start := 0.6
## Instability added per second while balancing (difficulty ramp over time).
@export var instability_gain_per_second := 0.03
## Instability added after every completed rep.
@export var instability_gain_per_rep := 0.25
## How strongly A/D (or Left/Right) corrects the balance, per second.
@export var correction_strength := 1.6
## Half-width of the success zone, as a fraction of the meter (0..1).
@export var success_zone := 0.22
## Seconds the marker must stay in the zone to complete one rep.
@export var hold_time_per_rep := 2.5
## How fast rep progress decays while outside the zone (1.0 = realtime).
@export var hold_decay := 1.5
## Extra XP fraction per completed rep (later reps are worth more).
@export var xp_growth_per_rep := 0.1
