extends RefCounted
## Session-only rewards; presentation never mutates fighter rules or permanent XP.
const ITEMS=[
    {"id":"speed","title":"SPEED CORE","detail":"MOVE +20% / DASH +10%","color":Color("44ffdd")},
    {"id":"guard","title":"GUARD CORE","detail":"GUARD REGEN +35%","color":Color("ffca42")},
    {"id":"charge","title":"CHARGE CORE","detail":"START ENERGY +20","color":Color("ff70b9")},
    {"id":"fury","title":"FURY CORE","detail":"HIT DAMAGE +15%","color":Color("ff7657")},
    {"id":"plate","title":"PLATE CORE","detail":"HIT TAKEN -15%","color":Color("8aaaff")},
    {"id":"flow","title":"FLOW CORE","detail":"HIT ENERGY +30%","color":Color("91f5ff")},
    {"id":"eco","title":"ECO CORE","detail":"SKILL COST -20%","color":Color("bdff00")},
    {"id":"breach","title":"BREACH CORE","detail":"GUARD DAMAGE +25%","color":Color("ffad46")},
    {"id":"siphon","title":"SIPHON CORE","detail":"HIT HEAL +2 / HEAL CAP 12","color":Color("b98cff")}]
var claimed:Dictionary={}
var results:Dictionary={}
static func item(id:String) -> Dictionary:
    for entry in ITEMS:
        if entry.id==id:return entry.duplicate()
    return {}

static func skill_cost(f:Dictionary,name:String,last_service:bool) -> int:
    var base:int=10 if name=="node_pulse" else (75 if name=="overdrive" else (20 if last_service and f.get("character",0)==3 else 50))
    return roundi(base*.8) if f.get("draw_core","")=="eco" else base

func reset() -> void:claimed.clear();results.clear()
func roll(boundary:String,seed_value:int) -> Dictionary:
    if results.has(boundary):return results[boundary].duplicate()
    var rng:=RandomNumberGenerator.new();rng.seed=seed_value
    var result:Dictionary=ITEMS[rng.randi_range(0,ITEMS.size()-1)].duplicate()
    result["boundary"]=boundary;results[boundary]=result
    return result.duplicate()
func apply_once(sim:RefCounted,result:Dictionary,recipient:=0) -> bool:
    if result.is_empty() or recipient<0 or recipient>=sim.fighters.size() or item(result.get("id","")).is_empty() or not result.has("boundary") or claimed.has(result.boundary):return false
    claimed[result.boundary]=true
    sim.fighters[recipient]["draw_core"]=result.id
    if result.id=="charge":sim.fighters[recipient].meter=minf(100,sim.fighters[recipient].meter+20)
    return true
