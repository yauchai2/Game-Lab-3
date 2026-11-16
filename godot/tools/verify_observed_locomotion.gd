extends SceneTree
const Sim=preload("res://scripts/combat/enemies/squad_simulation.gd")
const Blend=preload("res://scripts/combat/motion_interpolation.gd")
const OUT="res://../docs/evidence/ground-motion-review/"
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("OBSERVED_MOTION ",label," ",ok)
    if not ok:push_error(label)
func _initialize() -> void:
    var s=Sim.new();s.arcade_enabled=true;s.ai_enabled=false;s.phase="fight";var blend=Blend.new();var f:Dictionary=s.fighters[0]
    f.x=s.EDGE;f.vx=8;blend.remember(s);var before:String=JSON.stringify(s.fighters)
    check("stationary edge shows no locomotion despite a movement command",blend.sample(f,"p0").vx==0)
    check("F2 keeps the same blocked-movement correction",blend.sample(f,"p0",false).vx==0)
    check("motion sampling never changes physical velocity or state",JSON.stringify(s.fighters)==before and f.vx==8)
    f.x=0;f.vx=8;blend.remember(s);f.x=.05;blend.alpha=.25
    check("partial body movement slows animation to the observed speed",is_equal_approx(blend.sample(f,"p0").vx,3.0))
    check("position interpolation keeps its old fraction",is_equal_approx(blend.sample(f,"p0").x,.0125))
    check("F2 skips positional smoothing while retaining actual motion",is_equal_approx(blend.sample(f,"p0",false).x,.05) and is_equal_approx(blend.sample(f,"p0",false).vx,3.0))
    f.x=0;f.vx=4;blend.remember(s);f.x=.2
    check("collision correction cannot accelerate the requested gait",blend.sample(f,"p0").vx==4)
    f.x=0;f.vx=0;blend.remember(s);f.x=.1
    check("a pushed idle body does not invent walking input",blend.sample(f,"p0").vx==0)
    f.x=0;f.vx=8;blend.remember(s);f.x=-.1
    check("opposite collision displacement keeps a braced pose",blend.sample(f,"p0").vx==0)
    f.x=0;f.vx=-4;blend.remember(s);f.x=-.025
    check("backward movement preserves actual direction and speed",is_equal_approx(blend.sample(f,"p0").vx,-1.5))
    f.x=0;f.vx=8;s.hitstop=2;blend.remember(s);s.hitstop=1
    check("hitstop preserves the frozen gait rather than changing to idle",blend.sample(f,"p0").vx==8)
    s.hitstop=0;f.x=0;f.state="dash";f.vx=14;blend.remember(s)
    check("a one-shot dash keeps its authored fourteen-tick pose",blend.sample(f,"p0").vx==14)
    f.state="attack";f.move="jab";blend.remember(s)
    check("attacks never inherit the neutral movement filter",blend.sample(f,"p0").vx==14)
    f.state="idle";f.move="";f.y=1;blend.remember(s)
    check("air motion keeps its existing velocity contract",blend.sample(f,"p0").vx==14)
    f.y=0;f.x=0;blend.remember(s);f.x=3.0
    check("teleports are not mistaken for gait motion",blend.sample(f,"p0").vx==14)
    f.x=0;blend.remember(s);f.character=1
    check("a role change rejects the old position history",blend.sample(f,"p0").vx==14)
    blend.clear();check("reset removes stale movement history",blend.sample(f,"p0").vx==14)
    for hero in 4:
        s=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.ai_enabled=false;s.character_choices=[hero,1];s.reset_round();s.phase="fight";f=s.fighters[0];f.x=s.EDGE;s.fighters[1].x=-7
        blend=Blend.new();var frozen_rows:=0
        for tick in 25:
            blend.remember(s);s.tick({"axis":1.0});var pose:Dictionary=blend.sample(f,"p0")
            if tick>3 and f.vx>.3 and absf(pose.vx)<.001:frozen_rows+=1
        check("hero%d actual wall commands preserve physics and stop the gait"%hero,f.x==s.EDGE and f.vx>.3 and frozen_rows>15)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));quit(1 if failed else 0)
