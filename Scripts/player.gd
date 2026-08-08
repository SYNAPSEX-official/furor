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

@onready var skin: AnimatedSprite2D = $skin
@onready var hair: AnimatedSprite2D = $hair
@onready var bottom: AnimatedSprite2D = $bottom_clothe
@onready var top: AnimatedSprite2D = $top_clothe

##########################
# VARIABLES
##########################

const SPEED: float = 500.0
const JUMP_VELOCITY: float = -700.0

# Coyote time
var coyote_time: float = 0.15
var coyote_timer: float = 0.0

# Jump buffer
var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0

var gender = Global.gender
# Player customization
var skin_type = Global.skin
var top_clothe: String = "blue_shirt_2"
var bottom_clothe: String = "green_pants"
var hair_style = "1"
var socks
var shoes

# Health system
var health = Global.health
var attack = Global.attack
var previous_health: float = 0.0

# Clothing system
var top_cloth_time: float = 20.0
var top_cloth_timer: float = 0.0

var bottom_clothe_time: float = 20.0
var bottom_clothe_timer: float = 0.0

var top_damage_multi: bool = false
var bottom_damage_multi: bool = false

# Death
var dying: bool = false

#Points
var rage = Global.rage

##########################
# JUICE VARIABLES
##########################

var was_on_floor: bool = true
var fall_start_y: float = 0.0
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.18

# Squash/stretch tweens (kept as refs so we can kill & restart cleanly)
var squash_tween: Tween

var skin_base_scale: Vector2
var top_base_scale: Vector2
var bottom_base_scale: Vector2

# Screen shake
var shake_strength: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var camera_base_offset: Vector2 = Vector2.ZERO

# Hit flash
var flash_tween: Tween


###############################
# READY
###############################

func _ready() -> void:
	top_cloth_timer = top_cloth_time
	bottom_clothe_timer = bottom_clothe_time
	previous_health = health

	if gender == "male":
		top_clothe = "blue_shirt_2"
		bottom_clothe = "green_pants"
	elif gender == "female":
		top_clothe = "blue_corset_2"
		bottom_clothe = "skirt"

	if camera:
		camera_base_offset = camera.offset

	skin_base_scale = skin.scale
	top_base_scale = top.scale
	bottom_base_scale = bottom.scale

###############################
# PHYSICS
###############################

func _physics_process(delta: float) -> void:
	points.text = "Score: " + str(Global.rage)
	if dying:
		return
	
	
	# Clothing system
	top_cloth_timer = max(top_cloth_timer - delta, 0.0)
	bottom_clothe_timer = max(bottom_clothe_timer - delta, 0.0)

	if top_cloth_timer <= 0.0 and not bottom_damage_multi:
		Global.damage_multiplier = 2.5

	elif bottom_clothe_timer <= 0.0 and not bottom_damage_multi:
		Global.damage_multiplier = 2.5

	elif bottom_clothe_timer > 0.0:
		Global.damage_multiplier = 1.0

	elif top_cloth_timer > 0.0:
		Global.damage_multiplier = 1.0

	# Health
	health = Global.health
	health_bar.value = health * 5.0

	# Detect damage taken -> flash + shake
	if health < previous_health:
		on_damaged()
	previous_health = health

	# Check death
	if health <= 0.0 and Global.is_alive:
		die()
		return

	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		velocity += get_gravity() * delta * 2.0
		coyote_timer = max(coyote_timer - delta, 0.0)

	# Jump buffer countdown
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	# Remember jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Perform jump
	if coyote_timer > 0.0 and jump_buffer_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		on_jump()

	# Horizontal movement
	var direction: float = Input.get_axis("left", "right")

	if direction != 0.0:
		velocity.x = direction * SPEED

		# Face direction
		if direction > 0.0:
			skin.flip_h = true
			top.flip_h = true
			bottom.flip_h = true
			hair.flip_h = true
		else:
			skin.flip_h = false
			top.flip_h = false
			bottom.flip_h = false
			hair.flip_h = false

	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Track fall start for landing impact strength
	if was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		fall_start_y = global_position.y

	# Move player
	move_and_slide()
	
	# Landing detection
	if not was_on_floor and is_on_floor():
		on_landed()

	was_on_floor = is_on_floor()

	# Animation
	if not is_on_floor():

		if velocity.y < 0.0:
			skin.play(skin_anim("jump"))
			top.play(top_anim("jump"))
			bottom.play(bottom_anim("jump"))
			hair.play(hair_anim("jump"))
		else:
			skin.play(skin_anim("fall"))
			top.play(top_anim("fall"))
			bottom.play(bottom_anim("fall"))
			hair.play(hair_anim("fall"))

	elif direction != 0.0:
		skin.play(skin_anim("run"))
		top.play(top_anim("run"))
		bottom.play(bottom_anim("run"))
		hair.play(hair_anim("run"))

	else:
		skin.play(skin_anim("idle"))
		top.play(top_anim("idle"))
		bottom.play(bottom_anim("idle"))
		hair.play(hair_anim("idle"))


	# Camera shake update
	if shake_timer > 0.0:
		shake_timer = max(shake_timer - delta, 0.0)
		apply_shake()
	elif camera:
		camera.offset = camera_base_offset


###############################
# JUICE: SQUASH & STRETCH
###############################

func squash_stretch(factor_x: float, factor_y: float, duration: float = 0.12) -> void:
	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()

	# factor_x/factor_y are multipliers applied ON TOP of each sprite's own base scale
	skin.scale = skin_base_scale * Vector2(factor_x, factor_y)
	top.scale = top_base_scale * Vector2(factor_x, factor_y)
	bottom.scale = bottom_base_scale * Vector2(factor_x, factor_y)

	squash_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(skin, "scale", skin_base_scale, duration)
	squash_tween.tween_property(top, "scale", top_base_scale, duration)
	squash_tween.tween_property(bottom, "scale", bottom_base_scale, duration)


###############################
# JUICE: JUMP / LANDING
###############################

func on_jump() -> void:
	squash_stretch(0.8, 1.25, 0.15)


func on_landed() -> void:
	var fall_distance: float = global_position.y - fall_start_y
	var impact: float = clamp(fall_distance / 300.0, 0.0, 1.0)  # 0 = light tap, 1 = hard landing

	# Squash on impact, stronger the harder the fall
	var squash_amount: float = lerp(0.95, 0.55, impact)
	var stretch_amount: float = lerp(1.05, 1.35, impact)
	squash_stretch(squash_amount, stretch_amount, 0.18)

	if impact > 0.15:
		shake(lerp(0.0, 6.0, impact), 0.2)


###############################
# JUICE
###############################

func shake(strength: float, duration: float) -> void:
	shake_strength = max(shake_strength, strength)
	shake_duration = duration
	shake_timer = duration


func apply_shake() -> void:
	if not camera:
		return
	var falloff: float = shake_timer / shake_duration
	var offset := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * shake_strength * falloff
	camera.offset = camera_base_offset + offset


###############################
# JUICE: HIT FLASH
###############################

func on_damaged() -> void:
	shake(4.0, 0.15)

	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	skin.modulate = Color(4.0, 4.0, 4.0)  # blown-out white flash
	top.modulate = Color(4.0, 4.0, 4.0)
	bottom.modulate = Color(4.0, 4.0, 4.0)

	flash_tween = create_tween().set_parallel(true)
	flash_tween.tween_property(skin, "modulate", Color.WHITE, 0.15)
	flash_tween.tween_property(top, "modulate", Color.WHITE, 0.15)
	flash_tween.tween_property(bottom, "modulate", Color.WHITE, 0.15)

	# Tiny hitstop for extra impact — comment out if it feels too disruptive
	hitstop(0.04)


func hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * Engine.time_scale, true, false, true).timeout
	Engine.time_scale = 1.0


###############################
# DEATH
###############################

func die() -> void:

	if dying:
		return

	dying = true
	Global.is_alive = false

	shake(10.0, 0.4)

	# Make the sprites continue processing while the game is paused
	skin.process_mode = Node.PROCESS_MODE_ALWAYS
	top.process_mode = Node.PROCESS_MODE_ALWAYS
	bottom.process_mode = Node.PROCESS_MODE_ALWAYS

	# Stop the player's movement
	velocity = Vector2.ZERO

	# Pause EVERYTHING else
	get_tree().paused = true

	# Play death animations
	skin.play(skin_anim("die"))
	top.play(top_anim("die"))
	bottom.play(bottom_anim("die"))

	# Wait for the death animation
	await get_tree().create_timer(1.8, true, false, true).timeout

	# Change scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/game_over.tscn")


###############################
# ANIMATIONS
###############################

func skin_anim(action: String) -> String:
	return gender + "_" + str(skin_type) + "_" + action

func top_anim(action: String) -> String:
	return top_clothe + "_" + action

func bottom_anim(action: String) -> String:
	return bottom_clothe + "_" + action

func hair_anim(action: String) -> String:
	return gender + "_" + hair_style + "_" + action
