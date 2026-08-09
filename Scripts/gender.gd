extends Control

func _on_male_pressed() -> void:
	Global.set_gender("male")
	get_tree().change_scene_to_file("res://UI/skin.tscn")

func _on_female_pressed() -> void:
	Global.set_gender("female")
	get_tree().change_scene_to_file("res://UI/skin.tscn")

#TODO change scene files to level 1

func _on_dark_pressed() -> void:
	Global.skin = "5"
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_tan_pressed() -> void:
	Global.skin = "4"
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_neutral_pressed() -> void:
	Global.skin = "3"
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_light_pressed() -> void:
	Global.skin = "2"
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_pale_pressed() -> void:
	Global.skin = "1"
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
