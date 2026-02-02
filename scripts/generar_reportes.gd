extends Control

func _ready():
	# Conectar botones
	$ContenedorPrincipal/CategoriasContainer/BtnNoConformidades.connect("pressed", _on_categoria_seleccionada.bind("no_conformidades"))
	$ContenedorPrincipal/CategoriasContainer/BtnSatisfaccion.connect("pressed", _on_categoria_seleccionada.bind("satisfaccion"))
	$ContenedorPrincipal/CategoriasContainer/BtnObjetivosCalidad.connect("pressed", _on_categoria_seleccionada.bind("objetivos"))
	$ContenedorPrincipal/CategoriasContainer/BtnEstadoNC.connect("pressed", _on_categoria_seleccionada.bind("estado_nc"))
	$ContenedorPrincipal/BtnGenerar.connect("pressed", _on_generar_previa)
	$ContenedorPrincipal/BtnExportar.connect("pressed", _on_exportar_reporte)
	$ContenedorPrincipal/BtnVolverMenu.connect("pressed", _on_volver_menu)

func _on_categoria_seleccionada(categoria):
	print("Categoría seleccionada: ", categoria)
	# Aquí se cargarían los filtros específicos para cada categoría

func _on_generar_previa():
	var fecha_inicio = $ContenedorPrincipal/FiltrosContainer/GridFiltros/InputFechaInicio.text
	var fecha_fin = $ContenedorPrincipal/FiltrosContainer/GridFiltros/InputFechaFin.text
	var sucursal = $ContenedorPrincipal/FiltrosContainer/GridFiltros/SelectSucursal.text
	
	print("Generando vista previa con filtros:")
	print("Fecha inicio: ", fecha_inicio)
	print("Fecha fin: ", fecha_fin)
	print("Sucursal: ", sucursal)
	
	# Mostrar diálogo de confirmación
	mostrar_mensaje("Vista previa generada", "Se ha generado la vista previa del reporte.")

func _on_exportar_reporte():
	# Diálogo para seleccionar formato de exportación
	mostrar_mensaje("Exportar reporte", "Seleccione formato de exportación:\n• PDF\n• Excel\n• CSV")

func _on_volver_menu():
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func mostrar_mensaje(titulo, mensaje):
	print(titulo, ": ", mensaje)
	# Aquí se implementaría un diálogo visual
