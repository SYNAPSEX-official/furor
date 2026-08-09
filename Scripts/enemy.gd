extends CharacterBody2D

const SPEED: float = 100.0

var player: Node2D = null
var health: float = 5.0
var is_hurt: bool = false


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


# Enemy takes damage
func take_damage(damage: float) -> void:
	if is_hurt:
		return

	health -= damage
	is_hurt = true

	# Hit flash
	modulate = Color(1.0, 0.3, 0.3)

	# Small knockback
	if player != null:
		velocity.x = sign(global_position.x - player.global_position.x) * 150.0

	await get_tree().create_timer(0.12).timeout

	modulate = Color.WHITE
	is_hurt = false

	if health <= 0.0:
		# Death flash
		modulate = Color(1.0, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		queue_free()
