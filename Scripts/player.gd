extends CharacterBody2D

######################
# NODES
######################

@onready var canvas_layer: CanvasLayer = $"../Camera2D/CanvasLayer"

@onready var health_bar: TextureProgressBar = canvas_layer.get_node(
	"Control/MarginContainer/HBoxContainer/HP bar/BlueBar"
)

@onready var points: Label = canvas_layer.get_node(
	"Control/MarginContainer/HBoxContainer/Label"
)

@onready var camera: Camera2D = $"../Camera2D"
@onready var noise_emitter: PhantomCameraNoiseEmitter2D = $PhantomCamera2D/PhantomCameraNoiseEmitter2D

@onready var attack_area: Area2D = $attack_area
@onready var attack_collision: CollisionShape2D = $attack_area/CollisionShape2D
var attack_damage: float = Global.attack

@onready var skin: AnimatedSprite2D = $skin
@onready var hair: AnimatedSprite2D = $hair
@onready var bottom: AnimatedSprite2D = $bottom_clothe
@onready var top: AnimatedSprite2D = $top_clothe
@onready var sword: AnimatedSprite2D = $sword

######################
# VARIABLES
######################

const SPEED: float = 500.0
const JUMP_VELOCITY: float = -1000.0

const ACCELERATION: float = 4000.0
const DECELERATION: float = 3500.0

const AIR_ANIM_DEADZONE: float = 40.0

const MAX_FALL_SPEED: float = 1400.0

const JUMP_CUT_MULTIPLIER: float = 0.45

const APEX_GRAVITY_MULTIPLIER: float = 0.55
const APEX_VELOCITY_THRESHOLD: float = 120.0

# Coyote time
var coyote_time: float = 0.15
var coyote_timer: float = 0.0

# Jump buffer
var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0

# PLAYER CUSTOMIZATION

var gender: String = Global.gender
var skin_type: String = str(Global.skin)

var top_clothe: String = "blue_shirt_2"
var bottom_clothe: String = "green_pants"

var hair_style: String = str(randi_range(1, 5))
var socks: String = ""
var shoes: String = ""


# HEALTH SYSTEM
var health: float = 100.0
var attack: float = 0.0
var previous_health: float = 100.0

var invulnerable: bool = false
var invulnerability_time: float = 0.6
var invulnerability_timer: float = 0.0


# CLOTHING SYSTEM
var top_cloth_time: float = 20.0
var top_cloth_timer: float = 0.0

var bottom_clothe_time: float = 20.0
var bottom_clothe_timer: float = 0.0

var top_damage_multi: bool = false
var bottom_damage_multi: bool = false


# DEATH
var dying: bool = false

# POINTS
var rage: float = 0.0

# JUICE VARIABLES
var was_on_floor: bool = true
var last_air_anim_was_jump: bool = true

# Fall tracking
var apex_y: float = 0.0
var was_airborne: bool = false

# SQUASH / STRETCH

var squash_tween: Tween
var skin_base_scale: Vector2
var top_base_scale: Vector2
var bottom_base_scale: Vector2
var hair_base_scale: Vector2


# CAMERA SHAKE
const BASE_SHAKE_AMPLITUDE: float = 30.0
const BASE_SHAKE_FREQUENCY: float = 28.0
const FREQUENCY_PER_INTENSITY: float = 10.0
const MIN_SHAKE_AXIS_MULTIPLIER: float = 0.35
var camera_base_offset: Vector2 = Vector2.ZERO

var attacking: bool = false
# HIT FLASH
var flash_tween: Tween

var hitstop_active_count: int = 0

# READY
func _ready() -> void:
	print("GENDER: ", Global.gender)
	print("TOP: ", Global.top_cloth)
	print("BOTTOM: ", Global.bottom_cloth)

	gender = Global.gender
	skin_type = str(Global.skin)
	top_clothe = Global.top_cloth
	bottom_clothe = Global.bottom_cloth

	print("PLAYER TOP: ", top_clothe)
	print("PLAYER BOTTOM: ", bottom_clothe)

	if Global.health <= 0.0:
		Global.health = 100.0

	health = Global.health
	previous_health = health

	Global.is_alive = true
	dying = false

	top_cloth_timer = top_cloth_time
	bottom_clothe_timer = bottom_clothe_time

	if camera:
		camera_base_offset = camera.offset

	skin_base_scale = skin.scale
	top_base_scale = top.scale
	bottom_base_scale = bottom.scale
	hair_base_scale = hair.scale

######################
# PHYSICS
######################

func _physics_process(delta: float) -> void:
	if dying:
		return

	if Input.is_action_just_pressed("attack") and not attacking:
		attack_player()


	###############################
	# UPDATE SCORE
	###############################

	rage = Global.rage
	points.text = "Score: " + str(rage)


	###############################
	# CLOTHING SYSTEM
	###############################
	top_clothe = Global.top_cloth
	bottom_clothe = Global.bottom_cloth

	top_cloth_timer = max(
		top_cloth_timer - delta,
		0.0
	)

	bottom_clothe_timer = max(
		bottom_clothe_timer - delta,
		0.0
	)

	if top_cloth_timer <= 0.0 or bottom_clothe_timer <= 0.0:
		Global.damage_multiplier = 2.5
	else:
		Global.damage_multiplier = 1.0


	###############################
	# HEALTH SYSTEM
	###############################

	health = Global.health

	health_bar.value = health * 5.0

	# Invulnerability countdown + blink so the player can SEE they're
	# briefly safe (classic "i-frames" feedback).
	if invulnerable:
		invulnerability_timer = max(invulnerability_timer - delta, 0.0)

		var blink_visible: bool = fmod(invulnerability_timer, 0.12) > 0.06
		skin.visible = blink_visible
		top.visible = blink_visible
		bottom.visible = blink_visible
		hair.visible = blink_visible
		sword.visible = blink_visible  # FIX #5: sword now blinks too

		if invulnerability_timer <= 0.0:
			invulnerable = false
			skin.visible = true
			top.visible = true
			bottom.visible = true
			hair.visible = true
			sword.visible = true

	# Detect damage — ignored while invulnerable, see note above.
	if health < previous_health and not invulnerable:
		on_damaged()
		invulnerable = true
		invulnerability_timer = invulnerability_time

	previous_health = health

	# Death from zero health
	if health <= 0.0:
		die()
		return


	###############################
	# COYOTE TIME + GRAVITY
	###############################
	# Runs even while attacking now, so an air-attack still falls/lands
	# normally instead of hanging frozen in place (FIX #1).

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		var gravity_scale: float = 2.0

		# Hang time near the apex — velocity.y is close to 0 right at
		# the top of a jump, so briefly ease off gravity there.
		if abs(velocity.y) < APEX_VELOCITY_THRESHOLD:
			gravity_scale = 2.0 * APEX_GRAVITY_MULTIPLIER

		velocity += get_gravity() * delta * gravity_scale
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

		coyote_timer = max(
			coyote_timer - delta,
			0.0
		)


	###############################
	# JUMP BUFFER
	###############################

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(
			jump_buffer_timer - delta,
			0.0
		)

	if Input.is_action_just_pressed("jump") and not attacking:
		jump_buffer_timer = jump_buffer_time


	###############################
	# JUMP
	###############################
	# Suppressed while attacking - you shouldn't be able to jump-cancel
	# out of an attack mid-swing.

	if not attacking and coyote_timer > 0.0 and jump_buffer_timer > 0.0:
		velocity.y = JUMP_VELOCITY

		jump_buffer_timer = 0.0
		coyote_timer = 0.0

		on_jump()


	###############################
	# VARIABLE JUMP HEIGHT
	###############################

	# Releasing jump early while still ascending cuts the velocity down,
	# giving a short hop instead of the full arc.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER
		shake(0.3)


	###############################
	# HORIZONTAL MOVEMENT
	###############################

	var direction: float = 0.0

	if not attacking:
		direction = Input.get_axis(
			"left",
			"right"
		)

	if direction != 0.0:

		velocity.x = move_toward(
			velocity.x,
			direction * SPEED,
			ACCELERATION * delta
		)

		# Face direction
		if direction > 0.0:
			skin.flip_h = true
			top.flip_h = true
			bottom.flip_h = true
			hair.flip_h = true
			sword.flip_h = true

		else:
			skin.flip_h = false
			top.flip_h = false
			bottom.flip_h = false
			hair.flip_h = false
			sword.flip_h = false

	else:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			DECELERATION * delta
		)


	###############################
	# ANIMATION SPEED
	###############################

	var speed_ratio: float = clamp(
		abs(velocity.x) / SPEED,
		0.3,
		1.0
	)


	###############################
	# FALL TRACKING
	###############################

	if not is_on_floor():

		if not was_airborne:
			apex_y = global_position.y
			was_airborne = true

		else:
			apex_y = min(
				apex_y,
				global_position.y
			)

	else:
		was_airborne = false


	###############################
	# MOVE PLAYER
	###############################

	move_and_slide()


	###############################
	# LANDING DETECTION
	###############################

	if not was_on_floor and is_on_floor():
		on_landed()

	was_on_floor = is_on_floor()


	###############################
	# PLAYER ANIMATIONS
	###############################
	# Skipped entirely while attacking so the attack animation (started
	# in attack_player()) doesn't get stomped every frame by idle/run/
	# jump/fall (FIX #1 continued).

	if attacking:
		pass

	elif not is_on_floor():

		var play_jump: bool

		if velocity.y < -AIR_ANIM_DEADZONE:
			play_jump = true

		elif velocity.y > AIR_ANIM_DEADZONE:
			play_jump = false

		else:
			play_jump = last_air_anim_was_jump

		last_air_anim_was_jump = play_jump

		skin.speed_scale = 1.0
		top.speed_scale = 1.0
		bottom.speed_scale = 1.0
		hair.speed_scale = 1.0

		if play_jump:
			skin.play(skin_anim("jump"))
			top.play(top_anim("jump"))
			bottom.play(bottom_anim("jump"))
			hair.play(hair_anim("jump"))
			sword.play(sword_anim("jump"))
		else:
			skin.play(skin_anim("fall"))
			top.play(top_anim("fall"))
			bottom.play(bottom_anim("fall"))
			hair.play(hair_anim("fall"))
			sword.play(sword_anim("fall"))


	elif direction != 0.0:

		skin.speed_scale = speed_ratio
		top.speed_scale = speed_ratio
		bottom.speed_scale = speed_ratio
		hair.speed_scale = speed_ratio

		skin.play(skin_anim("run"))
		top.play(top_anim("run"))
		bottom.play(bottom_anim("run"))
		hair.play(hair_anim("run"))
		sword.play(sword_anim("run"))

	else:

		skin.speed_scale = 1.0
		top.speed_scale = 1.0
		bottom.speed_scale = 1.0
		hair.speed_scale = 1.0

		skin.play(skin_anim("idle"))
		top.play(top_anim("idle"))
		bottom.play(bottom_anim("idle"))
		hair.play(hair_anim("idle"))
		sword.play(sword_anim("idle"))

###############################
# SQUASH & STRETCH
###############################

func squash_stretch(
	factor_x: float,
	factor_y: float,
	duration: float = 0.12
) -> void:

	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()

	skin.scale = skin_base_scale * Vector2(
		factor_x,
		factor_y
	)

	top.scale = top_base_scale * Vector2(
		factor_x,
		factor_y
	)

	bottom.scale = bottom_base_scale * Vector2(
		factor_x,
		factor_y
	)

	hair.scale = hair_base_scale * Vector2(
		factor_x,
		factor_y
	)

	squash_tween = create_tween().set_parallel(true)

	squash_tween.set_trans(
		Tween.TRANS_ELASTIC
	)

	squash_tween.set_ease(
		Tween.EASE_OUT
	)

	squash_tween.tween_property(
		skin,
		"scale",
		skin_base_scale,
		duration
	)

	squash_tween.tween_property(
		top,
		"scale",
		top_base_scale,
		duration
	)

	squash_tween.tween_property(
		bottom,
		"scale",
		bottom_base_scale,
		duration
	)

	squash_tween.tween_property(
		hair,
		"scale",
		hair_base_scale,
		duration
	)


###############################
# JUMP
###############################

func on_jump() -> void:
	squash_stretch(
		0.8,
		1.25,
		0.15
	)


###############################
# LANDING
###############################

func on_landed() -> void:

	var fall_distance: float = (
		global_position.y - apex_y
	)

	var impact: float = clamp(
		fall_distance / 300.0,
		0.0,
		1.0
	)

	var squash_amount: float = lerp(
		0.95,
		0.55,
		impact
	)

	var stretch_amount: float = lerp(
		1.05,
		1.35,
		impact
	)

	squash_stretch(
		squash_amount,
		stretch_amount,
		0.18
	)

	if impact > 0.15:
		shake(impact, Vector2.DOWN)


###############################
# CAMERA SHAKE
###############################
func shake(intensity: float = 1.0, direction: Vector2 = Vector2.ZERO) -> void:
	if noise_emitter == null or noise_emitter.noise == null:
		return

	var noise: PhantomCameraNoise2D = noise_emitter.noise

	noise.set_amplitude(BASE_SHAKE_AMPLITUDE * intensity)
	noise.set_frequency(BASE_SHAKE_FREQUENCY + intensity * FREQUENCY_PER_INTENSITY)

	# Directional weighting - shake mostly along the impact axis while
	# keeping a bit of jitter on the perpendicular axis for juice.
	if direction == Vector2.ZERO:
		noise.set_positional_multiplier_x(1.0)
		noise.set_positional_multiplier_y(1.0)
	else:
		var d: Vector2 = direction.normalized()
		noise.set_positional_multiplier_x(lerpf(MIN_SHAKE_AXIS_MULTIPLIER, 1.0, absf(d.x)))
		noise.set_positional_multiplier_y(lerpf(MIN_SHAKE_AXIS_MULTIPLIER, 1.0, absf(d.y)))

	noise_emitter.emit()

###############################
# HIT FLASH
###############################

func on_damaged() -> void:
	shake(0.6)

	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	skin.modulate = Color(
		4.0,
		4.0,
		4.0
	)

	top.modulate = Color(
		4.0,
		4.0,
		4.0
	)

	bottom.modulate = Color(
		4.0,
		4.0,
		4.0
	)

	hair.modulate = Color(
		4.0,
		4.0,
		4.0
	)

	flash_tween = create_tween().set_parallel(true)

	flash_tween.tween_property(
		skin,
		"modulate",
		Color.WHITE,
		0.15
	)

	flash_tween.tween_property(
		top,
		"modulate",
		Color.WHITE,
		0.15
	)

	flash_tween.tween_property(
		bottom,
		"modulate",
		Color.WHITE,
		0.15
	)

	flash_tween.tween_property(
		hair,
		"modulate",
		Color.WHITE,
		0.15
	)

	hitstop(0.04)


###############################
# HITSTOP
###############################

func hitstop(duration: float) -> void:
	# FIX #4: track overlapping hitstop requests with a counter so a
	# second hit landing during the first one's freeze doesn't get its
	# time_scale reset stolen early by the first coroutine finishing.
	hitstop_active_count += 1
	Engine.time_scale = 0.05

	await get_tree().create_timer(
		duration,
		true,
		false,
		true
	).timeout

	hitstop_active_count = max(hitstop_active_count - 1, 0)

	if hitstop_active_count == 0 and not dying:
		Engine.time_scale = 1.0


###############################
# DEATH
###############################

func die() -> void:

	# Prevent death from starting twice
	if dying:
		return

	dying = true
	Global.is_alive = false

	shake(1.0)

	# Restore normal time scale
	hitstop_active_count = 0
	Engine.time_scale = 1.0

	# Stop player movement
	velocity = Vector2.ZERO

	# Allow player and animations to continue
	# while the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	skin.process_mode = Node.PROCESS_MODE_ALWAYS
	top.process_mode = Node.PROCESS_MODE_ALWAYS
	bottom.process_mode = Node.PROCESS_MODE_ALWAYS
	hair.process_mode = Node.PROCESS_MODE_ALWAYS

	# Make sure death isn't hidden by a leftover invulnerability blink
	# or a frozen attack hitbox (FIX #3 follow-through).
	skin.visible = true
	top.visible = true
	bottom.visible = true
	hair.visible = true
	sword.visible = true
	attacking = false
	attack_collision.set_deferred("disabled", true)

	# Play death animations
	skin.play(skin_anim("die"))
	top.play(top_anim("die"))
	bottom.play(bottom_anim("die"))
	hair.play(hair_anim("die"))
	sword.play(sword_anim("die"))

	# Pause everything else
	get_tree().paused = true

	# Wait while paused
	await get_tree().create_timer(
		1.8,
		true
	).timeout

	# Unpause
	get_tree().paused = false

	# Game over
	get_tree().change_scene_to_file(
		"res://UI/game_over.tscn"
	)


###############################
# ANIMATION NAMES
###############################

func skin_anim(action: String) -> String:
	return gender + "_" + skin_type + "_" + action


func top_anim(action: String) -> String:
	return top_clothe + "_" + action


func bottom_anim(action: String) -> String:
	return bottom_clothe + "_" + action


func hair_anim(action: String) -> String:
	return gender + "_" + hair_style + "_" + action

func sword_anim(action: String) -> String:
	return gender + "_" + action

###############################
# NEXT LEVEL AREA
###############################

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not dying:
		get_tree().change_scene_to_file(
			"res://Scenes/level_2.tscn"
		)


###############################
# DEATH AREA
###############################

func _on_death_area_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if dying:
		return
	call_deferred("die")

func attack_player() -> void:
	if attacking or dying:
		return

	attacking = true
	velocity.x = 0.0

	# Play attack animation
	skin.play(skin_anim("attack"))
	top.play(top_anim("attack"))
	bottom.play(bottom_anim("attack"))
	hair.play(hair_anim("attack"))
	sword.play(sword_anim("attack"))

	await get_tree().create_timer(0.1).timeout
	if dying:
		return

	# Enable hitbox
	attack_collision.set_deferred("disabled", false)

	# Hitbox stays active briefly
	await get_tree().create_timer(0.15).timeout
	if dying:
		attack_collision.set_deferred("disabled", true)
		attacking = false
		return

	# Disable hitbox safely
	attack_collision.set_deferred("disabled", true)

	# Prevent instant spam
	await get_tree().create_timer(0.2).timeout
	if dying:
		attacking = false
		return

	attacking = false
	print("Attack finished")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name.begins_with("enemy") and attacking == true:
		body.take_damage(attack_damage)
		print(attack_damage)
