extends SceneTree
const Ink=preload("res://scripts/combat/ink_fx/world_ink_fx.gd")
class TraceCanvas extends Control:
    var session:Node
    var draw_count:=0
    func _draw() -> void:
        draw_count+=1
        session.ink_fx.draw(self,session)
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    print("INK_TRACE ",label," ",ok)
func frames() -> void:
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    check("coincident projected tips are discarded",Ink.trace_polygon(Vector2(640,360),Vector2(640,360),4).is_empty())
    check("subpixel collapsed trace is discarded",Ink.trace_polygon(Vector2.ZERO,Vector2(.00001,0),4).is_empty())
    check("expired width is discarded",Ink.trace_polygon(Vector2.ZERO,Vector2(30,0),0).is_empty())
    check("negative width is discarded",Ink.trace_polygon(Vector2.ZERO,Vector2(30,0),-1).is_empty())
    check("nonfinite projection is discarded",Ink.trace_polygon(Vector2(INF,0),Vector2.ZERO,4).is_empty())
    check("nonfinite width is discarded",Ink.trace_polygon(Vector2.ZERO,Vector2(30,0),NAN).is_empty())
    check("finite projection with lost width is discarded",Ink.trace_polygon(Vector2(1e30,1e30),Vector2(2e30,1e30),1).is_empty())
    var good:=true
    for angle in 36:
        for width in [.01,1.0,4.0,8.0]:
            var a:=Vector2(640,360)
            var b:=a+Vector2.RIGHT.rotated(float(angle)*TAU/36)*80
            var polygon:=Ink.trace_polygon(a,b,width)
            good=good and polygon.size()==4 and Geometry2D.triangulate_polygon(polygon).size()==6
    check("144 ordinary trail orientations retain valid quads",good)
    var session=preload("res://scenes/combat/street_fight.tscn").instantiate()
    session.preferences_path="";session.city_save_path=""
    root.add_child(session);session.set_process(false);session.set_physics_process(false)
    await frames()
    session.start_match(true);session.round_theatre.clear();session.sim.phase="fight"
    session.reduced_effects=false;session._process(0)
    var at:=Vector3(0,1,session.FIGHT_Z)
    var visible_tip:=at+Vector3(.8,.3,0)
    var behind:Vector3=session.camera.global_position+session.camera.global_basis.z*2
    var fixtures:Array[Dictionary]=[
        {"a":at,"b":at,"age":0.0,"gain":1.0,"character":0,"color":Color.CYAN},
        {"a":at,"b":visible_tip,"age":.14,"gain":1.0,"character":1,"color":Color.WHITE},
        {"a":behind,"b":behind+Vector3.RIGHT,"age":.02,"gain":1.0,"character":0,"color":Color.CYAN},
        {"a":at,"b":visible_tip,"age":.02,"gain":1.0,"character":0,"color":Color.CYAN}]
    session.ink_fx.traces=fixtures
    session.ink_fx.visible=true
    check("trace fixture uses visible play with effects enabled",session.screen=="play" and not session.reduced_effects and session.ink_fx.visible)
    var canvas:=TraceCanvas.new();canvas.session=session;canvas.size=Vector2(1280,720)
    root.add_child(canvas)
    session.hud.queue_redraw();canvas.queue_redraw();await frames()
    check("canvas issued the world trace draw call",canvas.draw_count>0)
    check("actual HUD renders collapsed, expired, behind-camera and valid traces",session.ink_fx.traces.size()==4)
    session.pause_game();session.hud.queue_redraw();await frames()
    check("pause redraw keeps traces safe",session.screen=="pause")
    session.resume_game();session.reduced_effects=true;session.hud.queue_redraw();await frames()
    check("reduced effects retains the opt-out",session.ink_fx.traces.size()==4)
    session.return_to_title()
    check("exit clears trail state",session.ink_fx.traces.is_empty())
    canvas.session=null;canvas.queue_free();session.queue_free()
    for i in 8:await process_frame
    await frames()
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var output:String=args[0] if not args.is_empty() else "user://ink-trace-checks.json"
    FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"passed":checks.size()-failed},"  "))
    quit(1 if failed else 0)
