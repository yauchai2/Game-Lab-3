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
var last_impact_strength := 0.0
var step_distance := [0.0,0.0]
var trail_clock := 0.0
var ink_pass: MeshInstance3D
var reduced_effects := false
var practice := false
@export var preferences_path := "user://afterhours.cfg"
var preferences := preload("res://scripts/combat/fight_preferences.gd").new()
var input_history: Array[String] = []
var hitboxes_visible := false
var backdrop: Node
var stage_environment: Environment
var base_camera := Vector3(0, 1.7, 16.5)
var camera_focus := Vector3(0,2.45,3.0)
const FIGHT_Z := 3.0
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
    _restore_options()
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
    stage_environment = backdrop.environment
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 48.0
    camera.near = 0.1
    camera.far = 220.0
    add_child(camera)
    camera.position = base_camera
    camera.look_at(camera_focus)
    camera.make_current()
    ink_pass = MeshInstance3D.new()
    ink_pass.name = "OptionalSceneEdges"
    ink_pass.set_script(preload("res://scripts/screen_outline.gd"))
    add_child(ink_pass)
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
    sim.training = training
    sim.restart_match()
    if practice: sim.phase="fight"
    input_history.clear()
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
    if previous_stop == 1 and sim.hitstop == 0 and last_impact_strength>0.45:
        audio.play_sound("release", 1.0 + sim.combo_hits * 0.06)
        audio.play_sound("sub",0.9,-4.0)
    for event in sim.events:
        _handle_event(event)
    if sim.phase in ["round_over", "match_over"]:
        screen = "result"
        audio.stop_all()
        audio.play_sound("ko")
        hud.rebuild_menu()

func _spawn_vfx(kind: String, at: Vector2, life: float, options: Dictionary = {}) -> void:
    if reduced_effects and kind in ["speed","trail"]: return
    if effects.size()>=64: effects.pop_front()
    var effect := {"kind":kind,"at":at,"age":0.0,"life":life,"strength":0.5,"face":1,"color":COLORS[0]}
    effect.merge(options,true)
    effects.append(effect)

func _handle_event(event: Dictionary) -> void:
    var kind: String = event.kind
    if kind in ["hit","block","parry","guard_break"]:
        var target: Dictionary = sim.fighters[event.target]
        var strength: float = event.get("strength",0.8 if kind in ["parry","guard_break"] else 0.25)
        var tint: Color = Color("eaf078") if kind in ["parry","guard_break"] else COLORS[event.get("attacker",0)]
        _spawn_vfx(kind,Vector2(target.x,target.y+1.2),0.38,{"strength":strength,"color":tint})
        last_impact_strength = strength
        trauma = maxf(trauma,strength*0.6)
        audio.play_sound(("heavy" if strength>0.55 else "hit") if kind=="hit" else kind,1.0+sim.combo_hits*0.04)
        if kind=="hit" and strength>0.55: audio.play_sound("sub",0.9,-5.0)
        if kind=="parry" or kind=="guard_break" or event.get("counter",false):
            hud.notice = "PERFECT GUARD" if kind=="parry" else ("GUARD BREAK" if kind=="guard_break" else "COUNTER HIT")
            hud.notice_time = 0.8
    elif kind=="swing":
        var fighter: Dictionary = sim.fighters[event.target]
        var startup: float = float(Simulation.MOVES[event.move].startup)/60.0
        _spawn_vfx("swing",Vector2(fighter.x+fighter.face*0.9,fighter.y+1.15),0.13,{"age":-startup,"face":fighter.face,"color":COLORS[event.target]})
        audio.play_sound("swing",1.0,-8.0)
        if event.move=="special":
            _spawn_vfx("charge",Vector2(fighter.x,fighter.y+1.2),startup,{"color":COLORS[event.target]})
            _spawn_vfx("wave",Vector2(fighter.x+fighter.face*0.6,fighter.y+1.2),0.26,{"age":-startup,"face":fighter.face,"color":COLORS[event.target]})
            audio.play_sound("charge",1.0,-4.0)
    elif kind in ["land","dash","jump"]:
        var fighter: Dictionary = sim.fighters[event.target]
        _spawn_vfx("dust",Vector2(fighter.x,0.08),0.22,{"color":Color("f1edcf")})
        audio.play_sound(kind,1.0,-6.0)
        if kind=="dash":
            _spawn_vfx("speed",Vector2(fighter.x,fighter.y+0.9),0.2,{"face":signf(fighter.vx),"color":COLORS[event.target]})
    elif kind=="air_chase":
        hud.notice="AIR CHASE / J TO FOLLOW UP"
        hud.notice_time=0.7
    elif kind=="fight":
        hud.notice = "FIGHT!"
        hud.notice_time = 0.7
    elif kind=="no_meter":
        hud.notice = "SPECIAL NEEDS 50 ENERGY"
        hud.notice_time = 1.5

func _process(delta: float) -> void:
    audio.context = screen
    if screen != "pause" and screen != "help":
        elapsed += delta
        for effect in effects:
            effect.age += delta
        effects = effects.filter(func(e: Dictionary) -> bool: return e.age < e.life)
        trauma = move_toward(trauma, 0.0, delta * 2.0)
    if screen=="play" and sim.hitstop==0:
        trail_clock += delta
        for i in 2:
            var fighter: Dictionary = sim.fighters[i]
            if fighter.state=="idle" and fighter.y<=0.01 and absf(fighter.vx)>2:
                step_distance[i] += absf(fighter.vx)*delta
                if step_distance[i]>1.25:
                    step_distance[i] = 0.0
                    audio.play_sound("step",1.0,-12.0)
            if fighter.state=="stun" and absf(fighter.vx)>6 and trail_clock>0.06:
                _spawn_vfx("trail",Vector2(fighter.x,fighter.y+1),0.15,{"face":signf(fighter.vx),"color":COLORS[i]})
        if trail_clock>0.06: trail_clock = 0.0
    backdrop.present(delta, screen in ["pause", "help", "result"])
    _present(delta if screen in ["play", "title", "result"] else 0.0)
    hud.queue_redraw()

func _present(delta: float) -> void:
    for i in fighters.size():
        fighters[i].present(sim.fighters[i], delta, sim.hitstop > 0 and screen=="play", reduced_effects, sim.fighters[1-i].x)
        silhouettes[i].position = Vector3(fighters[i].model.global_position.x,0.03,FIGHT_Z)
        silhouettes[i].scale = Vector3.ONE * clampf(1.0 - sim.fighters[i].y * 0.08, 0.5, 1.0)
    var shake := 0.0 if reduced_effects else trauma * trauma * 0.35
    var midpoint: float = (sim.fighters[0].x + sim.fighters[1].x) * 0.5
    var separation: float = absf(sim.fighters[0].x - sim.fighters[1].x)
    var distance := clampf(11.4 + separation * 0.35,13.5,17.2)
    var yaw := clampf(midpoint * 0.018,-0.10,0.10)
    var target_focus := Vector3(midpoint*0.8,2.45 + maxf(sim.fighters[0].y,sim.fighters[1].y)*0.15,FIGHT_Z)
    var target_position := Vector3(target_focus.x+sin(yaw)*distance,1.7,FIGHT_Z+cos(yaw)*distance)
    var blend := 1.0-exp(-delta*4.0)
    camera_focus = camera_focus.lerp(target_focus,blend)
    base_camera = base_camera.lerp(target_position,blend)
    camera.position = base_camera + Vector3(sin(elapsed*91)*shake,cos(elapsed*77)*shake*0.4,0)
    camera.look_at(camera_focus)

func project(point: Vector2) -> Vector2:
    return camera.unproject_position(Vector3(point.x,point.y,FIGHT_Z)) * Vector2(1280,720) / get_viewport().get_visible_rect().size

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
        save_options()
        hud.rebuild_menu()
    elif event.keycode == KEY_F4:
        audio.music_muted = not audio.music_muted
        save_options()
        hud.rebuild_menu()
    elif event.keycode == KEY_O:
        ink_pass.visible = not ink_pass.visible
        save_options()
        hud.rebuild_menu()
    elif event.keycode == KEY_F2:
        reduced_effects = not reduced_effects
        save_options()
        hud.rebuild_menu()
    elif event.keycode==KEY_F5 and practice and screen=="play":
        reset_training()
    elif event.keycode==KEY_F7 and practice and screen=="play":
        set_partner_mode((sim.partner_mode+1)%3)
    elif event.keycode == KEY_F3:
        hitboxes_visible = not hitboxes_visible
    elif event.keycode == KEY_ESCAPE:
        if screen == "play":
            pause_game()
        elif screen in ["pause", "help"]:
            resume_game()
    elif event.keycode==KEY_T and screen=="title":
        start_match(true)
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
        if practice: _record_training_input(event.physical_keycode)
        match event.physical_keycode:
            KEY_J: pending["attack"] = "light"
            KEY_K: pending["attack"] = "heavy"
            KEY_L: pending["attack"] = "special"
            KEY_SPACE: pending["jump"] = true
            KEY_E: pending["dash"] = true

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
        pause_game()

func reset_training() -> void:
    if not practice: return
    sim.reset_training()
    effects.clear()
    pending.clear()
    input_history.clear()
    trauma=0.0
    screen="play"
    hud.notice="TRAINING RESET"
    hud.notice_time=0.7
    hud.rebuild_menu()

func set_partner_mode(value: int) -> void:
    sim.partner_mode=clampi(value,0,2)
    if practice: reset_training()
    save_options()

func set_difficulty(value: int) -> void:
    sim.difficulty=clampi(value,0,2)
    save_options()

func _record_training_input(code: int) -> void:
    var labels := {KEY_J:"J  LIGHT",KEY_K:"K  HEAVY",KEY_L:"L  SPECIAL",KEY_SPACE:"SPACE  JUMP",KEY_E:"E  DODGE",KEY_SHIFT:"SHIFT  GUARD",KEY_A:"A  LEFT",KEY_D:"D  RIGHT"}
    if not labels.has(code): return
    var label: String = labels[code]
    if code==KEY_K and (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)): label="W+K  LAUNCH"
    input_history.append("%04d  %s" % [sim.tick_count%10000,label])
    if input_history.size()>6: input_history.pop_front()

func _restore_options() -> void:
    var options: Dictionary = preferences.read_options(preferences_path)
    audio.muted=options.muted
    audio.music_muted=options.music_muted
    reduced_effects=options.reduced_effects
    ink_pass.visible=options.scene_edges
    sim.difficulty=options.difficulty
    sim.partner_mode=options.partner_mode

func save_options() -> void:
    preferences.write_options(preferences_path,{"muted":audio.muted,"music_muted":audio.music_muted,"reduced_effects":reduced_effects,"scene_edges":ink_pass.visible,"difficulty":sim.difficulty,"partner_mode":sim.partner_mode})

func return_to_title() -> void:
    screen="title"
    pending.clear()
    effects.clear()
    audio.stop_all()
    hud.rebuild_menu()
