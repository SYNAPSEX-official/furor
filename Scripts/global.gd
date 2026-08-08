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

func take_damage():
	health -= 1 * damage_multiplier
