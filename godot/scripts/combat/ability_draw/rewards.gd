extends RefCounted
## Session-only rewards; presentation never mutates fighter rules or permanent XP.
const ITEMS=[
    {"id":"speed","title":"SPEED CORE","detail":"MOVE +20% / DASH +10%","color":Color("44ffdd")},
    {"id":"guard","title":"GUARD CORE","detail":"GUARD REGEN +35%","color":Color("ffca42")},
    {"id":"charge","title":"CHARGE CORE","detail":"START ENERGY +20","color":Color("ff70b9")}]
var claimed:Dictionary={}
var results:Dictionary={}
func reset() -> void:claimed.clear();results.clear()
func roll(boundary:String,seed_value:int) -> Dictionary:
    if results.has(boundary):return results[boundary].duplicate()
    var rng:=RandomNumberGenerator.new();rng.seed=seed_value
    var result:Dictionary=ITEMS[rng.randi_range(0,ITEMS.size()-1)].duplicate()
    result["boundary"]=boundary;results[boundary]=result
    return result.duplicate()
func apply_once(sim:RefCounted,result:Dictionary,recipient:=0) -> bool:
    if result.is_empty() or claimed.has(result.boundary):return false
    claimed[result.boundary]=true
    sim.fighters[recipient]["draw_core"]=result.id
    if result.id=="charge":sim.fighters[recipient].meter=minf(100,sim.fighters[recipient].meter+20)
    return true
