extends Control

# Variables para almacenar datos
var acciones_correctivas = []
var no_conformidades_pendientes = []
var no_conformidad_seleccionada = null
var no_conformidades_filtradas = []
var resultados_visibles = true  # Estado inicial: resultados visibles
var modo_busqueda_centrada = false  # Modo donde solo se muestran los resultados centrados
var panel_busqueda_visible = true  # Estado inicial: panel de búsqueda visible

func _ready():
	# Conectar botones
	$ContenedorPrincipal/FormContainer/BotonesForm/BtnRegistrarAccion.connect("pressed", _on_registrar_accion)
	$ContenedorPrincipal/FormContainer/BotonesForm/BtnLimpiarForm.connect("pressed", _on_limpiar_formulario)
	$ContenedorPrincipal/PanelAcciones/BotonesAcciones/BtnAsignarTareas.connect("pressed", _on_asignar_tareas)
	$ContenedorPrincipal/PanelAcciones/BotonesAcciones/BtnNotificarEstado.connect("pressed", _on_notificar_estado)
	$ContenedorPrincipal/PanelAcciones/BotonesAcciones/BtnActualizarTabla.connect("pressed", _on_actualizar_tabla)
	$ContenedorPrincipal/BotonesInferiores/BtnVolverMenu.connect("pressed", _on_volver_menu)
	
	# Conectar botones de búsqueda
	$ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnBuscar.connect("pressed", _on_buscar_nc)
	$ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnEvaluarNC.connect("pressed", _on_evaluar_nc)
	$ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnToggleResultados.connect("pressed", _on_toggle_resultados)
	
	# Conectar selección en resultados de búsqueda
	$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.item_selected.connect(_on_nc_seleccionada)
	
	# Conectar botones del diálogo de tareas
	$DialogoTareas/VBoxContainer/HBoxContainer/BtnGuardarTarea.connect("pressed", _on_dialogo_tareas_guardar)
	$DialogoTareas/VBoxContainer/HBoxContainer/BtnCancelar.connect("pressed", $DialogoTareas.hide)
	
	# Conectar botones del diálogo de evaluación
	$DialogoEvaluacion/VBoxContainer2/HBoxContainerBotones/BtnGuardarEvaluacion.connect("pressed", _on_dialogo_evaluacion_guardar)
	$DialogoEvaluacion/VBoxContainer2/HBoxContainerBotones/BtnCancelarEvaluacion.connect("pressed", $DialogoEvaluacion.hide)
	
	# Conectar cierre de ventanas
	$DialogoTareas.close_requested.connect($DialogoTareas.hide)
	$DialogoEvaluacion.close_requested.connect($DialogoEvaluacion.hide)
	
	# Conectar entrada de búsqueda para buscar al presionar Enter
	$ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/InputBusqueda.text_submitted.connect(_on_buscar_enter)
	
	# Configurar opciones de evaluación
	_configurar_opciones_evaluacion()
	
	# Cargar datos iniciales
	_cargar_no_conformidades()
	_configurar_tabla()
	_on_limpiar_formulario()
	
	# Ajustar el contenedor de resultados
	#$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.anchors_preset = Control.PRESET_VCENTER_WIDE
	$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.anchor_top = 1.0
	$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.anchor_bottom = 1.0
	$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.offset_top = -120
	$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.offset_bottom = -10
	
	# Mostrar todas las no conformidades inicialmente
	_actualizar_resultados_busqueda()
	
	# Configurar estado inicial de los botones de toggle
	_actualizar_boton_toggle()

func _configurar_opciones_evaluacion():
	# Configurar opciones de severidad
	var severidad = $DialogoEvaluacion/VBoxContainer2/OpcionesSeveridad
	severidad.clear()
	severidad.add_item("Baja", 0)
	severidad.add_item("Media", 1)
	severidad.add_item("Alta", 2)
	severidad.add_item("Crítica", 3)
	
	# Configurar opciones de impacto
	var impacto = $DialogoEvaluacion/VBoxContainer2/OpcionesImpacto
	impacto.clear()
	impacto.add_item("Calidad", 0)
	impacto.add_item("Seguridad", 1)
	impacto.add_item("Medio Ambiente", 2)
	impacto.add_item("Costos", 3)
	impacto.add_item("Tiempo", 4)
	impacto.add_item("Cliente", 5)

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
		{
			"id": "NC-2024-001", 
			"descripcion": "Retraso en entrega de producto A", 
			"tipo": "Incidencia", 
			"fecha": "15/01/2024",
			"area": "Logística",
			"responsable": "Juan Pérez",
			"severidad": "",
			"evaluacion": "",
			"evaluada": false
		},
		{
			"id": "NC-2024-002", 
			"descripcion": "Producto con defecto de fabricación", 
			"tipo": "Queja", 
			"fecha": "20/01/2024",
			"area": "Producción",
			"responsable": "María Gómez",
			"severidad": "",
			"evaluacion": "",
			"evaluada": false
		},
		{
			"id": "NC-2024-003", 
			"descripcion": "No conformidad en auditoría interna", 
			"tipo": "Auditoría", 
			"fecha": "25/01/2024",
			"area": "Calidad",
			"responsable": "Carlos Ruiz",
			"severidad": "",
			"evaluacion": "",
			"evaluada": false
		},
		{
			"id": "NC-2024-004", 
			"descripcion": "Queja por atención al cliente", 
			"tipo": "Reclamación", 
			"fecha": "28/01/2024",
			"area": "Servicio al Cliente",
			"responsable": "Ana López",
			"severidad": "",
			"evaluacion": "",
			"evaluada": false
		},
		{
			"id": "NC-2024-005", 
			"descripcion": "Documentación incompleta en proceso", 
			"tipo": "Documentación", 
			"fecha": "02/02/2024",
			"area": "Administración",
			"responsable": "Pedro Martínez",
			"severidad": "",
			"evaluacion": "",
			"evaluada": false
		}
	]
	
	no_conformidades_filtradas = no_conformidades_pendientes.duplicate(true)

# Eliminar o completar esta función si no se usa
func _on_toggle_panel_busqueda():
	pass  # Esta función no se usa en la escena actual

func _on_toggle_resultados():
	# Alternar visibilidad de los resultados
	resultados_visibles = !resultados_visibles
	
	if resultados_visibles:
		$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.visible = true
		# Si hay texto de búsqueda, actualizar los resultados
		if $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/InputBusqueda.text.strip_edges() != "":
			_on_buscar_nc()
	else:
		$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.visible = false
	
	# Actualizar texto del botón
	_actualizar_boton_toggle()

func _actualizar_boton_toggle():
	var boton = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnToggleResultados
	
	if resultados_visibles:
		boton.text = "▼ OCULTAR"
		boton.tooltip_text = "Ocultar resultados de búsqueda"
	else:
		boton.text = "▲ MOSTRAR"
		boton.tooltip_text = "Mostrar resultados de búsqueda"

func _on_buscar_nc():
	var termino_busqueda = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/InputBusqueda.text.strip_edges().to_lower()
	
	if termino_busqueda == "":
		no_conformidades_filtradas = no_conformidades_pendientes.duplicate(true)
	else:
		no_conformidades_filtradas = []
		for nc in no_conformidades_pendientes:
			var texto_busqueda = "%s %s %s %s" % [nc["id"], nc["descripcion"], nc["tipo"], nc["responsable"]]
			if termino_busqueda in texto_busqueda.to_lower():
				no_conformidades_filtradas.append(nc)
	
	_actualizar_resultados_busqueda()
	
	# Si hay resultados y estamos en modo búsqueda, activar modo centrado
	if no_conformidades_filtradas.size() > 0 and termino_busqueda != "":
		_activar_modo_centrado()
	else:
		_desactivar_modo_centrado()
		
	# Si hay resultados y están ocultos, mostrarlos automáticamente
	if no_conformidades_filtradas.size() > 0 and not resultados_visibles:
		resultados_visibles = true
		$ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda.visible = true
		_actualizar_boton_toggle()

func _activar_modo_centrado():
	# Activar modo donde solo se muestran los resultados centrados
	modo_busqueda_centrada = true
	
	# Ocultar otros elementos
	$ContenedorPrincipal/FormContainer.visible = false
	$ContenedorPrincipal/PanelAcciones.visible = false
	
	# Expandir el panel de búsqueda para que ocupe más espacio
	var panel_busqueda = $ContenedorPrincipal/PanelBusqueda
	panel_busqueda.custom_minimum_size = Vector2(0, 400)  # Hacerlo más alto
	panel_busqueda.size_flags_vertical = 3  # Permitir que se expanda
	
	# Expandir el contenedor de resultados
	var resultados = $ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda
	resultados.custom_minimum_size = Vector2(0, 300)
	
	# Cambiar texto del botón de búsqueda para indicar que se puede volver
	var btn_buscar = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnBuscar
	btn_buscar.text = "🔙 VOLVER"
	
	# Desconectar cualquier conexión previa y conectar a _desactivar_modo_centrado
	if btn_buscar.is_connected("pressed", _on_buscar_nc):
		btn_buscar.disconnect("pressed", _on_buscar_nc)
	btn_buscar.connect("pressed", _desactivar_modo_centrado)
	
	# Cambiar botón de evaluación para volver también
	var btn_evaluar = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnEvaluarNC
	btn_evaluar.visible = false
	
	# Cambiar botón de toggle resultados
	var btn_toggle_resultados = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnToggleResultados
	btn_toggle_resultados.visible = false
	
	# Agregar mensaje informativo
	$ContenedorPrincipal/PanelBusqueda/LabelBusqueda.text = "Resultados de Búsqueda (Modo Centrado)"
	
func _desactivar_modo_centrado():
	# Desactivar modo centrado
	modo_busqueda_centrada = false
	
	# Mostrar todos los elementos
	$ContenedorPrincipal/FormContainer.visible = true
	$ContenedorPrincipal/PanelAcciones.visible = true
	
	# Restaurar tamaño del panel de búsqueda
	var panel_busqueda = $ContenedorPrincipal/PanelBusqueda
	panel_busqueda.custom_minimum_size = Vector2(0, 120)
	panel_busqueda.size_flags_vertical = 0
	
	# Restaurar tamaño del contenedor de resultados
	var resultados = $ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda
	resultados.custom_minimum_size = Vector2(0, 0)
	
	# Restaurar botón de búsqueda
	var btn_buscar = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnBuscar
	btn_buscar.text = "🔍 BUSCAR"
	
	# Desconectar cualquier conexión previa y reconectar a _on_buscar_nc
	if btn_buscar.is_connected("pressed", _desactivar_modo_centrado):
		btn_buscar.disconnect("pressed", _desactivar_modo_centrado)
	if not btn_buscar.is_connected("pressed", _on_buscar_nc):
		btn_buscar.connect("pressed", _on_buscar_nc)
	
	# Mostrar botón de evaluación nuevamente
	var btn_evaluar = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnEvaluarNC
	btn_evaluar.visible = true
	
	# Mostrar botón de toggle resultados nuevamente
	var btn_toggle_resultados = $ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/BtnToggleResultados
	btn_toggle_resultados.visible = true
	
	# Restaurar título del panel
	$ContenedorPrincipal/PanelBusqueda/LabelBusqueda.text = "Buscar y Evaluar No Conformidades"
	
	# Limpiar campo de búsqueda
	$ContenedorPrincipal/PanelBusqueda/HBoxBusqueda/InputBusqueda.text = ""
	
	# Mostrar todas las no conformidades nuevamente
	no_conformidades_filtradas = no_conformidades_pendientes.duplicate(true)
	_actualizar_resultados_busqueda()

func _on_buscar_enter(texto):
	_on_buscar_nc()

func _actualizar_resultados_busqueda():
	var resultados = $ContenedorPrincipal/PanelBusqueda/ResultadosBusqueda
	resultados.clear()
	
	if no_conformidades_filtradas.size() == 0:
		resultados.add_item("No se encontraron no conformidades")
		resultados.set_item_custom_fg_color(0, Color(0.5, 0.5, 0.5))
		resultados.set_item_selectable(0, false)
		return
	
	for nc in no_conformidades_filtradas:
		var texto = "%s - %s" % [nc["id"], nc["descripcion"]]
		if nc["evaluada"]:
			texto += " [✅ Evaluada]"
		else:
			texto += " [❌ Pendiente]"
		
		resultados.add_item(texto)
		
		# Cambiar color según si está evaluada o no
		var indice = resultados.item_count - 1
		if nc["evaluada"]:
			resultados.set_item_custom_fg_color(indice, Color(0.2, 0.6, 0.2))
		else:
			resultados.set_item_custom_fg_color(indice, Color(0.8, 0.2, 0.2))

func _on_nc_seleccionada(index):
	if index < 0 or index >= no_conformidades_filtradas.size():
		return
	
	no_conformidad_seleccionada = no_conformidades_filtradas[index]
	
	# Si estamos en modo centrado, desactivarlo al seleccionar un resultado
	if modo_busqueda_centrada:
		_desactivar_modo_centrado()
	
	# Actualizar información en el formulario
	var info_label = $ContenedorPrincipal/FormContainer/GridForm/InfoNCSeleccionada
	var texto = "%s - %s" % [no_conformidad_seleccionada["id"], no_conformidad_seleccionada["descripcion"]]
	
	if no_conformidad_seleccionada["evaluada"]:
		texto += " (✅ Evaluada)"
		info_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	else:
		texto += " (❌ No evaluada)"
		info_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	
	info_label.text = texto
	
	# Si ya está evaluada, habilitar el formulario
	if no_conformidad_seleccionada["evaluada"]:
		mostrar_mensaje("NC Seleccionada", "No conformidad seleccionada. Puede proceder a crear la acción correctiva.")
	else:
		mostrar_mensaje("NC Seleccionada", "No conformidad seleccionada. Debe evaluarla antes de crear una acción correctiva.")

func _on_evaluar_nc():
	if no_conformidad_seleccionada == null:
		mostrar_error("Debe seleccionar una no conformidad primero")
		return
	
	# Configurar el diálogo de evaluación
	$DialogoEvaluacion/VBoxContainer2/InfoNCDetalle.text = "ID: %s\nDescripción: %s\nTipo: %s\nFecha: %s\nÁrea: %s\nResponsable: %s" % [
		no_conformidad_seleccionada["id"],
		no_conformidad_seleccionada["descripcion"],
		no_conformidad_seleccionada["tipo"],
		no_conformidad_seleccionada["fecha"],
		no_conformidad_seleccionada["area"],
		no_conformidad_seleccionada["responsable"]
	]
	
	# Limpiar campos de evaluación
	$DialogoEvaluacion/VBoxContainer2/OpcionesSeveridad.selected = 0
	$DialogoEvaluacion/VBoxContainer2/OpcionesImpacto.selected = 0
	$DialogoEvaluacion/VBoxContainer2/InputEvaluacion.text = ""
	
	# Mostrar diálogo
	$DialogoEvaluacion.popup_centered()

func _on_dialogo_evaluacion_guardar():
	if no_conformidad_seleccionada == null:
		return
	
	# Validar campos
	var severidad = $DialogoEvaluacion/VBoxContainer2/OpcionesSeveridad.text
	var impacto = $DialogoEvaluacion/VBoxContainer2/OpcionesImpacto.text
	var evaluacion = $DialogoEvaluacion/VBoxContainer2/InputEvaluacion.text.strip_edges()
	
	if evaluacion == "":
		mostrar_error("Debe ingresar una evaluación")
		return
	
	# Actualizar la no conformidad con la evaluación
	no_conformidad_seleccionada["severidad"] = severidad
	no_conformidad_seleccionada["area_impacto"] = impacto
	no_conformidad_seleccionada["evaluacion"] = evaluacion
	no_conformidad_seleccionada["evaluada"] = true
	no_conformidad_seleccionada["fecha_evaluacion"] = obtener_fecha_actual()
	
	# Actualizar resultados de búsqueda
	_actualizar_resultados_busqueda()
	
	# Actualizar información en el formulario
	var info_label = $ContenedorPrincipal/FormContainer/GridForm/InfoNCSeleccionada
	info_label.text = "%s - %s (✅ Evaluada)" % [no_conformidad_seleccionada["id"], no_conformidad_seleccionada["descripcion"]]
	info_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	
	# Cerrar diálogo
	$DialogoEvaluacion.hide()
	
	mostrar_mensaje("Evaluación Guardada", "La no conformidad %s ha sido evaluada correctamente." % no_conformidad_seleccionada["id"])

func _on_registrar_accion():
	# Validar que haya una no conformidad seleccionada y evaluada
	if no_conformidad_seleccionada == null:
		mostrar_error("Debe seleccionar una no conformidad primero")
		return
	
	if not no_conformidad_seleccionada["evaluada"]:
		mostrar_error("Debe evaluar la no conformidad antes de crear una acción correctiva")
		return
	
	# Validar campos del formulario
	var descripcion = $ContenedorPrincipal/FormContainer/GridForm/InputDescripcion.text
	var responsable = $ContenedorPrincipal/FormContainer/GridForm/InputResponsable.text
	var fecha_limite = $ContenedorPrincipal/FormContainer/GridForm/InputFechaLimite.text
	
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
	
	# Crear nueva acción correctiva
	var nueva_accion = {
		"id": "AC-%03d" % (acciones_correctivas.size() + 1),
		"no_conformidad": no_conformidad_seleccionada["id"],
		"descripcion_nc": no_conformidad_seleccionada["descripcion"],
		"descripcion": descripcion,
		"responsable": responsable,
		"fecha_limite": fecha_limite,
		"fecha_registro": obtener_fecha_actual(),
		"estado": "Pendiente",
		"completado": 0,
		"tareas": [],
		"severidad_nc": no_conformidad_seleccionada["severidad"],
		"impacto_nc": no_conformidad_seleccionada.get("area_impacto", "")
	}
	
	acciones_correctivas.append(nueva_accion)
	
	# Actualizar tabla
	_actualizar_tabla()
	
	# Limpiar formulario
	_on_limpiar_formulario()
	
	# Limpiar selección de no conformidad
	no_conformidad_seleccionada = null
	var info_label = $ContenedorPrincipal/FormContainer/GridForm/InfoNCSeleccionada
	info_label.text = "Ninguna seleccionada"
	info_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.7, 1))
	
	mostrar_mensaje("Acción Registrada", "Acción correctiva %s registrada correctamente" % nueva_accion["id"])

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
	
	# Calcular correctamente el índice en el array
	var fila_tabla = seleccionados[0]
	if fila_tabla < 6:  # Los primeros 6 son encabezados
		mostrar_error("Selección inválida: No puede seleccionar encabezados")
		return
	
	# Calcular índice en el array (restar encabezados y dividir por columnas)
	var indice = (fila_tabla - 6) / 6
	
	if indice < 0 or indice >= acciones_correctivas.size():
		mostrar_error("Selección inválida")
		return
	
	var accion = acciones_correctivas[indice]
	
	# Configurar y mostrar diálogo de tareas
	$DialogoTareas/VBoxContainer/LabelAccion.text = "Asignar tareas a: %s" % accion["id"]
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
	
	# Calcular correctamente el índice en el array
	var fila_tabla = seleccionados[0]
	if fila_tabla < 6:  # Los primeros 6 son encabezados
		mostrar_error("Selección inválida: No puede seleccionar encabezados")
		return
	
	var indice = (fila_tabla - 6) / 6
	if indice < 0 or indice >= acciones_correctivas.size():
		mostrar_error("Selección inválida")
		return
	
	var accion = acciones_correctivas[indice]
	
	# Agregar tarea
	var nueva_tarea = {
		"id": "T-%02d" % (accion["tareas"].size() + 1),
		"descripcion": descripcion,
		"responsable": responsable,
		"fecha_limite": fecha,
		"estado": "Pendiente",
		"fecha_asignacion": obtener_fecha_actual()
	}
	
	accion["tareas"].append(nueva_tarea)
	accion["estado"] = "En Progreso"
	
	# Actualizar tabla
	_actualizar_tabla()
	
	# Cerrar diálogo
	$DialogoTareas.hide()
	
	mostrar_mensaje("Tarea Asignada", "Tarea asignada a la acción %s" % accion["id"])

func _on_notificar_estado():
	# Obtener acción seleccionada en la tabla
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	var seleccionados = tabla.get_selected_items()
	
	if seleccionados.size() == 0:
		mostrar_error("Debe seleccionar una acción de la tabla")
		return
	
	# Calcular correctamente el índice en el array
	var fila_tabla = seleccionados[0]
	if fila_tabla < 6:  # Los primeros 6 son encabezados
		mostrar_error("Selección inválida: No puede seleccionar encabezados")
		return
	
	var indice = (fila_tabla - 6) / 6
	if indice < 0 or indice >= acciones_correctivas.size():
		mostrar_error("Selección inválida")
		return
	
	var accion = acciones_correctivas[indice]
	
	# Simular notificación
	print("=== NOTIFICACIÓN DE ESTADO ===")
	print("Acción Correctiva: %s" % accion["id"])
	print("No Conformidad: %s" % accion["no_conformidad"])
	print("Responsable: %s" % accion["responsable"])
	print("Estado actual: %s" % accion["estado"])
	print("Fecha límite: %s" % accion["fecha_limite"])
	print("Tareas asignadas: %d" % accion["tareas"].size())
	print("Severidad NC: %s" % accion.get("severidad_nc", "No especificada"))
	print("Impacto NC: %s" % accion.get("impacto_nc", "No especificado"))
	print("---------------------------")
	
	mostrar_mensaje("Notificación Enviada", "Se ha enviado notificación del estado a los responsables")

func _on_limpiar_formulario():
	$ContenedorPrincipal/FormContainer/GridForm/InputDescripcion.text = ""
	$ContenedorPrincipal/FormContainer/GridForm/InputResponsable.text = ""
	$ContenedorPrincipal/FormContainer/GridForm/InputFechaLimite.text = obtener_fecha_actual()
	
	# No limpiamos la no conformidad seleccionada, solo los campos de entrada

func _on_actualizar_tabla():
	_actualizar_tabla()
	mostrar_mensaje("Tabla Actualizada", "La tabla de acciones se ha actualizado")

func _actualizar_tabla():
	var tabla = $ContenedorPrincipal/PanelAcciones/ScrollContainer/TablaAcciones
	
	# Limpiar tabla (excepto encabezados)
	tabla.clear()
	
	# Agregar encabezados nuevamente
	tabla.add_item("ID")
	tabla.add_item("No Conformidad")
	tabla.add_item("Descripción")
	tabla.add_item("Responsable")
	tabla.add_item("Fecha Límite")
	tabla.add_item("Estado")
	
	# Deshabilitar selección de encabezados
	for i in range(6):
		tabla.set_item_selectable(i, false)
	
	# Agregar acciones
	for i in range(acciones_correctivas.size()):
		var accion = acciones_correctivas[i]
		var fila_inicio = tabla.get_item_count()
		
		tabla.add_item(accion["id"])
		tabla.add_item(accion["no_conformidad"])
		tabla.add_item(accion["descripcion"])
		tabla.add_item(accion["responsable"])
		tabla.add_item(accion["fecha_limite"])
		tabla.add_item(accion["estado"])
		
		# Color según estado
		for j in range(6):
			match accion["estado"]:
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
