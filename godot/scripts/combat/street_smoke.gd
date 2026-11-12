extends Node3D
## Bounded world-space smoke: vents/roofs plus a twelve-puff impact pool.
const SHADER=preload("res://shaders/street_smoke.gdshader")
var clock:=0.0
var ambient:Array=[]
var impacts:Array=[]
var serial:=0
var reaction_cd:=0.0
static func puff(color:Color,seed_value:float) -> MeshInstance3D:
    var node:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(2,2);node.mesh=quad
    var material:=ShaderMaterial.new();material.shader=SHADER
    material.set_shader_parameter("tint",color);material.set_shader_parameter("seed",seed_value)
    node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return node
func _ready() -> void:
    name="StreetSteamAndSmoke"
    for i in 18:
        var side:float=-1.0 if i%2==0 else 1.0
        var roof:bool=i>=12
        var at:=Vector3(side*(3.8 if not roof else 10.0),18.0 if roof else .5,2.0-(i%6)*6.0)
        var node:=puff(Color("c4afd0") if not roof else Color("97859f"),i*1.7)
        add_child(node);ambient.append({"node":node,"at":at,"size":1.3+(i%3)*.5,"phase":i*.37})
    for i in 12:
        var node:=puff(Color("ac9bb2"),50+i);add_child(node);node.hide()
        impacts.append({"node":node,"age":2.0,"at":Vector3.ZERO,"life":.65,"phase":i*.7})
func advance(delta:float,paused:bool,reduced:bool) -> void:
    if paused:return
    clock+=maxf(0,delta);reaction_cd=maxf(0,reaction_cd-delta)
    for i in ambient.size():
        var item:Dictionary=ambient[i];var node:MeshInstance3D=item.node
        node.visible=not reduced or i%3==0
        var cycle:float=fposmod(clock*.16+item.phase,1.0)
        node.position=item.at+Vector3(sin(clock*.28+i)*.5,cycle*3.6,0)
        node.scale=Vector3.ONE*item.size*(.8+cycle*.65)
        node.material_override.set_shader_parameter("age",clock+item.phase)
        node.material_override.set_shader_parameter("opacity",(.13 if reduced else .52)*sin(cycle*PI))
    for item in impacts:
        item.age+=delta
        item.node.visible=item.age<item.life and not reduced
        if not item.node.visible:continue
        var u:float=item.age/item.life
        item.node.position=item.at+Vector3(sin(item.phase)*u*.7,u*.65,cos(item.phase)*u*.25)
        item.node.scale=Vector3.ONE*(.35+u*.7)
        item.node.material_override.set_shader_parameter("age",item.age)
        item.node.material_override.set_shader_parameter("opacity",sin(u*PI)*.30)
func react(at:Vector3) -> void:
    if reaction_cd>0:return
    reaction_cd=.16
    for i in 3:
        var item:Dictionary=impacts[serial%impacts.size()];serial+=1
        item.age=0.0;item.at=at+Vector3((i-1)*.30,.25,-.8)
func clear_impacts() -> void:
    reaction_cd=0.0
    for item in impacts:item.age=2.0;item.node.hide()
