extends Node

# =========================================================
# CUSTOMIZATION
# =========================================================

var gender: String = "male"
var skin: String = ""
var is_alive: bool = true

# Clothes
var top_cloth: String = "blue_shirt_2"
var bottom_cloth: String = "green_pants"

# =========================================================
# HEALTH
# =========================================================

const MAX_HEALTH: float = 20.0

var health: float = MAX_HEALTH
var attack: float = 2.0
var damage_multiplier: float = 1.0
var damage_taken: float = 0.0
var rage: float = 0.0
var rage_multi: float = 1.0
var healing: bool = false

# =========================================================
# READY
# =========================================================

func _ready() -> void:
	update_clothes()

# =========================================================
# GENDER
# =========================================================

func set_gender(new_gender: String) -> void:
	gender = new_gender
	update_clothes()

# =========================================================
# CLOTHING
# =========================================================

func update_clothes() -> void:
	match gender:
		"female":
			top_cloth = "blue_corset_2"
			bottom_cloth = "skirt"

		"male":
			top_cloth = "blue_shirt_2"
			bottom_cloth = "green_pants"

		_:
			gender = "male"
			top_cloth = "blue_shirt_2"
			bottom_cloth = "green_pants"

# =========================================================
# DAMAGE
# =========================================================

func take_damage() -> void:
	damage_taken = damage_multiplier

	health -= damage_multiplier
	health = max(health, 0.0)

	rage += damage_taken * rage_multi

# =========================================================
# HEALING
# =========================================================

func _physics_process(_delta: float) -> void:

	if health < MAX_HEALTH and not healing:

		healing = true

		await get_tree().create_timer(4.0).timeout

		# Make sure we haven't died while waiting
		if health > 0.0:
			health += 1.0
			health = min(health, MAX_HEALTH)

		healing = false
