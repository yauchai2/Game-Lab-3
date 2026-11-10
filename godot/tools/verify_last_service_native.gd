extends SceneTree
const OUT="res://../docs/evidence/last-service-runtime/"
var s:Node
var checks:Array=[]
var hits:Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(name:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":name,"pass":passed,"detail":detail});print("SERVICE_NATIVE ",name," ",passed," ",detail)
func frames(n:=4) -> void:
    for i in n:await process_frame
func shot(label:String) -> void:
    s.hud.queue_redraw();await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+label+".png")
func button(key:String) -> Button:
    for node in s.hud.menu_stack.get_children():
        if node is Button and node.get_meta("ui_key","")==key:return node
    return null
func click(control:Control) -> void:
    if not is_instance_valid(control):check("Requested native button exists",false);return
    await frames(3)
    for pressed in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=root.get_screen_transform()*control.get_global_rect().get_center();event.global_position=event.position;event.pressed=pressed;Input.parse_input_event(event);await frames(2)
func run() -> void:
    var path:="/tmp/service-native-growth.cfg"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=path;root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.hud.open_page("roster");await frames()
    for i in 4:
        s.set_character(0,i);s.hud.roster_preview.update_preview(true,i,.2,false);await frames(8)
        var visual:Node=s.fighters[0]
        check("New model %d mapped and animated"%i,visual.motions.mapping.size()>=50 and visual.skeleton.get_bone_count()==65 and visual.motions.bone_index("RightHand")>=0)
    s.set_character(0,1);s.start_match(true);s.sim._start_attack(0,"special")
    for event in s.sim.events:s._handle_event(event)
    s.sim.fighters[0].frame=8;s.sim.fighters[0].service.preload=2;s._process(.5)
    var swings:Array=s.effects.filter(func(e:Dictionary)->bool:return e.kind=="swing")
    check("Held RIVET shows no premature strike VFX",not swings.is_empty() and swings.all(func(e:Dictionary)->bool:return e.age<0))
    s.sim.fighters[0].frame=24;s._process(.016)
    check("Strike VFX begins on actual active frames",swings.all(func(e:Dictionary)->bool:return e.age>=0))
    s.sim.fighters[0].state="stun";s._process(.016)
    check("Interrupted skill clears tracked charge and strike graphics",not s.effects.any(func(e:Dictionary)->bool:return e.get("track_attack",false)))
    s.return_to_title();s.set_character(0,3);s.hud.open_page("roster");await frames()
    await click(s.hud.art_buttons.skills)
    check("Real pointer opens skill page",s.hud.menu_page=="skills" and is_instance_valid(button("skill_loop_life")))
    check("Locked skills do not consume points",button("skill_loop_life").disabled and s.growth.points(3)==0)
    s.hud.close_page();s.set_character(0,0);s.hud.rebuild_menu();await frames()
    await click(s.hud.art_buttons.street_run)
    check("Street Run starts with new mechanics and isolated save",s.run_active and s.run_stage==1 and s.sim.last_service_enabled and s.growth.path==path)
    # Low-health standing opponent fixture; player still must land a real paid skill.
    s.sim.ai_enabled=false;s.sim.fighters[0].x=-.5;s.sim.fighters[1].x=.5;s.sim.fighters[0].meter=100;s.sim.fighters[1].health=7
    s.pending={"attack":"special"}
    for i in 240:
        s._physics_process(1.0/60);s._process(1.0/60);s.hud._process(1.0/60)
    check("Real victory awards XP and a point",s.screen=="result" and s.sim.winner==0 and s.growth.points(0)==1 and s.run_reward>=40)
    var xp:int=s.growth.records.zip.xp;s._award_run()
    check("Repeated result handling cannot duplicate reward",s.growth.records.zip.xp==xp)
    await shot("run-result")
    await click(button("skills"))
    await click(button("skill_zip_route"));await click(button("skill_zip_route"))
    check("Pointer unlocks and equips earned ZIP skill",s.growth.equipped(0)==["zip_route"] and s.growth.points(0)==0)
    await shot("skills-earned")
    s.hud.close_page();await frames()
    await click(button("next_stop"))
    check("Next stop changes rival and applies selected build",s.run_stage==2 and s.character_choices[1]==2 and "zip_route" in s.sim.fighters[0].perks)
    for stop in [2,3]:
        s.sim.ai_enabled=false;s.sim.fighters[0].x=-.5;s.sim.fighters[1].x=.5;s.sim.fighters[0].meter=100;s.sim.fighters[1].health=7
        s.pending={"attack":"special"}
        for frame in 240:s._physics_process(1.0/60);s._process(1.0/60);s.hud._process(1.0/60)
        check("Stop %d finishes through a real contact"%stop,s.screen=="result" and s.sim.winner==0 and s.run_stage==stop)
        if stop==2:await click(button("next_stop"))
        else:await click(button("end_run"))
    check("Three-stop clear returns to roster with saved mastery",s.screen=="title" and s.hud.menu_page=="roster" and s.growth.records.zip.xp>=120)
    s.return_to_title();s.start_match(false)
    check("Standard fight removes all progression modifiers",not s.run_active and s.sim.fighters[0].perks.is_empty() and s.sim.service_perks==[[],[]])
    s.return_to_title();s.set_character(0,2);s.set_character(1,3);s.start_demo()
    s.combat_event.connect(func(e:Dictionary):hits[e.kind]=hits.get(e.kind,0)+1)
    var peak_nodes:=0
    for frame in 1800:
        s._physics_process(1.0/60);s._process(1.0/60)
        peak_nodes=maxi(peak_nodes,s.sim.fighters[1].service.nodes.size())
    check("Free AI remains alive and both new roles hit",s.screen=="play" and s.demo.hits[0]>0 and s.demo.hits[1]>0,s.demo.hits)
    check("AI uses legal LOOP nodes",hits.get("node_placed",0)>0 and peak_nodes<=2,{"placed":hits.get("node_placed",0),"pulses":hits.get("node_pulse_fx",0),"peak":peak_nodes})
    check("Demo grants no XP",s.growth.records.hush.xp==0 and s.growth.records.loop.xp==0)
    await shot("hush-loop-demo")
    s.return_to_title();s.queue_free();s=null;await frames(8);await RenderingServer.frame_post_draw
    check("Replacement materials retire cleanly",preload("res://scripts/combat/fighter_visual.gd").retired_materials.is_empty())
    FileAccess.open(OUT+"native-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"demo_events":hits,"scope":"Real pointer inputs, model mapping/rendering, low-health standing-opponent result fixture, actual free AI. Linux Compatibility, not target Mac hardware or human-play proof."},"  "))
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
    await frames(4)
    await create_timer(.3).timeout
    call_deferred("quit",0 if checks.all(func(c:Dictionary)->bool:return c.pass) else 1)
