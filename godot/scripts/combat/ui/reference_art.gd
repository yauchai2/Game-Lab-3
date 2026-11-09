extends RefCounted
## Approved image composition; fixed art is raster, live game state remains native.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const TITLE=preload("res://assets/ui/replica/title.png")
const BOARD=preload("res://assets/ui/replica/roster-backplate.png")
const ROSTER=preload("res://assets/ui/replica/roster-reference.png")
const HEAD=preload("res://assets/ui/replica/headphones.png")
const RIBBON=preload("res://assets/ui/replica/controls.png")
const PORTRAIT_ATLAS=preload("res://assets/ui/replica/fighter-portraits.png")
var portrait_cache:Array[AtlasTexture]=[]
const MAIN_RECTS=[Rect2(150,351,468,155),Rect2(160,500,443,107),Rect2(158,607,448,96),Rect2(145,701,478,117),Rect2(49,838,286,86)]
const CARD_RECTS=[Rect2(198,155,300,349),Rect2(485,159,301,345),Rect2(191,509,298,332),Rect2(491,510,304,330)]
var roster_side:=0
var focused_key:="fight"
static func fit(rect:Rect2) -> Rect2:
    return Rect2(rect.position*Vector2(1280.0/1672,720.0/941),rect.size*Vector2(1280.0/1672,720.0/941))
func polygon(c:Control,pts:Array,color:Color) -> void:
    c.draw_colored_polygon(PackedVector2Array(pts),color)
func text(c:Control,at:Vector2,value:String,size:int,color:Color=T.INK) -> void:
    c.draw_string(T.DISPLAY,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func plate(c:Control,rect:Rect2,color:Color,cut:=14.0) -> void:
    var p:Vector2=rect.position;var e:Vector2=rect.end
    polygon(c,[p+Vector2(cut,0),Vector2(e.x,p.y),e-Vector2(cut,0),Vector2(p.x,e.y)],color)
func title(c:Control) -> void:
    c.draw_texture_rect(TITLE,Rect2(0,0,1280,720),false)
    var keys:Array=["fight","roster","training","settings","demo"]
    var index:int=keys.find(focused_key)
    if index>0:
        var r:Rect2=fit(MAIN_RECTS[index])
        c.draw_polyline(PackedVector2Array([r.position+Vector2(25,3),Vector2(r.end.x-5,r.position.y+3),r.end-Vector2(25,3),Vector2(r.position.x+5,r.end.y-3),r.position+Vector2(25,3)]),T.LIME,3)
        polygon(c,[Vector2(r.position.x-18,r.get_center().y),Vector2(r.position.x-34,r.get_center().y-9),Vector2(r.position.x-34,r.get_center().y+9)],T.LIME)
func roster(c:Control,s:Node) -> void:
    var choice:int=s.character_choices[roster_side]
    c.draw_texture_rect(ROSTER if choice==3 else BOARD,Rect2(0,0,1280,720),false)
    if choice!=3:
        # The complete original left composition preserves exact card artwork/edges.
        c.draw_texture_rect_region(ROSTER,Rect2(0,0,612.44,720),Rect2(0,0,800,941))
    for i in 4:
        var r:Rect2=fit(CARD_RECTS[i])
        for side in 2:
            if s.character_choices[side]!=i:continue
            var tint:Color=T.LIME if side==0 else T.TEAL
            var tag:Rect2=Rect2(r.position+Vector2(18 if side==0 else 132,16),Vector2(48,30))
            plate(c,tag,tint,5);text(c,tag.position+Vector2(9,25),"P%d"%(side+1),27)
        if focused_key=="card_"+str(i):c.draw_rect(r.grow(1),T.PAPER,false,2)
    for side in 2:
        var r:Rect2=fit(Rect2(18,241+side*100,160,84))
        plate(c,r,T.LIME if roster_side==side else T.PAPER)
        if focused_key=="side_"+str(side):c.draw_rect(r.grow(2),T.TEAL,false,3)
        text(c,r.position+Vector2(18,47),"P%d"%(side+1),48)
    if choice!=3:
        if portrait_cache.is_empty():
            var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/replica/portrait-regions.json"))
            for rect in data.regions:
                var piece:=AtlasTexture.new();piece.atlas=PORTRAIT_ATLAS;piece.region=Rect2(rect[0],rect[1],rect[2],rect[3]);portrait_cache.append(piece)
        var hero:Texture2D=portrait_cache[choice]
        var height:=464.0;var width:float=height*hero.get_width()/hero.get_height()
        c.draw_texture_rect(hero,Rect2(861-width*.5,127,width,height),false)
    if choice!=3:
        var label:Rect2=fit(Rect2(1400,339,244,218))
        plate(c,label,T.PAPER,18)
        text(c,label.position+Vector2(39,125),["A","1","3","4"][choice],139)
    var profile:Dictionary=s.Simulation.Profiles.profile(choice)
    var name:String=["BOXER / BALANCED","DANCER / AIR REACH","BASS / HEAVY HITS","SPARK / FAST ENERGY"][choice]
    plate(c,Rect2(675,674,313,29),T.PAPER,8)
    text(c,Vector2(686,697),name,21)
    var r:Rect2=fit(Rect2(849,773,550,100))
    if focused_key=="roster_fight":c.draw_rect(r,T.LIME,false,3)
    elif focused_key=="back":c.draw_rect(fit(Rect2(1507,875,145,50)),T.LIME,false,3)
func secondary(c:Control,heading:String) -> void:
    c.draw_texture_rect(BOARD,Rect2(0,0,1280,720),false)
    plate(c,Rect2(330,15,460,100),T.PAPER,35)
    text(c,Vector2(371,92),heading,72)
    polygon(c,[Vector2(0,580),Vector2(1280,550),Vector2(1280,720),Vector2(0,720)],T.INK)
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
        text(c,Vector2(1137 if reverse else 124,50),"P2" if reverse else "P1",29)
        text(c,Vector2(1070 if reverse else 177,50),str(f.health),29,T.PAPER)
        var meter:Rect2=Rect2(start+117,65,254,6)
        plate(c,Rect2(meter.position-Vector2(3,3),meter.size+Vector2(6,6)),T.INK,4)
        plate(c,meter,T.LIME.darkened(.7),3)
        if f.meter>0:plate(c,Rect2(meter.position,meter.size*Vector2(f.meter/100,1)),T.LIME,3)
        for threshold in [50,75]:
            var tx:float=meter.position.x+meter.size.x*threshold/100
            c.draw_line(Vector2(tx,61),Vector2(tx,73),T.PAPER,2)
        c.draw_texture_rect(HEAD,Rect2(58 if side==0 else 1163,15,58,61),false)
    c.draw_circle(Vector2(640,44),35,T.INK);c.draw_circle(Vector2(640,44),32,T.PAPER);c.draw_circle(Vector2(640,44),29,T.GOLD)
    var clock:String="∞" if s.practice or s.demo!=null else "%02d"%ceili(s.sim.remaining)
    var width:float=T.DISPLAY.get_string_size(clock,HORIZONTAL_ALIGNMENT_LEFT,-1,43).x
    text(c,Vector2(640-width*.5,59),clock,43)
    c.draw_texture_rect(RIBBON,Rect2(274,650,731,45),false)
    if s.sim.combo_hits>=2 and s.sim.combo_owner>=0 and s.sim.fighters[1-s.sim.combo_owner].state=="stun":
        var x:float=39 if s.sim.combo_owner==0 else 1104
        plate(c,Rect2(x,146,118,49),T.PAPER,15)
        plate(c,Rect2(x+3,149,110,43),T.INK,12)
        text(c,Vector2(x+10,184),"%02d"%s.sim.combo_hits,47,T.LIME)
        plate(c,Rect2(x+57,165,67,25),T.PAPER,5);text(c,Vector2(x+65,184),"HITS",22)
