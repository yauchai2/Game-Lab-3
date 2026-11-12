extends RefCounted
## Real seconds drive one shared director; existing authored poses remain reusable.
const ARRIVAL_DURATION:=2.05
const SPIN_DURATION:=2.20
const REEL_STOPS:=[1.02,1.20,1.39]
const REVEAL_AT:=1.61
const INPUT_SETTLE:=.16
const ARRIVAL_REAL:=[0.0,.16,.92,1.06,1.20,1.38,1.44,1.68,2.05]
const ARRIVAL_SOURCE:=[0.0,.16,1.04,1.06,1.25,1.42,1.42,1.75,1.95]
const SPIN_REAL:=[0.0,.16,.92,1.39,1.61,1.72,2.02,2.20]
const SPIN_SOURCE:=[2.55,2.63,3.15,3.45,3.50,3.61,3.98,4.10]
static func map_time(t:float,real:Array,source:Array) -> float:
    for i in range(real.size()-1):
        if t<=real[i+1]:return lerpf(source[i],source[i+1],clampf((t-real[i])/(real[i+1]-real[i]),0,1))
    return source[-1]
static func arrival(t:float) -> float:return map_time(t,ARRIVAL_REAL,ARRIVAL_SOURCE)
static func spin(t:float) -> float:return map_time(t,SPIN_REAL,SPIN_SOURCE)
static func reel_angle(index:int,time:float,outcome:int) -> float:
    var start:float=-TAU*(.125+index*.25)
    var finish:float=-TAU*(.125+outcome*.25)+TAU*(5+index)
    return lerpf(start,finish,smoothstep(0.0,REEL_STOPS[index],time))
