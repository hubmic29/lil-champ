# lil-champ

From couch potato to absolute unit – gym simulator.

Walk around the gym (WASD), approach a station and press **E** to train.
Each station is its own minigame that trains specific stats; **Esc** or the
Back button returns to the gym.

## Training stations

| Station | Mechanic | Trains |
|---|---|---|
| Punching Bag | Click random hit zones (top = punch, bottom = kick); combo + accuracy scale XP | Stamina |
| Bench Press | Mash E / Space / LMB to fill the power bar before it drains | Chest |
| Deadlift | Timing bar with Perfect / Good / Miss windows (Space) | Back, Hamstrings |
| Squat Rack | Balance minigame — keep the marker centered with A/D, instability ramps up | Quadriceps |
| Sauna | No skill gameplay: heals per-muscle fatigue, random small talk, grants a temporary +XP motivation buff | Recovery |
| Competition Stage | Posing routine of Quick Time Events against AI bodybuilders; 4 tournament tiers with entry fees and prize money | Money (+ a little Stamina) |
| Supplement Shop | Spend prize money on nutrients (energy, buffs) and steroids (instant XP, nasty side effects) | — |

## Progression

- Five independent muscle stats (Chest, Back, Quadriceps, Hamstrings,
  Stamina) with per-stat XP, levels and soft caps / diminishing returns.
- An **overall level** derived from total stat levels, each with its own
  title (Couch Potato → Sofa Warrior → ... → Absolute Unit), drives the
  character's sprite forms.
- Energy pool: every training action drains it and hitting zero locks all
  exercises until you recover in the sauna. A fresh character burns out
  quickly, but each Stamina level makes training cost less energy, so
  conditioning literally lets you work out longer. Low (but non-zero) energy
  halves XP gain. The energy bar is visible on the map HUD and in every
  minigame.
## The 30-day run

- The game lasts exactly 30 in-game days. Win the **Mr. Universe** tournament
  within that window for the victory screen; otherwise it's game over (with
  restart). `GameCalendar` (autoload) owns the day counter, schedule and
  win/lose state.
- Every day is a **training day** or a **rest day**, chosen for the next day
  on the calendar screen that appears when you leave the gym (the exit door
  at the bottom). Rest days skip the gym, fully restore energy (the ONLY
  energy source) and heal a large chunk of muscle fatigue.
- Training days allow at most **4 sessions** (machine or sauna visits);
  the HUD shows the remaining count.
- Each muscle tracks **fatigue** (0–100%): training a muscle raises it and a
  wrecked muscle trains at a fraction of normal XP — rotate muscle groups,
  sit in the sauna, or rest. Fatigue shows as red bars in the HUD and on the
  calendar screen.
- Levels make you measurably stronger and bigger: muscle size (total levels)
  directly boosts tournament pose scores, and the map character
  physically grows with muscle size.

- Money: earned by placing top-3 in competitions (higher tiers pay far more
  but their rivals roll near-perfect scores — you need both flawless QTE
  timing and a high muscle bonus from total stat levels to take 1st).
- Progress (stats, energy, money, calendar) persists per save slot
  (`user://slot_N_stats.json` / `slot_N_calendar.json`, 3 slots on the
  start screen).

## Architecture

- `autoload/player_stats.gd` — PlayerStats singleton: XP, levels, overall level,
  sprite forms, energy, motivation buff, save/load. Signal-based (no polling).
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
