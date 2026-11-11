extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Buffer=preload("res://scripts/combat/continuation_buffer.gd")
const Rhythm=preload("res://scripts/combat/combat_rhythm.gd")
var checks:Array=[]
var scene:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    print("ESCALATION ",label," ",ok)
    if not ok:push_error(label)
func fresh() -> RefCounted:
    var s=Sim.new();s.arcade_enabled=true;s.reset_round();s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-.55;s.fighters[1].x=.55
    return s
func step() -> void:
    scene._physics_process(1.0/60);scene._process(1.0/60)
func run() -> void:
    var b=Buffer.new()
    b.open(0);b.open(1);b.offer(0,"heavy");b.offer(0,"light");b.offer(1,"dash")
    check("each side locks its own first intent",b.slots[0].choice=="heavy" and b.slots[1].choice=="dash")
    for i in 120:b.command(0,true,true)
    check("presentation and native hitstop do not expire intent",b.slots[0].left==36)
    check("stun does not grant action",b.command(0,false,false).is_empty())
    check("intent consumed once",b.command(0,false,true).get("attack","")=="heavy" and b.command(0,false,true).is_empty())
    for i in 40:b.command(0,false,false)
    check("fixed simulation lifetime is bounded",b.slots[0].is_empty())
    b.cancel(1);check("interruption cancels other side independently",b.slots[1].is_empty())
    var s=fresh()
    s.fighters[0].meter=60
    s.tick({"attack":"heavy","up":true})
    for i in 18:s.tick()
    check("real launcher opens attacker continuation",not s.continuation.slots[0].is_empty() and s.exchange.pressure==10)
    s.continuation.offer(0,"dash")
    var chased:=false
    for i in 50:
        s.tick()
        for event in s.events:
            if event.kind=="homing_chase":chased=true
    check("queued E chases through native hitstop and pays energy",chased and s.fighters[0].meter<60)
    s=fresh();s.fighters[0].meter=0;s.fighters[0].air.chase_window=30;s.fighters[1].y=1;s.fighters[1].state="stun";s.fighters[1].stun=30
    s.continuation.open(0);s.continuation.offer(0,"dash");s.tick()
    check("low energy cannot buy chase",s.events.any(func(e:Dictionary)->bool:return e.kind=="no_chase_meter"))
    s=fresh();s.fighters[0].x=-5;s.tick({"attack":"light"})
    for i in 45:s.tick()
    check("whiff never increases SURGE",s.exchange.pressure==0)
    s=fresh();s.tick({"attack":"light"})
    for i in 8:s.tick()
    check("one connected strike increments only once",s.exchange.pressure==10)
    for i in 8:s.tick()
    check("remaining active frames cannot rescore same contact",s.exchange.pressure==10)
    s.exchange.contact(500);check("SURGE caps at ninety",s.exchange.pressure==90 and s.exchange.tier()==3)
    for i in 220:s.exchange.advance_idle(true)
    check("quiet separated fighters cool back to FLOW",s.exchange.pressure==0 and s.exchange.tier()==1)
    s.reset_round();check("reset clears SURGE and intents",s.exchange.pressure==0 and s.continuation.slots==[{},{}])
    s=fresh();s.tick({"attack":"light"},{"guard":true,"guard_pressed":true})
    for i in 6:s.tick({}, {"guard":true})
    check("real parry opens defender intent and adds sixteen",not s.continuation.slots[1].is_empty() and s.exchange.pressure==16)
    s.continuation.offer(1,"light")
    var parry_hit:=false
    for i in 65:
        s.tick({}, {"guard":true})
        for event in s.events:
            if event.kind=="counter_success":parry_hit=true
    check("queued parry followup earns success only on real hit",parry_hit)
    s=fresh();s.continuation.open(0);s.continuation.offer(0,"dash");s.tick()
    check("queued E without chase withdraws from opponent",s.fighters[0].vx<0)
    s=fresh();s.last_service_enabled=true;s.character_choices=[3,0];s.reset_round();s.phase="fight";s.fighters[0].meter=100
    s.tick({"attack":"special"})
    for i in 60:s.tick()
    check("LOOP placement never heats SURGE",s.exchange.pressure==0 and not s.fighters[0].service.nodes.is_empty())
    s=fresh();s.continuation.open(1);s.continuation.offer(1,"heavy")
    s.tick({"attack":"light"})
    for i in 8:s.tick()
    check("real hit invalidates defender continuation",s.continuation.slots[1].is_empty())
    s=fresh();s.fighters[1].health=1;s.continuation.open(1);s.tick({"attack":"light"})
    for i in 8:s.tick()
    check("KO clears both sides",s.phase=="round_over" and s.continuation.slots==[{},{}])
    var twin=fresh();s=fresh();s.endless=true;twin.endless=true
    var identical:=true
    for i in 2000:
        var a:Dictionary={"attack":"heavy","up":true} if i%70==0 else ({"dash":true} if i%70==17 else {})
        var rival:Dictionary={"guard":true} if i%140<40 else ({"attack":"light"} if i%50==0 else {})
        s.tick(a,rival);twin.tick(a,rival)
        identical=identical and s.fighters==twin.fighters and s.events==twin.events and s.continuation.slots==twin.continuation.slots and s.exchange.pressure==twin.exchange.pressure
    check("two thousand fixed steps replay identically",identical)
    var low=Rhythm.new();var high=Rhythm.new();low.trigger("parry",0,"",1);high.trigger("parry",0,"",3)
    for i in 4:low.take_steps(1.0/60,true);high.take_steps(1.0/60,true)
    check("low pressure hold is shorter on same clock",low.phase()=="slow" and high.phase()=="hold")
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false)
    scene.audio.muted=true
    await process_frame;await process_frame
    var sfx_bus:int=AudioServer.get_bus_index("Afterhours SFX")
    scene.audio._ensure_buses()
    check("SFX limiter is installed exactly once",AudioServer.get_bus_effect_count(sfx_bus)==1 and AudioServer.get_bus_effect(sfx_bus,0) is AudioEffectLimiter)
    scene.start_match(true);scene.sim.phase="fight"
    scene.sim.continuation.open(0);scene.rhythm.trigger("parry",0)
    var key:=InputEventKey.new();key.keycode=KEY_K;key.physical_keycode=KEY_K;key.pressed=true
    scene._unhandled_key_input(key)
    check("key handler accepts K immediately during presentation hold",scene.sim.continuation.slots[0].choice=="heavy")
    key.keycode=KEY_J;key.physical_keycode=KEY_J;scene._unhandled_key_input(key)
    check("later key cannot replace locked K",scene.sim.continuation.slots[0].choice=="heavy")
    var snapshot:Array=scene.sim.continuation.slots.duplicate(true)
    scene.pause_game()
    for i in 90:step()
    scene.resume_game()
    check("Esc preserves locked intent without countdown",scene.sim.continuation.slots==snapshot and scene.rhythm.age==0)
    scene.reset_training();check("restart clears intent",scene.sim.continuation.slots==[{},{}])
    scene.reduced_effects=true
    for pressure in [0,35,70]:
        scene.sim.exchange.pressure=pressure
        scene.hud.queue_redraw()
        await process_frame;await process_frame
        if DisplayServer.get_name()!="headless":
            await RenderingServer.frame_post_draw
            var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST)
            img.save_png("res://../docs/evidence/combat-escalation/surge-%d.png"%pressure)
    scene.sim.continuation.open(0);scene.sim.continuation.offer(0,"heavy")
    scene.reduced_effects=true;step()
    check("F2 keeps legal intent consumption on normal clock",scene.rhythm.rate_now==1 and (scene.sim.continuation.slots[0].is_empty() or scene.sim.continuation.slots[0].spent))
    scene.return_to_title();check("exit clears intent and rhythm",scene.sim.continuation.slots==[{},{}] and not scene.rhythm.active())
    scene.queue_free();scene=null
    for frame in 8:await process_frame
    await create_timer(.3).timeout
    var passed:int=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/combat-escalation/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":passed,"total":checks.size(),"engine":Engine.get_version_info().string,"display":DisplayServer.get_name()},"  "))
    quit(0 if passed==checks.size() else 1)
