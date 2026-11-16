extends "res://tools/verify_tactic_encounters.gd"
const MODULE_OUT="res://../docs/evidence/module-counterplay/"
func command(s:RefCounted,charged:bool) -> Dictionary:
    if s.arrival_left>0:return {}
    var ordinary:Dictionary=super.command(s,charged)
    var f:Dictionary=s.fighters[0];var enemy:Dictionary=s.fighters[1]
    var distance:float=absf(f.x-enemy.x)
    if not ordinary.get("guard",false) and f.state=="idle" and enemy.state!="attack" and distance>=1.2 and distance<=3.4 and s.tactics.quote(s,0,1).ready:return {"attack":"tactic_b"}
    return ordinary
func _initialize() -> void:
    var rows:Array=[]
    for level in [1,2]:
        for recipe in RECIPES:
            for pair in [[false,0],[false,2],[true,0],[true,1]]:
                var row:Dictionary=run_case(recipe,pair[0],pair[1],level,"",true);rows.append(row)
                check("live encounter obeys finite resources "+str(rows.size()),row.energy_min>=0 and row.energy_max<=100)
                check("live encounter replay matches "+str(rows.size()),row==run_case(recipe,pair[0],pair[1],level,"",true))
                print("MODULE_RUN ",JSON.stringify(row))
    for boss in ["gantry","signal"]:
        for module in [0,2]:
            var row:Dictionary=run_case(["boss","grunt","rusher"],false,module,1,boss,true);rows.append(row)
            check("boss encounter retains finite resources "+boss+str(module),row.energy_min>=0 and row.energy_max<=100)
            check("boss encounter replay matches "+boss+str(module),row==run_case(["boss","grunt","rusher"],false,module,1,boss,true))
            print("MODULE_RUN ",JSON.stringify(row))
    check("return module makes real contacts under live AI",rows.any(func(r:Dictionary)->bool:return r.module==1 and r.module_hits>0))
    check("delay module makes real contacts under live AI",rows.any(func(r:Dictionary)->bool:return r.module==2 and r.module_hits>0))
    check("live AI actually steps out of published warning zones",rows.any(func(r:Dictionary)->bool:return r.steps_out>0))
    check("live AI actually braces against published warning zones",rows.any(func(r:Dictionary)->bool:return r.braces>0))
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(MODULE_OUT+"encounters.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"runs":rows,"policy":"28 cases with deterministic replay, live AI Normal/Hard and two Normal bosses; same RIVET command policy waits until arrival finishes and uses a wide ground line at close openings; initial100 HP/60 energy, no resource or position grants during play, 1800-input-tick cap; automated defense is idealized and is not human balance evidence"},"  "));quit(1 if failed else 0)
