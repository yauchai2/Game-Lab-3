# User-provided Mixamo motions

`mixamo_fighters.json` and `mixamo_shoulder_throw.json` are game-ready derivatives of the FBX/GLB animations supplied by the repository owner or obtained through an owner-authorized Mixamo session. The owner explicitly authorized bundling these files in GitHub on 2026-11-14 so a normal checkout can run the animations without a separate download.

These files are Adobe Mixamo animation derivatives, not Quaternius/KayKit CC0 assets and not relicensed under a source-code license. The applicable Adobe terms remain applicable. Source information: <https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html>.

Source filenames, checksums, sampling, duplicate detection and original timing are recorded in `docs/evidence/mixamo-first-batch/sources.json`; runtime bundle checksums and activation coverage are in `docs/evidence/motion-completion`. The original uploaded FBX/GLB files are preserved outside this repository. The canonical rest rig used for retargeting remains the original CC0 library with its existing notices.

Build helpers: `tools/inspect_mixamo_batch.py`, `tools/build_mixamo_motion_library.py`, `tools/import_mixamo_throw.py`. `res://assets/animations` is the runtime source; `.godot` is only an import cache. `GAME_LAB_MOTION_LIBRARY` and `GAME_LAB_THROW_LIBRARY` are optional development overrides.
