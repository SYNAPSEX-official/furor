extends CharacterBody2D

const SPEED: float = 100.0
const FLOAT_SPEED: float = 1.5
const FLOAT_HEIGHT: float = 35.0

const FIRE_COOLDOWN: float = 1.5
const FIRE_RANGE: float = 500.0

var health: float = 100.0
var is_hurt: bool = false

var player: Node2D = null

var start_y: float = 0.0
var fire_timer: float = 0.0
var firing: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_y = global_position.y
	fire_timer = FIRE_COOLDOWN
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	var time_now: float = Time.get_ticks_msec() / 1000.0

	global_position.y = start_y + (
		sin(time_now * FLOAT_SPEED) * FLOAT_HEIGHT
	)

	if player != null and not firing:
		var distance_x: float = (
			player.global_position.x
			- global_position.x
		)

		var direction: float = sign(distance_x)
		velocity.x = direction * SPEED

	else:
		velocity.x = 0.0

	fire_timer -= delta

	if fire_timer <= 0.0 and player != null and not firing:
		var distance_to_player: float = (
			global_position.distance_to(
				player.global_position
			)
		)

		if distance_to_player <= FIRE_RANGE:
			fire()

	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


func fire() -> void:
	if firing or player == null:
		return

	firing = true
	fire_timer = FIRE_COOLDOWN
	velocity.x = 0.0

	if player.global_position.x < global_position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	sprite.play("fire")

	await get_tree().create_timer(0.25).timeout

	if player == null:
		firing = false
		sprite.play("idle")
		return

	var distance_to_player: float = (
		global_position.distance_to(
			player.global_position
		)
	)

	if distance_to_player <= FIRE_RANGE:
		Global.take_damage()

	await get_tree().create_timer(0.25).timeout

	firing = false

	if player != null:
		sprite.play("idle")


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.take_damage()


func take_damage(damage: float) -> void:
	if is_hurt:
		return

	health -= damage
	is_hurt = true

	if player != null:
		var knockback_direction: float = sign(
			global_position.x
			- player.global_position.x
		)

		velocity.x = knockback_direction * 150.0

	modulate = Color(1.0, 0.3, 0.3)

	await get_tree().create_timer(0.12).timeout

	modulate = Color.WHITE
	is_hurt = false

	if health <= 0.0:
		queue_free()
