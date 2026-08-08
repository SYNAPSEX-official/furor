extends CharacterBody2D

@onready var skin: AnimatedSprite2D = $skin
@onready var bottom: AnimatedSprite2D = $bottom_clothe
@onready var top: AnimatedSprite2D = $top_clothe

const SPEED = 500.0
const JUMP_VELOCITY = -700.0

# Coyote time
var coyote_time := 0.15
var coyote_timer := 0.0

# Jump buffer
var jump_buffer_time := 0.1
var jump_buffer_timer := 0.0

# Player customization
var gender = Global.gender
var skin_type = Global.skin
var top_clothe := "blue_shirt_2"
var bottom_clothe := "green_pants"
var hair_style
var socks
var shoes

#Health system
var health := Global.health
var attack := Global.attack

func _physics_process(delta: float) -> void:
	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		velocity += get_gravity() * delta * 2
		coyote_timer = max(coyote_timer - delta, 0.0)

	# Jump buffer countdown
	if jump_buffer_timer > 0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	# Remember jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Perform jump
	if coyote_timer > 0 and jump_buffer_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	# Horizontal movement
	var direction := Input.get_axis("left", "right")

	if direction:
		velocity.x = direction * SPEED

		# Face direction
		if direction > 0:
			skin.flip_h = true
			top.flip_h = true
			bottom.flip_h = true
		else:
			skin.flip_h = false
			top.flip_h = false
			bottom.flip_h = false

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Move player
	move_and_slide()

	# Animation
	if not is_on_floor():
		if velocity.y < 0:
			skin.play(skin_anim("jump"))
			top.play(top_anim("jump"))
			bottom.play(bottom_anim("jump"))
		else:
			skin.play(skin_anim("fall"))
			top.play(top_anim("fall"))
			bottom.play(bottom_anim("fall"))

	elif direction:
		skin.play(skin_anim("run"))
		top.play(top_anim("run"))
		bottom.play(bottom_anim("run"))

	else:
		skin.play(skin_anim("idle"))
		top.play(top_anim("idle"))
		bottom.play(bottom_anim("idle"))


func skin_anim(action: String) -> String:
	return gender + "_" + str(skin_type) + "_" + action

func top_anim(action: String) -> String:
	return top_clothe + "_" + action

func bottom_anim(action: String) -> String:
	return bottom_clothe + "_" + action
