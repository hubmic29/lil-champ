## Punching Bag — trains Stamina / Conditioning.
##
## Random hit zones appear on the bag; click them before they expire.
## Zones above the bag's midline throw a punch, below it a kick.
## XP per hit scales with session accuracy and the current combo.
extends BaseExercise

@onready var bag: TextureRect = %Bag
@onready var hit_zone: Button = %HitZone
@onready var character: AnimatedSprite2D = %Character
@onready var combo_label: Label = %ComboLabel
@onready var accuracy_label: Label = %AccuracyLabel
@onready var message_label: Label = %MessageLabel

var combo := 0
var hits := 0
var misses := 0

var _cfg: PunchingBagConfig
var _zone_timer: Timer
var _character_home := Vector2.ZERO


func _ready() -> void:
	super()
	_cfg = config as PunchingBagConfig
	_character_home = character.position
	bag.pivot_offset = Vector2(bag.size.x / 2.0, 0)  # sway around the chain mount
	hit_zone.pressed.connect(_on_zone_hit)
	bag.gui_input.connect(_on_bag_input)
	_zone_timer = Timer.new()
	_zone_timer.one_shot = true
	_zone_timer.timeout.connect(_on_zone_expired)
	add_child(_zone_timer)
	message_label.text = "Click the targets on the bag!"
	_update_labels()
	_spawn_zone()


## Places the hit zone at a random spot on the bag; lifetime shrinks with combo.
func _spawn_zone() -> void:
	var zone_size := Vector2.ONE * _cfg.target_size
	hit_zone.size = zone_size
	hit_zone.pivot_offset = zone_size / 2.0
	hit_zone.position = Vector2(
		randf_range(0.0, bag.size.x - zone_size.x),
		randf_range(0.0, bag.size.y - zone_size.y)
	)
	hit_zone.scale = Vector2.ZERO
	create_tween().tween_property(hit_zone, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lifetime := maxf(
		_cfg.target_lifetime_min,
		_cfg.target_lifetime - combo * _cfg.target_lifetime_decay
	)
	_zone_timer.start(lifetime)


func _on_zone_hit() -> void:
	if exhausted:
		return
	_zone_timer.stop()
	hits += 1
	combo += 1
	var zone_center_y := hit_zone.position.y + hit_zone.size.y / 2.0
	var is_punch := zone_center_y < bag.size.y / 2.0
	AudioManager.play(&"punch" if is_punch else &"kick")
	_play_attack_animation(is_punch)
	_sway_bag()
	var hit_position := bag.position + hit_zone.position + hit_zone.size / 2.0
	# Reward = accuracy factor (0.5..1.0) times the capped combo bonus.
	var accuracy := float(hits) / float(hits + misses)
	var multiplier := (0.5 + 0.5 * accuracy) \
		* (1.0 + minf(combo, _cfg.max_combo_for_bonus) * _cfg.combo_bonus)
	award_xp(multiplier, hit_position)
	burst_particles(hit_position)
	screen_shake(3.0 + minf(combo, 10.0) * 0.4, 0.15)
	message_label.text = "PUNCH!" if is_punch else "KICK!"
	_bump_combo_label()
	_update_labels()
	_spawn_zone()


## Clicks on the bag that the zone button didn't consume are misses.
func _on_bag_input(event: InputEvent) -> void:
	if exhausted:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_register_miss("You missed the target!")


func _on_zone_expired() -> void:
	if exhausted:
		return
	_register_miss("Too slow!")
	_spawn_zone()


## Stop the target loop entirely once the player runs out of energy.
func _on_exhausted() -> void:
	_zone_timer.stop()
	hit_zone.hide()


func _register_miss(reason: String) -> void:
	misses += 1
	combo = 0
	AudioManager.play(&"miss")
	message_label.text = reason
	_update_labels()


## Quick lunge toward the bag: level jab for punches, tilted swing for kicks.
func _play_attack_animation(is_punch: bool) -> void:
	var tween := create_tween()
	var lunge := _character_home + Vector2(45, -10 if is_punch else 15)
	var tilt := 0.0 if is_punch else -0.5
	tween.tween_property(character, "position", lunge, 0.07)
	tween.parallel().tween_property(character, "rotation", tilt, 0.07)
	tween.tween_property(character, "position", _character_home, 0.12)
	tween.parallel().tween_property(character, "rotation", 0.0, 0.12)


func _sway_bag() -> void:
	var tween := create_tween()
	tween.tween_property(bag, "rotation", randf_range(0.04, 0.08) * (1 if randf() > 0.5 else -1), 0.08)
	tween.tween_property(bag, "rotation", 0.0, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _bump_combo_label() -> void:
	combo_label.pivot_offset = combo_label.size / 2.0
	combo_label.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(combo_label, "scale", Vector2.ONE, 0.2)


func _update_labels() -> void:
	combo_label.text = "Combo: %d" % combo
	var total := hits + misses
	var accuracy := 100.0 if total == 0 else 100.0 * hits / total
	accuracy_label.text = "Accuracy: %.0f%%" % accuracy
