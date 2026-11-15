extends SceneTree
var session:Node3D
var fails:=0
var checks:=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
    checks+=1
    if not ok:fails+=1;push_error(label)
    print("DEADSHIFT ",label," ",ok)
func run()->void:
    session=preload("res://scenes/combat/street_fight.tscn").instantiate()
    session.preferences_path=""
    root.add_child(session)
    session.set_process(false);session.set_physics_process(false)
    for i in 5:await process_frame
    session.start_story()
    session.reduced_effects=true
    var sim=session.sim
    check("opening wave casts knuckle",session.squad_visuals[0].deadshift_id=="knuckle")
    sim.ai_enabled=false
    for f in sim.squad_members:f.health=0
    sim._finish_round()
    session._combat_step()
    check("wave 1 starts Dealer intermission",session.ability_draw.active() and session.ability_draw.continuation=="deadshift_wave" and session.screen=="result")
    check("all story actors hidden during draw",session.squad_visuals.all(func(v):return not v.visible))
    var draw=session.ability_draw
    draw.skip()
    draw.input_armed=true
    draw.confirm()
    check("Dealer actually draws a core",draw.state=="spin" and not draw.result.is_empty())
    var core:String=draw.result.id
    draw.skip()
    await process_frame
    draw.input_armed=true
    draw.confirm()
    check("draw has a real equip phase",draw.state=="equip")
    draw.skip()
    check("draw returns to wave 2 with usable core",sim.wave_index==1 and sim.fighters[0].get("draw_core")==core and session.screen=="play")
    var names:Array=session.squad_visuals.map(func(v):return v.deadshift_id)
    check("second wave roles",names==["bulk","skid","knuckle","tether"])
    check("shield attached",session.squad_visuals[0].skeleton.get_node_or_null("StoryRole")!=null)
    var handler=session.squad_visuals[3]
    var snap=handler.get_node_or_null("DeadshiftSnap")
    check("SNAP uses original 33-joint dog rig",snap!=null and snap.skeleton.get_bone_count()==33 and snap.bones.size()==9)
    var dog_bone:int=snap.skeleton.find_bone("bone_17")
    var q:Quaternion=snap.skeleton.get_bone_pose_rotation(dog_bone)
    var member:Dictionary=sim.squad_members[3]
    member.vx=3.5
    for i in 5:handler.present(member,.025,false,false)
    check("SNAP animates when handler moves",snap.skeleton.get_bone_pose_rotation(dog_bone).angle_to(q)>.05)
    for actor in session.squad_visuals:
        check("humanoid Tripo rig "+actor.deadshift_id,actor.skeleton.get_bone_count()==65 and actor.motions.bone_index("LeftHand")>=0)
    sim.story_state="break";sim.next_story_wave();session._sync_story_visuals()
    check("third wave named specialists",session.squad_visuals[3].deadshift_id=="foreman" and session.squad_visuals[1].deadshift_id=="static")
    check("signal case attached",session.squad_visuals[1].skeleton.get_node_or_null("StoryRole")!=null)
    for index in [3,1]:
        var f:Dictionary=sim.squad_members[index]
        var actor=session.squad_visuals[index]
        f.state="idle";f.vx=1.1*f.face;f.y=0.0
        for i in 8:actor.present(f,1.0/60.0,false,false)
        check("Mixamo locomotion "+actor.deadshift_id,actor.motions.clip_name=="MX_Walking" and actor.lowest_skin_y()>=.008)
        f.state="attack";f.move="heavy";f.move_data=sim.move_for(f,"heavy");f.frame=f.move_data.startup
        for i in 5:actor.present(f,1.0/60.0,false,false)
        check("Mixamo hit pose "+actor.deadshift_id,actor.motions.clip_name=="MX_BodyPunch" and actor.lowest_skin_y()>=.008)
        f.state="stun";f.y=1.0;actor.impact_reaction("hit","air_kick",-f.face,true,.55)
        actor.present(f,.016,true,false)
        check("air hit readable during freeze "+actor.deadshift_id,absf(actor.model.rotation.x)>.35 and actor.reaction_age==0)
    sim.arrival_left=0;sim.squad_clock=149
    sim.squad_members[1].state="idle";sim.squad_members[1].y=0.0
    sim.tick()
    check("STATIC projects a third-wave warned zone",sim.campaign_hazards.size()==1 and sim.campaign_hazards[0].source==1 and sim.campaign_hazards[0].warn==60)
    session._present(0.0)
    await process_frame
    var args:=OS.get_cmdline_user_args()
    if not args.is_empty() and DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(args[0])
    session.return_to_title()
    check("leave story restores regular roster",session.squad_visuals.is_empty() and session.fighters[1].deadshift_id=="")
    session.queue_free()
    for i in 4:await process_frame
    print("DEADSHIFT_RESULT ",checks-fails,"/",checks)
    quit(1 if fails else 0)
