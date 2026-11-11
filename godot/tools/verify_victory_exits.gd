extends SceneTree
const OUT="res://../docs/evidence/victory-exits/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("VICTORY ",label," ",ok)
    if not ok:push_error(label)
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/victory-test-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true;s.reduced_effects=false
    await process_frame;await process_frame
    var poses:Dictionary={}
    for side in 2:
        for character in 4:
            s.return_to_title();s.set_character(side,character)
            await process_frame;await process_frame
            s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1-side].health=0;s._combat_step()
            var c=s.city_breaker
            var snapshot:Array=s.sim.fighters.duplicate(true)
            check("five second destruction retained %d/%d"%[side,character],c.BASE_DURATION==5.0 and is_equal_approx(c.DURATION,8.2))
            c.sample_outro(.25);var hero:Node3D=s.fighters[side]
            check("winner uses live selected model %d/%d"%[side,character],hero.character_index==character and hero.visible and not s.fighters[1-side].visible)
            check("close lens has actual perspective and fisheye %d/%d"%[side,character],s.camera.fov>=115 and s.camera.near<.05 and c.lens_material.get_shader_parameter("fisheye")>.7)
            var head:int=hero.motions.bone_index("Head")
            var at:Vector3=hero.skeleton.global_transform*hero.skeleton.get_bone_global_pose(head).origin
            var pixel:Vector2=s.camera.unproject_position(at)/root.get_visible_rect().size
            check("head remains in close frame %d/%d"%[side,character],not s.camera.is_position_behind(at) and pixel.x>.1 and pixel.x<.9 and pixel.y>0 and pixel.y<1)
            c.sample_outro(.75)
            if side==0:
                var bone:int=hero.motions.bone_index("RightForeArm")
                var q:Quaternion=hero.skeleton.get_bone_pose_rotation(bone)
                poses[character]=Vector4(q.x,q.y,q.z,q.w)
            c.advance(0.0,false)
            check("character owns dedicated exit score %d/%d"%[side,character],c.outro_started and c.score_player.stream==c.outro_scores[character] and absf(c.score_player.stream.get_length()-3.2)<.03)
            s.pause_game();var elapsed:float=c.playback_elapsed;var before:Transform3D=hero.transform
            s._process(.2)
            check("pause freezes exit pose and score %d/%d"%[side,character],c.playback_elapsed==elapsed and hero.transform.is_equal_approx(before) and c.score_player.stream_paused)
            s.resume_game();s._process(.01)
            check("resume stays in result outro %d/%d"%[side,character],s.screen=="result" and not c.score_player.stream_paused)
            c.sample_outro(3.15)
            var end:Vector2=s.camera.unproject_position(hero.position+Vector3(0,1,0))/root.get_visible_rect().size
            check("winner walks outside screen %d/%d"%[side,character],end.x<0 or end.x>1)
            check("exit leaves combat snapshot unchanged %d/%d"%[side,character],s.sim.fighters==snapshot)
            s.skip_city_breaker()
            check("skip restores near lens and stops sound %d/%d"%[side,character],not c.active() and is_equal_approx(s.camera.near,.1) and not c.score_player.playing and c.lens_material.get_shader_parameter("fisheye")==0)
    var distinct:=true
    for a in 4:
        for b in range(a+1,4):distinct=distinct and poses[a].distance_to(poses[b])>.05
    check("four poses are measurably distinct on the actual rigs",distinct)
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    for i in 301:s._process(1.0/60)
    check("KO flows into winner closeup before showing result menu",s.city_breaker.active() and not s.finish_menu_open and not s.city_breaker.victory_state.is_empty())
    for i in 194:s._process(1.0/60)
    check("automatic completion after exit shows results",not s.city_breaker.active() and s.finish_menu_open)
    for action in ["F2","restart","title"]:
        s.reduced_effects=false;s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
        s.city_breaker.sample_outro(.45)
        if action=="F2":s.reduced_effects=true;s._process(.01)
        elif action=="restart":s.start_match(false)
        else:s.return_to_title()
        check(action+" during winner closeup releases fisheye / sound / near plane",not s.city_breaker.active() and not s.city_breaker.score_player.playing and is_equal_approx(s.camera.near,.1) and s.city_breaker.lens_material.get_shader_parameter("fisheye")==0)
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    # Let the threaded Dummy mixer release stopped playback before engine exit.
    await create_timer(.35).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(v:Dictionary)->bool:return not v.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name()},"  "))
    print("VICTORY_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
