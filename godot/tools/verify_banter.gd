extends SceneTree
## G3/G4/G7 banter lines and rival memory. Presentation/local-save only.
const Banter=preload("res://scripts/combat/banter.gd")
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("BANTER FAIL: "+label)
func run() -> void:
    for c in 4:
        for salt in 8:
            for en in [true,false]:
                var l:String=Banter.start_line((c+1)%4,c,0,salt,en)
                check("start line %d/%d/%s non-empty with name"%[c,salt,en],l.begins_with(Banter.NAMES[c]+": ") and l.length()>6)
    for c in 4:
        var line:String=Banter.win_line(c,1,false)
        check("win line %d"%c,line.begins_with(Banter.NAMES[c]))
    for pool in [Banter.START[0],Banter.START[1],Banter.START[2],Banter.START[3],Banter.WIN[0],Banter.MIRROR,Banter.STREAK_LINES]:
        for pair in pool:check("zh line <=20 chars: "+pair[0],pair[0].length()<=20 and pair[1].length()<=40)
    for w in [true,false]:
        for salt in 6:check("radio line %s/%d"%[w,salt],Banter.radio_line(w,salt,true).begins_with("RADIO: ") and Banter.radio_line(w,salt,false).begins_with("電台："))
    check("quiet match gets warm-up style",Banter.style_title({"hits":1,"defense":0,"air":1},0,true)=="WARM-UP SHIFT")
    check("offense style",Banter.style_title({"hits":9,"defense":2,"air":1},0,true)=="COMBO RUNNER")
    check("defense style wins ties over air/offense",Banter.style_title({"hits":3,"defense":3,"air":3},0,true)=="COOL OPERATOR")
    check("air style",Banter.style_title({"hits":2,"defense":1,"air":6},0,true)=="LOWWAY FLYER")
    for i in 6:check("dev note %d"%i,Banter.dev_note(i,true).begins_with("DEV NOTE: ") and Banter.dev_note(i,false).begins_with("製作筆記："))
    check("mirror uses mirror pool",Banter.start_line(2,2,0,0,true).contains("FIRST TO DELIVER"))
    check("streak>=5 uses streak pool",Banter.start_line(0,1,5,0,true).contains("FIFTH TIME"))
    check("streak<5 uses normal pool",not Banter.start_line(0,1,4,0,true).contains("FIFTH"))
    var path:="user://test_banter.cfg"
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var st=Banter.Store.new(path)
    check("empty store has no streak",st.streak_against(1)==0)
    for i in 5:st.record(1,true)
    check("5 wins vs same rival -> streak 5",st.streak_against(1)==5 and st.streak_against(2)==0)
    var re=Banter.Store.new(path)
    check("streak persists",re.streak_against(1)==5)
    re.record(2,true)
    check("rival change restarts at 1",re.streak_against(2)==1 and re.streak_against(1)==0)
    re.record(2,false)
    check("loss resets",re.streak_against(2)==0)
    var bad:=ConfigFile.new();bad.set_value("memory","version",1);bad.set_value("memory","rival",99);bad.set_value("memory","streak",-4000);bad.save(path)
    var clamped=Banter.Store.new(path)
    check("invalid values clamp",clamped.rival==3 and clamped.streak==0)
    bad.set_value("memory","version",99);bad.save(path)
    check("unknown version ignored",Banter.Store.new(path).streak==0)
    check("empty path never writes",Banter.Store.new("").streak==0)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    # Session integration
    var prefs:="user://test_banter_session/options.cfg"
    var scene:=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=prefs
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.character_choices=[0,1]
    scene.language="en"
    scene.start_match(false)
    check("standard fight sets the intro taunt for the rival",scene.intro_line.begins_with("RIVET: "))
    scene.character_choices=[2,2]
    scene.start_match(false)
    check("mirror match sets mirror taunt",scene.intro_line.begins_with("HUSH: "))
    scene.character_choices=[0,1]
    scene.hud.notice=""
    scene.start_match(true)
    check("training has no banter",scene.intro_line=="" and scene.result_line=="")
    scene.start_match(false)
    scene.sim.phase="match_over";scene.sim.winner=0
    scene._physics_process(1.0/60)
    check("player win records streak and sets result line",scene.banter_store.streak_against(1)==1 and scene.result_line.begins_with("ZIP: ") and scene.result_line.contains("RADIO: "))
    scene.start_match(true)
    scene.sim.phase="match_over";scene.sim.winner=0
    scene._physics_process(1.0/60)
    check("training result does not record",scene.banter_store.streak_against(1)==1 and scene.result_line=="")
    scene.free()
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_banter_session/banter.cfg"))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_banter_session/options.cfg"))
    var failed:=checks.filter(func(c):return not c.passed)
    print("BANTER: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
