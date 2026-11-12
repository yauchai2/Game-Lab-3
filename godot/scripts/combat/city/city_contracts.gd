extends RefCounted
const MODIFIERS={
    "reinforcements":{"name":"PATROL CONVOY","text":"Finite extra patrol arrivals, at most six active. Rewards +25%.","reward":.25},
    "capacitor":{"name":"CHARGED STREET","text":"Telegraphed ground hazards; jump or leave the mark. Rewards +25%.","reward":.25},
    "armoured":{"name":"ARMOURED PATROL","text":"Enemy HP +20%; more guards. Rewards +20%.","hp":.20,"reward":.20},
    "rush_hour":{"name":"RUSH HOUR","text":"Extra rusher (six actors maximum). Rewards +20%.","reward":.20},
    "heavy_hits":{"name":"LIVE AMMUNITION","text":"Enemy damage +15%. Rewards +20%.","damage":.15,"reward":.20},
    "salvage":{"name":"HEAVY FREIGHT","text":"Enemy HP +15%; credits +25%.","hp":.15,"reward":.25}}
static func make(id:int,tier:int,sector:int,seed_value:int) -> Dictionary:
    var random:=RandomNumberGenerator.new();random.seed=seed_value
    var pool:Array=MODIFIERS.keys();var mods:Array=[]
    for i in (1 if tier<3 else (2 if tier<5 else 3)):
        mods.append(pool.pop_at(random.randi_range(0,pool.size()-1)))
    return {"id":id,"tier":clampi(tier,1,5),"sector":clampi(sector,0,5),"seed":seed_value,"mods":mods,"waves":3 if tier<3 else (4 if tier<5 else 5)}
static func tuning(contract:Dictionary) -> Dictionary:
    var tier:=int(contract.get("tier",0))
    var result:={"enemy_hp":tier*.12,"enemy_damage":tier*.04,"reward":tier*.2}
    for id in contract.get("mods",[]):
        var mod:Dictionary=MODIFIERS[id]
        result.enemy_hp+=float(mod.get("hp",0));result.enemy_damage+=float(mod.get("damage",0));result.reward+=float(mod.get("reward",0))
    result.enemy_hp=minf(.5,result.enemy_hp);result.enemy_damage=minf(.25,result.enemy_damage)
    if "capacitor" in contract.get("mods",[]):result["hazards"]=1.0
    return result
static func recipe(contract:Dictionary,wave:int) -> Array:
    var random:=RandomNumberGenerator.new();random.seed=int(contract.seed)+wave*997
    var count:=mini(6,3+wave+int(contract.tier>=3))
    var result:Array=[]
    var pool:Array=["grunt","rusher","guard"]
    if int(contract.tier)>=2:pool.append("jammer")
    if int(contract.tier)>=3:pool.append("heavy")
    if int(contract.tier)>=4:pool.append("captain")
    for i in count:result.append(pool[random.randi_range(0,pool.size()-1)])
    if "armoured" in contract.mods:result[0]="guard"
    if "rush_hour" in contract.mods and result.size()<6:result.append("rusher")
    if wave==int(contract.waves)-1:result[0]="guard"
    if "reinforcements" in contract.mods and wave<int(contract.waves)-1:result.append_array(["grunt","rusher","grunt"] )
    return result
static func describe(contract:Dictionary) -> String:
    var result:="T%d / %d WAVES / 3 ATTEMPTS"%[int(contract.tier),int(contract.waves)]
    for id in contract.mods:result+="\n"+MODIFIERS[id].name+": "+MODIFIERS[id].text
    var total:Dictionary=tuning(contract)
    result+="\nTOTAL HP +%d%% / DAMAGE +%d%% (CAPPED)"%[roundi(total.enemy_hp*100),roundi(total.enemy_damage*100)]
    return result
