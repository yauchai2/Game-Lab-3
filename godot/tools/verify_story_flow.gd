extends SceneTree
## Native check of the chained STORY flow: cards, keep-going panel, route/boon defaults, endings, contract chain.
const OUT="res://../docs/evidence/story-flow/"
var s:Node
var c:Node
var p:RefCounted
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":name,"passed":ok,"detail":detail});print("STORY_FLOW ",name," ",ok)
    if not ok:push_error(name)
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func step(n:=1) -> void:
    for i in n:s._combat_step();s._process(1.0/60)
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down;Input.parse_input_event(e);await frames(2)
func tap(code:Key) -> void:
    await key(code,true);await key(code,false)
func shot(name:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func click(control:Control) -> void:
    await frames(3)
    for down in [true,false]:
        var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=control.get_global_rect().get_center();e.global_position=e.position;root.push_input(e,true);await frames(2)
func flow_button(prefix:String) -> Button:
    for child in c.flow.inter_stack.find_children("*","Button",true,false):
        if child.text.begins_with(prefix):return child
    return null
## Press Enter until every card is gone (first press completes the typing, second advances).
func read_cards(limit:=60) -> int:
    var presses:=0
    while c.flow.mode=="cards" and presses<limit:
        await tap(KEY_ENTER);presses+=1
    return presses
func win() -> void:
    s.sim.story_state="complete";s.sim.phase="match_over";s.sim.winner=0
    s._combat_step();s._process(1.0/60);await frames(2)
func lose() -> void:
    s.sim.story_state="failed";s.sim.phase="match_over";s.sim.winner=1
    s._combat_step();s._process(1.0/60);await frames(2)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var path:="user://story-flow/city.json"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://story-flow/story_flow.cfg"))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path=path;root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false);await frames(6)
    c=s.city_campaign;p=c.profile
    # Without a real session the old one-encounter-per-trip behaviour is unchanged.
    check("test session is not a live scene so older flows stay unchanged",not c.flow.live())
    p.start_run(0);c.depart();await frames(2)
    check("non-live depart starts the fight with no cards",s.screen=="play" and c.flow.mode=="")
    await win();c.return_from_encounter();await frames(2)
    check("non-live clear returns to the city exactly as before",s.screen=="city" and c.flow.mode=="")
    p.abandon();p.data.best=0;p.save_data()
    c.flow.force_live=true
    # --- prologue and chapter 1 intro
    p.start_run(0);c.depart();await frames(2)
    check("first departure plays prologue and chapter 1 as cards",c.flow.mode=="cards" and c.flow.queue_total==9 and c.flow.header_label.text=="PROLOGUE / WRONG DELIVERY",{"cards":c.flow.queue_total})
    await shot("prologue-card")
    var presses:=await read_cards()
    check("cards advance with Enter and then the encounter begins",c.flow.mode=="" and s.screen=="play" and p.data.run.in_flight and presses>=9,{"presses":presses})
    check("encounter opens with a radio caption from the crew",c.flow.caption.visible and c.flow.caption.text.begins_with("HUSH:"))
    await shot("encounter-caption")
    var seen_file:=ConfigFile.new()
    check("seen scenes are stored apart from the city save",seen_file.load("user://story-flow/story_flow.cfg")==OK and seen_file.has_section_key("seen","prologue") and seen_file.has_section_key("seen","ch0"))
    # --- clear 1: panel opens by itself, ENTER keeps going
    await win()
    check("clear shows result first",s.screen=="result" and c.encounter_finished() and c.result_action().begins_with("KEEP GOING"))
    c.flow._process(1.2);await frames(3)
    check("short pause later the keep-going panel opens without a key",c.flow.mode=="inter" and s.screen=="city" and p.data.run.room==1 and p.data.run.boon_due)
    check("panel offers the three currents, route choices and the next radio line",flow_button("1  ")!=null and flow_button("4  ")!=null and flow_button("NEXT ENCOUNTER")!=null and flow_button("RETURN TO SAFE BLOCK")!=null)
    await shot("keep-going-panel")
    var credits_before:int=p.data.credits
    await tap(KEY_ENTER);await frames(3)
    check("ENTER takes the default current and route and launches encounter 2",c.flow.mode=="" and s.screen=="play" and p.data.run.room==1 and p.data.run.in_flight and not p.data.run.boon_due and not p.data.run.get("route_due",false) and float(p.data.run.boons.get("damage",0))>0,p.data.run.boons)
    check("chain counter and radio line advance with the encounter",c.flow.streak==1 and c.flow.caption.text.begins_with("LOOP:"))
    check("route choice was tallied for the ending",p.data.run.get("tally",{}).get("combat",0)>=1)
    # --- manual picks: defence current by key, hazard route by key
    await win();c.flow._process(1.2);await frames(3)
    await tap(KEY_2);await tap(KEY_5)
    check("number keys choose current and route before continuing",not p.data.run.boon_due and p.data.run.route=="hazard" and float(p.data.run.boons.get("defence",0))>0)
    await click(flow_button("NEXT ENCOUNTER"));await frames(3)
    check("mouse button also continues",s.screen=="play" and p.data.run.room==2 and s.sim.campaign_route=="hazard")
    # --- chapter boundary: outro cards, then intermission, then next chapter intro
    await win();c.flow._process(1.2);await frames(3)
    check("end of chapter plays its outro cards first",c.flow.mode=="cards" and c.flow.header_label.text=="CHAPTER 1 CLEAR")
    await read_cards()
    check("then the keep-going panel",c.flow.mode=="inter" and p.data.run.room==3)
    await tap(KEY_ENTER);await frames(2)
    check("next chapter intro plays before the fight and only once",c.flow.mode=="cards" and c.flow.header_label.text=="CHAPTER 2 / TOLL GATE")
    await read_cards();await frames(2)
    check("fight starts after the intro",s.screen=="play" and p.data.run.room==3 and p.data.run.in_flight)
    # --- ESC goes home and ends the chain
    await win();c.flow._process(1.2);await frames(3)
    await tap(KEY_ESCAPE);await frames(3)
    check("ESC returns to the safe block with the expedition banked and chain reset",s.screen=="city" and c.flow.mode=="" and c.flow.streak==0 and not p.data.run.is_empty() and p.data.run.room==4)
    # --- run to the final boss through the chain; every clear must chain
    var rooms_chained:=0
    check("home keeps the pending current so the hub still asks for it",p.data.run.boon_due and p.data.run.get("route_due",false))
    p.choose_boon("damage");p.choose_route("combat")
    c.depart();await read_cards();await frames(2)
    for room in range(4,17):
        check("encounter %d running"%(room+1),s.screen=="play" and p.data.run.room==room)
        await win();c.flow._process(1.2);await frames(3)
        if c.flow.mode=="cards":await read_cards()
        if c.flow.mode=="inter":
            rooms_chained+=1;await tap(KEY_ENTER);await frames(2)
            if c.flow.mode=="cards":await read_cards()
        await frames(2)
    check("thirteen clears chained into one another",rooms_chained==13 and p.data.run.room==17,{"chained":rooms_chained})
    check("final encounter is the tower boss",s.sim.campaign_boss=="signal")
    await shot("boss-start")
    # --- ending
    var run_tally:Dictionary=p.data.run.get("tally",{})
    p.data.run["tally"]={"hazard":9,"rest":1};for id in p.Story.TECHNIQUES:if id not in p.data.quest_claims:p.data.quest_claims.append(id)
    await win();c.flow._process(1.2);await frames(3)
    check("final clear plays the earned ending then the true ending",c.flow.mode=="cards" and c.flow.header_label.text=="ENDING / LOUD NIGHT" and c.flow.queue.any(func(card:Dictionary)->bool:return card.header=="TRUE ENDING / AFTERHOURS"))
    await shot("ending-card")
    await read_cards(120)
    check("ending hands back to the city, run closed, story cleared",s.screen=="city" and p.data.run.is_empty() and p.data.best==18 and c.flow.mode=="")
    check("ending is recorded once",c.flow.endings_found()==1 and ConfigFile.new().load("user://story-flow/story_flow.cfg")==OK)
    check("ending selection rules",c.flow.Lines.ending_for({"hazard":2,"rest":3})=="open" and c.flow.Lines.ending_for({"rest":5,"hazard":4})=="steady" and c.flow.Lines.ending_for({"cache":6})=="salvage" and c.flow.Lines.ending_for({"hazard":4,"rest":4,"cache":1})=="loud")
    # --- contract chain
    check("contracts exist after the story",p.data.contracts.size()>0)
    var contract:Dictionary=p.data.contracts[0]
    p.start_contract(0,int(contract.id));c.depart();await frames(2)
    check("contract departs with no story cards",c.flow.mode=="" and s.screen=="play" and p.data.run.mode=="contract")
    var waves:int=contract.waves
    for w in waves-1:
        await win();c.flow._process(1.2);await frames(3)
        check("contract wave %d chains"%(w+1),c.flow.mode=="inter" and p.data.run.wave==w+1)
        await tap(KEY_ENTER);await frames(3)
        check("next contract wave launches",s.screen=="play" and p.data.run.wave==w+1 and p.data.run.in_flight)
    # a lost wave with attempts left offers a one-key retry
    var tries:int=p.data.run.tries
    await lose();await tap(KEY_ENTER);await frames(3)
    check("lost contract wave offers a retry panel",c.flow.mode=="inter" and c.flow.inter_info.kind=="retry" and p.data.run.tries==tries-1)
    await tap(KEY_ENTER);await frames(3)
    check("retry relaunches the same wave",s.screen=="play" and p.data.run.in_flight and p.data.run.wave==waves-1)
    await win();c.flow._process(1.2);await frames(3)
    check("finishing a contract offers the next one",c.flow.mode=="inter" and c.flow.inter_info.kind=="contract_next" and p.data.run.is_empty())
    await shot("contract-next")
    await tap(KEY_ENTER);await frames(3)
    check("ENTER starts the next contract immediately",s.screen=="play" and p.data.run.mode=="contract" and p.data.run.wave==0 and c.flow.streak>=1)
    # --- leaving mid-chain restores standard modes
    c.leave_city();s.start_match(false);s.round_theatre.clear();s._process(1.0/60);await frames(4)
    check("standard mode after the chain is clean",not s.sim.campaign_enabled and not c.flow.busy() and not c.flow.caption.visible)
    var failed:int=checks.filter(func(test:Dictionary)->bool:return not test.passed).size()
    var file:=FileAccess.open(OUT+"native.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    s.queue_free();await frames(10)
    print("STORY_FLOW RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
