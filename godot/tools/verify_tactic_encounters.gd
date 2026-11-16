extends SceneTree
## Fixed command policy, live Normal AI, normal initial resources; no per-tick grants.
const S=preload("res://scripts/combat/story/story_simulation.gd")
const P=preload("res://scripts/combat/city/city_profile.gd")
const OUT="res://../docs/evidence/tactics-usability/"
const RECIPES=[["guard","grunt","rusher"],["grunt","grunt","captain"],["heavy","rusher","jammer"]]
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ENCOUNTERS ",label," ",ok)
    if not ok:push_error(label)
func command(s:RefCounted,charged:bool) -> Dictionary:
    var f:Dictionary=s.fighters[0];var b:Dictionary=s.fighters[1];var gap:float=absf(b.x-f.x)
    if f.tactical.charge>=0:return {"tactic_a_held":charged and f.tactical.charge<38}
    if f.state in ["stun","blockstun"]:return {}
    if b.state=="attack" and b.move!="gun" and gap<2.7 and b.frame>=s.move_for(b,b.move).startup-8:return {"guard":true}
    if f.state=="attack":return {"rush":gap<1.8}
    if f.state!="idle":return {}
    if gap>=2.0 and gap<=4.8 and s.tactics.quote(s,0,0).ready:return {"attack":"tactic_a","tactic_a_held":charged}
    if gap>=2.0 and gap<=3.5 and s.tactics.quote(s,0,1).ready:return {"attack":"tactic_b"}
    if gap>1.4:return {"axis":signf(b.x-f.x)}
    return {"rush":true}
func run_case(recipe:Array,charged:bool) -> Dictionary:
    var p=P.new();p.path="";p.data.best=3;p.data.tactics[1].variants[0]=0 if charged else 1;p.data.tactics[1].supports[0]=0 if charged else 1
    var s=S.new();s.character_choices=[1,4];s.last_service_enabled=true;s.campaign_enabled=true;s.campaign_stats=p.stats(1);s.wave_recipes=[recipe.duplicate()];s.difficulty=1;s.begin_story()
    s.tactics.enabled=true;s.tactics.config=[p.data.tactics[1].duplicate(true),{}]
    var row:={"build":"charged_relay" if charged else "quick_pierce","recipe":recipe,"ticks":0,"damage":0,"taken":0,"casts":0,"tactical_hits":0,"tactical_blocks":0,"full_tiers":0,"relays":0,"energy_min":60.0,"energy_max":60.0}
    for tick in 1800:
        if s.story_state!="combat" or s.fighters[0].health<=0:break
        s.tick(command(s,charged));row.ticks=tick+1
        row.energy_min=minf(row.energy_min,s.fighters[0].meter);row.energy_max=maxf(row.energy_max,s.fighters[0].meter)
        for e in s.events:
            if e.kind=="tactic_start":row.casts+=1
            if e.kind=="tactic_tier":row.full_tiers+=1
            if e.kind=="tactic_relay":row.relays+=1
            if e.kind=="hit":
                if e.get("attacker",-1)==0:
                    row.damage+=int(e.damage)
                    if e.get("tactic",false):row.tactical_hits+=1
                else:row.taken+=int(e.damage)
            if e.kind=="block" and e.get("attacker",-1)==0 and e.get("tactic",false):row.tactical_blocks+=1
    row["enemies_left"]=s.remaining_enemies();row["health"]=s.fighters[0].health;row["meter"]=s.fighters[0].meter;row["state"]=s.story_state
    return row
func _initialize() -> void:
    var rows:Array=[]
    for recipe in RECIPES:
        for charged in [false,true]:
            var row:Dictionary=run_case(recipe,charged);rows.append(row)
            check("%s %s respects finite resources"%[row.build,str(recipe)],row.energy_min>=0 and row.energy_max<=100 and row.casts>0)
            check("%s %s is deterministic under live AI"%[row.build,str(recipe)],row==run_case(recipe,charged))
            print("ENCOUNTER_RESULT ",JSON.stringify(row))
    check("quick configuration produces real tactical contacts",rows.filter(func(r:Dictionary)->bool:return r.build=="quick_pierce" and r.tactical_hits>0).size()>0)
    check("charged configuration produces real full-tier contacts",rows.filter(func(r:Dictionary)->bool:return r.build=="charged_relay" and r.tactical_hits>0 and r.full_tiers>0).size()>0)
    check("same pilot produces measurably different build outcomes",rows[0].damage!=rows[1].damage or rows[0].taken!=rows[1].taken or rows[0].tactical_hits!=rows[1].tactical_hits)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"encounters.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"runs":rows,"policy":"same reactive command policy, Normal AI, 1800-tick cap, initial100 HP/60 energy, no resource injections, authored three role recipes; not human balance validation"},"  "));quit(1 if failed else 0)
