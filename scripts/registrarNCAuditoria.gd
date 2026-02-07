extends Control

class_name RegistrarNCAuditoriaForm

# Variables del formulario
@onready var codigo_nc_label = $ContentContainer/FormContainer/CodigoNCLabel
@onready var tipo_nc_dropdown = $ContentContainer/FormContainer/GridContainer/TipoNCDropdown
@onready var descripcion_text = $ContentContainer/FormContainer/DescripcionTextEdit
@onready var auditoria_dropdown = $ContentContainer/FormContainer/GridContainer/AuditoriaDropdown
@onready var severidad_dropdown = $ContentContainer/FormContainer/GridContainer/SeveridadDropdown
@onready var registrar_button = $ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar
@onready var status_label = $StatusLabel
@onready var notificacion_panel = $NotificacionPanel
@onready var btn_regresar = $HeaderPanel/HeaderHBox/BtnRegresar

# Diálogos
@onready var mensaje_exito = $MensajeExito
@onready var mensaje_error = $MensajeError
@onready var validacion_campos = $ValidacionCampos

# Referencias globales
var bd: BD
var usuario_actual_id: int = 0
var usuario_actual_nombre: String = ""
var sucursal_actual: String = "Central"

# Prefijos para codificación según tipo
var prefijos_codigo = {
	"INTERNA": "NC-AUD-INT",
	"EXTERNA": "NC-AUD-EXT", 
	"PROVEEDOR": "NC-AUD-PRV"
}

var contador_nc = 0
var auditor_autenticado = false

func _ready():
	print("=== REGISTRAR NC AUDITORÍA - INICIO ===")
	
	# Llamar a la inicialización asíncrona
	call_deferred("_iniciar_sistema_async")

func _iniciar_sistema_async():
	"""Inicializa el sistema de manera asíncrona"""
	print("🔧 Iniciando sistema de forma asíncrona...")
	
	# Inicialización robusta sin dependencias
	_inicializar_sistema()
	
	if bd == null:
		mostrar_error_fatal("Base de datos no disponible")
		registrar_button.disabled = true
		return
	
	# Configurar usuario por defecto
	usuario_actual_id = 1
	usuario_actual_nombre = "Auditor Sistema"
	sucursal_actual = "Central"
	auditor_autenticado = true
	
	print("✅ Usuario: ", usuario_actual_nombre)
	print("✅ Sucursal: ", sucursal_actual)
	
	# Configurar interfaz
	setup_ui()
	
	# Obtener contador actual desde BD
	_obtener_contador_actual()
	
	print("✅ Sistema inicializado correctamente")

func _inicializar_sistema():
	"""Inicializa el sistema de manera robusta"""
	print("🔧 Inicializando sistema...")
	
	# 1. Inicializar BD
	bd = _obtener_instancia_bd()
	
	# 2. Verificar que BD esté operativa
	if bd and bd.has_method("probar_conexion_bd"):
		if not bd.probar_conexion_bd():
			print("❌ BD no responde")
			bd = null
		else:
			print("✅ BD operativa")

func _obtener_instancia_bd():
	"""Obtiene o crea una instancia de BD - VERSIÓN SÍNCRONA"""
	# Buscar BD en el árbol
	var bd_en_arbol = get_node("/root/BD")
	if bd_en_arbol and bd_en_arbol is BD:
		print("✅ BD encontrada en árbol")
		return bd_en_arbol
	
	# Buscar por tipo
	for nodo in get_tree().root.get_children():
		if nodo is BD:
			print("✅ BD encontrada como hijo de root")
			return nodo
	
	# Crear nueva instancia
	print("🔧 Creando nueva instancia de BD...")
	var BDClass = load("res://scripts/BD.gd")
	if BDClass:
		var nueva_bd = BDClass.new()
		nueva_bd.name = "BD"
		
		# Añadir al árbol y inicializar
		get_tree().root.add_child(nueva_bd)
		
		# Inicializar si tiene método _ready
		if nueva_bd.has_method("_ready"):
			# Llamar directamente sin await
			nueva_bd._ready()
		
		print("✅ Nueva instancia de BD creada")
		return nueva_bd
	
	print("❌ No se pudo cargar BD.gd")
	return null

func mostrar_error_fatal(mensaje: String):
	"""Muestra un error fatal y deshabilita la interfaz."""
	mensaje_error.dialog_text = mensaje
	mensaje_error.popup_centered()
	registrar_button.disabled = true
	btn_regresar.disabled = false

func setup_ui():
	# Configurar opciones de tipo de NC
	tipo_nc_dropdown.clear()
	tipo_nc_dropdown.add_item("INTERNA", 0)
	tipo_nc_dropdown.add_item("EXTERNA", 1)
	tipo_nc_dropdown.add_item("PROVEEDOR", 2)
	
	# Configurar opciones de auditoría
	auditoria_dropdown.clear()
	auditoria_dropdown.add_item("Auditoría Interna - Procesos 2024", 0)
	auditoria_dropdown.add_item("Auditoría Externa - Certificación ISO", 1)
	auditoria_dropdown.add_item("Auditoría Proveedor - Logística", 2)
	auditoria_dropdown.add_item("Auditoría Cliente - Satisfacción", 3)
	auditoria_dropdown.add_item("Auditoría de Seguridad", 4)
	
	# Configurar severidad
	severidad_dropdown.clear()
	severidad_dropdown.add_item("Crítica", 0)
	severidad_dropdown.add_item("Mayor", 1)
	severidad_dropdown.add_item("Menor", 2)
	severidad_dropdown.add_item("Observación", 3)
	
	# Configurar tooltips
	registrar_button.tooltip_text = "Registrar No Conformidad en la base de datos"
	tipo_nc_dropdown.tooltip_text = "Seleccione el tipo de No Conformidad"
	auditoria_dropdown.tooltip_text = "Seleccione la auditoría relacionada"
	severidad_dropdown.tooltip_text = "Seleccione la severidad del hallazgo"
	descripcion_text.tooltip_text = "Describa detalladamente la No Conformidad"
	
	# Conectar señales
	registrar_button.connect("pressed", Callable(self, "_on_registrar_pressed"))
	btn_regresar.connect("pressed", Callable(self, "_on_regresar_pressed"))
	tipo_nc_dropdown.connect("item_selected", Callable(self, "_on_tipo_nc_changed"))
	auditoria_dropdown.connect("item_selected", Callable(self, "_on_auditoria_changed"))
	
	# Generar código inicial
	_generar_codigo_nc()
	
	# Actualizar estado del botón
	registrar_button.disabled = false

func _obtener_contador_actual():
	"""Obtiene el contador actual de NC desde la base de datos"""
	if bd == null:
		contador_nc = 1
		return
	
	var total_nc = bd.count("no_conformidades")
	if total_nc > 0:
		# Intentar obtener el último código para continuar la numeración
		var ultima_nc = bd.select_query("SELECT codigo_expediente FROM no_conformidades ORDER BY id_nc DESC LIMIT 1")
		if ultima_nc and ultima_nc.size() > 0:
			var ultimo_codigo = ultima_nc[0].get("codigo_expediente", "")
			if ultimo_codigo != "":
				# Extraer número del código
				var regex = RegEx.new()
				if regex.compile("-(\\d+)-") == OK:
					var resultado = regex.search(ultimo_codigo)
					if resultado:
						contador_nc = int(resultado.get_string(1))
						print("✅ Contador NC inicializado desde BD: ", contador_nc)
						return
		
		contador_nc = total_nc
		print("✅ Contador NC inicializado desde count: ", contador_nc)
	else:
		contador_nc = 0
		print("✅ Contador NC inicializado en 0")

func _generar_codigo_nc():
	"""Genera un código único para la NC"""
	contador_nc += 1
	var tipo_texto = tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected)
	var prefijo = prefijos_codigo.get(tipo_texto, "NC-AUD-UNK")
	
	# Obtener fecha actual en formato YYYYMMDD
	var fecha_actual = Time.get_date_string_from_system()
	var fecha_formateada = fecha_actual.replace("-", "")
	
	# Generar código con prefijo, número secuencial y fecha
	var codigo = "%s-%04d-%s" % [prefijo, contador_nc, fecha_formateada]
	codigo_nc_label.text = "Código NC: " + codigo
	print("🔢 Código generado: ", codigo)
	return codigo

func _on_tipo_nc_changed(_index):
	print("📝 Tipo de NC cambiado")
	_generar_codigo_nc()

func _on_auditoria_changed(index):
	print("📝 Auditoría cambiada")
	# Actualizar tipo según auditoría seleccionada (opcional)
	match index:
		0: # Interna
			tipo_nc_dropdown.select(0)
		1: # Externa
			tipo_nc_dropdown.select(1)
		2: # Proveedor
			tipo_nc_dropdown.select(2)
		_:
			tipo_nc_dropdown.select(0)
	
	_generar_codigo_nc()

func _on_regresar_pressed():
	"""Regresa al menú principal"""
	print("🏠 Regresando al menú principal...")
	
	# Intentar registrar auditoría (pero no bloquear si falla)
	if bd and bd.has_method("registrar_auditoria"):
		_registrar_auditoria_sistema("SALIR_FORMULARIO", "Regresó al menú principal desde RegistrarNCAuditoriaForm")
	
	# Cambiar escena
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_registrar_pressed():
	"""Registra una nueva No Conformidad en la base de datos"""
	print("📝 Iniciando registro de NC...")
	
	# Validación mejorada
	if not _validar_formulario_completo():
		return
	
	# Deshabilitar botón para evitar doble clic
	registrar_button.disabled = true
	registrar_button.text = "Registrando..."
	
	# Obtener datos
	var codigo = codigo_nc_label.text.replace("Código NC: ", "")
	var tipo = tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected)
	var descripcion = descripcion_text.text.strip_edges()
	var auditoria = auditoria_dropdown.get_item_text(auditoria_dropdown.selected)
	var severidad = severidad_dropdown.get_item_text(severidad_dropdown.selected)
	
	print("📊 Datos del formulario:")
	print("  - Código:", codigo)
	print("  - Tipo:", tipo)
	print("  - Descripción:", descripcion.substr(0, 50) + "..." if descripcion.length() > 50 else descripcion)
	print("  - Auditoría:", auditoria)
	print("  - Severidad:", severidad)
	
	# Mapear severidad
	var prioridad = _mapear_severidad_a_prioridad(severidad)
	
	# Registrar - Versión síncrona
	var resultado = registrar_no_conformidad_bd(codigo, tipo, descripcion, auditoria, prioridad)
	
	if resultado > 0:
		_mostrar_exito_registro(codigo, tipo)
		
		# Limpiar después de éxito
		await get_tree().create_timer(2.0).timeout
		_limpiar_formulario()
		_generar_codigo_nc()
	else:
		_mostrar_error_registro()
	
	# Rehabilitar botón
	registrar_button.disabled = false
	registrar_button.text = "Registrar NC"

func _validar_formulario_completo() -> bool:
	"""Valida todos los campos del formulario"""
	print("🔍 Validando formulario completo...")
	
	# Lista de errores
	var errores = []
	
	# Validar descripción
	var descripcion_limpia = descripcion_text.text.strip_edges()
	
	if descripcion_limpia.is_empty():
		errores.append("La descripción es obligatoria")
	elif descripcion_limpia.strip_edges(true, true).is_empty():
		errores.append("La descripción no puede contener solo espacios")
	elif descripcion_limpia.length() < 10:
		errores.append("La descripción debe tener al menos 10 caracteres")
	elif descripcion_limpia.length() > 5000:
		errores.append("La descripción es demasiado larga (máximo 5000 caracteres)")
	
	# Validar selecciones
	if tipo_nc_dropdown.selected < 0:
		errores.append("Debe seleccionar un tipo de NC")
	
	if auditoria_dropdown.selected < 0:
		errores.append("Debe seleccionar una auditoría")
	
	if severidad_dropdown.selected < 0:
		errores.append("Debe seleccionar una severidad")
	
	# Mostrar errores si hay
	if errores.size() > 0:
		print("❌ Errores de validación:", errores)
		
		# Construir mensaje
		var mensaje = "Por favor, corrija los siguientes errores:\n\n"
		for error in errores:
			mensaje += "• " + error + "\n"
		
		# Mostrar diálogo
		validacion_campos.dialog_text = mensaje
		validacion_campos.popup_centered()
		mostrar_error("Hay errores en el formulario")
		
		return false
	
	print("✅ Validación exitosa")
	return true

func _mapear_severidad_a_prioridad(severidad: String) -> int:
	"""Convierte la severidad textual a prioridad numérica"""
	match severidad:
		"Crítica":
			return 1  # Alta
		"Mayor":
			return 2  # Media
		"Menor", "Observación":
			return 3  # Baja
		_:
			return 3  # Baja por defecto

func registrar_no_conformidad_bd(codigo: String, tipo: String, descripcion: String, auditoria: String, prioridad: int) -> int:
	"""
	Registra la NC en la base de datos - VERSIÓN COMPLETAMENTE SÍNCRONA.
	"""
	if bd == null:
		print("❌ BD no disponible para registrar")
		return -1
	
	# Preparar descripción completa
	var descripcion_completa = descripcion
	descripcion_completa += "\n\n--- DATOS DE AUDITORÍA ---"
	descripcion_completa += "\nTipo de Auditoría: " + tipo
	descripcion_completa += "\nAuditoría Específica: " + auditoria
	descripcion_completa += "\nRegistrado por: " + usuario_actual_nombre
	descripcion_completa += "\nSucursal: " + sucursal_actual
	descripcion_completa += "\nSeveridad: " + severidad_dropdown.get_item_text(severidad_dropdown.selected)
	
	# Preparar datos
	var datos_nc = {
		"codigo_expediente": codigo,
		"tipo_nc": "Auditoría",
		"estado": "pendiente",
		"descripcion": descripcion_completa,
		"fecha_ocurrencia": Time.get_date_string_from_system(),
		"sucursal": sucursal_actual,
		"producto_servicio": "Auditoría de Calidad",
		"responsable_id": usuario_actual_id,
		"prioridad": prioridad,
		"creado_por": usuario_actual_id
	}
	
	print("📝 Intentando insertar NC...")
	
	# Intentar insertar - Versión síncrona (SIN TIMERS, SIN AWAIT)
	var nc_id = -1
	for intento in range(3):  # Reintentar 3 veces
		print("  Intento", intento + 1, "...")
		nc_id = bd.insert("no_conformidades", datos_nc)
		
		if nc_id > 0:
			print("✅ NC insertada con ID:", nc_id)
			break
		else:
			print("⚠️ Intento", intento + 1, "fallido")
			# NO usar await, simplemente continuar con el siguiente intento
	
	if nc_id > 0:
		# Intentar registrar traza (pero no fallar si no puede)
		_registrar_traza_nc(nc_id, codigo)
		
		# Intentar registrar en auditoría
		_registrar_auditoria_sistema("REGISTRAR_NC", "NC registrada: " + codigo)
	
	return nc_id

func _registrar_traza_nc(nc_id: int, codigo: String):
	"""Intenta registrar traza de NC (no crítico)"""
	if bd and bd.has_method("table_exists") and bd.table_exists("trazas_nc"):
		var traza_data = {
			"id_nc": nc_id,
			"usuario_id": usuario_actual_id,
			"accion": "CREACION",
			"detalles": "NC creada desde formulario de auditoría: " + codigo,
			"ip_address": "SISTEMA"
		}
		
		if bd.insert("trazas_nc", traza_data) > 0:
			print("✅ Traza registrada")
		else:
			print("⚠️ No se pudo registrar traza")

func _registrar_auditoria_sistema(accion: String, detalles: String):
	"""Intenta registrar auditoría (no crítico)"""
	if bd and bd.has_method("registrar_auditoria"):
		# Verificar que la tabla auditoria existe
		if bd.has_method("table_exists") and bd.table_exists("auditoria"):
			bd.registrar_auditoria(usuario_actual_id, accion, "RegistrarNCAuditoriaForm", detalles)
			print("✅ Auditoría registrada")
		else:
			print("⚠️ Tabla 'auditoria' no disponible para registro")
	else:
		print("⚠️ Método 'registrar_auditoria' no disponible en BD")

func notificar_partes_interesadas(codigo: String, tipo: String, severidad: String):
	"""
	Notifica a las partes interesadas sobre la nueva NC.
	"""
	# Mostrar panel de notificación
	notificacion_panel.visible = true
	notificacion_panel.get_node("MensajeLabel").text = "✅ NC registrada en BD\nCódigo: " + codigo + "\nNotificando partes interesadas..."
	
	# Aquí podrías agregar lógica para:
	# 1. Insertar en tabla de notificaciones (si existe)
	# 2. Enviar emails
	# 3. Registrar en historial
	
	# Ejemplo: Insertar en historial_usuarios si existe
	if bd and bd.table_exists("historial_usuarios"):
		var historial_data = {
			"usuario_id": usuario_actual_id,
			"tipo_evento": "NC_REGISTRADA",
			"descripcion": "Registró NC de auditoría: " + codigo,
			"detalles": "Tipo: " + tipo + " | Severidad: " + severidad
		}
		bd.insert("historial_usuarios", historial_data)
		print("✅ Historial registrado")
	
	# Ocultar después de 3 segundos
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_ocultar_notificacion)

func _ocultar_notificacion():
	"""Oculta el panel de notificación"""
	notificacion_panel.visible = false

func mostrar_exito(mensaje: String):
	"""Muestra mensaje de éxito"""
	status_label.text = "✅ " + mensaje
	status_label.modulate = Color.GREEN
	status_label.visible = true
	
	# Ocultar después de 5 segundos
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_ocultar_status)

func mostrar_error(mensaje: String):
	"""Muestra mensaje de error"""
	status_label.text = "❌ " + mensaje
	status_label.modulate = Color.RED
	status_label.visible = true
	
	# Ocultar después de 5 segundos
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_ocultar_status)

func _ocultar_status():
	"""Oculta el label de estado"""
	status_label.visible = false

func _limpiar_formulario():
	"""Limpia los campos del formulario"""
	descripcion_text.text = ""
	severidad_dropdown.select(0)
	# No limpiar tipo y auditoría para mantener coherencia
	print("🧹 Formulario limpiado")

func _mostrar_exito_registro(codigo: String, tipo: String):
	"""Muestra mensaje de éxito de registro"""
	mostrar_exito("NC registrada exitosamente")
	
	mensaje_exito.dialog_text = "✅ No Conformidad registrada exitosamente\n\nCódigo: " + codigo + "\nTipo: " + tipo
	mensaje_exito.popup_centered()
	
	# Notificar
	notificar_partes_interesadas(codigo, tipo, severidad_dropdown.get_item_text(severidad_dropdown.selected))

func _mostrar_error_registro():
	"""Muestra mensaje de error de registro"""
	mensaje_error.dialog_text = "❌ Error al registrar No Conformidad\n\nVerifique:\n1. Conexión a la base de datos\n2. Que el código no esté duplicado\n3. Que todos los campos sean válidos"
	mensaje_error.popup_centered()
	mostrar_error("No se pudo registrar en la base de datos")

# =========================
# FUNCIONES DE PRUEBA Y DIAGNÓSTICO
# =========================

func probar_conexion_bd():
	"""Prueba la conexión a la base de datos"""
	if bd == null:
		print("❌ BD no inicializada")
		return false
	
	print("🧪 Probando conexión a BD...")
	
	# Probar consulta simple
	var test_result = bd.select_query("SELECT 1 as test_value")
	if test_result != null and test_result.size() > 0:
		print("✅ Conexión a BD exitosa")
		return true
	else:
		print("❌ Error en conexión a BD")
		return false

# =========================
# FUNCIONES DE EXPORTACIÓN
# =========================

func exportar_datos_nc() -> Dictionary:
	"""Exporta los datos actuales del formulario"""
	return {
		"codigo": codigo_nc_label.text.replace("Código NC: ", ""),
		"tipo": tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected),
		"descripcion": descripcion_text.text,
		"auditoria": auditoria_dropdown.get_item_text(auditoria_dropdown.selected),
		"severidad": severidad_dropdown.get_item_text(severidad_dropdown.selected),
		"fecha_registro": Time.get_datetime_string_from_system(),
		"usuario": usuario_actual_nombre,
		"sucursal": sucursal_actual
	}

func generar_reporte_nc():
	"""Genera un reporte de la NC actual para imprimir/exportar"""
	var datos = exportar_datos_nc()
	
	var reporte = """
    ========================================
    REPORTE DE NO CONFORMIDAD - AUDITORÍA
    ========================================
    
    Código NC: {codigo}
    Fecha Registro: {fecha_registro}
    
    --- DATOS DE AUDITORÍA ---
    Tipo de NC: {tipo}
    Auditoría: {auditoria}
    Severidad: {severidad}
    
    --- DESCRIPCIÓN ---
    {descripcion}
    
    --- DATOS DEL REGISTRADOR ---
    Usuario: {usuario}
    Sucursal: {sucursal}
    
    ========================================
    FIN DEL REPORTE
    ========================================
	""".format(datos)
	
	return reporte

# =========================
# FUNCIONES DE VALIDACIÓN
# =========================

func validar_formulario() -> Dictionary:
	"""Valida todos los campos del formulario"""
	var errores = []
	
	# Validar descripción
	if descripcion_text.text.strip_edges().is_empty():
		errores.append("La descripción es obligatoria")
	elif descripcion_text.text.strip_edges().length() < 10:
		errores.append("La descripción debe tener al menos 10 caracteres")
	
	# Validar que se haya seleccionado tipo
	if tipo_nc_dropdown.selected < 0:
		errores.append("Debe seleccionar un tipo de NC")
	
	# Validar que se haya seleccionado auditoría
	if auditoria_dropdown.selected < 0:
		errores.append("Debe seleccionar una auditoría")
	
	# Validar que se haya seleccionado severidad
	if severidad_dropdown.selected < 0:
		errores.append("Debe seleccionar una severidad")
	
	return {
		"valido": errores.size() == 0,
		"errores": errores
	}

# =========================
# FUNCIONES DE UTILIDAD
# =========================

func registrar_auditoria_sistema(accion: String, detalles: String):
	"""Registra una acción en la auditoría del sistema."""
	if bd and bd.has_method("registrar_auditoria"):
		bd.registrar_auditoria(usuario_actual_id, accion, "RegistrarNCAuditoria", detalles)

func verificar_permisos_usuario() -> bool:
	"""Verifica si el usuario actual tiene permisos para registrar NC."""
	# En modo standalone, siempre permitir
	return true

func obtener_info_sistema() -> Dictionary:
	"""Obtiene información del sistema para depuración."""
	return {
		"usuario_id": usuario_actual_id,
		"usuario_nombre": usuario_actual_nombre,
		"sucursal": sucursal_actual,
		"bd_disponible": bd != null,
		"contador_nc": contador_nc,
		"auditor_autenticado": auditor_autenticado,
		"modo": "standalone"
	}

# =========================
# FUNCIONES DE NAVEGACIÓN
# =========================

func ir_a_menu_principal():
	"""Navega al menú principal."""
	print("🔄 Navegando al menú principal...")
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func recargar_formulario():
	"""Recarga el formulario con valores por defecto."""
	print("🔄 Recargando formulario...")
	_limpiar_formulario()
	_obtener_contador_actual()
	_generar_codigo_nc()
	mostrar_exito("Formulario recargado correctamente")

# =========================
# SEÑALES Y EVENTOS
# =========================

func _on_validacion_campos_confirmado():
	"""Maneja la confirmación del diálogo de validación."""
	print("✅ Usuario confirmó validación de campos")
	descripcion_text.grab_focus()

func _on_mensaje_exito_cerrado():
	"""Maneja el cierre del diálogo de éxito."""
	print("ℹ️ Diálogo de éxito cerrado")

func _on_mensaje_error_cerrado():
	"""Maneja el cierre del diálogo de error."""
	print("ℹ️ Diálogo de error cerrado")
	registrar_button.disabled = false
	registrar_button.text = "Registrar NC"

# =========================
# FUNCIONES DE DEPURACIÓN
# =========================

func _log(mensaje: String):
	"""Función de logging para depuración."""
	print("[RegistrarNCAuditoria] " + mensaje)

func _verificar_estado_sistema():
	"""Verifica el estado actual del sistema."""
	print("=== ESTADO DEL SISTEMA ===")
	var info = obtener_info_sistema()
	for key in info:
		print("  " + key + ": " + str(info[key]))
	print("=== FIN ESTADO ===")
