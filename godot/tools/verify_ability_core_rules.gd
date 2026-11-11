extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Rewards=preload("res://scripts/combat/ability_draw/rewards.gd")
const OUT="res://../docs/evidence/ability-draw/expanded-pool/"
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("CORE_RULES ",label," ",ok)
    if not ok:push_error(label)
func fresh(character:=0) -> RefCounted:
    var s:=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.character_choices=[character,1];s.reset_round();s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-.65;s.fighters[1].x=.65
    s.fighters[0].meter=0;s.fighters[1].meter=0
    return s
func hit(s:RefCounted,core:String,defense:="",blocked:=false,parry:=false) -> Dictionary:
    s.fighters[0]["draw_core"]=core;s.fighters[1]["draw_core"]=defense
    s.fighters[1].guarding=blocked;s.fighters[1].guard_frames=1 if parry else 20
    s._start_attack(0,"jab");s._resolve_hit(0,false)
    return s.fighters[1]
func run() -> void:
    var ids:Array=[];var seen:Dictionary={};var rng_rewards:=Rewards.new()
    for entry in Rewards.ITEMS:
        check(entry.id+" has a distinct ID and valid item",entry.id not in ids and not Rewards.item(entry.id).is_empty());ids.append(entry.id)
        check(entry.id+" icon and matching drum texture exist",ResourceLoader.exists("res://assets/ability_draw/pool/"+entry.id+".png") and ResourceLoader.exists("res://assets/ability_draw/pool/reels_"+entry.id+".png"))
        var s:=fresh();var item:Dictionary=entry.duplicate();item.boundary="test/"+entry.id
        check(entry.id+" can be applied exactly once",rng_rewards.apply_once(s,item) and not rng_rewards.apply_once(s,item) and s.fighters[0].draw_core==entry.id)
        s.fighters[0]["draw_healed"]=8;s.reset_round()
        check(entry.id+" leaves no modifier or healing budget on reset",not s.fighters[0].has("draw_core") and not s.fighters[0].has("draw_healed"))
    for seed_value in 512:
        var a:=Rewards.new();var b:=Rewards.new();var item:Dictionary=a.roll("sample",seed_value)
        seen[item.id]=true
        if item!=b.roll("sample",seed_value):check("identical seeds reproduce reward",false)
        if item!=a.roll("sample",seed_value+123):check("same boundary never rerolls",false)
    check("all nine equal-weight entries are reachable across seeds",seen.size()==9)
    var bad:=Rewards.new();var invalid:=fresh()
    check("invalid IDs and recipients cannot consume a claim",not bad.apply_once(invalid,{"id":"missing","boundary":"bad"}) and not bad.apply_once(invalid,{"id":"speed","boundary":"bad"},2) and bad.claimed.is_empty())
    for character in 4:
        var base:=fresh(character);hit(base,"")
        var s:=fresh(character);hit(s,"fury")
        check("FURY raises real hit damage for character %d"%character,s.fighters[1].health<base.fighters[1].health and s.last_combo_damage>base.last_combo_damage)
        s=fresh(character);hit(s,"","plate")
        check("PLATE reduces actual incoming damage for character %d"%character,s.fighters[1].health>base.fighters[1].health and s.last_combo_damage<base.last_combo_damage)
        s=fresh(character);hit(s,"flow")
        check("FLOW grants 30 percent more hit energy for character %d"%character,is_equal_approx(s.fighters[0].meter,base.fighters[0].meter*1.3) and s.fighters[1].health==base.fighters[1].health)
        s=fresh(character);hit(s,"breach","",true)
        var normal:=fresh(character);hit(normal,"","",true)
        check("BREACH increases guard drain without chip health for character %d"%character,s.fighters[1].guard<normal.fighters[1].guard and s.fighters[1].health==100)
        for move_name in ["special","overdrive","node_pulse"]:
            if move_name=="node_pulse" and character!=3:continue
            s=fresh(character);s.fighters[0]["draw_core"]="eco"
            var cost:int=s.skill_cost(s.fighters[0],move_name)
            if move_name=="node_pulse":s.fighters[0].service.nodes=[{"x":0.0,"life":300,"id":1}]
            s.fighters[0].meter=cost-1;s._start_attack(0,move_name)
            var rejected:bool=s.fighters[0].state!="attack" and s.fighters[0].meter==cost-1
            s.fighters[0].meter=cost;s._start_attack(0,move_name)
            check("ECO exact affordability and payment %d %s"%[character,move_name],rejected and s.fighters[0].state=="attack" and is_zero_approx(s.fighters[0].meter))
    var s:=fresh();s.fighters[0].health=60
    for i in 10:
        s.fighters[1].state="idle";s.fighters[1].health=100;hit(s,"siphon")
    check("SIPHON heals two per hit and stops at twelve per round",s.fighters[0].health==72 and s.fighters[0].draw_healed==12)
    s=fresh();hit(s,"siphon");check("SIPHON full health neither overheals nor spends its cap",s.fighters[0].health==100 and not s.fighters[0].has("draw_healed"))
    s.fighters[0].health=99;s.fighters[1].state="idle";hit(s,"siphon")
    check("SIPHON only spends actual restored HP at health cap",s.fighters[0].health==100 and s.fighters[0].draw_healed==1)
    for parry in [false,true]:
        s=fresh();s.fighters[0].health=60;hit(s,"siphon","",true,parry)
        check("SIPHON cannot heal from block or parry %s"%parry,s.fighters[0].health==60 and not s.fighters[0].has("draw_healed"))
        s=fresh();hit(s,"flow","",true,parry)
        check("FLOW cannot farm energy from block or parry %s"%parry,is_zero_approx(s.fighters[0].meter))
    s=fresh();s.fighters[0].health=0;hit(s,"siphon")
    check("SIPHON cannot revive a KO in a trade",s.fighters[0].health==0)
    s=fresh();s.fighters[0]["draw_core"]="flow";s.fighters[0].meter=99;hit(s,"flow")
    check("FLOW never exceeds energy cap",s.fighters[0].meter==100)
    # Genuine tick-driven attack, including startup, contact and hitstop.
    var real_base:=fresh();var real_fury:=fresh();real_fury.fighters[0]["draw_core"]="fury"
    for i in 25:
        real_base.tick({"attack":"heavy"} if i==0 else {})
        real_fury.tick({"attack":"heavy"} if i==0 else {})
    check("FURY is active through legal combat ticks",real_fury.fighters[1].health<real_base.fighters[1].health and real_fury.last_combo_hits==1)
    s=fresh();s.fighters[0]["draw_core"]="eco";s.fighters[0].meter=40;s.fighters[1].state="stun"
    check("ECO AI can commit a signature at the discounted threshold",s.rush_agent._plan(s,0,600,2,false).get("attack","")=="special")
    s=fresh(3);s.fighters[0]["draw_core"]="eco";s.fighters[0].meter=8;s.fighters[0].service.nodes=[{"x":.6,"life":300,"id":1}]
    check("ECO LOOP AI can trigger an eight-energy pulse",s.rush_agent._loop_ready(s,s.fighters[0],s.fighters[1]))
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(OUT+"core-rules.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"reachable_ids":seen.keys(),"scope":"Deterministic actual simulation fixtures and a legal input-driven attack; not human balance or GPU proof."},"  "))
    print("CORE_RULE_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
