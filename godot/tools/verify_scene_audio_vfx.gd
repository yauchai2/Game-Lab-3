extends SceneTree
const Sim = preload("res://scripts/combat/fight_simulation.gd")
var checks: Array[Dictionary] = []
func _initialize() -> void:
    call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value: push_error("SCENE/AUDIO/VFX FAIL: "+label)
func setup() -> RefCounted:
    var sim := Sim.new()
    sim.phase = "fight"
    sim.ai_enabled = false
    sim.fighters[0].x = -0.65
    sim.fighters[1].x = 0.65
    return sim
func run() -> void:
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    await process_frame
    var bg: Node3D = scene.backdrop
    check("street keeps source proportions without X stretching",bg.street.scale.is_equal_approx(Vector3.ONE))
    var panorama: PanoramaSkyMaterial = bg.environment.sky.sky_material
    check("accepted image panorama restored",panorama!=null and panorama.panorama.resource_path=="res://assets/SKY_BLUE_A01.png")
    check("image panorama rotation matches walk scene",is_equal_approx(bg.environment.sky_rotation.y,PI*0.5))
    check("red car wrapper restored at source location",bg.street.has_node("ParkedCar") and bg.street.get_node("ParkedCar").position.is_equal_approx(Vector3(-2.9,0,-17)))
    check("truck wrapper restored at source location",bg.street.has_node("ParkedTruck") and bg.street.get_node("ParkedTruck").position.is_equal_approx(Vector3(2.6,0,-36)))
    check("vehicle wrapper scales remain uniform",bg.street.get_node("ParkedCar/Visual").scale.is_equal_approx(Vector3.ONE*bg.street.get_node("ParkedCar/Visual").scale.x))
    check("original van and six props retained",bg.street.get_node("Props").get_child_count()>=6)
    check("source sample details restored",bg.source_detail_count>150 and bg.street.has_node("SourceStyleDetails"))
    check("source street dressing density retained",bg.street.find_children("BatchedGeometry","Node3D",true,false).size()==1)
    check("low-resolution environment textures restored",bg.environment_textures.applied.size()>=10)
    var road: MeshInstance3D = bg.street.get_node("StreetGeometry/MainRoad")
    check("road toon shader retains world UVs and texture",road.get_active_material(0).get_shader_parameter("use_world_uv") and road.get_active_material(0).get_shader_parameter("world_texture")!=null)
    check("only entrance paint extended for fight width",bg.get_node("CrossingExtension").multimesh.instance_count==10)
    bg.elapsed = 0
    bg.present(0.1,false)
    var first: Vector3 = bg.plane.global_position
    bg.present(0.1,false)
    var velocity: Vector3 = bg.plane.global_position-first
    var nose: Vector3 = (bg.plane.get_node("Aircraft_Nose").global_position-bg.plane.global_position).normalized()
    check("aircraft moves nose-first rather than backwards",velocity.normalized().dot(nose)>0.999)
    check("flight height clears the street rooftops",bg.plane.global_position.y-6.0>22.0)
    check("scene outline off by default",not scene.ink_pass.visible)
    check("character outlines remain independent",scene.fighters[0].materials[0].next_pass!=null)
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_O
    scene._unhandled_key_input(key)
    check("O toggles scene edges",scene.ink_pass.visible)
    scene._unhandled_key_input(key)
    check("O restores the clear scene view",not scene.ink_pass.visible)
    var audio: Node = scene.audio
    check("open music loads with loop enabled",audio.music.stream is AudioStreamOggVorbis and audio.music.stream.loop and audio.music.stream.get_length()>60)
    check("downloaded physical hit and parry clips are loaded",audio.sounds.hit[0] is AudioStreamOggVorbis and audio.sounds.parry[0] is AudioStreamOggVorbis)
    audio.muted = true
    audio._process(0.02)
    check("master mute pauses music",audio.music.stream_paused)
    audio.muted = false
    audio.music_muted = true
    audio._process(0.02)
    check("music can be disabled independently",audio.music.stream_paused and not audio.muted)
    audio.music_muted = false
    audio.context = "pause"
    audio._process(0.02)
    check("pause suspends music without rewinding",audio.music.stream_paused)
    audio.context = "play"
    audio._process(0.02)
    check("resume enables music",not audio.music.stream_paused)
    var sim := setup()
    sim.fighters[0].state = "attack"
    sim.fighters[0].move = "jab"
    sim.fighters[0].frame = 4
    sim.tick({}, {"guard":true})
    check("timed guard parries an incoming jab",sim.fighters[1].health==100 and sim.events.any(func(event: Dictionary)->bool: return event.kind=="parry"))
    check("parry opens a counter window and grants energy",sim.fighters[0].state=="stun" and sim.fighters[1].meter==12 and sim.fighters[1].parry_cd>0)
    sim = setup()
    for i in 10: sim.tick({}, {"guard":true})
    sim.tick({"attack":"light"},{"guard":true})
    for i in 6: sim.tick({}, {"guard":true})
    check("holding guard beyond the window is a regular block",sim.fighters[1].health==100 and sim.fighters[1].meter==0 and sim.fighters[1].guard<100)
    sim = setup()
    sim.fighters[1].parry_cd = 40
    sim.fighters[0].state = "attack"
    sim.fighters[0].move = "jab"
    sim.fighters[0].frame = 4
    sim.tick({}, {"guard":true})
    check("parry cooldown prevents repeated perfect guards",sim.fighters[1].meter==0 and sim.events.any(func(event: Dictionary)->bool: return event.kind=="block"))
    sim = setup()
    sim.fighters[0].state = "attack"
    sim.fighters[0].move = "jab"
    sim.fighters[0].frame = 4
    sim.fighters[1].state = "attack"
    sim.fighters[1].move = "heavy"
    sim.fighters[1].frame = 1
    sim.tick()
    check("interrupting startup awards a counter hit",sim.fighters[1].health==92 and sim.events.any(func(event: Dictionary)->bool: return event.get("counter",false)))
    scene.effects.clear()
    scene._handle_event({"kind":"swing","target":0,"move":"special"})
    check("energy attacks schedule charge and travelling wave effects",scene.effects.any(func(effect: Dictionary)->bool: return effect.kind=="charge") and scene.effects.any(func(effect: Dictionary)->bool: return effect.kind=="wave"))
    scene._handle_event({"kind":"parry","target":0,"attacker":1})
    check("parry has its own visual and notice",scene.hud.notice=="PERFECT GUARD" and scene.effects.any(func(effect: Dictionary)->bool: return effect.kind=="parry"))
    for i in 100: scene._spawn_vfx("hit",Vector2.ZERO,0.2)
    check("effect count is bounded",scene.effects.size()==64)
    scene.effects.clear()
    scene.reduced_effects = true
    scene._spawn_vfx("trail",Vector2.ZERO,0.2)
    scene._spawn_vfx("speed",Vector2.ZERO,0.2)
    check("reduced effects omits trails and speed shards",scene.effects.is_empty())
    # Let the mixer consume the deliberately triggered last-frame test sounds before teardown.
    await create_timer(0.10).timeout
    scene.queue_free()
    await process_frame
    await create_timer(0.10).timeout
    var failed := checks.filter(func(result: Dictionary)->bool: return not result.passed).size()
    var file := FileAccess.open("res://../docs/evidence/scene-audio-vfx/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"headless source inventory, proportions, flight geometry, audio resources/controls and combat/VFX regressions; no human listening or hardware FPS claim"},"  "))
    file.close()
    print("SCENE_AUDIO_VFX_CHECKS ",checks.size()-failed,"/",checks.size())
    call_deferred("quit",0 if failed==0 else 1)
