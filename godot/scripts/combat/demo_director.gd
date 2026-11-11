extends RefCounted
## Endless autonomous combat: no chapters, presets during play or timed resets.
var age:=0
var needs_setup:=true
var seen: Dictionary={}
var hits:=[0,0]
var longest_combo:=0
var first_hit:=-1
var no_hit_ticks:=0
var longest_gap:=0
var agent=preload("res://scripts/combat/rush_agent.gd").new()
func prepare(s: RefCounted) -> void:
    agent.reset()
    s.training=true;s.arcade_enabled=true;s.endless=true
    s.reset_training()
    s.ai_enabled=false;s.partner_mode=0
    for i in 2:
        s.fighters[i].x=-1.5 if i==0 else 1.5
        s.fighters[i].meter=70.0
    needs_setup=false
func commands(s: RefCounted) -> Array:
    age+=1
    return [agent.choose(s,0,age,2,true),agent.choose(s,1,age,2,true)]
func observe(s: RefCounted) -> void:
    no_hit_ticks+=1
    for event in s.events:
        var label: String=event.kind
        if event.kind=="hit":
            label+="/"+str(event.get("move",""))
            hits[event.attacker]+=1
            if first_hit<0:first_hit=age
            longest_gap=maxi(longest_gap,no_hit_ticks);no_hit_ticks=0
        seen[label]=seen.get(label,0)+1
    longest_combo=maxi(longest_combo,s.combo_hits)
