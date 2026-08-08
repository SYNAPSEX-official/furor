extends Node

#Customization
var gender
var skin
var is_alive = true

#Health system
var health = 20.0
var attack = 2.0
#var mana := 5.0
var damage_multiplier := 1.0
var damage_taken := 0
var rage = 0
var healing := false

func take_damage():
	damage_taken = 1 * damage_multiplier
	health -= damage_multiplier
	rage += damage_taken

func _physics_process(delta: float) -> void:
	if health < 20 and not healing:
		healing = true
		await get_tree().create_timer(4.0).timeout
		health += 1
		healing = false
