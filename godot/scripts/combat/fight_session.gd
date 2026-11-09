extends Node3D
signal combat_event(event: Dictionary)
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
var theatre=preload("res://scripts/combat/impact_theatre.gd").new()
var rhythm=preload("res://scripts/combat/combat_rhythm.gd").new()
const FINISH_SECONDS := 1.4
var red_environment: Environment
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
var retro_pixels := true
var pixel_pass: ColorRect
var language := "en"
var character_choices := [0,1]
var training_details := false
var settings_save_clock := -1.0
var practice := false
var demo: RefCounted
var demo_partner := 0
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
        fighter.setup(COLORS[i],character_choices[i])
        fighters.append(fighter)
    audio = FightAudio.new()
    add_child(audio)
    _restore_options()
    var pixel_layer:=CanvasLayer.new()
    pixel_layer.layer=0
    add_child(pixel_layer)
    pixel_pass=ColorRect.new()
    pixel_pass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pixel_pass.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var pixel_material:=ShaderMaterial.new()
    pixel_material.shader=preload("res://shaders/retro_pixels.gdshader")
    pixel_pass.material=pixel_material
    pixel_layer.add_child(pixel_pass)
    get_viewport().msaa_3d=Viewport.MSAA_DISABLED
    get_viewport().screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
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
    red_environment=Environment.new()
    red_environment.background_mode=Environment.BG_COLOR
    red_environment.background_color=Color("f42d20")
    red_environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    red_environment.ambient_light_color=Color.WHITE
    red_environment.ambient_light_energy=.8
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
    if demo!=null:sim.partner_mode=demo_partner
    demo=null
    sim.arcade_enabled=true
    sim.endless=false
    result_clock=0.0
    practice = training
    sim.training = training
    sim.restart_match()
    finish_menu_open=false
    if practice:
        sim.phase="fight"
        sim.fighters[0].x=-.7;sim.fighters[1].x=.7
    input_history.clear()
    sim.ai_enabled = not practice
    effects.clear()
    _clear_impacts()
    pending.clear()
    trauma = 0
    screen = "play"
    hud.rebuild_menu()

func _physics_process(delta: float) -> void:
    if screen!="play":return
    var count:int=rhythm.take_steps(delta,sim.arcade_enabled and not reduced_effects)
    for i in count:
        if screen!="play":break
        _combat_step()
        # A new contact must be seen before spending a second accelerated step.
        if rhythm.active() and rhythm.phase()=="hold":break

func _combat_step() -> void:
    if screen != "play":
        return
    var input := pending.duplicate()
    pending.clear()
    input["axis"] = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
    input["guard_pressed"] = input.get("guard_pressed",false)
    input["guard"] = Input.is_physical_key_pressed(KEY_SHIFT)
    input["down"] = input.get("down",Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
    input["up"] = input.get("up",Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
    if sim.arcade_enabled and demo==null:
        input["rush"]=Input.is_physical_key_pressed(KEY_J)
        if input.get("attack","")=="heavy":
            input["down"]=sim.fighters[0].y>.1 or input.get("down",false)
            input["up"]=sim.fighters[0].y<=.1 and not input.down
    var previous_stop := sim.hitstop
    if demo!=null:
        if demo.needs_setup:_prepare_demo_state()
        var commands: Array=demo.commands(sim)
        sim.tick(commands[0],commands[1])
        demo.observe(sim)
    else:sim.tick(input)
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
        if sim.arcade_enabled and sim.winner>=0 and sim.fighters[1-sim.winner].health<=0:
            theatre.begin("ko",winning_side)
        else:theatre.clear()
        audio.stop_all()
        audio.play_sound("ko")
        hud.rebuild_menu()

func start_demo() -> void:
    var original_partner: int=demo_partner if demo!=null else sim.partner_mode
    start_match(true)
    demo_partner=original_partner
    demo=preload("res://scripts/combat/demo_director.gd").new()
    _prepare_demo_state()

func _prepare_demo_state() -> void:
    demo.prepare(sim)
    effects.clear()
    _clear_impacts()
    spectacle.clear()
    audio.stop_all()
    pending.clear()
    input_history.clear()
    trauma=0.0
    result_clock=0.0
    finish_menu_open=false
    screen="play"
    hud.notice_time=0
    hud.rebuild_menu()

func _spawn_vfx(kind: String, at: Vector2, life: float, options: Dictionary = {}) -> void:
    if reduced_effects and kind in ["speed","trail"]: return
    if effects.size()>=64: effects.pop_front()
    var effect := {"rush":sim.arcade_enabled,"kind":kind,"at":at,"age":0.0,"life":life,"strength":0.5,"face":1,"color":COLORS[0]}
    effect.merge(options,true)
    var actor:int=effect.get("attacker",effect.get("owner",0 if effect.color==COLORS[0] else 1))
    effect["character"]=character_choices[clampi(actor,0,1)]
    if effect.get("move","") in ["special","overdrive"]:effect.color=Color(Simulation.Profiles.profile(effect.character).color)
    effects.append(effect)

func _handle_event(event: Dictionary) -> void:
    combat_event.emit(event)
    var kind: String = event.kind
    if sim.arcade_enabled and not reduced_effects:
        var side:int=event.get("attacker",event.get("target",0))
        if kind=="break_finish":rhythm.trigger("break",side)
        elif kind in ["parry","air_counter_start"]:rhythm.trigger("parry",side)
        elif kind=="homing_chase":rhythm.trigger("chase",side)
        elif kind=="swing" and event.get("move","") in ["special","overdrive"]:rhythm.trigger("overdrive" if event.move=="overdrive" else "skill",side)
        elif kind=="hit":
            if event.get("move","") in ["meteor","special","overdrive","air_counter"]:rhythm.trigger("impact",side,event.move)
            elif event.get("move","")=="launcher":rhythm.trigger("launch",side)
        if rhythm.active() and rhythm.phase()=="hold":
            effects=effects.filter(func(e:Dictionary)->bool:return e.kind not in ["echo","trail","speed"])
    if kind=="break_finish":
        theatre.begin("break",event.attacker)
        audio.play_sound("slam",.75,-2)
    elif kind=="counter_success":
        if event.target==0 or demo!=null:
            hud.notice="COUNTER SUCCESS"
            hud.notice_time=1.1
            audio.play_sound("rally",1.4,-9)
    elif kind=="air_lesson_reset":
        effects.clear()
        _clear_impacts()
        audio.stop_all()
        pending.clear()
    elif kind in ["air_parry_attempt","air_parry_no_meter"]:
        if kind=="air_parry_attempt":
            var f: Dictionary=sim.fighters[event.target]
            _spawn_vfx("parry",Vector2(f.x,f.y+1.2),.12,{"color":COLORS[event.target]})
            audio.play_sound("parry",1.25,-10)
        else:
            hud.notice="AIR PARRY NEEDS 25"
            hud.notice_time=.9
    elif kind=="air_counter_start":
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="air_counter_core")
        _clear_impacts()
        var point:=Vector2((sim.fighters[0].x+sim.fighters[1].x)*.5,(sim.fighters[0].y+sim.fighters[1].y)*.5+1.1)
        _spawn_vfx("air_counter_core",point,.5,{"held":true,"tier":3,"color":COLORS[event.owner]})
        spectacle.trigger("contact",event.owner,point,3)
        audio.play_sound("rally",1.1,-5)
        audio.play_sound("charge",1.15,-8)
        pending.clear()
        hud.notice_time=0
    elif kind=="air_counter_windup":
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="air_counter_core")
    elif kind=="air_counter_release":
        var f: Dictionary=sim.fighters[event.owner]
        spectacle.trigger("burst",event.owner,Vector2(f.x,f.y+1.0),3)
        _spawn_vfx("surge_arc",Vector2(f.x+f.face*.6,f.y+1.1),.22,{"face":f.face,"tier":3,"color":COLORS[event.owner]})
        audio.play_sound("release",1.1,-6)
    elif kind=="air_counter_end":
        effects=effects.filter(func(e:Dictionary)->bool:return e.kind!="air_counter_core")
        hud.notice="AIR COUNTER "+event.reason.to_upper()
        hud.notice_time=.8
        if event.reason!="hit":spectacle.clear()
    elif kind in ["fast_fall","air_land","ground_bounce","homing_chase","chase_arrive","air_escape","no_chase_meter","chase_unavailable"]:
        var fighter: Dictionary=sim.fighters[event.target]
        var point:=Vector2(fighter.x,fighter.y+.8)
        if kind in ["air_land","ground_bounce"]:
            _spawn_vfx("ground_ring",Vector2(fighter.x,.04),.30,{"color":COLORS[event.target]})
            _spawn_vfx("dust",Vector2(fighter.x,.08),.22,{"color":Color("fff5db")})
            if kind=="ground_bounce" or event.get("hard",false):
                _spawn_vfx("slam_crater",Vector2(fighter.x,.04),.32,{"color":COLORS[event.target]})
                trauma=maxf(trauma,.28)
                audio.play_sound("sub",.85,-7)
            audio.play_sound("land",.85,-6)
        elif kind=="homing_chase":
            _spawn_vfx("chase_path",point,.24,{"points":fighter.air.points.duplicate(),"color":COLORS[event.target]})
            audio.play_sound("chase",1.0,-6)
            hud.notice="CHASE"
            hud.notice_time=.6
        elif kind=="fast_fall":
            _spawn_vfx("speed",point,.22,{"face":fighter.face,"color":COLORS[event.target]})
            audio.play_sound("swing",.8,-8)
        elif kind=="air_escape":
            _spawn_vfx("parry",point,.22,{"color":COLORS[event.target]})
            hud.notice="AIR ESCAPE"
            hud.notice_time=.8
        elif kind=="chase_unavailable":
            hud.notice="CHASE UNAVAILABLE"
            hud.notice_time=.8
        elif kind=="no_chase_meter":
            hud.notice="CHASE NEEDS 20"
            hud.notice_time=.8
    elif kind=="rally_contact":
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
        var point := Vector2(target.x,target.y+fighters[event.target].model_scale*.57)
        _spawn_vfx(kind,point,0.38,{"strength":strength,"color":tint,"move":move,"face":face,"attacker":attacker,"held":kind=="hit" and sim.hitstop>0})
        if kind=="hit":
            if sim.arcade_enabled and move in ["meteor","special","overdrive"]:theatre.begin("cannon_hit" if move=="overdrive" else "impact",attacker)
            if sim.arcade_enabled and move=="meteor":_spawn_vfx("meteor_streak",point,.22,{"color":COLORS[attacker],"face":face})
            if strength>.55:
                spectacle.trigger("contact",attacker,point,clampi(ceili(strength*4),1,4))
                if sim.arcade_enabled:spectacle.tag_move(move)
            if impact_queue.size()>=4:impact_queue.pop_front()
            impact_queue.append({"at":point,"strength":strength,"color":tint,"move":move,"face":face,"attacker":attacker})
            if sim.hitstop==0:_release_impacts()
        trauma = maxf(trauma,strength*0.6)
        audio.play_sound(("slam" if sim.arcade_enabled and move=="meteor" else ("launch" if sim.arcade_enabled and move=="launcher" else ("heavy" if strength>0.55 else "hit"))) if kind=="hit" else kind,1.0+sim.combo_hits*0.04)
        if kind=="hit" and strength>0.55: audio.play_sound("sub",0.9,-5.0)
        if kind=="hit" and move=="grab":
            hud.notice="THROW"
            hud.notice_time=.7
            audio.play_sound("heavy",.85,-7)
        if kind=="block" and (event.target==0 or demo!=null):
            hud.notice="NICE BLOCK"
            hud.notice_time=.65
        if kind=="parry" or kind=="guard_break" or (event.get("counter",false) and not event.get("exchange",false)):
            hud.notice = ("PERFECT GUARD" if event.target==0 or demo!=null else "RIVAL PARRY") if kind=="parry" else ("GUARD BREAK" if kind=="guard_break" else "COUNTER HIT")
            hud.notice_time = 0.8
    elif kind=="swing":
        var fighter: Dictionary = sim.fighters[event.target]
        var startup: float = float(sim.move_for(fighter,event.move).startup)/60.0
        _spawn_vfx("swing",Vector2(fighter.x+fighter.face*0.9,fighter.y+fighters[event.target].model_scale*.55),0.15,{"age":-startup,"face":fighter.face,"color":COLORS[event.target],"move":event.move})
        audio.play_sound("swing",1.0,-8.0)
        if event.move=="grab":_spawn_vfx("grab_tell",Vector2(fighter.x+fighter.face*.55,fighter.y+1.25),startup,{"face":fighter.face,"color":Color("eebd4c")})
        if event.move in ["special","overdrive"]:
            var profile:Dictionary=Simulation.Profiles.profile(character_choices[event.target])
            hud.skill_key=profile.overdrive_name if event.move=="overdrive" else profile.special_name
            hud.skill_time=1.3
            if sim.arcade_enabled:theatre.begin("overdrive" if event.move=="overdrive" else "skill",event.target)
            spectacle.trigger("charge",event.target,Vector2(fighter.x,fighter.y+1.2),4)
            _spawn_vfx("charge",Vector2(fighter.x,fighter.y+1.2),startup,{"color":COLORS[event.target]})
            _spawn_vfx("wave",Vector2(fighter.x+fighter.face*0.6,fighter.y+1.2),0.26,{"age":-startup,"face":fighter.face,"color":COLORS[event.target]})
            audio.play_sound("charge",1.0,-4.0)
            if event.move=="overdrive":
                _spawn_vfx("cannon_charge",Vector2(fighter.x,fighter.y+fighters[event.target].model_scale*.6),.5,{"face":fighter.face,"color":COLORS[event.target],"owner":event.target})
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
        hud.notice = "OVERDRIVE NEEDS 75" if event.get("cost",50)==75 else "SPECIAL NEEDS 50 ENERGY"
        hud.notice_time = 1.5

func _clear_impacts() -> void:
    theatre.clear()
    rhythm.clear()
    if is_instance_valid(backdrop):backdrop.visible=true
    if is_instance_valid(camera):camera.environment=null
    for shadow in silhouettes:shadow.visible=true
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
        if impact.move=="overdrive":_spawn_vfx("cannon_blast",impact.at,.34,impact)
        if impact.strength>.55:
            var side:=0 if impact.color==COLORS[0] else 1
            spectacle.trigger("burst",side,impact.at,clampi(ceili(impact.strength*4),1,4))
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
        if result_clock>=FINISH_SECONDS and not finish_menu_open:
            finish_menu_open=true
            hud.rebuild_menu()
    spectacle.advance(delta,screen in ["pause","help"])
    theatre.advance(delta,screen in ["pause","help"])
    audio.context = screen
    if screen != "pause" and screen != "help":
        elapsed += delta
        for effect in effects:
            effect.age += delta*rhythm.view_speed() if screen=="play" and not reduced_effects else delta
            if effect.get("held",false) and (sim.hitstop>0 or sim.exchange.active() or sim.rally.active() or sim.air_counter.active()):effect.life=maxf(effect.life,effect.age+0.1)
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
    # Motion paths already communicate pursuit; omit opaque skeleton-stick ghosts.
    backdrop.present(delta, screen in ["pause", "help", "result"], reduced_effects)
    _present((delta*rhythm.view_speed() if screen=="play" and not reduced_effects else delta) if screen in ["play", "title", "result"] else 0.0)
    _grade_world()
    _apply_red_stage()
    hud.queue_redraw()

func _apply_red_stage() -> void:
    var red:bool=theatre.active() and not reduced_effects and screen in ["play","result"]
    if red:
        red_environment.background_color=Color("692049") if theatre.mode=="overdrive" else (Color("c92645") if theatre.mode=="skill" else (Color("ff431e") if theatre.mode=="break" else Color("f42d20")))
    backdrop.visible=not red
    camera.environment=red_environment if red else null
    for shadow in silhouettes:shadow.visible=not red
    if red:grade.visible=false

func _grade_world() -> void:
    if not is_instance_valid(grade):return
    pixel_pass.visible=retro_pixels
    var strength:=0.0
    var grade_owner:=spectacle.owner
    if not reduced_effects and screen in ["play","result"]:
        if sim.rally.active() and sim.rally.tier>=3:
            strength=.45+(sim.rally.tier-3)*.2
            grade_owner=sim.rally.owner
        elif spectacle.mode in ["charge","burst","contact"] and spectacle.tier>=3:
            strength=(.84 if sim.arcade_enabled else .62)*clampf(1.0-spectacle.age/maxf(.001,spectacle.duration),0,1)
        elif screen=="result" and result_clock<FINISH_SECONDS:
            strength=.85*(1.0-result_clock/FINISH_SECONDS)
    grade.visible=strength>.001
    grade_material.set_shader_parameter("strength",strength)
    grade_material.set_shader_parameter("accent",COLORS[grade_owner])

func _present(delta: float) -> void:
    for i in fighters.size():
        var pose: Dictionary=sim.fighters[i].duplicate()
        pose["air_enabled"]=sim.is_aerial()
        pose["rush_visual"]=sim.arcade_enabled and not reduced_effects
        pose["ko_theatre"]=theatre.age/theatre.duration*.64 if theatre.mode=="ko" and theatre.active() and not reduced_effects else -1.0
        if sim.air_counter.active():
            pose["air_counter_role"]="owner" if i==sim.air_counter.owner else "target"
            pose["air_counter_phase"]=sim.air_counter.phase
        if screen=="result":
            if theatre.active() and theatre.mode=="ko" and not reduced_effects:
                pose.x-=pose.face*(.28 if i==sim.winner else .45)
                if i!=sim.winner:pose.y+=.18
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
            if i==1 and demo==null:choice=sim.exchange.clash.cue
            pose["exchange_choice"]=choice
        fighters[i].present(pose, delta, (sim.hitstop>0 or sim.exchange.active() or (sim.rally.active() and sim.rally.phase=="compress") or (sim.air_counter.active() and sim.air_counter.phase=="hold")) and screen=="play", reduced_effects, sim.fighters[1-i].x)
        silhouettes[i].position = Vector3(fighters[i].model.global_position.x,0.03,FIGHT_Z)
        silhouettes[i].scale = Vector3.ONE * clampf(1.0 - pose.y * 0.08, 0.5, 1.0)*(fighters[i].model_scale/2.1)
    var shake := 0.0 if reduced_effects else trauma * trauma * 0.60
    var midpoint: float = (sim.fighters[0].x + sim.fighters[1].x) * 0.5
    var separation: float = absf(sim.fighters[0].x - sim.fighters[1].x)
    var distance := clampf(8.1+separation*.22,8.4,15.0) if sim.arcade_enabled else clampf(10.0 + separation * 0.35,10.7,17.2)
    var yaw := clampf(midpoint * 0.018,-0.10,0.10)
    var target_focus := Vector3(midpoint*0.8,2.1 + maxf(sim.fighters[0].y,sim.fighters[1].y)*0.15,FIGHT_Z)
    if sim.is_aerial():
        var aspect: float=get_viewport().get_visible_rect().size.x/maxf(1,get_viewport().get_visible_rect().size.y)
        distance=maxf(distance,(separation+.9)/(2.0*tan(deg_to_rad(24.0))*aspect*.90))
        var bottom: float=minf(sim.fighters[0].y,sim.fighters[1].y)
        var top: float=maxf(sim.fighters[0].y+maxf(0,sim.fighters[0].vy)*.08,sim.fighters[1].y+maxf(0,sim.fighters[1].vy)*.08)+2.4
        target_focus.y=maxf(2.1,(bottom+top)*.5-.35)
        distance=maxf(distance,(top-bottom+.35)/(2.0*tan(deg_to_rad(24.0))*.58))
        distance=minf(distance,22.0)
    var camera_height:=1.7+maxf(0,target_focus.y-2.1)*.8 if sim.is_aerial() else 1.7
    var target_position := Vector3(target_focus.x+sin(yaw)*distance,camera_height,FIGHT_Z+cos(yaw)*distance)
    if screen=="title" and sim.phase=="ready":
        target_focus=Vector3(.6,2.5,FIGHT_Z)
        target_position=Vector3(-.6,2.3,FIGHT_Z+9.7)
        if not reduced_effects:target_position.x+=sin(elapsed*.23)*.07
    var finish_zoom:=0.0
    if screen=="result" and result_clock<FINISH_SECONDS and sim.winner>=0 and not reduced_effects:
        finish_zoom=sin(clampf(result_clock/FINISH_SECONDS,0,1)*PI)
        var victim: Dictionary=sim.fighters[1-sim.winner]
        target_focus=target_focus.lerp(Vector3(victim.x*.6,1.3,FIGHT_Z),finish_zoom*.65)
        target_position=target_position.lerp(Vector3(target_focus.x+.45,1.3,FIGHT_Z+(6.0 if sim.arcade_enabled else 7.8)),finish_zoom)
    var blend := 1.0-exp(-delta*4.0)
    camera_focus = camera_focus.lerp(target_focus,blend)
    base_camera = base_camera.lerp(target_position,blend)
    var punch := Vector2.ZERO
    if not reduced_effects and recoil_age<0.24:
        punch=recoil*exp(-recoil_age*18.0)*cos(recoil_age*23.0)
    var cinematic:=spectacle.camera_punch(reduced_effects)
    var desired_fov:=48.0-finish_zoom*6.0
    if screen=="title" and hud.menu_page=="roster":desired_fov=40.0
    if not reduced_effects and screen=="play":
        if sim.rally.active() and sim.rally.phase=="compress":desired_fov=48.0-sim.rally.tier*.6
        desired_fov-=cinematic*3.0
        if sim.arcade_enabled and spectacle.mode in ["contact","burst"] and spectacle.tier>=3:
            desired_fov-=5.0*clampf(1.0-spectacle.age/.22,0,1)
    camera.fov=48.0 if reduced_effects else lerpf(camera.fov,desired_fov,1.0-exp(-delta*12.0))
    camera.position = base_camera + Vector3(sin(elapsed*91)*shake+punch.x,cos(elapsed*77)*shake*0.4+punch.y,-cinematic)
    camera.look_at(camera_focus)
    if rhythm.active() and not reduced_effects and screen=="play":
        var stage:String=rhythm.phase()
        var direction:float=1.0 if rhythm.owner==0 else -1.0
        var center:=Vector3(midpoint,(sim.fighters[0].y+sim.fighters[1].y)*.5+.95,FIGHT_Z)
        var travel:float=clampf(rhythm.age/.74,0,1)
        var reverse:float=-1.0 if rhythm.style in ["parry","air_counter"] else 1.0
        var orbit:float=direction*reverse*(-.22+travel*.50)
        var vertical_gap:float=absf(sim.fighters[0].y-sim.fighters[1].y)
        var aspect:float=get_viewport().get_visible_rect().size.x/get_viewport().get_visible_rect().size.y
        var cinematic_distance:float=maxf(5.8,maxf((separation+2.0)/(2*tan(deg_to_rad(25.0))*aspect*.78),(vertical_gap+3.0)/(2*tan(deg_to_rad(25.0))*.68)))
        var slam:float=sin(travel*PI)
        var elevation:float=1.7-slam*.4 if rhythm.style=="meteor" else (-.2+slam*.15 if rhythm.style=="overdrive" else .6+slam*.6)
        camera.position=center+Vector3(sin(orbit)*cinematic_distance,elevation,cos(orbit)*cinematic_distance)
        if stage=="release":camera.position+=Vector3(sin(elapsed*110)*.19,cos(elapsed*97)*.10,0)
        camera.look_at(center)
        camera.fov=(38.0 if rhythm.style=="overdrive" else 44.0) if stage=="slow" else 50.0
        camera.rotation.z=direction*deg_to_rad((11.0 if stage!="release" else -7.0)*slam)
    if theatre.active() and theatre.mode=="ko" and not reduced_effects and screen=="result":
        var progress:float=clampf(theatre.age/theatre.duration,0,1)
        var center:=Vector3(midpoint,(sim.fighters[0].y+sim.fighters[1].y)*.5+.95,FIGHT_Z)
        var orbit:float=-.25+progress
        var close_distance:float=maxf(3.05,separation*1.1)-sin(progress*PI)*.2
        camera.position=center+Vector3(sin(orbit)*close_distance,.15+sin(progress*PI)*.18,cos(orbit)*close_distance)
        camera.look_at(center)
        camera.fov=42.0
        camera.rotation.z=deg_to_rad(-7.0*sin(progress*PI))

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
    if event.keycode==KEY_F12:
        if demo!=null:return_to_title()
        elif screen in ["title","play"]:start_demo()
        return
    if demo!=null and screen in ["play","pause","result"]:
        if event.keycode==KEY_R:start_demo();return
        if event.keycode not in [KEY_ESCAPE,KEY_F1,KEY_H,KEY_F2,KEY_F3,KEY_F4,KEY_F6,KEY_M,KEY_O]:return
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
    elif event.keycode==KEY_F11 and screen in ["title","play"]:
        if screen=="title":start_match(true)
        if practice:prime_air_drill()
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
        if sim.is_aerial() and not sim.arcade_enabled:prime_air_defense()
        else:prime_pressure_drill()
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
            var focused:Control=get_viewport().gui_get_focus_owner()
            if focused is Button and focused.get_parent()==hud.art_controls:focused.pressed.emit()
            else:start_match()
        elif screen == "result":
            if sim.phase == "match_over":
                start_match(practice)
            else:
                advance_round()
    elif event.keycode == KEY_R and screen in ["pause", "result"]:
        start_match(practice)
    elif screen == "play":
        if sim.air_counter.active() and sim.air_counter.phase=="hold":
            if event.physical_keycode==KEY_J:commit_air_choice("kick")
            elif event.physical_keycode==KEY_E:commit_air_choice("escape")
            return
        if sim.is_air_lesson() and sim.air_lesson_stage in ["read","review"] and event.physical_keycode==KEY_K:
            pending["lesson_start"]=true
            return
        if sim.exchange.active():
            var choices := {KEY_J:"press",KEY_SHIFT:"turn",KEY_E:"slip"}
            if choices.has(event.physical_keycode):commit_clash_choice(choices[event.physical_keycode])
            return
        if practice: _record_training_input(event.physical_keycode)
        match event.physical_keycode:
            KEY_S,KEY_DOWN: pending["down_pressed"] = true
            KEY_SHIFT: pending["guard_pressed"] = true
            KEY_J: pending["attack"] = "light"
            KEY_K:
                pending["attack"] = "heavy"
                pending["up"] = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
                pending["down"] = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
            KEY_L: pending["attack"] = "overdrive" if sim.arcade_enabled and (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) else "special"
            KEY_G: pending["attack"] = "grab"
            KEY_SPACE: pending["jump"] = true
            KEY_E: pending["dash"] = true

func commit_air_choice(choice: String) -> void:
    if screen=="play" and sim.air_counter.phase=="hold" and sim.air_counter.owner==0 and choice in ["kick","escape"] and not pending.has("air_choice"):
        pending["air_choice"]=choice

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

func prime_air_defense() -> void:
    if not practice:return
    sim.arcade_enabled=false
    reset_training()
    sim.configure_air_lesson()
    hud.notice_time=0
    hud.rebuild_menu()

func prime_air_drill() -> void:
    if not practice:return
    sim.arcade_enabled=false
    reset_training()
    sim.partner_mode=0
    _configure_air_lab()
    hud.notice="AIR LAB READY"
    hud.notice_time=1.0
    hud.rebuild_menu()

func _configure_air_lab() -> void:
    sim.arcade_enabled=false
    sim.practice_scenario="air"
    sim.fighters[0].x=-.75
    sim.fighters[1].x=.75
    for fighter in sim.fighters:fighter.meter=100.0

func prime_rally_drill() -> void:
    if not practice:return
    sim.arcade_enabled=false
    reset_training()
    sim.practice_scenario="rally"
    sim.rally_enabled=true
    sim.rally_drill=true
    sim.fighters[0].x=-.65
    sim.fighters[1].x=.65
    hud.notice="RALLY READY"
    hud.notice_time=2.0
    hud.rebuild_menu()

func prime_pressure_drill() -> void:
    if not practice:return
    sim.arcade_enabled=false
    reset_training()
    sim.fighters[0].x=-.8
    sim.fighters[1].x=.8
    sim.practice_scenario="pressure"
    sim.pressure_drill=true
    sim.exchange.pressure=sim.exchange.THRESHOLD
    hud.notice="PRESSURE READY / K TO START"
    hud.notice_time=2.0

func set_partner_mode(value: int) -> void:
    sim.partner_mode=clampi(value,0,2)
    if practice:
        var air_lab: bool=sim.is_aerial() and not sim.arcade_enabled
        var defense_lab: bool=sim.is_air_lesson()
        reset_training(true)
        if defense_lab:sim.configure_air_lesson()
        elif air_lab:_configure_air_lab()
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
    retro_pixels=options.retro_pixels
    ink_pass.visible=options.scene_edges
    language="en"
    training_details=options.training_details
    audio.music_level=options.music_level
    audio.effects_level=options.effects_level
    sim.difficulty=options.difficulty
    sim.partner_mode=options.partner_mode
    character_choices=[options.player_character,options.rival_character]
    sim.character_choices=character_choices.duplicate()
    for i in 2:sim.fighters[i]["character"]=character_choices[i]
    for i in 2:
        if fighters[i].character_index!=character_choices[i]:fighters[i].setup(COLORS[i],character_choices[i])

func set_character(side:int,index:int) -> void:
    if screen!="title" or side not in [0,1]:return
    var selected:=clampi(index,0,FighterVisual.Roster.ENTRIES.size()-1)
    if character_choices[side]==selected:return
    character_choices[side]=selected
    sim.character_choices[side]=selected
    sim.fighters[side]["character"]=selected
    fighters[side].setup(COLORS[side],selected)
    save_options()
    if is_instance_valid(hud) and hud.menu_page=="roster":hud.rebuild_menu()

func save_options() -> void:
    preferences.write_options(preferences_path,{"muted":audio.muted,"music_muted":audio.music_muted,"reduced_effects":reduced_effects,"retro_pixels":retro_pixels,"scene_edges":ink_pass.visible,"difficulty":sim.difficulty,"partner_mode":demo_partner if demo!=null else sim.partner_mode,"language":language,"training_details":training_details,"music_level":audio.music_level,"effects_level":audio.effects_level,"player_character":character_choices[0],"rival_character":character_choices[1]})

func return_to_title() -> void:
    if demo!=null:sim.partner_mode=demo_partner
    demo=null
    sim.arcade_enabled=false;sim.endless=false
    sim.reset_round()
    sim.pressure_drill=false
    sim.exchange.reset()
    screen="title"
    hud.skill_time=0
    pending.clear()
    effects.clear()
    _clear_impacts()
    audio.stop_all()
    hud.rebuild_menu()
