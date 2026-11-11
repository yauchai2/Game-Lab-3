extends RefCounted
## LAST SERVICE. Original uploaded GLBs preserved byte-for-byte; transforms are wrappers.
const ENTRIES := [
 {"id":"zip","label":"fighter_zip","path":"res://assets/characters/last_service/source/tripo_convert_99c7d390-686e-4266-8ab4-9a4945bc8c0e.glb","scale":2.05,"trait":"trait_zip"},
 {"id":"rivet","label":"fighter_rivet","path":"res://assets/characters/last_service/source/tripo_convert_eba86dd1-7407-406c-8cd4-c30a60170283.glb","scale":2.23,"trait":"trait_rivet"},
 {"id":"hush","label":"fighter_hush","path":"res://assets/characters/last_service/source/tripo_convert_966f11dc-0f0f-4749-89e3-3ce3dac4b3ed.glb","scale":2.08,"trait":"trait_hush"},
 {"id":"loop","label":"fighter_loop","path":"res://assets/characters/last_service/source/tripo_convert_0a7a6724-6fde-4347-9257-cd31c2d34e36.glb","scale":2.12,"trait":"trait_loop"}]
static func entry(index:int) -> Dictionary:return ENTRIES[clampi(index,0,3)]
