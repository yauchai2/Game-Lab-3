extends Node3D
## Original faceted, articulated 3D actors. No video planes or fighter substitutions.
const INK=Color("12101d")
const PURPLE=Color("6936a0")
const ORANGE=Color("ed7827")
const CYAN=Color("44ffdd")
var machine:Node3D
var chassis:Node3D
var dealer:Node3D
var body:Node3D
var head:Node3D
var left_arm:Node3D
var right_arm:Node3D
var left_forearm:Node3D
var right_forearm:Node3D
var shoes:Array[Node3D]=[]
var left_hand:Node3D
var right_hand:Node3D
var left_leg:Node3D
var right_leg:Node3D
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
var reward_id:="speed"

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

func polygon(parent:Node3D,points:Array,color:Color) -> MeshInstance3D:
    var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1,points.size()-1):
        for v in [points[0],points[i],points[i+1]]:st.add_vertex(v)
    st.generate_normals()
    var node:=mesh(parent,st.commit(),Vector3.ZERO,color,false,true)
    var paint:=mat(color,true).duplicate() as StandardMaterial3D;paint.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=paint
    return node

func loft(parent:Node3D,rows:Array,color:Color) -> MeshInstance3D:
    var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(rows.size()-1):
        for i in 8:
            var a:=TAU*(i+.5)/8;var b:=TAU*(i+1.5)/8
            var r:Vector4=rows[j];var n:Vector4=rows[j+1]
            var p:=[Vector3(cos(a)*r.y,r.x,sin(a)*r.z+r.w),Vector3(cos(b)*r.y,r.x,sin(b)*r.z+r.w),Vector3(cos(b)*n.y,n.x,sin(b)*n.z+n.w),Vector3(cos(a)*n.y,n.x,sin(a)*n.z+n.w)]
            # Outward-facing winding, individual triangles retain hard normals.
            for k in [0,2,1,0,3,2]:st.add_vertex(p[k])
    st.generate_normals();return mesh(parent,st.commit(),Vector3.ZERO,color,true)

func icon(parent:Node3D,id:String,at:Vector3,size:Vector2) -> MeshInstance3D:
    var shape:=QuadMesh.new();shape.size=size
    var node:=mesh(parent,shape,at,Color.WHITE)
    var m:=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.albedo_texture=load("res://assets/ability_draw/"+id+".png");m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;node.material_override=m;return node

func build() -> void:
    machine=Node3D.new();machine.name="PhysicalSlotMachine";add_child(machine)
    chassis=Node3D.new();chassis.name="SpringMountedChassis";machine.add_child(chassis)
    box(chassis,Vector3(0,1.35,0),Vector3(1.9,1.88,.95),ORANGE,true)
    box(chassis,Vector3(0,2.28,-.02),Vector3(1.96,.17,1.02),Color("ff9b3a"),true)
    box(chassis,Vector3(0,.45,0),Vector3(2.02,.20,1.03),INK)
    for x in [-.79,.79]:
        box(chassis,Vector3(x,1.73,.515),Vector3(.11,1.04,.17),Color("4a3338"),true)
    box(chassis,Vector3(0,1.73,.505),Vector3(1.55,1.0,.08),INK)
    for i in 3:
        var reel:=Node3D.new();reel.position=Vector3((i-1)*.49,1.73,.23);chassis.add_child(reel);reels.append(reel)
        var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for j in 64:
            var a:=TAU*j/64;var b:=TAU*(j+1)/64
            var points:=[Vector3(-.217,sin(a)*.48,cos(a)*.48),Vector3(.217,sin(a)*.48,cos(a)*.48),Vector3(.217,sin(b)*.48,cos(b)*.48),Vector3(-.217,sin(b)*.48,cos(b)*.48)]
            var uv:=[Vector2(0,1.0-float(j)/64),Vector2(1,1.0-float(j)/64),Vector2(1,1.0-float(j+1)/64),Vector2(0,1.0-float(j+1)/64)]
            for k in [0,1,2,0,2,3]:st.set_uv(uv[k]);st.add_vertex(points[k])
        st.generate_normals()
        var drum:=mesh(reel,st.commit(),Vector3.ZERO,Color.WHITE)
        var rm:=StandardMaterial3D.new();rm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;rm.albedo_texture=load("res://assets/ability_draw/reels.png");rm.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;rm.cull_mode=BaseMaterial3D.CULL_DISABLED;drum.material_override=rm
        box(chassis,Vector3((i-1)*.49,2.20,.61),Vector3(.36,.055,.07),CYAN,false,true)
    box(chassis,Vector3(0,2.23,.54),Vector3(1.6,.12,.20),INK)
    box(chassis,Vector3(0,1.22,.58),Vector3(1.6,.10,.18),INK)
    for x in [-.245,.245]:box(chassis,Vector3(x,1.72,.70),Vector3(.045,1.0,.055),INK)
    box(chassis,Vector3(.18,.82,.505),Vector3(.96,.48,.13),INK,true)
    box(chassis,Vector3(.18,.88,.59),Vector3(.72,.06,.06),CYAN,false,true)
    hatch=Node3D.new();hatch.position=Vector3(.18,1.02,.59);chassis.add_child(hatch)
    box(hatch,Vector3(0,-.14,0),Vector3(1.0,.32,.085),Color("8f4b39"),true)
    box(chassis,Vector3(.18,.56,.62),Vector3(1.03,.06,.30),Color("69454b"),true)
    for x in [-.84,.84]:
        box(chassis,Vector3(x,.69,.51),Vector3(.18,.45,.06),Color("ffc834"))
        for i in 3:
            var stripe:=box(chassis,Vector3(x,.52+i*.14,.55),Vector3(.21,.075,.018),INK);stripe.rotation.z=.5
    # Side speaker and exposed grill.
    box(chassis,Vector3(-1.02,1.18,0),Vector3(.22,.8,.74),Color("55414b"),true)
    for i in 5:
        for j in 4:box(chassis,Vector3(-1.145,.91+i*.12,-.24+j*.16),Vector3(.018,.045,.065),INK)
    box(chassis,Vector3(.93,1.03,.51),Vector3(.28,.38,.08),Color("55414b"),true)
    for i in 4:box(chassis,Vector3(.93,.91+i*.075,.56),Vector3(.21,.025,.025),INK)
    var lever:=cylinder(chassis,Vector3(1.03,1.84,.03),.06,.90,INK);lever.rotation.z=-.15
    box(chassis,Vector3(1.10,2.32,.03),Vector3(.23,.24,.23),Color("ffd13b"),true)
    # Bolts, chipped paint, tape and original crown graphic are physical decals.
    for x in [-.86,.86]:
        for y in [1.2,2.24]:
            var bolt:=cylinder(chassis,Vector3(x,y,.548),.055,.025,Color("9d9b93"),6);bolt.rotation.x=PI/2
    for i in 19:
        var x:float=sin(i*13.4)*.78;var y:float=.61+fmod(i*.37,1.55)
        if y>1.20 and absf(x)<.76:continue
        var chip:=box(chassis,Vector3(x,y,.492),Vector3(.045+fmod(i*.04,.1),.10,.008),Color("76505e"));chip.rotation.z=i*.9
    polygon(chassis,[Vector3(-.70,.91,.55),Vector3(-.69,1.13,.55),Vector3(-.54,1.00,.55),Vector3(-.46,1.17,.55),Vector3(-.40,.97,.55),Vector3(-.23,1.11,.55),Vector3(-.26,.89,.55)],Color("f4e4cb"))
    for x in [-.70,.70]:
        for z in [-.30,.30]:
            var wheel:=Node3D.new();wheel.position=Vector3(x,.24,z);machine.add_child(wheel);wheels.append(wheel)
            var tire:=cylinder(wheel,Vector3.ZERO,.235,.15,INK,10, -1,true);tire.rotation.z=PI/2
            var hub:=cylinder(wheel,Vector3(signf(x)*.09,0,0),.115,.025,Color("8d847d"),6);hub.rotation.z=PI/2
    _build_dealer()
    var card:=QuadMesh.new();card.size=Vector2(6,6)
    reward_backdrop=mesh(self,card,Vector3(-.8,1.9,.9),Color("4f1b80"),false,true);reward_backdrop.hide()
    reward=Node3D.new();reward.name="PhysicalAbilityCapsule";add_child(reward)
    cylinder(reward,Vector3.ZERO,.19,.63,CYAN,6,-1,true)
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

func _limb(parent:Node3D,color:Color,width:float) -> Node3D:
    var root:=Node3D.new();parent.add_child(root)
    cylinder(root,Vector3.ZERO,width,1.0,color,6,width*.77,true)
    return root

func _hand(parent:Node3D) -> Node3D:
    var hand:=Node3D.new();parent.add_child(hand)
    box(hand,Vector3.ZERO,Vector3(.36,.19,.31),Color("302b3d"),true)
    for i in 4:
        box(hand,Vector3(-.135+i*.09,-.015,.20),Vector3(.072,.14,.17),Color("514858"),true)
        box(hand,Vector3(-.135+i*.09,-.025,.28),Vector3(.075,.12,.065),Color("262331"))
    var thumb:=box(hand,Vector3(.22,-.02,.075),Vector3(.13,.16,.22),Color("403747"),true);thumb.rotation.y=-.65
    return hand

func _build_dealer() -> void:
    dealer=Node3D.new();dealer.name="MaskedDealer";add_child(dealer)
    body=Node3D.new();dealer.add_child(body)
    loft(body,[Vector4(1.06,.46,.30,0),Vector4(1.62,.56,.33,0),Vector4(2.11,.65,.30,0),Vector4(2.27,.32,.22,0)],PURPLE)
    polygon(body,[Vector3(-.04,1.12,.32),Vector3(.08,2.22,.25),Vector3(.15,2.10,.31),Vector3(.06,1.12,.34)],Color("332342"))
    box(body,Vector3(-.33,1.40,.32),Vector3(.33,.10,.03),Color("3a2452"))
    box(body,Vector3(.32,1.40,.32),Vector3(.33,.10,.03),Color("3a2452"))
    for x in [-.12,.12]:box(body,Vector3(x,2.01,.35),Vector3(.025,.34,.025),Color("ddcd99"))
    # Angular sprayed shoulder mark.
    polygon(body,[Vector3(-.55,1.95,.29),Vector3(-.48,2.15,.29),Vector3(-.39,2.04,.34),Vector3(-.30,2.19,.32),Vector3(-.29,1.91,.36),Vector3(-.39,1.86,.35)],Color("f4c832"))
    head=Node3D.new();head.position=Vector3(0,2.22,0);body.add_child(head)
    loft(head,[Vector4(0,.28,.25,0),Vector4(.27,.43,.34,0),Vector4(.66,.37,.28,-.03),Vector4(.78,.12,.12,-.04)],Color("48266d"))
    polygon(head,[Vector3(-.29,.08,.30),Vector3(-.34,.46,.32),Vector3(-.15,.69,.26),Vector3(.20,.65,.27),Vector3(.35,.39,.31),Vector3(.17,.04,.30)],INK)
    polygon(head,[Vector3(-.22,.22,.345),Vector3(-.24,.50,.345),Vector3(-.10,.63,.325),Vector3(.19,.56,.345),Vector3(.26,.35,.36),Vector3(.08,.10,.37)],Color("e8dfbf"))
    polygon(head,[Vector3(.08,.10,.371),Vector3(.26,.35,.361),Vector3(.19,.56,.346),Vector3(.04,.45,.38)],Color("b3ad9d"))
    polygon(head,[Vector3(-.19,.48,.425),Vector3(-.09,.39,.425),Vector3(-.045,.46,.425),Vector3(-.13,.57,.425)],INK)
    polygon(head,[Vector3(-.15,.25,.425),Vector3(-.10,.20,.425),Vector3(-.04,.31,.425),Vector3(-.12,.40,.425)],INK)
    polygon(head,[Vector3(.04,.36,.425),Vector3(.22,.40,.425),Vector3(.17,.46,.425),Vector3(.02,.42,.425)],INK)
    polygon(head,[Vector3(.08,.39,.435),Vector3(.19,.415,.435),Vector3(.16,.44,.435),Vector3(.07,.42,.435)],CYAN)
    left_arm=_limb(body,PURPLE,.26);right_arm=_limb(body,PURPLE,.27)
    left_forearm=_limb(body,Color("51297c"),.23);right_forearm=_limb(body,Color("51297c"),.24)
    left_hand=_hand(body);right_hand=_hand(body)
    left_leg=_limb(dealer,Color("302b3d"),.26);right_leg=_limb(dealer,Color("302b3d"),.27)
    for x in [-.31,.31]:
        var shoe:=Node3D.new();dealer.add_child(shoe);shoes.append(shoe)
        box(shoe,Vector3(x,.13,.19),Vector3(.49,.22,.80),Color("dfbd43"),true)
        box(shoe,Vector3(x,.045,.20),Vector3(.51,.09,.82),Color("e9dfb8"),true)
        for z in [.15,.27,.39]:box(shoe,Vector3(x,.255,z),Vector3(.31,.028,.025),INK)
    token=Node3D.new();left_hand.add_child(token);token.position=Vector3(0,.19,.15)
    var coin:=cylinder(token,Vector3.ZERO,.20,.055,Color("ffc13b"),8,-1,true);coin.rotation.x=PI/2
    icon(token,"speed",Vector3(0,0,.039),Vector2(.26,.26))

func limb_at(node:Node3D,a:Vector3,b:Vector3) -> void:
    node.position=(a+b)*.5
    node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
    node.scale=Vector3(1,a.distance_to(b),1)

func pose(t:float,entry:Vector3,spin:float,outcome:String,reveal:float,reduced:bool) -> void:
    machine.position=entry
    var brake:=sin(clampf((t-.97)/.25,0,1)*PI)
    machine.position.y+=brake*.20
    var rolling:=smoothstep(.16,.32,t)*(1-smoothstep(.95,1.08,t))
    var direction:=signf(entry.x) if absf(entry.x)>.01 else -1.0
    machine.rotation.z=direction*rolling*.09+sin(entry.x*18)*rolling*.018
    chassis.position.y=-maxf(0,1-absf(t-1.40)/.12)*.09
    chassis.rotation.z=sin(t*49)*maxf(0,1-absf(t-1.40)/.32)*.035
    for wheel in wheels:wheel.rotation.x=-entry.x/.235
    var drag:=rolling
    dealer.position=entry+Vector3(-1.05,0,-.42)
    dealer.rotation.z=drag*-.10
    body.rotation.x=drag*.18
    head.rotation.z=-.13+sin(floor(t*12)/12*1.6)*.045
    var stepping:=sin(entry.x*4.5)*drag*.13
    limb_at(left_leg,Vector3(-.27,1.20,0),Vector3(-.31,.24,.06+stepping))
    limb_at(right_leg,Vector3(.27,1.20,0),Vector3(.31,.24,.06-stepping))
    shoes[0].position.z=stepping;shoes[1].position.z=-stepping
    var hand_a:=Vector3(.2,1.85,.62)
    var hand_b:=Vector3(1.0,1.45,.12)
    if t>=1.2 and t<1.95:
        hand_b=Vector3(1.0,2.43,.45)
        hand_b.y+=maxf(0,1-absf(t-1.29)/.12)*.5
    if t>=1.95:
        hand_a=Vector3(.22,2.08,.95)
        hand_b=Vector3(.75,1.7,.45)
    if reveal>0:
        body.rotation.x=-sin(minf(1,reveal)*PI)*.20
        hand_b=Vector3(1.0,1.8,.65+sin(reveal*PI)*.65)
    var elbow_a:=Vector3(-.56,1.78,.33) if t>=1.95 else Vector3(-.30,1.70,.26)
    var elbow_b:=Vector3(.86,1.83,-.08)
    limb_at(left_arm,Vector3(-.44,2.02,0),elbow_a)
    limb_at(left_forearm,elbow_a,hand_a)
    limb_at(right_arm,Vector3(.47,2.02,0),elbow_b)
    limb_at(right_forearm,elbow_b,hand_b)
    left_hand.position=hand_a;right_hand.position=hand_b
    left_hand.scale=Vector3.ONE*1.20;right_hand.scale=Vector3.ONE*1.40
    left_hand.rotation.x=-.15 if t>=1.95 else -.9
    right_hand.rotation.x=-.9 if t<1.95 else -.15
    token.visible=t>=1.95 and t<2.55
    var target_index:int={"speed":0,"guard":1,"charge":2}.get(outcome,0)
    for i in 3:
        # v=.125 is the first symbol centre at the visible front of each drum.
        var symbol_index:int=i if t<2.55 else target_index
        var target:float=-TAU*(.125+symbol_index*.25)
        var turning:float=pow(maxf(0,1-spin/(.60+i*.13)),3)*TAU*(4+i) if spin>=0 else 0.0
        reels[i].rotation.x=target+turning
    hatch.rotation.x=-minf(1,reveal*3)*1.1
    reward.visible=reveal>0
    reward.position=Vector3(.18,1.02,.65)+Vector3(0,sin(minf(reveal,1)*PI)*1.9+reveal*.3,reveal*1.9)
    reward.rotation=Vector3(.13,reveal*2.1,-.15+reveal*.24)
    if reward_id!=outcome:
        reward_id=outcome
        (reward_icon.material_override as StandardMaterial3D).albedo_texture=load("res://assets/ability_draw/"+outcome+".png")
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
