## Tuning for the bench press minigame (trains Chest).
class_name BenchPressConfig
extends ExerciseConfig

## Power added to the bar per key/mouse press (bar completes at 100).
@export var power_per_press := 9.0
## Power drained per second at the start of a session.
@export var initial_drain_speed := 16.0
## Extra drain per second added after every completed rep (difficulty ramp).
@export var drain_gain_per_rep := 2.5
## Cosmetic starting weight shown on the label, in kg.
@export var starting_weight := 60.0
## Weight added per completed rep, in kg.
@export var weight_per_rep := 10.0
## Extra XP fraction per completed rep (later reps are worth more).
@export var xp_growth_per_rep := 0.1
