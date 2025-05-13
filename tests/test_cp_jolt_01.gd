extends Node3D

# === CONSTANTES DE CONFIGURACIÓN ===
const NUM_OBJECTS := 100                   # Número total de objetos a generar en la simulación
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

# === VARIABLES DE SEGUIMIENTO DE SIMULACIÓN ===
var objects_data = {}               # Diccionario para almacenar tiempos de detención por material y forma
var simulation_time := 0.0          # Tiempo acumulado de simulación
var simulation_active := true       # Controla si la simulación está corriendo
var objects_stopped := 0            # Contador de objetos que han dejado de moverse
var stop_threshold := 0.5           # Umbral de velocidad para considerar un objeto como "detenido"
var stop_time_required := 1.0       # Tiempo mínimo continuo por debajo del umbral para confirmar detención
var stop_tracking := {}             # Almacena el tiempo acumulado por objeto con baja velocidad

# === MÉTODO PRINCIPAL DE INICIALIZACIÓN ===
func _ready():
	# Configura la escena inicial con cámara, plano, piso y objetos
	add_debug_camera()
	create_inclined_plane()
	create_floor()
	spawn_objects()
	initialize_data_collection()
	set_process(true)

# === BUCLE PRINCIPAL DE SIMULACIÓN ===
func _process(delta):
	if simulation_active:
		simulation_time += delta
		if simulation_time >= 60.0:
			simulation_active = false
			analyze_results()
			return

		check_moving_objects()

# === Inicializa estructura para recopilar datos por tipo de objeto ===
func initialize_data_collection():
	objects_data = {
		"metal": {"SPHERE": [], "BOX": [], "CYLINDER": []},
		"wood": {"SPHERE": [], "BOX": [], "CYLINDER": []},
		"rubber": {"SPHERE": [], "BOX": [], "CYLINDER": []}
	}

# === Verifica el estado de movimiento de cada objeto y registra su detención ===
func check_moving_objects():
	for child in get_children():
		if child is RigidBody3D and not child.get_meta("stopped", false):
			var linear_speed = child.linear_velocity.length()
			var angular_speed = child.angular_velocity.length()
			var speed = max(linear_speed, angular_speed)

			if speed < stop_threshold:
				# Si está bajo el umbral, acumula tiempo de quietud
				if not stop_tracking.has(child):
					stop_tracking[child] = 0.0
				stop_tracking[child] += get_process_delta_time()

				# Si se mantiene suficiente tiempo detenido, registrarlo
				if stop_tracking[child] >= stop_time_required:
					record_stopped_object(child)
					stop_tracking.erase(child)
			else:
				# Si se vuelve a mover, reiniciar el conteo
				if stop_tracking.has(child):
					stop_tracking.erase(child)

# === Registra un objeto como detenido y guarda su tiempo ===
func record_stopped_object(obj: RigidBody3D):
	if obj.get_meta("stopped", false):
		return  # Ya ha sido registrado antes

	var material_type = ""
	for key in materials:
		if materials[key] == obj.physics_material_override:
			material_type = key
			break

	var shape_type = ""
	for shape_child in obj.get_children():
		if shape_child is CollisionShape3D:
			if shape_child.shape is SphereShape3D:
				shape_type = "SPHERE"
			elif shape_child.shape is BoxShape3D:
				shape_type = "BOX"
			elif shape_child.shape is CylinderShape3D:
				shape_type = "CYLINDER"
			break

	if material_type != "" and shape_type != "":
		objects_data[material_type][shape_type].append(simulation_time)
		obj.set_meta("stopped", true)
		objects_stopped += 1

# === Calcula y muestra los resultados al finalizar la simulación ===
func analyze_results():
	print("\n=== RESULTADOS DE LA SIMULACIÓN ===")
	print("Tiempo total de simulación: %.2f segundos" % simulation_time)
	print("Objetos detenidos: %d/%d" % [objects_stopped, NUM_OBJECTS])

	for material in objects_data:
		print("\nMaterial: %s" % material)
		for shape in objects_data[material]:
			var times = objects_data[material][shape]
			if times.size() > 0:
				var avg = average(times)
				print("  Forma %s: %.2f segundos (promedio, %d objetos)" % [shape, avg, times.size()])
			else:
				print("  Forma %s: Ningún objeto se detuvo" % shape)

# === Calcula el promedio de un arreglo de números ===
func average(arr: Array) -> float:
	var sum = 0.0
	for num in arr:
		sum += num
	return sum / arr.size()

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
