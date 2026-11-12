extends RefCounted
## Independent campaign save. Transactions snapshot and roll back on disk failure.
const DISTRICTS=["NEON ALLEY","GATE STREET","UNDERPASS","FREIGHT YARD","LOCKDOWN AVE","CORE TOWER"]
const TALENTS=[
    {"id":"break_1","name":"Heavy hands","branch":0,"rank":0,"stat":"damage","amount":.04},
    {"id":"break_2","name":"Impact circuit","branch":0,"rank":1,"stat":"damage","amount":.06},
    {"id":"break_3","name":"Glass cannon","branch":0,"rank":2,"stat":"damage","amount":.12},
    {"id":"air_1","name":"Efficient current","branch":1,"rank":0,"stat":"economy","amount":.04},
    {"id":"air_2","name":"Lightweight wiring","branch":1,"rank":1,"stat":"economy","amount":.06},
    {"id":"air_3","name":"Skill specialist","branch":1,"rank":2,"stat":"economy","amount":.10},
    {"id":"guard_1","name":"Street armour","branch":2,"rank":0,"stat":"defence","amount":.04},
    {"id":"guard_2","name":"Reinforced shell","branch":2,"rank":1,"stat":"defence","amount":.06},
    {"id":"guard_3","name":"Heavy plating","branch":2,"rank":2,"stat":"defence","amount":.10},
    {"id":"flow_1","name":"Charged entry","branch":3,"rank":0,"stat":"entry","amount":5.0},
    {"id":"flow_2","name":"Reserve cell","branch":3,"rank":1,"stat":"entry","amount":5.0},
    {"id":"flow_3","name":"Overclock","branch":3,"rank":2,"stat":"entry","amount":15.0}]
const SKILLS=[{"id":"double_jump","name":"DOUBLE JUMP","at":1},{"id":"launcher","name":"LAUNCHER","at":3},{"id":"chase","name":"AIR CHASE","at":4},{"id":"finisher","name":"AIR FINISHER","at":6},{"id":"overdrive","name":"OVERDRIVE","at":7}]
const SLOTS=["WRISTS","SOLES","WAIST"]
var path:="user://neon_lab/city_v1.json"
var data:Dictionary={}
var error:=""
var loaded_backup:=false
var rng:=RandomNumberGenerator.new()

func _init() -> void:
    rng.randomize();data=fresh()

func fresh() -> Dictionary:
    return {"version":1,"credits":0,"parts":0,"best":0,"points":0,"skills":[],"skill_levels":[0,0,0,0],"talents":[[],[],[],[]],"gear":[{},{},{}],"inventory":[],"pulls":0,"pity":0,"unique_pity":0,"serial":0,"attempts":0,"dialogue":0,"claims":[],"run":{}}

func valid(value:Variant) -> bool:
    if not value is Dictionary or value.get("version",0)!=1:return false
    for key in fresh():
        if not value.has(key) or typeof(value[key])!=typeof(fresh()[key]):
            # JSON integers are parsed as floats.
            if not value.has(key) or not (fresh()[key] is int and value[key] is float):return false
    if value.talents.size()!=4 or value.gear.size()!=3 or value.skill_levels.size()!=4:return false
    for rank in value.skill_levels:
        if not (rank is int or rank is float) or rank<0 or rank>3:return false
    for skill in value.skills:
        if not skill is String or not SKILLS.any(func(t:Dictionary)->bool:return t.id==skill):return false
    if value.inventory.size()>60:return false
    for gear in value.inventory+value.gear:
        if not gear is Dictionary:return false
        if gear.is_empty():continue
        for key in ["id","slot","tier","stat","amount","name"]:
            if not gear.has(key):return false
        if not gear.stat is String or gear.stat not in ["damage","defence","economy"] or not gear.name is String:return false
        for key in ["id","slot","tier","amount"]:
            if not (gear[key] is int or gear[key] is float):return false
        if gear.slot<0 or gear.slot>2 or gear.tier<0 or gear.tier>3 or gear.amount<0 or gear.amount>.1:return false
    for allocation in value.talents:
        if not allocation is Array or allocation.size()>12:return false
        for id in allocation:
            if not id is String or not TALENTS.any(func(t:Dictionary)->bool:return t.id==id):return false
    for key in ["credits","parts","best","points","pity","unique_pity","pulls","serial","attempts","dialogue"]:
        if value[key]<0:return false
    if value.points>8 or value.best>18:return false
    if not value.run.is_empty():
        for key in ["id","room","hp","meter","boons","boon_due","hero"]:
            if not value.run.has(key):return false
        if not value.run.boons is Dictionary or not value.run.boon_due is bool:return false
        for stat in value.run.boons:
            if stat not in ["damage","defence","economy"] or not (value.run.boons[stat] is int or value.run.boons[stat] is float):return false
        for key in ["id","room","hp","meter","hero"]:
            if not (value.run[key] is int or value.run[key] is float):return false
        if value.run.get("in_flight",false) is not bool:return false
        if int(value.run.room)<0 or int(value.run.room)>=18 or int(value.run.hero)<0 or int(value.run.hero)>3:return false
    return true

func load_data() -> void:
    error="";loaded_backup=false
    if path=="":return
    for source in [path,path+".bak"]:
        if not FileAccess.file_exists(source):continue
        var parser:=JSON.new()
        if parser.parse(FileAccess.get_file_as_string(source))!=OK:continue
        var parsed:Variant=parser.data
        if valid(parsed):data=parsed;loaded_backup=source.ends_with(".bak");return
    if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak"):error="Save unreadable. Original files preserved; purchases disabled."

func save_data() -> bool:
    if path=="":return true
    var full:=ProjectSettings.globalize_path(path)
    if DirAccess.make_dir_recursive_absolute(full.get_base_dir())!=OK:return false
    var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
    if file==null:return false
    file.store_string(JSON.stringify(data));file.flush()
    var ok:bool=file.get_error()==OK;file.close()
    if not ok:return false
    if FileAccess.file_exists(path) and not loaded_backup:
        if DirAccess.copy_absolute(full,full+".bak")!=OK:return false
    var renamed:bool=DirAccess.rename_absolute(full+".tmp",full)==OK
    if renamed:loaded_backup=false
    return renamed

func commit(before:Dictionary) -> bool:
    if error!="" or not save_data():
        data=before;error="Save failed. Progress kept in the last saved state; action cancelled."
        return false
    return true

func retry_save() -> bool:
    # Re-read retained primary/backup; never overwrite unreadable saves with defaults.
    error="";load_data()
    return error==""

func start_run(hero:int,sector:=0) -> bool:
    if not data.run.is_empty() or sector>mini(5,floori(float(data.best)/3.0)) or hero<0 or hero>3:return false
    var before:=data.duplicate(true)
    data.serial+=1;data.attempts+=1
    data.run={"id":int(data.serial),"hero":hero,"room":sector*3,"hp":100,"meter":60.0,"boons":{},"boon_due":false}
    return commit(before)

func settle(won:bool,hp:int,meter:float) -> bool:
    if data.run.is_empty() or not data.run.get("in_flight",false):return false
    var before:=data.duplicate(true)
    data.run.in_flight=false
    var room:=int(data.run.room)
    if won:
        var claim:="%d:%d"%[int(data.run.id),room]
        if claim in data.claims:return false
        data.claims.append(claim)
        if data.claims.size()>256:data.claims.pop_front()
        data.credits+=45+floori(float(room)/3.0)*10;data.parts+=1
        if room>=int(data.best):data.best=room+1;data.points=mini(8,int(data.points)+1)
        data.run.room=room+1;data.run.hp=clampi(hp,1,100);data.run.meter=clampf(meter,0,100)
        data.run.boon_due=true
        if room==17:data.run={}
    else:data.run={}
    return commit(before)

func abandon() -> bool:
    var before:=data.duplicate(true);data.run={}
    return commit(before)

func choose_boon(id:String) -> bool:
    if data.run.is_empty() or not data.run.boon_due or id not in ["damage","defence","economy"]:return false
    var before:=data.duplicate(true)
    data.run.boons[id]=minf(.30,float(data.run.boons.get(id,0))+.05)
    data.run.boon_due=false
    return commit(before)

func learn(id:String) -> bool:
    if id in data.skills:return false
    var index:=SKILLS.find_custom(func(s:Dictionary)->bool:return s.id==id and int(data.best)>=s.at)
    if index<0:return false
    var before:=data.duplicate(true);data.skills.append(id)
    return commit(before)

func allocate(hero:int,id:String) -> bool:
    var tree:Array=data.talents[hero]
    var index:=TALENTS.find_custom(func(t:Dictionary)->bool:return t.id==id)
    if index<0 or id in tree or tree.size()>=int(data.points):return false
    var node:Dictionary=TALENTS[index]
    if int(node.rank)>0 and TALENTS[index-1].id not in tree:return false
    var before:=data.duplicate(true);data.talents[hero].append(id)
    return commit(before)

func respec(hero:int) -> bool:
    var before:=data.duplicate(true);data.talents[hero]=[]
    return commit(before)

func stats(hero:int) -> Dictionary:
    var result:={"damage":0.0,"defence":0.0,"economy":0.0,"entry":0.0,"skill_damage":float(data.skill_levels[hero])*.05}
    for node in TALENTS:
        if node.id in data.talents[hero]:result[node.stat]+=node.amount
    # Keystone tradeoffs, visible in the city UI.
    if "break_3" in data.talents[hero]:result.defence-=.06
    if "guard_3" in data.talents[hero]:result.damage-=.06
    if "flow_3" in data.talents[hero]:result.economy-=.06
    for gear in data.gear:
        if not gear.is_empty():result[gear.stat]+=float(gear.amount)
    if not data.run.is_empty():
        for stat in data.run.boons:result[stat]+=float(data.run.boons[stat])
    result.damage=clampf(result.damage,-.2,.50);result.defence=clampf(result.defence,-.2,.40);result.economy=clampf(result.economy,-.2,.35)
    return result

func heal() -> bool:
    if data.run.is_empty() or int(data.run.hp)>=100 or data.credits<25:return false
    var before:=data.duplicate(true)
    data.credits-=25;data.run.hp=mini(100,int(data.run.hp)+40)
    return commit(before)

func pull(slot:int) -> Dictionary:
    if slot<0 or slot>2 or data.credits<100 or data.inventory.size()>=60:return {}
    var before:=data.duplicate(true)
    data.credits-=100;data.pulls+=1;data.pity+=1;data.unique_pity+=1
    var roll:=rng.randi_range(1,100)
    var tier:=3 if roll==100 or int(data.unique_pity)>=40 else (2 if roll>=81 or int(data.pity)>=10 else (1 if roll>=26 else 0))
    if tier>=2:data.pity=0
    if tier==3:data.unique_pity=0
    var stat:String=["damage","economy","defence"][slot]
    var gear:={"id":int(data.pulls),"slot":slot,"tier":tier,"stat":stat,"amount":[.02,.04,.07,.10][tier],"name":["SALVAGED","TUNED","RARE","SIGNATURE"][tier]+" "+SLOTS[slot]}
    data.inventory.append(gear)
    if data.gear[slot].is_empty():data.gear[slot]=gear.duplicate(true)
    if not commit(before):return {}
    return gear

func equip(id:int) -> bool:
    for gear in data.inventory:
        if int(gear.id)!=id:continue
        var before:=data.duplicate(true);data.gear[int(gear.slot)]=gear.duplicate(true)
        return commit(before)
    return false

func salvage(id:int) -> bool:
    for gear in data.gear:
        if not gear.is_empty() and int(gear.id)==id:return false
    for i in data.inventory.size():
        if int(data.inventory[i].id)!=id:continue
        var before:=data.duplicate(true)
        data.parts+=1+int(data.inventory[i].tier);data.inventory.remove_at(i)
        return commit(before)
    return false

func buy_point() -> bool:
    if data.parts<5 or int(data.points)>=8:return false
    var before:=data.duplicate(true);data.parts-=5;data.points+=1
    return commit(before)

func recipe(room:int) -> Array:
    var result:Array=[["grunt","grunt","grunt"],["grunt","rusher","grunt","rusher"],["guard","grunt","rusher","grunt","guard","grunt"]][room%3].duplicate()
    if room>=6:result[0]="guard"
    if room>=9 and room%3==0:result.append("rusher")
    return result

func upgrade_skill(hero:int) -> bool:
    var rank:=int(data.skill_levels[hero]);var cost:=2+rank
    if rank>=3 or data.parts<cost or data.credits<30:return false
    var before:=data.duplicate(true);data.parts-=cost;data.credits-=30;data.skill_levels[hero]=rank+1
    return commit(before)
