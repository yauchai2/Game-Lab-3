extends SceneTree
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const OUT="res://../docs/evidence/grounded-death/"
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("GROUNDED_DEATH ",label," ",ok)
    if not ok:push_error(label)
func frames(count:=2) -> void:
    for i in count:await process_frame
    await RenderingServer.frame_post_draw
func rendered_floor(v:Node) -> float:
    var low:=INF
    for mesh in v.model.find_children("*","MeshInstance3D",true,false):
        if mesh.skin==null:continue
        # Independent renderer bake validates the CPU grounding calculation.
        var posed:Mesh=mesh.bake_mesh_from_current_skeleton_pose()
        for surface in posed.get_surface_count():
            for vertex in posed.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
                low=minf(low,mesh.to_global(vertex).y)
    return low
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for character in 5:
        var v=Visual.new();root.add_child(v);v.setup(Color.CYAN,character)
        await frames()
        var sim=Sim.new();var f:Dictionary=sim.fighters[0].duplicate(true)
        for face in [-1,1]:
            for reduced in [false,true]:
                f.character=character;f.face=face;f.health=100;f.y=0;f.state="idle"
                f["air_enabled"]=true;f["rush_visual"]=true
                v.present(f,.1,false,reduced)
                f.health=0;f.state="attack";f.move="special";f.frame=0
                f.air.phase="apex";f.ricochet.ticks=20;f.ricochet.spin=PI
                var snapshot:Dictionary=f.duplicate(true)
                v.present(f,.1,false,reduced);v.present(f,3.0,false,reduced)
                await frames()
                var low:float=rendered_floor(v)
                var label:="%d/%d/%s"%[character,face,str(reduced)]
                check("deformed skin rests on floor "+label,low>=.005 and low<=.035,low)
                check("death owns attack/air/spin pose "+label,v.motions.clip_name=="Death01" and v.motions.air_pose_name=="" and v.model.rotation.is_zero_approx())
                var before:float=v.motions.clip_elapsed;var at:Vector3=v.model.position
                f.state="idle";v.present(f,.2,false,reduced)
                check("idle state cannot restart or stand up corpse "+label,v.motions.clip_name=="Death01" and v.motions.clip_elapsed>before and v.model.position.is_equal_approx(at) and v.death_ground_cached)
                f.state="attack"
                check("presentation leaves simulation snapshot intact "+label,f==snapshot)
                f.health=100;f.y=1.2;f.state="idle"
                v.present(f,.1,false,reduced)
                check("living airborne pose is not grounded "+label,is_equal_approx(v.position.y,1.2) and not v.death_ground_cached)
        v.queue_free();v=null;await frames()
    var s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path="";root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.start_squad();s.sim.phase="fight";s.sim.ai_enabled=false
    for id in 2:
        var f:Dictionary=s.sim.squad_members[id];f.health=0;f.y=0;f.state="stun";f.stun=999;f.x=-1.2+id*2.4
    for tick in 200:
        s._physics_process(1.0/60);s._process(1.0/60)
        if tick%20==0:await process_frame
    await frames()
    check("squad continues after two corpses",s.screen=="play" and s.sim.remaining_enemies()==2)
    for id in 2:
        var low:float=rendered_floor(s.squad_visuals[id])
        check("live squad corpse rests on street %d"%id,low>=.005 and low<=.035,low)
    root.get_texture().get_image().save_png(OUT+"after-squad.png")
    for f in s.sim.squad_members:f.health=0;f.y=2.0
    s.sim._finish_round();s._combat_step()
    # Explicit result fixture isolates frozen non-focus enemies from live physics.
    s.screen="result";s.result_clock=2.0;s._present(.1);s._present(3.0)
    await frames()
    check("all result corpses settle, including non-focus enemies",s.squad_visuals.all(func(v:Node)->bool:return v.position.y==0))
    s.return_to_title();s.queue_free();s=null;await frames(8)
    var failed:int=checks.filter(func(row:Dictionary)->bool:return not row.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Actual renderer-deformed mesh contact on five rigs, F2, both facings, real squad lifecycle and explicit frozen-result fixture. Linux Compatibility, not target Mac validation."},"  "))
    quit(1 if failed else 0)
