extends RefCounted
## One fullscreen owner, presentation seconds only. No damage/input/audio authority.
var profile:Resource=preload("res://scripts/combat/neon/neon_style_profile.tres")
var mode:=""
var age:=0.0
var duration:=0.0
var cooldown:=0.0
var owner:=0
var priority:=0
var point:=Vector2.ZERO
var accepted:=0
var suppressed:=0
var signature:=false
var move_name:=""
var sprites=preload("res://scripts/combat/sprite_fx.gd").new()
func clear() -> void:
    mode="";age=0.0;duration=0.0;cooldown=0.0;priority=0;signature=false;move_name=""
func active() -> bool:return mode!="" and age<duration
func silhouette() -> bool:
    return active() and age<profile.silhouette_seconds
func stage() -> bool:
    # One brief poster frame at the accent; longer, readable monochrome stage for signatures.
    return active() and age<(0.10 if priority<3 else .23)
func trigger(event:Dictionary,fighters:Array,surge_tier:=3) -> void:
    var kind:String=event.kind
    var next:="";var rank:=0;var length:=0.0
    var side:int=event.get("attacker",event.get("owner",event.get("target",0)))
    if kind in ["parry","air_counter_start"]:
        next="PARRY";rank=2;length=.30;side=event.get("target",event.get("owner",0))
    elif kind=="swing" and event.get("move","") in ["special","overdrive"]:
        next="CHARGE";rank=3;length=1.50 if event.move=="overdrive" else .85
    elif kind=="hit" and event.get("move","") in ["meteor","special","overdrive","air_counter"]:
        next="RELEASE";rank=4;length=.85 if event.move=="overdrive" else .38
    elif kind=="break_finish":next="BREAK";rank=5;length=.50
    elif kind=="ko":next="K.O.";rank=6;length=.65;side=maxi(0,event.get("winner",0))
    if next=="":return
    if next in ["PARRY","RELEASE"]:length*=[.45,.72,1.0][clampi(surge_tier-1,0,2)]
    # A charge-to-release upgrade is allowed. Lower events must leave recovery space.
    if (active() and rank<=priority) or (not active() and cooldown>0 and rank<6):
        suppressed+=1;return
    mode=next;age=0.0;duration=length;owner=clampi(side,0,1);priority=rank
    signature=event.get("move","")=="overdrive" and next in ["CHARGE","RELEASE"]
    move_name=event.get("move","")
    var target:int=clampi(event.get("target",1-owner),0,1)
    point=Vector2(fighters[target].x,fighters[target].y+1.2)
    cooldown=length+profile.recovery_seconds
    accepted+=1
func advance(delta:float,paused:bool,reduced:bool) -> void:
    if reduced:clear();return
    if paused:return
    age+=delta;cooldown=maxf(0.0,cooldown-delta)
    if age>=duration:mode="";priority=0;signature=false
func draw(canvas:Control,session:Node3D) -> void:
    if not active() or session.reduced_effects or session.screen not in ["play","result"]:return
    var color:Color=session.effect_color_for(owner)
    var at:Vector2=session.project(point)
    var ink:=Color("080a10")
    # Cropped edge cuts leave both the contact point and top HUD unobstructed.
    var width:=160.0*(1.0-age/duration)
    canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,130),Vector2(width,130),Vector2(0,340)]),color)
    canvas.draw_colored_polygon(PackedVector2Array([Vector2(1280,570),Vector2(1280-width,620),Vector2(1280,620)]),color)
    if mode=="CHARGE":
        sprites.converge(canvas,at,age,color,95.0-65.0*clampf(age/.30,0,1),6)
    elif age<.30:
        sprites.hit_spark(canvas,at,age/.30,color,0.0,260.0 if priority>=4 else 120.0)
    # Lethal League style hit flash: two crisp paper-white frames. This director is the single fullscreen owner.
    if mode in ["RELEASE","BREAK","K.O."] and age<.045:
        canvas.draw_rect(Rect2(0,0,1280,720),Color("fff8dc",.32 if age<.02 else .14))
    # Pixel-snapped ink speed lines away from the point of impact.
    if mode in ["RELEASE","BREAK","K.O."] and age<duration*.7:
        var dir:float=1.0 if owner==0 else -1.0
        for i in 9:
            var y:float=roundf((at.y+(float(i)-4.0)*30.0+float((i*37)%5)*4.0)/2.0)*2.0
            var length:float=(240.0+float((i*53)%4)*80.0)*(1.0-age/duration*.6)
            var start:float=roundf((at.x-dir*(160.0+float(i%3)*46.0))/2.0)*2.0
            var rect:=Rect2(Vector2(start if dir>0 else start-length,y),Vector2(length,6.0))
            canvas.draw_rect(rect,ink)
            canvas.draw_rect(Rect2(rect.position+Vector2(0,2),Vector2(rect.size.x*.7,2.0)),color if i%2==0 else Color("fff8dc"))
    if priority>=5:
        canvas.draw_string(session.hud.bold,Vector2(64,625),mode,HORIZONTAL_ALIGNMENT_LEFT,-1,64,Color.WHITE)
    else:
        canvas.draw_rect(Rect2(62,594,170,36),ink)
        canvas.draw_string(session.hud.bold,Vector2(72,620),mode,HORIZONTAL_ALIGNMENT_LEFT,-1,28,color)
func camera_roll() -> float:
    if not active():return 0.0
    var limit:float=profile.signature_roll_degrees if signature else (6.0 if priority>=3 else profile.accent_roll_degrees)
    return deg_to_rad(limit)*sin(PI*age/duration)*(1 if owner==0 else -1)

func signature_phase() -> String:
    if not active() or not signature:return ""
    if mode=="RELEASE":return "drive" if age<.32 else "settle"
    if age<.22:return "gather"
    if age<.65:return "open"
    return "aim"
func camera_weight() -> float:
    if not active() or not signature:return 0.0
    var entrance:float=1.0 if mode=="RELEASE" else smoothstep(0.0,.14,age)
    return entrance*(1.0-smoothstep(duration-.22,duration,age))
