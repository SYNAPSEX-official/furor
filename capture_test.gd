extends SceneTree

var shot := 0

func _init() -> void:
	var tpl: PackedScene = load("res://level_template.tscn")
	var node := tpl.instantiate()
	root.add_child(node)
	var to_hide := ["Player", "Node", "Camera2D", "enemies", "death area"]
	for name in to_hide:
		var child := node.get_node_or_null(name)
		if child:
			child.visible = false
	await process_frame
	await process_frame
	var vp: Viewport = root
	for x in [-800, 0, 800, 1600, 2400]:
		var cam := Camera2D.new()
		cam.position = Vector2(x, -7)
		root.add_child(cam)
		cam.make_current()
		for i in 5:
			await process_frame
		var img: Image = vp.get_texture().get_image()
		img.save_png("/tmp/opencode/bg_%d.png" % shot)
		shot += 1
		cam.queue_free()
		await process_frame
	quit()
