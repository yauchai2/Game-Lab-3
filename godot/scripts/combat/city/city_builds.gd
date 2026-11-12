extends RefCounted
## 28 minors, 12 notables, four keystones, four free character gateways.
const BRANCHES=["BREAK","AIR","COUNTER","CIRCUIT"]
const PREFIXES=["break","air","guard","flow"]
static func nodes() -> Array:
    var result:Array=[]
    var sets:Array=[
        [["Heavy hands","heavy_damage",.04],["Street force","damage",.03],["Armour breaker","guard_damage",.15],["Hard landing","finisher_damage",.05],["Momentum","launch_force",.08],["Relay weight","chain_damage",.15],["Street sweep","heavy_damage",.04],["Impact link","chain_damage",.05],["Crowd breaker","chain_targets",1.0],["Final punch","damage",.03],["PILE DRIVER","pile_driver",1.0]],
        [["Efficient current","economy",.04],["Light wiring","aerial_damage",.04],["Air specialist","aerial_damage",.12],["Clean landing","finisher_damage",.05],["Flying finish","aerial_damage",.04],["Chase battery","chase_refund",5.0],["Light gear","economy",.03],["Sky route","finisher_damage",.05],["Dive driver","finisher_damage",.15],["Air reserve","economy",.03],["SKY COMMITMENT","sky_commitment",1.0]],
        [["Street armour","defence",.03],["Counter stance","counter_damage",.05],["Live wire parry","parry_meter",4.0],["Braced hands","guard_damage",.05],["Solid shell","defence",.03],["Reversal","counter_damage",.18],["Counter rhythm","economy",.03],["Steady current","defence",.03],["Reserve plate","entry",10.0],["Return strike","counter_damage",.05],["PATIENT STORM","patient_storm",1.0]],
        [["Charged entry","entry",5.0],["Reserve cell","entry",5.0],["Relay circuit","chain_meter",2.0],["Conductive fists","chain_damage",.04],["Shared current","economy",.03],["Broadcast impact","splash",1.0],["Long wire","launch_force",.06],["Crowd routing","chain_damage",.05],["Extra relay","chain_targets",1.0],["Circuit reserve","entry",5.0],["BROADCASTER","broadcaster",1.0]]]
    for branch in 4:
        var angle:float=-PI*.5+branch*PI*.5
        result.append({"id":"hub_%d"%branch,"name":["ZIP","RIVET","HUSH","LOOP"][branch],"kind":"hub","branch":branch,"stat":"","amount":0.0,"at":Vector2(cos(angle)*52*1.15,sin(angle)*52*.58),"links":[]})
        var entries:Array=sets[branch]
        for index in 11:
            var entry:Array=entries[index]
            var radius:float=[110,165,220,270,325,380,270,325,380,425,480][index]
            var offset:float=-.25 if index in [3,4,5] else (.25 if index in [6,7,8] else 0.0)
            var id:String=PREFIXES[branch]+"_"+str(index+1)
            var previous:String="hub_%d"%branch if index==0 else PREFIXES[branch]+"_"+str(index)
            if index==6:previous=PREFIXES[branch]+"_3"
            if index==9:previous=PREFIXES[branch]+"_6"
            var links:Array=[previous]
            if index==9:links.append(PREFIXES[branch]+"_9")
            if index==1:links.append(PREFIXES[(branch+1)%4]+"_2")
            result.append({"id":id,"name":entry[0],"kind":"keystone" if index==10 else ("notable" if index in [2,5,8] else "minor"),"branch":branch,"stat":entry[1],"amount":entry[2],"at":Vector2(cos(angle+offset)*radius*1.15,sin(angle+offset)*radius*.58),"links":links})
    return result

static func by_id(id:String) -> Dictionary:
    for node in nodes():
        if node.id==id:return node
    return {}

static func connected(hero:int,id:String,allocation:Array) -> bool:
    var node:=by_id(id)
    if node.is_empty() or node.kind=="hub" or id in allocation:return false
    var owned:Array=allocation.duplicate();owned.append("hub_%d"%hero)
    if node.kind=="keystone":
        for candidate in allocation:
            if by_id(candidate).get("kind","")=="keystone":return false
    for other in nodes():
        if other.id not in owned:continue
        if other.id in node.links or id in other.links:return true
    return false

static func describe(node:Dictionary) -> String:
    match str(node.stat):
        "pile_driver":return "+25% body impact damage; chain target limit -1."
        "sky_commitment":return "+25% aerial damage; grounded damage -10%."
        "patient_storm":return "Next hit after parry +30%; active skills cost +10%."
        "broadcaster":return "First body impact splashes nearby targets; chain damage -20%. Shared hit/target limits."
        "splash":return "First body impact splashes nearby targets at 25% source damage. One splash per attack."
        "chase_refund":return "Real homing chase refunds 5 meter. Maximum 10 per encounter."
        "parry_meter":return "Successful parry restores 4 extra meter. Maximum 12 per encounter."
        "chain_meter":return "Body chain grants +2 extra meter once per attack, total maximum 8."
        "chain_targets":return "+1 additional body-chain target; combined hard limit 6."
        "entry":return "+%d starting meter once per expedition."%int(node.amount)
    return "%s +%d%%"%[str(node.stat).replace("_"," ").capitalize(),roundi(float(node.amount)*100)]
