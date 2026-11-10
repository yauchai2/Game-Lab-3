extends SceneTree
var scene: Node
var samples: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func snapshot(cycles: int) -> Dictionary:
    return {"cycles":cycles,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC)}
func cycle(index: int) -> void:
    scene.hud.open_page("settings")
    scene.set_language("zh" if index%2==0 else "en")
    scene.hud.open_page("help")
    scene.hud.close_page()
    await process_frame
    await process_frame
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    for i in 16:await cycle(i)
    var baseline:=snapshot(0)
    samples.append(baseline)
    for i in 512:
        await cycle(i)
        if (i+1)%64==0:samples.append(snapshot(i+1))
    var last:=snapshot(512)
    var checks:=[{"name":"menu rebuilds retain a stable live-node count after warmup","passed":last.nodes==baseline.nodes},{"name":"512 page and language cycles leave no extra orphan nodes","passed":last.orphans==baseline.orphans},{"name":"steady-state object growth stays within four transient resources","passed":last.objects-baseline.objects<=4}]
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/ui-lifecycle.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"samples":samples,"passed":checks.size()-failed,"failed":failed,"method":"headless Control/Callable lifecycle after 16 warmup cycles; native renderer memory is observed separately"},"  "))
    print("UI_LIFECYCLE ",checks.size()-failed,"/",checks.size()," objects ",baseline.objects," -> ",last.objects," nodes ",baseline.nodes," -> ",last.nodes)
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    quit(0 if failed==0 else 1)
