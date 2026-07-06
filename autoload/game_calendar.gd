## GameCalendar (autoload) — the 30-day run structure.
##
## Every in-game day is a training day or a rest day. Training days allow
## up to N gym sessions (machine or sauna visits, N from progression config);
## rest days skip the gym and are the only source of energy restoration
## (plus a big chunk of muscle recovery). The run ends in victory when the
## player wins the Mr. Universe tournament, or in defeat when day 30 passes.
extends Node

signal day_changed(day: int, day_type: DayType)
signal sessions_changed(sessions_left: int)
signal universe_won_changed

enum DayType { TRAINING, REST }

const TOTAL_DAYS := 30
## Day 1 is the 1st of the in-game month shown on the calendar screen.
const MONTH_NAME := "June"

var day := 1
var day_type := DayType.TRAINING
var sessions_used := 0
var universe_won := false


func _ready() -> void:
	load_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()


func max_sessions() -> int:
	return PlayerStats.progression.sessions_per_day


func sessions_left() -> int:
	return maxi(0, max_sessions() - sessions_used)


func can_start_session() -> bool:
	return day_type == DayType.TRAINING and sessions_left() > 0


## Consumes one of today's gym sessions (a machine or sauna visit).
func use_session() -> void:
	sessions_used += 1
	sessions_changed.emit(sessions_left())
	save_state()


## Moves to the next day of the chosen type. A rest day immediately applies
## its recovery: full energy plus a large exhaustion heal on every muscle.
func advance_day(next_type: DayType) -> void:
	day += 1
	day_type = next_type
	sessions_used = 0
	if day_type == DayType.REST:
		PlayerStats.restore_energy(PlayerStats.progression.max_energy)
		PlayerStats.heal_all_exhaustion(PlayerStats.progression.rest_day_exhaustion_heal)
	day_changed.emit(day, day_type)
	sessions_changed.emit(sessions_left())
	save_state()


func set_universe_won() -> void:
	universe_won = true
	universe_won_changed.emit()
	save_state()


func is_out_of_days() -> bool:
	return day > TOTAL_DAYS


func is_game_over() -> bool:
	return universe_won or is_out_of_days()


func date_string() -> String:
	return "%s %d" % [MONTH_NAME, mini(day, TOTAL_DAYS)]


## Back to day 1 for a fresh run (used by Restart together with
## PlayerStats.reset_progress()).
func reset() -> void:
	day = 1
	day_type = DayType.TRAINING
	sessions_used = 0
	universe_won = false
	day_changed.emit(day, day_type)
	sessions_changed.emit(sessions_left())
	save_state()


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

## Discards in-memory state and loads the active save slot (fresh day 1 if
## the slot is empty). Used when switching slots.
func reload_from_disk() -> void:
	day = 1
	day_type = DayType.TRAINING
	sessions_used = 0
	universe_won = false
	load_state()
	day_changed.emit(day, day_type)
	sessions_changed.emit(sessions_left())


func save_state() -> void:
	var file := FileAccess.open(SaveSlots.calendar_path(), FileAccess.WRITE)
	if file == null:
		push_warning("GameCalendar: could not write save file.")
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"day": day,
		"day_type": day_type,
		"sessions_used": sessions_used,
		"universe_won": universe_won,
	}, "\t"))


func load_state() -> void:
	if not FileAccess.file_exists(SaveSlots.calendar_path()):
		return
	var file := FileAccess.open(SaveSlots.calendar_path(), FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("GameCalendar: save file corrupted, starting fresh.")
		return
	day = maxi(1, int(data.get("day", 1)))
	day_type = int(data.get("day_type", DayType.TRAINING)) as DayType
	sessions_used = maxi(0, int(data.get("sessions_used", 0)))
	universe_won = bool(data.get("universe_won", false))
