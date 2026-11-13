extends SceneTree
## Replay exact commands at 60 simulation ticks, independent of demo/view clocks.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
var actors:Array=[]
func _initialize() -> void:call_deferred("run")
func fresh(pair:Array) -> RefCounted:
    var sim:=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
    sim.character_choices.assign(pair);sim.reset_round();sim.phase="fight"
    sim.fighters[0].x=-.65;sim.fighters[1].x=.65
    for f in sim.fighters:f.meter=100
    return sim
func command(tick:int,side:int) -> Dictionary:
    var cycle:int=tick%180
    var actions:=["light","heavy","special","overdrive","launcher","grab"]
    var kind:int=floori(float(tick)/180.0)%6
    if side==1:return {"guard":cycle<18,"allow_parry":false,"axis":-1.0 if cycle in [120,121] else 0.0}
    var result:Dictionary={"skill_held":cycle<38 and kind==2,"axis":1.0 if cycle in [100,101,102] else 0.0}
    if cycle==0:result.attack=actions[kind]
    if cycle in [28,36,44]:result.rush=true
    if cycle==80:result.jump=true
    if cycle==90:result.attack="light"
    return result
func digest_state(sim:RefCounted) -> String:
    return JSON.stringify({"tick":sim.tick_count,"phase":sim.phase,"hitstop":sim.hitstop,"fighters":sim.fighters,"events":sim.events})
func run() -> void:
    for id in 2:
        var actor:=Visual.new();root.add_child(actor);actor.neon_enabled=true;actors.append(actor)
    var state_hash:=HashingContext.new();state_hash.start(HashingContext.HASH_SHA256)
    var input_hash:=HashingContext.new();input_hash.start(HashingContext.HASH_SHA256)
    var mismatches:=0;var mutation_count:=0;var hits:=0;var steps:=0
    for pair in [[0,1],[2,3]]:
        for side in 2:actors[side].setup(Color.WHITE,pair[side])
        var clean:RefCounted=fresh(pair);var shown:RefCounted=fresh(pair)
        for tick in 900:
            if tick%180==0:
                clean=fresh(pair);shown=fresh(pair)
            var a:Dictionary=command(tick,0);var b:Dictionary=command(tick,1)
            input_hash.update(JSON.stringify([pair,tick,a,b]).to_utf8_buffer())
            clean.tick(a.duplicate(true),b.duplicate(true));shown.tick(a.duplicate(true),b.duplicate(true))
            var snapshot:String=digest_state(shown)
            for side in 2:
                var pose:Dictionary=shown.fighters[side].duplicate(true)
                pose.air_enabled=true;pose.rush_visual=true
                actors[side].present(pose,1.0/60,shown.hitstop>0,false)
            if snapshot!=digest_state(shown):mutation_count+=1
            if digest_state(clean)!=digest_state(shown):mismatches+=1
            state_hash.update(digest_state(shown).to_utf8_buffer())
            for event in shown.events:
                if event.kind=="hit":hits+=1
            steps+=1
    var report:={"steps":steps,"hits":hits,"input_sha256":input_hash.finish().hex_encode(),"sha256":state_hash.finish().hex_encode(),"simulation_mismatches":mismatches,"presentation_mutations":mutation_count,"scope":"Identical explicit commands at 1800 fixed simulation ticks, two hero pairs; reset every 180 ticks to exercise paid moves without synthetic damage. Pure simulation compared with posed simulation each tick. Not a human match, demo-clock or performance test."}
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print(JSON.stringify(report))
    for actor in actors:actor.queue_free()
    await process_frame;await RenderingServer.frame_post_draw;quit(0 if mismatches==0 and mutation_count==0 and hits>0 else 1)
