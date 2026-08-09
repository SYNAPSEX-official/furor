extends Area2D

var clothe_gender: String = "female"

var corset_colours: Array[String] = [
	"blue_corset_2",
	"green_corset_2",
	"orange_corset_2",
	"purple_corset_2"
]


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if clothe_gender != Global.gender:
			Global.rage_multi += 0.2
			queue_free()
		else:
			Global.top_cloth = corset_colours.pick_random()
			Global.damage_multiplier = 1.0
			queue_free()
