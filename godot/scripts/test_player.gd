extends CharacterBody3D
## A scale-reference controller, not a finished character or traversal system.
@export var walk_speed := 4.5
@export var sprint_speed := 7.0
@export var acceleration := 24.0
@export var gravity := 20.0
@export var jump_speed := 6.0
@export var mouse_sensitivity := 0.0025
@export var camera_distance := 3.4
var controls_enabled := false
var first_person := false
var mouse_look_enabled := false
var yaw := 0.0
var pitch := deg_to_rad(-10.0)
var spawn_transform := Transform3D.IDENTITY
var respawn_count := 0
@onready var pivot: Node3D = $ViewPivot
@onready var arm: SpringArm3D = $ViewPivot/SpringArm3D
@onready var camera: Camera3D = $ViewPivot/SpringArm3D/Camera3D
func _ready() -> void:
    spawn_transform = global_transform
    floor_snap_length = 0.25
    safe_margin = 0.01
    arm.add_excluded_object(get_rid())
    _bind("walk_forward",[KEY_W,KEY_UP])
    _bind("walk_back",[KEY_S,KEY_DOWN])
    _bind("walk_left",[KEY_A,KEY_LEFT])
    _bind("walk_right",[KEY_D,KEY_RIGHT])
    _bind("walk_jump",[KEY_SPACE])
    _bind("walk_sprint",[KEY_SHIFT])
    apply_look(Vector2.ZERO)
func _bind(action: StringName, keys: Array) -> void:
    # Preserve pre-existing project/user bindings.
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    for code in keys:
        var event := InputEventKey.new()
        event.physical_keycode = code
        InputMap.action_add_event(action,event)
func set_control_enabled(value: bool) -> void:
    controls_enabled = value
    if not value:
        velocity.x = 0
        velocity.z = 0
func activate_camera(capture_mouse := true) -> void:
    camera.make_current()
    set_control_enabled(true)
    set_mouse_capture(capture_mouse)
func set_mouse_capture(value: bool) -> void:
    # Track application intent separately: headless display drivers cannot capture a cursor.
    mouse_look_enabled = value
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        set_mouse_capture(false)
func set_first_person(value: bool) -> void:
    first_person = value
    arm.spring_length = 0.0 if value else camera_distance
    $Visual.visible = not value
func apply_look(relative: Vector2) -> void:
    yaw = wrapf(yaw-relative.x*mouse_sensitivity,-PI,PI)
    pitch = clampf(pitch-relative.y*mouse_sensitivity,deg_to_rad(-75),deg_to_rad(80))
    pivot.rotation = Vector3(pitch,yaw,0)
func reset_to_spawn() -> void:
    global_transform = spawn_transform
    velocity = Vector3.ZERO
    yaw = 0
    pitch = deg_to_rad(-10)
    apply_look(Vector2.ZERO)
func _unhandled_input(event: InputEvent) -> void:
    if not controls_enabled:
        return
    if event is InputEventMouseMotion and mouse_look_enabled:
        apply_look(event.relative)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        set_mouse_capture(true)
func _physics_process(delta: float) -> void:
    if global_position.y < -10 or absf(global_position.x) > 30 or global_position.z < -85 or global_position.z > 25:
        respawn_count += 1
        reset_to_spawn()
    var input := Vector2.ZERO
    var can_move := controls_enabled and mouse_look_enabled
    if can_move:
        input = Input.get_vector("walk_left","walk_right","walk_forward","walk_back")
    var speed := sprint_speed if can_move and Input.is_action_pressed("walk_sprint") else walk_speed
    var direction := Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
    velocity.x = move_toward(velocity.x,direction.x*speed,acceleration*delta)
    velocity.z = move_toward(velocity.z,direction.z*speed,acceleration*delta)
    if not is_on_floor():
        velocity.y -= gravity*delta
    if can_move and is_on_floor() and Input.is_action_just_pressed("walk_jump"):
        velocity.y = jump_speed
    move_and_slide()
    if direction.length_squared() > 0.01:
        $Visual.rotation.y = lerp_angle($Visual.rotation.y,atan2(-direction.x,-direction.z),minf(12*delta,1))
