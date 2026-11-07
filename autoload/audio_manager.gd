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
	_streams["morph_to_thresher"] = _make_metallic_sweep(380.0, 1000.0, 0.14)
	_streams["morph_to_gunship"] = _make_metallic_sweep(1000.0, 380.0, 0.14)
	_streams["graze_tick"] = _make_metallic_sweep(2400.0, 3000.0, 0.035)
	_streams["overclock_on"] = _make_rising_roar(0.55)
	_streams["assimilate"] = _make_metallic_sweep(1400.0, 240.0, 0.22)
	_streams["strike"] = _make_rising_roar(0.9)
	_streams["denied"] = _make_metallic_sweep(240.0, 170.0, 0.12)
	_streams["threat_alarm"] = _make_alarm(0.8)
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


## Noise plus a climbing tone: a heat surge for Overclock.
func _make_rising_roar(duration: float) -> AudioStreamWAV:
	var frames: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frames * 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var phase: float = 0.0
	var noise: float = 0.0
	for i: int in frames:
		var t: float = float(i) / frames
		phase += TAU * lerpf(160.0, 900.0, t * t) / SAMPLE_RATE
		# Smoothed noise sounds like rushing air rather than hiss.
		noise = lerpf(noise, rng.randf_range(-1.0, 1.0), 0.25)
		var envelope: float = minf(1.0, t * 12.0) * (1.0 - t)
		var sample: float = (0.55 * sin(phase) + 0.25 * sin(phase * 1.5) + 0.5 * noise) * envelope * 0.5
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


## Alternating two-tone beeps with a hard edge: the HSD escalation alarm (Threat Level rising).
func _make_alarm(duration: float) -> AudioStreamWAV:
	var frames: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frames * 2)
	var phase: float = 0.0
	const BEEP: float = 0.16
	for i: int in frames:
		var t: float = float(i) / SAMPLE_RATE
		var beat: float = t / BEEP
		var on: bool = fmod(beat, 1.0) < 0.7
		var hz: float = 720.0 if int(beat) % 2 == 0 else 540.0
		phase += TAU * hz / SAMPLE_RATE
		var envelope: float = (1.0 if on else 0.0) * (1.0 - 0.35 * t / duration)
		# A touch of square wave gives it the edge of a real klaxon.
		var sample: float = (0.6 * sin(phase) + 0.25 * signf(sin(phase))) * envelope * 0.4
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


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
