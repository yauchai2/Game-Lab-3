extends SceneTree
var s:Node
var checks:Array=[]
var out:String
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("INTEGRATION ",label," ",ok)
func frames() -> void:
    await process_frame;await process_frame;await RenderingServer.frame_post_draw
func shot(label:String) -> void:
    s.hud.queue_redraw();await frames();root.get_texture().get_image().save_png(out+"/"+label+".png")
func keys() -> Array:
    var result:Array=[]
    for node in s.hud.menu_stack.find_children("*","Button",true,false):result.append(node.get_meta("ui_key",""))
    return result
func run() -> void:
    out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path="";s.progression_path="";s.story_opening_on_boot=false;s.city_save_path="user://remaining-integration-city.json"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);await frames()
    s.return_to_title();await frames()
    check("Five main actions, no public AI demo",s.hud.art_buttons.keys()==["story","fight","roster","training","settings"])
    await shot("main")
    s.hud.open_page("settings");await frames()
    var settings_keys:Array=keys()
    check("Settings expose controls, labs and opening replay",settings_keys.has("labs") and settings_keys.has("how_to_play") and settings_keys.has("replay_opening"))
    check("Exactly two audio level controls",s.hud.menu_stack.find_children("*","HSlider",true,false).size()==2)
    check("No duplicate music switch or intro replay",not settings_keys.has("music_enable") and not settings_keys.has("replay_intro"))
    s.audio.music_muted=true;s.set_volume("music",.5)
    check("Music slider can restore a legacy muted music preference",not s.audio.music_muted and s.audio.music_level==.5)
    await shot("settings")
    s.hud.open_page("labs");await frames()
    check("Legacy drills collected under LABS",keys().has("pressure_lab") and keys().has("rally_lab") and keys().has("air_lab") and keys().has("surge_lab"))
    await shot("labs")
    s.hud.open_page("help");await frames()
    check("One lesson entry and no duplicated per-hero pages",keys().has("first_minute") and keys().has("labs"))
    await shot("help")
    s.hud.open_page("roster");await frames()
    check("Roster selects fighters without duplicate mode launches",s.hud.art_buttons.roster_fight.text=="CONFIRM" and not s.hud.art_buttons.has("street_run") and not s.hud.art_buttons.has("story_waves"))
    await shot("roster")
    s.start_match(false);s.round_theatre.clear();s.sim.phase="fight";s.sim.ai_enabled=false
    s.hud.hint_round=s.sim.round_number;s.hud.hint_elapsed=0;s.control_hints=0
    check("Auto hints visible on opening round",s.hud.hints_visible())
    await shot("hud-hints")
    s.hud._process(7)
    check("Auto hints expire after six seconds",not s.hud.hints_visible())
    await shot("hud-clear")
    var age:float=s.hud.hint_elapsed;s.pause_game();s.hud._process(8)
    check("Pause freezes hint timer",s.hud.hint_elapsed==age)
    s.resume_game();s.control_hints=1
    check("Always hints override timer",s.hud.hints_visible())
    s.control_hints=2;s.practice=true
    check("Off preference also hides ordinary training legend",not s.hud.hints_visible())
    s.practice=false;s.control_hints=0;s.sim.round_number=2;s.hud.hint_elapsed=0
    check("Auto hints stay hidden in later rounds",not s.hud.hints_visible())
    var actor:Node3D=preload("res://scripts/combat/fighter_visual.gd").new();s.add_child(actor)
    for hero in 4:
        actor.setup(Color.WHITE,hero)
        for face in [-1,1]:
            var sim=preload("res://scripts/combat/fight_simulation.gd").new()
            sim.last_service_enabled=true;sim.arcade_enabled=true;sim.character_choices=[hero,0];sim.reset_round();sim.ai_enabled=false;sim.phase="fight"
            var f:Dictionary=sim.fighters[0];f.face=face;f.x=0;f.y=0;f.air_enabled=true
            var before:String=JSON.stringify(f);var finite:=true
            for i in 30:
                actor.present(f,1.0/60,false,false)
                for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
            check("Finite planted pose %d / %d"%[hero,face],finite and actor.foot_contact.corrections>0)
            check("Foot solver preserves simulation %d / %d"%[hero,face],JSON.stringify(f)==before)
            check("Bounded foot target error %d / %d"%[hero,face],actor.foot_contact.max_error<.08,actor.foot_contact.max_error)
            var finite_attacks:=true
            var preserved:=true
            for attack in ["jab","cross","heavy","finisher","launcher","special","overdrive"]:
                f.state="attack";f.move=attack;f.move_data=sim.move_for(f,attack)
                for sample in [1,int(f.move_data.startup),int(f.move_data.startup+f.move_data.active),int(f.move_data.startup+f.move_data.active+f.move_data.recovery-1)]:
                    f.frame=sample;var saved:String=JSON.stringify(f)
                    actor.present(f,1.0/60,false,false)
                    preserved=preserved and JSON.stringify(f)==saved
                    for bone in actor.skeleton.get_bone_count():finite_attacks=finite_attacks and actor.skeleton.get_bone_global_pose(bone).is_finite()
            check("Ground attack contact and recovery stay finite %d / %d"%[hero,face],finite_attacks and preserved)
            check("Ground motion support error stays bounded %d / %d"%[hero,face],actor.foot_contact.max_error<.08,actor.foot_contact.max_error)
            f.state="idle";f.move="";f.move_data={}
            f.y=1;actor.present(f,1.0/60,false,false)
            check("Airborne clears plant anchors %d / %d"%[hero,face],actor.foot_contact.anchors.is_empty())
            f.y=0;f.state="idle";f.vx=0;f.showcase=true;f.shared_profile=true
            actor.motions.present(f,.1,false)
            check("Showcase shares hero motion profile %d / %d"%[hero,face],actor.motions.pose_owner!="legacy",actor.motions.pose_owner)
    actor.queue_free()
    s.queue_free();await frames()
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(out+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Linux llvmpipe native renderer, explicit UI/pose fixtures. No physical controllers, human feel, Mac GPU, terrain IK or paired throw asset validation."},"  "))
    quit(0 if failed==0 else 1)
