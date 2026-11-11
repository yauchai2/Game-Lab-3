extends Node3D
## User-uploaded Tripo actors plus independent mechanical props. No video planes.
const Rewards=preload("res://scripts/combat/ability_draw/rewards.gd")
const INK=Color("12101d")
const CYAN=Color("44ffdd")
var machine:Node3D
var chassis:Node3D
var dealer:Node3D
var dealer_rig:Node3D
var shell_model:Node3D
var lever:Node3D
var entry_start_x:=0.0
var previous_source_time:=-1.0
var token:Node3D
var reward:Node3D
var reels:Array[Node3D]=[]
var wheels:Array[Node3D]=[]
var hatch:Node3D
var shards:Array[MeshInstance3D]=[]
var dust:Array[MeshInstance3D]=[]
var ring:MeshInstance3D
var reward_icon:MeshInstance3D
var reward_backdrop:MeshInstance3D
var mats:Dictionary={}
var reward_id:=""
var reward_body:MeshInstance3D
var reel_materials:Array[StandardMaterial3D]=[]

func mat(color:Color,unlit:=false) -> StandardMaterial3D:
    var key:=str(color)+str(unlit)
    if mats.has(key):return mats[key]
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=1.0
    if unlit:m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mats[key]=m;return m

func mesh(parent:Node3D,shape:Mesh,at:Vector3,color:Color,edge:=false,unlit:=false) -> MeshInstance3D:
    var node:=MeshInstance3D.new();node.mesh=shape;node.position=at;node.material_override=mat(color,unlit);parent.add_child(node)
    if edge:
        var outline:=MeshInstance3D.new();outline.mesh=shape
        var black:=mat(INK,true).duplicate() as StandardMaterial3D;black.cull_mode=BaseMaterial3D.CULL_FRONT
        outline.material_override=black;outline.scale=Vector3.ONE*1.045;node.add_child(outline)
    return node

func box(parent:Node3D,at:Vector3,size:Vector3,color:Color,edge:=false,unlit:=false) -> MeshInstance3D:
    var shape:=BoxMesh.new();shape.size=size;return mesh(parent,shape,at,color,edge,unlit)

func cylinder(parent:Node3D,at:Vector3,radius:float,height:float,color:Color,segments:=8,top:=-1.0,edge:=false) -> MeshInstance3D:
    var shape:=CylinderMesh.new();shape.top_radius=radius if top<0 else top;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=segments;shape.rings=1
    return mesh(parent,shape,at,color,edge)

func icon(parent:Node3D,id:String,at:Vector3,size:Vector2) -> MeshInstance3D:
    var shape:=QuadMesh.new();shape.size=size
    var node:=mesh(parent,shape,at,Color.WHITE)
    var m:=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.albedo_texture=load("res://assets/ability_draw/"+id+".png");m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;node.material_override=m;return node

func build() -> void:
    _build_machine()
    _build_dealer()
    var card:=QuadMesh.new();card.size=Vector2(12,8)
    reward_backdrop=mesh(self,card,Vector3(-.8,1.9,.9),Color("090b0e"),false,true);reward_backdrop.hide()
    reward=Node3D.new();reward.name="PhysicalAbilityCapsule";add_child(reward)
    reward_body=cylinder(reward,Vector3.ZERO,.19,.63,CYAN,6,-1,true)
    for y in [-.37,.37]:
        cylinder(reward,Vector3(0,y,0),.25,.14,Color("ded1a8"),6,-1,true)
        cylinder(reward,Vector3(0,y+signf(y)*.07,0),.16,.04,INK,6)
    reward_icon=icon(reward,"speed",Vector3(0,0,.204),Vector2(.25,.46))
    for y in [-.22,.22]:box(reward,Vector3(0,y,.18),Vector3(.28,.025,.025),Color("edffef"),false,true)
    var torus:=TorusMesh.new();torus.inner_radius=.92;torus.outer_radius=1.0;torus.rings=24;torus.ring_segments=6
    ring=mesh(self,torus,Vector3.ZERO,CYAN,false,true)
    for i in 24:
        var shard:=box(self,Vector3.ZERO,Vector3(.04,.16,.03),CYAN,false,true);shards.append(shard)
    for i in 20:
        var shape:=SphereMesh.new();shape.radius=.23;shape.height=.37;shape.radial_segments=6;shape.rings=2
        dust.append(mesh(self,shape,Vector3.ZERO,Color("b0a1b9")))

func _build_machine() -> void:
    machine=Node3D.new();machine.name="PhysicalSlotMachine";add_child(machine)
    chassis=Node3D.new();chassis.name="SpringMountedChassis";machine.add_child(chassis)
    shell_model=preload("res://assets/ability_draw/source/tripo_convert_275dc57f-e328-47e0-89e5-10195d3209c4.glb").instantiate()
    shell_model.name="OriginalTripoCabinet";shell_model.scale=Vector3.ONE*2.0;shell_model.position=Vector3(0,.40,0);chassis.add_child(shell_model)
    preload("res://scripts/combat/ability_draw/asset_materials.gd").style(shell_model,true)
    # Real drums are inserted in the uploaded shell's dark recessed front bay.
    for i in 3:
        var reel:=Node3D.new();reel.position=Vector3((i-1)*.335+.01,1.72,-.265);chassis.add_child(reel);reels.append(reel)
        var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for j in 64:
            var a:=TAU*j/64;var b:=TAU*(j+1)/64
            var points:=[Vector3(-.155,sin(a)*.365,cos(a)*.365),Vector3(.155,sin(a)*.365,cos(a)*.365),Vector3(.155,sin(b)*.365,cos(b)*.365),Vector3(-.155,sin(b)*.365,cos(b)*.365)]
            var uv:=[Vector2(0,1.0-float(j)/64),Vector2(1,1.0-float(j)/64),Vector2(1,1.0-float(j+1)/64),Vector2(0,1.0-float(j+1)/64)]
            for k in [0,1,2,0,2,3]:st.set_uv(uv[k]);st.add_vertex(points[k])
        st.generate_normals()
        var drum:=mesh(reel,st.commit(),Vector3.ZERO,Color.WHITE)
        var rm:=StandardMaterial3D.new();rm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;rm.albedo_texture=load("res://assets/ability_draw/reels.png");rm.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;rm.cull_mode=BaseMaterial3D.CULL_DISABLED;drum.material_override=rm;reel_materials.append(rm)
    for x in [-.1575,.1775]:box(chassis,Vector3(x,1.72,.095),Vector3(.025,.73,.025),INK)
    hatch=Node3D.new();hatch.name="IndependentHingedFlap";hatch.position=Vector3(.10,.99,.53);chassis.add_child(hatch)
    box(hatch,Vector3(0,-.13,0),Vector3(.63,.26,.05),Color("80513f"),true)
    lever=Node3D.new();lever.name="IndependentLeverPivot";lever.position=Vector3(1.02,1.55,0);chassis.add_child(lever)
    var pivot:=cylinder(lever,Vector3.ZERO,.11,.06,Color("57515a"),8);pivot.rotation.z=PI/2
    cylinder(lever,Vector3(0,.35,0),.045,.70,Color("bdb7a0"),6)
    box(lever,Vector3(0,.76,0),Vector3(.24,.25,.23),Color("ffd13b"),true)
    var grip:=Node3D.new();grip.name="DragGrip";grip.position=Vector3(-1.06,1.72,-.40);chassis.add_child(grip)
    cylinder(grip,Vector3.ZERO,.045,.44,INK,6)
    for x in [-.70,.70]:
        for z in [-.43,.43]:
            var wheel:=Node3D.new();wheel.name="IndependentWheel";wheel.position=Vector3(x,.235,z);machine.add_child(wheel);wheels.append(wheel)
            var tire:=cylinder(wheel,Vector3.ZERO,.235,.15,INK,10,-1,true);tire.rotation.z=PI/2
            var hub:=cylinder(wheel,Vector3(signf(x)*.09,0,0),.115,.025,Color("8d847d"),6);hub.rotation.z=PI/2

func _build_dealer() -> void:
    dealer=Node3D.new();dealer.name="MaskedDealer";add_child(dealer)
    dealer_rig=preload("res://scripts/combat/ability_draw/dealer_rig.gd").new();dealer.add_child(dealer_rig);dealer_rig.setup()
    token=Node3D.new();token.name="WristCarriedToken";add_child(token)
    var coin:=cylinder(token,Vector3.ZERO,.20,.055,Color("ffc13b"),8,-1,true);coin.rotation.x=PI/2
    icon(token,"speed",Vector3(0,0,.039),Vector2(.26,.26))

func pose(t:float,entry:Vector3,spin:float,outcome:String,reveal:float,reduced:bool) -> void:
    if t<=.0001 or t<previous_source_time-.1:entry_start_x=entry.x
    previous_source_time=t
    machine.position=entry
    var brake:=sin(clampf((t-.97)/.25,0,1)*PI)
    machine.position.y+=brake*.20
    var rolling:=smoothstep(.16,.32,t)*(1-smoothstep(.95,1.08,t))
    var direction:=signf(entry.x) if absf(entry.x)>.01 else -1.0
    machine.rotation.z=direction*rolling*.09+sin(entry.x*18)*rolling*.018
    chassis.position.y=-maxf(0,1-absf(t-1.40)/.12)*.09
    chassis.rotation.z=sin(t*49)*maxf(0,1-absf(t-1.40)/.32)*.035
    for wheel in wheels:wheel.rotation.x=-entry.x/.235
    dealer.position=entry+Vector3(-1.25,0,-.48)
    var travel_direction:float=-signf(entry_start_x) if absf(entry_start_x)>.01 else 1.0
    dealer.rotation.z=-rolling*.10*travel_direction
    dealer_rig.sample(t,absf(entry.x-entry_start_x),rolling,reveal,chassis,travel_direction)
    token.global_transform=dealer_rig.token_transform
    lever.rotation.z=-sin(clampf((t-2.55)/.20,0,1)*PI)*.10
    token.visible=t>=1.95 and t<2.55
    var target_index:=3 # Four panels per drum; the hidden fourth panel is the selected core.
    for i in 3:
        # v=.125 is the first symbol centre at the visible front of each drum.
        var symbol_index:int=i if t<2.55 else target_index
        var target:float=-TAU*(.125+symbol_index*.25)
        reels[i].rotation.x=preload("res://scripts/combat/ability_draw/timing.gd").reel_angle(i,spin,target_index) if spin>=0 else target

    hatch.rotation.x=-minf(1,reveal*3)*1.1
    reward.visible=reveal>0
    reward.position=Vector3(.18,1.02,.65)+Vector3(0,sin(minf(reveal,1)*PI)*1.9+reveal*.3,reveal*1.9)
    reward.rotation=Vector3(.13,reveal*2.1,-.15+reveal*.24)
    if reward_id!=outcome:
        reward_id=outcome
        var entry_data:Dictionary=Rewards.item(outcome)
        var color:Color=entry_data.get("color",CYAN)
        reward_body.material_override=mat(color)
        ring.material_override=mat(color,true)
        for shard in shards:shard.material_override=mat(color,true)
        for reel_mat in reel_materials:reel_mat.albedo_texture=load("res://assets/ability_draw/pool/reels_"+outcome+".png")
        (reward_icon.material_override as StandardMaterial3D).albedo_texture=load("res://assets/ability_draw/pool/"+outcome+".png")
    for i in shards.size():
        var shard:MeshInstance3D=shards[i];var a:=TAU*i/shards.size()
        shard.visible=reveal>0 and reveal<.95 and not reduced
        shard.position=Vector3(.18,1.3,.5)+Vector3(cos(a)*2.4,sin(a)*1.7+1.2,cos(a*3)*.8)*reveal
        shard.rotation=Vector3(a,0,-a);shard.scale=Vector3.ONE*(1-reveal)*2
    for i in dust.size():
        var puff:MeshInstance3D=dust[i];var a:=i*2.399
        var life:=clampf((t-1.02)/.70,0,1)
        puff.visible=life>0 and life<1 and (not reduced or i<5)
        puff.position=entry+Vector3(cos(a)*life*1.9,.12+sin(life*PI)*.18,sin(a)*life*.70)
        puff.scale=Vector3.ONE*(.6+life*1.2)*(1-life)
    ring.visible=reveal>0 and reveal<.5 and not reduced
    ring.position=Vector3(.18,1.15,.7);ring.rotation.x=PI/2;ring.scale=Vector3.ONE*(.4+reveal*5)
