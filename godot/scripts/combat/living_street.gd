extends Node3D
## Bounded decorative life. Visual state only; never touches fight simulation.
const Toon=preload("res://shaders/sample_toon.gdshader")
const Shapes=preload("res://scripts/combat/street_art_meshes.gd")
var elapsed:=0.0
var sample_clock:=0.0
var actors:Array[Node3D]=[]
var trees:Array[Node3D]=[]
var papers:Array[MeshInstance3D]=[]
var lamps:Array[MeshInstance3D]=[]
var moving_car:Node3D
var reaction:=0.0
var reaction_cooldown:=0.0
var material_cache:Dictionary={}
var decoration_count:=0
func _ready() -> void:
    name="LivingStreet"
    var rng:=RandomNumberGenerator.new();rng.seed=20261110
    # Clusters stay off the central crossing; they have no collision bodies.
    for cluster in [Vector3(-5.3,.05,-1),Vector3(5.5,.05,-4),Vector3(-5.4,.05,-12),Vector3(5.3,.05,-18)]:
        for i in 7:
            var at:Vector3=cluster+Vector3(rng.randf_range(-.65,.65),0,rng.randf_range(-.8,.8))
            var trash:MeshInstance3D
            if i%3==0:
                var can:=CylinderMesh.new();can.radial_segments=6;can.top_radius=.07;can.bottom_radius=.065;can.height=.2
                trash=_mesh(can,at+Vector3(0,.1,0),Color("b2ba96") if i%2 else Color("c56543"))
            else:
                var paper:=BoxMesh.new();paper.size=Vector3(.18+rng.randf()*.12,.012,.16)
                trash=_mesh(paper,at,Color("d9cfa8") if i%2 else Color("a79274"));trash.rotation.y=rng.randf()*TAU
                if i==1:papers.append(trash)
    for spec in [[Vector3(-5.5,0,-2),.92],[Vector3(5.6,0,-11),1.0]]:
        var tree:=Node3D.new();tree.position=spec[0];tree.scale=Vector3.ONE*spec[1];add_child(tree);trees.append(tree)
        var trunk:=CylinderMesh.new();trunk.radial_segments=5;trunk.top_radius=.08;trunk.bottom_radius=.15;trunk.height=2.5
        var stem:=_mesh(trunk,Vector3(0,1.25,0),Color("785a43"),tree);stem.rotation.z=.06
        for i in 7:
            var angle:float=i*TAU/7
            var leaf:=_mesh(Shapes.crown(),Vector3(cos(angle)*.62,2.4+sin(i*1.9)*.35,sin(angle)*.5),[Color("547644"),Color("769146"),Color("3e6654")][i%3],tree)
            leaf.scale=Vector3(1.15,1.1,.95);leaf.rotation.y=angle
    for i in 4:
        var actor=preload("res://scripts/combat/fighter_visual.gd").new();add_child(actor);actor.setup(Color("b3aa88"),i)
        actor.position=Vector3(-5.25 if i%2==0 else 5.25,0,-5.0-i*5.2);actor.rotation.y=.5 if i%2==0 else -.8
        actor.model_scale*=.85;actor.model.scale=Vector3.ONE*actor.model_scale;actors.append(actor)
    moving_car=preload("res://scenes/VEH_CAR_A01.tscn").instantiate();moving_car.name="DistantRedCar";add_child(moving_car)
    moving_car.position=Vector3(-13,0,-42);moving_car.rotation.y=PI*.5
    moving_car.collision_layer=0;moving_car.collision_mask=0
    for mesh in moving_car.find_children("*","MeshInstance3D",true,false):
        var original:Material=mesh.get_active_material(0)
        if original is BaseMaterial3D:
            var paint:Material=original.duplicate(true)
            if paint.albedo_color.r>.4:paint.albedo_color=Color("a7473e")
            paint.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;mesh.material_override=paint
    for body in moving_car.find_children("*","CollisionObject3D",true,false):body.collision_layer=0;body.collision_mask=0
    for x in [-3.5,-2.3]:
        var cube:=BoxMesh.new();cube.size=Vector3(.16,.08,.035)
        lamps.append(_mesh(cube,Vector3(x,.68,-15.5),Color("bc493b")))
    # A pair of asymmetrical shop canopy lips adds a readable, folded silhouette.
    for side in [-1,1]:
        var canopy:=_mesh(BoxMesh.new(),Vector3(side*5.8,2.75,-4),Color("b96745"))
        canopy.scale=Vector3(1.25,.12,1.3);canopy.rotation.z=side*.045
func _material(color:Color) -> Material:
    var key:String=color.to_html()
    if material_cache.has(key):return material_cache[key]
    var m:=ShaderMaterial.new();m.shader=Toon;m.set_shader_parameter("base_color",color);m.set_shader_parameter("shadow_tint",Vector3(.35,.50,.58));material_cache[key]=m;return m
func _mesh(resource:Mesh,at:Vector3,color:Color,parent:Node3D=self) -> MeshInstance3D:
    var node:=MeshInstance3D.new();node.mesh=resource;node.position=at;node.material_override=_material(color);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);decoration_count+=1;return node
func react() -> void:
    if reaction_cooldown<=0:reaction=.55;reaction_cooldown=22.0
func advance(delta:float,paused:bool,reduced:bool) -> void:
    if paused:return
    elapsed+=delta;reaction=maxf(0,reaction-delta);reaction_cooldown=maxf(0,reaction_cooldown-delta)
    for i in trees.size():trees[i].rotation.z=sin(elapsed*1.7+i)*(.012 if reduced else .035)
    for i in papers.size():
        papers[i].rotation.z=sin(elapsed*1.5+i)*(.02 if reduced else .08)
        if reaction>0 and not reduced:papers[i].position.y=.05+sin(reaction*PI/.55)*.35
        else:papers[i].position.y=.05
    var phase:float=fmod(elapsed,36)
    moving_car.position.x=-13+phase*.85;moving_car.visible=phase<31
    for i in lamps.size():lamps[i].visible=fmod(elapsed+float(i)*.05,14)<.8 or fmod(elapsed,14)>1.2
    sample_clock+=delta
    if sample_clock<1.0/12:return
    sample_clock=0
    for i in actors.size():
        var a:Node3D=actors[i];var m=a.motions
        m.present({"character":i,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"guarding":false,"showcase":true},1.0/12,false)
        var t:float=elapsed+i*1.7
        # Wipe counter, drink, check watch and talk: distinct upper-body gestures.
        var direction:Vector3=m.model_forward*.5-m.model_up*.5
        if i==1:direction=m.model_up*.65+m.model_forward*.25
        if i==2:direction=m.model_forward*.8-m.model_up*.15
        if i==3:direction=m.model_forward+ m.model_up*sin(t)*.18
        m._aim_limb("RightArm","RightForeArm",direction,.9)
        m._aim_limb("LeftArm","LeftForeArm",-m.model_up+m.model_forward*.2,.9)
        a.model.rotation.z=(sin(t*.8)*.025 if not reduced else 0.0)+reaction*.2
