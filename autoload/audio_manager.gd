extends Node
## Plays sound effects by name. Placeholder sounds are generated in code so there are no audio
## files yet; jsfxr sounds replace them in Step 18 by dropping files into audio/sfx/.

const SAMPLE_RATE: int = 22050
## How many sounds can overlap. The oldest one is cut off when they're all busy.
const VOICES: int = 8

var _streams: Dictionary[String, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	_streams["morph_to_lance"] = _make_metallic_sweep(380.0, 1000.0, 0.14)
	_streams["morph_to_gunship"] = _make_metallic_sweep(1000.0, 380.0, 0.14)
	for i: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound_name: String, volume_db: float = 0.0) -> void:
	if not _streams.has(sound_name):
		push_warning("AudioManager: no sound named '%s'" % sound_name)
		return
	var player: AudioStreamPlayer = _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = _streams[sound_name]
	player.volume_db = volume_db
	player.play()


## A short pitch sweep with a wobbling overtone and a fast decay: reads as "liquid metal" for now.
func _make_metallic_sweep(from_hz: float, to_hz: float, duration: float) -> AudioStreamWAV:
	var frames: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frames * 2) # 16-bit mono
	var phase: float = 0.0
	for i: int in frames:
		var t: float = float(i) / frames
		phase += TAU * lerpf(from_hz, to_hz, t) / SAMPLE_RATE
		var envelope: float = minf(1.0, t * 25.0) * (1.0 - t) * (1.0 - t)
		var sample: float = (sin(phase) + 0.35 * sin(phase * 2.01) + 0.15 * sin(phase * 3.7)) * envelope * 0.45
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
