extends AnimatableBody2D

@export var fall_delay: float = 0.3
@export var fall_speed: float = 1000

var activated: bool = false
var falling: bool = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not activated:
		activated = true
		await get_tree().create_timer(fall_delay).timeout
		falling = true


func _physics_process(delta: float) -> void:
	if falling:
		position.y += fall_speed * delta
