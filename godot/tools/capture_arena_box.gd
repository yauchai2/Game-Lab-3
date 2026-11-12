extends SceneTree
## Explicit standing-partner fixture; each launch comes from a paid overdrive final hit.
const OUT="res://../docs/evidence/ricochet-scope/"
var s:Node
var contacts:Array=[]
var clock:=0.0
var shots:Dictionary={}
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/capture-arena-growth.cfg"
    root.add_child(s);s.audio.muted=false;s.audio.music_muted=true;s.reduced_effects=false
    s.combat_event.connect(func(e:Dictionary):
        if e.kind=="arena_bounce":contacts.append({"seconds":clock,"surface":e.surface,"chain":e.chain,"speed":e.speed}))
    for actor in [0,2]:
        s.return_to_title();s.set_character(0,actor);s.set_character(1,actor+1);s.start_match(false)
        s.round_theatre.clear();s.sim.ai_enabled=false;s.sim.phase="fight"
        s.sim.fighters[0].x=0;s.sim.fighters[1].x=1
        s.sim.fighters[0].meter=100
        s.pending={"attack":"overdrive"}
        s.hud.notice="OVERDRIVE / LEGAL HIT / NO E RECOVERY INPUT";s.hud.notice_time=1.5
        for frame in 180:
            await process_frame;clock+=1.0/30
            if not contacts.is_empty():
                var surface:String=contacts[-1].surface
                if not shots.has(surface):
                    shots[surface]=clock
                    await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png(OUT+"bounce-"+surface+".png")
    FileAccess.open(OUT+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"contacts":contacts,"seconds":clock,"shots":shots,"scope":"Standing CPU / x=0 and 1 / paid overdrive final hits / initial meter 100. No damage, launch velocity or boundary fixtures. Both pairs show all four current models; no E recovery so ricochet can be inspected."},"  "))
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.35).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    quit()
