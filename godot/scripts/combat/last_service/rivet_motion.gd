extends RefCounted
## Retained boxing timing and source-stance mask used by street_motion.gd.
const ATTACKS={
    "jab":{"clip":"Punch_Jab","contact":.30,"release":.40},
    "cross":{"clip":"Punch_Cross","contact":.30,"release":.40},
    "heavy":{"clip":"Punch_Cross","contact":.30,"release":.40},
    "finisher":{"clip":"Punch_Cross","contact":.30,"release":.40},
    "special":{"clip":"Punch_Cross","contact":.30,"release":.40}}
static func sample(f:Dictionary,duration:float,move:Dictionary={}) -> float:
    if f.state!="attack":return duration
    var entry:Dictionary=ATTACKS[f.move]
    var frame:float=f.frame
    if frame<float(move.startup):
        if f.move=="special":
            # The simulation repeats frames 7/8 while holding. Both map to one
            # load pose; release then advances toward the real contact tick.
            var load:float=.12+.015*float(f.get("service",{}).get("preload",0))
            if frame<=8:return duration*load*smoothstep(0.0,7.0,frame)
            return duration*lerpf(load,entry.contact,smoothstep(8.0,float(move.startup),frame))
        return duration*float(entry.contact)*smoothstep(0.0,float(move.startup),frame)
    if frame<float(move.startup+move.active):
        return duration*lerpf(entry.contact,entry.release,(frame-move.startup)/float(move.active))
    return duration*lerpf(entry.release,1.0,clampf((frame-move.startup-move.active)/float(move.recovery),0.0,1.0))
static func planted_source(name:String) -> bool:
    # Freeze source pelvis and legs in the authored boxing stance. This is a
    # bounded planted clip mask, not terrain-aware foot IK or a walking solver.
    return name=="DEF-hips" or name.begins_with("DEF-thigh") or name.begins_with("DEF-shin") or name.begins_with("DEF-foot") or name.begins_with("DEF-toe")
