extends RefCounted
const L10n=preload("res://scripts/combat/ui/locale_text.gd")
const Skills=preload("res://scripts/combat/tactics/skills.gd")
const COLORS=[Color("00d6e7"),Color("ff921c"),Color("ff459d"),Color("b8ff00")]
static func slot_view(sim:RefCounted,slot:int) -> Dictionary:
    var f:Dictionary=sim.fighters[0];var t:Dictionary=f.tactical;var id:int=sim.tactics.skill(0,slot)
    var credit:int=sim.tactics.conversion_credit(sim,0,id)
    var offer:Dictionary=sim.tactics.quote(sim,0,slot,credit)
    var view:={"ready":false,"text":"","progress":0.0}
    if t.charge>=0 and t.slot==slot:
        var extra:int=Skills.adjusted_cost(10,float(f.get("tactic_economy",0)))
        view.text=L10n.text("READY / RELEASE") if t.full else (L10n.text("HOLD / +%d ENERGY")%extra if f.meter>=extra else L10n.text("RELEASE / QUICK SHOT"))
        view.progress=minf(1,float(t.charge)/36.0);return view
    if f.character==0 and id==5 and f.state=="attack" and f.move==Skills.MOVE_NAMES[slot] and f.frame>=6 and not t.fired:
        view.ready=true;view.text=L10n.text("PRESS AGAIN TO STOP");return view
    if f.character==2 and id==1 and t.sample_window>0 and not offer.returning:
        view.text=L10n.text("RECEIVING / ONE ROUND");view.progress=float(t.sample_window)/24.0;return view
    if not offer.ready:
        match str(offer.reason):
            "Clear the next story milestone to learn this tactic.":view.text=L10n.text("LEARN / CLEAR %d")%Skills.UNLOCKS[id]
            "Tactic is cooling down.":
                view.text=L10n.text("%.1fs")%(t.cd[slot]/60.0)
                view.progress=1.0-clampf(float(t.cd[slot])/maxf(1,float(t.cd_total[slot])),0,1)
            "Not enough energy for this tactic.":view.text=L10n.text("NEED %d ENERGY")%offer.price
            "Jump before using this diving tactic.":view.text=L10n.text("JUMP TO DIVE")
            "This jump has already spent its diving tactic.":view.text=L10n.text("DIVE USED / LAND FIRST")
            "This tactic needs solid ground.":view.text=L10n.text("LAND TO CAST")
            "Earn two routes before a two-stop delivery.":view.text=L10n.text("DODGE / ROUTES %d/2")%f.service.routes
            "No second legal target on this route.":view.text=L10n.text("NEED ANOTHER TARGET")
            "Charge L first to store preload.":view.text=L10n.text("HOLD L TO PRELOAD")
            "Place two nodes first.":view.text=L10n.text("PLACE NODES %d/2")%f.service.nodes.size()
            "Place a node first.":view.text=L10n.text("PLACE ONE NODE")
            _:view.text=L10n.text("WAIT FOR ACTIVE TACTICS")
        return view
    if credit>0:
        view.ready=true;view.text=L10n.text("CONVERT L / %d ENERGY")%offer.price;return view
    var follow_action:bool=offer.follow and f.state=="attack" and f.move==Skills.MOVE_NAMES[slot]
    var light_cancel:bool=f.state=="attack" and f.move in ["jab","cross"] and f.hit_confirmed and f.frame>=sim.move_for(f,f.move).startup+sim.move_for(f,f.move).active
    if f.guarding:view.text=L10n.text("RELEASE GUARD TO CAST");return view
    if f.health<=0 or f.state not in ["idle"] and not follow_action and not light_cancel:
        view.text=L10n.text("RECOVERING");return view
    view.ready=true
    if offer.follow:
        view.text=L10n.text("EMITTER READY / FIRE" if f.character==3 and id==4 else "FOLLOW / 0 ENERGY")
        if not (f.character==3 and id==4):view.progress=clampf(float(t.follow_window)/(30.0 if f.character==0 else 24.0),0,1)
    elif offer.returning:view.text=L10n.text("RETURN / 0 ENERGY");view.progress=float(t.return_ready)/90.0
    else:view.text=L10n.text("%d ENERGY")%offer.price
    return view
static func draw_overlay(canvas:Control,session:Node3D) -> void:
    var sim:RefCounted=session.sim
    if not sim.tactics.enabled or session.screen not in ["play","pause"]:return
    var f:Dictionary=sim.fighters[0]
    if not f.has("tactical"):return
    var ink:=Color("10121f");var tint:Color=COLORS[clampi(f.character,0,3)]
    for p in sim.tactics.shots:
        var at:Vector2=session.project(Vector2(p.x,p.y))
        var trail:Vector2=session.project(Vector2(p.x-p.dir*.4,p.y))
        if p.kind=="zone":
            var left:Vector2=session.project(Vector2(p.x-p.radius,.05));var right:Vector2=session.project(Vector2(p.x+p.radius,.05))
            canvas.draw_line(left,right,ink,14);canvas.draw_line(left,right,tint,4)
            var ratio:float=minf(1,float(p.age)/maxf(1,float(p.get("delay",30))))
            canvas.draw_line(left,left.lerp(right,ratio),Color.WHITE,7)
        elif p.kind=="cable":
            var anchor:Vector2=session.project(Vector2(p.fighter.x,p.fighter.y+.9))
            canvas.draw_line(anchor,at,ink,7);canvas.draw_line(anchor,at,tint,3);canvas.draw_circle(at,5,Color.WHITE)
        elif p.kind=="arc":
            canvas.draw_arc(at,10,-PI*.7,PI*.7,8,ink,8);canvas.draw_arc(at,10,-PI*.7,PI*.7,8,tint,4)
        elif p.kind=="elevated":
            canvas.draw_line(trail,at,ink,10);canvas.draw_line(trail,at,Color.WHITE,5);canvas.draw_circle(at,5,tint)
        elif p.kind=="connector":
            canvas.draw_line(at-Vector2(10,0),at+Vector2(10,0),ink,10);canvas.draw_line(at-Vector2(8,0),at+Vector2(8,0),tint,5)
        elif p.kind in ["pulse","ground"]:
            var edge:Vector2=session.project(Vector2(p.x+p.radius,.15))
            canvas.draw_line(at,edge,ink,14);canvas.draw_line(at,edge,tint,7)
        else:
            canvas.draw_line(trail,at,ink,12);canvas.draw_line(trail,at,tint,6)
            canvas.draw_circle(at,7,Color.WHITE);canvas.draw_circle(at,4,tint)
    var keys:Array=session.controls.tactic_keys
    for slot in 2:
        var id:int=sim.tactics.skill(0,slot)
        var rect:=Rect2(324+slot*316,572,304,66)
        canvas.draw_rect(rect,Color("10121fe8"))
        var view:Dictionary=slot_view(sim,slot)
        var label:String=OS.get_keycode_string(keys[slot])+"  "+L10n.text(str(Skills.NAMES[f.character][id]))
        canvas.draw_string(session.hud.font,rect.position+Vector2(8,23),label,HORIZONTAL_ALIGNMENT_LEFT,288,20,tint if view.ready else Color("9299aa"))
        canvas.draw_string(session.hud.font,rect.position+Vector2(8,49),view.text,HORIZONTAL_ALIGNMENT_LEFT,288,18,tint if view.ready else Color("9299aa"))
        if view.progress>0:canvas.draw_rect(Rect2(rect.position+Vector2(8,62),Vector2(288*clampf(view.progress,0,1),2)),tint)
    if f.tactical.charge>=0:
        var at:Vector2=session.project(Vector2(f.x,2.4))
        canvas.draw_rect(Rect2(at-Vector2(45,4),Vector2(90,8)),ink)
        canvas.draw_rect(Rect2(at-Vector2(43,2),Vector2(86*minf(1,float(f.tactical.charge)/36.0),4)),tint)
        canvas.draw_string(session.hud.font,at+Vector2(-45,-12),L10n.text("READY / RELEASE" if f.tactical.full else "CHARGE / GUARD TO CANCEL"),HORIZONTAL_ALIGNMENT_LEFT,-1,13,tint)
    if f.tactical.mark_ttl>0:
        for target in sim.tactics.targets(sim,0):
            if int(target.get("squad_id",0))==f.tactical.mark and target.health>0:
                var at:Vector2=session.project(Vector2(target.x,target.y+2.3))
                canvas.draw_line(at-Vector2(8,6),at,Color.WHITE,4);canvas.draw_line(at,at+Vector2(8,-6),tint,4)

    for target in sim.tactics.targets(sim,0):
        if target.get("tactic_silence",0)>0:
            var at:Vector2=session.project(Vector2(target.x,target.y+2.5))
            canvas.draw_string(session.hud.font,at-Vector2(24,0),L10n.text("JAMMED"),HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
