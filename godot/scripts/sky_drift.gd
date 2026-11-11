extends RefCounted
## Animate only sky orientation, never sunlight, ambient lighting or scene geometry.
const RADIANS_PER_SECOND := PI / 2250.0 # 0.08 degrees/s; one revolution in 75 min.
var offset := 0.0
func advance(environment: Environment, delta: float, base_yaw: float, stopped := false) -> void:
    if stopped or environment.background_mode != Environment.BG_SKY: return
    offset = wrapf(offset + maxf(delta,0.0) * RADIANS_PER_SECOND, -PI, PI)
    environment.sky_rotation = Vector3(0,base_yaw+offset,0)
