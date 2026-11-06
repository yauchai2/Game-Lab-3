extends MeshInstance3D
## Optional depth-based ink pass for the current viewport.
func _ready() -> void:
    var quad := QuadMesh.new()
    quad.size = Vector2(2,2)
    mesh = quad
    var material := ShaderMaterial.new()
    material.shader = load("res://shaders/screen_outline.gdshader")
    # Render before transparent Label3D signs so the screen copy cannot erase them.
    material.render_priority = -100
    material_override = material
    extra_cull_margin = 10000.0
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    visible = false
