## Tuning for the bodybuilding competition (pose-off QTE minigame).
## All tournament arrays are indexed by tier (0 = easiest); they must all
## have the same length.
class_name CompetitionConfig
extends ExerciseConfig

@export_group("Posing QTE")
## Poses (= Quick Time Events) per tournament routine.
@export var poses_per_tournament := 5
## Keys the QTE can ask for (uppercase letters).
@export var qte_keys: Array[String] = ["A", "S", "D", "W", "F"]
## Points for hitting the perfect / good window. Miss and wrong key give 0.
@export var perfect_points := 2
@export var good_points := 1
## Pose score bonus per point of muscle size (= total stat levels): bigger
## muscles impress the judges, so training is required to out-pose elites.
@export var muscle_bonus_per_level := 0.01
@export var good_zone_width := 1
@export var perfect_zone_width := 2

@export_group("Tournaments")
@export var tournament_names: Array[String] = [
	"Local Show", "Regional Cup", "National Championship", "Mr. Universe",
]
## Cost to enter each tournament.
@export var entry_fees: Array[int] = [0, 40, 120, 300]
## Prize for 1st place; 2nd/3rd get a fraction of it (below).
@export var first_prizes: Array[int] = [80, 250, 700, 2000]
@export var second_place_fraction := 0.4
@export var third_place_fraction := 0.15
## Indicator sweep speed per tier — higher tiers demand faster reactions.
@export var indicator_speeds: Array[float] = [420.0, 520.0, 640.0, 780.0]

@export_group("Opponents")
## Rivals on stage per tier. More rivals = more chances someone rolls high.
@export var opponent_counts: Array[int] = [4, 5, 6, 7]
## Per-pose score range the AI bodybuilders roll in, per tier. Top tiers
## average close to (or above) a flawless unmodified player routine, so
## winning Mr. Universe takes near-perfect timing AND developed muscles.
@export var opponent_pose_min: Array[float] = [35.0, 55.0, 68.0, 80.0]
@export var opponent_pose_max: Array[float] = [75.0, 90.0, 100.0, 110.0]
@export var opponent_names: Array[String] = [
	"Big Ron", "Hans Flex", "Quadzilla", "Bulk Hogan", "Sir Lat",
	"Marco Delts", "The Mountain", "Aleks Pecs", "Tiny Tim", "Arnie Jr.",
	"Mad Traps", "Captain Curl", "Don Pump", "Iron Igor",
]
