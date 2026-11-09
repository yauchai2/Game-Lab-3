extends Node3D
const Simulation = preload("res://scripts/combat/fight_simulation.gd")
const FighterVisual = preload("res://scripts/combat/fighter_visual.gd")
const FightHUD = preload("res://scripts/combat/fight_hud.gd")
const FightAudio = preload("res://scripts/combat/fight_audio.gd")
var spectacle := preload("res://scripts/combat/fight_spectacle.gd").new()
var grade: ColorRect
var grade_material: ShaderMaterial
var echo_clock := 0.0
var finish_menu_open := false
var sim := Simulation.new()
var fighters: Array[Node3D] = []
var camera: Camera3D
var hud: Control
var audio: Node
var screen := "title"
var pending: Dictionary = {}
var effects: Array[Dictionary] = []
var elapsed := 0.0
var result_clock := 0.0
var trauma := 0.0
var impact_queue: Array[Dictionary] = []
var recoil := Vector2.ZERO
var recoil_age := 1.0
var step_distance := [0.0,0.0]
var trail_clock := 0.0
var ink_pass: MeshInstance3D
var reduced_effects := false
var language := "zh"
var training_details := false
var settings_save_clock := -1.0
var practice := false
@export var static_batches_enabled := true
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
    var grading_layer:=CanvasLayer.new()
    grading_layer.layer=1
    add_child(grading_layer)
    grade=ColorRect.new()
    grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    grade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    grade_material=ShaderMaterial.new()
    grade_material.shader=preload("res://shaders/kinetic_grade.gdshader")
    grade.material=grade_material
    grade.visible=false
    grading_layer.add_child(grade)
    var canvas := CanvasLayer.new()
    canvas.layer=2
    add_child(canvas)
    hud = FightHUD.new()
    hud.session = self
    canvas.add_child(hud)
    _present(0.0)

func _build_stage() -> void:
    backdrop = preload("res://scripts/combat/street_backdrop.gd").new()
    backdrop.name = "StreetBackdrop"
    backdrop.static_batches_enabled=static_batches_enabled
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
    result_clock=0.0
    practice = training
    sim.training = training
    sim.restart_match()
    finish_menu_open=false
    if practice: sim.phase="fight"
    input_history.clear()
    sim.ai_enabled = not practice
    effects.clear()
    _clear_impacts()
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
    input["guard_pressed"] = input.get("guard_pressed",false)
    input["guard"] = Input.is_physical_key_pressed(KEY_SHIFT)
    input["up"] = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
    var previous_stop := sim.hitstop
    sim.tick(input)
    if previous_stop>0 and sim.hitstop==0:
        _release_impacts()
    for event in sim.events:
        _handle_event(event)
    if sim.phase in ["round_over", "match_over"]:
        _release_impacts(false)
        result_clock=0.0
        screen = "result"
        finish_menu_open=false
        var winning_side:=maxi(0,sim.winner)
        spectacle.trigger("finish",winning_side,Vector2(sim.fighters[1-winning_side].x,1.1),4)
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
    if kind=="rally_contact":
        pending.clear()
        _clear_impacts()
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="rally_core")
        var point:=Vector2((sim.fighters[0].x+sim.fighters[1].x)*.5,1.2)
        spectacle.trigger("contact",event.owner,point,event.tier)
        _spawn_vfx("rally_core",point,.5,{"held":true,"color":COLORS[event.owner],"strength":event.tier*.25,"tier":event.tier})
        audio.play_sound("rally",1.0+event.tier*.08,-5)
        audio.play_sound("charge",.85+event.tier*.08,-6)
        trauma=maxf(trauma,.12+event.tier*.07)
    elif kind=="rally_windup":
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="rally_core")
        audio.play_sound("swing",.85,-8)
    elif kind=="rally_release":
        var fighter: Dictionary=sim.fighters[event.owner]
        var point:=Vector2(fighter.x+fighter.face*.7,fighter.y+1.2)
        spectacle.trigger("burst",event.owner,point,event.tier)
        _spawn_vfx("surge_arc",point,.22,{"color":COLORS[event.owner],"face":fighter.face,"tier":event.tier})
        audio.play_sound("release",.8+event.tier*.08,-4)
    elif kind=="rally_end":
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="rally_core")
        if event.reason!="hit":spectacle.clear()
        hud.notice=event.reason.to_upper()
        hud.notice_time=.7
    elif kind in ["wall_bounce","wall_tech","throw_tech"]:
        var fighter: Dictionary=sim.fighters[event.target]
        var point:=Vector2(fighter.x,fighter.y+1.0)
        if kind=="wall_bounce":
            _spawn_vfx("wall",point,.22,{"color":Color("eebd4c"),"face":-signf(fighter.x),"move":"heavy"})
            trauma=maxf(trauma,.25)
            audio.play_sound("heavy",.85,-8)
        else:
            _spawn_vfx("parry",point,.22,{"color":COLORS[event.target]})
            audio.play_sound("parry",1.1,-8)
            hud.notice="WALL TECH" if kind=="wall_tech" else "THROW TECH"
            hud.notice_time=.7
    elif kind=="clash_start":
        pending.clear()
        effects.clear()
        _clear_impacts()
        var midpoint: float=(sim.fighters[0].x+sim.fighters[1].x)*.5
        _spawn_vfx("clash",Vector2(midpoint,1.2),.5,{"held":true,"color":Color("eaf078"),"move":"heavy"})
        audio.play_sound("block",.85,-3)
        audio.play_sound("charge",1.0,-7)
        hud.notice_time=0
    elif kind=="clash_end":
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="clash")
        var result: String=event.choice
        hud.notice=("YOU / " if event.winner==0 else "RIVAL / ")+result.to_upper() if event.winner>=0 else "EVEN / PRESSURE RELEASED"
        if event.get("feint",false):hud.notice="FEINT / "+hud.notice
        hud.notice_time=1.2
        if result=="turn":audio.play_sound("parry",1.0,-3)
    elif kind in ["hit","block","parry","guard_break"]:
        var target: Dictionary = sim.fighters[event.target]
        var strength: float = event.get("strength",0.8 if kind in ["parry","guard_break"] else 0.25)
        var tint: Color = Color("eaf078") if kind in ["parry","guard_break"] else COLORS[event.get("attacker",0)]
        var attacker: int = event.get("attacker",0)
        var move: String = event.get("move","jab")
        var face: float = sim.fighters[attacker].face
        var point := Vector2(target.x,target.y+1.2)
        _spawn_vfx(kind,point,0.38,{"strength":strength,"color":tint,"move":move,"face":face,"held":kind=="hit" and sim.hitstop>0})
        if kind=="hit":
            if strength>.55:spectacle.trigger("contact",attacker,point,clampi(ceili(strength*4),1,4))
            if impact_queue.size()>=4:impact_queue.pop_front()
            impact_queue.append({"at":point,"strength":strength,"color":tint,"move":move,"face":face})
            if sim.hitstop==0:_release_impacts()
        trauma = maxf(trauma,strength*0.6)
        audio.play_sound(("heavy" if strength>0.55 else "hit") if kind=="hit" else kind,1.0+sim.combo_hits*0.04)
        if kind=="hit" and strength>0.55: audio.play_sound("sub",0.9,-5.0)
        if kind=="hit" and move=="grab":
            hud.notice="THROW"
            hud.notice_time=.7
            audio.play_sound("heavy",.85,-7)
        if kind=="parry" or kind=="guard_break" or (event.get("counter",false) and not event.get("exchange",false)):
            hud.notice = "PERFECT GUARD" if kind=="parry" else ("GUARD BREAK" if kind=="guard_break" else "COUNTER HIT")
            hud.notice_time = 0.8
    elif kind=="swing":
        var fighter: Dictionary = sim.fighters[event.target]
        var startup: float = float(Simulation.MOVES[event.move].startup)/60.0
        _spawn_vfx("swing",Vector2(fighter.x+fighter.face*0.9,fighter.y+1.15),0.15,{"age":-startup,"face":fighter.face,"color":COLORS[event.target],"move":event.move})
        audio.play_sound("swing",1.0,-8.0)
        if event.move=="grab":_spawn_vfx("grab_tell",Vector2(fighter.x+fighter.face*.55,fighter.y+1.25),startup,{"face":fighter.face,"color":Color("eebd4c")})
        if event.move=="special":
            spectacle.trigger("charge",event.target,Vector2(fighter.x,fighter.y+1.2),4)
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

func _clear_impacts() -> void:
    impact_queue.clear()
    recoil=Vector2.ZERO
    recoil_age=1.0
    spectacle.clear()
    if is_instance_valid(grade):grade.visible=false
    if is_instance_valid(camera):camera.fov=48.0

func _release_impacts(with_audio := true) -> void:
    if impact_queue.is_empty():return
    effects=effects.filter(func(e:Dictionary)->bool:return not e.get("held",false))
    var strongest:=0.0
    for impact in impact_queue:
        _spawn_vfx("release",impact.at,0.18 if impact.strength<0.5 else 0.24,impact)
        if impact.strength>.55:
            var side:=0 if impact.color==COLORS[0] else 1
            spectacle.trigger("burst",side,impact.at,clampi(ceili(impact.strength*4),1,4))
            _spawn_vfx("surge_arc",impact.at,.20,{"face":impact.face,"color":impact.color,"tier":clampi(ceili(impact.strength*4),1,4)})
            _spawn_vfx("ground_ring",Vector2(impact.at.x,.04),.32,{"face":impact.face,"color":impact.color,"strength":impact.strength})
        if impact.strength>=strongest:
            strongest=impact.strength
            recoil=Vector2(-impact.face,-0.55 if impact.move=="launcher" else 0.12)*minf(.18,impact.strength*.18)
            recoil_age=0.0
    if with_audio and strongest>0.45:
        audio.play_sound("release",1.0+minf(sim.combo_hits*.06,.3),-3.0)
        audio.play_sound("sub",0.9,-7.0)
    impact_queue.clear()

func _process(delta: float) -> void:
    if settings_save_clock>=0:
        settings_save_clock-=delta
        if settings_save_clock<0:save_options()
    if screen=="result":
        result_clock+=delta
        if result_clock>=.82 and not finish_menu_open:
            finish_menu_open=true
            hud.rebuild_menu()
    spectacle.advance(delta,screen in ["pause","help"])
    audio.context = screen
    if screen != "pause" and screen != "help":
        elapsed += delta
        for effect in effects:
            effect.age += delta
            if effect.get("held",false) and (sim.hitstop>0 or sim.exchange.active() or sim.rally.active()):effect.life=maxf(effect.life,effect.age+0.1)
        effects = effects.filter(func(e: Dictionary) -> bool: return e.age < e.life)
        recoil_age += delta
        trauma = move_toward(trauma, 0.0, delta * 2.0)
    if screen=="play" and sim.hitstop==0 and not sim.exchange.active():
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
    if screen=="play" and not reduced_effects:
        echo_clock+=delta
        if echo_clock>=.055:
            echo_clock=0.0
            for side in 2:
                var state: Dictionary=sim.fighters[side]
                if (state.state=="dash" or (state.state=="stun" and absf(state.vx)>6) or (state.state=="attack" and state.move in ["special","heavy","finisher"])) and sim.hitstop==0:
                    var bones: Array=fighters[side].capture_echo()
                    _spawn_vfx("echo",Vector2.ZERO,.18,{"bones":bones,"color":COLORS[side],"face":state.face})
    backdrop.present(delta, screen in ["pause", "help", "result"], reduced_effects)
    _present(delta if screen in ["play", "title", "result"] else 0.0)
    _grade_world()
    hud.queue_redraw()

func _grade_world() -> void:
    if not is_instance_valid(grade):return
    var strength:=0.0
    var owner:=spectacle.owner
    if not reduced_effects and screen in ["play","result"]:
        if sim.rally.active() and sim.rally.tier>=3:
            strength=.45+(sim.rally.tier-3)*.2
            owner=sim.rally.owner
        elif spectacle.mode in ["charge","burst","contact"] and spectacle.tier>=3:
            strength=.62*clampf(1.0-spectacle.age/maxf(.001,spectacle.duration),0,1)
        elif screen=="result" and result_clock<.82:
            strength=.85*(1.0-result_clock/.82)
    grade.visible=strength>.001
    grade_material.set_shader_parameter("strength",strength)
    grade_material.set_shader_parameter("accent",COLORS[owner])

func _present(delta: float) -> void:
    for i in fighters.size():
        var pose: Dictionary=sim.fighters[i].duplicate()
        if screen=="result":
            if result_clock>.18:pose.flash=0
            pose.y=maxf(0,pose.y-maxf(0,result_clock-.15)*5.0)
            if i==sim.winner and result_clock>.45:
                pose.state="idle"
                pose.vx=0.0
                pose.vy=0.0
        if screen=="title" and sim.phase=="ready":
            pose.x=1.2 if i==0 else 4.0
            pose.face=1 if i==0 else -1
        if sim.rally.active():
            pose["rally_phase"]=sim.rally.phase
            pose["rally_owner"]=i==sim.rally.owner
            pose["rally_tier"]=sim.rally.tier
            pose["rally_amount"]=float(sim.rally.age)/sim.rally.HOLDS[sim.rally.tier-1] if sim.rally.phase=="compress" else float(sim.rally.age)/sim.rally.WINDUP
            if sim.rally.phase=="windup" and i==sim.rally.owner:
                pose.state="attack"
                pose.move="cross"
                pose.frame=floori(clampf(float(sim.rally.age)/sim.rally.WINDUP,0,1)*Simulation.MOVES.cross.startup)
        if sim.exchange.active():
            var choice: String=sim.exchange.clash.choices[i]
            if i==1:choice=sim.exchange.clash.cue
            pose["exchange_choice"]=choice
        fighters[i].present(pose, delta, (sim.hitstop>0 or sim.exchange.active() or (sim.rally.active() and sim.rally.phase=="compress")) and screen=="play", reduced_effects, sim.fighters[1-i].x)
        silhouettes[i].position = Vector3(fighters[i].model.global_position.x,0.03,FIGHT_Z)
        silhouettes[i].scale = Vector3.ONE * clampf(1.0 - pose.y * 0.08, 0.5, 1.0)
    var shake := 0.0 if reduced_effects else trauma * trauma * 0.35
    var midpoint: float = (sim.fighters[0].x + sim.fighters[1].x) * 0.5
    var separation: float = absf(sim.fighters[0].x - sim.fighters[1].x)
    var distance := clampf(10.0 + separation * 0.35,10.7,17.2)
    var yaw := clampf(midpoint * 0.018,-0.10,0.10)
    var target_focus := Vector3(midpoint*0.8,2.1 + maxf(sim.fighters[0].y,sim.fighters[1].y)*0.15,FIGHT_Z)
    var target_position := Vector3(target_focus.x+sin(yaw)*distance,1.7,FIGHT_Z+cos(yaw)*distance)
    if screen=="title" and sim.phase=="ready":
        target_focus=Vector3(.6,2.5,FIGHT_Z)
        target_position=Vector3(-.6,2.3,FIGHT_Z+9.7)
        if not reduced_effects:target_position.x+=sin(elapsed*.23)*.07
    var finish_zoom:=0.0
    if screen=="result" and result_clock<.82 and sim.winner>=0 and not reduced_effects:
        finish_zoom=sin(clampf(result_clock/.82,0,1)*PI)
        var victim: Dictionary=sim.fighters[1-sim.winner]
        target_focus=target_focus.lerp(Vector3(victim.x*.6,1.3,FIGHT_Z),finish_zoom*.65)
        target_position=target_position.lerp(Vector3(target_focus.x+.45,1.3,FIGHT_Z+7.8),finish_zoom)
    var blend := 1.0-exp(-delta*4.0)
    camera_focus = camera_focus.lerp(target_focus,blend)
    base_camera = base_camera.lerp(target_position,blend)
    var punch := Vector2.ZERO
    if not reduced_effects and recoil_age<0.24:
        punch=recoil*exp(-recoil_age*18.0)*cos(recoil_age*23.0)
    var cinematic:=spectacle.camera_punch(reduced_effects)
    var desired_fov:=48.0-finish_zoom*6.0
    if not reduced_effects and screen=="play":
        if sim.rally.active() and sim.rally.phase=="compress":desired_fov=48.0-sim.rally.tier*.6
        desired_fov-=cinematic*3.0
    camera.fov=48.0 if reduced_effects else lerpf(camera.fov,desired_fov,1.0-exp(-delta*12.0))
    camera.position = base_camera + Vector3(sin(elapsed*91)*shake+punch.x,cos(elapsed*77)*shake*0.4+punch.y,-cinematic)
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
    finish_menu_open=false
    effects.clear()
    _clear_impacts()
    pending.clear()
    screen = "play"
    hud.rebuild_menu()

func return_to_street() -> void:
    audio.stop_all()
    get_tree().change_scene_to_file("res://scenes/street_walk.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed() or event.is_echo():
        return
    if hud.handle_shortcut(event):return
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
    elif event.keycode==KEY_F10 and screen in ["title","play"]:
        if screen=="title":start_match(true)
        if practice:prime_rally_drill()
    elif event.keycode==KEY_F8 and screen=="title":
        start_match(true)
        prime_pressure_drill()
    elif event.keycode==KEY_F9:
        training_details=not training_details
        save_options()
        hud.rebuild_menu()
    elif event.keycode==KEY_F8 and practice and screen=="play":
        prime_pressure_drill()
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
        if sim.exchange.active():
            var choices := {KEY_J:"press",KEY_SHIFT:"turn",KEY_E:"slip"}
            if choices.has(event.physical_keycode):commit_clash_choice(choices[event.physical_keycode])
            return
        if practice: _record_training_input(event.physical_keycode)
        match event.physical_keycode:
            KEY_SHIFT: pending["guard_pressed"] = true
            KEY_J: pending["attack"] = "light"
            KEY_K: pending["attack"] = "heavy"
            KEY_L: pending["attack"] = "special"
            KEY_G: pending["attack"] = "grab"
            KEY_SPACE: pending["jump"] = true
            KEY_E: pending["dash"] = true

func commit_clash_choice(choice: String) -> void:
    if screen=="play" and sim.exchange.active() and choice in sim.exchange.CHOICES and not pending.has("clash_choice"):
        pending["clash_choice"]=choice

func set_language(value: String) -> void:
    language=value if value in ["zh","en"] else "zh"
    save_options()
    hud.rebuild_menu()

func set_volume(kind: String, value: float) -> void:
    if kind=="music":audio.music_level=clampf(value,0,1)
    else:
        audio.effects_level=clampf(value,0,1)
        if audio.effects_level<=0:audio.stop_all()
    settings_save_clock=.35

func _exit_tree() -> void:
    # A scene switch or immediate quit can happen before the slider debounce.
    if settings_save_clock>=0 and is_instance_valid(audio) and is_instance_valid(ink_pass):
        save_options()
        settings_save_clock=-1.0

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
        pause_game()

func reset_training(keep_screen := false) -> void:
    if not practice: return
    var previous_screen := screen
    sim.reset_training()
    effects.clear()
    _clear_impacts()
    pending.clear()
    input_history.clear()
    trauma=0.0
    screen=previous_screen if keep_screen and previous_screen in ["pause","help"] else "play"
    hud.notice="TRAINING RESET"
    hud.notice_time=0.7
    hud.rebuild_menu()

func prime_rally_drill() -> void:
    if not practice:return
    reset_training()
    sim.rally_enabled=true
    sim.rally_drill=true
    sim.fighters[0].x=-.65
    sim.fighters[1].x=.65
    hud.notice="RALLY READY"
    hud.notice_time=2.0
    hud.rebuild_menu()

func prime_pressure_drill() -> void:
    if not practice:return
    reset_training()
    sim.fighters[0].x=-.8
    sim.fighters[1].x=.8
    sim.pressure_drill=true
    sim.exchange.pressure=sim.exchange.THRESHOLD
    hud.notice="PRESSURE READY / K TO START"
    hud.notice_time=2.0

func set_partner_mode(value: int) -> void:
    sim.partner_mode=clampi(value,0,2)
    if practice: reset_training(true)
    save_options()

func set_difficulty(value: int) -> void:
    sim.difficulty=clampi(value,0,2)
    save_options()

func _record_training_input(code: int) -> void:
    var labels := {KEY_J:"J  LIGHT",KEY_K:"K  HEAVY",KEY_L:"L  SPECIAL",KEY_SPACE:"SPACE  JUMP",KEY_E:"E  DODGE",KEY_G:"G  THROW",KEY_SHIFT:"SHIFT  GUARD",KEY_A:"A  LEFT",KEY_D:"D  RIGHT"}
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
    language=options.language
    training_details=options.training_details
    audio.music_level=options.music_level
    audio.effects_level=options.effects_level
    sim.difficulty=options.difficulty
    sim.partner_mode=options.partner_mode

func save_options() -> void:
    preferences.write_options(preferences_path,{"muted":audio.muted,"music_muted":audio.music_muted,"reduced_effects":reduced_effects,"scene_edges":ink_pass.visible,"difficulty":sim.difficulty,"partner_mode":sim.partner_mode,"language":language,"training_details":training_details,"music_level":audio.music_level,"effects_level":audio.effects_level})

func return_to_title() -> void:
    sim.reset_round()
    sim.pressure_drill=false
    sim.exchange.reset()
    screen="title"
    pending.clear()
    effects.clear()
    _clear_impacts()
    audio.stop_all()
    hud.rebuild_menu()
