extends Node3D
const Simulation = preload("res://scripts/combat/fight_simulation.gd")
const FighterVisual = preload("res://scripts/combat/fighter_visual.gd")
const FightHUD = preload("res://scripts/combat/fight_hud.gd")
const FightAudio = preload("res://scripts/combat/fight_audio.gd")
var sim := Simulation.new()
var fighters: Array[Node3D] = []
var camera: Camera3D
var hud: Control
var audio: Node
var screen := "title"
var pending: Dictionary = {}
var effects: Array[Dictionary] = []
var elapsed := 0.0
var trauma := 0.0
var reduced_effects := false
var practice := false
var hitboxes_visible := false
var backdrop: Node
var stage_environment: Environment
var base_camera := Vector3(0, 6.5, 24)
var silhouettes: Array[MeshInstance3D] = []
const COLORS := [Color("65e9de"), Color("ff7659")]

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_stage()
    for i in 2:
        var fighter := FighterVisual.new()
        add_child(fighter)
        fighter.setup(COLORS[i])
        fighters.append(fighter)
    audio = FightAudio.new()
    add_child(audio)
    var canvas := CanvasLayer.new()
    add_child(canvas)
    hud = FightHUD.new()
    hud.session = self
    canvas.add_child(hud)
    _present(0.0)

func _build_stage() -> void:
    backdrop = preload("res://scripts/combat/street_backdrop.gd").new()
    backdrop.name = "StreetBackdrop"
    add_child(backdrop)
    var world := WorldEnvironment.new()
    stage_environment = Environment.new()
    stage_environment.background_mode = Environment.BG_CANVAS
    stage_environment.background_canvas_max_layer = -1
    stage_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    stage_environment.ambient_light_color = Color("b5c9e7")
    stage_environment.ambient_light_energy = 0.7
    world.environment = stage_environment
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-30,0)
    sun.light_color = Color("ffe8c9")
    sun.light_energy = 0.85
    sun.shadow_enabled = true
    sun.shadow_blur = 0.0
    add_child(sun)
    # A flush road surface continues to the camera; no raised arena front wall.
    _box(Vector3(0,0.015,48.85), Vector3(50,0.04,102.3), Color("68777d"))
    for side in [-1,1]:
        _box(Vector3(side*9.15,0.06,0), Vector3(0.14,0.07,4.8), COLORS[0 if side < 0 else 1], true)
        for x in 6:
            _box(Vector3(side*(5.6+x*0.45),0.05,1.8), Vector3(0.18,0.035,0.5), Color("e7c34d"))
    for x in [-3.0,3.0]:
        var ring := MeshInstance3D.new()
        var mesh := TorusMesh.new()
        mesh.inner_radius = 0.63
        mesh.outer_radius = 0.68
        mesh.rings = 24
        mesh.ring_segments = 6
        ring.mesh = mesh
        ring.position = Vector3(x,0.07,0)
        ring.material_override = _material(COLORS[0 if x < 0 else 1], true)
        add_child(ring)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 9.0
    camera.near = 0.1
    camera.far = 220.0
    add_child(camera)
    camera.position = base_camera
    camera.look_at(Vector3(0,2.5,0))
    camera.make_current()
    for i in 2:
        var shadow := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.58
        mesh.bottom_radius = 0.58
        mesh.height = 0.015
        mesh.radial_segments = 12
        shadow.mesh = mesh
        shadow.material_override = _material(Color("2e344e"), true)
        add_child(shadow)
        silhouettes.append(shadow)

func _box(at: Vector3, size: Vector3, color: Color, unlit := false) -> void:
    var node := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    node.mesh = box
    node.position = at
    node.material_override = _material(color, unlit)
    add_child(node)

func _material(color: Color, unlit: bool) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 1.0
    if unlit:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func start_match(training := false) -> void:
    practice = training
    sim.restart_match()
    sim.ai_enabled = not practice
    effects.clear()
    pending.clear()
    trauma = 0
    screen = "play"
    hud.rebuild_menu()

func _physics_process(_delta: float) -> void:
    if screen != "play":
        return
    var input := pending.duplicate()
    pending.clear()
    input["axis"] = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
    input["guard"] = Input.is_physical_key_pressed(KEY_SHIFT)
    input["up"] = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
    var previous_stop := sim.hitstop
    sim.tick(input)
    if previous_stop == 1 and sim.hitstop == 0:
        audio.play_sound("release", 1.0 + sim.combo_hits * 0.06)
    for event in sim.events:
        _handle_event(event)
    if sim.phase in ["round_over", "match_over"]:
        screen = "result"
        audio.stop_all()
        audio.play_sound("ko")
        hud.rebuild_menu()

func _handle_event(event: Dictionary) -> void:
    var kind: String = event.kind
    if kind in ["hit", "block", "guard_break"]:
        var target: Dictionary = sim.fighters[event.target]
        var position_2d := Vector2(target.x, target.y + 1.2)
        effects.append({"kind": kind, "at": position_2d, "age": 0.0, "life": 0.34, "strength": event.get("strength",0.25), "color": COLORS[event.get("attacker",0)]})
        trauma = maxf(trauma, event.get("strength",0.2) * 0.6)
        audio.play_sound("block" if kind == "block" else "hit", 1.0 + sim.combo_hits * 0.07)
        if kind == "hit":
            audio.play_sound("charge", 0.8 + event.strength * 0.4)
    elif kind == "swing":
        var f: Dictionary = sim.fighters[event.target]
        effects.append({"kind": "swing", "at": Vector2(f.x + f.face * 1.0, f.y + 1.15), "age": -float(Simulation.MOVES[event.move].startup) / 60.0, "life": 0.13, "strength": 0.5, "face": f.face, "color": COLORS[event.target]})
        audio.play_sound("swing")
    elif kind in ["land", "dash", "jump"]:
        var f: Dictionary = sim.fighters[event.target]
        effects.append({"kind": "dust", "at": Vector2(f.x,0.08), "age": 0.0, "life": 0.22, "strength": 0.3, "color": Color("f1edcf")})
    elif kind == "fight":
        hud.notice = "FIGHT!"
        hud.notice_time = 0.7
    elif kind == "no_meter":
        hud.notice = "SPECIAL NEEDS 50 ENERGY"
        hud.notice_time = 1.5

func _process(delta: float) -> void:
    if screen != "pause" and screen != "help":
        elapsed += delta
        for effect in effects:
            effect.age += delta
        effects = effects.filter(func(e: Dictionary) -> bool: return e.age < e.life)
        trauma = move_toward(trauma, 0.0, delta * 2.0)
    backdrop.present(delta, screen in ["pause", "help", "result"])
    _present(delta if screen in ["play", "title"] else 0.0)
    hud.queue_redraw()

func _present(delta: float) -> void:
    for i in fighters.size():
        fighters[i].present(sim.fighters[i], delta, sim.hitstop > 0, reduced_effects)
        silhouettes[i].position = Vector3(sim.fighters[i].x,0.09,0)
        silhouettes[i].scale = Vector3.ONE * clampf(1.0 - sim.fighters[i].y * 0.08, 0.5, 1.0)
    var shake := 0.0 if reduced_effects else trauma * trauma * 0.35
    var midpoint: float = (sim.fighters[0].x + sim.fighters[1].x) * 0.5
    var separation: float = absf(sim.fighters[0].x - sim.fighters[1].x)
    camera.size = lerpf(camera.size, clampf(separation * 0.5 + 7.0, 9.0, 12.6), 1.0 - exp(-delta * 4.0))
    camera.position = base_camera + Vector3(midpoint * 0.6 + sin(elapsed*91)*shake,cos(elapsed*77)*shake*0.4,0)

func project(point: Vector2) -> Vector2:
    return camera.unproject_position(Vector3(point.x,point.y,0)) * Vector2(1280,720) / get_viewport().get_visible_rect().size

func pause_game() -> void:
    if screen == "play":
        screen = "pause"
        pending.clear()
        audio.stop_all()
        hud.rebuild_menu()

func resume_game() -> void:
    screen = "play"
    pending.clear()
    hud.rebuild_menu()

func advance_round() -> void:
    sim.next_round()
    effects.clear()
    pending.clear()
    screen = "play"
    hud.rebuild_menu()

func return_to_street() -> void:
    audio.stop_all()
    get_tree().change_scene_to_file("res://scenes/street_walk.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed() or event.is_echo():
        return
    if event.keycode == KEY_F6:
        return_to_street()
    elif event.keycode == KEY_M:
        audio.muted = not audio.muted
        audio.stop_all()
        hud.rebuild_menu()
    elif event.keycode == KEY_F2:
        reduced_effects = not reduced_effects
        hud.rebuild_menu()
    elif event.keycode == KEY_F3:
        hitboxes_visible = not hitboxes_visible
    elif event.keycode == KEY_ESCAPE:
        if screen == "play":
            pause_game()
        elif screen in ["pause", "help"]:
            resume_game()
    elif event.keycode == KEY_ENTER:
        if screen == "title":
            start_match()
        elif screen == "result":
            if sim.phase == "match_over":
                start_match(practice)
            else:
                advance_round()
    elif event.keycode == KEY_R and screen in ["pause", "result"]:
        start_match(practice)
    elif screen == "play":
        match event.physical_keycode:
            KEY_J: pending["attack"] = "light"
            KEY_K: pending["attack"] = "heavy"
            KEY_L: pending["attack"] = "special"
            KEY_SPACE: pending["jump"] = true
            KEY_E: pending["dash"] = true

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
        pause_game()
