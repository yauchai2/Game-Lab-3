extends SceneTree
const OUT="res://../docs/evidence/ink-fx/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("INK_FX ",label," ",ok," ",detail)
func render() -> void:
    await process_frame;await RenderingServer.frame_post_draw
func shot(label:String) -> void:
    s.hud.queue_redraw();await render()
    root.get_texture().get_image().save_png(OUT+label+".png")
func fresh() -> void:
    s.return_to_title();s.start_match(true);s.sim.phase="fight";s.sim.ai_enabled=false
    s.sim.fighters[0].x=-.8;s.sim.fighters[1].x=.8
    s._process(.016)
func tick(a:Dictionary={},b:Dictionary={}) -> void:
    s.sim.tick(a,b)
    for event in s.sim.events:s._handle_event(event)
    s._process(1.0/60.0)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await render()
    fresh()
    var bones_ok:=true
    for character in 5:
        s.set_character(0,character);s._process(.016)
        for face in [-1,1]:
            s.sim.fighters[0].face=face;s._process(.016)
            for label in ["LeftHand","RightHand","LeftFoot","RightFoot","Spine"]:
                var socket:Vector3=s.fighters[0].fx_socket(label)
                bones_ok=bones_ok and socket.is_finite() and socket.distance_to(s.fighters[0].global_position)<4
    check("five characters and both facings have finite bounded bone sockets",bones_ok)
    s.set_character(0,0);fresh()
    # Footsteps must require actual distance, not repeated render calls or wall time.
    for i in 60:s._process(1.0/60)
    check("idle never emits movement smoke",s.ink_fx.active_count()==0)
    s.sim.fighters[1].x=5
    for i in 22:tick({"axis":1.0})
    check("actual grounded movement emits pooled foot dust",s.ink_fx.spawned>0 and s.ink_fx.active_count()>0,s.ink_fx.spawned)
    await shot("running")
    var spawn_count:int=s.ink_fx.spawned
    s.sim.fighters[0].vx=0
    for i in 30:s._process(1.0/60)
    check("render-only frames cannot invent new footsteps",s.ink_fx.spawned<=spawn_count+3)
    fresh();tick({"jump":true})
    for i in 10:
        if s.sim.fighters[0].y>.05:break
        tick()
    check("jump fixture actually left the ground",s.sim.fighters[0].y>.05)
    var count:int=s.ink_fx.spawned
    for i in 12:tick({"axis":1.0})
    check("airborne movement has no repeated ground dust",s.ink_fx.spawned==count,{"before":count,"after":s.ink_fx.spawned,"height":s.sim.fighters[0].y})
    fresh()
    for i in 50:
        tick({"attack":"light"} if i==0 else {"rush":true})
        if s.ink_fx.contact_age<.065:await shot("light-contact");break
    check("true hit produces a contact accent",s.ink_fx.contact_age<.1)
    var accent:float=s.ink_fx.contact_age
    s._process(.05);s._process(.05)
    check("hitstop cannot restart contact flash",s.ink_fx.contact_age>accent+.09 and s.fighters[1].fx_flash_age>=.045)
    check("contact remains within victim body region",absf(s.ink_fx.contact_at.x-s.sim.fighters[1].x)<.65)
    fresh();s.sim.fighters[1].x=8
    for i in 32:tick({"attack":"light"} if i==0 else {})
    check("whiff has no contact flash or impact puff",s.ink_fx.contact_age>.2 and s.ink_fx.pool.all(func(p:Dictionary)->bool:return p.rank==0 or p.age>=p.life))
    # A strong true hit is generated through ordinary input, no showcase damage.
    fresh()
    s._handle_event({"kind":"air_land","target":0,"hard":true});s._process(.04)
    check("formal aerial landing event emits world-space smoke",s.ink_fx.active_count()==5 and not s.effects.any(func(e:Dictionary)->bool:return e.kind=="dust"))
    fresh();s.sim.fighters[0].meter=100
    for i in 100:
        tick({"attack":"heavy","up":true} if i==0 else {})
        if s.ink_fx.contact_age<.065:await shot("launch-contact");break
    check("launcher keeps a finite directional accent",s.ink_fx.contact_at.is_finite())
    for i in 12:s._process(1.0/60)
    fresh()
    for i in 75:s._process(1.0/60)
    s.ink_fx.ground("slam",Vector3(0,.045,3),1,1,false);s._process(.08)
    s._process(.05);s._process(.05)
    await shot("landing-cels")
    var before:Array=[]
    for item in s.ink_fx.pool:before.append(item.age)
    s.pause_game();s._process(.2)
    var after:Array=[]
    for item in s.ink_fx.pool:after.append(item.age)
    check("pause freezes all world cels",before==after)
    s.resume_game();s.reduced_effects=true;s._process(.016)
    check("F2 clears smoke ribbons and camera accent",s.ink_fx.active_count()==0 and s.ink_fx.traces.is_empty() and s.ink_fx.camera_kick()==Vector2.ZERO)
    s.reduced_effects=false;fresh()
    # Saturated decoration cannot steal a reserved foreground hit/parry slot.
    for i in 100:s.ink_fx.emit_puff("wake",Vector3(0,1,3),1)
    check("decorative pool is capped with reserved space",s.ink_fx.active_count()==s.ink_fx.DECOR_LIMIT)
    s.ink_fx.emit_puff("heavy",Vector3(0,1,3),1,1)
    check("important smoke survives decorative saturation",s.ink_fx.active_count()==s.ink_fx.DECOR_LIMIT+1)
    for i in 100:s._spawn_vfx("trail",Vector2.ZERO,.2)
    s._spawn_vfx("parry",Vector2(0,1),.2)
    for i in 100:s._spawn_vfx("trail",Vector2.ZERO,.2)
    check("canvas decoration cannot evict parry",s.effects.any(func(e:Dictionary)->bool:return e.kind=="parry") and s.effects.size()<=24)
    var shapes=preload("res://scripts/combat/impact_shapes.gd").new()
    var valid:=true
    var all_shapes:Array=[]
    for character in 5:
        var signature:Array=[]
        for move in shapes.PROFILES:
            for kind in ["swing","hit","release"]:
                for frame in 6:
                    for face in [-1,1]:
                        for shape in shapes.build(kind,move,(frame+.2)/6.0,Color.CYAN,face,false,character):
                            valid=valid and not Geometry2D.triangulate_polygon(shape.points).is_empty()
                if move=="jab":signature.append(str(shapes.build(kind,move,.2,Color.CYAN,1,false,character)))
        all_shapes.append(str(signature))
    check("all authored move cels triangulate in both directions",valid)
    check("four hero normal effects have distinct shape language",all_shapes[0]!=all_shapes[1] and all_shapes[1]!=all_shapes[2] and all_shapes[2]!=all_shapes[3])
    s.ink_fx.clear()
    s.audio.muted=false;s.audio.contact_budget=0;s.audio.play_contact_layer(0,"jab",.3)
    var layers:int=s.audio.contact_layers_played
    s.audio.play_contact_layer(1,"heavy",.9)
    check("simultaneous contacts share one audio accent budget",s.audio.contact_layers_played==layers and s.audio.contact_budget>0)
    check("new contact layers contain PCM",s.audio.sounds.ink_snap[0].data.size()>1000 and s.audio.sounds.ink_scrape[0].data.size()>1000)
    s.audio.muted=true;s.audio.stop_all()
    s.return_to_title();check("menu transition drains all effects",s.ink_fx.active_count()==0 and s.ink_fx.traces.is_empty())
    s.start_squad();s.sim.phase="fight"
    for i in 150:
        s._physics_process(1.0/60);s._process(1.0/60)
        if i%30==0:await render()
    check("squad tracks each visual independently",s.ink_fx.tracking.size()==s.sim.squad_members.size()+1)
    check("squad remains within fixed pools",s.ink_fx.active_count()<=36 and s.ink_fx.traces.size()<=32)
    await shot("squad")
    s.return_to_title();s.start_match(false);s._process(.016)
    check("fight after squad has no stale member tracks",s.ink_fx.tracking.size()<=2)
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    check("material retirement drained",preload("res://scripts/combat/fighter_visual.gd").retired_materials.is_empty())
    var ok:bool=checks.all(func(c:Dictionary)->bool:return c.passed)
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"engine":Engine.get_version_info().string,"scope":"Native Linux Compatibility llvmpipe, fixed input and explicit pressure fixtures; not target hardware performance or a human playtest."},"  "))
    await create_timer(.3).timeout;quit(0 if ok else 1)
