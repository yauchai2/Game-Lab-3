extends Node
## Original synthesized placeholders. No external recordings or licensed music.
var muted := false
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var voice_index := 0

func _ready() -> void:
    sounds["hit"] = _tone(0.10, 180.0, 55.0, 0.3)
    sounds["block"] = _tone(0.08, 580.0, 130.0, 0.14)
    sounds["charge"] = _tone(0.28, 65.0, 120.0, 0.08)
    sounds["release"] = _tone(0.17, 100.0, 30.0, 0.26)
    sounds["swing"] = _tone(0.05, 310.0, 100.0, 0.04)
    sounds["ko"] = _tone(0.45, 90.0, 22.0, 0.28)
    for i in 6:
        var voice := AudioStreamPlayer.new()
        add_child(voice)
        voice.volume_db = -9.0
        voices.append(voice)

func play_sound(kind: String, pitch := 1.0) -> void:
    if muted or not sounds.has(kind):
        return
    var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
    voice_index += 1
    voice.stop()
    voice.stream = sounds[kind]
    voice.pitch_scale = pitch
    voice.play()

func stop_all() -> void:
    for voice in voices:
        voice.stop()

func _tone(duration: float, start: float, end: float, noise: float) -> AudioStreamWAV:
    var rate := 22050
    var count := int(duration * rate)
    var data := PackedByteArray()
    data.resize(count * 2)
    var phase := 0.0
    var rng := RandomNumberGenerator.new()
    rng.seed = 73
    for i in count:
        var t := float(i) / count
        phase += TAU * lerpf(start, end, t) / rate
        var envelope := minf(1.0, t * 80.0) * pow(1.0 - t, 2.0)
        var sample := (sin(phase) * 0.65 + sin(phase * 2.7) * 0.12 + rng.randf_range(-noise, noise)) * envelope
        data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 26000))
    var result := AudioStreamWAV.new()
    result.format = AudioStreamWAV.FORMAT_16_BITS
    result.mix_rate = rate
    result.data = data
    return result
