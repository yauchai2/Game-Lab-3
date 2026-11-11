extends RefCounted
## Normal-health AI exhibition; session owns entry / KO / next-round timing.
var rounds_finished:=0
var matches_finished:=0
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
    s.training=false;s.arcade_enabled=true;s.endless=false
    s.restart_match()
    s.ai_enabled=false;s.partner_mode=0
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

func advance_round(s:RefCounted) -> void:
    rounds_finished+=1
    if s.phase=="match_over":matches_finished+=1;s.restart_match()
    else:s.next_round()
    s.training=false;s.endless=false;s.ai_enabled=false
    agent.reset()
