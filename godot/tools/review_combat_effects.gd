extends SceneTree
const DIR="res://../docs/evidence/ui-replica/effects"
var scene:Node
var receipts:Array=[]
func _initialize() -> void:call_deferred("run")
func step() -> void:
    scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func shot(name:String) -> void:
    scene.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(DIR+"/"+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true;scene.backdrop.freeze_for_capture();root.size=Vector2i(960,540)
    for index in 4:
        scene.return_to_title();scene.set_character(0,index);scene.set_character(1,(index+1)%4)
        for move in scene.Simulation.MOVES:
            if index>0 and move not in ["special","overdrive"]:continue
            scene.start_match(true);scene.sim.ai_enabled=false;scene.sim.phase="fight"
            scene.sim.fighters[0].x=-.4;scene.sim.fighters[1].x=.4;scene.sim.fighters[0].meter=100
            if move.begins_with("air_") or move=="meteor":scene.sim.fighters[0].y=.9;scene.sim.fighters[1].y=.9
            if move=="heavy":scene.sim.arcade_enabled=false # Legacy heavy; arcade K intentionally maps to launcher.
            scene.pending["attack"]=move
            var saved:Dictionary={};var true_hit:=false;var max_effects:=0
            for frame in 260:
                step();max_effects=maxi(max_effects,scene.effects.size())
                if not saved.has("swing") and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="swing" and e.age>=0):saved.swing=frame;await shot("%d-%s-swing"%[index,move])
                if not saved.has("contact") and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("move","")==move):saved.contact=frame;true_hit=true;await shot("%d-%s-contact"%[index,move])
                if not saved.has("release") and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="release" and e.get("move","")==move):saved.release=frame;await shot("%d-%s-release"%[index,move])
                if saved.has("release") and frame>saved.release+15:break
            receipts.append({"character":index,"move":move,"true_hit":true_hit,"stages":saved,"max_effects":max_effects})
    for kind in ["block","parry","guard_break","dust","speed","slam_crater","chase_path"]:
        scene.start_match(true);scene.sim.phase="fight";scene.effects.clear()
        # Isolated render diagnostic, explicitly not a gameplay event for defense samples.
        scene._spawn_vfx(kind,Vector2(0,1),.3,{"age":.08,"color":Color("4acfe0"),"points":[Vector2(-1,0),Vector2(-1,1),Vector2(1,1),Vector2(1,0)]})
        await shot("defense-"+kind)
    FileAccess.open("res://../docs/evidence/ui-replica/effect-review.json",FileAccess.WRITE).store_string(JSON.stringify({"attacks":receipts,"defense_capture_scope":"Isolated render diagnostics; not claimed as actual parry/block gameplay events.","attack_scope":"Actual legal commands and contact/release events for all 13 moves and four signature pairs; fixed wall steps, not human input."},"  "))
    scene.queue_free();for i in 8:await process_frame
    quit()
