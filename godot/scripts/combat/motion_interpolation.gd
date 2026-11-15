extends RefCounted
## Render-only interpolation between committed simulation states. No prediction.
var previous:Dictionary={}
var alpha:=1.0
func clear() -> void:
    previous.clear();alpha=1.0
func key_for(f:Dictionary,side:int,squad:bool) -> String:
    return "p0" if side==0 else ("s%d"%int(f.get("squad_id",0)) if squad else "p1")
func remember(sim:RefCounted) -> void:
    var actors:Array=[sim.fighters[0]]
    if sim.squad_enabled:actors.append_array(sim.squad_members)
    else:actors.append(sim.fighters[1])
    for side in actors.size():
        var f:Dictionary=actors[side]
        previous[key_for(f,0 if side==0 else 1,sim.squad_enabled)]={"x":f.x,"y":f.y,"frame":f.frame,"state":f.state,"move":f.move,"character":f.character,"serial":f.get("service",{}).get("serial",0)}
func sample(f:Dictionary,key:String) -> Dictionary:
    var pose:Dictionary=f.duplicate()
    if not previous.has(key) or f.health<=0:return pose
    var old:Dictionary=previous[key]
    if old.character!=f.character or old.state!=f.state or old.move!=f.move or old.serial!=f.get("service",{}).get("serial",0):return pose
    if Vector2(old.x,old.y).distance_to(Vector2(f.x,f.y))>2.5:return pose
    pose.x=lerpf(float(old.x),float(f.x),alpha)
    pose.y=lerpf(float(old.y),float(f.y),alpha)
    if f.state=="attack" and f.frame>=old.frame and f.frame-old.frame<=2:
        pose.frame=lerpf(float(old.frame),float(f.frame),alpha)
    return pose
