## Base configuration resource shared by every exercise.
## Concrete exercises extend this with their own tuning fields; each minigame
## folder under res://scenes/minigames/ holds its config script and .tres,
## so balancing never touches code.
class_name ExerciseConfig
extends Resource

@export var display_name := "Exercise"

## XP granted by one "perfect quality" action, before stat weights and
## quality multipliers are applied.
@export var base_xp := 10.0

## Which stats this exercise trains: stat name -> weight.
## e.g. {"back": 0.6, "hamstrings": 0.6} — each successful action grants
## base_xp * weight XP to that stat. Keys must exist in PlayerStats.STATS.
@export var stat_rewards: Dictionary = {}

## Energy drained from the player per successful action.
@export var energy_cost_per_action := 1.0

## Exhaustion added per successful action to each rewarded muscle, scaled by
## that muscle's stat_rewards weight. Tired muscles train less effectively.
@export var exhaustion_per_action := 0.0
