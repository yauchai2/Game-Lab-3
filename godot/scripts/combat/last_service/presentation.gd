extends RefCounted
const P=preload("res://scripts/combat/last_service/profiles.gd")
func draw(canvas:Control,s:Node) -> void:
    if not s.sim.last_service_enabled:return
    for side in 2:
        var f:Dictionary=s.sim.fighters[side];var r:Dictionary=f.service
        if f.character==4:
            var caption:String="%d LEFT"%s.sim.remaining_enemies() if s.sim.squad_enabled else "BLACK SUIT"
            canvas.draw_string(s.hud.font,Vector2(820,100),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,24,s.effect_color_for(side))
            continue
        var x:float=227.0 if side==0 else 820.0
        var tint:Color=s.effect_color_for(side)
        canvas.draw_string(s.hud.font,Vector2(x,100),P.NAMES[f.character],HORIZONTAL_ALIGNMENT_LEFT,-1,24,tint)
        var count:int=[r.routes,r.preload,1 if r.sample>0 else 0,r.nodes.size()][f.character]
        var slots:int=1 if f.character==2 else 2
        var pip_x:float=x+108
        for pip in slots:
            canvas.draw_rect(Rect2(pip_x+pip*20,86,14,14),Color("15101f"))
            canvas.draw_rect(Rect2(pip_x+pip*20+2,88,10,10),tint if pip<count else Color(tint,.18))
        var duration:float=0.0;var capacity:float=1.0
        match int(f.character):
            0:duration=r.route_ttl if r.routes>0 else 0;capacity=300.0 if "zip_route" in f.perks else 180.0
            1:duration=r.preload_age if f.state=="attack" and f.move=="special" else 0;capacity=36.0
            2:duration=r.sample_ttl if r.sample>0 else 0;capacity=360.0 if "hush_hold" in f.perks else 240.0
            3:
                if not r.nodes.is_empty():duration=r.nodes[0].life
                capacity=420.0 if "loop_life" in f.perks else 300.0
        if duration>0:
            var position:=Vector2(x,105)
            canvas.draw_rect(Rect2(position,Vector2(146,3)),Color("08090d"))
            canvas.draw_rect(Rect2(position,Vector2(146*clampf(duration/capacity,0,1),3)),s.effect_color_for(side))
        for node in r.nodes:
            var at:Vector2=s.project(Vector2(node.x,.10))
            var points:=PackedVector2Array([at+Vector2(-14,0),at+Vector2(0,-9),at+Vector2(14,0),at+Vector2(0,9)])
            canvas.draw_colored_polygon(points,s.effect_color_for(side));canvas.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color.WHITE,2)
            canvas.draw_rect(Rect2(at+Vector2(-15,9),Vector2(38,22)),Color("08090d"))
            canvas.draw_string(s.hud.font,at+Vector2(-10,27),"P%d"%(side+1),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
    if s.run_active and (s.sim.phase=="ready" or s.screen in ["pause","result"]):
        canvas.draw_string(s.hud.font,Vector2(488,252),"STREET RUN %d/3 / BUILD ON"%s.run_stage,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
    if s.sim.squad_enabled:
        for id in s.sim.squad_members.size():
            var f:Dictionary=s.sim.squad_members[id]
            if f.health<=0 or f.has("boss"):continue
            var at:Vector2=s.project(Vector2(f.x,f.y+2.25))
            canvas.draw_rect(Rect2(at-Vector2(32,0),Vector2(64,7)),Color("15101f"))
            if s.sim.story_enabled:
                var role_color:Color={"guard":Color("ffd84c"),"rusher":Color("00d7d7"),"jammer":Color("dd27ff"),"heavy":Color("e87d39"),"captain":Color("d8ff39")}.get(f.story_role,Color("a888ff"))
                canvas.draw_rect(Rect2(at-Vector2(32,0),Vector2(64*float(f.health)/f.max_health,7)),role_color)
                if f.rush_charge>0:canvas.draw_string(s.hud.font,at+Vector2(-6,-15),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("ffd84c"))
            if not s.sim.story_enabled:canvas.draw_rect(Rect2(at-Vector2(32,0),Vector2(64*float(f.health)/f.max_health,7)),Color("a888ff"))
            if id==s.sim.squad_focus:canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-14),at+Vector2(8,-14),at+Vector2(0,-4)]),Color.WHITE)
            if f.state=="attack" and f.frame<s.sim.move_for(f,f.move).startup:
                canvas.draw_string(s.hud.font,at+Vector2(-5,-22),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("ff459d"))
