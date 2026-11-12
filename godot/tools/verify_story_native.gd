extends SceneTree
var s:Node
var checks:Array=[]
var chain_events:Array=[]
const OUT="res://../docs/evidence/story-waves/"
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("STORY_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func key(code:Key,down:bool) -> void:
    var e=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down
    Input.parse_input_event(e);await frames(2)
func step(n:=1) -> void:
    for i in n:s._physics_process(1.0/60);s._process(1.0/60)
func shot(name:String) -> void:
    s.hud.queue_redraw();await frames()
    root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.combat_event.connect(func(e:Dictionary)->void:
        if e.kind=="story_chain_hit":chain_events.append(e.duplicate()))
    s.set_character(1,2);s.hud.open_page("roster");await frames()
    await shot("entry")
    var entry:Control=s.hud.art_buttons.story_waves
    for down in [true,false]:
        var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down
        e.position=root.get_screen_transform()*entry.get_global_rect().get_center();e.global_position=e.position
        Input.parse_input_event(e);await frames(2)
    check("real Fighters story button starts an isolated finite wave",s.sim.story_enabled and s.sim.wave_index==0 and s.squad_visuals.size()==3 and not s.run_active and s.demo==null)
    var xp:Dictionary=s.growth.records.duplicate(true)
    s.sim.ai_enabled=false;s.sim.squad_members[0].x=.9
    await key(KEY_J,true);step(12);await key(KEY_J,false)
    check("native J causes real damage in story",s.sim.squad_members[0].health<35)
    step(80);await shot("wave-one")
    s.sim.retry_story_wave();s._sync_story_visuals();s.sim.ai_enabled=false;s.sim.arrival_left=0
    for id in 3:s.sim.squad_members[id].x=1.3+id*1.5
    await key(KEY_S,true);await key(KEY_K,true);await key(KEY_K,false);await key(KEY_S,false)
    for tick in 180:
        step()
        if not chain_events.is_empty():break
    check("native down-K creates actual chain damage and feedback",not chain_events.is_empty() and s.effects.any(func(e:Dictionary)->bool:return e.kind=="hit"))
    await shot("chain-hit")
    for f in s.sim.squad_members:f.health=0
    s.sim._finish_round();s.sim.fighters[0].health=77;s.sim.fighters[0].meter=41
    await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false)
    var clock:int=s.sim.break_left;step(20)
    check("pause freezes the inter-wave timer",s.screen=="pause" and s.sim.break_left==clock)
    await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false)
    await key(KEY_ENTER,true);await key(KEY_ENTER,false)
    check("native Enter advances one wave and carries resources",s.sim.wave_index==1 and s.squad_visuals.size()==4 and s.sim.fighters[0].health==77 and s.sim.fighters[0].meter==41)
    check("rushers carry distinct derived accessories",s.squad_visuals[1].model.find_child("StoryRole",true,false)!=null)
    s.sim.fighters[0].health=0;s.sim._finish_round();s._combat_step();s._process(2)
    check("story KO uses result without giant two-person cinematic",s.screen=="result" and not s.city_breaker.active())
    await key(KEY_R,true);await key(KEY_R,false)
    check("native R retries current checkpoint without duplicating visuals",s.screen=="play" and s.sim.wave_index==1 and s.squad_visuals.size()==4 and s.sim.fighters[0].health>=60)
    s.sim._load_wave(2,100,60);s._sync_story_visuals();s.sim.ai_enabled=false
    step(80)
    for i in 100:s._process(1.0/60)
    await frames()
    var guards:int=0
    for id in s.squad_visuals.size():
        if s.sim.squad_members[id].story_role=="guard" and s.squad_visuals[id].model.find_child("StoryRole",true,false)!=null:guards+=1
    check("third wave contains six actual rigs and two shields",s.squad_visuals.size()==6 and guards==2)
    var hero:Dictionary=s.sim.fighters[0]
    var foot:Vector2=s.camera.unproject_position(Vector3(hero.x,hero.y,s.FIGHT_Z))
    var head:Vector2=s.camera.unproject_position(Vector3(hero.x,hero.y+2.1,s.FIGHT_Z))
    var pixels:float=absf(foot.y-head.y)*360.0/root.get_visible_rect().size.y
    check("crowd framing keeps player above 32 internal pixels",pixels>=32,pixels)
    var visible:=true;var area:=Rect2(root.get_visible_rect().size*Vector2(.04,.18),root.get_visible_rect().size*Vector2(.92,.70))
    for f in s.sim.squad_members:
        for height in [.05,2.1]:
            var point:=Vector3(f.x,f.y+height,s.FIGHT_Z)
            if s.camera.is_position_behind(point) or not area.has_point(s.camera.unproject_position(point)):visible=false
    check("six real enemies stay inside the readable camera area",visible)
    await shot("wave-three")
    s.reduced_effects=true;step(3);await shot("reduced")
    check("F2 preserves six-member story physics",s.sim.story_enabled and s.sim.squad_members.size()==6)
    for f in s.sim.squad_members:f.health=0
    s.sim._finish_round();s._combat_step();s._process(2)
    check("last wave reaches its actual completion result",s.screen=="result" and s.sim.story_state=="complete")
    check("M1 gives no accidental XP or permanent core",s.growth.records==xp and s.draw_rewards.claimed.is_empty() and s.draw_rewards.results.is_empty())
    await shot("complete")
    s.return_to_title();await frames(8)
    check("exit removes wave simulation and extras and restores P2",not s.sim.story_enabled and s.squad_visuals.is_empty() and s.character_choices[1]==2)
    s.start_match(false);check("ordinary FIGHT remains two-person",not s.sim.story_enabled and not s.sim.squad_enabled)
    s.return_to_title();s.start_squad();check("old squad remains independent",s.sim.squad_enabled and not s.sim.story_enabled)
    s.return_to_title();s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.1).timeout;s.queue_free();s=null;await frames(8);await create_timer(.3).timeout
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Linux 4.7.2 Compatibility; injected real UI/J/Esc/Enter/R and explicit boundary fixtures, not human playtest or target GPU validation."},"  "))
    quit(1 if failed else 0)
