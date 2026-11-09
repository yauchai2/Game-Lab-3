extends RefCounted
## User-supplied source models, shared combat rules. Names pending user art direction.
const ENTRIES := [
    {"id":"original","label":"fighter_original","path":"res://assets/CHAR_PLAYER_A01.glb","scale":2.1},
    {"id":"upload_1","label":"fighter_1","path":"res://assets/characters/CHAR_FIGHTER_1.glb","scale":2.1},
    {"id":"upload_3","label":"fighter_3","path":"res://assets/characters/CHAR_FIGHTER_3.glb","scale":2.1},
    {"id":"upload_4","label":"fighter_4","path":"res://assets/characters/CHAR_FIGHTER_4.glb","scale":1.4},
]
static func entry(index:int) -> Dictionary:
    return ENTRIES[clampi(index,0,ENTRIES.size()-1)]
