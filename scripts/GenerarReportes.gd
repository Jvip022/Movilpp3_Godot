extends Control

class_name GenerarReportes

# Variables para almacenar la categoría seleccionada
var categoria_seleccionada = ""
var datos_reporte = {}

func _ready():
	# Conectar botones
	$ContenedorPrincipal/VBoxContainer/BotonesAccion/BtnGenerar.connect("pressed", _on_generar_pressed)
	$ContenedorPrincipal/VBoxContainer/BotonesAccion/BtnExportar.connect("pressed", _on_exportar_pressed)
	$ContenedorPrincipal/VBoxContainer/BotonesAccion/BtnVolverMenu.connect("pressed", _on_volver_menu)
	
	# Conectar botones de categorías
	$ContenedorPrincipal/VBoxContainer/CategoriasContainer/BtnNoConformidades.connect("pressed", _on_categoria_seleccionada.bind("no_conformidades"))
	$ContenedorPrincipal/VBoxContainer/CategoriasContainer/BtnSatisfaccion.connect("pressed", _on_categoria_seleccionada.bind("satisfaccion"))
	$ContenedorPrincipal/VBoxContainer/CategoriasContainer/BtnObjetivosCalidad.connect("pressed", _on_categoria_seleccionada.bind("objetivos"))
	$ContenedorPrincipal/VBoxContainer/CategoriasContainer/BtnEstadoNC.connect("pressed", _on_categoria_seleccionada.bind("estado_nc"))
	
	# Inicializar selectores
	_inicializar_selectores()
	
	# Configurar fecha actual por defecto
	_establecer_fechas_por_defecto()

func _inicializar_selectores():
	# Configurar Sucursal
	var select_sucursal = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/SelectSucursal
	select_sucursal.clear()
	select_sucursal.add_item("Todas las sucursales", 0)
	select_sucursal.add_item("Sucursal Norte", 1)
	select_sucursal.add_item("Sucursal Sur", 2)
	select_sucursal.add_item("Sucursal Este", 3)
	select_sucursal.add_item("Sucursal Oeste", 4)
	select_sucursal.selected = 0
	
	# Configurar Producto
	var select_producto = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/SelectProducto
	select_producto.clear()
	select_producto.add_item("Todos los productos", 0)
	select_producto.add_item("Producto A", 1)
	select_producto.add_item("Producto B", 2)
	select_producto.add_item("Servicio C", 3)
	select_producto.add_item("Servicio D", 4)
	select_producto.selected = 0

func _establecer_fechas_por_defecto():
	# Establecer mes actual por defecto
	var fecha_actual = Time.get_date_dict_from_system()
	var primer_dia_mes = "01/%02d/%04d" % [fecha_actual.month, fecha_actual.year]
	var ultimo_dia_mes = "%02d/%02d/%04d" % [fecha_actual.day, fecha_actual.month, fecha_actual.year]
	
	var input_fecha_inicio = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/InputFechaInicio
	var input_fecha_fin = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/InputFechaFin
	
	input_fecha_inicio.text = primer_dia_mes
	input_fecha_fin.text = ultimo_dia_mes

func _on_categoria_seleccionada(categoria):
	categoria_seleccionada = categoria
	
	var nombre_categoria = ""
	match categoria:
		"no_conformidades":
			nombre_categoria = "Estadísticas de No Conformidades"
		"satisfaccion":
			nombre_categoria = "Satisfacción del Cliente"
		"objetivos":
			nombre_categoria = "Objetivos de Calidad"
		"estado_nc":
			nombre_categoria = "Estado de No Conformidades"
		_:
			nombre_categoria = "Desconocida"
	
	# Actualizar panel de resultado
	var label_resultado = $ContenedorPrincipal/VBoxContainer/PanelResultado/LabelResultado
	label_resultado.text = "Categoría seleccionada: %s\n\nAjuste los filtros y haga clic en 'Generar Vista Previa'" % nombre_categoria
	
	print("Categoría seleccionada: ", nombre_categoria)

func _on_generar_pressed():
	# Validar que se haya seleccionado una categoría
	if categoria_seleccionada == "":
		mostrar_error("Debe seleccionar una categoría de reporte")
		return
	
	# Obtener valores de los filtros
	var fecha_inicio = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/InputFechaInicio.text
	var fecha_fin = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/InputFechaFin.text
	var sucursal = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/SelectSucursal.get_item_text(
		$ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/SelectSucursal.selected
	)
	var producto = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/SelectProducto.get_item_text(
		$ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/SelectProducto.selected
	)
	
	# Validar campos obligatorios
	if fecha_inicio.strip_edges() == "":
		mostrar_error("Debe ingresar la fecha de inicio")
		return
	
	if fecha_fin.strip_edges() == "":
		mostrar_error("Debe ingresar la fecha de fin")
		return
	
	# Simular generación de datos del reporte
	datos_reporte = {
		"categoria": categoria_seleccionada,
		"fecha_inicio": fecha_inicio,
		"fecha_fin": fecha_fin,
		"sucursal": sucursal,
		"producto": producto,
		"fecha_generacion": Time.get_datetime_string_from_system(),
		"total_registros": 0,
		"datos": []
	}
	
	# Simular datos según la categoría
	match categoria_seleccionada:
		"no_conformidades":
			datos_reporte["total_registros"] = 42
			datos_reporte["datos"] = [
				{"tipo": "Producto A", "cantidad": 15},
				{"tipo": "Producto B", "cantidad": 12},
				{"tipo": "Servicio C", "cantidad": 10},
				{"tipo": "Servicio D", "cantidad": 5}
			]
		"satisfaccion":
			datos_reporte["total_registros"] = 28
			datos_reporte["datos"] = [
				{"mes": "Enero", "puntuacion": 4.2},
				{"mes": "Febrero", "puntuacion": 4.5},
				{"mes": "Marzo", "puntuacion": 4.0}
			]
		"objetivos":
			datos_reporte["total_registros"] = 10
			datos_reporte["datos"] = [
				{"objetivo": "Reducir NC en 20%", "cumplimiento": 85},
				{"objetivo": "Mejorar satisfacción", "cumplimiento": 90},
				{"objetivo": "Capacitar personal", "cumplimiento": 100}
			]
		"estado_nc":
			datos_reporte["total_registros"] = 35
			datos_reporte["datos"] = [
				{"estado": "Abiertas", "cantidad": 15},
				{"estado": "En proceso", "cantidad": 12},
				{"estado": "Cerradas", "cantidad": 8}
			]
	
	print("=== REPORTE GENERADO ===")
	print("Categoría: ", datos_reporte["categoria"])
	print("Período: ", datos_reporte["fecha_inicio"], " a ", datos_reporte["fecha_fin"])
	print("Sucursal: ", datos_reporte["sucursal"])
	print("Producto: ", datos_reporte["producto"])
	print("Total registros: ", datos_reporte["total_registros"])
	
	# Actualizar panel de resultado
	var label_resultado = $ContenedorPrincipal/VBoxContainer/PanelResultado/LabelResultado
	
	var nombre_categoria = ""
	match categoria_seleccionada:
		"no_conformidades":
			nombre_categoria = "Estadísticas de No Conformidades"
		"satisfaccion":
			nombre_categoria = "Satisfacción del Cliente"
		"objetivos":
			nombre_categoria = "Objetivos de Calidad"
		"estado_nc":
			nombre_categoria = "Estado de No Conformidades"
	
	var resultado_texto = "✅ VISTA PREVIA GENERADA\n\n"
	resultado_texto += "Categoría: %s\n" % nombre_categoria
	resultado_texto += "Período: %s a %s\n" % [fecha_inicio, fecha_fin]
	resultado_texto += "Sucursal: %s\n" % sucursal
	resultado_texto += "Producto: %s\n" % producto
	resultado_texto += "Total registros: %d\n" % datos_reporte["total_registros"]
	resultado_texto += "\nHaga clic en 'Exportar Reporte' para guardar"
	
	label_resultado.text = resultado_texto
	
	mostrar_mensaje("Éxito", "Vista previa generada correctamente")

func _on_exportar_pressed():
	# Validar que haya datos generados
	if datos_reporte.is_empty():
		mostrar_error("Debe generar primero la vista previa del reporte")
		return
	
	var fecha_inicio = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/InputFechaInicio.text
	var fecha_fin = $ContenedorPrincipal/VBoxContainer/FiltrosContainer/GridFiltros/InputFechaFin.text
	
	# Mostrar opciones de exportación
	var dialog = ConfirmationDialog.new()
	dialog.title = "Exportar Reporte"
	dialog.dialog_text = "Seleccione formato de exportación para el período:\n%s a %s" % [fecha_inicio, fecha_fin]
	dialog.confirmed.connect(_on_exportar_pdf.bind(dialog))
	dialog.canceled.connect(_on_cancelar_exportacion.bind(dialog))
	
	# Crear contenedor para botones de formato
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(200, 100)
	
	var btn_pdf = Button.new()
	btn_pdf.text = "📄 Exportar a PDF"
	btn_pdf.connect("pressed", _on_exportar_pdf.bind(dialog))
	
	var btn_excel = Button.new()
	btn_excel.text = "📊 Exportar a Excel"
	btn_excel.connect("pressed", _on_exportar_excel.bind(dialog))
	
	var btn_csv = Button.new()
	btn_csv.text = "📝 Exportar a CSV"
	btn_csv.connect("pressed", _on_exportar_csv.bind(dialog))
	
	vbox.add_child(btn_pdf)
	vbox.add_child(btn_excel)
	vbox.add_child(btn_csv)
	
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func _on_exportar_pdf(dialog):
	print("Exportando a PDF...")
	dialog.queue_free()
	
	# Aquí iría el código para exportar a PDF
	var ruta_archivo = "reporte_%s_%s.pdf" % [categoria_seleccionada, Time.get_datetime_string_from_system().replace(":", "-")]
	mostrar_mensaje("Exportación completada", "Reporte exportado como PDF:\n%s" % ruta_archivo)

func _on_exportar_excel(dialog):
	print("Exportando a Excel...")
	dialog.queue_free()
	
	# Aquí iría el código para exportar a Excel
	var ruta_archivo = "reporte_%s_%s.xlsx" % [categoria_seleccionada, Time.get_datetime_string_from_system().replace(":", "-")]
	mostrar_mensaje("Exportación completada", "Reporte exportado como Excel:\n%s" % ruta_archivo)

func _on_exportar_csv(dialog):
	print("Exportando a CSV...")
	dialog.queue_free()
	
	# Aquí iría el código para exportar a CSV
	var ruta_archivo = "reporte_%s_%s.csv" % [categoria_seleccionada, Time.get_datetime_string_from_system().replace(":", "-")]
	mostrar_mensaje("Exportación completada", "Reporte exportado como CSV:\n%s" % ruta_archivo)

func _on_cancelar_exportacion(dialog):
	print("Exportación cancelada")
	dialog.queue_free()

func _on_volver_menu():
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func mostrar_error(mensaje):
	print("ERROR: ", mensaje)
	# Aquí se implementaría un diálogo visual de error
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()

func mostrar_mensaje(titulo, mensaje):
	print(titulo, ": ", mensaje)
	# Aquí se implementaría un diálogo visual
	var dialog = AcceptDialog.new()
	dialog.title = titulo
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()

# Manejar tecla ESC para volver al menú
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_volver_menu()
