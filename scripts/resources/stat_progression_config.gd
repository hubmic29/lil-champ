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

@export_group("Muscle exhaustion")
## Exhaustion scale per muscle (0 = fresh, this value = fully wrecked).
@export var max_exhaustion := 100.0
## XP effectiveness lost at full exhaustion (0.8 = trains at 20% when wrecked).
@export var exhaustion_xp_penalty := 0.8
## Exhaustion healed on every muscle by one rest day.
@export var rest_day_exhaustion_heal := 60.0

@export_group("Day schedule")
## Machine/sauna sessions allowed per training day at overall level 1.
@export var sessions_per_day := 4
## One extra daily session per this many overall levels (0 disables scaling).
@export var overall_levels_per_extra_session := 3
## Ceiling on the level-based bonus sessions.
@export var max_bonus_sessions := 4

@export_group("Overall level")
## How many total stat levels are needed per overall level.
@export var levels_per_overall_level := 3
## Title shown for each overall level (index 0 = level 1). Levels beyond
## the list reuse the last name.
@export var level_names: Array[String] = [
	"Couch Potato", "Sofa Warrior", "Fresh Meat", "Gym Newbie",
	"Rookie", "Regular", "Grinder", "Athlete", "Bodybuilder",
	"Beast", "Mass Monster", "Absolute Unit",
]
## Overall level at which each character form (sprite) unlocks.
@export var form_overall_levels: Array[int] = [1, 5, 10]
