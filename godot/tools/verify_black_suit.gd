extends SceneTree
## Integration check on actual runtime paths. Run natively to capture/read pixels.
const OUT="res://../docs/evidence/black-suit/"
const Roster=preload("res://scripts/combat/fighter_roster.gd")
var s:Node
var checks:Array=[]
var native:=false
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":value,"detail":detail})
    print("BLACK_SUIT ",label," ",value)
func frames(n:=3) -> void:
    for i in n:await process_frame
func shot(label:String) -> void:
    if not native:return
    s.hud.queue_redraw();await frames();await RenderingServer.frame_post_draw
    check("capture "+label,root.get_texture().get_image().save_png(OUT+label+".png")==OK)
func click(control:Control) -> void:
    await frames()
    if not native:
        control.pressed.emit()
        return
    for pressed in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
        event.position=root.get_screen_transform()*control.get_global_rect().get_center()
        event.global_position=event.position;event.pressed=pressed
        Input.parse_input_event(event);await frames(2)
func run() -> void:
    native=DisplayServer.get_name()!="headless"
    if not native:
        push_error("Run this visual integration check with a native display; use verify_last_service_rules for headless rules.")
        quit(2)
        return
    var options_path:="/tmp/black-suit-test-options.cfg"
    var prefs=preload("res://scripts/combat/fight_preferences.gd").new()
    prefs.write_options(options_path,{"player_character":2,"rival_character":4})
    s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path=options_path;s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await frames()
    check("enemy option restores into real model and simulation",s.character_choices==[2,4] and s.sim.fighters[1].character==4 and s.fighters[1].character_index==4)
    check("four hero identities and mastery records remain isolated",Roster.ENTRIES.size()==4 and s.growth.records.size()==4 and not s.growth.records.has("black_suit"))
    var v:Node=s.fighters[1]
    check("uploaded rig maps onto animation library",v.skeleton.get_bone_count()==65 and v.motions.mapping.size()>=50,{"bones":v.skeleton.get_bone_count(),"mapped":v.motions.mapping.size()})
    check("black suit preserves original texture",v.materials.size()>=1 and v.materials.any(func(m:ShaderMaterial)->bool:return m.get_shader_parameter("use_texture") and m.get_shader_parameter("tint")==Color.WHITE))
    s.set_character(0,4)
    check("enemy cannot replace a player hero",s.character_choices[0]==3)
    s.set_character(0,0);s.set_character(1,1);s.hud.open_page("roster");await frames()
    await click(s.hud.art_buttons.enemy_black_suit)
    s.hud.roster_preview.update_preview(true,4,.2,false);await frames()
    check("enemy button selects P2 with preview",s.hud.art.roster_side==1 and s.character_choices[1]==4 and s.hud.roster_preview.models[4].character_index==4)
    check("keyboard navigation reaches enemy button",s.hud.art_buttons.street_run.focus_neighbor_bottom==s.hud.art_buttons.enemy_black_suit.get_path() and s.hud.art_buttons.enemy_black_suit.focus_neighbor_left==s.hud.art_buttons.card_3.get_path())
    await shot("enemy-selection")
    for viewport_size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,900)]:
        root.size=viewport_size;await frames()
        var rect:Rect2=s.hud.art_buttons.enemy_black_suit.get_global_rect()
        check("enemy control fits viewport "+str(viewport_size),rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=root.get_visible_rect().size.x+1 and rect.end.y<=root.get_visible_rect().size.y+1)
    root.size=Vector2i(1280,720)
    s.start_match(true);s.sim.fighters[1].meter=100
    for move in ["jab","heavy","launcher","special","overdrive"]:
        var pose:Dictionary=s.sim.fighters[1].duplicate(true)
        pose.state="attack";pose.move=move;pose.move_data=s.sim.move_for(pose,move);pose.frame=pose.move_data.startup;pose.air_enabled=true
        v.present(pose,.1,false,false)
        var finite:=true
        for bone in v.skeleton.get_bone_count():finite=finite and v.skeleton.get_bone_global_pose(bone).is_finite()
        check("enemy animated pose "+move,finite)
    # Actual ordinary move contact, no damage injected by presentation.
    s.start_match(true)
    s.sim.fighters[0].x=-.6;s.sim.fighters[1].x=.6
    s.sim.fighters[1].face=-1;s.sim.fighters[0].face=1
    s.sim._start_attack(1,"jab")
    var health:float=s.sim.fighters[0].health
    for tick in 45:s.sim.tick({})
    check("enemy melee deals real damage",s.sim.fighters[0].health<health)
    # Parry the enemy through the same directional contact path.
    s.start_match(true);s.sim.fighters[0].x=-.6;s.sim.fighters[1].x=.6
    s.sim._start_attack(1,"jab");var parried:=false
    for tick in 16:
        s.sim.tick({"guard":true,"guard_pressed":tick==0})
        for e in s.sim.events:
            if e.kind=="parry" and e.target==0:parried=true
    check("enemy strikes remain parryable",parried)
    s.return_to_title();s.set_character(1,4);s.start_match(false)
    check("standard fight uses enemy and fixed stats",s.sim.fighters[1].character==4 and s.sim.service_perks==[[],[]] and not s.run_active)
    var choices:Array=s.character_choices.duplicate();s.set_character(1,0)
    check("enemy selection locked during fight",s.character_choices==choices)
    s.sim.phase="fight";s.sim.fighters[0].x=-.7;s.sim.fighters[1].x=.7
    s._process(.016);await shot("enemy-fight")
    s.return_to_title();s.start_demo()
    var events:Dictionary={}
    s.combat_event.connect(func(e:Dictionary):events[e.kind]=events.get(e.kind,0)+1)
    for tick in 1800:
        s._physics_process(1.0/60);s._process(1.0/60)
        if tick%120==0:await frames(1)
    check("free AI actually fights as the enemy",s.demo.hits[0]>0 and s.demo.hits[1]>0 and s.fighters[1].character_index==4,{"hits":s.demo.hits.duplicate(),"events":events})
    check("enemy has no hero-only resources",s.sim.fighters[1].service.routes==0 and s.sim.fighters[1].service.sample==0 and s.sim.fighters[1].service.nodes.is_empty())
    await shot("enemy-demo")
    s.return_to_title();s.start_run()
    check("existing Street Run retains hero opponents",s.run_active and s.character_choices[1]<4)
    s.return_to_title()
    check("leaving run restores enemy opponent",s.character_choices[1]==4 and s.fighters[1].character_index==4)
    s.save_options()
    var loaded:Dictionary=prefs.read_options(options_path)
    check("enemy persists after run without changing player save",loaded.rival_character==4 and loaded.player_character==0)
    s.start_match(false);s.reduced_effects=false
    s.round_theatre.age=1.4;s.round_theatre.sample_intro();s.hud.queue_redraw();await frames()
    check("enemy supports round entry portrait",s.fighters[1].visible and s.camera.transform.is_finite())
    s.round_theatre.clear();s.sim.phase="fight";s.sim.wins[1]=1;s.sim.fighters[0].health=0;s._combat_step()
    check("enemy win starts deciding KO",s.city_breaker.active())
    s.city_breaker.playback_elapsed=5.2;s.city_breaker.advance(0.0,false)
    check("enemy winner exit has valid pose and fallback score",s.fighters[1].visible and s.camera.transform.is_finite() and s.city_breaker.score_player.stream==s.city_breaker.outro_scores[2])
    s.return_to_title()
    # A reusable background/cutscene actor must not overwrite the director's placement.
    var actor:Node3D=preload("res://scenes/characters/black_suit_actor.tscn").instantiate()
    actor.position=Vector3(3,0,-4);actor.rotation.y=.7;root.add_child(actor);actor.set_process(false)
    var transform:Transform3D=actor.transform
    var clips:Array=[]
    for posture in ["idle","walk","guard"]:
        actor.posture=posture
        for tick in 12:actor.advance(1.0/30)
        clips.append(actor.visual.motions.clip_name)
        check("reusable actor "+posture+" preserves scene placement",actor.transform==transform and actor.visual.position==Vector3.ZERO and actor.visual.rotation==Vector3.ZERO)
    check("background actor uses walk animation",clips[1]=="Walk_Loop",clips)
    actor.queue_free()
    for swap in 12:
        s.set_character(1,4 if swap%2==0 else 2)
        s.hud.roster_preview.update_preview(true,s.character_choices[1],.2,false)
        await frames(1)
    if native:await RenderingServer.frame_post_draw
    s.return_to_title();s.queue_free();s=null;await frames(8)
    check("model swaps retire render materials",preload("res://scripts/combat/fighter_visual.gd").retired_materials.is_empty())
    var passed:bool=checks.all(func(c:Dictionary)->bool:return c.passed)
    FileAccess.open(OUT+("native-checks.json" if native else "headless-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"engine":Engine.get_version_info().string,"native":native,"scope":"Enemy registry/UI/preferences, existing simulation contact, free AI, shared retargeting, actor lifecycle and run isolation. No new story, weapons, encounters or human balance claim."},"  "))
    DirAccess.remove_absolute(options_path)
    await create_timer(.3).timeout
    call_deferred("quit",0 if passed else 1)
