## Tuning for the squats balance minigame (trains Quadriceps).
class_name SquatsConfig
extends ExerciseConfig

## Random wobble force at the start of a session (units of balance/s²).
@export var instability_start := 0.6
## Instability added per second while balancing (difficulty ramp over time).
@export var instability_gain_per_second := 0.03
## Instability added after every completed rep.
@export var instability_gain_per_rep := 0.25
## Ceiling for instability, so the wobble never outgrows what the player can
## counter no matter how long the set runs.
@export var instability_max := 2.5
## How strongly A/D (or Left/Right) corrects the balance, per second.
@export var correction_strength := 1.6
## Cap on the wobble's drift speed, as a fraction of correction_strength.
## Must stay below 1.0 or the marker becomes impossible to steer back.
@export var max_drift_fraction := 0.65
## How quickly the drift bleeds off on its own, per second (exponential).
@export var drift_damping := 0.8
## Half-width of the success zone, as a fraction of the meter (0..1).
@export var success_zone := 0.22
## Seconds the marker must stay in the zone to complete one rep.
@export var hold_time_per_rep := 2.5
## How fast rep progress decays while outside the zone (1.0 = realtime).
@export var hold_decay := 1.5
## Extra XP fraction per completed rep (later reps are worth more).
@export var xp_growth_per_rep := 0.1
