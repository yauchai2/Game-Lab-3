extends Node3D
## Visual-only cargo-door kit. Original Tripo GLB and vehicle collision remain unchanged.
func _ready() -> void:
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color("43545b")
    dark.roughness = 1.0
    var light := StandardMaterial3D.new()
    light.albedo_color = Color("d8d1bf")
    light.roughness = 1.0
    var yellow := StandardMaterial3D.new()
    yellow.albedo_color = Color("e3b443")
    yellow.roughness = 1.0
    # Cargo rear is toward local -Z. Dimensions are in world metres in the wrapper.
    for x in [-1.12,0.0,1.12]:
        _bar("DoorVertical",Vector3(x,1.82,-2.765),Vector3(.045,1.90,.045),dark)
    for y in [.87,2.77]:
        _bar("DoorHorizontal",Vector3(0,y,-2.765),Vector3(2.25,.045,.045),dark)
    for side in [-1,1]:
        _bar("LockingBar",Vector3(side*.75,1.83,-2.80),Vector3(.045,1.72,.045),light)
        _bar("Latch",Vector3(side*.75,1.24,-2.84),Vector3(.23,.06,.06),dark)
        for y in [1.12,2.45]:
            _bar("Hinge",Vector3(side*1.07,y,-2.80),Vector3(.18,.11,.05),light)
    _bar("Plate",Vector3(0,.52,-2.79),Vector3(.45,.16,.04),yellow)
func _bar(title: String, at: Vector3, size: Vector3, material: Material) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.name = title
    instance.mesh = mesh
    instance.material_override = material
    instance.position = at
    add_child(instance,true)
