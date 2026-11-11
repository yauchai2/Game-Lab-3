extends RefCounted
## Original generated sprite art, animated by discrete attack/release stages.
const ACTIONS=preload("res://assets/vfx/street_actions.png")
var signatures:Texture2D
var textures:Dictionary={}
const MOVE_CELLS={"jab":0,"cross":1,"launcher":2,"meteor":3,"air_counter":5,"grab":6,"heavy":8,"finisher":15,"air_jab":0,"air_kick":14,"air_finisher":15,"special":13,"overdrive":13}
const KIND_CELLS={"parry":4,"block":9,"guard_break":8,"grab_tell":6,"speed":7,"dust":10,"ground_ring":10,"slam_crater":11,"charge":12,"cannon_charge":12,"cannon_blast":13,"wave":13,"surge_arc":14,"wall":8}
func tile(texture:Texture2D,index:int,columns:int,rows:int) -> AtlasTexture:
    var key:String=str(texture.get_instance_id())+"/"+str(index)
    if textures.has(key):return textures[key]
    var col:int=index%columns
    var row:int=floori(float(index)/columns)
    var x0:int=floori(float(col)*texture.get_width()/columns)
    var y0:int=floori(float(row)*texture.get_height()/rows)
    var x1:int=floori(float(col+1)*texture.get_width()/columns)
    var y1:int=floori(float(row+1)*texture.get_height()/rows)
    var region:=AtlasTexture.new();region.atlas=texture;region.region=Rect2(x0,y0,x1-x0,y1-y0)
    textures[key]=region
    return region
func sprite_for(effect:Dictionary) -> Texture2D:
    if effect.get("move","") in ["special","overdrive"] and effect.kind in ["swing","release","cannon_blast","wave"]:
        if signatures==null and ResourceLoader.exists("res://assets/vfx/fighter_signatures.png"):signatures=load("res://assets/vfx/fighter_signatures.png")
        if signatures:return tile(signatures,effect.get("character",0)+(4 if effect.move=="overdrive" else 0),4,2)
    if effect.kind in ["swing","hit","release"]:
        return tile(ACTIONS,MOVE_CELLS.get(effect.get("move","jab"),0),4,4)
    if KIND_CELLS.has(effect.kind):return tile(ACTIONS,KIND_CELLS[effect.kind],4,4)
    return null
func draw(canvas:Control,session:Node3D,effect:Dictionary) -> void:
    if effect.age<0:return
    var texture:Texture2D=sprite_for(effect)
    if texture==null:return
    if session.reduced_effects and effect.kind not in ["hit","parry","block","guard_break","release"]:return
    # A single impact sprite per contact; procedural geometry still supplies paths/beam anchors.
    if effect.kind=="hit" and effect.age>.10:return
    var t:float=clampf(effect.age/effect.life,0,1)
    var stage:int=mini(3,floori(t*4))
    var extent:float=([96.0,152.0,128.0,72.0][stage])*(.60 if session.reduced_effects else 1.0)
    if effect.get("move","") in ["special","overdrive"]:extent*=1.65
    if effect.kind in ["dust","speed","block"]:extent*=.7
    var at:Vector2=session.project(effect.at)
    at=at.snapped(Vector2(2,2))
    var face:float=effect.get("face",1)
    var ui_scale:Vector2=canvas.size/Vector2(1280,720)
    canvas.draw_set_transform(at*ui_scale,0,ui_scale*Vector2(-1 if face<0 else 1,1))
    canvas.draw_texture_rect(texture,Rect2(-extent*.5,-extent*.5,extent,extent),false,Color(1,1,1,1.0 if stage<3 else .65))
    canvas.draw_set_transform(Vector2.ZERO,0,canvas.size/Vector2(1280,720))
