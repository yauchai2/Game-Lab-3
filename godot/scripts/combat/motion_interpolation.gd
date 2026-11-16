extends RefCounted
## Render-only interpolation between committed simulation states. No prediction.
var previous:Dictionary={}
var alpha:=1.0
func clear() -> void:
    previous.clear();alpha=1.0
func key_for(f:Dictionary,side:int,squad:bool) -> String:
    return "p0" if side==0 else ("s%d"%int(f.get("squad_id",0)) if squad else "p1")
func remember(sim:RefCounted) -> void:
    var frozen:bool=sim.hitstop>0 or sim.exchange.active() or (sim.rally.active() and sim.rally.phase=="compress") or (sim.air_counter.active() and sim.air_counter.phase=="hold")
    var actors:Array=[sim.fighters[0]]
    if sim.squad_enabled:actors.append_array(sim.squad_members)
    else:actors.append(sim.fighters[1])
    for side in actors.size():
        var f:Dictionary=actors[side]
        previous[key_for(f,0 if side==0 else 1,sim.squad_enabled)]={"x":f.x,"y":f.y,"frame":f.frame,"state":f.state,"move":f.move,"character":f.character,"serial":f.get("service",{}).get("serial",0),"frozen":frozen}
func sample(f:Dictionary,key:String,interpolate_positions:=true) -> Dictionary:
    var pose:Dictionary=f.duplicate()
    if not previous.has(key) or f.health<=0:return pose
    var old:Dictionary=previous[key]
    if old.character==f.character and f.state=="idle" and old.state=="idle" and f.y<=.01 and old.y<=.01 and not old.get("frozen",false) and absf(f.x-old.x)<=2.5:
        # Command velocity can remain nonzero at an edge or behind a body.
        # Only animate the part that actually advanced along that command;
        # collision pushes must not become an unsolicited walking cycle.
        var direction:float=signf(f.vx)
        var observed:float=(f.x-old.x)*60.0*direction
        pose.vx=direction*minf(absf(f.vx),maxf(0.0,observed))
    if not interpolate_positions:return pose
    if old.character!=f.character or old.state!=f.state or old.move!=f.move or old.serial!=f.get("service",{}).get("serial",0):return pose
    if Vector2(old.x,old.y).distance_to(Vector2(f.x,f.y))>2.5:return pose
    pose.x=lerpf(float(old.x),float(f.x),alpha)
    pose.y=lerpf(float(old.y),float(f.y),alpha)
    if f.state=="attack" and f.frame>=old.frame and f.frame-old.frame<=2:
        pose.frame=lerpf(float(old.frame),float(f.frame),alpha)
    return pose
