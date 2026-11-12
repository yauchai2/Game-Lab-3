extends RefCounted
## Story-only swept body impacts. One source attack has one shared hit budget.
var roots:Dictionary={}
var bodies:Array=[]
func clear() -> void:roots.clear();bodies.clear()
func arm(f:Dictionary,serial:int,damage:int) -> void:
    if not roots.has(serial):roots[serial]={"hit":{},"count":0,"age":0}
    var root:Dictionary=roots[serial]
    root.hit[f.squad_id]=true
    bodies=bodies.filter(func(b:Dictionary)->bool:return b.id!=f.squad_id)
    bodies.append({"id":f.squad_id,"serial":serial,"damage":damage,"depth":0,"left":72})

func advance(s:RefCounted,previous:Array) -> void:
    for root in roots.values():root.age+=1
    var additions:Array=[]
    for body in bodies:
        body.left-=1
        var root:Dictionary=roots[body.serial]
        if body.left<=0 or root.age>108 or root.count>=4:continue
        var source:Dictionary=s.squad_members[body.id]
        var from:Vector2=previous[body.id]
        var to:=Vector2(source.x,source.y)
        if maxf(Vector2(source.vx,source.vy).length(),from.distance_to(to)*60)<6 or (source.health<=0 and source.y<=.01 and from.y<=.01):continue
        for id in s.squad_members.size():
            var target:Dictionary=s.squad_members[id]
            if target.health<=0 or root.hit.has(id) or target.invuln>0:continue
            var target_at:=Vector2(target.x,target.y)
            var a:Vector2=from-previous[id];var b:=to-target_at
            a.y*=.7;b.y*=.7
            if Geometry2D.get_closest_point_to_segment(Vector2.ZERO,a,b).length()>.72:continue
            if root.count>=4:break
            root.hit[id]=true;root.count+=1
            if target.get("story_role","")=="guard" and target.guarding and (from.x-target.x)*target.face>0:
                target.guard=maxf(0,target.guard-30)
                source.x=target.x+target.face*.8;source.vx=0.0;source.vy=minf(0,source.vy);body.left=0
                if target.guard<=0:target.guarding=false;target.state="stun";target.stun=35
                s.events.append({"kind":"story_chain_block","target":1,"squad_id":id,"face":-float(target.face)})
                break
            var damage:int=maxi(1,roundi(body.damage*[.60,.40,.25,.15][root.count-1]))
            target.health=maxi(0,target.health-damage)
            s.air_motion.cancel_stall(target)
            target.state="stun";target.stun=maxi(target.stun,18);target.flash=8
            target.buffer="";target.buffer_ttl=0;target.jump_buffer=0;target.guarding=false
            target.vx=signf(source.vx)*maxf(6,absf(source.vx)*.72)
            target.vy=maxf(target.vy,3.5)
            target.air.combo_left=mini(60,108-root.age) if target.air.combo_left<=0 else mini(target.air.combo_left,108-root.age)
            target.air.bounce_granted=false
            additions.append({"id":id,"serial":body.serial,"damage":body.damage,"depth":body.depth+1,"left":mini(72,108-root.age)})
            s.events.append({"kind":"story_chain_hit","target":1,"attacker":0,"squad_id":id,"source_id":body.id,"damage":damage,"chain":root.count,"face":signf(source.vx)})
            # No replay of normal-hit perk/core rewards. One bounded reward per root.
            if not root.get("rewarded",false):
                s.fighters[0].meter=minf(100,s.fighters[0].meter+4);root["rewarded"]=true
    bodies=bodies.filter(func(b:Dictionary)->bool:return b.left>0 and roots[b.serial].age<=108 and roots[b.serial].count<4)
    bodies.append_array(additions)
    var used:Dictionary={}
    for body in bodies:used[body.serial]=true
    for serial in roots.keys():
        if not used.has(serial):roots.erase(serial)
