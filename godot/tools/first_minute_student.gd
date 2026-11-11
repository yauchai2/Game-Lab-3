extends RefCounted
## Automated student fixture: only ordinary input commands from public combat state.
static func command(s:RefCounted,c:RefCounted) -> Dictionary:
    var f:Dictionary=s.fighters[0];var other:Dictionary=s.fighters[1]
    var gap:float=other.x-f.x
    var input:Dictionary={"axis":signf(gap) if absf(gap)>1.25 else 0.0}
    match c.index:
        0:input["attack"]="light"
        1:
            if f.counter_window>0:input["attack"]="light"
            elif other.state=="attack":
                var startup:int=s.move_for(other,other.move).startup
                input["guard"]=other.frame>=startup-7
                input["guard_pressed"]=other.frame==startup-7
                input["axis"]=0.0
        2:
            if c.chased:input["attack"]="light"
            elif c.launched:input["dash"]=true
            elif f.state=="idle":input["attack"]="heavy";input["up"]=true
        3:
            if f.state=="idle":input["attack"]="overdrive"
    return input
