extends SceneTree
func _initialize() -> void:
    for category in ["shadowed_variable_base_class","shadowed_global_identifier","integer_division"]:
        ProjectSettings.set_setting("debug/gdscript/warnings/"+category,2)
    var results: Array[Dictionary] = []
    for path in ["res://scripts/combat/fight_hud.gd","res://scripts/street_dressing.gd","res://scripts/aircraft_flyby.gd"]:
        var script := GDScript.new()
        script.source_code = FileAccess.get_file_as_string(path)
        script.resource_path = path
        var status := script.reload()
        results.append({"script":path,"compile_error":status,"passed":status==OK})
    var failures := results.filter(func(result: Dictionary)->bool: return not result.passed).size()
    var file := FileAccess.open("res://../docs/evidence/scene-audio-vfx/editor-warnings.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"categories_promoted_to_error":["shadowed_variable_base_class","shadowed_global_identifier","integer_division"],"scripts":results,"failed":failures},"  "))
    file.close()
    print("EDITOR_WARNING_CHECKS ",results.size()-failures,"/",results.size())
    quit(0 if failures==0 else 1)
