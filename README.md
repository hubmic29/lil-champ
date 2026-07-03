# lil-champ

From couch potato to absolute unit – gym simulator.

Walk around the gym (WASD), approach a station and press **E** to train.
Each station is its own minigame that trains specific stats; **Esc** or the
Back button returns to the gym.

## Training stations

| Station | Mechanic | Trains |
|---|---|---|
| Punching Bag | Click random hit zones (top = punch, bottom = kick); combo + accuracy scale XP | Stamina |
| Bench Press | Mash E / Space / LMB to fill the power bar before it drains | Chest (+ Strength) |
| Deadlift | Timing bar with Perfect / Good / Miss windows (Space) | Back, Hamstrings (+ Strength) |
| Squat Rack | Balance minigame — keep the marker centered with A/D, instability ramps up | Quadriceps (+ Strength) |
| Sauna | No skill gameplay: restores energy, random small talk, grants a temporary +XP motivation buff | Recovery |

## Progression

- Six independent stats (Strength, Chest, Back, Quadriceps, Hamstrings,
  Stamina) with per-stat XP, levels and soft caps / diminishing returns.
- Overall **Gym Level** derived from total stat levels drives **evolution
  tiers**: Couch Potato → Rookie → Athlete → Beast → Absolute Unit.
- Energy pool: every training action drains it and hitting zero locks all
  exercises until you recover in the sauna. A fresh character burns out
  quickly, but each Stamina level makes training cost less energy, so
  conditioning literally lets you work out longer. Low (but non-zero) energy
  halves XP gain. The energy bar is visible on the map HUD and in every
  minigame.
- Progress persists to `user://lil_champ_save.json`.

## Architecture

- `autoload/player_stats.gd` — PlayerStats singleton: XP, levels, gym level,
  evolution, energy, motivation buff, save/load. Signal-based (no polling).
- `autoload/audio_manager.gd` — all SFX/ambience synthesized at startup
  (no audio assets needed).
- `autoload/scene_switcher.gd` — fade-to-black scene transitions.
- `scripts/exercises/base_exercise.gd` — base class for every minigame:
  config-driven XP awarding, floating XP numbers, screen shake, particles,
  level-up fanfare, back/escape handling.
- `scenes/minigames/<name>/` — each minigame is a self-contained folder:
  scene, script, config script and balancing `.tres`.
- Every balancing number lives in exported `Resource` fields
  (`resources/progression.tres` and the per-minigame `.tres` files);
  nothing is hardcoded.
- `scenes/stations/training_station.gd` — one reusable interactable station
  script shared by all stations.

### Adding a new exercise

1. Create a folder under `scenes/minigames/` with a config script extending
   `ExerciseConfig` and a `.tres` for it (pick which stats it rewards via
   `stat_rewards`).
2. In the same folder, create a `Control` scene whose root script extends
   `BaseExercise` and assign the config; implement the mechanic and call
   `award_xp(...)`.
3. Instance a station scene (reusing `training_station.gd`) in the gym map
   pointing at your new scene. Done — HUD, XP, saving and polish come free.
