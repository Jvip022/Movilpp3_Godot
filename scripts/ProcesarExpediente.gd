extends Control

"""
Módulo para procesar expedientes de No Conformidades (NC) - Refactorizado BPMN

Esta escena permite a los usuarios especialistas de calidad:
1. Evaluar incidencias y solicitar clasificación de NC
2. Solicitar aprobación de dictámenes
3. Cerrar expedientes cuando la NC está en estado 'cerrada'
4. Gestionar documentos asociados a cada NC
5. Todas las decisiones humanas pasan por diálogos reutilizables

Usa la base de datos SQLite existente (BD.gd singleton)
"""

# ============================================================
# VARIABLES Y REFERENCIAS A NODOS (ACTUALIZADAS PARA NUEVO DISEÑO)
# ============================================================

# Nodos de información del expediente (Panel Izquierdo) - NUEVAS RUTAS
@onready var label_id: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/IDExpediente
@onready var label_tipo: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/TipoNC
@onready var label_estado: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/EstadoNC
@onready var label_fecha: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/InfoGrid/FechaRegistro
@onready var label_desc: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/DescripcionContainer/Descripcion
@onready var lista_documentos: ItemList = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/InfoContainer/DocumentosContainer/ListaDocumentos

# Nodos de acciones (Panel Derecho) - NUEVAS RUTAS
@onready var boton_cargar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonCargarDoc
@onready var boton_clasificar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonClasificar
@onready var boton_aprobar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonAprobar
@onready var boton_cerrar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/BotonesContainer/BotonCerrarExp
@onready var mensaje_estado: Label = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/EstadoContainer/MensajeEstado
@onready var boton_actualizar: Button = $ContentContainer/PanelDerecho/PanelAcciones/AccionesContainer/AccionesSecundarias/BtnActualizarInfo

# Nodos del footer - NUEVAS RUTAS
@onready var boton_menu: Button = $Footer/FooterContainer/BtnVolverMenu

# Nodos de diálogo (sin cambios)
@onready var dialogo_cargar: FileDialog = $DialogoCargarDoc
@onready var dialogo_confirmar: AcceptDialog = $DialogoConfirmacion
@onready var mensaje_exito: AcceptDialog = $MensajeExito
@onready var mensaje_error: AcceptDialog = $MensajeError

# ============================================================
# VARIABLES DE ESTADO
# ============================================================

var id_nc_actual: int = 0
var datos_nc: Dictionary = {}
var documentos: Array = []

# ============================================================
# FUNCIONES DE INICIALIZACIÓN
# ============================================================

func _ready():
	print("=== PROCESAR EXPEDIENTE - INICIO ===")
	
	# Verificar estructura de la base de datos
	_verificar_estructura_bd()
	
	# Conectar señales de todos los botones
	_conectar_senales()
	
	# Configurar filtros de archivo
	dialogo_cargar.filters = PackedStringArray([
		"*.pdf ; Documentos PDF",
		"*.doc, *.docx ; Documentos Word",
		"*.xls, *.xlsx ; Hojas de cálculo",
		"*.jpg, *.jpeg, *.png ; Imágenes",
		"*.txt ; Archivos de texto"
	])
	
	# Cargar la NC desde la base de datos
	_cargar_nc_desde_bd()
	
	# Actualizar interfaz
	_actualizar_interfaz()

func _verificar_estructura_bd():
	"""Verifica la estructura de la tabla no_conformidades."""
	print("🔍 Verificando estructura de la tabla no_conformidades...")
	
	# Verificar si la tabla existe
	if not Bd.table_exists("no_conformidades"):
		print("❌ Tabla 'no_conformidades' no existe")
		return
	
	# Obtener estructura de la tabla
	var estructura = Bd.get_table_structure("no_conformidades")
	print("📋 Estructura de la tabla 'no_conformidades':")
	for columna in estructura:
		print("   - " + str(columna))
	
	# Verificar columnas necesarias
	var columnas_requeridas = ["clasificacion", "fecha_clasificacion", "usuario_clasificacion", 
							   "aprobacion", "fecha_aprobacion", "usuario_aprobacion",
							   "expediente_cerrado", "fecha_cierre", "usuario_cierre"]
	
	var columnas_faltantes = []
	for columna in columnas_requeridas:
		var encontrada = false
		for col in estructura:
			if col.get("name", "") == columna:
				encontrada = true
				break
		
		if not encontrada:
			columnas_faltantes.append(columna)
	
	if columnas_faltantes.size() > 0:
		print("⚠️ Columnas faltantes: ", columnas_faltantes)
		print("Intentando agregar columnas faltantes...")
		_agregar_columnas_faltantes(columnas_faltantes)
	else:
		print("✅ Todas las columnas requeridas existen")

func _agregar_columnas_faltantes(columnas_faltantes: Array):
	"""Agrega columnas faltantes a la tabla no_conformidades."""
	for columna in columnas_faltantes:
		var tipo_columna = "TEXT"
		if columna in ["usuario_clasificacion", "usuario_aprobacion", "usuario_cierre", "expediente_cerrado"]:
			tipo_columna = "INTEGER"
		
		var sql = "ALTER TABLE no_conformidades ADD COLUMN {columna} {tipo}".format({
			"columna": columna,
			"tipo": tipo_columna
		})
		
		print("   Agregando columna '{columna}'...".format({"columna": columna}))
		var resultado = Bd.query(sql)
		if resultado:
			print("   ✅ Columna '{columna}' agregada".format({"columna": columna}))
		else:
			print("   ❌ Error al agregar columna '{columna}'".format({"columna": columna}))

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

# ============================================================
# FUNCIONES DE CARGA DE DATOS DESDE BD
# ============================================================

func _cargar_nc_desde_bd():
	"""Carga una No Conformidad desde la base de datos para procesamiento."""
	print("Buscando NC para procesar desde BD...")
	
	# Verificar si la tabla existe
	if not Bd.table_exists("no_conformidades"):
		print("❌ Tabla 'no_conformidades' no existe")
		mensaje_estado.text = "Error: Tabla de NC no encontrada en BD"
		return
	
	# Buscar la primera NC en estado 'analizado' o 'cerrada'
	var sql = """
    SELECT 
        nc.*,
        c.nombre as nombre_cliente,
        u.nombre_completo as nombre_responsable
    FROM no_conformidades nc
    LEFT JOIN clientes c ON nc.cliente_id = c.id
    LEFT JOIN usuarios u ON nc.responsable_id = u.id
    WHERE nc.estado IN ('analizado', 'cerrada')
        AND (nc.expediente_cerrado = 0 OR nc.expediente_cerrado IS NULL)
    ORDER BY nc.prioridad ASC, nc.fecha_registro ASC
    LIMIT 1
	"""
	
	var resultado = Bd.select_query(sql)
	
	if resultado and resultado.size() > 0:
		var fila = resultado[0]
		id_nc_actual = fila["id_nc"]
		datos_nc = fila
		print("✅ NC cargada desde BD: ", id_nc_actual)
		print("📊 Datos NC: ", datos_nc)
		
		# Cargar documentos asociados
		_cargar_documentos_desde_bd()
	else:
		print("⚠️ No hay NC para procesar en BD")
		mensaje_estado.text = "No hay expedientes disponibles para procesar"
		_deshabilitar_todos_botones()

func _cargar_documentos_desde_bd():
	"""Carga los documentos asociados a la NC actual desde la base de datos."""
	print("Cargando documentos de NC desde BD: ", id_nc_actual)
	
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
	
	if resultado:
		for fila in resultado:
			var nombre_archivo = fila["nombre_archivo"]
			var tipo_archivo = fila["tipo_archivo"]
			var fecha_carga = fila["fecha_carga"]
			var usuario = fila["nombre_usuario"] or "Desconocido"
			
			# Agregar a array interno
			documentos.append({
				"id": fila["id"],
				"nombre": nombre_archivo,
				"ruta": fila["ruta_archivo"],
				"tipo": tipo_archivo,
				"fecha": fecha_carga,
				"usuario": usuario,
				"descripcion": fila["descripcion"] or ""
			})
			
			# Agregar a ItemList con icono según tipo
			var icono = ""
			if tipo_archivo:
				match tipo_archivo.to_lower():
					"pdf": icono = "📄"
					"doc", "docx": icono = "📝"
					"xls", "xlsx": icono = "📊"
					"jpg", "jpeg", "png": icono = "🖼️"
					_: icono = "📎"
			else:
				icono = "📎"
			
			# Mostrar nombre y fecha
			var fecha_formateada = fecha_carga if fecha_carga else "Sin fecha"
			var texto_item = "{icono} {nombre}\n   📅 {fecha} 👤 {usuario}".format({
				"icono": icono,
				"nombre": nombre_archivo,
				"fecha": fecha_formateada.substr(0, 10) if fecha_formateada.length() >= 10 else fecha_formateada,
				"usuario": usuario
			})
			
			lista_documentos.add_item(texto_item)
	
	print("✅ Documentos cargados desde BD: ", documentos.size())

# ============================================================
# FUNCIONES DE ACTUALIZACIÓN DE INTERFAZ
# ============================================================

func _actualizar_interfaz():
	"""Actualiza toda la interfaz de usuario con los datos de la NC."""
	print("Actualizando interfaz desde BD...")
	
	if datos_nc.size() == 0:
		print("⚠️ No hay datos de NC para mostrar")
		return
	
	# Mostrar información básica - solo el valor, las etiquetas ya están en el diseño
	label_id.text = datos_nc.get("codigo_expediente", "N/A")
	label_tipo.text = datos_nc.get("tipo_nc", "No especificado")
	label_estado.text = datos_nc.get("estado", "Desconocido")
	
	# Formatear fecha
	var fecha_registro = datos_nc.get("fecha_registro", "")
	if fecha_registro:
		label_fecha.text = fecha_registro.substr(0, 10)
	else:
		label_fecha.text = "N/A"
	
	label_desc.text = datos_nc.get("descripcion", "Sin descripción")
	
	# Actualizar botones según estado
	_actualizar_botones_segun_estado()

func _actualizar_botones_segun_estado():
	"""Actualiza el estado de los botones según el estado de la NC."""
	var estado = datos_nc.get("estado", "")
	
	# Resetear todos los botones
	_deshabilitar_todos_botones()
	
	match estado:
		"analizado":
			mensaje_estado.text = "📊 Puede clasificar la no conformidad"
			boton_cargar.disabled = false
			boton_clasificar.disabled = false
			print("Estado: analizado - Clasificar habilitado")
		
		"pendiente_aprobacion":
			mensaje_estado.text = "⏳ Esperando aprobación del comité de calidad"
			boton_cargar.disabled = false
			boton_aprobar.disabled = false
			print("Estado: pendiente_aprobacion - Aprobar habilitado")
		
		"cerrada":
			mensaje_estado.text = "✅ Puede proceder a cerrar el expediente"
			boton_cargar.disabled = false
			boton_cerrar.disabled = false
			print("Estado: cerrada - Cerrar habilitado")
		
		"expediente_cerrado":
			mensaje_estado.text = "📁 Expediente cerrado - Solo lectura"
			print("Estado: expediente_cerrado - Todos deshabilitados")
		
		_:
			mensaje_estado.text = "⚠️ Estado no procesable: " + estado
			print("Estado: ", estado, " - Todos deshabilitados")

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
	"""Maneja la solicitud de clasificación usando diálogo."""
	print("📊 Botón Clasificar presionado")
	
	# Crear un diálogo simple de clasificación
	dialogo_confirmar.dialog_text = """
	📋 CLASIFICAR NO CONFORMIDAD
	
	ID Expediente: {id}
	Descripción: {desc}
	
	Seleccione la clasificación:
	""".format({
		"id": datos_nc.get("codigo_expediente", ""),
		"desc": datos_nc.get("descripcion", "").substr(0, 100) + "..."
	})
	
	# Limpiar conexiones previas
	_limpiar_conexiones_dialogo()
	
	# Configurar botones personalizados
	dialogo_confirmar.get_ok_button().text = "Leve"
	dialogo_confirmar.add_button("Mayor", false, "mayor")
	dialogo_confirmar.add_button("Crítica", false, "critica")
	dialogo_confirmar.add_button("Cancelar", true, "cancel")
	
	# Conectar nuevas señales
	dialogo_confirmar.confirmed.connect(_on_clasificacion_leve)
	dialogo_confirmar.custom_action.connect(_on_clasificacion_accion_personalizada)
	
	dialogo_confirmar.popup_centered()

func _on_BotonAprobar_pressed():
	"""Maneja la solicitud de aprobación usando diálogo."""
	print("✅ Botón Aprobar presionado")
	
	# Crear un diálogo simple de aprobación
	dialogo_confirmar.dialog_text = """
	📋 APROBAR DICTAMEN
	
	ID Expediente: {id}
	Clasificación: {clasif}
	
	¿Desea aprobar el dictamen?
	""".format({
		"id": datos_nc.get("codigo_expediente", ""),
		"clasif": datos_nc.get("clasificacion", "No clasificada")
	})
	
	# Limpiar conexiones previas
	_limpiar_conexiones_dialogo()
	
	# Configurar botones personalizados
	dialogo_confirmar.get_ok_button().text = "Aprobar"
	dialogo_confirmar.add_button("Rechazar", false, "rechazar")
	dialogo_confirmar.add_button("Revisar", false, "revisar")
	dialogo_confirmar.add_button("Cancelar", true, "cancel")
	
	# Conectar nuevas señales
	dialogo_confirmar.confirmed.connect(_on_aprobacion_confirmada)
	dialogo_confirmar.custom_action.connect(_on_aprobacion_accion_personalizada)
	
	dialogo_confirmar.popup_centered()

func _limpiar_conexiones_dialogo():
	"""Limpia todas las conexiones del diálogo para evitar conflictos."""
	# Desconectar todas las conexiones de confirmed
	if dialogo_confirmar.confirmed.is_connected(_on_clasificacion_leve):
		dialogo_confirmar.confirmed.disconnect(_on_clasificacion_leve)
	if dialogo_confirmar.confirmed.is_connected(_on_aprobacion_confirmada):
		dialogo_confirmar.confirmed.disconnect(_on_aprobacion_confirmada)
	if dialogo_confirmar.confirmed.is_connected(_on_DialogoConfirmacion_confirmed):
		dialogo_confirmar.confirmed.disconnect(_on_DialogoConfirmacion_confirmed)
	
	# Desconectar todas las conexiones de custom_action
	for conn in dialogo_confirmar.custom_action.get_connections():
		dialogo_confirmar.custom_action.disconnect(conn.callable)

func _on_clasificacion_leve():
	"""Procesa clasificación como "Leve"."""
	print("📝 Clasificando como LEVE")
	_procesar_clasificacion("Leve")

func _on_clasificacion_accion_personalizada(action: String):
	"""Procesa otras clasificaciones."""
	match action:
		"mayor":
			print("📝 Clasificando como MAYOR")
			_procesar_clasificacion("Mayor")
		"critica":
			print("📝 Clasificando como CRÍTICA")
			_procesar_clasificacion("Crítica")
		"cancel":
			print("❌ Clasificación cancelada")

func _procesar_clasificacion(clasificacion: String):
	"""Procesa la clasificación seleccionada."""
	# Determinar nuevo estado
	var nuevo_estado = "cerrada"
	if clasificacion == "Crítica":
		nuevo_estado = "pendiente_aprobacion"
	
	# Actualizar la NC en la base de datos
	var datos_actualizacion = {
		"clasificacion": clasificacion,
		"estado": nuevo_estado,
		"fecha_clasificacion": Time.get_datetime_string_from_system(),
		"usuario_clasificacion": 1  # ID del usuario actual
	}
	
	print("📝 Actualizando NC con datos: ", datos_actualizacion)
	print("📝 WHERE: id_nc = ?")
	print("📝 Parámetros: ", [id_nc_actual])
	
	# Intentar con el método update primero
	var exito = Bd.update("no_conformidades", datos_actualizacion, "id_nc = ?", [id_nc_actual])
	
	if not exito:
		print("⚠️ Método update() falló, intentando con consulta directa...")
		# Método alternativo usando consulta SQL directa
		exito = _actualizar_nc_directo(datos_actualizacion)
	
	if exito:
		print("✅ NC clasificada como: ", clasificacion)
		
		# Registrar traza
		_registrar_traza("CLASIFICACION_NC", "NC clasificada como: " + clasificacion)
		
		# Notificar si es crítica
		if clasificacion == "Crítica":
			_notificar_comite_calidad()
		
		# Recargar datos
		_cargar_nc_desde_bd()
		_actualizar_interfaz()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ NC clasificada como '{clasificacion}'".format({"clasificacion": clasificacion})
		mensaje_exito.popup_centered()
	else:
		print("❌ Error al clasificar NC")
		mensaje_error.dialog_text = "Error al clasificar la no conformidad. Verifique la base de datos."
		mensaje_error.popup_centered()

func _on_aprobacion_confirmada():
	"""Procesa aprobación del dictamen."""
	print("✅ Aprobando dictamen")
	_procesar_aprobacion("Aprobado")

func _on_aprobacion_accion_personalizada(action: String):
	"""Procesa otras acciones de aprobación."""
	match action:
		"rechazar":
			print("❌ Rechazando dictamen")
			_procesar_aprobacion("Rechazado")
		"revisar":
			print("🔍 Enviando a revisión")
			_procesar_aprobacion("En revisión")
		"cancel":
			print("❌ Aprobación cancelada")

func _procesar_aprobacion(decision: String):
	"""Procesa la decisión de aprobación."""
	var nuevo_estado = "cerrado"
	match decision:
		"Aprobado": nuevo_estado = "cerrado"
		"Rechazado": nuevo_estado = "rechazado"
		"En revisión": nuevo_estado = "en_revision"
		_: nuevo_estado = "pendiente_aprobacion"
	
	# Actualizar la NC en la base de datos
	var datos_actualizacion = {
		"aprobacion": decision,
		"estado": nuevo_estado,
		"fecha_aprobacion": Time.get_datetime_string_from_system(),
		"usuario_aprobacion": 1  # ID del usuario actual
	}
	
	print("📝 Actualizando aprobación con datos: ", datos_actualizacion)
	
	# Intentar con el método update primero
	var exito = Bd.update("no_conformidades", datos_actualizacion, "id_nc = ?", [id_nc_actual])
	
	if not exito:
		print("⚠️ Método update() falló, intentando con consulta directa...")
		# Método alternativo usando consulta SQL directa
		exito = _actualizar_nc_directo(datos_actualizacion)
	
	if exito:
		print("✅ Dictamen: ", decision)
		
		# Registrar traza
		_registrar_traza("APROBACION_NC", "Dictamen: " + decision)
		
		# Notificar al responsable si fue aprobado
		if decision == "Aprobado":
			_notificar_responsable_cierre()
		
		# Recargar datos
		_cargar_nc_desde_bd()
		_actualizar_interfaz()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ Dictamen '{decision}' registrado".format({"decision": decision})
		mensaje_exito.popup_centered()
	else:
		print("❌ Error al procesar dictamen")
		mensaje_error.dialog_text = "Error al procesar el dictamen"
		mensaje_error.popup_centered()

func _actualizar_nc_directo(datos_actualizacion: Dictionary) -> bool:
	"""Método alternativo para actualizar la NC usando SQL directo."""
	print("🔧 Usando método de actualización directa...")
	
	# Construir la consulta UPDATE
	var sets = []
	var valores = []
	
	for key in datos_actualizacion.keys():
		sets.append("{key} = ?".format({"key": key}))
		valores.append(datos_actualizacion[key])
	
	# Agregar el ID al final para el WHERE
	valores.append(id_nc_actual)
	
	var sql = "UPDATE no_conformidades SET {sets} WHERE id_nc = ?".format({
		"sets": ", ".join(sets)
	})
	
	print("📝 SQL: ", sql)
	print("📝 Valores: ", valores)
	
	# Ejecutar la consulta
	var resultado = Bd.select_query(sql, valores)
	print("📝 Resultado de consulta directa: ", resultado)
	
	# Si la consulta no devuelve error, consideramos éxito
	return resultado != null

func _notificar_comite_calidad():
	"""Notifica al comité de calidad sobre una NC crítica."""
	print("📢 Notificando al comité de calidad sobre NC crítica")
	
	# Registrar notificación en la base de datos
	var datos_traza = {
		"id_nc": id_nc_actual,
		"usuario_id": 1,
		"accion": "NOTIFICACION_COMITE",
		"detalles": "NC crítica requiere revisión del comité de calidad",
		"ip_address": "127.0.0.1"
	}
	
	var id_traza = Bd.insert("trazas_nc", datos_traza)
	if id_traza > 0:
		print("✅ Notificación registrada con ID: ", id_traza)

func _notificar_responsable_cierre():
	"""Notifica al responsable sobre el cierre del expediente."""
	print("📧 Notificando al responsable sobre cierre de expediente")
	
	# Registrar notificación en la base de datos
	var datos_traza = {
		"id_nc": id_nc_actual,
		"usuario_id": 1,
		"accion": "NOTIFICACION_CIERRE",
		"detalles": "Expediente cerrado y notificado al responsable",
		"ip_address": "127.0.0.1"
	}
	
	var id_traza = Bd.insert("trazas_nc", datos_traza)
	if id_traza > 0:
		print("✅ Notificación registrada con ID: ", id_traza)

# ============================================================
# FUNCIONES ORIGINALES (MODIFICADAS MÍNIMAMENTE)
# ============================================================

func _on_BotonCargarDoc_pressed():
	print("--- Botón Cargar presionado ---")
	dialogo_cargar.popup(Rect2i(100, 100, 800, 500))

func _on_BotonCerrarExp_pressed():
	print("📦 Botón Cerrar expediente presionado")
	
	dialogo_confirmar.dialog_text = """
	¿Está seguro que desea cerrar definitivamente este expediente?
	
	📋 ID: {id}
	📄 Estado: {estado}
	
	⚠️ Esta acción no se puede deshacer.
	""".format({
		"id": datos_nc.get("codigo_expediente", ""),
		"estado": datos_nc.get("estado", "")
	})
	
	# Limpiar conexiones previas
	_limpiar_conexiones_dialogo()
	
	# Restaurar conexión original para cierre
	dialogo_confirmar.confirmed.connect(_on_DialogoConfirmacion_confirmed)
	
	dialogo_confirmar.popup_centered()

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
	var tamanio_bytes = _obtener_tamanio_archivo(path)
	
	# Determinar tipo de archivo
	var tipo_archivo = extension
	
	# Guardar en la base de datos
	var datos_documento = {
		"id_nc": id_nc_actual,
		"nombre_archivo": nombre_archivo,
		"ruta_archivo": path,
		"tipo_archivo": tipo_archivo,
		"tamanio_bytes": tamanio_bytes,
		"usuario_carga": 1,  # ID del usuario actual
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
		
		# Registrar traza de auditoría
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

func _on_DialogoConfirmacion_confirmed():
	print("🚪 Cerrando expediente en BD...")
	
	var datos_actualizacion = {
		"expediente_cerrado": 1,
		"fecha_cierre": Time.get_datetime_string_from_system(),
		"usuario_cierre": 1,
		"estado": "expediente_cerrado"
	}
	
	print("📝 Cerrando expediente con datos: ", datos_actualizacion)
	
	# Intentar con el método update primero
	var exito = Bd.update("no_conformidades", datos_actualizacion, "id_nc = ?", [id_nc_actual])
	
	if not exito:
		print("⚠️ Método update() falló, intentando con consulta directa...")
		# Método alternativo usando consulta SQL directa
		exito = _actualizar_nc_directo(datos_actualizacion)
	
	if exito:
		print("✅ Expediente cerrado en BD")
		
		# Actualizar datos locales
		datos_nc["estado"] = "expediente_cerrado"
		datos_nc["expediente_cerrado"] = 1
		
		# Actualizar interfaz
		_actualizar_interfaz()
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✅ Expediente cerrado exitosamente"
		mensaje_exito.popup_centered()
		
		# Registrar traza de auditoría
		_registrar_traza("CIERRE_EXPEDIENTE", "Expediente cerrado: " + datos_nc.get("codigo_expediente", ""))
	else:
		print("❌ Error al cerrar expediente en BD")
		mensaje_error.dialog_text = "Error al cerrar el expediente en la base de datos"
		mensaje_error.popup_centered()

func _registrar_traza(accion: String, detalles: String):
	if not Bd.table_exists("trazas_nc"):
		print("⚠️ Tabla 'trazas_nc' no existe, no se puede registrar traza")
		return
	
	var datos_traza = {
		"id_nc": id_nc_actual,
		"usuario_id": 1,
		"accion": accion,
		"detalles": detalles,
		"ip_address": "127.0.0.1"
	}
	
	var id_traza = Bd.insert("trazas_nc", datos_traza)
	if id_traza > 0:
		print("✅ Traza registrada con ID: ", id_traza)

# ============================================================
# FUNCIONES DE UTILIDAD
# ============================================================

func _log(mensaje: String):
	"""Función de logging para depuración."""
	print("[ProcesarExpediente] " + mensaje)

func _copiar_archivo_a_documentos(origen: String, nombre_archivo: String, id_documento: int) -> bool:
	"""Copia un archivo a la carpeta de documentos del sistema."""
	var _carpeta_docs = "user://documentos_nc/"
	
	# Crear directorio si no existe
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("documentos_nc"):
		var error = dir.make_dir("documentos_nc")
		if error != OK:
			print("❌ Error al crear carpeta documentos_nc: ", error)
			return false
	
	# Generar nombre único para evitar colisiones
	var timestamp = Time.get_unix_time_from_system()
	var nombre_unico = "{id_nc}_{id_doc}_{timestamp}_{nombre}".format({
		"id_nc": id_nc_actual,
		"id_doc": id_documento,
		"timestamp": timestamp,
		"nombre": nombre_archivo
	})
	
	var destino = _carpeta_docs + nombre_unico
	
	# Copiar archivo
	if DirAccess.copy_absolute(origen, destino) == OK:
		print("✅ Archivo copiado a: ", destino)
		
		# Actualizar ruta en la base de datos
		Bd.update("documentos_nc", {"ruta_archivo": destino}, "id = ?", [id_documento])
		return true
	else:
		print("⚠️ No se pudo copiar archivo, usando ruta original")
		return false
