extends SceneTree
## Native Compatibility stress for render-resource replacement; inspect stderr too.
const OUT="res://../docs/evidence/readable-ui/"
var checks:Array=[]
var inspected:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
    for cycle in 3:
        var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
        scene.preferences_path="";root.add_child(scene);scene.audio.muted=true
        scene.set_character(0,[0,1,3][cycle])
        scene.hud.open_page("roster")
        for choice in 8:
            scene.set_character(0,(choice+[0,1,3][cycle])%4)
            scene.hud.roster_preview.update_preview(true,(choice+[0,1,3][cycle])%4,.1,false)
            await process_frame
            await RenderingServer.frame_post_draw
        scene.hud.close_page();scene.start_match(true)
        scene.backdrop._style_surfaces(scene.backdrop.street)
        for i in 4:await process_frame
        await RenderingServer.frame_post_draw
        var missing:=0
        for node in scene.find_children("*","MeshInstance3D",true,false):
            if node.mesh:
                for surface in node.mesh.get_surface_count():
                    inspected+=1
                    if node.get_active_material(surface)==null:missing+=1
        for node in scene.find_children("*","MultiMeshInstance3D",true,false):
            if node.multimesh and node.multimesh.mesh:
                for surface in node.multimesh.mesh.get_surface_count():
                    inspected+=1
                    if node.material_override==null and node.multimesh.mesh.surface_get_material(surface)==null:missing+=1
        checks.append({"cycle":cycle,"name":"live materials cycle "+str(cycle),"passed":missing==0,"missing_active_materials":missing})
        var pending:int=preload("res://scripts/combat/fighter_visual.gd").retired_materials.size()
        checks.append({"name":"retirement queue drained cycle "+str(cycle),"passed":pending==0,"pending":pending})
        print("MATERIAL_LIFECYCLE ",cycle," missing=",missing," pending=",pending)
        scene.queue_free()
        for i in 8:await process_frame
    FileAccess.open(OUT+"material-lifecycle.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"scope":"Three native scene lifecycles,24 roster model changes,restyle and frame renders; Linux driver only. Renderer errors must also be checked in the captured log.","inspected_surfaces":inspected,"checks":checks},"  "))
    var passed:=checks.all(func(c:Dictionary)->bool:return c.passed)
    quit(0 if passed else 1)
