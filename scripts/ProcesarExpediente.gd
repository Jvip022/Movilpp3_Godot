extends Control

"""
Módulo para procesar expedientes de No Conformidades (NC) - Versión corregida
Con manejo de base de datos y diálogos corregido
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
@onready var dialogo_confirmar: AcceptDialog = $DialogoConfirmacion  # CORREGIDO: AcceptDialog en lugar de ConfirmationDialog
@onready var mensaje_exito: AcceptDialog = $MensajeExito
@onready var mensaje_error: AcceptDialog = $MensajeError

# Popup para opciones múltiples
var popup_opciones: PopupMenu
var accion_pendiente: String = ""
var tipo_accion: String = ""

# ============================================================
# VARIABLES DE ESTADO
# ============================================================

var id_nc_actual: int = 0
var datos_nc: Dictionary = {}
var documentos: Array = []
var usuario_actual_id: int = 1

# ============================================================
# FUNCIONES DE INICIALIZACIÓN
# ============================================================

func _ready():
	print("=== PROCESAR EXPEDIENTE - INICIO ===")
	
	# Configurar diálogos para evitar problemas de exclusividad
	dialogo_confirmar.exclusive = true
	mensaje_exito.exclusive = true
	mensaje_error.exclusive = true
	
	# Configurar filtros de archivo
	dialogo_cargar.filters = PackedStringArray([
		"*.pdf ; Documentos PDF",
		"*.doc, *.docx ; Documentos Word",
		"*.xls, *.xlsx ; Hojas de cálculo",
		"*.jpg, *.jpeg, *.png ; Imágenes",
		"*.txt ; Archivos de texto"
	])
	
	# Crear PopupMenu para opciones múltiples
	popup_opciones = PopupMenu.new()
	popup_opciones.id_pressed.connect(_on_opcion_seleccionada)
	add_child(popup_opciones)
	
	# Conectar señales de todos los botones
	_conectar_senales()
	
	# Cargar la NC desde la base de datos
	_cargar_nc_desde_bd()
	
	# Actualizar interfaz
	_actualizar_interfaz()

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

# ============================================================
# FUNCIONES DE CARGA DE DATOS DESDE BD - CORREGIDAS
# ============================================================

func _cargar_nc_desde_bd():
	"""Carga una No Conformidad desde la base de datos para procesamiento."""
	print("Buscando NC para procesar desde BD...")
	
	# PRIMERO: Verificar qué NC existen en la BD
	var sql_test = "SELECT id_nc, codigo_expediente, estado, descripcion FROM no_conformidades LIMIT 10"
	var test_resultado = Bd.select_query(sql_test)
	
	if test_resultado and test_resultado.size() > 0:
		print("📊 NC disponibles en BD:")
		for nc in test_resultado:
			print("   - ID: " + str(nc.get("id_nc", "N/A")) + 
				  ", Código: " + str(nc.get("codigo_expediente", "N/A")) + 
				  ", Estado: " + str(nc.get("estado", "N/A")))
	else:
		print("⚠️ No se encontraron NC en la tabla 'no_conformidades'")
		mensaje_estado.text = "No hay No Conformidades registradas"
		_deshabilitar_todos_botones()
		return
	
	# Buscar NC en estados procesables
	var sql = """
    SELECT 
        nc.*,
        c.nombre as nombre_cliente,
        u.nombre_completo as nombre_responsable
    FROM no_conformidades nc
    LEFT JOIN clientes c ON nc.cliente_id = c.id
    LEFT JOIN usuarios u ON nc.responsable_id = u.id
    WHERE (nc.estado IN ('analizado', 'cerrada', 'pendiente') 
           OR nc.estado IS NULL)
        AND (nc.expediente_cerrado = 0 OR nc.expediente_cerrado IS NULL)
    ORDER BY 
        CASE 
            WHEN nc.estado = 'cerrada' THEN 1
            WHEN nc.estado = 'analizado' THEN 2
            WHEN nc.estado = 'pendiente' THEN 3
            ELSE 4
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
		# Si no hay NC en estados procesables, cargar cualquier NC
		print("⚠️ No hay NC en estados procesables, intentando cargar cualquier NC...")
		sql = """
		SELECT 
			nc.*,
			c.nombre as nombre_cliente,
			u.nombre_completo as nombre_responsable
		FROM no_conformidades nc
		LEFT JOIN clientes c ON nc.cliente_id = c.id
		LEFT JOIN usuarios u ON nc.responsable_id = u.id
		ORDER BY nc.fecha_registro DESC
		LIMIT 1
		"""
		
		resultado = Bd.select_query(sql)
		if resultado and resultado.size() > 0:
			var fila = resultado[0]
			id_nc_actual = fila["id_nc"] if fila.has("id_nc") else 0
			datos_nc = fila.duplicate(true)
			print("✅ NC cargada (cualquier estado): ", id_nc_actual)
			_cargar_documentos_desde_bd()
		else:
			print("⚠️ No hay NC para procesar en BD")
			mensaje_estado.text = "No hay expedientes disponibles para procesar"
			_deshabilitar_todos_botones()

func _cargar_documentos_desde_bd():
	"""Carga los documentos asociados a la NC actual desde la base de datos."""
	if id_nc_actual <= 0:
		print("⚠️ No hay NC activa para cargar documentos")
		return
	
	print("Cargando documentos de NC desde BD: ", id_nc_actual)
	
	# Verificar si la tabla existe
	if not Bd.table_exists("documentos_nc"):
		print("⚠️ Tabla 'documentos_nc' no existe")
		lista_documentos.clear()
		lista_documentos.add_item("No hay documentos disponibles")
		return
	
	var sql = """
    SELECT 
        dn.*,
        u.nombre_completo as nombre_usuario
    FROM documentos_nc dn
    LEFT JOIN usuarios u ON dn.usuario_carga = u.id
    WHERE dn.id_nc = {id_nc}
    ORDER BY dn.fecha_carga DESC
	""".format({"id_nc": id_nc_actual})
	
	var resultado = Bd.select_query(sql)
	
	documentos.clear()
	lista_documentos.clear()
	
	if resultado and resultado.size() > 0:
		for fila in resultado:
			var nombre_archivo = str(fila.get("nombre_archivo", "Sin nombre"))
			var tipo_archivo = str(fila.get("tipo_archivo", ""))
			var fecha_carga = str(fila.get("fecha_carga", ""))
			var usuario = str(fila.get("nombre_usuario", "Desconocido"))
			
			# Agregar a array interno
			documentos.append({
				"id": fila.get("id", 0),
				"nombre": nombre_archivo,
				"ruta": fila.get("ruta_archivo", ""),
				"tipo": tipo_archivo,
				"fecha": fecha_carga,
				"usuario": usuario,
				"descripcion": str(fila.get("descripcion", ""))
			})
			
			# Agregar a ItemList con icono según tipo
			var icono = _obtener_icono_por_tipo(tipo_archivo)
			
			# Mostrar nombre y fecha
			var fecha_formateada = fecha_carga if fecha_carga else "Sin fecha"
			if fecha_formateada.length() >= 10:
				fecha_formateada = fecha_formateada.substr(0, 10)
			
			var texto_item = "{icono} {nombre}\n   📅 {fecha} 👤 {usuario}".format({
				"icono": icono,
				"nombre": nombre_archivo,
				"fecha": fecha_formateada,
				"usuario": usuario
			})
			
			lista_documentos.add_item(texto_item)
		
		print("✅ Documentos cargados desde BD: ", documentos.size())
	else:
		lista_documentos.add_item("No hay documentos asociados")
		print("ℹ️ No hay documentos asociados a esta NC")

func _obtener_icono_por_tipo(tipo_archivo: String) -> String:
	"""Devuelve un emoji según el tipo de archivo."""
	var tipo = tipo_archivo.to_lower()
	match tipo:
		"pdf": return "📄"
		"doc", "docx": return "📝"
		"xls", "xlsx": return "📊"
		"jpg", "jpeg", "png", "gif": return "🖼️"
		_: return "📎"

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
# FUNCIONES DE DECISIÓN (FLUJO BPMN) - SIMPLIFICADAS
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
			dialogo_confirmar.cancel_button_text = "Cancelar"
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
			dialogo_confirmar.cancel_button_text = "Cancelar"
			accion_pendiente = "aprobar_" + opcion
			dialogo_confirmar.popup_centered()
	
	tipo_accion = ""

func _on_DialogoConfirmacion_confirmed():
	"""Procesa la confirmación del diálogo según la acción pendiente."""
	print("✅ Diálogo confirmado")
	
	if accion_pendiente.begins_with("clasificar_"):
		var clasificacion = accion_pendiente.split("_")[1]  # CORREGIDO: accion_pendient -> accion_pendiente
		_procesar_clasificacion(clasificacion)
	elif accion_pendiente.begins_with("aprobar_"):
		var aprobacion = accion_pendiente.split("_")[1]  # CORREGIDO: accion_pendient -> accion_pendiente
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
# FUNCIONES ORIGINALES (MODIFICADAS PARA CORREGIR ERRORES)
# ============================================================

func _on_BotonCargarDoc_pressed():
	print("--- Botón Cargar presionado ---")
	dialogo_cargar.popup_centered(Vector2i(800, 500))

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

func _on_DialogoCargarDoc_file_selected(path: String):
	print("📁 Procesando archivo: ", path)
	
	var nombre_archivo = path.get_file()
	var extension = nombre_archivo.get_extension().to_lower()
	
	# Determinar tipo de archivo
	var tipo_archivo = extension
	
	# Guardar en la base de datos
	var datos_documento = {
		"id_nc": id_nc_actual,
		"nombre_archivo": nombre_archivo,
		"ruta_archivo": path,
		"tipo_archivo": tipo_archivo,
		"tamanio_bytes": _obtener_tamanio_archivo(path),
		"usuario_carga": usuario_actual_id,
		"descripcion": "Documento cargado desde sistema"
	}
	
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

func _obtener_tamanio_archivo(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var tamanio = file.get_length()
		file.close()
		return tamanio
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

# ============================================================
# FUNCIONES DE UTILIDAD
# ============================================================

func _log(mensaje: String):
	"""Función de logging para depuración."""
	print("[ProcesarExpediente] " + mensaje)
