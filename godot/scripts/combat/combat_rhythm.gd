extends RefCounted
## Wall-time choreography around unchanged 60 Hz combat steps. Both sides share it.
var kind := ""
var age := 10.0
var owner := 0
var style := ""
var priority := 0
var cooldown := 0.0
var bank := 0.0
var steps := 0
var rate_now := 1.0
const PROFILES := {
    "launch":[.055,.14,.20,1.65,1],
    "chase":[.025,.035,.17,1.8,1],
    "parry":[.12,.18,.24,1.65,2],
    "skill":[.16,.26,.32,1.8,3],
    "overdrive":[.20,.34,.38,1.95,4],
    "impact":[.11,.20,.30,1.85,5],
    "break":[.18,.24,.36,2.0,6],
}
func clear() -> void:
    kind="";style="";age=10.0;priority=0;cooldown=0.0;bank=0.0;rate_now=1.0
func active() -> bool:return kind!=""
func trigger(next:String,side:int,move_hint:="") -> void:
    if not PROFILES.has(next):return
    var profile:Array=PROFILES[next]
    if active() and int(profile[4])<=priority:return
    if cooldown>0 and int(profile[4])<3:return
    kind=next;owner=clampi(side,0,1);age=0.0;priority=profile[4]
    style=move_hint if move_hint!="" else next
    cooldown=.75
    bank=0.0
    rate_now=0.0
func phase() -> String:
    if not active():return "flow"
    var p:Array=PROFILES[kind]
    if age<p[0]:return "hold"
    if age<p[0]+p[1]:return "slow"
    return "release"
func rate() -> float:
    if not active():return 1.0
    match phase():
        "hold":return 0.0
        "slow":return .22
        _:return PROFILES[kind][3]
func advance(delta:float) -> void:
    cooldown=maxf(0,cooldown-delta)
    age+=delta
    if active():
        var p:Array=PROFILES[kind]
        if age>=p[0]+p[1]+p[2]:kind="";priority=0
func take_steps(delta:float,enabled:bool) -> int:
    if not enabled:
        clear();steps+=1;return 1
    advance(clampf(delta,0,.05))
    rate_now=rate()
    bank=minf(2.0,bank+clampf(delta,0,.05)*60.0*rate_now)
    var count:=floori(bank+0.00001)
    bank-=count;steps+=count
    return count
func view_speed() -> float:return rate_now
func draw(canvas:Control,session:Node3D) -> void:
    if not active() or session.reduced_effects or session.screen!="play":return
    var accent:Color=session.COLORS[owner]
    var stage:String=phase()
    var ink:=Color("111328")
    if stage=="hold":
        # A single graphic contact frame, then readable shutters rather than a strobe.
        if age<.025 and kind in ["impact","break","parry"]:
            canvas.draw_rect(Rect2(0,0,1280,720),Color(accent,.25))
        canvas.draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,85),Vector2(940,48),Vector2(0,56)]),ink)
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,650),Vector2(360,672),Vector2(1280,625),Vector2(1280,720),Vector2(0,720)]),ink)
        var x:float=1150-age*600
        for i in 5:canvas.draw_line(Vector2(x+i*25,115),Vector2(x-30+i*25,150),accent,8)
    elif stage=="slow":
        for i in 3:
            var inset:float=18+i*9
            canvas.draw_line(Vector2(inset,118),Vector2(inset,590),Color(accent,.5-i*.12),3)
        canvas.draw_line(Vector2(70,625),Vector2(380+age*250,625),accent,5)
    elif stage=="release":
        var center:Vector2=session.project(Vector2((session.sim.fighters[0].x+session.sim.fighters[1].x)*.5,(session.sim.fighters[0].y+session.sim.fighters[1].y)*.5+1))
        var pulse:float=fmod(age*8,1)
        for i in 26:
            var direction:=Vector2.from_angle(i*TAU/26+.07)
            var reach:=direction*Vector2(960,600)
            var end:=center+reach
            var start:=center+reach*(.38+pulse*.16)
            canvas.draw_line(start,end,Color.WHITE if i%4==0 else accent,2.0 if i%3 else 7.0)
