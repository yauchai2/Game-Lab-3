extends Node3D
## Generated arena and simulation-owned hazard presentation; no gameplay writes.
var session:Node3D
var environment:Environment
var marks:Array[MeshInstance3D]=[]
var hints:Array[Label3D]=[]
var crates:Array[MeshInstance3D]=[]
func setup(owner_session:Node3D,sector:int) -> void:
    session=owner_session
    var arena:Node3D=load("res://assets/campaign/generated/district_%d.glb"%sector).instantiate();add_child(arena)
    paint(arena)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,-35,0);light.light_energy=1.1;add_child(light)
    environment=Environment.new();environment.background_mode=Environment.BG_COLOR
    environment.background_color=[Color("b02070"),Color("32334b"),Color("24273b"),Color("8b4a52"),Color("261a38"),Color("ca0061")][sector]
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a6a5c0");environment.ambient_light_energy=.8
    for i in 2:
        var crate:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=Vector3(.8,.8,.8);crate.mesh=shape
        var mat:=StandardMaterial3D.new();mat.albedo_color=Color("d5bb39");mat.roughness=1;crate.material_override=mat;add_child(crate);crates.append(crate)
    for i in 4:
        var mesh:=MeshInstance3D.new();mesh.mesh=BoxMesh.new();var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mesh.material_override=mat;add_child(mesh);marks.append(mesh)
        var hint:=Label3D.new();hint.font_size=42;hint.pixel_size=.012;hint.billboard=BaseMaterial3D.BILLBOARD_ENABLED;hint.outline_size=8;add_child(hint);hints.append(hint)
func _process(_delta:float) -> void:
    if not is_instance_valid(session) or not session.sim.campaign_enabled:return
    for i in crates.size():
        crates[i].visible=i<session.sim.campaign_props.size() and int(session.sim.campaign_props[i].hp)>0
        if i<session.sim.campaign_props.size():crates[i].position=Vector3(float(session.sim.campaign_props[i].x),.42,3)
    var zones:Array=session.sim.campaign_hazards
    for i in marks.size():
        marks[i].visible=i<zones.size();hints[i].visible=i<zones.size()
        if i>=zones.size():continue
        var zone:Dictionary=zones[i];var active:bool=int(zone.age)>=int(zone.warn)
        var x:float=float(zone.bolt_x) if zone.kind=="bolt" and active else float(zone.x)
        marks[i].position=Vector3(x,1.0 if zone.kind=="bolt" and active else .035,3)
        (marks[i].mesh as BoxMesh).size=Vector3(.45,.4,.45) if zone.kind=="bolt" and active else Vector3(float(zone.half)*2,.06,1.3)
        (marks[i].material_override as StandardMaterial3D).albedo_color=Color(1,.03,.4,.85) if active else Color(1,.8,.05,.40)
        hints[i].text="MOVE" if zone.kind in ["slam","jammer","street"] else ("JUMP" if zone.kind=="sweep" else "PARRY / DODGE")
        hints[i].position=Vector3(float(zone.x),.6,3);hints[i].modulate=Color("ffe15b")
static func paint(node:Node) -> void:
    for mesh in node.find_children("*","MeshInstance3D",true,false):
        for surface in mesh.mesh.get_surface_count():
            var original:Material=mesh.get_active_material(surface)
            var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/sample_toon.gdshader")
            mat.set_shader_parameter("base_color",original.albedo_color if original is StandardMaterial3D else Color.WHITE)
            mat.set_shader_parameter("bands",2);mat.set_shader_parameter("shadow_tint",Vector3(.40,.39,.58));mesh.set_surface_override_material(surface,mat)
