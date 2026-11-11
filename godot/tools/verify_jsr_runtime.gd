extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Roster=preload("res://scripts/combat/fighter_roster.gd")
const Tokens=preload("res://scripts/combat/ui/ui_theme.gd")
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("JSR FAIL: "+label)
func fresh(index:int) -> RefCounted:
    var s=Sim.new();s.arcade_enabled=true;s.ai_enabled=false;s.character_choices=[index,0];s.reset_round();s.phase="fight";s.fighters[0].x=-.4;s.fighters[1].x=.4;s.fighters[0].meter=100
    return s
func frames() -> void:
    await process_frame;await process_frame;await process_frame
func control(hud:Node,key:String) -> Control:
    for c in hud.menu_stack.find_children("*","Control",true,false):
        if c.get_meta("ui_key","")==key:return c
    return null
func run() -> void:
    for index in 4:
        var s=fresh(index)
        check("profile %d survives round reset"%index,s.fighters[0].character==index)
        for move in Sim.MOVES:
            s=fresh(index)
            if move.begins_with("air_") or move=="meteor":s.fighters[0].y=.9;s.fighters[1].y=.9
            s.tick({"attack":move})
            var started:bool=s.fighters[0].move==move
            var contacts:int=0
            for tick in 140:
                s.tick()
                for e in s.events:
                    if e.kind=="hit" and e.get("move","")==move:contacts+=1
            check("profile %d %s is legal and single-contact"%[index,move],started and contacts==1)
        s=fresh(index);s.tick({"axis":1.0})
        check("profile %d movement uses its true speed"%index,is_equal_approx(s.fighters[0].vx,8.0*Sim.Profiles.profile(index).speed))
        s=fresh(index);s.tick({"attack":"special"})
        for tick in 100:s.tick()
        check("profile %d special has its actual damage"%index,s.fighters[1].health==100-Sim.Profiles.move(Sim.MOVES.special,index,"special").damage)
    check("goggles height is only slightly smaller",Roster.entry(3).scale/Roster.entry(0).scale>.93 and Roster.entry(3).scale/Roster.entry(0).scale<.96)
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    var hud=scene.hud
    for locale in ["zh","en"]:
        scene.set_language(locale)
        for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
            root.size=dimensions
            scene.return_to_title();hud.close_page();await frames()
            check("title %s %s all actions reachable"%[locale,dimensions],control(hud,"fight")!=null and control(hud,"demo")!=null and control(hud,"roster")!=null and hud.menu.get_global_rect().end.y<=root.get_visible_rect().size.y+1)
            hud.open_page("roster");await frames()
            check("roster fight action remains inside its scroll viewport",control(hud,"fight").get_global_rect().end.y<=hud.menu_scroll.get_global_rect().end.y+1)
            var selectors:Array=hud.menu_stack.find_children("*","OptionButton",true,false)
            check("roster %s %s native selectors"%[locale,dimensions],selectors.size()==2 and selectors[0].item_count==4 and selectors[0].get_global_rect().end.x<root.get_visible_rect().size.x)
    root.size=Vector2i(1280,720);scene.return_to_title();hud.open_page("roster");await frames()
    var selector:OptionButton=control(hud,"player_character");selector.select(3);selector.item_selected.emit(3);await frames()
    check("roster callback updates visuals and gameplay profile",scene.fighters[0].character_index==3 and scene.sim.character_choices[0]==3)
    scene.start_match(true);check("profile retained in real practice",scene.sim.fighters[0].character==3)
    check("pixel pass defaults on and UI is a later layer",scene.retro_pixels and scene.pixel_pass.get_parent().layer<scene.hud.get_parent().layer)
    scene._present(0);scene._grade_world();scene.retro_pixels=false;scene._grade_world();check("pixel option switches immediately",not scene.pixel_pass.visible)
    scene.retro_pixels=true;scene._grade_world()
    scene.audio.context="title";scene.audio._process(.01);check("title selects Berlin",scene.audio.current_track==scene.audio.BERLIN)
    scene.audio.context="play";scene.audio._process(.01);check("play selects Groove District",scene.audio.current_track==scene.audio.GROOVE and scene.audio.music.stream.loop)
    var stream:AudioStream=scene.audio.music.stream
    scene.audio.context="pause";scene.audio._process(.01);check("pause retains current song",scene.audio.music.stream==stream)
    scene.audio.context="play";scene.audio._process(.01);check("resume retains current song",scene.audio.music.stream==stream)
    var renderer=scene.hud.vfx_renderer.sprite_fx
    for move in Sim.MOVES:
        check("sprite mapped for "+move,renderer.sprite_for({"kind":"swing","move":move,"character":0})!=null)
    for index in 4:
        for move in ["special","overdrive"]:
            var sprite:Texture2D=renderer.sprite_for({"kind":"release","move":move,"character":index})
            check("signature art %d %s"%[index,move],sprite!=null and sprite.atlas.resource_path.ends_with("fighter_signatures.png"))
    scene.return_to_title();scene.set_character(0,2);scene.set_character(1,3);scene.start_demo()
    var hits:=0
    for tick in 3600:
        scene._physics_process(1.0/60);scene._process(1.0/60)
        for e in scene.sim.events:
            if e.kind=="hit":hits+=1
    check("new profiles sustain live endless combat",scene.sim.phase=="fight" and scene.demo.hits[0]>0 and scene.demo.hits[1]>0 and scene.sim.fighters[0].character==2 and scene.sim.fighters[1].character==3)
    scene.return_to_title();check("title clears generated effects",scene.effects.is_empty())
    scene.queue_free();await frames();await frames()
    var passed:int=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/jsr-runtime/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks,"scope":"Native UI ownership, profile rules, real damage, music context, sprites and fixed-step AI. Not human/target GPU validation."},"  "))
    print("JSR_RUNTIME ",passed,"/",checks.size());quit(0 if passed==checks.size() else 1)
