extends Resource
## Local to the current battlefield. Author a clear lane; no baked city backdrop.
@export var anchor:=Vector3(0,0,3)
@export var heading_degrees:=0.0
@export var entry_offset:=Vector3(-5.0,0,-.25)
@export var backup_entry_offset:=Vector3(5.0,0,-.25)
@export var floor_height:=0.0
@export_flags_3d_physics var collision_mask:=1
@export var dust_color:=Color("b0a1b9")
func world_transform() -> Transform3D:
    return Transform3D(Basis(Vector3.UP,deg_to_rad(heading_degrees)),anchor+Vector3(0,floor_height,0))
func lane_clear(space:PhysicsDirectSpaceState3D,offset:Vector3) -> bool:
    # Sweep an upright machine-sized box, not only a centre line.
    var shape:=BoxShape3D.new();shape.size=Vector3(2.6,2.9,1.5)
    var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=collision_mask
    q.transform=world_transform()*Transform3D(Basis.IDENTITY,offset+Vector3(0,1.55,0))
    q.motion=world_transform().basis*(-offset)
    var cast:=space.cast_motion(q)
    return cast.size()==2 and cast[0]>=.999 and space.intersect_shape(q,1).is_empty()
