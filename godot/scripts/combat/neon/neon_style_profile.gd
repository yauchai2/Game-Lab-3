extends Resource
## Scene-load variant. Never edits imported meshes or the authoritative simulation.
@export var actor_accents:PackedColorArray=PackedColorArray([Color("00d6d8"),Color("ff921c"),Color("ff459d"),Color("b8ff00")])
@export var sky_top:Color=Color("6e135d")
@export var sky_horizon:Color=Color("ff1684")
@export var effect_limit:=24
@export var recovery_seconds:=0.8
@export var silhouette_seconds:=0.10
@export var accent_roll_degrees:=3.0
@export var signature_roll_degrees:=14.0
@export var rhythm_profiles:Dictionary={
    "launch":[.04,.09,.20,1.65,1],"chase":[.025,.035,.17,1.8,1],
    "parry":[.07,.12,.24,1.65,2],"skill":[.14,.42,.34,1.8,3],
    "overdrive":[.22,.78,.44,1.95,4],"impact":[.08,.14,.28,1.85,5],
    "break":[.16,.22,.34,2.0,6]}
func accent(index:int) -> Color:return actor_accents[clampi(index,0,3)]
