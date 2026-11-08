extends SceneTree
## Repeatable bot styles are a balance diagnostic, not a human difficulty rating.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var results: Array[Dictionary]=[]
var violations: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    for level in 3:
        for style in ["guard","light","heavy","mixed"]:
            for trial in 6:
                results.append(play(level,style,trial))
    var output:=FileAccess.open("res://../docs/evidence/extended-polish/combat-styles.json",FileAccess.WRITE)
    output.store_string(JSON.stringify({"rounds":results,"invariant_violations":violations,"passed":violations.is_empty(),"method":"60 Hz offline simulation; 12-tick-old visual observations, deterministic bot styles; diagnostic only, not human balance validation"},"  "))
    print("STYLE_PROBE rounds=",results.size()," violations=",violations.size())
    quit(0 if violations.is_empty() else 1)
func play(level: int, style: String, trial: int) -> Dictionary:
    var sim:=Sim.new()
    sim.difficulty=level
    sim.phase="fight"
    sim.fighters[0].x=-2.3-trial*.13
    sim.fighters[1].x=2.3+trial*.13
    var observations: Array[Dictionary]=[]
    var clashes:=0
    var throws:=0
    var recoveries:=0
    var hits:=0
    var step:=0
    for index in 10000:
        step=index+1
        var a: Dictionary=sim.fighters[0]
        var b: Dictionary=sim.fighters[1]
        # Only state which has a visible pose/position is available to this bot.
        observations.append({"x":b.x,"y":b.y,"state":b.state,"guarding":b.guarding,"cue":sim.exchange.clash.get("cue","")})
        if observations.size()>13:observations.pop_front()
        var seen: Dictionary=observations[0]
        var distance: float=absf(a.x-seen.x)
        var command:={"axis":signf(seen.x-a.x) if distance>1.35 else 0.0}
        if style=="guard":command={"guard":true}
        elif style=="light" and index%7==trial:command["attack"]="light"
        elif style=="heavy" and index%29==trial:command["attack"]="heavy"
        elif style=="mixed":
            if seen.state=="attack" and distance<2.8 and index%43<13:command["guard"]=true
            if index%19==trial:
                command["attack"]="grab" if seen.guarding and distance<1.1 else (["light","heavy","special"][posmod(floori(index/19.0)+trial,3)] if a.meter>=50 else "light")
            if index%151==trial:command["jump"]=true
            if a.wall_tech_window>0 and a.wall_tech_window<=5:command["dash"]=true
        if sim.exchange.active() and sim.exchange.WINDOW-sim.exchange.clash.remaining>=12:
            var cue: String=seen.cue
            if cue in sim.exchange.CHOICES:command["clash_choice"]=sim.exchange.CHOICES[(sim.exchange.CHOICES.find(cue)+1)%3]
        sim.tick(command)
        for event in sim.events:
            if event.kind=="clash_start":clashes+=1
            elif event.kind=="wall_tech":recoveries+=1
            elif event.kind=="hit":
                hits+=1
                if event.move=="grab":throws+=1
        var valid: bool=sim.exchange.pressure>=0 and sim.exchange.pressure<=90 and sim.remaining>=0 and sim.hitstop>=0
        for f in sim.fighters:
            valid=valid and is_finite(f.x) and is_finite(f.y) and is_finite(f.vx) and is_finite(f.vy) and absf(f.x)<=sim.EDGE+.00001 and f.y>=0 and f.health>=0 and f.health<=100 and f.guard>=0 and f.guard<=100 and f.meter>=0 and f.meter<=100 and f.wall_bounces in [0,1]
        if not valid:
            violations.append({"difficulty":level,"style":style,"trial":trial,"step":step,"fighters":sim.fighters.duplicate(true)})
            break
        if sim.phase!="fight":break
    return {"difficulty":level,"style":style,"trial":trial,"steps":step,"winner":sim.winner,"remaining":sim.remaining,"health":[sim.fighters[0].health,sim.fighters[1].health],"clashes":clashes,"throws":throws,"recoveries":recoveries,"hits":hits,"finished":sim.phase!="fight"}
