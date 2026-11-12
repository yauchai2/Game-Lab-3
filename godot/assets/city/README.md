# Nightshift reference hub

The active set is `scripts/combat/city/nightshift/reference_workshop.gd`: fixed-camera image-projected facade/depth surfaces, walkable ground/stairs, live rigged heroes and ambient 3D animation. `reference/empty-workshop.png` is a clean plate derived from the approved scene by removing actors and the moving orange arm; it is not a screenshot of a completed all-angle model.

`nightshift_workshop.glb` is a self-contained static export with projected UVs and embedded texture, rebuilt by `tools/export_nightshift_hub.gd`. It is for the supplied camera, not a complete building for unrestricted rotation. Heroes and gameplay animation are loaded separately. Use `scenes/city/nightshift_workshop.tscn` + F6 for the live art preview. Original user GLBs are unchanged. See docs/NIGHTSHIFT_REFERENCE_REBUILD.zh-TW.md and references/nightshift-hub/TRIPO_REQUIREMENTS.zh-TW.md.

The earlier procedural blockout remains in `nightshift/workshop.gd` as source history and a geometry helper; the active Story hub no longer builds that layout.
