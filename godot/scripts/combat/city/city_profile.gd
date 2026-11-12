extends RefCounted
## Versioned, atomic account progress. Standard modes never consume this profile.
const Advanced=preload("res://scripts/combat/last_service/progression.gd")
const Story=preload("res://scripts/combat/city/city_story.gd")
const Cores=preload("res://scripts/combat/ability_draw/rewards.gd")
const Balance=preload("res://scripts/combat/city/city_balance.gd")
const Builds=preload("res://scripts/combat/city/city_builds.gd")
const Loot=preload("res://scripts/combat/city/city_loot.gd")
const Contracts=preload("res://scripts/combat/city/city_contracts.gd")
const DISTRICTS=["NEON ALLEY","GATE STREET","UNDERPASS","FREIGHT YARD","LOCKDOWN AVE","CORE TOWER"]
const SKILLS=[{"id":"double_jump","name":"DOUBLE JUMP","at":1},{"id":"launcher","name":"LAUNCHER","at":3},{"id":"chase","name":"AIR CHASE","at":4},{"id":"finisher","name":"AIR FINISHER","at":6},{"id":"overdrive","name":"OVERDRIVE","at":7}]
const SLOTS=Loot.SLOTS
var path:="user://neon_lab/city_v1.json"
var data:Dictionary={}
var error:=""
var loaded_backup:=false
var migration_source:=""
var migration_notice:=""
var migration_version:=1
var rng:=RandomNumberGenerator.new()

func _init() -> void:rng.randomize();data=fresh()
func fresh() -> Dictionary:
    return {"version":3,"advanced":[[],[],[],[]],"quest_claims":[],"core_offer":{},"pending_core":"","core_serial":0,"craft_serial":0,"credits":0,"parts":0,"best":0,"points":0,"xp":0,"skills":[],"skill_levels":[0,0,0,0],"talents":[[],[],[],[]],"gear":[{},{},{}],"loadouts":[[{},{},{}],[{},{},{}],[{},{},{}],[{},{},{}]],"inventory":[],"stash":[],"pulls":0,"pity":0,"unique_pity":0,"item_serial":0,"serial":0,"attempts":0,"dialogue":0,"claims":[],"run":{},"contracts":[],"contract_serial":0,"contract_tier":1,"contract_wins":[0,0,0,0,0],"last_loot":[]}
func level() -> int:return mini(20,1+floori(float(data.xp)/100.0))
func _points() -> void:data.points=mini(25,level()-1+floori(float(data.best)/3.0))

func valid(item:Variant) -> bool:
    if not item is Dictionary or int(item.get("version",0))!=3:return false
    for key in fresh():
        if not item.has(key):return false
        if typeof(item[key])!=typeof(fresh()[key]) and not (fresh()[key] is int and item[key] is float):return false
    for key in ["credits","parts","best","points","xp","pulls","pity","unique_pity","item_serial","serial","attempts","dialogue","contract_serial"]:
        if item[key]<0:return false
    if item.best>18 or item.points>25 or item.xp>1900 or item.contract_tier<1 or item.contract_tier>5:return false
    if item.advanced.size()!=4:return false
    for hero in 4:
        if not item.advanced[hero] is Array or item.advanced[hero].size()>2:return false
        for id in item.advanced[hero]:
            if not Advanced.SKILLS[hero].any(func(skill:Dictionary)->bool:return skill.id==id):return false
    if item.talents.size()!=4 or item.loadouts.size()!=4 or item.skill_levels.size()!=4 or item.gear.size()!=3 or item.contract_wins.size()!=5:return false
    if item.inventory.size()>60 or item.stash.size()>120 or item.contracts.size()>60 or item.claims.size()>256:return false
    for hero in 4:
        var allocation:Variant=item.talents[hero]
        if not allocation is Array or allocation.size()>25:return false
        var seen:Array=[];var keys:=0
        for id in allocation:
            if not id is String or id in seen or not Builds.connected(hero,id,seen):return false
            seen.append(id)
            if Builds.by_id(id).kind=="keystone":keys+=1
        if keys>1:return false
    for rank in item.skill_levels:
        if not (rank is int or rank is float) or rank<0 or rank>3:return false
    for skill in item.skills:
        if not SKILLS.any(func(s:Dictionary)->bool:return s.id==skill):return false
    for stored in item.inventory+item.stash:
        if not stored is Dictionary or stored.is_empty():return false
    var equipment:Array=item.inventory+item.stash+item.gear
    for loadout in item.loadouts:
        if not loadout is Array or loadout.size()!=3:return false
        equipment+=loadout
    for gear in equipment:
        if not _valid_gear(gear):return false
    for contract in item.contracts:
        if not _valid_contract(contract):return false
    if item.pending_core!="" and Cores.item(item.pending_core).is_empty():return false
    if not item.core_offer.is_empty() and (not item.core_offer.has("id") or Cores.item(item.core_offer.id).is_empty() or not item.core_offer.has("boundary") or not item.core_offer.has("seed")):return false
    var run:Dictionary=item.run
    if not run.is_empty():
        if run.get("core","")!="" and Cores.item(run.core).is_empty():return false
        if int(run.get("core_healed",0))<0 or int(run.get("core_healed",0))>12:return false
        if run.get("mode","story") not in ["story","contract"]:return false
        for key in ["id","hero","room","hp","meter","boons","boon_due"]:
            if not run.has(key):return false
        for key in ["id","hero","room","hp","meter"]:
            if not (run[key] is int or run[key] is float):return false
        if run.hero<0 or run.hero>3 or run.room<0 or run.room>=18 or run.hp<1 or run.hp>100 or run.meter<0 or run.meter>100:return false
        if not run.boons is Dictionary or not run.boon_due is bool or not run.get("in_flight",false) is bool:return false
        for stat in run.boons:
            if stat not in ["damage","defence","economy"] or not (run.boons[stat] is float or run.boons[stat] is int):return false
            if run.boons[stat]<0 or run.boons[stat]>.30:return false
        if run.get("mode","story")=="contract":
            if not _valid_contract(run.get("contract",{})):return false
            if int(run.get("wave",-1))<0 or int(run.wave)>=int(run.contract.waves) or int(run.get("tries",0))<1 or int(run.tries)>3:return false
    return true

func _valid_gear(item:Variant) -> bool:
    if not item is Dictionary:return false
    if item.is_empty():return true
    for key in ["id","slot","tier","stat","amount","name"]:
        if not item.has(key):return false
    for key in ["id","slot","tier","amount"]:
        if not (item[key] is int or item[key] is float):return false
    if item.slot<0 or item.slot>2 or item.tier<0 or item.tier>3 or item.amount<0 or item.amount>.1:return false
    if item.stat not in ["damage","defence","economy"] or not item.name is String:return false
    if not item.get("affixes",[]) is Array:return false
    for affix in item.get("affixes",[]):
        if not affix is Dictionary or not affix.has("stat") or not affix.has("amount"):return false
        if not Loot.AFFIXES.any(func(a:Dictionary)->bool:return a.stat==affix.stat):return false
        if not (affix.amount is float or affix.amount is int) or affix.amount<0 or affix.amount>.2:return false
    return item.get("special","") in ["","relay_brace","anchor_brace","counter_cell","broadcast_cell"]

func _valid_contract(item:Variant) -> bool:
    if not item is Dictionary:return false
    for key in ["id","tier","sector","seed","mods","waves"]:
        if not item.has(key):return false
    for key in ["id","tier","sector","seed","waves"]:
        if not (item[key] is int or item[key] is float):return false
    if item.tier<1 or item.tier>5 or item.sector<0 or item.sector>5 or item.waves<3 or item.waves>5 or not item.mods is Array:return false
    if item.mods.size()>3:return false
    for id in item.mods:
        if not Contracts.MODIFIERS.has(id):return false
    return true

func migrate(old:Dictionary) -> Dictionary:
    var converted:=fresh()
    for key in converted:
        if old.has(key) and key not in ["version","talents","points","xp","loadouts"]:converted[key]=old[key].duplicate(true) if old[key] is Array or old[key] is Dictionary else old[key]
    converted.xp=clampi((int(old.get("points",0))-floori(float(old.get("best",0))/3.0))*100,0,1900)
    converted.points=mini(25,1+floori(float(converted.xp)/100.0)-1+floori(float(converted.best)/3.0))
    for hero in 4:converted.loadouts[hero]=converted.gear.duplicate(true)
    for gear in converted.inventory:
        if not gear.is_empty():converted.item_serial=maxi(int(converted.item_serial),int(gear.id))
    return converted

func expand(previous:Dictionary) -> Dictionary:
    var converted:=fresh()
    for key in previous:
        if key in converted and key!="version":converted[key]=previous[key].duplicate(true) if previous[key] is Dictionary or previous[key] is Array else previous[key]
    return converted

func load_data() -> void:
    error="";loaded_backup=false;migration_source="";migration_notice=""
    if path=="":return
    for source in [path,path+".bak"]:
        if not FileAccess.file_exists(source):continue
        var parser:=JSON.new()
        if parser.parse(FileAccess.get_file_as_string(source))!=OK or not parser.data is Dictionary:continue
        var candidate:Dictionary=parser.data
        var old_version:=int(candidate.get("version",0))
        var legacy:bool=old_version in [1,2]
        if old_version==1:
            if not candidate.has("gear") or not candidate.has("inventory") or not candidate.has("best") or not candidate.has("points"):continue
            candidate=migrate(candidate)
        elif old_version==2:candidate=expand(candidate)
        if not valid(candidate):continue
        data=candidate;loaded_backup=source.ends_with(".bak")
        if legacy:
            migration_source=source;migration_version=old_version;migration_notice="Circuit expanded. Old allocations refunded; skills, gear and point budget preserved." if old_version==1 else "Campaign expanded. Your skills, talent paths and equipment are preserved."
        return
    if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak"):error="Save unreadable. Originals preserved; transactions disabled."

func save_data() -> bool:
    if path=="":return true
    var full:=ProjectSettings.globalize_path(path)
    if DirAccess.make_dir_recursive_absolute(full.get_base_dir())!=OK:return false
    var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
    if file==null:return false
    file.store_string(JSON.stringify(data));file.flush();var ok:bool=file.get_error()==OK;file.close()
    if not ok:return false
    if migration_source!="" and not FileAccess.file_exists(path+".v%d.bak"%migration_version):
        if DirAccess.copy_absolute(ProjectSettings.globalize_path(migration_source),full+".v%d.bak"%migration_version)!=OK:return false
    if FileAccess.file_exists(path) and not loaded_backup:
        if DirAccess.copy_absolute(full,full+".bak")!=OK:return false
    var renamed:bool=DirAccess.rename_absolute(full+".tmp",full)==OK
    if renamed:loaded_backup=false;migration_source=""
    return renamed
func commit(before:Dictionary) -> bool:
    if error!="" or not save_data():data=before;error="Save failed. Action cancelled; reload saved profile to retry.";return false
    return true
func retry_save() -> bool:load_data();return error==""

func start_run(hero:int,sector:=0) -> bool:
    if not data.run.is_empty() or sector<0 or sector>mini(5,floori(float(data.best)/3.0)) or hero<0 or hero>3:return false
    var before:=data.duplicate(true);data.serial+=1;data.attempts+=1
    data.run={"id":int(data.serial),"hero":hero,"room":sector*3,"hp":100,"meter":60.0,"boons":{},"boon_due":false,"mode":"story","seed":rng.randi_range(1,2000000000),"core":data.pending_core,"core_healed":0,"route":"combat"}
    data.pending_core=""
    return commit(before)
func start_contract(hero:int,id:int) -> bool:
    if not data.run.is_empty() or hero<0 or hero>3 or data.best<18:return false
    for i in data.contracts.size():
        if int(data.contracts[i].id)!=id:continue
        var before:=data.duplicate(true);var contract:Dictionary=data.contracts.pop_at(i)
        data.serial+=1;data.attempts+=1
        data.run={"id":int(data.serial),"hero":hero,"room":int(contract.sector)*3,"hp":100,"meter":60.0,"boons":{},"boon_due":false,"mode":"contract","seed":int(contract.seed),"contract":contract,"wave":0,"tries":3,"core":data.pending_core,"core_healed":0,"route":"combat"}
        data.pending_core=""
        return commit(before)
    return false
func _contract(tier:int,sector:int,seed_value:int) -> void:
    if data.contracts.size()>=60:data.parts+=3;return
    data.contract_serial+=1;data.contracts.append(Contracts.make(int(data.contract_serial),tier,sector,seed_value))
func _store(item:Dictionary,hero:int) -> void:
    if data.inventory.size()<60:data.inventory.append(item)
    elif data.stash.size()<120:data.stash.append(item)
    else:
        data.parts+=1+int(item.tier);data.last_loot.append("FULL STORAGE: item recycled to parts");return
    data.last_loot.append(item.name)
    if data.loadouts[hero][int(item.slot)].is_empty():data.loadouts[hero][int(item.slot)]=item.duplicate(true)
    data.gear=data.loadouts[0].duplicate(true)
func _drop(hero:int,quality:int,seed_value:int,item_level:int) -> void:
    data.item_serial+=1
    var item:Dictionary=Loot.make(int(data.item_serial),posmod(seed_value,3),quality,item_level,data.skills,seed_value)
    _store(item,hero)
func settle(won:bool,hp:int,meter:float,healed:=-1,techniques:Dictionary={}) -> bool:
    if data.run.is_empty() or not data.run.get("in_flight",false):return false
    var before:=data.duplicate(true);var run:Dictionary=data.run
    var challenge:bool=run.get("mode","story")=="contract"
    var wave:=int(run.get("wave",run.room));var claim:="%d:%d"%[int(run.id),wave]
    if won and claim in data.claims:return false
    run.in_flight=false;data.last_loot=[]
    if healed>=0:run["core_healed"]=clampi(healed,0,12)
    if won:
        data.claims.append(claim)
        if data.claims.size()>256:data.claims.pop_front()
        var previous_best:=int(data.best)
        var room:=int(run.room);var sector:=floori(float(room)/3.0)
        var tier:int=int(run.contract.tier) if challenge else 0
        var tuning:Dictionary=Contracts.tuning(run.contract) if challenge else {"reward":0.0}
        var credits:=roundi((45+tier*10)*(1.0+float(tuning.reward))) if challenge else 70+sector*10
        if not challenge and data.best==0:credits+=30
        if run.get("route","")=="hazard":credits=roundi(credits*1.2)
        data.credits+=credits;data.parts+=1;data.last_loot.append("+%d CREDITS / +1 PART"%credits)
        data.xp=mini(1900,int(data.xp)+(100 if data.best==0 and not challenge else 50+sector*10+tier*10))
        if not challenge:data.best=maxi(int(data.best),room+1)
        _points()
        var seed_value:=int(run.get("seed",run.id))+wave*997
        var quality:=1 if posmod(seed_value,10)<7 else 2
        var final:bool=wave==int(run.contract.waves)-1 if challenge else room==17
        if posmod(seed_value,100)==0:quality=3
        if final:quality=3 if not challenge and previous_best<18 else maxi(2,quality)
        _drop(int(run.hero),quality,seed_value,1+sector+tier*2)
        if run.get("route","")=="cache":_drop(int(run.hero),1,seed_value+39,1+sector+tier)
        for technique in techniques:
            if technique in Story.TECHNIQUES and int(techniques[technique])>0 and technique not in data.quest_claims:
                data.quest_claims.append(technique);data.credits+=30;data.parts+=1;data.last_loot.append("FIRST TECHNIQUE: "+str(technique).to_upper())
        run.hp=clampi(hp,1,100);run.meter=clampf(meter,0,100);run.boon_due=true;run["route_due"]=true;run["route"]="combat"
        if challenge:
            run.wave+=1
            if final:
                data.contract_wins[tier-1]+=1;_contract(tier,sector,seed_value+71)
                if tier<5 and int(data.contract_wins[tier-1])%2==0:
                    data.contract_tier=maxi(int(data.contract_tier),tier+1);_contract(tier+1,sector,seed_value+89)
                data.credits+=tier*100;data.last_loot.append("CONTRACT COMPLETE / SAME TIER RETURNED");data.run={}
        else:
            run.room+=1
            if room%3==2 and data.best>=18:_contract(1,sector,seed_value+19)
            if final:data.run={}
    elif challenge and int(run.tries)>1:
        run.tries-=1;run.boon_due=false;data.last_loot.append("CONTRACT RETRY: %d ATTEMPTS LEFT"%int(run.tries))
    else:data.run={}
    return commit(before)
func abandon() -> bool:
    var before:=data.duplicate(true);data.run={};return commit(before)
func choose_boon(id:String) -> bool:
    if data.run.is_empty() or not data.run.boon_due or id not in ["damage","defence","economy"] or float(data.run.boons.get(id,0))>=.30 or boon_gain(id)<=0:return false
    var before:=data.duplicate(true);data.run.boons[id]=minf(.30,float(data.run.boons.get(id,0))+.05);data.run.boon_due=false
    return commit(before)
func learn(id:String) -> bool:
    if id in data.skills or not SKILLS.any(func(s:Dictionary)->bool:return s.id==id and int(data.best)>=s.at):return false
    var before:=data.duplicate(true);data.skills.append(id);return commit(before)
func allocate(hero:int,id:String) -> bool:
    if hero<0 or hero>3 or data.talents[hero].size()>=int(data.points) or not Builds.connected(hero,id,data.talents[hero]):return false
    var before:=data.duplicate(true);data.talents[hero].append(id);return commit(before)
func respec(hero:int) -> bool:
    if hero<0 or hero>3:return false
    var before:=data.duplicate(true);data.talents[hero]=[];return commit(before)
func gear_for(hero:int) -> Array:return data.loadouts[hero]
func stats(hero:int) -> Dictionary:
    var result:={"damage":0.0,"defence":0.0,"economy":0.0,"entry":0.0,"skill_damage":float(data.skill_levels[hero])*.05,"heavy_damage":0.0,"aerial_damage":0.0,"finisher_damage":0.0,"guard_damage":0.0,"launch_force":0.0,"chain_damage":0.0,"chain_targets":0.0,"chain_meter":0.0,"splash":0.0,"parry_meter":0.0,"chase_refund":0.0,"counter_damage":0.0}
    for id in data.talents[hero]:
        var node:Dictionary=Builds.by_id(id)
        match str(node.stat):
            "pile_driver":result.chain_damage+=.25;result.chain_targets-=1
            "sky_commitment":result.aerial_damage+=.25;result["ground_penalty"]=-.10
            "patient_storm":result.counter_damage+=.30;result.economy-=.10
            "broadcaster":result.splash=1;result.chain_damage-=.20
            _:result[node.stat]+=node.amount
    var equipment_stats:Dictionary={}
    for item in gear_for(hero):
        var effects:Dictionary=Loot.effects(item)
        for stat in effects:equipment_stats[stat]=float(equipment_stats.get(stat,0))+float(effects[stat])
    for stat in Balance.equipment(equipment_stats):result[stat]=float(result.get(stat,0))+float(Balance.equipment(equipment_stats)[stat])
    if not data.run.is_empty():
        for stat in data.run.boons:result[stat]+=float(data.run.boons[stat])
    result=Balance.cap(result)
    return result
func heal() -> bool:
    if data.run.is_empty() or int(data.run.hp)>=100 or data.credits<25:return false
    var before:=data.duplicate(true);data.credits-=25;data.run.hp=mini(100,int(data.run.hp)+40);return commit(before)
func pull(slot:int,hero:=0) -> Dictionary:
    if slot<0 or slot>2 or hero<0 or hero>3 or data.credits<100 or data.inventory.size()+data.stash.size()>=180:return {}
    var before:=data.duplicate(true);data.credits-=100;data.pulls+=1;data.pity+=1;data.unique_pity+=1
    var roll:=rng.randi_range(1,100)
    var quality:=3 if roll==100 or int(data.unique_pity)>=40 else (2 if roll>=81 or int(data.pity)>=10 else (1 if roll>=26 else 0))
    if quality>=2:data.pity=0
    if quality==3:data.unique_pity=0
    data.item_serial+=1;data.last_loot=[]
    var item:Dictionary=Loot.make(int(data.item_serial),slot,quality,1+floori(float(data.best)/3.0)+int(data.contract_tier),data.skills,rng.randi_range(1,2000000000))
    _store(item,hero)
    if not commit(before):return {}
    return item
func equip(id:int,hero:=0) -> bool:
    if hero<0 or hero>3:return false
    for item in data.inventory+data.stash:
        if int(item.id)!=id:continue
        var before:=data.duplicate(true);data.loadouts[hero][int(item.slot)]=item.duplicate(true);data.gear=data.loadouts[0].duplicate(true);return commit(before)
    return false
func salvage(id:int) -> bool:
    for loadout in data.loadouts:
        for item in loadout:
            if not item.is_empty() and int(item.id)==id:return false
    for storage in [data.inventory,data.stash]:
        for i in storage.size():
            if int(storage[i].id)!=id:continue
            var before:=data.duplicate(true);data.parts+=1+int(storage[i].tier);storage.remove_at(i);return commit(before)
    return false
func recipe(room:int) -> Array:
    var result:Array=[["grunt","grunt","grunt"],["grunt","rusher","grunt","rusher"],["guard","grunt","rusher","grunt","guard","grunt"]][posmod(room,3)].duplicate()
    if room>=6:result[0]="jammer"
    if room>=9:result[1]="heavy"
    if room>=12:result[2]="captain"
    if room>=12 and room%3==1:result.append_array(["grunt","rusher","grunt","guard"])
    return result
func upgrade_skill(hero:int) -> bool:
    if hero<0 or hero>3:return false
    var rank:=int(data.skill_levels[hero]);var cost:=2+rank
    if rank>=3 or data.parts<cost or data.credits<30:return false
    var before:=data.duplicate(true);data.parts-=cost;data.credits-=30;data.skill_levels[hero]=rank+1;return commit(before)
func unequip(slot:int,hero:int) -> bool:
    if slot<0 or slot>2 or hero<0 or hero>3:return false
    var before:=data.duplicate(true);data.loadouts[hero][slot]={};data.gear=data.loadouts[0].duplicate(true);return commit(before)
func is_equipped(id:int) -> bool:
    for loadout in data.loadouts:
        for item in loadout:
            if not item.is_empty() and int(item.id)==id:return true
    return false

func choose_route(id:String) -> bool:
    if data.run.is_empty() or not data.run.get("route_due",false) or id not in route_options():return false
    var before:=data.duplicate(true);data.run.route=id;data.run.route_due=false
    if id=="rest":data.run.hp=mini(100,int(data.run.hp)+20)
    return commit(before)
func route_options() -> Array:
    if data.run.is_empty():return []
    return ["combat","hazard","rest"] if int(data.run.room) in [3,6,9,11,15,17] else ["combat","hazard","cache"]
func roll_core() -> Dictionary:
    if not can_prepare_core():return {}
    if not data.core_offer.is_empty():return data.core_offer
    if data.parts<1:return {}
    var before:=data.duplicate(true);data.parts-=1;data.core_serial+=1
    data.core_offer={"id":Cores.ITEMS[rng.randi_range(0,8)].id,"seed":rng.randi_range(1,2000000000),"boundary":"city:%d"%int(data.core_serial)}
    if not commit(before):return {}
    return data.core_offer
func claim_core() -> bool:
    if data.core_offer.is_empty() or not can_prepare_core():return false
    var before:=data.duplicate(true)
    if data.run.is_empty():data.pending_core=data.core_offer.id
    else:
        data.run["core"]=data.core_offer.id;data.run["core_healed"]=0
        if data.core_offer.id=="charge" and data.run.get("entered",false):data.run.meter=minf(100,float(data.run.meter)+20)
    data.core_offer={};return commit(before)
func _refresh_item(item:Dictionary) -> void:
    for hero in 4:
        for slot in 3:
            if not data.loadouts[hero][slot].is_empty() and int(data.loadouts[hero][slot].id)==int(item.id):data.loadouts[hero][slot]=item.duplicate(true)
    data.gear=data.loadouts[0].duplicate(true)
func craft(id:int,kind:String,index:=0) -> bool:
    if kind not in ["recalibrate","temper"]:return false
    for item in data.inventory+data.stash:
        if int(item.id)!=id:continue
        var temper:bool=kind=="temper"
        if data.parts<(6 if temper else 5) or data.credits<(120 if temper else 80):return false
        if temper and int(item.tier)>=2:return false
        if not temper and (index<0 or index>=item.get("affixes",[]).size()):return false
        var before:=data.duplicate(true);data.parts-=6 if temper else 5;data.credits-=120 if temper else 80;data.craft_serial+=1
        if temper:
            var improved:Dictionary=Loot.make(int(item.id),int(item.slot),int(item.tier)+1,int(item.get("level",1)),data.skills,int(data.craft_serial)*997+id)
            improved.amount=maxf(float(item.amount),float(improved.amount))
            item.merge(improved,true)
        else:
            var pool:Array=Loot.AFFIXES.filter(func(a:Dictionary)->bool:return (not a.has("skill") or a.skill in data.skills) and a.stat!=item.affixes[index].stat)
            item.affixes[index]=pool[posmod(int(data.craft_serial)*31+id,pool.size())].duplicate(true)
        _refresh_item(item);data.last_loot=["WORKSHOP: "+kind.to_upper()];return commit(before)
    return false

func advanced_skill(hero:int,id:String) -> bool:
    if hero<0 or hero>3:return false
    var index:int=Advanced.SKILLS[hero].find_custom(func(skill:Dictionary)->bool:return skill.id==id)
    if index<0 or int(data.best)<[9,12,15][index]:return false
    var equipped:Array=data.advanced[hero]
    if id not in equipped and equipped.size()>=2:return false
    var before:=data.duplicate(true)
    if id in equipped:equipped.erase(id)
    else:equipped.append(id)
    return commit(before)
func boon_gain(id:String) -> float:
    if data.run.is_empty() or id not in ["damage","defence","economy"]:return 0.0
    var hero:=int(data.run.hero);var before:=float(stats(hero)[id]);var old:float=float(data.run.boons.get(id,0))
    data.run.boons[id]=minf(.30,old+.05);var after:=float(stats(hero)[id])
    if old==0:data.run.boons.erase(id)
    else:data.run.boons[id]=old
    return maxf(0,after-before)
func skip_boon() -> bool:
    if data.run.is_empty() or not data.run.boon_due:return false
    var before:=data.duplicate(true);data.run.boon_due=false;data.credits+=10;return commit(before)

func can_prepare_core() -> bool:
    return data.pending_core=="" and (data.run.is_empty() or (data.run.get("core","")=="" and not data.run.get("in_flight",false)))
