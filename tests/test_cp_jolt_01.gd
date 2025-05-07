extends GutTest

func test_objects_do_not_fall_through_plane():
	var scene = load("res://scenes/main_test_cpjolt_01.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	var rigid_bodies = scene.find_children("", "RigidBody3D", true, false)

	for body in rigid_bodies:
		assert_gt(body.global_position.y, 0.0, "¡El objeto se cayó debajo del plano!")

	scene.queue_free()
