extends Control

"""
Módulo para procesar expedientes de No Conformidades (NC) - Versión con carga automática
Con manejo de base de datos y flujo continuo de expedientes
"""

# ============================================================
# VARIABLES Y REFERENCIAS A NODOS
# ============================================================

# Nodos de información del expediente (Panel Izquierdo)
@onready var label_id: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/IDExpediente
@onready var label_tipo: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/TipoNC
@onready var label_estado: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/EstadoNC
@onready var label_fecha: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/FechaRegistro
@onready var label_desc: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/DescripcionContainer/Descripcion
@onready var lista_documentos: ItemList = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/DocumentosContainer/ListaDocumentos

# Nodos de acciones (Panel Derecho)
@onready var boton_cargar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonCargarDoc
@onready var boton_clasificar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonClasificar
@onready var boton_aprobar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonAprobar
@onready var boton_cerrar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonCerrarExp
@onready var mensaje_estado: Label = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/EstadoContainer/MensajeEstado
@onready var boton_actualizar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/AccionesSecundarias/BtnActualizarInfo

# Nodos del footer
@onready var boton_menu: Button = $Footer/FooterContainer/BtnVolverMenu

# Nodos de diálogo
@onready var dialogo_cargar: FileDialog = $DialogoCargarDoc
@onready var dialogo_confirmar: AcceptDialog = $DialogoConfirmacion
@onready var mensaje_exito: AcceptDialog = $MensajeExito
@onready var mensaje_error: AcceptDialog = $MensajeError

# Nuevo diálogo para preguntar después de cerrar
var dialogo_post_cierre: AcceptDialog

# Popup para opciones múltiples
var popup_opciones: PopupMenu
var accion_pendiente: String = ""
var tipo_accion: String = ""

# Timer para actualización automática
var timer_actualizacion: Timer

# ============================================================
# VARIABLES DE ESTADO
# ============================================================

var id_nc_actual: int = 0
var datos_nc: Dictionary = {}
var documentos: Array = []
var usuario_actual_id: int = 1
var indice_expediente_actual: int = 0  # Para seguimiento de posición

# ============================================================
# FUNCIONES DE INICIALIZACIÓN
# ============================================================

func _ready():
	print("=== PROCESAR EXPEDIENTE - INICIO ===")
	
	# Configurar diálogos para evitar problemas de exclusividad
	dialogo_confirmar.exclusive = true
	mensaje_exito.exclusive = true
	mensaje_error.exclusive = true
	
	# CONFIGURACIÓN CRÍTICA PARA FileDialog
	dialogo_cargar.exclusive = false  # Importante: permitir otros diálogos
	dialogo_cargar.unresizable = false  # Permitir redimensionar
	dialogo_cargar.min_size = Vector2i(600, 400)  # Tamaño mínimo
	
	# Configurar permisos de acceso
	dialogo_cargar.access = FileDialog.ACCESS_FILESYSTEM
	dialogo_cargar.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	
	# Establecer directorio inicial
	dialogo_cargar.current_dir = "user://"  # Directorio del usuario
	dialogo_cargar.current_path = "user://"
	
	# Configurar filtros de archivo - FORMATO CORRECTO
	dialogo_cargar.filters = PackedStringArray([
		"*.pdf", 
		"*.doc; *.docx", 
		"*.xls; *.xlsx", 
		"*.jpg; *.jpeg; *.png",
		"*.txt"
	])
	
	# Crear PopupMenu para opciones múltiples
	popup_opciones = PopupMenu.new()
	popup_opciones.id_pressed.connect(_on_opcion_seleccionada)
	add_child(popup_opciones)
	
	# Crear diálogo para preguntar después de cerrar
	_crear_dialogo_post_cierre()
	
	# Crear timer para actualización automática
	_crear_timer_actualizacion()
	
	# Conectar señales de todos los botones
	_conectar_senales()
	
	# Cargar la primera NC desde la base de datos
	_cargar_nc_desde_bd()
	
	# Actualizar interfaz
	_actualizar_interfaz()

func _crear_dialogo_post_cierre():
	"""Crea el diálogo para preguntar qué hacer después de cerrar un expediente."""
	dialogo_post_cierre = AcceptDialog.new()
	dialogo_post_cierre.title = "✅ Expediente Cerrado"
	dialogo_post_cierre.exclusive = true
	
	# Agregar botones personalizados
	dialogo_post_cierre.add_button("Cargar siguiente expediente", true, "siguiente")
	dialogo_post_cierre.add_button("Buscar otro expediente", true, "buscar")
	dialogo_post_cierre.add_button("Volver al menú principal", true, "menu")
	dialogo_post_cierre.add_button("Quedarme aquí", true, "quedarse")
	
	# Conectar señal para manejar las opciones
	dialogo_post_cierre.custom_action.connect(_on_dialogo_post_cierre_accion)
	
	add_child(dialogo_post_cierre)

func _crear_timer_actualizacion():
	"""Crea un timer para actualización automática periódica."""
	timer_actualizacion = Timer.new()
	timer_actualizacion.wait_time = 60  # 60 segundos = 1 minuto
	timer_actualizacion.timeout.connect(_actualizar_silenciosa)
	timer_actualizacion.autostart = true
	add_child(timer_actualizacion)

func _conectar_senales():
	"""Conecta todas las señales de los botones."""
	print("🔌 Conectando señales...")
	
	# Conectar FileDialog
	dialogo_cargar.file_selected.connect(_on_DialogoCargarDoc_file_selected)
	
	# Conectar botones de acciones
	boton_cargar.pressed.connect(_on_BotonCargarDoc_pressed)
	boton_clasificar.pressed.connect(_on_BotonClasificar_pressed)
	boton_aprobar.pressed.connect(_on_BotonAprobar_pressed)
	boton_cerrar.pressed.connect(_on_BotonCerrarExp_pressed)
	boton_actualizar.pressed.connect(_on_BtnActualizarInfo_pressed)
	
	# Conectar botón del footer
	boton_menu.pressed.connect(_on_BtnVolverMenu_pressed)
	
	# Conectar diálogo de confirmación
	dialogo_confirmar.confirmed.connect(_on_DialogoConfirmacion_confirmed)
	dialogo_confirmar.canceled.connect(_on_DialogoConfirmacion_canceled)
	
	# Conectar señal de doble clic en la lista de documentos
	lista_documentos.item_activated.connect(_on_ListaDocumentos_item_activated)

# ============================================================
# FUNCIONES DE CARGA DE DATOS DESDE BD - MODIFICADAS
# ============================================================

func _cargar_nc_desde_bd():
	"""Carga una No Conformidad desde la base de datos para procesamiento."""
	print("Buscando NC para procesar desde BD...")
	
	# PRIMERO: Verificar qué NC existen en la BD
	var sql_test = "SELECT id_nc, codigo_expediente, estado, descripcion FROM no_conformidades WHERE expediente_cerrado = 0 LIMIT 10"
	var test_resultado = Bd.select_query(sql_test)
	
	if test_resultado and test_resultado.size() > 0:
		print("📊 NC disponibles en BD (no cerradas):")
		indice_expediente_actual = 0  # Resetear índice
		for nc in test_resultado:
			print("   - ID: " + str(nc.get("id_nc", "N/A")) + 
				  ", Código: " + str(nc.get("codigo_expediente", "N/A")) + 
				  ", Estado: " + str(nc.get("estado", "N/A")))
	else:
		print("⚠️ No se encontraron NC en la tabla 'no_conformidades'")
		mensaje_estado.text = "No hay No Conformidades pendientes"
		_deshabilitar_todos_botones()
		return
	
	# Buscar NC en estados procesables (no cerradas)
	var sql = """
    SELECT 
        nc.*,
        c.nombre as nombre_cliente,
        u.nombre_completo as nombre_responsable
    FROM no_conformidades nc
    LEFT JOIN clientes c ON nc.cliente_id = c.id
    LEFT JOIN usuarios u ON nc.responsable_id = u.id
    WHERE (nc.estado IN ('analizado', 'cerrada', 'pendiente', 'pendiente_aprobacion', 'en_revision') 
           OR nc.estado IS NULL)
        AND (nc.expediente_cerrado = 0 OR nc.expediente_cerrado IS NULL)
    ORDER BY 
        CASE 
            WHEN nc.estado = 'cerrada' THEN 1
            WHEN nc.estado = 'pendiente_aprobacion' THEN 2
            WHEN nc.estado = 'analizado' THEN 3
            WHEN nc.estado = 'pendiente' THEN 4
            ELSE 5
        END,
        nc.prioridad ASC, 
        nc.fecha_registro ASC
    LIMIT 1
	"""
	
	var resultado = Bd.select_query(sql)
	
	if resultado and resultado.size() > 0:
		var fila = resultado[0]
		id_nc_actual = fila["id_nc"] if fila.has("id_nc") else 0
		datos_nc = fila.duplicate(true)
		print("✅ NC cargada desde BD: ", id_nc_actual)
		
		# Cargar documentos asociados
		_cargar_documentos_desde_bd()
	else:
		# Si no hay NC en estados procesables, cargar cualquier NC no cerrada
		print("⚠️ No hay NC en estados procesables, intentando cargar cualquier NC no cerrada...")
		sql = """
		SELECT 
			nc.*,
			c.nombre as nombre_cliente,
			u.nombre_completo as nombre_responsable
		FROM no_conformidades nc
		LEFT JOIN clientes c ON nc.cliente_id = c.id
		LEFT JOIN usuarios u ON nc.responsable_id = u.id
		WHERE nc.expediente_cerrado = 0
		ORDER BY nc.fecha_registro DESC
		LIMIT 1
		"""
		
		resultado = Bd.select_query(sql)
		if resultado and resultado.size() > 0:
			var fila = resultado[0]
			id_nc_actual = fila["id_nc"] if fila.has("id_nc") else 0
			datos_nc = fila.duplicate(true)
			print("✅ NC cargada (cualquier estado no cerrado): ", id_nc_actual)
			_cargar_documentos_desde_bd()
		else:
			print("⚠️ No hay NC para procesar en BD")
			mensaje_estado.text = "No hay expedientes disponibles para procesar"
			_deshabilitar_todos_botones()
			
			# Mostrar mensaje especial si todos están cerrados
			sql = "SELECT COUNT(*) as total FROM no_conformidades WHERE expediente_cerrado = 1"
			var total_cerrados = Bd.select_query(sql)
			if total_cerrados and total_cerrados[0]["total"] > 0:
				mensaje_estado.text += "\n\n✅ Todos los expedientes están cerrados"

func _cargar_siguiente_expediente():
	"""Carga el siguiente expediente disponible (no cerrado)."""
	print("🔄 Buscando siguiente expediente disponible...")
	
	# Primero intentar cargar el siguiente por ID
	var sql_siguiente = """
	SELECT id_nc 
	FROM no_conformidades 
	WHERE expediente_cerrado = 0 
	  AND id_nc > ?
	ORDER BY id_nc ASC
	LIMIT 1
	"""
	
	var resultado = Bd.select_query(sql_siguiente, [id_nc_actual])
	
	if resultado and resultado.size() > 0:
		# Cargar el siguiente expediente
		id_nc_actual = resultado[0]["id_nc"]
		_cargar_nc_desde_bd()
		_actualizar_interfaz()
		print("✅ Siguiente expediente cargado: ", id_nc_actual)
		return true
	else:
		# Si no hay siguientes, buscar el primero (ciclo)
		sql_siguiente = """
		SELECT id_nc 
		FROM no_conformidades 
		WHERE expediente_cerrado = 0
		ORDER BY id_nc ASC
		LIMIT 1
		"""
		
		resultado = Bd.select_query(sql_siguiente)
		if resultado and resultado.size() > 0:
			id_nc_actual = resultado[0]["id_nc"]
			_cargar_nc_desde_bd()
			_actualizar_interfaz()
			print("✅ Primer expediente disponible cargado: ", id_nc_actual)
			return true
		else:
			print("⚠️ No hay más expedientes disponibles")
			mensaje_estado.text = "✅ Todos los expedientes han sido procesados"
			_deshabilitar_todos_botones()
			return false

func _buscar_otro_expediente():
	"""Permite al usuario buscar otro expediente específico."""
	print("🔍 Buscando otro expediente...")
	
	# Primero obtener lista de expedientes disponibles
	var sql = """
	SELECT id_nc, codigo_expediente, estado, descripcion
	FROM no_conformidades 
	WHERE expediente_cerrado = 0
	ORDER BY codigo_expediente ASC
	LIMIT 20
	"""
	
	var expedientes = Bd.select_query(sql)
	
	if not expedientes or expedientes.size() == 0:
		print("⚠️ No hay expedientes disponibles")
		mensaje_error.dialog_text = "No hay expedientes pendientes disponibles"
		mensaje_error.popup_centered()
		return
	
	# Crear diálogo de selección
	var dialogo_seleccion = AcceptDialog.new()
	dialogo_seleccion.title = "Seleccionar Expediente"
	dialogo_seleccion.dialog_text = "Seleccione un expediente para procesar:"
	dialogo_seleccion.size = Vector2i(600, 400)
	
	# Crear contenedor con lista
	var scroll_container = ScrollContainer.new()
	scroll_container.size = Vector2i(580, 300)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	for expediente in expedientes:
		var btn = Button.new()
		btn.text = "📋 " + str(expediente["codigo_expediente"]) + " - " + str(expediente["estado"])
		btn.tooltip_text = str(expediente.get("descripcion", ""))
		btn.custom_minimum_size = Vector2i(550, 40)
		btn.text_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Conectar señal con el ID del expediente usando lambda
		btn.pressed.connect(_seleccionar_expediente.bind(expediente["id_nc"], dialogo_seleccion))
		
		vbox.add_child(btn)
	
	scroll_container.add_child(vbox)
	dialogo_seleccion.add_child(scroll_container)
	
	add_child(dialogo_seleccion)
	dialogo_seleccion.popup_centered(Vector2i(620, 450))

func _seleccionar_expediente(id_expediente: int, dialogo: AcceptDialog):
	"""Carga el expediente seleccionado."""
	print("✅ Expediente seleccionado: ", id_expediente)
	id_nc_actual = id_expediente
	_cargar_nc_desde_bd()
	_actualizar_interfaz()
	dialogo.queue_free()

func _cargar_documentos_desde_bd():
	"""Carga los documentos asociados a la NC actual desde la base de datos."""
	if id_nc_actual <= 0:
		print("⚠️ No hay NC activa para cargar documentos")
		lista_documentos.clear()
		lista_documentos.add_item("No hay NC activa")
		return
	
	print("Cargando documentos de NC desde BD: ", id_nc_actual)
	
	# Verificar si la tabla existe
	if not Bd.table_exists("documentos_nc"):
		print("⚠️ Tabla 'documentos_nc' no existe")
		lista_documentos.clear()
		lista_documentos.add_item("Tabla de documentos no disponible")
		return
	
	# CONSULTA CORREGIDA - Usando parámetros de forma segura
	var sql = """
	SELECT 
		dn.*,
		u.nombre_completo as nombre_usuario
	FROM documentos_nc dn
	LEFT JOIN usuarios u ON dn.usuario_carga = u.id
	WHERE dn.id_nc = ?
	ORDER BY dn.fecha_carga DESC
	"""
	
	var valores = [id_nc_actual]
	var resultado = Bd.select_query(sql, valores)
	
	documentos.clear()
	lista_documentos.clear()
	
	if resultado and resultado.size() > 0:
		print("✅ Encontrados " + str(resultado.size()) + " documentos")
		
		for fila in resultado:
			# Obtener valores con valores por defecto seguros
			var nombre_archivo = str(fila.get("nombre_archivo", "Sin nombre"))
			var tipo_archivo = str(fila.get("tipo_archivo", ""))
			var fecha_carga = str(fila.get("fecha_carga", ""))
			var usuario = str(fila.get("nombre_usuario", "Desconocido"))
			var ruta_archivo = str(fila.get("ruta_archivo", ""))
			var descripcion = str(fila.get("descripcion", ""))
			
			# Validar que tenemos datos mínimos
			if nombre_archivo == "" or nombre_archivo == "Sin nombre":
				nombre_archivo = "Documento sin nombre"
			
			# Agregar a array interno
			documentos.append({
				"id": fila.get("id", 0),
				"nombre": nombre_archivo,
				"ruta": ruta_archivo,
				"tipo": tipo_archivo,
				"fecha": fecha_carga,
				"usuario": usuario,
				"descripcion": descripcion
			})
			
			# Agregar a ItemList con icono según tipo
			var icono = _obtener_icono_por_tipo(tipo_archivo)
			
			# Formatear fecha para mostrar
			var fecha_formateada = "Sin fecha"
			if fecha_carga and fecha_carga != "":
				# Intentar varios formatos de fecha
				if fecha_carga.length() >= 10:
					fecha_formateada = fecha_carga.substr(0, 10)
				else:
					fecha_formateada = fecha_carga
			
			# Construir texto para mostrar
			var texto_item = icono + " " + nombre_archivo + "  (" + fecha_formateada + ")"
			
			# Agregar a la lista
			var idx = lista_documentos.add_item(texto_item)
			
			# Agregar metadata útil al item
			lista_documentos.set_item_metadata(idx, {
				"id": fila.get("id", 0),
				"ruta": ruta_archivo,
				"tipo": tipo_archivo,
				"nombre": nombre_archivo
			})
		
		print("✅ Documentos cargados desde BD: ", documentos.size())
		
		# Agregar información para el usuario
		lista_documentos.add_item("💡 Haga doble clic en un documento para abrirlo")
		lista_documentos.set_item_disabled(lista_documentos.item_count - 1, true)
			
	else:
		# No hay documentos - mostrar mensaje informativo
		lista_documentos.add_item("📭 No hay documentos asociados a esta NC")
		
		# Agregar item instructivo
		lista_documentos.add_item("💡 Use 'Cargar Documento' para agregar archivos")
		lista_documentos.set_item_disabled(lista_documentos.item_count - 1, true)
		
		print("ℹ️ No hay documentos asociados a esta NC")

# ============================================================
# FUNCIONES POST-CIERRE (NUEVAS)
# ============================================================

func _on_dialogo_post_cierre_accion(accion: String):
	"""Maneja la selección del usuario después de cerrar un expediente."""
	print("✅ Acción seleccionada post-cierre: ", accion)
	
	match accion:
		"siguiente":
			_cargar_siguiente_expediente()
		
		"buscar":
			_buscar_otro_expediente()
		
		"menu":
			get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")
		
		"quedarse":
			print("ℹ️ Usuario decide quedarse en el expediente cerrado")
			# Mantener la vista actual (expediente cerrado)

func _mostrar_dialogo_post_cierre():
	"""Muestra el diálogo con opciones después de cerrar un expediente."""
	dialogo_post_cierre.dialog_text = """
	✅ Expediente cerrado exitosamente:
	
	📋 ID: {id}
	📅 Fecha: {fecha}
	
	¿Qué desea hacer ahora?
	
	1. Cargar siguiente expediente disponible
	2. Buscar otro expediente específico
	3. Volver al menú principal
	4. Quedarme en este expediente (solo lectura)
	""".format({
		"id": datos_nc.get("codigo_expediente", "N/A"),
		"fecha": Time.get_datetime_string_from_system()
	})
	
	dialogo_post_cierre.popup_centered(Vector2i(500, 400))

# ============================================================
# FUNCIONES DE ACTUALIZACIÓN DE INTERFAZ
# ============================================================

func _actualizar_interfaz():
	"""Actualiza toda la interfaz de usuario con los datos de la NC."""
	print("Actualizando interfaz desde BD...")
	
	if datos_nc.is_empty():
		print("⚠️ No hay datos de NC para mostrar")
		label_id.text = "N/A"
		label_tipo.text = "N/A"
		label_estado.text = "N/A"
		label_fecha.text = "N/A"
		label_desc.text = "No hay expediente cargado"
		return
	
	# Mostrar información básica
	label_id.text = str(datos_nc.get("codigo_expediente", "N/A"))
	label_tipo.text = str(datos_nc.get("tipo_nc", "No especificado"))
	label_estado.text = str(datos_nc.get("estado", "Desconocido"))
	
	# Formatear fecha
	var fecha_registro = str(datos_nc.get("fecha_registro", ""))
	if fecha_registro and fecha_registro != "N/A":
		if fecha_registro.length() >= 10:
			label_fecha.text = fecha_registro.substr(0, 10)
		else:
			label_fecha.text = fecha_registro
	else:
		label_fecha.text = "N/A"
	
	label_desc.text = str(datos_nc.get("descripcion", "Sin descripción"))
	
	# Actualizar botones según estado
	_actualizar_botones_segun_estado()

func _actualizar_botones_segun_estado():
	"""Actualiza el estado de los botones según el estado de la NC."""
	if datos_nc.is_empty():
		mensaje_estado.text = "❌ No hay expediente cargado"
		_deshabilitar_todos_botones()
		return
	
	var estado = str(datos_nc.get("estado", ""))
	var expediente_cerrado = bool(datos_nc.get("expediente_cerrado", false))
	
	# Resetear todos los botones
	_deshabilitar_todos_botones()
	
	if expediente_cerrado:
		mensaje_estado.text = "📁 Expediente cerrado - Solo lectura"
		print("Estado: expediente_cerrado - Todos deshabilitados")
		return
	
	# Habilitar botón de cargar siempre (excepto si está cerrado)
	boton_cargar.disabled = false
	
	match estado:
		"analizado", "pendiente":
			mensaje_estado.text = "📊 Puede clasificar la no conformidad"
			boton_clasificar.disabled = false
			print("Estado: " + estado + " - Clasificar habilitado")
		
		"pendiente_aprobacion":
			mensaje_estado.text = "⏳ Esperando aprobación del comité de calidad"
			boton_aprobar.disabled = false
			print("Estado: pendiente_aprobacion - Aprobar habilitado")
		
		"cerrada":
			mensaje_estado.text = "✅ Puede proceder a cerrar el expediente"
			boton_cerrar.disabled = false
			print("Estado: cerrada - Cerrar habilitado")
		
		_:
			mensaje_estado.text = "⚠️ Estado no procesable: " + estado
			print("Estado: " + estado + " - Todos deshabilitados")

func _deshabilitar_todos_botones():
	"""Deshabilita todos los botones de acción."""
	boton_cargar.disabled = true
	boton_clasificar.disabled = true
	boton_aprobar.disabled = true
	boton_cerrar.disabled = true

# ============================================================
# FUNCIONES DE DECISIÓN (FLUJO BPMN)
# ============================================================

func _on_BotonClasificar_pressed():
	"""Maneja la solicitud de clasificación usando popup."""
	print("📊 Botón Clasificar presionado")
	
	if id_nc_actual <= 0:
		mensaje_error.dialog_text = "No hay NC seleccionada para clasificar"
		mensaje_error.popup_centered()
		return
	
	tipo_accion = "clasificar"
	
	# Configurar popup con opciones
	popup_opciones.clear()
	popup_opciones.add_item("Leve", 0)
	popup_opciones.add_item("Mayor", 1)
	popup_opciones.add_item("Crítica", 2)
	
	popup_opciones.position = get_global_mouse_position()
	popup_opciones.popup()

func _on_BotonAprobar_pressed():
	"""Maneja la solicitud de aprobación usando popup."""
	print("✅ Botón Aprobar presionado")
	
	if id_nc_actual <= 0:
		mensaje_error.dialog_text = "No hay NC seleccionada para aprobar"
		mensaje_error.popup_centered()
		return
	
	tipo_accion = "aprobar"
	
	# Configurar popup con opciones
	popup_opciones.clear()
	popup_opciones.add_item("Aprobar", 0)
	popup_opciones.add_item("Rechazar", 1)
	popup_opciones.add_item("Revisar", 2)
	
	popup_opciones.position = get_global_mouse_position()
	popup_opciones.popup()

func _on_opcion_seleccionada(id: int):
	"""Procesa la opción seleccionada en el popup."""
	var opcion = ""
	
	match tipo_accion:
		"clasificar":
			match id:
				0: opcion = "Leve"
				1: opcion = "Mayor"
				2: opcion = "Crítica"
			
			# Mostrar diálogo de confirmación
			dialogo_confirmar.dialog_text = """
			📋 CONFIRMAR CLASIFICACIÓN
			
			¿Clasificar como: {clasificacion}?
			
			ID Expediente: {id}
			""".format({
				"clasificacion": opcion,
				"id": datos_nc.get("codigo_expediente", "")
			})
			
			dialogo_confirmar.ok_button_text = "Sí, clasificar"
			accion_pendiente = "clasificar_" + opcion
			dialogo_confirmar.popup_centered()
		
		"aprobar":
			match id:
				0: opcion = "Aprobar"
				1: opcion = "Rechazar"
				2: opcion = "Revisar"
			
			# Mostrar diálogo de confirmación
			dialogo_confirmar.dialog_text = """
			📋 CONFIRMAR DICTAMEN
			
			¿Procesar como: {aprobacion}?
			
			ID Expediente: {id}
			""".format({
				"aprobacion": opcion,
				"id": datos_nc.get("codigo_expediente", "")
			})
			
			dialogo_confirmar.ok_button_text = "Sí, procesar"
			accion_pendiente = "aprobar_" + opcion
			dialogo_confirmar.popup_centered()
	
	tipo_accion = ""

func _on_DialogoConfirmacion_confirmed():
	"""Procesa la confirmación del diálogo según la acción pendiente."""
	print("✅ Diálogo confirmado")
	
	if accion_pendiente.begins_with("clasificar_"):
		var clasificacion = accion_pendiente.split("_")[1]
		_procesar_clasificacion(clasificacion)
	elif accion_pendiente.begins_with("aprobar_"):
		var aprobacion = accion_pendiente.split("_")[1]
		_procesar_aprobacion(aprobacion)
	elif accion_pendiente == "cerrar":
		_cerrar_expediente_bd()
	
	accion_pendiente = ""

func _on_DialogoConfirmacion_canceled():
	"""Maneja la cancelación del diálogo."""
	print("❌ Diálogo cancelado")
	accion_pendiente = ""

func _procesar_clasificacion(clasificacion: String):
	"""Procesa la clasificación seleccionada."""
	print("📝 Clasificando como: ", clasificacion)
	
	var nuevo_estado = "cerrada"
	if clasificacion == "Crítica":
		nuevo_estado = "pendiente_aprobacion"
	
	# Usar consulta UPDATE directa
	var sql = """
	UPDATE no_conformidades 
	SET clasificacion = ?, 
		estado = ?,
		fecha_clasificacion = datetime('now'),
		usuario_clasificacion = ?
	WHERE id_nc = ?
	"""
	
	var valores = [clasificacion, nuevo_estado, usuario_actual_id, id_nc_actual]
	
	# Usar query en lugar de select_query para UPDATE
	if Bd.query(sql, valores):
		print("✅ NC clasificada como: ", clasificacion)
		
		# Registrar traza (si existe la tabla)
		if Bd.table_exists("trazas_nc"):
			_registrar_traza("CLASIFICACION_NC", "NC clasificada como: " + clasificacion)
		
		# Recargar datos
		_cargar_nc_desde_bd()
		_actualizar_interfaz()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ NC clasificada como '{clasificacion}'".format({"clasificacion": clasificacion})
		mensaje_exito.popup_centered()
	else:
		print("❌ Error al clasificar NC")
		mensaje_error.dialog_text = "Error al clasificar la no conformidad."
		mensaje_error.popup_centered()

func _procesar_aprobacion(aprobacion: String):
	"""Procesa la aprobación seleccionada."""
	print("📝 Aprobación: ", aprobacion)
	
	var nuevo_estado = "cerrada"
	match aprobacion:
		"Aprobar": nuevo_estado = "cerrada"
		"Rechazar": nuevo_estado = "rechazado"
		"Revisar": nuevo_estado = "en_revision"
		_: nuevo_estado = "pendiente_aprobacion"
	
	# Usar consulta UPDATE directa
	var sql = """
	UPDATE no_conformidades 
	SET aprobacion = ?, 
		estado = ?,
		fecha_aprobacion = datetime('now'),
		usuario_aprobacion = ?
	WHERE id_nc = ?
	"""
	
	var valores = [aprobacion, nuevo_estado, usuario_actual_id, id_nc_actual]
	
	# Usar query en lugar de select_query para UPDATE
	if Bd.query(sql, valores):
		print("✅ Dictamen procesado: ", aprobacion)
		
		# Registrar traza (si existe la tabla)
		if Bd.table_exists("trazas_nc"):
			_registrar_traza("APROBACION_NC", "Dictamen: " + aprobacion)
		
		# Recargar datos
		_cargar_nc_desde_bd()
		_actualizar_interfaz()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ Dictamen '{aprobacion}' registrado".format({"aprobacion": aprobacion})
		mensaje_exito.popup_centered()
	else:
		print("❌ Error al procesar dictamen")
		mensaje_error.dialog_text = "Error al procesar el dictamen"
		mensaje_error.popup_centered()

# ============================================================
# FUNCIONES ORIGINALES CON MEJORAS
# ============================================================

func _on_BotonCargarDoc_pressed():
	print("--- Botón Cargar presionado ---")
	
	# Verificar que hay una NC activa
	if id_nc_actual <= 0:
		mensaje_error.dialog_text = "No hay expediente activo para cargar documentos"
		mensaje_error.popup_centered()
		return
	
	# Cerrar otros diálogos primero
	_cerrar_todos_dialogos()
	
	# Configurar directorio inicial a Documentos del sistema
	var directorio_documentos = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	dialogo_cargar.current_dir = directorio_documentos
	dialogo_cargar.current_path = ""
	
	# Mostrar FileDialog usando popup_centered_ratio para mejor control
	dialogo_cargar.popup_centered_ratio(0.7)
	
	print("✅ FileDialog abierto en: ", directorio_documentos)

func _cerrar_todos_dialogos():
	"""Cierra todos los diálogos abiertos."""
	if dialogo_cargar.visible:
		dialogo_cargar.hide()
	if dialogo_confirmar.visible:
		dialogo_confirmar.hide()
	if mensaje_exito.visible:
		mensaje_exito.hide()
	if mensaje_error.visible:
		mensaje_error.hide()
	if dialogo_post_cierre.visible:
		dialogo_post_cierre.hide()

func _on_BotonCerrarExp_pressed():
	print("📦 Botón Cerrar expediente presionado")
	
	accion_pendiente = "cerrar"
	
	dialogo_confirmar.dialog_text = """
	¿Está seguro que desea cerrar definitivamente este expediente?
	
	📋 ID: {id}
	📄 Estado: {estado}
	
	⚠️ Esta acción no se puede deshacer.
	""".format({
		"id": datos_nc.get("codigo_expediente", ""),
		"estado": datos_nc.get("estado", "")
	})
	
	dialogo_confirmar.ok_button_text = "Sí, cerrar expediente"
	dialogo_confirmar.popup_centered()

func _cerrar_expediente_bd():
	"""Cierra el expediente en la base de datos."""
	print("🚪 Cerrando expediente en BD...")
	
	var sql = """
	UPDATE no_conformidades 
	SET expediente_cerrado = 1,
		fecha_cierre = datetime('now'),
		usuario_cierre = ?,
		estado = 'expediente_cerrado'
	WHERE id_nc = ?
	"""
	
	var valores = [usuario_actual_id, id_nc_actual]
	
	if Bd.query(sql, valores):
		print("✅ Expediente cerrado en BD")
		
		# Actualizar datos locales
		datos_nc["estado"] = "expediente_cerrado"
		datos_nc["expediente_cerrado"] = 1
		
		# Actualizar interfaz
		_actualizar_interfaz()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ Expediente cerrado exitosamente"
		mensaje_exito.popup_centered()
		
		# Registrar traza de auditoría (si existe la tabla)
		if Bd.table_exists("trazas_nc"):
			_registrar_traza("CIERRE_EXPEDIENTE", "Expediente cerrado: " + str(datos_nc.get("codigo_expediente", "")))
		
		# Esperar 0.5 segundos y mostrar opciones post-cierre
		await get_tree().create_timer(0.5).timeout
		_mostrar_dialogo_post_cierre()
	else:
		print("❌ Error al cerrar expediente en BD")
		mensaje_error.dialog_text = "Error al cerrar el expediente en la base de datos"
		mensaje_error.popup_centered()

func _on_BtnVolverMenu_pressed():
	print("🏠 Regresando al menú principal...")
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_BtnActualizarInfo_pressed():
	print("🔄 Actualizando información desde BD...")
	
	# Recargar datos del expediente
	_cargar_nc_desde_bd()
	
	# Actualizar interfaz
	_actualizar_interfaz()
	
	mensaje_exito.dialog_text = "✅ Información actualizada correctamente"
	mensaje_exito.popup_centered()
	
	print("✅ Información actualizada desde BD")

func _actualizar_silenciosa():
	"""Actualiza datos sin mostrar mensaje (para no molestar al usuario)."""
	if not dialogo_cargar.visible and not dialogo_confirmar.visible:
		if id_nc_actual > 0:
			_cargar_nc_desde_bd()
			_actualizar_interfaz()
			print("🔄 Actualización silenciosa completada")

func _on_DialogoCargarDoc_file_selected(path: String):
	print("📁 Procesando archivo: ", path)
	
	# Verificar que la ruta sea válida
	if path.is_empty():
		print("❌ Ruta de archivo vacía")
		mensaje_error.dialog_text = "No se seleccionó ningún archivo"
		mensaje_error.popup_centered()
		return
	
	# Verificar que el archivo exista
	if not FileAccess.file_exists(path):
		print("❌ El archivo no existe: ", path)
		mensaje_error.dialog_text = "El archivo seleccionado no existe o no se puede acceder"
		mensaje_error.popup_centered()
		return
	
	var nombre_archivo = path.get_file()
	var extension = nombre_archivo.get_extension().to_lower()
	
	# Validar extensión
	if extension.is_empty():
		print("⚠️ Archivo sin extensión: ", nombre_archivo)
		mensaje_error.dialog_text = "El archivo no tiene extensión válida"
		mensaje_error.popup_centered()
		return
	
	# Determinar tipo de archivo
	var tipo_archivo = extension
	
	# Obtener tamaño
	var tamanio_bytes = _obtener_tamanio_archivo(path)
	if tamanio_bytes <= 0:
		print("⚠️ Archivo de tamaño 0 o no accesible: ", path)
	
	# Guardar en la base de datos
	var datos_documento = {
		"id_nc": id_nc_actual,
		"nombre_archivo": nombre_archivo,
		"ruta_archivo": path,
		"tipo_archivo": tipo_archivo,
		"tamanio_bytes": tamanio_bytes,
		"usuario_carga": usuario_actual_id,
		"descripcion": "Documento cargado desde sistema"
	}
	
	print("📝 Insertando documento en BD: ", datos_documento)
	
	var id_insertado = Bd.insert("documentos_nc", datos_documento)
	
	if id_insertado > 0:
		print("✅ Documento guardado en BD con ID: ", id_insertado)
		
		# Actualizar la lista de documentos
		_cargar_documentos_desde_bd()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ Documento '{nombre}' cargado exitosamente".format({"nombre": nombre_archivo})
		mensaje_exito.popup_centered()
		
		# Registrar traza de auditoría (si existe la tabla)
		if Bd.table_exists("trazas_nc"):
			_registrar_traza("CARGA_DOCUMENTO", "Documento cargado: " + nombre_archivo)
	else:
		print("❌ Error al guardar documento en BD")
		mensaje_error.dialog_text = "Error al guardar el documento en la base de datos"
		mensaje_error.popup_centered()

# ============================================================
# FUNCIONES DE UTILIDAD (SIN CAMBIOS)
# ============================================================

func _obtener_icono_por_tipo(tipo_archivo: String) -> String:
	"""Devuelve un emoji según el tipo de archivo."""
	var tipo = tipo_archivo.to_lower()
	match tipo:
		"pdf": return "📄"
		"doc", "docx": return "📝"
		"xls", "xlsx": return "📊"
		"jpg", "jpeg", "png", "gif": return "🖼️"
		_: return "📎"

func _on_ListaDocumentos_item_activated(index: int):
	"""Abre el documento al hacer doble clic en la lista."""
	
	# Verificar que el índice sea válido
	if index < 0 or index >= lista_documentos.item_count:
		print("⚠️ Índice inválido: ", index)
		return
	
	# Obtener metadata del item
	var metadata = lista_documentos.get_item_metadata(index)
	
	# Verificar si es un documento válido (tiene metadata con ruta)
	if metadata == null:
		print("ℹ️ Item sin metadata (probablemente mensaje informativo)")
		return
	
	# Obtener la ruta del archivo
	var ruta_archivo = metadata.get("ruta", "")
	var nombre_archivo = metadata.get("nombre", "Documento")
	var tipo_archivo = metadata.get("tipo", "")
	
	if ruta_archivo.is_empty():
		print("⚠️ No hay ruta para abrir el documento")
		mensaje_error.dialog_text = "No se encontró la ruta del documento"
		mensaje_error.popup_centered()
		return
	
	print("📂 Intentando abrir documento: ", nombre_archivo)
	print("   - Ruta: ", ruta_archivo)
	print("   - Tipo: ", tipo_archivo)
	
	# Verificar si el archivo existe
	if not FileAccess.file_exists(ruta_archivo):
		print("❌ El archivo no existe en la ruta: ", ruta_archivo)
		
		# Intentar buscar en diferentes ubicaciones
		var archivo_encontrado = _buscar_archivo_alternativo(nombre_archivo, ruta_archivo)
		if archivo_encontrado != "":
			ruta_archivo = archivo_encontrado
			print("✅ Archivo encontrado en ubicación alternativa: ", ruta_archivo)
		else:
			mensaje_error.dialog_text = """
			No se pudo encontrar el archivo: 
			
			{nombre}
			
			Ruta original: {ruta}
			
			Posibles causas:
			1. El archivo fue movido o eliminado
			2. La ruta almacenada es incorrecta
			3. No tiene permisos de acceso
			""".format({"nombre": nombre_archivo, "ruta": ruta_archivo})
			mensaje_error.popup_centered()
			return
	
	# Intentar abrir el archivo con la aplicación predeterminada del sistema
	var resultado = OS.shell_open(ruta_archivo)
	
	if resultado == OK:
		print("✅ Documento abierto exitosamente: ", nombre_archivo)
		
		# Registrar la acción en trazas si existe la tabla
		if Bd.table_exists("trazas_nc"):
			_registrar_traza("APERTURA_DOCUMENTO", "Documento abierto: " + nombre_archivo)
	else:
		print("❌ Error al abrir el documento: ", nombre_archivo)
		
		# Intentar métodos alternativos para abrir el archivo
		if not _intentar_abrir_con_metodo_alternativo(ruta_archivo, tipo_archivo):
			mensaje_error.dialog_text = """
			No se pudo abrir el documento: 
			
			{nombre}
			
			Error: El sistema no tiene una aplicación asociada para abrir este tipo de archivo.
			
			Tipo de archivo: {tipo}
			""".format({"nombre": nombre_archivo, "tipo": tipo_archivo})
			mensaje_error.popup_centered()

func _buscar_archivo_alternativo(nombre_archivo: String, ruta_original: String) -> String:
	"""Busca el archivo en ubicaciones alternativas."""
	print("🔍 Buscando archivo en ubicaciones alternativas...")
	
	# Lista de directorios donde buscar
	var directorios_busqueda = [
		"user://",
		OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS),
		OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS),
		OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP),
		"res://",
		ProjectSettings.globalize_path("user://")
	]
	
	# También buscar en la carpeta de la aplicación
	var exe_path = OS.get_executable_path().get_base_dir()
	if exe_path != "":
		directorios_busqueda.append(exe_path)
	
	for directorio in directorios_busqueda:
		var ruta_posible = directorio.path_join(nombre_archivo)
		if FileAccess.file_exists(ruta_posible):
			print("✅ Encontrado en: ", ruta_posible)
			return ruta_posible
	
	# Intentar buscar solo por nombre en todo el directorio original
	var directorio_base = ruta_original.get_base_dir()
	if directorio_base != "" and directorio_base != ".":
		var dir = DirAccess.open(directorio_base)
		if dir:
			dir.list_dir_begin()
			var nombre_archivo_actual = dir.get_next()
			while nombre_archivo_actual != "":
				if nombre_archivo_actual == nombre_archivo or nombre_archivo_actual.find(nombre_archivo) != -1:
					var ruta_encontrada = directorio_base.path_join(nombre_archivo_actual)
					if FileAccess.file_exists(ruta_encontrada):
						print("✅ Encontrado por nombre similar: ", ruta_encontrada)
						return ruta_encontrada
				nombre_archivo_actual = dir.get_next()
	
	print("❌ No se encontró el archivo en ubicaciones alternativas")
	return ""

func _intentar_abrir_con_metodo_alternativo(ruta_archivo: String, tipo_archivo: String) -> bool:
	"""Intenta abrir el archivo con métodos alternativos."""
	print("🔄 Intentando métodos alternativos para abrir: ", ruta_archivo)
	
	# Dependiendo del tipo de archivo, usar diferentes estrategias
	match tipo_archivo.to_lower():
		"txt", "log", "csv":
			# Para archivos de texto, intentar abrir con editor de texto simple
			print("📝 Archivo de texto detectado, usando método alternativo")
			# En Godot podemos mostrar el contenido en un diálogo si es pequeño
			return _mostrar_contenido_texto(ruta_archivo)
		
		"jpg", "jpeg", "png", "gif", "bmp":
			# Para imágenes, podemos cargarlas y mostrarlas en la aplicación
			print("🖼️ Imagen detectada, usando método alternativo")
			return _mostrar_imagen(ruta_archivo)
		
		_:
			print("⚠️ No hay método alternativo para el tipo: ", tipo_archivo)
			return false

func _mostrar_contenido_texto(ruta_archivo: String) -> bool:
	"""Muestra el contenido de un archivo de texto en un diálogo."""
	var file = FileAccess.open(ruta_archivo, FileAccess.READ)
	if file:
		var contenido = file.get_as_text()
		file.close()
		
		# Limitar el tamaño para no saturar el diálogo
		if contenido.length() > 10000:
			contenido = contenido.substr(0, 10000) + "\n\n... (contenido truncado, archivo muy grande)"
		
		# Crear diálogo para mostrar el contenido
		var dialogo_texto = AcceptDialog.new()
		dialogo_texto.title = "Contenido del archivo"
		dialogo_texto.dialog_text = contenido
		dialogo_texto.size = Vector2i(800, 600)
		
		# Agregar área de texto desplazable para contenido largo
		var scroll_container = ScrollContainer.new()
		scroll_container.size = Vector2i(780, 500)
		
		var label_contenido = RichTextLabel.new()
		label_contenido.bbcode_enabled = false
		label_contenido.text = contenido
		label_contenido.scroll_following = true
		label_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		scroll_container.add_child(label_contenido)
		dialogo_texto.add_child(scroll_container)
		
		add_child(dialogo_texto)
		dialogo_texto.popup_centered(Vector2i(800, 600))
		
		return true
	
	return false

func _mostrar_imagen(ruta_archivo: String) -> bool:
	"""Muestra una imagen en un diálogo."""
	var imagen = Image.load_from_file(ruta_archivo)
	if imagen:
		var textura = ImageTexture.create_from_image(imagen)
		
		# Crear diálogo para mostrar la imagen
		var dialogo_imagen = AcceptDialog.new()
		dialogo_imagen.title = "Vista previa de imagen"
		dialogo_imagen.dialog_text = ""
		
		var textura_rect = TextureRect.new()
		textura_rect.texture = textura
		textura_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textura_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		textura_rect.custom_minimum_size = Vector2i(600, 400)
		
		dialogo_imagen.add_child(textura_rect)
		add_child(dialogo_imagen)
		dialogo_imagen.popup_centered(Vector2i(650, 450))
		
		return true
	
	return false

func _obtener_tamanio_archivo(path: String) -> int:
	if not FileAccess.file_exists(path):
		print("⚠️ El archivo no existe: ", path)
		return 0
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var tamanio = file.get_length()
		file.close()
		return tamanio
	else:
		print("⚠️ No se pudo abrir el archivo para lectura: ", path)
		return 0

func _registrar_traza(accion: String, detalles: String):
	"""Registra una traza en la base de datos (si la tabla existe)."""
	if not Bd.table_exists("trazas_nc"):
		print("⚠️ Tabla 'trazas_nc' no existe, no se puede registrar traza")
		return
	
	var datos_traza = {
		"id_nc": id_nc_actual,
		"usuario_id": usuario_actual_id,
		"accion": accion,
		"detalles": detalles,
		"ip_address": "127.0.0.1"
	}
	
	var id_traza = Bd.insert("trazas_nc", datos_traza)
	if id_traza > 0:
		print("✅ Traza registrada con ID: ", id_traza)
	else:
		print("⚠️ No se pudo registrar traza")

func _log(mensaje: String):
	"""Función de logging para depuración."""
	print("[ProcesarExpediente] " + mensaje)

func _verificar_dialogos():
	"""Verifica el estado de todos los diálogos."""
	print("=== ESTADO DE DIÁLOGOS ===")
	print("FileDialog visible: ", dialogo_cargar.visible)
	print("FileDialog enabled: ", dialogo_cargar.disabled == false)
	print("FileDialog exclusive: ", dialogo_cargar.exclusive)
	print("FileDialog filters: ", dialogo_cargar.filters)
	print("=== FIN ESTADO ===")
