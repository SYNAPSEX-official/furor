extends CharacterBody2D

const SPEED: float = 100.0

var player: Node2D = null


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Chase player
	if player != null:
		velocity.x = sign(player.global_position.x - global_position.x) * SPEED
	else:
		velocity.x = 0.0

	move_and_slide()


# Player enters detection area
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body


# Player leaves detection area
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

# Player enters damage area
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.take_damage()
