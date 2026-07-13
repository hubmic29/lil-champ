## Tuning for the treadmill run minigame (trains Stamina).
class_name TreadmillConfig
extends ExerciseConfig

## Meters gained per correct alternating stride.
@export var stride_length := 2.0
## Meters of belt distance per XP reward.
@export var meters_per_reward := 20.0
## Pace added per stride (the pace bar goes 0..100).
@export var pace_per_stride := 9.0
## Pace lost per second while not striding.
@export var pace_decay := 14.0
## Extra XP multiplier granted at a full pace bar.
@export var pace_bonus := 0.75
## Extra XP fraction per reward already earned this session.
@export var xp_growth_per_reward := 0.1
