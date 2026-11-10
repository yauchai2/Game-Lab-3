extends Node
## Low-resolution, tileable texture multipliers on per-instance materials.
## Source whitebox resources and all user GLBs remain unchanged.
const ROAD = preload("res://assets/textures/road_asphalt_128.png")
const SIDEWALK = preload("res://assets/textures/sidewalk_tiles_128.png")
const WALL = preload("res://assets/textures/painted_concrete_128.png")
var applied: Array[MeshInstance3D] = []
@onready var street: Node3D = get_parent().get_node("Street")
func _ready() -> void:
    for mesh in street.get_node("StreetGeometry").get_children():
        if not mesh is MeshInstance3D:
            continue
        if mesh.name in ["MainRoad","EntranceCrossStreet","SideAlley"]:
            _apply(mesh,ROAD,.25)
        elif str(mesh.name).begins_with("Sidewalk"):
            _apply(mesh,SIDEWALK,.5)
    var walls := ["BlueFront","OldLeftA","OldLeftB","OldLeftC","OrangeFront","OrangeMid","RightOld","RightFar","DistantBlock"]
    for title in walls:
        var mesh = street.get_node("BuildingMasses").get_node_or_null(title)
        if mesh is MeshInstance3D:
            _apply(mesh,WALL,.25)
func _apply(mesh: MeshInstance3D, texture: Texture2D, scale: float) -> void:
    var source := mesh.get_active_material(0)
    if not source is BaseMaterial3D:
        return
    var material: BaseMaterial3D = source.duplicate(true)
    material.albedo_texture = texture
    material.uv1_triplanar = true
    material.uv1_world_triplanar = true
    material.uv1_scale = Vector3.ONE*scale
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
    mesh.material_override = material
    applied.append(mesh)
