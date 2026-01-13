extends CharacterBody3D

@export_group("Bean Custom Properties")
@export var speed: float = 5.0
@export var jump_velocity: float = 4.0
@export var phantom_camera: PhantomCamera3D

var _camera_yaw: float = 0
var _camera_pitch: float = 0
var _camera_distance: float = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    if self.is_on_floor():
        velocity += get_gravity() * delta
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction_before_camera_rot: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
    var direction: Vector3 = direction_before_camera_rot.rotated(Vector3.UP, phantom_camera.rotation.y)
    if direction != Vector3.ZERO:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        look_at(direction+position, Vector3.UP, true)
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    const sens: float = 0.01
    const distanceSens: float = 0.5

    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else Input.MOUSE_MODE_VISIBLE 

    if (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and event is InputEventMouseMotion):
        var input_event_: InputEventMouseMotion = event
        _camera_yaw -= input_event_.relative.x * sens
        _camera_pitch -= input_event_.relative.y * sens
        _camera_pitch = clamp(_camera_pitch, deg_to_rad(-50), deg_to_rad(60))
        _update_camera_position()  
        
func _update_camera_position() -> void:
    if not phantom_camera:
        return
    var rotation_: Quaternion = Quaternion.from_euler(Vector3(_camera_pitch, _camera_yaw, 0))
    var offset: Vector3 = rotation_ * Vector3.BACK * 30
    phantom_camera.follow_offset = offset
    var cam3d: Camera3D = PhantomCameraManager.get_phantom_camera_hosts()[0].camera_3d
    cam3d.size = _camera_distance
    
    
    
