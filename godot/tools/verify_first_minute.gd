extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Coach=preload("res://scripts/combat/first_minute_coach.gd")
const Student=preload("res://tools/first_minute_student.gd")
const OUT="res://../docs/evidence/first-minute/"
var checks:Array=[]
var scene:Node
var trials:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,ok:bool) -> void:
    checks.append({"name":name,"passed":ok});print("FIRST_MINUTE ",name," ",ok)
    if not ok:push_error(name)
func fresh(character:=0) -> RefCounted:
    var s=Sim.new();s.training=true;s.arcade_enabled=true;s.last_service_enabled=true
    s.character_choices=[character,(character+1)%4];s.reset_round();s.phase="fight";s.ai_enabled=false
    for side in 2:s.fighters[side].x=-.6 if side==0 else .6;s.fighters[side].meter=100
    return s
func tick(s:RefCounted,c:RefCounted,input:Dictionary={}) -> void:
    s.tick(input,c.command(s));c.observe(s)
func step() -> void:
    scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func key(code:int,echo:=false) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;e.echo=echo;scene._unhandled_key_input(e)
func shot(name:String) -> void:
    if DisplayServer.get_name()=="headless":return
    scene.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
    var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST);img.save_png(OUT+name+".png")
func run() -> void:
    for character in 4:
        for lesson in 4:
            var s=fresh(character);var c=Coach.new();c.index=lesson;c.reset_attempt();c.advance()
            var events:Dictionary={};var steps:=0
            for i in 1500:
                tick(s,c,Student.command(s,c));steps+=1
                for e in s.events:events[e.kind]=events.get(e.kind,0)+1
                if c.completed[lesson]:break
            check("character %d lesson %d completes only with real actions"%[character,lesson],c.completed[lesson])
            check("character %d lesson %d cannot complete on a whiff"%[character,lesson],events.get("hit",0)>0)
            trials.append({"character":character,"lesson":lesson,"steps":steps,"events":events,"passed":c.completed[lesson]})
    var s=fresh();var c=Coach.new();c.advance();s.fighters[1].x=6
    for i in 120:tick(s,c,{"attack":"light"})
    check("whiff cannot pass combo and gives distance feedback",c.status=="running" and c.combo_max==0 and c.feedback.contains("MISS"))
    s=fresh();c=Coach.new();c.index=3;c.reset_attempt();c.advance();s.fighters[0].meter=10
    for i in 50:tick(s,c,{"attack":"overdrive"})
    check("low energy cannot pass burst lesson",not c.paid and not c.completed[3] and c.feedback.contains("ENERGY"))
    s=fresh();c=Coach.new();c.index=3;c.reset_attempt();c.advance();tick(s,c,{"attack":"overdrive"})
    check("paid startup alone is not success",c.paid and not c.completed[3] and s.fighters[0].meter==25)
    s=fresh();c=Coach.new();c.index=1;c.reset_attempt();c.advance()
    # Hold a genuine guard from before the windup: block, never claim a parry/counter.
    for i in 140:tick(s,c,{"guard":true})
    check("ordinary block alone never passes counter lesson",not c.parried and not c.completed[1])
    check("holding guard gets a release-and-tap timing hint",c.cue(s).contains("RELEASE SHIFT"))
    s=fresh();c=Coach.new();c.advance()
    for i in 90:
        s.tick({"attack":"light"},{"guard":true,"allow_parry":false});c.observe(s)
    check("blocked attacks do not count as combo success",not c.completed[0] and c.combo_max==0 and c.feedback.contains("BLOCKED"))
    s=fresh();c=Coach.new();c.index=1;c.reset_attempt();c.advance()
    var startup_counter:=false
    for i in 35:
        s.tick({"attack":"light"} if i==0 else {},{"attack":"heavy"} if i==0 else {});c.observe(s)
        for e in s.events:
            if e.kind=="hit" and e.attacker==0 and e.get("counter",false):startup_counter=true
    check("startup counter hit cannot replace parry counter objective",startup_counter and not c.parried and not c.completed[1])
    s=fresh();c=Coach.new();c.index=1;c.reset_attempt();c.advance()
    for i in 140:
        var input:Dictionary=Student.command(s,c);input.erase("attack");tick(s,c,input)
    check("real parry alone never claims completed counter",c.parried and not c.completed[1])
    for i in 70:tick(s,c)
    check("expired counter opportunity does not keep a false ready cue",not c.parried and not c.completed[1])
    s=fresh();c=Coach.new();c.index=2;c.reset_attempt();c.advance()
    tick(s,c,{"attack":"heavy","up":true})
    for i in 32:tick(s,c)
    check("real launcher alone cannot pass air lesson",c.launched and not c.chased and not c.completed[2])
    for i in 70:tick(s,c)
    check("expired chase opportunity asks for a fresh launcher",not c.launched and c.feedback.contains("CLOSED"))
    s=fresh();c=Coach.new();c.index=1;c.reset_attempt();c.advance()
    s.tick({}, {"attack":"heavy"})
    for i in 8:s.tick()
    s.fighters[0].state="stun";s.fighters[0].stun=20
    check("windup cue never promises guard during player stun",not c.cue(s).contains("SHIFT NOW"))
    s=fresh();c=Coach.new();c.index=1;c.reset_attempt();c.advance()
    var twin=Coach.new();twin.index=1;twin.reset_attempt();twin.advance()
    var same:=true
    for i in 160:
        var before:Array=s.fighters.duplicate(true)
        var a:Dictionary=c.command(s);var b:Dictionary=twin.command(s)
        same=same and a==b and s.fighters==before
        s.tick({},a);c.observe(s);twin.observe(s)
    check("companion is deterministic and never edits fighter state",same)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    var growth_before:String=JSON.stringify(scene.growth.records)
    key(KEY_C)
    check("C enters explicit fixture without experimental window",scene.coach!=null and scene.coach.status=="ready" and scene.sim.fighters[0].meter==100 and scene.sim.exchange.pressure==0 and not scene.sim.surge_lab_enabled)
    var before_tick:int=scene.sim.tick_count
    key(KEY_J)
    for i in 30:step()
    check("ready screen waits for deliberate start without queued attacks",scene.sim.tick_count==before_tick and scene.pending.is_empty())
    await shot("ready")
    scene.hud.coach_continue.pressed.emit()
    check("native begin button starts current lesson",scene.coach.status=="running")
    for i in 220:
        scene.pending=Student.command(scene.sim,scene.coach);step()
        if scene.coach.status=="passed":break
    check("session route completes actual combo",scene.coach.status=="passed")
    await shot("combo-passed")
    key(KEY_ENTER,true);check("key echo cannot skip lesson",scene.coach.index==0)
    key(KEY_ENTER);check("Enter continues and resets explicit next fixture",scene.coach.index==1 and scene.coach.status=="running" and scene.sim.fighters[0].meter==100 and scene.sim.combo_hits==0)
    for i in 400:
        scene.pending=Student.command(scene.sim,scene.coach);step()
        if scene.coach.status=="passed":break
    check("session route completes real parry counter",scene.coach.status=="passed")
    await shot("counter-passed")
    key(KEY_ENTER)
    var snap:Array=scene.sim.fighters.duplicate(true);var elapsed:float=scene.coach.elapsed
    scene.pending.attack="heavy";scene.pending.up=true
    scene.pause_game()
    for i in 60:step()
    check("Esc preserves objective, pending and clocks",scene.coach.index==2 and scene.coach.elapsed==elapsed and scene.sim.fighters==snap and scene.pending.attack=="heavy")
    scene.resume_game()
    for i in 400:
        scene.pending=Student.command(scene.sim,scene.coach);step()
        if scene.coach.status=="passed":break
    check("session route completes paid chase and real air hit",scene.coach.status=="passed")
    await shot("air-passed")
    key(KEY_ENTER);scene.reduced_effects=true
    for i in 240:
        scene.pending=Student.command(scene.sim,scene.coach);step()
        if scene.coach.status=="complete":break
    check("F2 retains final paid-hit objective",scene.coach.status=="complete" and scene.coach.completed==[true,true,true,true])
    await shot("complete")
    check("tutorial never awards XP or changes loadout",JSON.stringify(scene.growth.records)==growth_before and not scene.run_active)
    key(KEY_F5);check("retry keeps prior achievements and resets current attempt",scene.coach.index==3 and scene.coach.completed==[true,true,true,false] and scene.coach.status=="ready" and scene.sim.hitstop==0 and scene.pending.is_empty())
    scene.start_demo();check("free AI demo never inherits coach",scene.coach==null and scene.demo!=null)
    scene.start_first_minute();scene.start_surge_lab();check("SURGE comparison never inherits coach",scene.coach==null and scene.sim.surge_lab_fixture)
    scene.start_first_minute();scene.prime_pressure_drill();check("old F8 classroom remains isolated",scene.coach==null and scene.sim.pressure_drill)
    scene.start_first_minute();scene.start_match(false);check("standard FIGHT stays fixed and uncoached",scene.coach==null and not scene.practice and scene.sim.service_perks==[[],[]])
    scene.start_first_minute();scene.return_to_title();check("exit clears all tutorial state",scene.coach==null and scene.pending.is_empty() and not scene.rhythm.active())
    check("music transport survives all lesson and mode switches",scene.audio.music.playing and not scene.audio.music.stream_paused)
    scene.queue_free();scene=null
    for i in 8:await process_frame
    await create_timer(.3).timeout
    var passed:int=checks.filter(func(t:Dictionary)->bool:return t.passed).size()
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks,"trials":trials,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"scope":"Automated students and explicit training fixtures, not human learning or fun validation."},"  "))
    quit(0 if passed==checks.size() else 1)
