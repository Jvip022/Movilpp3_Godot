extends Control

# Variables para almacenar datos
var acciones_correctivas = []
var no_conformidades_pendientes = []

func _ready():
	# Conectar botones
	$ContenedorPrincipal/FormContainer/BotonesForm/BtnRegistrarAccion.connect("pressed", _on_registrar_accion)
	$ContenedorPrincipal/FormContainer/BotonesForm/BtnLimpiarForm.connect("pressed", _on_limpiar_formulario)
	$ContenedorPrincipal/PanelAcciones/BotonesAcciones/BtnAsignarTareas.connect("pressed", _on_asignar_tareas)
	$ContenedorPrincipal/PanelAcciones/BotonesAcciones/BtnNotificarEstado.connect("pressed", _on_notificar_estado)
	$ContenedorPrincipal/PanelAcciones/BotonesAcciones/BtnActualizarTabla.connect("pressed", _on_actualizar_tabla)
	$ContenedorPrincipal/BotonesInferiores/BtnVolverMenu.connect("pressed", _on_volver_menu)
	
	# Conectar botones del diálogo de tareas
	$DialogoTareas/VBoxContainer/HBoxContainer/BtnGuardarTarea.connect("pressed", _on_dialogo_tareas_guardar)
	$DialogoTareas/VBoxContainer/HBoxContainer/BtnCancelar.connect("pressed", $DialogoTareas.hide)
	
	# Conectar cierre de ventana
	$DialogoTareas.close_requested.connect($DialogoTareas.hide)
	
	# Cargar datos iniciales
	_cargar_no_conformidades()
	_configurar_tabla()
	_on_limpiar_formulario()

func _configurar_tabla():
	# Configurar columnas de la tabla
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	tabla.clear()
	tabla.max_columns = 6
	tabla.auto_height = true
	
	# Agregar encabezados
	tabla.add_item("ID")
	tabla.add_item("No Conformidad")
	tabla.add_item("Descripción")
	tabla.add_item("Responsable")
	tabla.add_item("Fecha Límite")
	tabla.add_item("Estado")
	
	# Deshabilitar selección de encabezados
	for i in range(6):
		tabla.set_item_selectable(i, false)

func _cargar_no_conformidades():
	# Simular carga de no conformidades desde base de datos
	no_conformidades_pendientes = [
		{"id": "NC-2024-001", "descripcion": "Retraso en entrega de producto A", "tipo": "Incidencia", "fecha": "15/01/2024"},
		{"id": "NC-2024-002", "descripcion": "Producto con defecto de fabricación", "tipo": "Queja", "fecha": "20/01/2024"},
		{"id": "NC-2024-003", "descripcion": "No conformidad en auditoría interna", "tipo": "Auditoría", "fecha": "25/01/2024"},
		{"id": "NC-2024-004", "descripcion": "Queja por atención al cliente", "tipo": "Reclamación", "fecha": "28/01/2024"}
	]
	
	var selector = $ContenedorPrincipal/FormContainer/GridForm/SelectNoConformidad
	selector.clear()
	selector.add_item("Seleccione una no conformidad...")
	
	for nc in no_conformidades_pendientes:
		var texto = "%s - %s (%s)" % [nc.id, nc.descripcion, nc.tipo]
		selector.add_item(texto)

func _on_registrar_accion():
	# Validar campos
	var no_conformidad_idx = $ContenedorPrincipal/FormContainer/GridForm/SelectNoConformidad.selected
	var descripcion = $ContenedorPrincipal/FormContainer/GridForm/InputDescripcion.text
	var responsable = $ContenedorPrincipal/FormContainer/GridForm/InputResponsable.text
	var fecha_limite = $ContenedorPrincipal/FormContainer/GridForm/InputFechaLimite.text
	
	if no_conformidad_idx == 0:
		mostrar_error("Debe seleccionar una no conformidad")
		return
	
	if descripcion.strip_edges() == "":
		mostrar_error("Debe ingresar una descripción de la acción")
		return
	
	if responsable.strip_edges() == "":
		mostrar_error("Debe especificar un responsable")
		return
	
	if fecha_limite.strip_edges() == "":
		mostrar_error("Debe establecer una fecha límite")
		return
	
	# Validar formato de fecha (simple)
	if not _validar_fecha(fecha_limite):
		mostrar_error("Formato de fecha inválido. Use DD/MM/AAAA")
		return
	
	# Obtener información de la no conformidad
	var nc_info = no_conformidades_pendientes[no_conformidad_idx - 1]
	
	# Crear nueva acción correctiva
	var nueva_accion = {
		"id": "AC-%03d" % (acciones_correctivas.size() + 1),
		"no_conformidad": nc_info.id,
		"descripcion_nc": nc_info.descripcion,
		"descripcion": descripcion,
		"responsable": responsable,
		"fecha_limite": fecha_limite,
		"fecha_registro": obtener_fecha_actual(),
		"estado": "Pendiente",
		"completado": 0,
		"tareas": []
	}
	
	acciones_correctivas.append(nueva_accion)
	
	# Actualizar tabla
	_actualizar_tabla()
	
	# Limpiar formulario
	_on_limpiar_formulario()
	
	mostrar_mensaje("Acción Registrada", "Acción correctiva %s registrada correctamente" % nueva_accion.id)

func _validar_fecha(fecha_str):
	# Validación simple de fecha DD/MM/AAAA
	var regex = RegEx.new()
	regex.compile("^\\d{2}/\\d{2}/\\d{4}$")
	return regex.search(fecha_str) != null

func _on_asignar_tareas():
	# Obtener acción seleccionada en la tabla
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	var seleccionados = tabla.get_selected_items()
	
	if seleccionados.size() == 0:
		mostrar_error("Debe seleccionar una acción de la tabla")
		return
	
	var indice = seleccionados[0] - 1  # Restar 1 por el encabezado
	if indice < 0 or indice >= acciones_correctivas.size():
		mostrar_error("Selección inválida")
		return
	
	var accion = acciones_correctivas[indice]
	
	# Configurar y mostrar diálogo de tareas
	$DialogoTareas/VBoxContainer/LabelAccion.text = "Asignar tareas a: %s" % accion.id
	$DialogoTareas/VBoxContainer/InputTareaDescripcion.text = ""
	$DialogoTareas/VBoxContainer/InputTareaResponsable.text = ""
	$DialogoTareas/VBoxContainer/InputTareaFechaLimite.text = obtener_fecha_actual()
	
	$DialogoTareas.popup_centered()

func _on_dialogo_tareas_guardar():
	# Validar campos del diálogo
	var descripcion = $DialogoTareas/VBoxContainer/InputTareaDescripcion.text
	var responsable = $DialogoTareas/VBoxContainer/InputTareaResponsable.text
	var fecha = $DialogoTareas/VBoxContainer/InputTareaFechaLimite.text
	
	if descripcion.strip_edges() == "":
		mostrar_error("Debe ingresar descripción de la tarea")
		return
	
	if responsable.strip_edges() == "":
		mostrar_error("Debe especificar responsable de la tarea")
		return
	
	if fecha.strip_edges() == "" or not _validar_fecha(fecha):
		mostrar_error("Debe establecer una fecha límite válida (DD/MM/AAAA)")
		return
	
	# Obtener acción seleccionada
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	var seleccionados = tabla.get_selected_items()
	if seleccionados.size() == 0:
		return
	
	var indice = seleccionados[0] - 1
	var accion = acciones_correctivas[indice]
	
	# Agregar tarea
	var nueva_tarea = {
		"id": "T-%02d" % (accion.tareas.size() + 1),
		"descripcion": descripcion,
		"responsable": responsable,
		"fecha_limite": fecha,
		"estado": "Pendiente",
		"fecha_asignacion": obtener_fecha_actual()
	}
	
	accion.tareas.append(nueva_tarea)
	accion.estado = "En Progreso"
	
	# Actualizar tabla
	_actualizar_tabla()
	
	# Cerrar diálogo
	$DialogoTareas.hide()
	
	mostrar_mensaje("Tarea Asignada", "Tarea asignada a la acción %s" % accion.id)

func _on_notificar_estado():
	# Obtener acción seleccionada en la tabla
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	var seleccionados = tabla.get_selected_items()
	
	if seleccionados.size() == 0:
		mostrar_error("Debe seleccionar una acción de la tabla")
		return
	
	var indice = seleccionados[0] - 1
	if indice < 0 or indice >= acciones_correctivas.size():
		mostrar_error("Selección inválida")
		return
	
	var accion = acciones_correctivas[indice]
	
	# Simular notificación
	print("=== NOTIFICACIÓN DE ESTADO ===")
	print("Acción Correctiva: %s" % accion.id)
	print("No Conformidad: %s" % accion.no_conformidad)
	print("Responsable: %s" % accion.responsable)
	print("Estado actual: %s" % accion.estado)
	print("Fecha límite: %s" % accion.fecha_limite)
	print("Tareas asignadas: %d" % accion.tareas.size())
	print("---------------------------")
	
	mostrar_mensaje("Notificación Enviada", "Se ha enviado notificación del estado a los responsables")

func _on_limpiar_formulario():
	$ContenedorPrincipal/FormContainer/GridForm/SelectNoConformidad.selected = 0
	$ContenedorPrincipal/FormContainer/GridForm/InputDescripcion.text = ""
	$ContenedorPrincipal/FormContainer/GridForm/InputResponsable.text = ""
	$ContenedorPrincipal/FormContainer/GridForm/InputFechaLimite.text = obtener_fecha_actual()

func _on_actualizar_tabla():
	_actualizar_tabla()
	mostrar_mensaje("Tabla Actualizada", "La tabla de acciones se ha actualizado")

func _actualizar_tabla():
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	
	# Limpiar tabla (excepto encabezados)
	while tabla.get_item_count() > 6:  # 6 encabezados
		tabla.remove_item(6)
	
	# Agregar acciones
	for i in range(acciones_correctivas.size()):
		var accion = acciones_correctivas[i]
		var fila_inicio = tabla.get_item_count()
		
		tabla.add_item(accion.id)
		tabla.add_item(accion.no_conformidad)
		tabla.add_item(accion.descripcion)
		tabla.add_item(accion.responsable)
		tabla.add_item(accion.fecha_limite)
		tabla.add_item(accion.estado)
		
		# Color según estado
		for j in range(6):
			match accion.estado:
				"Pendiente":
					tabla.set_item_custom_fg_color(fila_inicio + j, Color.RED)
				"En Progreso":
					tabla.set_item_custom_fg_color(fila_inicio + j, Color.ORANGE)
				"Completada":
					tabla.set_item_custom_fg_color(fila_inicio + j, Color.GREEN)

func obtener_fecha_actual():
	# Retorna la fecha actual en formato dd/mm/aaaa
	var tiempo = Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d" % [tiempo.day, tiempo.month, tiempo.year]

func _on_volver_menu():
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func mostrar_error(mensaje):
	$PopupError.dialog_text = mensaje
	$PopupError.popup_centered()

func mostrar_mensaje(titulo, mensaje):
	$PopupMensaje.title = titulo
	$PopupMensaje.dialog_text = mensaje
	$PopupMensaje.popup_centered()
