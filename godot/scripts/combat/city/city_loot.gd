extends RefCounted
const SLOTS=["WRISTS","SOLES","WAIST"]
const AFFIXES=[
    {"stat":"damage","amount":.025,"name":"STRIKING"},{"stat":"defence","amount":.025,"name":"PLATED"},
    {"stat":"economy","amount":.025,"name":"EFFICIENT"},{"stat":"heavy_damage","amount":.06,"name":"BREAKER"},
    {"stat":"guard_damage","amount":.08,"name":"SIEGE"},{"stat":"chain_damage","amount":.06,"name":"RELAY"},
    {"stat":"aerial_damage","amount":.06,"name":"SKY","skill":"launcher"},{"stat":"finisher_damage","amount":.08,"name":"DIVER","skill":"finisher"}]
static func make(id:int,slot:int,quality:int,item_level:int,skills:Array,seed_value:int) -> Dictionary:
    var random:=RandomNumberGenerator.new();random.seed=seed_value
    var candidates:Array=AFFIXES.filter(func(a:Dictionary)->bool:return not a.has("skill") or a.skill in skills).duplicate(true)
    var affixes:Array=[]
    for i in mini([0,2,3,2][quality],candidates.size()):
        var index:=random.randi_range(0,candidates.size()-1)
        affixes.append(candidates.pop_at(index))
    var special:String=["relay_brace","anchor_brace","counter_cell","broadcast_cell"][posmod(seed_value,4)] if quality==3 else ""
    return {"id":id,"slot":slot,"tier":quality,"level":item_level,"stat":["damage","economy","defence"][slot],"amount":[.015,.025,.035,.045][quality],"name":["SALVAGED","TUNED","RARE","SIGNATURE"][quality]+" "+SLOTS[slot],"affixes":affixes,"special":special}

static func effects(item:Dictionary) -> Dictionary:
    var result:Dictionary={}
    if item.is_empty():return result
    result[item.stat]=float(item.amount)
    for affix in item.get("affixes",[]):result[affix.stat]=float(result.get(affix.stat,0))+float(affix.amount)
    match str(item.get("special","")):
        "relay_brace":result.launch_force=.15;result.damage=float(result.get("damage",0))-.05
        "anchor_brace":result.heavy_damage=.20;result.chain_targets=-1.0
        "counter_cell":result.parry_meter=4.0;result.economy=float(result.get("economy",0))-.05
        "broadcast_cell":result.splash=1.0;result.chain_damage=float(result.get("chain_damage",0))-.15
    return result

static func describe(item:Dictionary) -> String:
    if item.is_empty():return "EMPTY"
    var lines:String="%s / LV%d\n"%[item.name,int(item.get("level",1))]
    for stat in effects(item):
        var amount:float=effects(item)[stat]
        lines+="%s %+d%s\n"%[str(stat).replace("_"," "),roundi(amount if stat in ["entry","parry_meter","chain_targets","splash"] else amount*100),"" if stat in ["entry","parry_meter","chain_targets","splash"] else "%"]
    return lines.strip_edges()
