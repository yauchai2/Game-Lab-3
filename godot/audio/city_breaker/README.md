# Original CITY BREAKER sound design

`score.ogg`: original procedural synthesis, stereo 48kHz, ten seconds, no external samples or downloaded recordings. Source is `tools/build_city_breaker_audio.py`; seed and cue times are recorded in `provenance.json`. Rebuilding needs Python + NumPy and FFmpeg/libvorbis; runtime only needs the packaged OGG.

Layers: rising air-pressure and reverse suction, low-frequency impacts, filtered noise/concrete crunch, inharmonic metal fragments, four-engine synthetic rumble, alternating stereo debris and a descending arcade KO chord. Authored peak is -2dBFS before Vorbis encoding; runtime gain, user SFX level and existing SFX bus limiter determine the final mix.

The dedicated AudioStreamPlayer belongs to CityBreaker. It starts on an authoritative KO, pauses with the cinematic, and stops on every clear path. BGM continues through the original music owner with a temporary 4–8dB target duck; no track replacement or global time scaling. Mute and zero SFX level preserve transport timing at -80dB, so restoring output does not replay the opening.
