extends CharacterBody2D

@export var speed: float = 100.0
@export var damage: int = 20

var direction: float = -1.0


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Move left/right
	velocity.x = direction * speed

	move_and_slide()


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
