extends RefCounted
## Original editable ink cels. All dimensions are world metres; no reference art.
const PAPER=Color("fff7df")
const INK=Color("252237")
const HOLDS=[0.0,.10,.25,.43,.65,.84]
const RECIPES={
    "step":Vector3(.28,.14,.24),"run":Vector3(.40,.20,.28),
    "dash":Vector3(.72,.26,.34),"brake":Vector3(.62,.32,.38),
    "jump":Vector3(.42,.20,.27),"land":Vector3(.60,.24,.34),
    "slam":Vector3(1.02,.46,.52),"wake":Vector3(.34,.28,.38),
    "impact":Vector3(.45,.32,.36),"heavy":Vector3(.72,.42,.46),
    "launch":Vector3(.46,.64,.44),"parry":Vector3(.35,.25,.24)}
# Six asymmetric silhouettes, compressed first cel then rolling broken tail.
const OUTLINES=[
    [Vector2(-.90,0),Vector2(-.70,.19),Vector2(-.15,.28),Vector2(.48,.18),Vector2(1,0)],
    [Vector2(-1,0),Vector2(-.92,.35),Vector2(-.64,.44),Vector2(-.46,.78),Vector2(-.09,.86),Vector2(.14,.60),Vector2(.50,.63),Vector2(.66,.28),Vector2(.95,.19),Vector2(1,0)],
    [Vector2(-1,0),Vector2(-.85,.31),Vector2(-.65,.27),Vector2(-.76,.57),Vector2(-.48,.91),Vector2(-.15,1),Vector2(.10,.80),Vector2(.02,.52),Vector2(.36,.68),Vector2(.66,.48),Vector2(.64,.25),Vector2(.94,.21),Vector2(1,0)],
    [Vector2(-.95,.10),Vector2(-.82,.32),Vector2(-.57,.26),Vector2(-.66,.60),Vector2(-.36,.91),Vector2(-.04,.87),Vector2(.05,.65),Vector2(-.18,.55),Vector2(.10,.42),Vector2(.40,.62),Vector2(.66,.43),Vector2(.63,.20),Vector2(.91,.12),Vector2(.65,.02)],
    [Vector2(-.80,.23),Vector2(-.62,.46),Vector2(-.41,.40),Vector2(-.45,.71),Vector2(-.13,.92),Vector2(.14,.74),Vector2(-.08,.62),Vector2(.23,.44),Vector2(.43,.58),Vector2(.61,.37),Vector2(.32,.22),Vector2(.49,.08),Vector2(.04,.12),Vector2(-.29,.29)],
    [Vector2(-.55,.41),Vector2(-.34,.68),Vector2(-.12,.63),Vector2(.05,.79),Vector2(.18,.64),Vector2(.02,.48),Vector2(.28,.41),Vector2(.20,.27),Vector2(-.05,.33),Vector2(-.24,.45)]
]
static func cel(t:float) -> int:
    for i in range(HOLDS.size()-1,-1,-1):
        if t>=HOLDS[i]:return i
    return 0
static func rank(kind:String) -> int:
    if kind in ["hit","parry","block","guard_break","rally_core","air_counter_core","grab_tell"]:return 3
    if kind in ["release","swing","charge","cannon_charge","cannon_blast","service_pulse","wave"]:return 2
    return 0
static func limb(move:String,character:int,fighter:Dictionary={}) -> String:
    if not fighter.is_empty():
        var selected:String=preload("res://scripts/combat/last_service/street_motion.gd").striking_limb(fighter)
        if selected!="":return selected
    if character==0:return "LeftFoot" if move in ["jab","air_jab","special"] else "RightFoot"
    if move in ["heavy","air_kick","air_counter","meteor"]:return "RightFoot"
    return "LeftHand" if move in ["jab","air_jab"] else "RightHand"
static func outline(frame:int,variant:int) -> PackedVector2Array:
    var p:=PackedVector2Array(OUTLINES[frame])
    for i in p.size():
        p[i].x*=1.0 if variant%2==0 else -1.0
        p[i].x+=sin(float(i)*1.7+variant)*.035
    return p
