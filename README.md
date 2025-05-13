# godot-tests-gut

# Proyecto de Pruebas Automatizadas en Godot usando GUT

Este repositorio contiene las escenas, scripts y documentación del plan de pruebas para nuevas funciones del motor Godot, incluyendo:

Pruebas funcionales

CP-JOLT-01: Simulación de gravedad con múltiples objetos

CP-JOLT-02: Colisiones complejas

CP-JOLT-03: Rendimiento comparativo

CP-EMBED-01: Sincronización en tiempo real

CP-LIVEEDIT-01: Modificación de propiedades


Pruebas no funcionales

CP-PERF-01: Tiempo de compilación de shaders

CP-ANDROID-01: Exportación básica

## Organización

- `scenes/`: Escenas de prueba usadas en las pruebas manuales y automáticas
- `tests/`: Scripts GDScript que ejecutan pruebas usando GUT
- `docs/`: Resultados, capturas y análisis
- `addons/gut/`: Plugin GUT para pruebas unitarias

## Cómo ejecutar las pruebas

1. Activar el plugin GUT en el menú de Plugins de Godot (Ya debe tener instalada la última versión de godot https://godotengine.org/download/windows/)
2. Abrir `run_tests.tscn`
3. Presionar `F5`

---
