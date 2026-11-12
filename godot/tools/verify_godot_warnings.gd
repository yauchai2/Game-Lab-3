extends SceneTree
## Keep the user's four warning categories fatal in the affected runtime scripts.
const SCRIPTS=[
    "res://scripts/combat/combat_motions.gd",
    "res://scripts/combat/fighter_visual.gd",
    "res://scripts/combat/fight_session.gd",
    "res://scripts/combat/fight_simulation.gd",
    "res://scripts/combat/cinematic/round_theatre.gd",
    "res://scripts/combat/cinematic/city_breaker.gd",
    "res://scripts/combat/ability_draw/dealer_rig.gd",
    "res://scripts/combat/cinematic/ability_draw.gd"]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var checks:Array=[]
    # Godot caches warning levels before loading the main script. The Python
    # runner supplies override.cfg at process startup; changing settings here
    # would silently miss the warnings we are meant to detect.
    for category in ["static_called_on_instance","incompatible_ternary","shadowed_variable_base_class","integer_division"]:
        if ProjectSettings.get_setting("debug/gdscript/warnings/"+category)!=2:
            push_error("Run tools/verify_godot_warnings.py so warning levels are set at startup")
            quit(2)
            return
    for path in SCRIPTS:
        var script=GDScript.new()
        script.source_code=FileAccess.get_file_as_string(path)
        var code:Error=script.reload()
        checks.append({"name":path,"passed":code==OK,"reload_code":code})
        print("STRICT_WARNING ",path," ",code==OK)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var args:=OS.get_cmdline_user_args()
    var output:String=args[0] if not args.is_empty() else "res://../docs/evidence/godot-warnings/strict.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
    FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failed":failed,"passed":checks.size()-failed,"scope":"Four screenshot warning categories treated as compile errors; no warning suppression."},"  "))
    quit(1 if failed else 0)
