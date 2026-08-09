extends AnimatableBody2D

@export var fall_delay: float = 0.3
@export var fall_speed: float = 1000.0

var activated: bool = false
var falling: bool = false

var start_position: Vector2


func _ready() -> void:
	start_position = global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not activated:
		activated = true

		await get_tree().create_timer(fall_delay).timeout

		if not Global.is_alive:
			reset_platform()
			return

		falling = true

func _physics_process(delta: float) -> void:
	if not Global.is_alive:
		reset_platform()
		return

	if falling:
		position.y += fall_speed * delta

func reset_platform() -> void:
	falling = false

	global_position = start_position

	activated = false
