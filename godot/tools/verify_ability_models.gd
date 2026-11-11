extends SceneTree
var OUT="res://../docs/evidence/ability-draw/tripo-models/"
var s:Node
var checks:Array=[]
var samples:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ABILITY_MODELS ",label," ",ok)
    if not ok:push_error(label)
func run() -> void:
    if "--rhythm-ui" in OS.get_cmdline_user_args():OUT="res://../docs/evidence/ability-draw/rhythm-ui/"
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ability-models-growth.cfg";root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await process_frame;await process_frame
    s.start_match(false);s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.advance_round()
    var d=s.ability_draw;var v=d.actors;var rig=v.dealer_rig
    check("uploaded character is the visible 65-bone rig",rig.skeleton.get_bone_count()==65 and rig.model.visible)
    check("uploaded cabinet is actually in the moving chassis",v.shell_model.get_parent()==v.chassis and v.shell_model.visible)
    check("all two-bone and finger chains resolve",["LeftArm","LeftForeArm","LeftHand","RightArm","RightForeArm","RightHand","Head","LeftFoot","RightFoot","LeftHandIndex1","LeftHandThumb3"].all(func(id):return rig.bone(id)>=0))
    check("existing CC0 gait retargets actual source skeleton",rig.motions.mapping.size()>=50)
    check("shell retains source embedded albedo",v.shell_model.find_children("*","MeshInstance3D",true,false).all(func(node):return node.get_surface_override_material(0).get_shader_parameter("base_texture")!=null))
    check("three drums four wheels and flap remain independent",v.reels.size()==3 and v.wheels.size()==4 and v.hatch.get_parent()==v.chassis)
    var hand_points:Array=[];var foot_poses:Array=[];var errors:Array=[]
    for t in [.30,.55,.82,1.05,1.42,1.70,2.16,2.85,3.75]:
        d.state="arrival" if t<1.95 else ("offer" if t<2.55 else "spin")
        d.source_age=t;d.age=t-2.55 if t>=2.55 else t;d.result={"id":"speed"};d.sample()
        var hand:Vector3=rig.point("LeftHand")
        var foot:Quaternion=rig.skeleton.get_bone_pose_rotation(rig.bone("LeftUpLeg"))
        hand_points.append(hand);foot_poses.append(foot)
        if rig.pose_label in ["drag","slap"]:errors.append(rig.contact_error)
        samples.append({"time":t,"pose":rig.pose_label,"hand":str(hand),"contact_error_m":rig.contact_error})
        check("pose %.2f remains finite"%t,hand.is_finite() and rig.model.global_transform.origin.is_finite())
    print("CONTACT_ERRORS ",errors)
    check("drag and slap wrist contacts stay within 15cm",errors.all(func(e):return e<.15))
    check("gait articulates leg bones rather than sliding a static model",absf(foot_poses[0].dot(foot_poses[1]))<.999)
    check("hand animation changes with authored phases",hand_points[0].distance_to(hand_points[4])>.35 and hand_points[4].distance_to(hand_points[6])>.3)
    d.state="offer";d.source_age=2.16;d.sample()
    check("token follows actual animated wrist",v.token.global_position.distance_to(rig.point("LeftHand"))<.3)
    if DisplayServer.get_name()!="headless":
        d.state="spin";d.source_age=3.4;d.age=.85;d.sample();s.hud.queue_redraw()
        await process_frame;await RenderingServer.frame_post_draw
        var image:Image=root.get_texture().get_image();var bright:=0;var total:=0
        for y in range(int(image.get_height()*.38),int(image.get_height()*.65),2):
            for x in range(int(image.get_width()*.35),int(image.get_width()*.65),2):
                var color:=image.get_pixel(x,y);total+=1
                if color.r>.65 and color.g>.70 and color.b>.65:bright+=1
        image.save_png(OUT+"reel-visibility-check.png")
        check("real reel faces are visible through the uploaded bay",float(bright)/maxi(total,1)>.15)
    var snapshot:Quaternion=rig.skeleton.get_bone_pose_rotation(rig.bone("LeftArm"));s.pause_game();s._process(.5)
    check("pause preserves uploaded skeleton pose",snapshot.is_equal_approx(rig.skeleton.get_bone_pose_rotation(rig.bone("LeftArm"))))
    s.return_to_title();check("return clears uploaded actors and temporary lens",not v.visible and not d.lens.visible)
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.15).timeout;s.queue_free();s=null
    for i in 10:await process_frame
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(OUT+"model-verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"samples":samples,"passed":checks.size()-failed,"failed":failed,"scope":"Actual uploaded character skin/bones and cabinet plus attached mechanisms; authored boundary fixture"},"  "))
    print("ABILITY_MODEL_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
