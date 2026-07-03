## Balancing resource for the whole progression system.
## Edit res://resources/progression.tres in the Inspector to retune the game
## without touching any code.
class_name StatProgressionConfig
extends Resource

@export_group("Stat levelling")
## XP needed to reach level 2. Each further level costs `level_growth` times more.
@export var base_xp_to_level := 100.0
## Multiplier applied to the XP requirement per level (exponential curve).
@export_range(1.0, 2.0, 0.01) var level_growth := 1.15

@export_group("Soft cap / diminishing returns")
## From this stat level onward, XP gain starts to shrink.
@export var soft_cap_level := 20
## How aggressively XP gain shrinks per level past the soft cap.
@export var soft_cap_falloff := 0.15

@export_group("XP multipliers")
## Global tuning knob applied to every XP grant.
@export var global_xp_multiplier := 1.0
## XP bonus while the sauna motivation buff is active.
@export var motivation_xp_multiplier := 1.25
## XP penalty when energy falls to/below `tired_threshold`.
@export var tired_xp_multiplier := 0.5

@export_group("Energy")
@export var max_energy := 100.0
## At or below this energy XP gain is penalized (see tired_xp_multiplier).
@export var tired_threshold := 20.0
## How much each Stamina level stretches the energy pool: exercise energy
## costs are multiplied by 1 / (1 + (stamina_level - 1) * this). At the
## default 0.15, Stamina 5 already makes training ~38% cheaper.
@export var stamina_energy_efficiency := 0.15

@export_group("Gym level & evolution")
## How many total stat levels are needed per overall Gym Level.
@export var levels_per_gym_level := 3
## Character forms, weakest to strongest. Must match evolution_gym_levels.
@export var evolution_tiers: Array[String] = [
	"Couch Potato", "Rookie", "Athlete", "Beast", "Absolute Unit",
]
## Gym Level required to reach each tier above.
@export var evolution_gym_levels: Array[int] = [1, 3, 7, 12, 20]
