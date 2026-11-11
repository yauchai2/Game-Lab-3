extends SceneTree
const OUT="res://../docs/evidence/ability-equip/"
const Rewards=preload("res://scripts/combat/ability_draw/rewards.gd")
var s:Node
var checks:Array=[]
var samples:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("EQUIP ",label," ",ok)
    if not ok:push_error(label)
func step(n:int) -> void:
    for i in n:s._process(1.0/60)
func fixture(id:int=0) -> void:
    s.return_to_title();s.character_choices[0]=id;s.start_match(false);s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.advance_round()
    var d=s.ability_draw;d.result=Rewards.item("speed");d.result.boundary=s.ability_draw_boundary();d.state="result";d.age=.5;d.input_armed=true
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/equip-verify.cfg";root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await process_frame;await process_frame
    for selection in 5:
        fixture(selection);await process_frame
        var d=s.ability_draw;d.confirm()
        check("selected actor %d enters equip before gameplay claim"%selection,d.state=="equip" and s.sim.round_number==2 and s.draw_rewards.claimed.is_empty())
        check("selected actor %d uses original current rig"%selection,d.equip_view.hero.character_index==selection and d.equip_view.hero.skeleton.get_bone_count()>=50)
        for t in [.20,.60,1.70,2.44,3.30,3.90]:
            d.age=t;d.sample();s.hud.queue_redraw()
            var head:Vector3=d.equip_view.solver.point("Head")
            var head_uv:Vector2=s.camera.unproject_position(head)/root.get_visible_rect().size
            var hidden:bool=s.camera.is_position_behind(head) or not Rect2(0,0,1,1).has_point(head_uv)
            samples.append({"character":selection,"time":t,"head_uv":str(head_uv),"contact_error_m":d.equip_view.contact_error})
            check("actor %d t%.2f keeps head outside frame"%[selection,t],hidden)
            check("actor %d t%.2f wrist target is reachable"%[selection,t],d.equip_view.contact_error<.16)
            await process_frame;await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(OUT+"actor%d-%.2f.png"%[selection,t])
        s.pause_game();var age:float=d.age;step(30)
        check("pause freezes equip and cue %d"%selection,d.age==age and d.equip_cue.stream_paused)
        s.resume_game();d.age=.1;await process_frame
        var key:=InputEventKey.new();key.keycode=KEY_ENTER;d.handle_key(key)
        check("repeated Enter does not skip equip %d"%selection,d.state=="equip")
        d.age=3.9;step(15)
        check("playback claims once and starts round three %d"%selection,not d.active() and s.sim.round_number==3 and s.sim.fighters[0].get("draw_core","")=="speed")
        s._process(0)
        check("physical core follows live selected actor %d"%selection,s.fighters[0].core_module!=null and s.fighters[0].core_module.visible)
        var mounted:Vector3=s.fighters[0].core_module.global_position
        s.sim.fighters[0].x+=1.0;s._process(0)
        check("installed module follows live movement %d"%selection,s.fighters[0].core_module.global_position.distance_to(mounted)>.9)
        s.sim.reset_round();s._process(0)
        check("new round removes visible module %d"%selection,not s.fighters[0].core_module.visible)
    for item in Rewards.ITEMS:
        fixture();s.ability_draw.result=item.duplicate();s.ability_draw.result.boundary=s.ability_draw_boundary();await process_frame;s.ability_draw.confirm()
        check("equip preserves selected core %s"%item.id,s.ability_draw.equip_view.module.core_id==item.id and s.ability_draw.equip_view.module.color==item.color)
        s.ability_draw.skip()
    var profile=preload("res://scripts/combat/ability_draw/stage_profile.gd").new()
    profile.anchor=Vector3(2,.25,4);profile.heading_degrees=32;profile.collision_mask=1<<18
    s.ability_draw_stage=profile;fixture();await process_frame;s.ability_draw.confirm();s.ability_draw.age=2.4;s.ability_draw.sample()
    check("equip follows alternate stage origin and heading",s.ability_draw.equip_view.global_position.distance_to(profile.anchor)<.01 and s.ability_draw.equip_view.contact_error<.16)
    s.ability_draw_stage=null
    fixture();s.reduced_effects=true;await process_frame;s.ability_draw.confirm();step(72)
    check("F2 shortened equip claims the same core",not s.ability_draw.active() and s.sim.fighters[0].draw_core=="speed")
    fixture();await process_frame;s.ability_draw.confirm();s.ability_draw.age=.5;s.ability_draw.skip()
    check("skip equip claims once without reroll",not s.ability_draw.active() and s.sim.fighters[0].draw_core=="speed")
    fixture();await process_frame;s.ability_draw.confirm();s.return_to_title()
    check("cancel restores visibility camera and stops score",not s.ability_draw.active() and not s.ability_draw.equip_view.visible and not s.ability_draw.equip_cue.playing and s.fighters.all(func(f):return f.visible))
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop();await create_timer(.15).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"samples":samples,"passed":checks.size()-failed,"failed":failed},"  "))
    print("EQUIP_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
