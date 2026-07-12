## PlayerStats (autoload) — single source of truth for player progression.
##
## Holds per-stat XP and levels, the derived overall level (each with its
## own title), the sprite form tier, an energy pool, per-muscle exhaustion
## and the temporary sauna "motivation" buff.
## All balancing numbers live in a [StatProgressionConfig] resource
## (res://resources/progression.tres) so the game can be tuned without code.
##
## Other systems interact with it exclusively through methods and signals —
## never by writing fields directly.
extends Node

signal steroids_changed
## Emitted whenever XP is added to a stat (amount is after all multipliers).
signal xp_gained(stat: StringName, amount: float)
## Emitted when a stat reaches a new level.
signal stat_leveled_up(stat: StringName, new_level: int)
## Emitted when the overall level changes (each level has its own title).
signal overall_level_changed(new_level: int, level_title: String)
## Emitted when the character evolves into a new sprite form.
signal evolution_changed(tier_index: int, tier_name: String)
## Emitted when the energy pool changes.
signal energy_changed(value: float, max_value: float)
## Emitted when the motivation buff turns on or off.
signal motivation_changed(active: bool)
## Emitted when the money balance changes.
signal money_changed(amount: int)
## Emitted when a muscle's exhaustion changes.
signal exhaustion_changed(stat: StringName, value: float)

const PROGRESSION_PATH := "res://resources/progression.tres"

## Every trainable stat. To add a new stat, append it here — exercises grant
## XP by name through their ExerciseConfig resources, so nothing else changes.
const STATS: Array[StringName] = [
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
## Per-muscle exhaustion (0..max_exhaustion). Training a muscle raises it and
## makes further XP on that muscle less effective; the sauna and rest days
## bring it back down.
var exhaustion := {}
## Energy pool; exercises drain it, the sauna restores it. Being exhausted
## reduces XP gain (see StatProgressionConfig.tired_xp_multiplier).
var energy := 100.0
## Overall progression level derived from the sum of all stat levels; each
## level has its own title (see StatProgressionConfig.level_names).
var overall_level := 1
## Character sprite form index (unlocked at form_overall_levels thresholds).
var evolution_tier := 0
## Cash earned in competitions, spent in the shop.
var money := 0

var intro_seen := false

## Motivation buff expiry in msec ticks (-1 = never had one).
var _buff_ends_at_msec := -1

var steroid_bonus_multiplier := 1.0 # Domyślnie 1.0 (brak bonusu)
var energy_reduction_multiplier := 1.0


var active_steroid_type := ""
var steroid_bonus := 1.0
var energy_reduction := 1.0
var steroid_expires_at := 0

func _ready() -> void:
	progression = load(PROGRESSION_PATH)
	if progression == null:
		push_warning("PlayerStats: progression resource missing, using defaults.")
		progression = StatProgressionConfig.new()
	for stat in STATS:
		xp[stat] = 0.0
		levels[stat] = 1
		exhaustion[stat] = 0.0
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
		* exhaustion_effectiveness(stat) \
		* (progression.motivation_xp_multiplier if is_motivated() else 1.0) \
		* (progression.tired_xp_multiplier if energy <= progression.tired_threshold else 1.0)\
		* steroid_bonus
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


## Recomputes the overall level (from total stat levels) and the sprite form.
func _refresh_overall_progress(silent := false) -> void:
	var total_levels := 0
	for stat in STATS:
		total_levels += int(levels[stat])
	var new_level := 1 + (total_levels - STATS.size()) / progression.levels_per_overall_level
	if new_level != overall_level:
		overall_level = new_level
		if not silent:
			overall_level_changed.emit(overall_level, level_name())
	var new_tier := 0
	for i in progression.form_overall_levels.size():
		if overall_level >= progression.form_overall_levels[i]:
			new_tier = i
	if new_tier != evolution_tier:
		evolution_tier = new_tier
		if not silent:
			evolution_changed.emit(evolution_tier, level_name())


## The title of an overall level ("Couch Potato", "Rookie", ...).
func level_name(level := overall_level) -> String:
	if progression.level_names.is_empty():
		return "?"
	return progression.level_names[clampi(level - 1, 0, progression.level_names.size() - 1)]


# ---------------------------------------------------------------------------
# Muscle exhaustion
# ---------------------------------------------------------------------------

func add_exhaustion(stat: StringName, amount: float) -> void:
	if not STATS.has(stat) or amount <= 0.0:
		return
	exhaustion[stat] = clampf(exhaustion[stat] + amount, 0.0, progression.max_exhaustion)
	exhaustion_changed.emit(stat, exhaustion[stat])


func heal_exhaustion(stat: StringName, amount: float) -> void:
	if not STATS.has(stat) or amount <= 0.0:
		return
	exhaustion[stat] = clampf(exhaustion[stat] - amount, 0.0, progression.max_exhaustion)
	exhaustion_changed.emit(stat, exhaustion[stat])


func heal_all_exhaustion(amount: float) -> void:
	for stat in STATS:
		heal_exhaustion(stat, amount)


## How effectively a muscle trains right now: 1.0 fresh, down to
## (1 - exhaustion_xp_penalty) at full exhaustion. Wrecked muscles barely grow.
func exhaustion_effectiveness(stat: StringName) -> float:
	return 1.0 - exhaustion[stat] / progression.max_exhaustion * progression.exhaustion_xp_penalty


func average_exhaustion() -> float:
	var total := 0.0
	for stat in STATS:
		total += exhaustion[stat]
	return total / STATS.size()


# ---------------------------------------------------------------------------
# Energy & motivation buff
# ---------------------------------------------------------------------------

func spend_energy(amount: float) -> void:
	energy = clampf(energy - amount, 0.0, progression.max_energy)
	energy_changed.emit(energy, progression.max_energy)


## Spends energy for a training action, scaled by Stamina: conditioning makes
## the same workout cheaper, so the energy pool lasts longer as you progress.
func spend_exercise_energy(base_cost: float) -> void:
	spend_energy(base_cost * exercise_cost_multiplier() * energy_reduction)


## Energy cost multiplier derived from the Stamina level (asymptotic, so it
## never reaches zero). Level 1 = 1.0 (drains very fast on a fresh character).
func exercise_cost_multiplier() -> float:
	return 1.0 / (1.0 + (levels[&"stamina"] - 1) * progression.stamina_energy_efficiency)


## Completely out of energy — no more training until the player recovers.
func is_exhausted() -> bool:
	return energy <= 0.0


# ---------------------------------------------------------------------------
# Money
# ---------------------------------------------------------------------------

func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)


## Returns false (and changes nothing) if the player can't afford it.
func spend_money(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	money_changed.emit(money)
	return true


## Sum of all stat levels — used e.g. as the competition muscle bonus.
func total_stat_levels() -> int:
	var total := 0
	for stat in STATS:
		total += int(levels[stat])
	return total


## Derived attribute: how physically big the character is. Grows with every
## level in every muscle; drives tournament judging and the sprite scale.
func muscle_size() -> int:
	return total_stat_levels()


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
		"version": 2,
		"xp": {},
		"levels": {},
		"exhaustion": {},
		"energy": energy,
		"money": money,
		"intro_seen": intro_seen,
		"steroid_data": {
			"type": active_steroid_type,
			"bonus": steroid_bonus,
			"energy_red": energy_reduction,
			"expires": steroid_expires_at
		}
	}
	for stat in STATS:
		data["xp"][String(stat)] = xp[stat]
		data["levels"][String(stat)] = levels[stat]
		data["exhaustion"][String(stat)] = exhaustion[stat]
	var file := FileAccess.open(SaveSlots.stats_path(), FileAccess.WRITE)
	if file == null:
		push_warning("PlayerStats: could not write save file.")
		return
	file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SaveSlots.stats_path()):
		return
		
	var file := FileAccess.open(SaveSlots.stats_path(), FileAccess.READ)
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
		exhaustion[stat] = clampf(
			float(data.get("exhaustion", {}).get(key, 0.0)), 0.0, progression.max_exhaustion)
	energy = clampf(float(data.get("energy", progression.max_energy)), 0.0, progression.max_energy)
	money = maxi(0, int(data.get("money", 0)))
	intro_seen = data.get("intro_seen", false)
	var s_data = data.get("steroid_data", {})
	active_steroid_type = s_data.get("type", "")
	steroid_bonus = float(s_data.get("bonus", 1.0))
	energy_reduction = float(s_data.get("energy_red", 1.0))
	steroid_expires_at = int(s_data.get("expires", 0))

## Discards in-memory state and loads whatever the active save slot holds
## (a fresh character if the slot is empty). Used when switching slots.
func reload_from_disk() -> void:
	for stat in STATS:
		xp[stat] = 0.0
		levels[stat] = 1
		exhaustion[stat] = 0.0
	energy = progression.max_energy
	money = 0
	intro_seen = false
	_buff_ends_at_msec = -1
	load_game()
	_refresh_overall_progress(true)
	for stat in STATS:
		exhaustion_changed.emit(stat, exhaustion[stat])
	energy_changed.emit(energy, progression.max_energy)
	money_changed.emit(money)


## Wipes all progression back to a fresh character (used by Restart).
func reset_progress() -> void:
	active_steroid_type = ""
	steroid_bonus = 1.0
	energy_reduction = 1.0
	steroid_expires_at = 0
	save_game()
	for stat in STATS:
		xp[stat] = 0.0
		levels[stat] = 1
		exhaustion[stat] = 0.0
		exhaustion_changed.emit(stat, 0.0)
	energy = progression.max_energy
	money = 0
	intro_seen = false
	_buff_ends_at_msec = -1
	_refresh_overall_progress(true)
	energy_changed.emit(energy, progression.max_energy)
	money_changed.emit(money)
	save_game()
	
func apply_steroids(type: String, duration: int, bonus_xp: float, energy_red: float):
	active_steroid_type = type
	steroid_bonus = bonus_xp
	energy_reduction = energy_red
	steroid_expires_at = GameCalendar.day + duration
	steroids_changed.emit()
	
func check_steroid_expiry(current_day: int):
	if steroid_expires_at > 0 and current_day >= steroid_expires_at:
		active_steroid_type = ""
		steroid_bonus = 1.0
		energy_reduction = 1.0
		
func get_total_level() -> int:
	var total := 0
	for stat in levels:
		total += levels[stat]
	return total
