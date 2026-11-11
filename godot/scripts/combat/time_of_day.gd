extends RefCounted
## Lighting-only time-of-day presets. Presentation only: no collision, rule or music change.
const NAMES:=[["白晝","DAY"],["黃昏","DUSK"],["深夜","NIGHT"],["霧晨","FOG"],["黑白","MONO"]]
# sun color, sun energy, ambient color, ambient energy, brightness, saturation, fog density, fog color
const PRESETS:=[
    {"sun":Color("ffe8c2"),"sun_e":0.85,"amb":Color("9eb8db"),"amb_e":0.7,"bright":1.0,"sat":1.0,"fog":0.0,"fog_c":Color("c8d4e6"),"nb":1.0,"nfog":0.0},
    {"sun":Color("ff9a5c"),"sun_e":0.7,"amb":Color("c48aa8"),"amb_e":0.62,"bright":0.96,"sat":1.12,"fog":0.0,"fog_c":Color("e8a07a"),"nb":0.92,"nfog":0.006},
    {"sun":Color("7f9cff"),"sun_e":0.38,"amb":Color("4a5a9a"),"amb_e":0.5,"bright":0.88,"sat":1.1,"fog":0.0,"fog_c":Color("1c2448"),"nb":0.66,"nfog":0.009},
    {"sun":Color("e4ecf0"),"sun_e":0.5,"amb":Color("b4c0c8"),"amb_e":0.85,"bright":1.0,"sat":0.7,"fog":0.012,"fog_c":Color("c6ced4"),"nb":1.0,"nfog":0.012},
    {"sun":Color("e8e8e8"),"sun_e":0.8,"amb":Color("a8a8a8"),"amb_e":0.75,"bright":1.0,"sat":0.0,"fog":0.0,"fog_c":Color("c8c8c8"),"nb":1.0,"nfog":0.0},
]
static func clamp_index(value:int) -> int:return clampi(value,0,PRESETS.size()-1)
static func label(index:int,english:bool) -> String:return NAMES[clamp_index(index)][1 if english else 0]
static func apply(environment:Environment,sun:DirectionalLight3D,index:int) -> void:
    var p:Dictionary=PRESETS[clamp_index(index)]
    sun.light_color=p.sun;sun.light_energy=p.sun_e
    environment.ambient_light_color=p.amb;environment.ambient_light_energy=p.amb_e
    environment.adjustment_enabled=index!=0
    environment.adjustment_brightness=p.bright;environment.adjustment_saturation=p.sat
    environment.fog_enabled=p.fog>0.0
    environment.fog_light_color=p.fog_c;environment.fog_density=p.fog
