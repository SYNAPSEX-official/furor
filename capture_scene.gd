extends Node2D

func _ready() -> void:
	var level: PackedScene = load("res://Scenes/level_1.tscn")
	var node := level.instantiate()
	add_child(node)
	await get_tree().process_frame
	await get_tree().process_frame
	var cam := Camera2D.new()
	add_child(cam)
	cam.position = Vector2(0, -7)
	cam.make_current()
	for i in 5:
		await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("/tmp/opencode/level1_full.png")
	get_tree().quit()
