extends Area2D

var clothe_gender = "male"
func _on_body_entered(body: Node2D) -> void:
		if body.name == "Player":
				if clothe_gender != Global.gender:
						Global.rage_multi += 0.2
						queue_free()
				else:
						Global.top_cloth = "green_shirt_2"
						queue_free()
