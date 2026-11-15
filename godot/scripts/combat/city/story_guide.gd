extends RefCounted
## Read-only recommendations. Navigation still walks to the real station.
const W=preload("res://scripts/combat/city/hub_widgets.gd")
const T=preload("res://scripts/combat/ui/ui_theme.gd")

static func next_step(p:RefCounted,hero:int) -> Dictionary:
    if p.error!="":return {"station":4,"text":"Save needs attention. Open DEPART to reload your saved profile."}
    if not p.data.run.is_empty() and p.data.run.boon_due:
        return {"station":4,"text":"Choose a current at DEPART, then continue. Currents last until the expedition ends."}
    if p.data.points>p.data.talents[hero].size():
        return {"station":1,"text":"Talent points are ready. At CIRCUIT, select a connected node and CONNECT. Reset is free."}
    var rank:int=int(p.data.skill_levels[hero])
    if rank<3 and p.data.credits>=30 and p.data.parts>=2+rank:
        return {"station":0,"text":"You can upgrade L. Visit SKILLS: 30 credits plus parts gives +5% skill damage per rank."}
    return {"station":4,"text":"Ready to fight. Visit DEPART and choose GO. All basic moves are available from the first encounter."}

static func page(hub:Node) -> void:
    W.head(hub,"radio","STORY GUIDE",T.TEAL)
    hub.set_info("Scroll for combat controls, upgrades and equipment. Esc closes this guide.")
    W.section(hub,"play","FIGHT / RETURN / GROW")
    W.guide(hub,"Walk with WASD or click the floor. E uses a nearby station; 1-6 walks there. Tab shows station shortcuts. H reopens this guide.")
    var step:Dictionary=next_step(hub.campaign.profile,hub.campaign.hero_id())
    W.guide(hub,step.text)
    W.cta(hub,"arrow","GO TO NEXT STEP",T.LIME,func():hub.request_station(int(step.station)),false,"guide_next")
    W.section(hub,"fist","YOUR FULL BASIC KIT")
    W.guide(hub,"Hold J to chain attacks. K launches on the ground and slams in the air. Space jumps; release and press again for a double jump. G grabs nearby enemies.")
    W.guide(hub,"After a launcher hits, J or E spends 20 energy to chase. L uses 50 energy; W + L uses 75. Land attacks to rebuild energy. Shift guards; a well-timed guard parries, then J counters.")
    W.cta(hub,"fist","PRACTISE BASIC MOVES",T.TEAL,func():hub.request_station(0),false,"guide_practice")
    W.section(hub,"star","PERMANENT UPGRADES")
    W.guide(hub,"SKILLS: strengthen L with credits and parts. CIRCUIT: spend level-up points on connected talents, with free reset. Advanced techniques still unlock later in the story.")
    W.guide(hub,"SHOP: select loot, compare stats and FIT. Wrist, sole and belt equipment is separate for each hero. DEALER: optional gear draws; you can also earn gear by fighting.")
    W.cta(hub,"gear","MANAGE EQUIPMENT",T.TEAL,func():hub.request_station(5),false,"guide_equipment")
    W.section(hub,"flag","AFTER EACH ENCOUNTER")
    W.guide(hub,"Enter continues through the current and route choices. Esc returns home to upgrade. Banked credits, gear and talents stay after defeat; currents and the expedition core are temporary.")

static func combat_tip(f:Dictionary,special_cost:int=50,overdrive_cost:int=75) -> String:
    if f.get("counter_window",0)>0:return "PARRY! J: counterattack."
    if f.air.chase_window>0 and not f.air.chase_used:
        return "LAUNCH HIT: J / E chases for 20 energy." if f.meter>=20 else "CHASE NEEDS 20 ENERGY. Land attacks to recharge."
    if f.y>.1:return "AIR: J chains / K slams." if f.air.double_used else "AIR: J chains / K slams / release Space, then jump again."
    if f.meter>=overdrive_cost:return "W + L: overdrive (%d) / L: skill (%d) / Shift: guard."%[overdrive_cost,special_cost]
    if f.meter>=special_cost:return "L: skill (%d) / K: launch / J: chain / G: grab."%special_cost
    return "J: chain / K: launch / Shift: guard / land hits to recharge."
