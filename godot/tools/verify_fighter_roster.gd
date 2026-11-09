extends SceneTree
const Roster=preload("res://scripts/combat/fighter_roster.gd")
var scene:Node
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("ROSTER FAIL: "+label)
func frames(n:=2) -> void:
    for i in n:await process_frame
func shot(name:String) -> void:
    await process_frame;await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/charged-cannon/roster-captures"))
    root.get_texture().get_image().save_png("res://../docs/evidence/charged-cannon/roster-captures/"+name+".png")
func step() -> void:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func settle_preview() -> void:
    for i in 90:scene._process(1.0/60);scene.hud._process(1.0/60)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await frames()
    check("four source characters are available",Roster.ENTRIES.size()==4 and scene.character_choices==[0,1])
    var before:Dictionary=scene.sim.fighters[0].duplicate(true)
    for selection in 4:
        scene.set_character(0,selection);await frames()
        var visual:Node=scene.fighters[0]
        check("character %d has a complete retargeted rig"%selection,visual.skeleton.get_bone_count()==65 and visual.motions.mapping.size()>=50 and visual.motions.target_hips>=0)
        var pose:Dictionary=scene.sim.fighters[0].duplicate(true)
        pose.merge({"air_enabled":true,"rush_visual":true,"state":"attack","move":"meteor","frame":14,"y":1.5},true)
        visual.present(pose,1.0/60,false,false)
        check("character %d deforms and enlarges both active hands"%selection,visual.oversized_bones.size()==2 and visual.motions.air_pose_name!="")
        var finite:=true
        for bone in visual.skeleton.get_bone_count():
            var transform:Transform3D=visual.skeleton.get_bone_global_pose(bone)
            finite=finite and transform.is_finite() and absf(transform.basis.determinant())>.001
        check("character %d bone transforms remain finite"%selection,finite)
        pose.rush_visual=false;visual.present(pose,1.0/60,false,true)
        check("character %d restores active limb scales"%selection,visual.oversized_bones.is_empty() and visual.skeleton.get_bone_pose_scale(visual.skeleton.find_bone("mixamorig_LeftHand")).is_equal_approx(Vector3.ONE))
    check("swapping source models leaves combat data untouched",scene.sim.fighters[0]==before)
    scene.set_character(0,1);scene.set_character(1,2)
    scene.hud.open_page("roster");scene._process(.1);await frames()
    var selectors:Array=[]
    for control in scene.hud.menu_stack.find_children("*","OptionButton",true,false):selectors.append(control)
    check("title exposes two four-way roster selectors",selectors.size()==2 and selectors.all(func(c:OptionButton)->bool:return c.item_count==4))
    selectors[0].select(3);selectors[0].item_selected.emit(3);await frames();settle_preview()
    check("native selector callback updates the live model",scene.character_choices[0]==3 and scene.fighters[0].character_index==3)
    await shot("01_fighter_4_vs_3")
    selectors[0].select(1);selectors[0].item_selected.emit(1);await frames();settle_preview()
    await shot("02_fighter_1_vs_3")
    var fit:=true
    for language in ["zh","en"]:
        scene.language=language
        for viewport in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,900)]:
            root.size=viewport;scene.hud.rebuild_menu();await frames(3)
            for control in scene.hud.menu_stack.find_children("*","OptionButton",true,false):
                var rect:Rect2=control.get_global_rect()
                fit=fit and rect.position.x>=0 and rect.end.x<=root.size.x+1 and rect.end.y<=root.size.y+1
    check("both locales and three viewport sizes contain the roster controls",fit)
    root.size=Vector2i(1280,720);scene.language="zh";scene.hud.close_page();await frames()
    var all_chains:=true
    for selection in [1,2,3]:
        scene.return_to_title();scene.set_character(0,selection);scene.set_character(1,0);scene.start_match(false)
        var seen:={}
        for tick in 600:
            scene.pending["attack"]="light";scene.pending["rush"]=true
            # Physical held-J mirrors the actual runtime path.
            var key:=InputEventKey.new();key.keycode=KEY_J;key.physical_keycode=KEY_J;key.pressed=true
            Input.parse_input_event(key)
            step()
            for event in scene.sim.events:
                if event.kind=="hit" and event.attacker==0:seen[event.move]=true
            if scene.screen=="result":break
        all_chains=all_chains and seen.has("meteor") and scene.screen=="result" and scene.sim.winner==0
        if selection==3:await shot("03_new_fighter_ko")
        var release:=InputEventKey.new();release.keycode=KEY_J;release.physical_keycode=KEY_J;release.pressed=false;Input.parse_input_event(release)
        var chosen:Array=scene.character_choices.duplicate();scene.set_character(0,0)
        check("selection %d cannot change during combat/result"%selection,scene.character_choices==chosen)
    check("all three new models play a real air chain through KO",all_chains)
    scene.return_to_title();scene.set_character(0,2);scene.set_character(1,3);scene.start_demo()
    for i in 600:step()
    check("endless demo keeps the selected distinct pair",scene.demo!=null and scene.fighters[0].character_index==2 and scene.fighters[1].character_index==3 and scene.demo.hits[0]+scene.demo.hits[1]>0)
    await shot("04_demo_pair")
    scene.return_to_title()
    for selection in 24:
        scene.set_character(0,selection%4);await frames(1)
    check("repeated preview swaps keep one model and one retarget cache",scene.fighters[0].get_child_count()==1 and scene.fighters[0].materials.size()==1 and scene.fighters[0].motions.source_rest.size()>0 and scene.fighters[0].motions.target_local_rest.size()==65)
    scene.set_character(0,99)
    check("invalid roster indices clamp safely",scene.character_choices[0]==3)
    var prefs=preload("res://scripts/combat/fight_preferences.gd").new()
    var path:="user://verify_roster.cfg"
    prefs.write_options(path,{"player_character":2,"rival_character":3})
    var loaded:Dictionary=prefs.read_options(path)
    check("roster preferences persist independently",loaded.player_character==2 and loaded.rival_character==3)
    prefs.write_options(path,{"player_character":-9,"rival_character":999})
    loaded=prefs.read_options(path)
    check("corrupt numeric preferences stay in the roster",loaded.player_character==0 and loaded.rival_character==3)
    DirAccess.remove_absolute(path)
    scene.queue_free();await frames()
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/character-roster/native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Native Godot model, retargeting, presentation and UI callbacks; fixed-step injected input, software GL, not human playtest."},"  "))
    print("ROSTER_CHECKS ",passed,"/",checks.size());call_deferred("quit",0 if passed==checks.size() else 1)
