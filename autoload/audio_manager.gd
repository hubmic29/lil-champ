## AudioManager (autoload) — central audio playback with zero binary assets.
##
## All sound effects and the sauna ambience are synthesized into
## AudioStreamWAV buffers at startup, so the project needs no audio files.
## Usage: AudioManager.play(&"punch"), AudioManager.play_music(&"sauna_ambient").
extends Node

const SAMPLE_RATE := 22050
const PLAYER_POOL_SIZE := 8

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer


func _ready() -> void:
	for i in PLAYER_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_bake_all_sounds()


## Plays a one-shot sound effect by name. Slight random pitch keeps rapid
## repeats (combos, mashing) from sounding robotic.
func play(sound: StringName, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not _streams.has(sound):
		push_warning("AudioManager: unknown sound '%s'" % sound)
		return
	var player := _find_idle_player()
	player.stream = _streams[sound]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale * randf_range(0.95, 1.05)
	player.play()


func play_music(sound: StringName, volume_db := -12.0) -> void:
	if not _streams.has(sound):
		return
	_music_player.stream = _streams[sound]
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music(fade_seconds := 0.6) -> void:
	if not _music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -60.0, fade_seconds)
	tween.tween_callback(_music_player.stop)


func _find_idle_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]  # all busy: steal the oldest


# ---------------------------------------------------------------------------
# Synthesis
# ---------------------------------------------------------------------------

func _bake_all_sounds() -> void:
	# Segments are [frequency_hz, duration_s, volume_0_1, noise_mix_0_1].
	_streams[&"punch"] = _bake([[150.0, 0.09, 0.8, 0.5]])
	_streams[&"kick"] = _bake([[90.0, 0.13, 0.9, 0.5]])
	_streams[&"miss"] = _bake([[180.0, 0.07, 0.5, 0.1], [120.0, 0.12, 0.5, 0.1]])
	_streams[&"rep"] = _bake([[330.0, 0.06, 0.5, 0.0], [440.0, 0.09, 0.5, 0.0]])
	_streams[&"good"] = _bake([[520.0, 0.1, 0.5, 0.0]])
	_streams[&"perfect"] = _bake([[660.0, 0.07, 0.55, 0.0], [880.0, 0.13, 0.55, 0.0]])
	_streams[&"level_up"] = _bake([
		[523.0, 0.09, 0.5, 0.0], [659.0, 0.09, 0.5, 0.0],
		[784.0, 0.09, 0.5, 0.0], [1047.0, 0.22, 0.55, 0.0],
	])
	_streams[&"click"] = _bake([[900.0, 0.03, 0.3, 0.0]])
	_streams[&"sauna_ambient"] = _bake_ambient_loop()


## Renders a sequence of decaying tone segments into a 16-bit mono WAV.
func _bake(segments: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for segment in segments:
		var freq: float = segment[0]
		var frames := int(segment[1] * SAMPLE_RATE)
		var volume: float = segment[2]
		var noise_mix: float = segment[3]
		for i in frames:
			var t := float(i) / SAMPLE_RATE
			var envelope := 1.0 - float(i) / frames  # linear decay per segment
			var tone := sin(TAU * freq * t)
			var noise := randf_range(-1.0, 1.0)
			var sample := lerpf(tone, noise, noise_mix) * volume * envelope
			_append_sample(data, sample)
	return _wrap_wav(data)


## A gentle two-tone drone with a slow tremolo; frequencies and the LFO fit
## the loop length exactly, so it repeats seamlessly.
func _bake_ambient_loop() -> AudioStreamWAV:
	var duration := 2.0
	var frames := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var tremolo := 0.75 + 0.25 * sin(TAU * 0.5 * t)
		var sample := (sin(TAU * 196.0 * t) + sin(TAU * 294.0 * t)) * 0.5 * 0.18 * tremolo
		_append_sample(data, sample)
	var wav := _wrap_wav(data)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = frames
	return wav


func _append_sample(data: PackedByteArray, sample: float) -> void:
	var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
	data.append(value & 0xFF)
	data.append((value >> 8) & 0xFF)


func _wrap_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = data
	return wav
