## PlayerStats (autoload) — single source of truth for player progression.
##
## Holds per-stat XP and levels, the derived overall Gym Level, the current
## evolution tier, an energy pool and the temporary sauna "motivation" buff.
## All balancing numbers live in a [StatProgressionConfig] resource
## (res://resources/progression.tres) so the game can be tuned without code.
##
## Other systems interact with it exclusively through methods and signals —
## never by writing fields directly.
extends Node

## Emitted whenever XP is added to a stat (amount is after all multipliers).
signal xp_gained(stat: StringName, amount: float)
## Emitted when a stat reaches a new level.
signal stat_leveled_up(stat: StringName, new_level: int)
## Emitted when the overall Gym Level changes.
signal gym_level_changed(new_level: int)
## Emitted when the character evolves into a new form/tier.
signal evolution_changed(tier_index: int, tier_name: String)
## Emitted when the energy pool changes.
signal energy_changed(value: float, max_value: float)
## Emitted when the motivation buff turns on or off.
signal motivation_changed(active: bool)

const SAVE_PATH := "user://lil_champ_save.json"
const PROGRESSION_PATH := "res://resources/progression.tres"

## Every trainable stat. To add a new stat, append it here — exercises grant
## XP by name through their ExerciseConfig resources, so nothing else changes.
const STATS: Array[StringName] = [
	&"strength",
	&"chest",
	&"back",
	&"quadriceps",
	&"hamstrings",
	&"stamina",
]

## Balancing resource (XP curves, soft caps, evolution thresholds...).
var progression: StatProgressionConfig

## Per-stat XP progress *inside* the current level.
var xp := {}
## Per-stat level, starting at 1.
var levels := {}
## Energy pool; exercises drain it, the sauna restores it. Being exhausted
## reduces XP gain (see StatProgressionConfig.tired_xp_multiplier).
var energy := 100.0
## Overall progression derived from the sum of all stat levels.
var gym_level := 1
## Index into progression.evolution_tiers (character form).
var evolution_tier := 0

## Motivation buff expiry in msec ticks (-1 = never had one).
var _buff_ends_at_msec := -1


func _ready() -> void:
	progression = load(PROGRESSION_PATH)
	if progression == null:
		push_warning("PlayerStats: progression resource missing, using defaults.")
		progression = StatProgressionConfig.new()
	for stat in STATS:
		xp[stat] = 0.0
		levels[stat] = 1
	energy = progression.max_energy
	load_game()
	_refresh_overall_progress(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# ---------------------------------------------------------------------------
# XP & levelling
# ---------------------------------------------------------------------------

## Grants XP to a stat. Applies global, soft-cap, motivation and fatigue
## multipliers, handles level-ups and returns the amount actually gained.
func add_xp(stat: StringName, base_amount: float) -> float:
	if not STATS.has(stat) or base_amount <= 0.0:
		return 0.0
	var amount := base_amount \
		* progression.global_xp_multiplier \
		* _soft_cap_multiplier(levels[stat]) \
		* (progression.motivation_xp_multiplier if is_motivated() else 1.0) \
		* (progression.tired_xp_multiplier if energy <= progression.tired_threshold else 1.0)
	xp[stat] += amount
	xp_gained.emit(stat, amount)
	while xp[stat] >= xp_required(levels[stat]):
		xp[stat] -= xp_required(levels[stat])
		levels[stat] += 1
		stat_leveled_up.emit(stat, levels[stat])
	_refresh_overall_progress()
	return amount


## XP needed to go from `level` to `level + 1`.
func xp_required(level: int) -> float:
	return progression.base_xp_to_level * pow(progression.level_growth, level - 1)


## Diminishing returns: past the soft cap every extra level makes XP gain
## progressively smaller, so no single stat can be grinded forever.
func _soft_cap_multiplier(level: int) -> float:
	if level < progression.soft_cap_level:
		return 1.0
	return 1.0 / (1.0 + (level - progression.soft_cap_level + 1) * progression.soft_cap_falloff)


## Recomputes Gym Level (from total stat levels) and the evolution tier.
func _refresh_overall_progress(silent := false) -> void:
	var total_levels := 0
	for stat in STATS:
		total_levels += int(levels[stat])
	var new_gym_level := 1 + (total_levels - STATS.size()) / progression.levels_per_gym_level
	if new_gym_level != gym_level:
		gym_level = new_gym_level
		if not silent:
			gym_level_changed.emit(gym_level)
	var new_tier := 0
	for i in progression.evolution_gym_levels.size():
		if gym_level >= progression.evolution_gym_levels[i]:
			new_tier = i
	if new_tier != evolution_tier:
		evolution_tier = new_tier
		if not silent:
			evolution_changed.emit(evolution_tier, evolution_tier_name())


func evolution_tier_name() -> String:
	if progression.evolution_tiers.is_empty():
		return "?"
	return progression.evolution_tiers[clampi(evolution_tier, 0, progression.evolution_tiers.size() - 1)]


# ---------------------------------------------------------------------------
# Energy & motivation buff
# ---------------------------------------------------------------------------

func spend_energy(amount: float) -> void:
	energy = clampf(energy - amount, 0.0, progression.max_energy)
	energy_changed.emit(energy, progression.max_energy)


## Spends energy for a training action, scaled by Stamina: conditioning makes
## the same workout cheaper, so the energy pool lasts longer as you progress.
func spend_exercise_energy(base_cost: float) -> void:
	spend_energy(base_cost * exercise_cost_multiplier())


## Energy cost multiplier derived from the Stamina level (asymptotic, so it
## never reaches zero). Level 1 = 1.0 (drains very fast on a fresh character).
func exercise_cost_multiplier() -> float:
	return 1.0 / (1.0 + (levels[&"stamina"] - 1) * progression.stamina_energy_efficiency)


## Completely out of energy — no more training until the player recovers.
func is_exhausted() -> bool:
	return energy <= 0.0


func restore_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, progression.max_energy)
	energy_changed.emit(energy, progression.max_energy)


## Starts (or extends) the temporary motivation buff that boosts all XP gain.
func apply_motivation_buff(duration_seconds: float) -> void:
	_buff_ends_at_msec = Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	motivation_changed.emit(true)
	# Announce expiry so UI can react without polling.
	get_tree().create_timer(duration_seconds + 0.05).timeout.connect(
		func() -> void:
			if not is_motivated():
				motivation_changed.emit(false)
	)


func is_motivated() -> bool:
	return _buff_ends_at_msec > Time.get_ticks_msec()


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func save_game() -> void:
	var data := {
		"version": 1,
		"xp": {},
		"levels": {},
		"energy": energy,
	}
	for stat in STATS:
		data["xp"][String(stat)] = xp[stat]
		data["levels"][String(stat)] = levels[stat]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("PlayerStats: could not write save file.")
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("PlayerStats: save file corrupted, starting fresh.")
		return
	for stat in STATS:
		var key := String(stat)
		xp[stat] = float(data.get("xp", {}).get(key, 0.0))
		levels[stat] = int(data.get("levels", {}).get(key, 1))
	energy = clampf(float(data.get("energy", progression.max_energy)), 0.0, progression.max_energy)
