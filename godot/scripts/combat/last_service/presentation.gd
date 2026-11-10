extends RefCounted
const P=preload("res://scripts/combat/last_service/profiles.gd")
func draw(canvas:Control,s:Node) -> void:
    if not s.sim.last_service_enabled:return
    for side in 2:
        var f:Dictionary=s.sim.fighters[side];var r:Dictionary=f.service
        var label:String=P.NAMES[f.character]+" / "+["ROUTE %d/2"%r.routes,"PRELOAD %d/2"%r.preload,"SAMPLE "+("READY" if r.sample>0 else "--"),"NODES %d/2"%r.nodes.size()][f.character]
        canvas.draw_string(s.hud.font,Vector2(330 if side==0 else 755,104),label,HORIZONTAL_ALIGNMENT_LEFT,-1,24,s.effect_color_for(side))
        var duration:float=0.0;var capacity:float=1.0
        match int(f.character):
            0:duration=r.route_ttl if r.routes>0 else 0;capacity=300.0 if "zip_route" in f.perks else 180.0
            1:duration=r.preload_age if f.state=="attack" and f.move=="special" else 0;capacity=36.0
            2:duration=r.sample_ttl if r.sample>0 else 0;capacity=360.0 if "hush_hold" in f.perks else 240.0
            3:
                if not r.nodes.is_empty():duration=r.nodes[0].life
                capacity=420.0 if "loop_life" in f.perks else 300.0
        if duration>0:
            var position:=Vector2(330 if side==0 else 755,110)
            canvas.draw_rect(Rect2(position,Vector2(210,4)),Color("08090d"))
            canvas.draw_rect(Rect2(position,Vector2(210*clampf(duration/capacity,0,1),4)),s.effect_color_for(side))
        for node in r.nodes:
            var at:Vector2=s.project(Vector2(node.x,.10))
            var points:=PackedVector2Array([at+Vector2(-14,0),at+Vector2(0,-9),at+Vector2(14,0),at+Vector2(0,9)])
            canvas.draw_colored_polygon(points,s.effect_color_for(side));canvas.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color.WHITE,2)
            canvas.draw_rect(Rect2(at+Vector2(-15,9),Vector2(38,22)),Color("08090d"))
            canvas.draw_string(s.hud.font,at+Vector2(-10,27),"P%d"%(side+1),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
    if s.run_active:
        canvas.draw_string(s.hud.font,Vector2(488,128),"STREET RUN %d/3 / BUILD ON"%s.run_stage,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
