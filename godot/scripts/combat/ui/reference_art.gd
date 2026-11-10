extends RefCounted
## Approved image composition; fixed art is raster, live game state remains native.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const LARGE_TYPE=preload("res://assets/fonts/RadioPixelDisplay.fnt")
const TITLE=preload("res://assets/ui/last_service/cover-neon-city.png")
const CITY=preload("res://assets/ui/ink/city-band.png")
const SLASHES=preload("res://assets/ui/ink/slashes.png")
const MAIN_RECTS=[Rect2(56,260,408,84),Rect2(56,354,408,66),Rect2(56,430,408,66),Rect2(56,506,408,66),Rect2(56,604,282,54)]
const CARD_RECTS=[Rect2(198,155,300,349),Rect2(485,159,301,345),Rect2(191,509,298,332),Rect2(491,510,304,330)]
var roster_side:=0
var focus_age:=1.0
var focused_key:="fight":
    set(value):
        if value!=focused_key:focus_age=0.0
        focused_key=value
func advance(delta:float,reduced:bool) -> void:
    focus_age=1.0 if reduced else minf(1.0,focus_age+delta)
func fit(rect:Rect2) -> Rect2:
    return Rect2(rect.position*Vector2(1280.0/1672,720.0/941),rect.size*Vector2(1280.0/1672,720.0/941))
func polygon(c:Control,pts:Array,color:Color) -> void:
    c.draw_colored_polygon(PackedVector2Array(pts),color)
func text(c:Control,at:Vector2,value:String,size:int,color:Color=T.INK) -> void:
    c.draw_string(LARGE_TYPE if size>=40 else T.DISPLAY,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func plate(c:Control,rect:Rect2,color:Color,cut:=14.0) -> void:
    var p:Vector2=rect.position;var e:Vector2=rect.end
    polygon(c,[p+Vector2(cut,0),Vector2(e.x,p.y),e-Vector2(cut,0),Vector2(p.x,e.y)],color)
func title(c:Control) -> void:
    # Opaque faceless key art; the previous illustrated portraits are not drawn.
    c.draw_texture_rect(TITLE,Rect2(0,0,1280,720),false)
    logo(c,Vector2(48,70),560)
    text(c,Vector2(58,222),"LAST SERVICE / STREET FIGHT",28,T.PAPER)
    c.draw_texture_rect(SLASHES,Rect2(514,198,56,36),false)
    var keys:Array=["fight","roster","training","settings","demo"]
    var labels:Array=["FIGHT","FIGHTERS","TRAINING","SETTINGS","AI DEMO"]
    for i in 5:
        var active:bool=focused_key==keys[i]
        var rect:Rect2=MAIN_RECTS[i]
        plate(c,Rect2(rect.position+Vector2(6,7),rect.size),Color("07030d"),14)
        plate(c,rect.grow(3),Color.WHITE,14)
        plate(c,rect,T.MAGENTA if active else T.NIGHT,14)
        var point_size:int=64 if i==0 else (34 if i==4 else 46)
        text(c,rect.position+Vector2(24,62 if i==0 else (40 if i==4 else 49)),labels[i],point_size,T.INK if active else Color.WHITE)
        if active:
            var kick:int=4 if focus_age<.10 else (2 if focus_age<.20 else 0)
            var center:Vector2=Vector2(rect.position.x-14-kick,rect.get_center().y)
            polygon(c,[center,center+Vector2(-15,-10),center+Vector2(-15,10)],T.MAGENTA)
    text(c,Vector2(64,594),"FIGHTERS: XP / SKILLS",24,T.MUTED)
    hints(c)
func logo(c:Control,at:Vector2,width:float) -> void:
    var height:float=width*T.LOGO.get_height()/T.LOGO.get_width()
    c.draw_texture_rect(T.LOGO,Rect2(at,Vector2(width,height)),false)
func page_base(c:Control,heading:String) -> void:
    c.draw_rect(Rect2(0,0,1280,720),T.INK)
    c.draw_texture_rect(CITY,Rect2(0,0,1280,380),false,Color(.22,.22,.22))
    logo(c,Vector2(40,29),340)
    text(c,Vector2(430,88),heading,64,T.PAPER)
    c.draw_rect(Rect2(40,106,1200,4),T.MAGENTA)
    c.draw_texture_rect(SLASHES,Rect2(1154,30,80,50),false)
    c.draw_rect(Rect2(40,704,1200,4),T.TEAL)
func corners(c:Control,rect:Rect2,color:Color,length:=18.0) -> void:
    for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
        var x:float=1 if point.x==rect.position.x else -1
        var y:float=1 if point.y==rect.position.y else -1
        c.draw_line(point,point+Vector2(x*length,0),color,4)
        c.draw_line(point,point+Vector2(0,y*length),color,4)
func roster(c:Control,s:Node) -> void:
    var choice:int=s.character_choices[roster_side]
    page_base(c,"FIGHTERS")
    for i in 4:
        var card_rect:Rect2=fit(CARD_RECTS[i])
        plate(c,card_rect,T.NIGHT,10)
        c.draw_rect(card_rect,T.MAGENTA if choice==i else T.EDGE,false,3 if choice==i else 1)
        if choice==i:corners(c,card_rect,T.PAPER,18)
        c.draw_texture_rect(s.hud.roster_preview.card_texture(i),Rect2(card_rect.position+Vector2(14,8),card_rect.size-Vector2(28,40)),false)
        text(c,card_rect.position+Vector2(30,card_rect.size.y-8),["ZIP","RIVET","HUSH","LOOP"][i],27,T.PAPER)
        for side in 2:
            if s.character_choices[side]!=i:continue
            var tint:Color=T.TEAL if side==0 else T.MAGENTA
            var tag:=Rect2(card_rect.position+Vector2(18 if side==0 else 132,16),Vector2(48,30))
            plate(c,tag,tint,5);text(c,tag.position+Vector2(9,25),"P%d"%(side+1),27,T.INK)
        if focused_key=="card_"+str(i):corners(c,card_rect.grow(3),T.TEAL,23)
    for side in 2:
        var side_rect:Rect2=fit(Rect2(18,241+side*100,160,84))
        plate(c,side_rect,T.PAPER if roster_side==side else T.NIGHT)
        text(c,side_rect.position+Vector2(18,47),"P%d"%(side+1),48,T.INK if roster_side==side else T.PAPER)
        if focused_key=="side_"+str(side):corners(c,side_rect.grow(2),T.TEAL)
    corners(c,Rect2(657,121,420,476),T.EDGE,30)
    c.draw_texture_rect(s.hud.roster_preview.hero_texture(),Rect2(662,117,420,486),false)
    plate(c,Rect2(1094,142,140,128),T.NIGHT,10)
    text(c,Vector2(1124,243),["Z","R","H","L"][choice],106,T.PAPER)
    for label in [["SKILLS",Rect2(1094,300,140,60)],["STREET",Rect2(1094,380,140,86)]]:
        plate(c,label[1],T.NIGHT,8)
        text(c,label[1].position+Vector2(12,37),label[0],28,T.PAPER)
    text(c,Vector2(1107,447),"RUN",28,T.TEAL)
    var fight_rect:Rect2=fit(Rect2(849,773,550,100))
    plate(c,fight_rect,T.TEAL if focused_key=="roster_fight" else T.PAPER,12)
    text(c,fight_rect.position+Vector2(54,58),"FIGHT",64,T.INK)
    var name:String=["ZIP / ROUTE KICKS","RIVET / PRELOAD","HUSH / SAMPLE","LOOP / PATCH NODES"][choice]
    plate(c,Rect2(672,666,250,38),T.NIGHT,8)
    text(c,Vector2(686,697),name,26,T.PAPER)
    hints(c)
    if focused_key=="back":corners(c,fit(Rect2(1507,875,145,50)),T.TEAL)
func hints(c:Control) -> void:
    c.draw_rect(Rect2(924,658,356,62),T.INK)
    plate(c,Rect2(932,665,178,40),T.PAPER,8)
    text(c,Vector2(944,695),"ENTER SELECT",28)
    plate(c,Rect2(1118,665,132,40),T.PAPER,8)
    text(c,Vector2(1130,695),"ESC BACK",28)
func secondary(c:Control,heading:String) -> void:
    page_base(c,heading)
func hud(c:Control,s:Node,hp_lag:Array) -> void:
    for side in 2:
        var reverse:bool=side==1
        var f:Dictionary=s.sim.fighters[side]
        var start:float=109 if side==0 else 683
        var outer:PackedVector2Array=PackedVector2Array([Vector2(start,35),Vector2(start+462,35),Vector2(start+490,61),Vector2(start-21,61)])
        if reverse:outer=PackedVector2Array([Vector2(start+21,35),Vector2(start+483,35),Vector2(start+504,61),Vector2(start-7,61)])
        c.draw_polyline(PackedVector2Array([outer[0],outer[1],outer[2],outer[3],outer[0]]),T.PAPER,4)
        c.draw_colored_polygon(outer,T.INK)
        var bar:Rect2=Rect2(704 if reverse else 227,40,350,14)
        var ratio:float=clampf(f.health/100.0,0,1)
        var lag:float=clampf(hp_lag[side]/100,0,1)
        var x:float=bar.end.x-bar.size.x*lag if reverse else bar.position.x
        plate(c,Rect2(x,bar.position.y,bar.size.x*lag,bar.size.y),T.PAPER,7)
        x=bar.end.x-bar.size.x*ratio if reverse else bar.position.x
        if ratio>0:plate(c,Rect2(x,bar.position.y,bar.size.x*ratio,bar.size.y),T.CORAL if side else T.TEAL,7)
        var tab:Rect2=Rect2(1130 if reverse else 117,27,49,28)
        plate(c,tab,T.PAPER,5)
        text(c,Vector2(1137 if reverse else 124,50),"P2" if reverse else "P1",32)
        text(c,Vector2(1070 if reverse else 177,50),str(f.health),36,T.PAPER)
        var meter:Rect2=Rect2(start+117,65,254,6)
        plate(c,Rect2(meter.position-Vector2(3,3),meter.size+Vector2(6,6)),T.INK,4)
        plate(c,meter,T.LIME.darkened(.7),3)
        if f.meter>0:plate(c,Rect2(meter.position,meter.size*Vector2(f.meter/100,1)),T.LIME,3)
        var marks:Array=[10,20,75] if f.character==3 else [50,75]
        for threshold in marks:
            var tx:float=meter.position.x+meter.size.x*threshold/100
            c.draw_line(Vector2(tx,61),Vector2(tx,73),T.PAPER,2)
        var center:=Vector2(87 if side==0 else 1192,45)
        c.draw_circle(center,29,T.INK)
        c.draw_arc(center,27,0,TAU,24,T.PAPER,2)
        for bar_index in 3:
            var extent:float=[14.0,26.0,20.0][bar_index]
            c.draw_rect(Rect2(center+Vector2(-15+bar_index*11,-extent*.5),Vector2(7,extent)),T.TEAL if side==0 else T.MAGENTA)
    c.draw_circle(Vector2(640,44),35,T.INK);c.draw_circle(Vector2(640,44),32,T.PAPER);c.draw_circle(Vector2(640,44),29,T.GOLD)
    var clock:String="∞" if s.practice or s.demo!=null else "%02d"%ceili(s.sim.remaining)
    var width:float=T.DISPLAY.get_string_size(clock,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x
    text(c,Vector2(640-width*.5,59),clock,48)
    plate(c,Rect2(150,644,980,60),T.INK,20)
    plate(c,Rect2(154,646,972,54),T.PAPER,20)
    var skill_label:String="NODE" if s.character_choices[0]==3 else ("HOLD" if s.character_choices[0]==1 else "SKILL")
    var shortcuts:Array=[["J","RUSH",174],["K","LAUNCH",382],["L",skill_label,616],["W+L","SUPER",820]]
    for entry in shortcuts:
        var key_width:float=72 if entry[0]=="W+L" else 44
        plate(c,Rect2(entry[2],655,key_width,34),T.INK,6)
        text(c,Vector2(entry[2]+7,683),entry[0],32,T.PAPER)
        text(c,Vector2(entry[2]+key_width+10,683),entry[1],30)

    if s.character_choices[0]==3:
        plate(c,Rect2(990,606,238,32),T.INK,6)
        text(c,Vector2(1000,631),"S+L  PULSE",24,T.LIME)
    if s.sim.combo_hits>=2 and s.sim.combo_owner>=0 and s.sim.fighters[1-s.sim.combo_owner].state=="stun":
        var x:float=39 if s.sim.combo_owner==0 else 1104
        plate(c,Rect2(x,146,118,49),T.PAPER,15)
        plate(c,Rect2(x+3,149,110,43),T.INK,12)
        text(c,Vector2(x+10,184),"%02d"%s.sim.combo_hits,47,T.LIME)
        plate(c,Rect2(x+57,165,67,25),T.PAPER,5);text(c,Vector2(x+65,184),"HITS",22)
