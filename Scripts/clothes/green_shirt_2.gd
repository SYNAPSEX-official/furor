extends Area2D

var clothe_gender: String = "male"

var shirt_colours: Array[String] = [
	"purple_shirt_2",
	"orange_shirt_2",
	"green_shirt_2",
	"blue_shirt_2"
]


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if clothe_gender != Global.gender:
			Global.rage_multi += qeue_free()
		else:
			Global.top_cloth = shirt_colours.pick_random()
			
			queue_free()
