extends Node3D

# === CONSTANTES DE CONFIGURACIÓN ===
const NUM_OBJECTS := 1000                   # Número total de objetos a generar en la simulación
const DROP_HEIGHT := 5.0                   # Altura desde la cual se sueltan los objetos (en unidades)
const INCLINE_ANGLE := 30.0                # Ángulo de inclinación del plano (en grados)

# === MATERIALES Y COLORES ===

# Diccionario que asocia tipos de material con sus recursos físicos
var materials = {
	"metal": preload("res://materials/metal.tres"),
	"wood": preload("res://materials/wood.tres"),
	"rubber": preload("res://materials/rubber.tres")
}

# Colores visuales para distinguir los materiales en pantalla
var visual_colors = {
	"metal": Color(0.6, 0.6, 0.6), # Gris
	"wood": Color(0.4, 0.2, 0.0),  # Café
	"rubber": Color(0.0, 0.3, 0.8) # Azul
}

# Enumeración de los tipos de forma disponibles
enum ShapeType { SPHERE, BOX, CYLINDER }

# === MÉTODO PRINCIPAL DE INICIALIZACIÓN ===
func _ready():
	# Configura la escena inicial con cámara, plano, piso y objetos
	add_debug_camera()
	create_inclined_plane()
	create_floor()
	spawn_objects()

# === Crea una cámara fija para observar la simulación ===
func add_debug_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(35, 0, -35)
	camera.rotation_degrees = Vector3(0, 106, 0)
	camera.current = true
	add_child(camera)

# === Crea un plano inclinado con colisión y material físico ===
func create_inclined_plane():
	var plane = StaticBody3D.new()

	var plane_mesh = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(20, 20)
	plane_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	plane_mesh.material_override = mat

	plane.add_child(plane_mesh)

	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(20, 0.5, 20)
	collider.shape = shape
	plane.add_child(collider)

	var phys_material = PhysicsMaterial.new()
	phys_material.friction = 0.5
	phys_material.bounce = 0.0
	plane.physics_material_override = phys_material

	plane.rotation_degrees.x = -INCLINE_ANGLE
	plane.position = Vector3(0, 0, 0)

	add_child(plane)

# === Crea el piso horizontal inferior para evitar caídas infinitas ===
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

# === Genera objetos físicos con forma, masa, material y color aleatorios ===
func spawn_objects():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in NUM_OBJECTS:
		var body = RigidBody3D.new()

		# Elegir forma aleatoria
		var shape_type = rng.randi_range(0, 2)
		var shape_node = CollisionShape3D.new()
		var mesh_node = MeshInstance3D.new()

		match shape_type:
			ShapeType.SPHERE:
				shape_node.shape = SphereShape3D.new()
				mesh_node.mesh = SphereMesh.new()
			ShapeType.BOX:
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3(0.5, 0.5, 0.5)
				shape_node.shape = box_shape
				mesh_node.mesh = BoxMesh.new()
			ShapeType.CYLINDER:
				var cyl_shape = CylinderShape3D.new()
				cyl_shape.height = 1.0
				cyl_shape.radius = 0.3
				shape_node.shape = cyl_shape
				mesh_node.mesh = CylinderMesh.new()

		body.add_child(shape_node)
		body.add_child(mesh_node)

		# Posición inicial aleatoria sobre el plano inclinado
		var x = rng.randf_range(-8, 8)
		var z = rng.randf_range(-8, 8)
		body.position = Vector3(x, DROP_HEIGHT, z)

		# Masa aleatoria entre 1kg y 10kg
		body.mass = rng.randf_range(1.0, 10.0)

		# Material físico aleatorio
		var keys = materials.keys()
		var mat_key = keys[rng.randi_range(0, keys.size() - 1)]
		body.physics_material_override = materials[mat_key]

		# Color visual según material
		var visual_mat = StandardMaterial3D.new()
		visual_mat.albedo_color = visual_colors[mat_key]
		mesh_node.material_override = visual_mat

		add_child(body)
