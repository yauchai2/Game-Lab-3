# Generated combat art

Original JSR-inspired sharp street fighting effects. Runtime originals are in `godot/assets/vfx/`; see [generation.json](generation.json) and [atlas regions and alpha](assets.json). PNG bytes are unchanged. First signature output had a white fog background; the final ImageGen edit removes it. General atlas has a negligible alpha=1 corner; the signature atlas corners are zero.

- [16 attack/defense shapes](../../godot/assets/vfx/street_actions.png)
- [8 character signatures](../../godot/assets/vfx/fighter_signatures.png)
- [Actual native captures](../../docs/evidence/jsr-runtime/README.md)

All existing 13 attack identifiers are mapped; parry, block, guard break, dust, dash and ground effects also use the atlas. Four-stage engine transforms animate static sprites. No GIF playback or false frame-by-frame animation claim. Existing procedural trajectory/beam/red-stage/camera effects remain event-driven. No original SEGA sprites included.
