extends SceneTree
## Four legal grab inputs on actual hero meshes; fixed close-range training fixtures.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Motion=preload("res://scripts/combat/paired_throw_motion.gd")
var sim=Sim.new()
var actors:Array=[]
var label:Label
var clip:=-1
var tick_in_clip:=0
var ready_frames:=0
var hits:=0
var landings:=0
var starts:=0
func _initialize() -> void:call_deferred("build")
func build() -> void:
    if not sim.ThrowData.available():push_error("Import the private throw library first");quit(1);return
    var world:=Node3D.new();root.add_child(world)
    var environment:=WorldEnvironment.new();world.add_child(environment)
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color("1c2633")
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color.WHITE
    environment.environment.ambient_light_energy=.8
    var light:=DirectionalLight3D.new();world.add_child(light)
    light.rotation_degrees=Vector3(-45,-35,0);light.light_energy=1.3
    var floor_mesh:=MeshInstance3D.new();world.add_child(floor_mesh)
    floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(30,30)
    var floor_material:=StandardMaterial3D.new();floor_material.albedo_color=Color("414b56")
    floor_mesh.material_override=floor_material
    var camera:=Camera3D.new();world.add_child(camera)
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.8
    camera.position=Vector3(0,3.5,11);camera.look_at(Vector3(0,1.0,3));camera.current=true
    for i in 2:
        var actor=Visual.new();world.add_child(actor);actors.append(actor)
    var canvas:=CanvasLayer.new();root.add_child(canvas)
    label=Label.new();canvas.add_child(label);label.position=Vector2(22,18)
    label.add_theme_font_size_override("font_size",22)
    _next_clip()
func _next_clip() -> void:
    clip+=1;tick_in_clip=0;ready_frames=1
    if clip>=4:
        print("PAIRED_PREVIEW ",JSON.stringify({"starts":starts,"hits":hits,"landings":landings,"fixtures":4,"simulation_ticks_per_frame":2}))
        quit(0 if hits==4 and starts==4 and landings==4 else 1)
        return
    sim.character_choices=[clip,(clip+1)%4];sim.last_service_enabled=true
    sim.training=true;sim.ai_enabled=false;sim.partner_mode=0;sim.reset_round();sim.phase="fight"
    var face:int=1 if clip%2==0 else -1
    sim.fighters[0].x=-.45*face;sim.fighters[1].x=.45*face
    sim.fighters[0].face=face;sim.fighters[1].face=-face
    for i in 2:actors[i].setup(Color("51dce7") if i==0 else Color("ee7f9c"),sim.character_choices[i])
func _process(_delta:float) -> bool:
    if clip<0 or clip>=4:return false
    if ready_frames>0:
        ready_frames-=1
    else:
        for substep in 2:
            sim.tick({"attack":"grab"} if tick_in_clip==0 else {},{})
            for event in sim.events:
                if event.kind=="hit" and event.move=="grab":hits+=1
                if event.kind=="throw_start":starts+=1
                if event.kind=="throw_land":landings+=1
            tick_in_clip+=1
    for i in 2:actors[i].present(sim.fighters[i],1.0/30.0,sim.hitstop>0,false,sim.fighters[1-i].x)
    Motion.correct_contacts(actors[0],actors[1])
    label.text="%s  →  %s | SHOULDER THROW\nActual hero meshes · legal grab input · shared simulation clock\nSource frame %.1f | victim HP %d"%[["ZIP","RIVET","HUSH","LOOP"][clip],["ZIP","RIVET","HUSH","LOOP"][(clip+1)%4],float(sim.fighters[0].get("paired_throw",{}).get("source_frame",61)),sim.fighters[1].health]
    if tick_in_clip>=150:_next_clip()
    return false
