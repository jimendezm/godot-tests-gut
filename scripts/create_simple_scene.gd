extends Node3D

const NUM_OBJECTS := 100         # Número total de objetos
const DROP_HEIGHT := 5.0         # Altura inicial de caída
const BOX_SIZE := Vector3(0.5, 0.5, 0.5)

# Material constante: madera
var wood_material := preload("res://materials/wood.tres")

# === MÉTODO PRINCIPAL DE INICIALIZACIÓN ===
func _ready():
	add_debug_camera()
	create_floor()
	spawn_objects()

# === Crea una cámara para observar la simulación desde arriba ===
func add_debug_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(25, 0, -25)
	camera.rotation_degrees = Vector3(0, 140, 0)
	camera.current = true
	add_child(camera)

# === Crea el plano horizontal para evitar caída infinita ===
func create_floor():
	var floor1 = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(1000, 1000)
	mesh_instance.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.AQUA
	mesh_instance.material_override = mat

	floor1.add_child(mesh_instance)

	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1000, 0.5, 1000)
	collider.shape = shape
	floor1.add_child(collider)

	floor1.position = Vector3(0, -5, 20)

	add_child(floor1)

# === Genera 100 RigidBody3D en forma de caja de madera ===
func spawn_objects():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in NUM_OBJECTS:
		var body = RigidBody3D.new()

		# Colisión con forma de caja
		var shape_node = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = BOX_SIZE
		shape_node.shape = box_shape
		body.add_child(shape_node)

		# Representación visual
		var mesh_node = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = BOX_SIZE
		mesh_node.mesh = box_mesh

		var visual_mat = StandardMaterial3D.new()
		visual_mat.albedo_color = Color(0.4, 0.2, 0.0) # Color madera
		mesh_node.material_override = visual_mat
		body.add_child(mesh_node)

		# Posición aleatoria dentro de un área
		var x = rng.randf_range(-8, 8)
		var z = rng.randf_range(-8, 8)
		body.position = Vector3(x, DROP_HEIGHT, z)

		# Masa constante y material físico (madera)
		body.mass = 5.0
		body.physics_material_override = wood_material

		add_child(body)
