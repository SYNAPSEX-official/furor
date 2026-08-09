extends AnimatableBody2D

@export var speed: float = 100.0

@onready var left_ray: RayCast2D = $left
@onready var right_ray: RayCast2D = $right

var direction := 1.0

func _physics_process(delta: float) -> void:
	if direction > 0 and right_ray.is_colliding():
		direction = -1.0

	elif direction < 0 and left_ray.is_colliding():
		direction = 1.0

	global_position.x += direction * speed * delta
