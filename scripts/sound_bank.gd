class_name SoundBank
extends Node

## Mirrors load_sounds() / play_sound() from the original: every WAV found in
## the sound group folders is loaded once and played at a random pitch.
##
## Folder layout (inside assets/):
##   sound/small, sound/medium, sound/big, sound/huge, sound/sneaky, sound/special
##   sound/original1 .. sound/original5
##   sound/voice1 .. sound/voiceN
##   sound/sfx (hip press / vacuum from the original game)

# Explicit preloads: keeps the scripts parseable on a fresh checkout before
# Godot's editor has built its global class cache.
const Content := preload("res://scripts/content.gd")
const SynthFart := preload("res://scripts/synth_fart.gd")
const WavLoader := preload("res://scripts/wav_loader.gd")

const PLAYER_POOL := 24
const BASE_GROUPS := ["Small", "Medium", "Big", "Huge", "Sneaky", "Special"]
const ORIGINAL_GROUPS := 5

var groups: Dictionary = {}
var group_order: Array[String] = []
var voices: Array = []
var voice_count: int = 5
var sfx: Dictionary = {}
var allow_synth_fallback := true
var master_volume_db := 0.0

var last_handle: AudioStreamPlayer = null

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _synth: Array[AudioStream] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for i in PLAYER_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func load_content(voice_max: int = 5) -> void:
	voice_count = clampi(voice_max, 0, 32)
	groups.clear()
	group_order.clear()
	for gname in BASE_GROUPS:
		var list := _load_folder(Content.path("sound").path_join(gname.to_lower()))
		groups[gname] = list
		group_order.append(gname)
	for i in ORIGINAL_GROUPS:
		var key := "Orig%d" % (i + 1)
		var list := _load_folder(Content.path("sound").path_join("original%d" % (i + 1)))
		groups[key] = list
		group_order.append(key)

	voices.clear()
	for i in voice_count:
		voices.append(_load_folder(Content.path("sound").path_join("voice%d" % (i + 1))))

	sfx["hip_press"] = WavLoader.load_wav(Content.path("sound/sfx/snd_hip_press.wav"))
	sfx["vacuum"] = WavLoader.load_wav(Content.path("sound/sfx/snd_vacuum.wav"))


func _load_folder(dir: String) -> Array:
	var out: Array = []
	for path in Content.list_files(dir, ["wav"]):
		var stream := WavLoader.load_wav(path)
		if stream != null:
			out.append(stream)
	return out


func total_sounds() -> int:
	var n := 0
	for key in groups:
		n += (groups[key] as Array).size()
	return n


func has_any_sound() -> bool:
	return total_sounds() > 0 or not voices.is_empty()


func group_is_empty(group: String) -> bool:
	return (groups.get(group, []) as Array).is_empty()


## Play a random sample from a sound group (play_sound in the original).
func play_group(group: String, pitch_variation: float) -> AudioStreamPlayer:
	var list: Array = groups.get(group, [])
	var stream: AudioStream = null
	if not list.is_empty():
		stream = list[_rng.randi_range(0, list.size() - 1)]
	elif allow_synth_fallback:
		stream = synth_stream()
	if stream == null:
		return null
	return play_stream(stream, pitch_variation)


func play_voice(index: int, pitch_variation: float) -> AudioStreamPlayer:
	if index < 0 or index >= voices.size():
		return null
	var list: Array = voices[index]
	if list.is_empty():
		return null
	return play_stream(list[_rng.randi_range(0, list.size() - 1)], pitch_variation)


func play_sfx(name: String) -> void:
	var stream: AudioStream = sfx.get(name, null)
	if stream == null:
		return
	play_stream(stream, 0.0)


func play_stream(stream: AudioStream, pitch_variation: float) -> AudioStreamPlayer:
	var p := _free_player()
	if p == null:
		return null
	p.stream = stream
	var v := maxf(pitch_variation, 0.0)
	p.pitch_scale = 1.0 + _rng.randf_range(-v, v)
	p.volume_db = master_volume_db
	p.play()
	last_handle = p
	return p


func _free_player() -> AudioStreamPlayer:
	for i in _players.size():
		var idx := (_next_player + i) % _players.size()
		if not _players[idx].playing:
			_next_player = (idx + 1) % _players.size()
			return _players[idx]
	if _players.is_empty():
		return null
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return p


func stop_all() -> void:
	for p in _players:
		p.stop()
	last_handle = null


func is_last_playing() -> bool:
	return last_handle != null and last_handle.playing


func synth_stream() -> AudioStream:
	if _synth.is_empty():
		for i in 4:
			_synth.append(SynthFart.make(1337 + i * 977))
	return _synth[_rng.randi_range(0, _synth.size() - 1)]
