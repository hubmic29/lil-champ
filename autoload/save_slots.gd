## SaveSlots (autoload) — three independent save slots.
##
## Owns which slot is active and where its files live; PlayerStats and
## GameCalendar read/write through the paths given here. The main menu uses
## peek() to show each slot's summary and select_slot() to load or reset one.
## Must be registered BEFORE PlayerStats/GameCalendar in the autoload list.
extends Node

const SLOT_COUNT := 3
const LAST_SLOT_PATH := "user://last_slot.json"
## Pre-slot save files from older versions get adopted into slot 1.
const LEGACY_STATS_PATH := "user://lil_champ_save.json"
const LEGACY_CALENDAR_PATH := "user://lil_champ_calendar.json"

var current_slot := 1


func _ready() -> void:
	_migrate_legacy_save()
	var meta := _read_json(LAST_SLOT_PATH)
	current_slot = clampi(int(meta.get("slot", 1)), 1, SLOT_COUNT)


func stats_path(slot := current_slot) -> String:
	return "user://slot_%d_stats.json" % slot


func calendar_path(slot := current_slot) -> String:
	return "user://slot_%d_calendar.json" % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(stats_path(slot)) \
		or FileAccess.file_exists(calendar_path(slot))


## Activates a slot and reloads both singletons from its files.
## With start_fresh the slot is wiped first (New Game).
func select_slot(slot: int, start_fresh: bool) -> void:
	current_slot = clampi(slot, 1, SLOT_COUNT)
	var file := FileAccess.open(LAST_SLOT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"slot": current_slot}))
	if start_fresh:
		delete_slot(current_slot)
	PlayerStats.reload_from_disk()
	GameCalendar.reload_from_disk()
	if start_fresh:
		PlayerStats.save_game()
		GameCalendar.save_state()


func delete_slot(slot: int) -> void:
	for path in [stats_path(slot), calendar_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Slot summary for menus, computed from the raw save files without touching
## the live singletons. Keys: exists, level, level_name, muscle_size, money,
## day, days_left, won, over.
func peek(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {"exists": false}
	var stats := _read_json(stats_path(slot))
	var cal := _read_json(calendar_path(slot))
	var prog: StatProgressionConfig = PlayerStats.progression
	var levels: Dictionary = stats.get("levels", {})
	var total := 0
	for stat in PlayerStats.STATS:
		total += int(levels.get(String(stat), 1))
	var level := 1 + (total - PlayerStats.STATS.size()) / int(prog.levels_per_overall_level)
	var level_name := "?"
	if not prog.level_names.is_empty():
		level_name = prog.level_names[clampi(level - 1, 0, prog.level_names.size() - 1)]
	var day := maxi(1, int(cal.get("day", 1)))
	return {
		"exists": true,
		"level": level,
		"level_name": level_name,
		"muscle_size": total,
		"money": int(stats.get("money", 0)),
		"day": day,
		"days_left": clampi(GameCalendar.TOTAL_DAYS - day + 1, 0, GameCalendar.TOTAL_DAYS),
		"won": bool(cal.get("universe_won", false)),
		"over": day > GameCalendar.TOTAL_DAYS,
	}


func _migrate_legacy_save() -> void:
	if FileAccess.file_exists(LEGACY_STATS_PATH) and not slot_exists(1):
		DirAccess.rename_absolute(LEGACY_STATS_PATH, stats_path(1))
		if FileAccess.file_exists(LEGACY_CALENDAR_PATH):
			DirAccess.rename_absolute(LEGACY_CALENDAR_PATH, calendar_path(1))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if typeof(data) == TYPE_DICTIONARY else {}
	
