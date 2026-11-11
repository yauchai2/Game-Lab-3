extends RefCounted
## LAST SERVICE. Original uploaded GLBs preserved byte-for-byte; transforms are wrappers.
const ENTRIES := [
 {"id":"zip","label":"fighter_zip","path":"res://assets/characters/last_service/source/tripo_convert_99c7d390-686e-4266-8ab4-9a4945bc8c0e.glb","scale":2.05,"trait":"trait_zip"},
 {"id":"rivet","label":"fighter_rivet","path":"res://assets/characters/last_service/source/tripo_convert_eba86dd1-7407-406c-8cd4-c30a60170283.glb","scale":2.23,"trait":"trait_rivet"},
 {"id":"hush","label":"fighter_hush","path":"res://assets/characters/last_service/source/tripo_convert_966f11dc-0f0f-4749-89e3-3ce3dac4b3ed.glb","scale":2.08,"trait":"trait_hush"},
 {"id":"loop","label":"fighter_loop","path":"res://assets/characters/last_service/source/tripo_convert_0a7a6724-6fde-4347-9257-cd31c2d34e36.glb","scale":2.12,"trait":"trait_loop"}]
## Enemies have a separate identity; the four hero/save indices never move.
const BLACK_SUIT_INDEX := 4
const BLACK_SUIT := {"id":"black_suit","label":"fighter_black_suit","path":"res://assets/characters/black_suit/derived/black_suit_repaired.glb","scale":2.15,"trait":"trait_black_suit"}
static func entry(index:int) -> Dictionary:
    return BLACK_SUIT if index==BLACK_SUIT_INDEX else ENTRIES[clampi(index,0,3)]
