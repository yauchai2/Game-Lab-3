# Original campaign geometry

Twelve original low-poly models authored by the repository script, exported with Blender 4.3.2. No third-party meshes, generated-image textures, or external model service were used. Existing character/Dealer Tripo assets are separate and unchanged.

Rebuild from repository root:

```sh
blender -b --python tools/build_campaign_models.py -- "$PWD"
```

Six district shells include their own floors, structures and landmarks. Safe Block contains the city shell; three NPCs and two giant robots are separate models. Robot Arm_L / Arm_R / CorePivot / HeadPivot nodes support rigid runtime animation, not skeletal ragdolls. Fighter equipment is attached separately to actual hero bones. Materials are replaced by the existing toon shader at runtime.

`manifest.json` records the exported files, hashes and mesh counts. These are playable placeholder art; further bespoke animation and production art remain possible.
