extends RefCounted
## Skill-first authority. Equipment supplies a limited slice of the build budget.
const EQUIPMENT_CAPS={"damage":.12,"defence":.10,"economy":.10,"heavy_damage":.12,"aerial_damage":.12,"finisher_damage":.12,"guard_damage":.15,"launch_force":.15,"counter_damage":.15,"chain_damage":.20,"chain_targets":1.0,"parry_meter":4.0,"splash":1.0}
static func equipment(raw:Dictionary) -> Dictionary:
    var result:Dictionary={}
    for key in raw:result[key]=clampf(float(raw[key]),-.2,float(EQUIPMENT_CAPS.get(key,.15)))
    return result
static func cap(stats:Dictionary) -> Dictionary:
    stats.damage=clampf(stats.damage,-.2,.20);stats.defence=clampf(stats.defence,-.2,.15);stats.economy=clampf(stats.economy,-.2,.20)
    stats.chain_damage=clampf(stats.chain_damage,-.5,.35);stats.chain_targets=clampf(stats.chain_targets,-2,2)
    stats.chain_meter=clampf(stats.chain_meter,0,4);stats.parry_meter=clampf(stats.parry_meter,0,8)
    return stats
static func attack_bonus(bonus:float,counter:bool) -> float:return clampf(bonus,-.25,.60 if counter else .50)
