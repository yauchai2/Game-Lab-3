extends RefCounted
## Deterministic four-boundary ricochet. No damage or input polling.
const CEILING:=5.6 # Fighter feet; body top reaches the eight-metre cage roof.
const CONTACTS:=6
const FLIGHT_TICKS:=180
const STEP:=1.0/60.0
static func fresh() -> Dictionary:
    return {"ticks":0,"count":0,"spin":0.0,"normal":Vector2.ZERO}
static func active(f:Dictionary) -> bool:return f.ricochet.ticks>0
static func arm(f:Dictionary,move:String,face:float,push:float) -> void:
    if f.ricochet.count>=CONTACTS:return
    if not active(f):f.ricochet.ticks=FLIGHT_TICKS
    f.vx=face*clampf(push*1.55,22,34)
    f.vy=-22.0 if move in ["meteor","air_counter"] else (23.0 if move=="launcher" else 17.0)
    f.air.stall=0;f.air.bounce_granted=false
    f.air.combo_left=maxi(f.air.combo_left,FLIGHT_TICKS)
static func release(f:Dictionary) -> void:
    f.ricochet.ticks=0;f.ricochet.count=CONTACTS
    f.wall_tech_window=0;f.wall_tech_buffer=0
    f.state="idle";f.stun=0;f.invuln=maxi(f.invuln,18)
static func integrate(f:Dictionary,edge:float) -> Array:
    var contacts:Array=[]
    f.ricochet.ticks-=1
    f.vy=maxf(-30,f.vy-18*STEP)
    f.x+=f.vx*STEP;f.y+=f.vy*STEP
    f.ricochet.spin+=signf(f.vx)*Vector2(f.vx,f.vy).length()*STEP*.7
    if absf(f.x)>=edge and f.vx*signf(f.x)>0:
        var side:float=signf(f.x)
        f.x=side*(edge-.015);f.vx=-side*absf(f.vx)*.86
        contacts.append({"surface":"right" if side>0 else "left","x":side*edge,"y":f.y+1.1,"normal":Vector2(-side,0)})
    if f.y>=CEILING and f.vy>0:
        f.y=CEILING-.015;f.vy=-absf(f.vy)*.84
        contacts.append({"surface":"ceiling","x":f.x,"y":CEILING+2.4,"normal":Vector2(0,-1)})
    elif f.y<=0 and f.vy<0:
        f.y=.015;f.vy=absf(f.vy)*.78
        contacts.append({"surface":"floor","x":f.x,"y":.03,"normal":Vector2(0,1)})
    f.x=clampf(f.x,-edge,edge);f.y=clampf(f.y,0,CEILING)
    contacts=contacts.slice(0,maxi(0,CONTACTS-f.ricochet.count))
    for contact in contacts:
        f.ricochet.count+=1;f.ricochet.normal=contact.normal
        f.wall_tech_window=18;f.wall_bounces+=1
        contact["speed"]=Vector2(f.vx,f.vy).length();contact["chain"]=f.ricochet.count
    if f.ricochet.ticks<=0 or f.ricochet.count>=CONTACTS or Vector2(f.vx,f.vy).length()<7:
        release(f)
    return contacts
