extends GutTest

# Este test verifica que durante la ejecución del juego se puedan modificar:
# posición, escala y variables personalizadas de un nodo

func test_liveedit_properties_can_be_modified():
	# Crear nodo en tiempo de ejecución (como si fuera una instancia en el juego)
	var obj = Node3D.new()
	add_child(obj)  # Se debe agregar al árbol para que funcione correctamente

	await get_tree().process_frame  # Esperar un frame para asegurar que todo cargó

	# Verificar modificación de posición
	obj.position = Vector3(10, 20, 30)
	assert_eq(obj.position, Vector3(10, 20, 30), "La posición no se modificó correctamente")

	# Verificar modificación de escala
	obj.scale = Vector3(2, 2, 2)
	assert_eq(obj.scale, Vector3(2, 2, 2), "La escala no se modificó correctamente")

	# Crear un script dinámico con una variable llamada 'vida'
	var script := GDScript.new()
	script.source_code = "extends Node3D\nvar vida = 100"
	var error = script.reload()
	assert_eq(error, OK, "El script no pudo cargarse correctamente")

	# Asignar script al nodo y modificar su propiedad 'vida'
	obj.set_script(script)
	obj.vida = 150
	assert_eq(obj.vida, 150, "La variable 'vida' no se modificó correctamente")
