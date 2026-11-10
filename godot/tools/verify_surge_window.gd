extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var checks:Array=[]
var scene:Node
const OUT="res://../docs/evidence/surge-window/"
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    print("SURGE_WINDOW ",label," ",ok)
    if not ok:push_error(label)
func fresh() -> RefCounted:
    var s=Sim.new();s.training=true;s.arcade_enabled=true;s.reset_round()
    s.surge_lab_enabled=true;s.ai_enabled=false;s.phase="fight";s.exchange.pressure=60
    for side in 2:
        s.fighters[side].x=-.65 if side==0 else .65;s.fighters[side].meter=60
    return s
func finish(s:RefCounted,a:Dictionary={},b:Dictionary={}) -> void:
    for i in s.exchange.DECISION_TICKS:s.tick(a,b)
func step() -> void:
    scene._physics_process(1.0/60);scene._process(1.0/60)
func key(code:int,echo:=false) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;e.echo=echo
    scene._unhandled_key_input(e)
func shot(name:String) -> void:
    if DisplayServer.get_name()=="headless":return
    scene.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
    var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST);img.save_png(OUT+name+".png")
func run() -> void:
    var s=fresh();s.tick({"attack":"heavy","up":true})
    check("neutral close high-SURGE proposal opens window before startup",s.exchange.decision_active() and s.fighters[0].state=="idle" and s.fighters[0].meter==60)
    check("new window leaves old F8 clash isolated",not s.exchange.active())
    var frozen:Array=s.fighters.duplicate(true)
    var time:float=s.remaining
    s.tick({"surge_choice":"guard"},{"surge_choice":"evade"})
    s.tick({"surge_choice":"strike"},{"surge_choice":"guard"})
    check("simultaneous inputs lock independently, first wins",s.exchange.decision.choices==["guard","evade"])
    check("decision freezes combat, never awards damage or resources",s.fighters==frozen and s.exchange.pressure==60 and s.remaining==time)
    for i in 18:s.tick({"surge_choice":"strike"})
    check("last decision step is still open",s.exchange.decision.remaining==1)
    s.tick()
    check("window closes at exactly twenty-one decision steps",not s.exchange.decision_active() and s.surge_release.size()==2)
    s.tick();check("guard and evade use ordinary commands",s.fighters[0].guarding and s.fighters[1].state=="dash" and s.fighters[1].vx>0)
    check("shared cooldown prevents instant reopen",s.exchange.cooldown>0)
    s=fresh();s.tick({"attack":"heavy"},{"attack":"light"});finish(s)
    check("timeout preserves both original proposals",s.surge_release[0].attack=="heavy" and s.surge_release[1].attack=="light")
    s.tick();check("both timeout attacks still have normal windup",s.fighters[0].state=="attack" and s.fighters[1].state=="attack" and s.fighters[0].health==100 and s.fighters[1].health==100)
    var windup_events:Array=[]
    for i in 12:
        s.tick();windup_events.append_array(s.events)
    check("faster real jab can interrupt slower strike",windup_events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.attacker==1) and s.fighters[0].health<100)
    s=fresh();s.tick({}, {"attack":"heavy"});finish(s,{"surge_choice":"guard"})
    var blocked:=false
    var invented_success:=false
    for i in 28:
        s.tick()
        for e in s.events:
            if e.kind=="block" and e.target==0:blocked=true
            if e.kind=="counter_success":invented_success=true
    check("guard choice holds a finite real guard until heavy contact",blocked)
    check("guard does not invent counter success or damage",not invented_success and s.fighters[1].health==100)
    s=fresh();s.fighters[0].dash_cd=30;s.tick({"attack":"heavy"});finish(s,{"surge_choice":"evade"});s.tick()
    check("evade still respects original dash cooldown",s.fighters[0].state!="dash" and s.fighters[0].invuln==0)
    s=fresh();s.fighters[0].guard=0;s.tick({"attack":"heavy"});finish(s,{"surge_choice":"guard"});s.tick()
    check("guard with exhausted resource cannot grant defense",not s.fighters[0].guarding)
    s=fresh();s.tick({"attack":"special"});check("paid signature cannot open a cancel window",not s.exchange.decision_active())
    s=fresh();s.tick({"attack":"heavy"});s.fighters[1].x=6;s.tick({"surge_choice":"strike"})
    check("range invalidation cancels every intent",not s.exchange.decision_active() and s.surge_release.is_empty())
    s=fresh();s.tick({"attack":"heavy"},{"attack":"heavy"})
    var first:int=s.exchange.decision.initiator
    s.exchange.cancel_decision();s.exchange.cooldown=0;s.tick({"attack":"heavy"},{"attack":"heavy"})
    check("simultaneous proposals alternate deterministic priority",first==0 and s.exchange.decision.initiator==1)
    for mode in ["standard","off","low","range","air","stun","active","buffer","hitstop","cooldown"]:
        s=fresh()
        match mode:
            "standard":s.training=false
            "off":s.surge_lab_enabled=false
            "low":s.exchange.pressure=59
            "range":s.fighters[1].x=4.0
            "air":s.fighters[1].y=.2
            "stun":s.fighters[1].state="stun";s.fighters[1].stun=20
            "active":s.fighters[1].state="attack";s.fighters[1].move="jab";s.fighters[1].frame=5
            "buffer":s.fighters[1].buffer_ttl=10;s.fighters[1].buffer="light"
            "hitstop":s.hitstop=5
            "cooldown":s.exchange.cooldown=5
        s.tick({"attack":"heavy"})
        check(mode+" cannot open window",not s.exchange.decision_active())
    s=fresh();s.tick({"attack":"heavy"});s.fighters[0].state="stun";s.fighters[0].stun=15
    s.tick({"surge_choice":"evade"});check("external interruption cancels without granting action",not s.exchange.decision_active() and s.surge_release.is_empty() and s.fighters[0].stun==15)
    s=fresh();s.tick({"attack":"heavy"});s.fighters[1].health=0;s.tick()
    check("KO invalidates all queued choices",not s.exchange.decision_active() and s.surge_release.is_empty())
    s=fresh();s.tick({"attack":"heavy"});s.reset_training()
    check("reset clears mode window and queued actions",not s.exchange.decision_active() and s.surge_release.is_empty() and not s.surge_lab_enabled and s.surge_guards==[0,0])
    var twin=fresh();s=fresh();twin.surge_lab_fixture=true;s.surge_lab_fixture=true
    s.tick({"attack":"heavy"});twin.tick({"attack":"heavy"})
    var committed:Array=s.exchange.decision.intents.duplicate()
    for i in 12:
        s.tick({"surge_choice":"guard"});twin.tick({"surge_choice":"evade"})
    check("AI commitment does not inspect player window choice",s.exchange.decision.intents==committed and s.exchange.decision.choices[1]==twin.exchange.decision.choices[1])
    s=fresh();twin=fresh();var identical:=true
    for i in 3000:
        var a:Dictionary={"attack":"heavy"} if i%100==0 else {"surge_choice":["strike","guard","evade"][i%3]}
        var rival:Dictionary={"surge_choice":["guard","strike","evade"][i%3]}
        s.tick(a,rival);twin.tick(a,rival)
        identical=identical and s.fighters==twin.fighters and s.exchange.decision==twin.exchange.decision and s.events==twin.events and s.surge_release==twin.surge_release
    check("three thousand mixed fixed steps replay identically",identical)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.start_surge_lab();scene.sim.tick({"attack":"heavy","up":true});scene.rhythm.trigger("overdrive",1)
    var music_head:float=scene.audio.music.get_playback_position()
    key(KEY_E);key(KEY_J);key(KEY_SHIFT,true)
    check("native handler records first key during hold and ignores echo",scene.pending.get("surge_choice","")=="evade")
    await shot("window-pending")
    scene.pause_game();var snapshot:Dictionary=scene.sim.exchange.decision.duplicate(true)
    for i in 60:step()
    check("Esc freezes both choices and decision deadline",scene.sim.exchange.decision==snapshot and scene.pending.surge_choice=="evade")
    scene.resume_game();step()
    check("resume applies the saved intent",scene.sim.exchange.decision.choices[0]=="evade")
    await shot("window-locked")
    for i in 19:step()
    check("decision clock bypasses presentation overdrive hold",scene.sim.exchange.decision.remaining==1)
    scene.reduced_effects=true;step()
    check("F2 does not reset or extend window deadline",not scene.sim.exchange.decision_active() and scene.sim.surge_release.size()==2)
    scene.reset_training();check("F5 recreates explicit comparable fixture",scene.sim.surge_lab_enabled and scene.sim.exchange.pressure==60 and scene.sim.surge_release.is_empty())
    key(KEY_B);check("B switches to baseline without window",scene.sim.surge_lab_fixture and not scene.sim.surge_lab_enabled)
    scene.sim.tick({"attack":"heavy"});check("baseline starts normal attack immediately",not scene.sim.exchange.decision_active() and scene.sim.fighters[0].state=="attack")
    await shot("baseline")
    key(KEY_B);check("B restores window fixture and clears old state",scene.sim.surge_lab_enabled and scene.sim.fighters[0].state=="idle")
    scene.sim.tick({"attack":"heavy"});scene.return_to_title()
    check("exit clears decision pending and committed guard",not scene.sim.exchange.decision_active() and scene.pending.is_empty() and scene.sim.surge_release.is_empty() and scene.sim.surge_guards==[0,0])
    scene.start_match(false);check("standard FIGHT never inherits experimental mode",not scene.sim.surge_lab_enabled and not scene.sim.surge_lab_fixture)
    scene.start_demo();check("normal free AI demo never inherits experimental mode",not scene.sim.surge_lab_enabled and not scene.sim.surge_lab_fixture)
    check("music transport remains active across mode switches",scene.audio.music.playing and not scene.audio.music.stream_paused)
    scene.return_to_title();scene.queue_free();scene=null
    for i in 8:await process_frame
    await create_timer(.3).timeout
    var passed:int=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"scope":"Explicit comparison fixtures and native integration; not human fun validation."},"  "))
    quit(0 if passed==checks.size() else 1)
