extends SceneTree
## Rules check for the Black Suit pistol (headless-safe, pure simulation).
## godot --headless --path godot --script res://tools/verify_gun_shot.gd
const Story=preload("res://scripts/combat/story/story_simulation.gd")
const Squad=preload("res://scripts/combat/enemies/squad_simulation.gd")
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Gun=preload("res://scripts/combat/enemies/gun_shot.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"name":name,"passed":passed,"detail":detail});print("GUN ",name," ",passed," ",detail)
func fresh(level:=1,hero:=0) -> RefCounted:
    var s=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.character_choices=[hero,4]
    s.difficulty=level;s.restart_match();s.phase="fight";s.ai_enabled=false
    return s
func kinds(s:RefCounted) -> Array:return s.events.map(func(e:Dictionary)->String:return e.kind)
## Runs until `kind` is emitted (returns the event) or the budget runs out.
func until(s:RefCounted,kind:String,hero:Callable,budget:=140) -> Dictionary:
    for i in budget:
        s.tick(hero.call(s,i))
        for e in s.events:
            if e.kind==kind:return e
    return {}
func idle(_s,_i) -> Dictionary:return {}
func start_gun(s:RefCounted) -> void:
    s.fighters[1].buffer="gun";s.fighters[1].buffer_ttl=14
func run() -> void:
    # 1. only Black Suit may fire, and the human-facing hero path never creates a bullet
    var s=fresh()
    s.fighters[0].buffer="gun";s.fighters[0].buffer_ttl=14
    for i in 20:s.tick({})
    check("non-Black-Suit fighters cannot use the gun",s.fighters[0].move!="gun" and s.projectiles.is_empty())
    # 2. wind-up length, exact fire frame, slow visible bullet
    s=fresh();start_gun(s)
    var fired_at:=-1;var start_tick:int=s.tick_count
    var shot:Dictionary={}
    for i in 80:
        s.tick({})
        for e in s.events:
            if e.kind=="gun_fire":fired_at=s.tick_count-start_tick;shot=e
        if fired_at>=0:break
    check("fire frame equals the 30-tick telegraph (+1 start tick)",fired_at>=30 and fired_at<=32,{"ticks":fired_at})
    check("bullet leaves the muzzle in front of the shooter and travels toward the hero",s.projectiles.size()==1 and signf(s.projectiles[0].dir)==float(s.fighters[1].face) and absf(shot.x-s.fighters[1].x)<=1.0)
    var x0:float=s.projectiles[0].x
    s.tick({})
    check("bullet speed is about 15 units/s",absf(absf(s.projectiles[0].x-x0)-Gun.SPEED)<.001 if not s.projectiles.is_empty() else false)
    # 3. unguarded hit
    var hp:int=s.fighters[0].health
    var hit:Dictionary=until(s,"gun_hit",idle)
    check("unguarded hero is hit for the move damage and stunned",not hit.is_empty() and s.fighters[0].health==hp-10 and s.fighters[0].state=="stun",{"hp":s.fighters[0].health})
    check("projectile is removed after the hit",s.projectiles.is_empty())
    # 4. dash i-frames dodge it and pay a little energy
    s=fresh();start_gun(s);s.fighters[0].meter=0.0
    var dodge:Dictionary={}
    for i in 120:
        var cmd:Dictionary={}
        if not s.projectiles.is_empty() and absf(s.projectiles[0].x-s.fighters[0].x)<2.6 and s.fighters[0].state=="idle":cmd={"dash":true,"axis":1.0}
        s.tick(cmd)
        for e in s.events:
            if e.kind=="gun_dodge":dodge=e
        if not dodge.is_empty():break
    check("dash dodges the bullet (no damage, +6 energy)",dodge.get("how","")=="dash" and s.fighters[0].health==100 and s.fighters[0].meter>=6.0,dodge)
    # 5. jumping over it
    s=fresh();s.fighters[0].x=-4.5;s.fighters[1].x=3.0;start_gun(s)
    dodge={}
    for i in 140:
        var cmd:Dictionary={}
        if not s.projectiles.is_empty() and absf(s.projectiles[0].x-s.fighters[0].x)<4.0 and s.fighters[0].y<=.01:cmd={"jump":true}
        s.tick(cmd)
        for e in s.events:
            if e.kind=="gun_dodge":dodge=e
        if not dodge.is_empty():break
    check("jump passes over the bullet",dodge.get("how","")=="jump" and s.fighters[0].health==100,dodge)
    # 6. holding guard blocks it: chip on guard, no health loss
    s=fresh();start_gun(s)
    for i in 12:s.tick({"guard":true})
    var guard_before:float=s.fighters[0].guard
    var block:Dictionary=until(s,"gun_block",func(_s,_i)->Dictionary:return {"guard":true})
    check("held guard blocks (guard chips, health intact)",not block.is_empty() and s.fighters[0].health==100 and s.fighters[0].guard<guard_before,{"guard":s.fighters[0].guard})
    # 7. a timed guard parries and sends the bullet back at the shooter
    s=fresh();start_gun(s)
    var press:=false;var deflect:Dictionary={}
    for i in 160:
        var cmd:Dictionary={}
        if not s.projectiles.is_empty() and s.projectiles[0].dir==1.0 or (not s.projectiles.is_empty() and not s.projectiles[0].reflected):
            if absf(s.projectiles[0].x-s.fighters[0].x)<.5+Gun.SPEED*6.0:cmd={"guard":true,"guard_pressed":not press};press=true
        elif press:cmd={"guard":true}
        s.tick(cmd)
        for e in s.events:
            if e.kind=="gun_deflect":deflect=e
        if not deflect.is_empty():break
    check("timed guard deflects",not deflect.is_empty() and s.fighters[0].health==100 and s.fighters[0].counter_window>0,deflect)
    check("deflected bullet is reflected toward the shooter",s.projectiles.size()==1 and s.projectiles[0].reflected and s.projectiles[0].target==s.fighters[1] and s.projectiles[0].dir==-1.0*s.fighters[1].face*-1.0 or s.projectiles[0].dir==float(s.fighters[0].face))
    var enemy_hp:int=s.fighters[1].health
    var back:Dictionary=until(s,"gun_hit",idle)
    check("reflected bullet hurts the shooter",not back.is_empty() and back.target==1 and s.fighters[1].health==enemy_hp-Gun.REFLECT_DAMAGE,{"hp":s.fighters[1].health})
    # 8. a hit during the wind-up cancels the shot
    s=fresh();start_gun(s)
    for i in 12:s.tick({})
    s.fighters[0].x=s.fighters[1].x-1.2;s.fighters[0].buffer="light";s.fighters[0].buffer_ttl=14
    var fired:=false
    for i in 60:
        s.tick({})
        for e in s.events:fired=fired or e.kind=="gun_fire"
    check("hit during the telegraph cancels the shot",not fired and s.projectiles.is_empty())
    # 9. cooldown and frequency: hero stands at range, AI decides
    s=fresh(1);s.ai_enabled=true
    var shots:Array=[]
    for i in 3600:
        s.tick({"allow_parry":false})
        # keep the hero far away and healthy so only the gun gate is under test
        s.fighters[0].x=-4.5;s.fighters[0].health=100;s.fighters[0].state="idle";s.fighters[0].stun=0
        s.fighters[1].x=clampf(s.fighters[1].x,.4,6.0)
        for e in s.events:
            if e.kind=="gun_fire":shots.append(i)
    var gaps:Array=[]
    for i in range(1,shots.size()):gaps.append(shots[i]-shots[i-1])
    var min_gap:int=gaps.min() if not gaps.is_empty() else 9999
    check("AI uses the gun, but rarely (60 s: 1-8 shots)",shots.size()>=1 and shots.size()<=8,{"shots":shots.size()})
    check("gap between shots respects the 6 s normal cooldown",min_gap>=Gun.COOLDOWN[1],{"min_gap":min_gap})
    # 10. close range never shoots
    s=fresh(2);s.ai_enabled=true;var close_shots:=0
    for i in 2400:
        s.tick({})
        s.fighters[0].x=s.fighters[1].x-1.6;s.fighters[0].health=100
        for e in s.events:
            if e.kind=="gun_fire":close_shots+=1
    check("no shots at melee range",close_shots==0,{"shots":close_shots})
    # 11. squad: events name real members, bullets stay finite, only grunt/captain roles shoot
    for level in 3:
        var q=Squad.new();q.last_service_enabled=true;q.arcade_enabled=true;q.character_choices=[0,4]
        q.difficulty=level;q.restart_match();q.begin_squad();q.phase="fight"
        var bad:=0;var fires:=0
        for i in 3600:
            q.tick(q.rush_agent.choose(q,0,q.ai_tick,1))
            for e in q.events:
                if e.has("squad_id") and (e.squad_id<0 or e.squad_id>=q.squad_members.size()):bad+=1
                if e.kind=="gun_fire":fires+=1
            for p in q.projectiles:
                if not is_finite(p.x) or absf(p.x)>Sim.EDGE+2.0:bad+=1
            if q.phase=="match_over":break
        check("squad %d: gun events valid and bounded"%level,bad==0,{"bad":bad,"fires":fires})
    # 12. story rushers/guards never shoot
    var st=Story.new();st.last_service_enabled=true;st.arcade_enabled=true;st.character_choices=[0,4];st.restart_match()
    st.wave_recipes=[["rusher","guard","grunt"]]
    st.begin_story();st.fighters[1].gun_cd=0
    var role_ok:=true
    for member in st.squad_members:
        st.fighters[1]=member;member["gun_cd"]=0
        if member.story_role in ["rusher","guard"]:role_ok=role_ok and not Gun.wants(st,1,0,2)
    check("melee-only story roles are excluded",role_ok)
    # 13. determinism
    var a:String=run_signature();var b:String=run_signature()
    check("deterministic: identical runs give identical shots",a==b and not a.is_empty(),{"a":a})
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    print("GUN SUMMARY ",checks.size()-failed,"/",checks.size())
    quit(1 if failed>0 else 0)
func run_signature() -> String:
    var s=fresh(1);s.ai_enabled=true;var parts:Array=[]
    for i in 1800:
        s.tick({"allow_parry":false})
        s.fighters[0].x=-4.5;s.fighters[0].health=100;s.fighters[0].state="idle";s.fighters[0].stun=0
        s.fighters[1].x=clampf(s.fighters[1].x,.4,6.0)
        for e in s.events:
            if e.kind in ["gun_fire","gun_hit","gun_block","gun_dodge"]:parts.append("%s@%d"%[e.kind,i])
    return ",".join(parts)
