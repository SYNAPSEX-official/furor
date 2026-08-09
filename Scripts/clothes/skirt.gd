extends Area2D

var clothe_gender = "female"
func _on_body_entered(body: Node2D) -> void:
		if body.name == "Player":
				if clothe_gender != Global.gender:
						Global.rage_multi += 0.2
						queue_free()
				else:
						Global.bottom_cloth = "skirt"
						queue_free()
