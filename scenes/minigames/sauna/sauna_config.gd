## Tuning for the sauna (recovery & social — no skill gameplay).
class_name SaunaConfig
extends ExerciseConfig

## Energy restored per second while sitting in the sauna.
@export var recovery_per_second := 4.0
## Seconds the player must stay before the motivation buff is granted.
@export var buff_after_seconds := 10.0
## How long the motivation XP buff lasts after it is granted, in seconds.
@export var buff_duration_seconds := 120.0
## Random small talk shown above the sauna friends.
@export var dialogue_lines: Array[String] = [
	"Leg day tomorrow... I can feel it already.",
	"They say the champ trains here.",
	"Pass the water bucket, will you?",
	"I benched my bodyweight today!",
	"This heat is doing wonders for my back.",
	"Protein shake after this?",
	"Don't skip cardio. That's all I'm saying.",
	"Ahh... this is the life.",
]
## Seconds between dialogue lines (random within this range).
@export var dialogue_interval_min := 4.0
@export var dialogue_interval_max := 8.0
