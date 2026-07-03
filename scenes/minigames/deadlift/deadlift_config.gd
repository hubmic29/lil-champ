## Tuning for the deadlift minigame (trains Back & Hamstrings).
class_name DeadliftConfig
extends ExerciseConfig

## Indicator speed at the start of a session, in pixels per second.
@export var indicator_speed_start := 380.0
## Speed added after every successful lift (difficulty ramp).
@export var indicator_speed_gain := 30.0
## Width of the "Good" timing zone, in pixels.
@export var good_zone_width := 110.0
## Width of the "Perfect" zone inside the good zone, in pixels.
@export var perfect_zone_width := 30.0
## XP multiplier for a Perfect lift (Good grants 1.0).
@export var perfect_multiplier := 2.0
## Cosmetic starting weight shown on the label, in kg.
@export var starting_weight := 100.0
## Weight added per successful lift, in kg.
@export var weight_per_success := 10.0
