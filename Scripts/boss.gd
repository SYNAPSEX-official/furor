extends CharacterBody2D

const SPEED: float = 150.0
const FLOAT_SPEED: float = 1.5
const FLOAT_HEIGHT: float = 35.0

var player: Node2D = null
var health: float = 5.0
var is_hurt: bool = false
var start_y: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_y = global_position.y

	print("========== BOSS READY ==========")
	print("[BOSS] Health: ", health)
	print("[BOSS] Sprite found: ", sprite)
	print("[BOSS] Ready!")
	print("================================")


func _physics_process(delta: float) -> void:

	# =========================
	# FLOATING
	# =========================

	var time: float = Time.get_ticks_msec() / 1000.0

	var float_y: float = start_y + (
		sin(time * FLOAT_SPEED) * FLOAT_HEIGHT
	)

	global_position.y = float_y


	# =========================
	# CHASE PLAYER
	# =========================

	if player != null:

		var distance_x: float = (
			player.global_position.x
			- global_position.x
		)

		var direction: float = sign(distance_x)

		velocity.x = direction * SPEED

	else:

		velocity.x = 0.0


	move_and_slide()


# =========================================================
# PLAYER DETECTION
# =========================================================

func _on_detection_area_body_entered(body: Node2D) -> void:

	print("[BOSS] Detection ENTERED: ", body.name)

	if body.name == "Player":

		player = body

		print("[BOSS] ✅ PLAYER DETECTED")


func _on_detection_area_body_exited(body: Node2D) -> void:

	print("[BOSS] Detection EXITED: ", body.name)

	if body == player:

		player = null

		print("[BOSS] ❌ PLAYER LEFT DETECTION")


# =========================================================
# BOSS ATTACKS PLAYER
# =========================================================

func _on_damage_area_body_entered(body: Node2D) -> void:

	print("[BOSS] Damage Area touched: ", body.name)

	if body.name == "Player":

		print("[BOSS] ⚔️ BOSS HIT PLAYER")

		Global.take_damage()

		print("[BOSS] Global.take_damage() called")


# =========================================================
# BOSS TAKES DAMAGE
# =========================================================

func take_damage(damage: float) -> void:

	print("")
	print("================================")
	print("💥 BOSS GOT HIT!")
	print("================================")

	print("[BOSS] Damage received: ", damage)
	print("[BOSS] Health BEFORE: ", health)


	# Don't allow multiple hits during flash
	if is_hurt:

		print("[BOSS] ⚠️ Already hurt!")
		return


	# =========================
	# APPLY DAMAGE
	# =========================

	health -= damage

	print("[BOSS] Health AFTER: ", health)


	is_hurt = true


	# =========================
	# 🔴 RED FLASH
	# =========================

	print("[BOSS] 🔴 SETTING SPRITE RED")

	sprite.modulate = Color(1.0, 0.0, 0.0, 1.0)

	print("[BOSS] Sprite modulate is now: ", sprite.modulate)


	# =========================
	# KNOCKBACK
	# =========================

	if player != null:

		var knockback_direction: float = sign(
			global_position.x
			- player.global_position.x
		)

		velocity.x = knockback_direction * 150.0

		print("[BOSS] 👊 Knockback applied")


	# =========================
	# WAIT
	# =========================

	await get_tree().create_timer(0.15).timeout


	# =========================
	# RESTORE COLOR
	# =========================

	sprite.modulate = Color.WHITE

	is_hurt = false

	print("[BOSS] ⚪ Sprite restored")


	# =========================
	# DEATH
	# =========================

	if health <= 0.0:

		print("")
		print("💀💀💀 BOSS DEAD 💀💀💀")

		sprite.modulate = Color(
			1.0,
			0.0,
			0.0,
			1.0
		)

		await get_tree().create_timer(0.15).timeout

		print("[BOSS] 🗑️ Removing boss")

		queue_free()
