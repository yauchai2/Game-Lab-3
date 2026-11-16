extends RefCounted
const L10n=preload("res://scripts/combat/ui/locale_text.gd")
const Skills=preload("res://scripts/combat/tactics/skills.gd")
const COLORS=[Color("00d6e7"),Color("ff921c"),Color("ff459d"),Color("b8ff00")]
static func draw_overlay(canvas:Control,session:Node3D) -> void:
    var sim:RefCounted=session.sim
    if not sim.tactics.enabled or session.screen not in ["play","pause"]:return
    var f:Dictionary=sim.fighters[0]
    if not f.has("tactical"):return
    var ink:=Color("10121f");var tint:Color=COLORS[clampi(f.character,0,3)]
    for p in sim.tactics.shots:
        var at:Vector2=session.project(Vector2(p.x,p.y))
        var trail:Vector2=session.project(Vector2(p.x-p.dir*.4,p.y))
        if p.kind=="connector":
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
        var rect:=Rect2(378+slot*264,594,252,44)
        canvas.draw_rect(rect,Color("10121fe8"))
        var available:bool=id<int(f.get("tactic_unlocked",0))
        var cooldown:int=f.tactical.cd[slot]
        var label:String=OS.get_keycode_string(keys[slot])+"  "+L10n.text(str(Skills.NAMES[f.character][id]))
        var suffix:String=L10n.text("LEARN IN STORY") if not available else (L10n.text("%.1fs")%(cooldown/60.0) if cooldown>0 else L10n.text("%d ENERGY")%Skills.COSTS[f.character][id])
        if f.character==2 and id==1 and f.tactical.return_ready>0:suffix=L10n.text("SAMPLE / PRESS TO RETURN")
        elif f.character==2 and id==1 and f.tactical.sample_window>0:suffix=L10n.text("RECEIVING / ONE ROUND")
        canvas.draw_string(session.hud.font,rect.position+Vector2(8,17),label,HORIZONTAL_ALIGNMENT_LEFT,240,13,tint if available and cooldown==0 else Color("9299aa"))
        canvas.draw_string(session.hud.font,rect.position+Vector2(8,36),suffix,HORIZONTAL_ALIGNMENT_LEFT,240,12,Color("9299aa"))
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
