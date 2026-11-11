extends RefCounted
const Profiles=preload("res://scripts/combat/last_service/profiles.gd")
const SKILLS=[
 [{"id":"zip_route","name":"LONG ROUTE","desc":"Route lasts 5 seconds instead of 3."},{"id":"zip_confirm","name":"SIGNED RECEIPT","desc":"Confirmed kick skill refunds 4 energy once."},{"id":"zip_dash","name":"EXIT PLAN","desc":"Route dash cooldown becomes 0.4 seconds."}],
 [{"id":"rivet_fast","name":"QUICK CLAMP","desc":"Reach the second charge tier sooner."},{"id":"rivet_guard","name":"PRESSURE SEAL","desc":"Strikes drain 5 extra guard."},{"id":"rivet_recover","name":"SAFE RELEASE","desc":"Tier-two strike recovers 4 frames sooner."}],
 [{"id":"hush_hold","name":"LONG SAMPLE","desc":"Sample lasts 6 seconds instead of 4."},{"id":"hush_gain","name":"CLEAN TAKE","desc":"Sample-confirmed hit refunds 5 energy once."},{"id":"hush_recover","name":"DEAD AIR","desc":"Sample strike recovers 4 frames sooner."}],
 [{"id":"loop_life","name":"LONG CABLE","desc":"Nodes last 7 seconds instead of 5."},{"id":"loop_cycle","name":"FAST PATCH","desc":"Pulse cooldown becomes 1 second."},{"id":"loop_gain","name":"FEEDBACK","desc":"Confirmed node pulse refunds 4 energy once."}]]
var path:="user://neon_lab/progression.cfg"
var records:Dictionary={}
var claimed:Array=[]
var story_cleared:=false # Clearing the 3-stop story unlocks FREE BATTLE.
var last_error:=OK
func _init() -> void:reset()
func reset() -> void:
    records.clear();claimed.clear();story_cleared=false
    for id in Profiles.IDS:records[id]={"xp":0,"unlocked":[],"equipped":[],"palette":false}
func level(character:int) -> int:return mini(3,floori(float(records[Profiles.IDS[character]].xp)/40.0))
func points(character:int) -> int:return maxi(0,level(character)-records[Profiles.IDS[character]].unlocked.size())
func equipped(character:int) -> Array:return records[Profiles.IDS[character]].equipped.duplicate()
func load_data() -> void:
    reset()
    var file:=ConfigFile.new()
    if file.load(path)!=OK and file.load(path+".bak")!=OK:return
    if file.get_value("save","version",0)!=1:return
    story_cleared=file.get_value("save","story_cleared",false)==true
    var claims:Variant=file.get_value("save","claimed",[])
    if claims is Array:
        for id in claims:
            if id is String and id.length()<120 and claimed.size()<128:claimed.append(id)
    for i in 4:
        var id:String=Profiles.IDS[i];var record:Dictionary=records[id]
        var xp:Variant=file.get_value(id,"xp",0)
        if xp is int:record.xp=clampi(xp,0,240)
        var unlocks:Variant=file.get_value(id,"unlocked",[])
        if unlocks is Array:
            for skill in SKILLS[i]:
                if skill.id in unlocks and record.unlocked.size()<level(i):record.unlocked.append(skill.id)
        var slots:Variant=file.get_value(id,"equipped",[])
        if slots is Array:
            for node in slots:
                if node in record.unlocked and node not in record.equipped and record.equipped.size()<2:record.equipped.append(node)
        record.palette=bool(file.get_value(id,"palette",false)) and record.xp>=120
func save() -> Error:
    if path.is_empty():return OK
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var file:=ConfigFile.new();file.set_value("save","version",1);file.set_value("save","claimed",claimed);file.set_value("save","story_cleared",story_cleared)
    for id in records:
        for key in records[id]:file.set_value(id,key,records[id][key])
    last_error=file.save(path+".tmp")
    if last_error!=OK:return last_error
    var absolute:String=ProjectSettings.globalize_path(path)
    if FileAccess.file_exists(path):
        if FileAccess.file_exists(path+".bak"):DirAccess.remove_absolute(absolute+".bak")
        last_error=DirAccess.rename_absolute(absolute,absolute+".bak")
        if last_error!=OK:return last_error
    last_error=DirAccess.rename_absolute(absolute+".tmp",absolute)
    return last_error
func reward(character:int,match_id:String,victory:bool,techniques:int) -> int:
    if match_id in claimed:return 0
    claimed.append(match_id)
    if claimed.size()>128:claimed.pop_front()
    var record:Dictionary=records[Profiles.IDS[character]]
    var gain:int=(40 if victory else 15)+mini(3,maxi(0,techniques))*5
    var old:int=record.xp;record.xp=mini(240,record.xp+gain);save();return record.xp-old
func unlock(character:int,index:int) -> bool:
    var record:Dictionary=records[Profiles.IDS[character]];var node:String=SKILLS[character][index].id
    if node in record.unlocked or points(character)<=0 or level(character)<index+1:return false
    record.unlocked.append(node);save();return true
func toggle(character:int,index:int) -> bool:
    var record:Dictionary=records[Profiles.IDS[character]];var node:String=SKILLS[character][index].id
    if node not in record.unlocked:return false
    if node in record.equipped:record.equipped.erase(node)
    elif record.equipped.size()<2:record.equipped.append(node)
    else:return false
    save();return true
func respec(character:int) -> void:
    var record:Dictionary=records[Profiles.IDS[character]];record.unlocked=[];record.equipped=[];save()
func toggle_palette(character:int) -> void:
    var record:Dictionary=records[Profiles.IDS[character]]
    if record.xp>=120:record.palette=not record.palette;save()
