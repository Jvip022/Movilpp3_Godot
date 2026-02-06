extends Control

class_name RegistrarNCAuditoriaScene

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
	# Obtener referencia a Global (AutoLoad)
	if not Engine.has_singleton("Global"):
		push_error("❌ Global no está configurado como AutoLoad")
		mostrar_error("Error de configuración del sistema")
		return
	
	var global_node = Engine.get_singleton("Global")
	
	# Obtener BD desde Global
	if global_node and global_node.has_method("get_bd_reference"):
		bd = global_node.get_bd_reference()
	elif global_node and global_node.has("db"):
		bd = global_node.db
	
	if bd == null:
		push_error("❌ No se pudo obtener referencia a BD")
		# Intentar crear instancia directa como fallback
		var BDClass = load("res://BD.gd")
		if BDClass:
			bd = BDClass.new()
			if bd and bd.has_method("_ready"):
				bd.call_deferred("_ready")
	
	if bd == null:
		mostrar_error("Base de datos no disponible")
		registrar_button.disabled = true
		return
	
	# Configurar usuario actual desde Global
	if global_node and global_node.has_method("esta_autenticado") and global_node.esta_autenticado():
		usuario_actual_id = global_node.obtener_id_usuario()
		usuario_actual_nombre = global_node.usuario_actual.get("nombre_completo", global_node.usuario_actual.get("username", "Usuario"))
		sucursal_actual = global_node.usuario_actual.get("sucursal", "Central")
		auditor_autenticado = true
		print("✅ Usuario autenticado: ", usuario_actual_nombre)
	else:
		# Usuario por defecto para pruebas
		usuario_actual_id = 1
		usuario_actual_nombre = "Auditor Sistema"
		print("⚠️ Usando usuario de prueba (ID: 1)")
	
	# Configurar interfaz
	setup_ui()
	
	# Obtener contador actual desde BD
	_obtener_contador_actual()

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
	return codigo

func _on_tipo_nc_changed(_index):
	_generar_codigo_nc()

func _on_auditoria_changed(index):
	# Actualizar tipo según auditoría seleccionada (opcional)
	match index:
		0: # Interna
			tipo_nc_dropdown.select(0)
		1: # Externa
			tipo_nc_dropdown.select(1)
		2: # Proveedor
			tipo_nc_dropdown.select(2)
		_:
			tipo_nc_dropdown.select(0)  # Por defecto interna
	
	_generar_codigo_nc()

func _on_regresar_pressed():
	"""Regresa al menú principal"""
	# Registrar en auditoría si es posible
	if bd and bd.has_method("registrar_auditoria"):
		bd.registrar_auditoria(usuario_actual_id, "SALIR_FORMULARIO", 
							  "RegistrarNCAuditoriaScene", "Regresó al menú principal")
	
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_registrar_pressed():
	"""Registra una nueva No Conformidad en la base de datos"""
	if not auditor_autenticado:
		mostrar_error("Auditor no autenticado")
		return
	
	if bd == null:
		mostrar_error("Base de datos no disponible")
		return
	
	# Validar campos obligatorios
	if descripcion_text.text.strip_edges().is_empty():
		validacion_campos.popup_centered()
		mostrar_error("La descripción es obligatoria")
		return
	
	# Deshabilitar botón para evitar doble clic
	registrar_button.disabled = true
	registrar_button.text = "Registrando..."
	
	# Obtener datos del formulario
	var codigo = codigo_nc_label.text.replace("Código NC: ", "")
	var tipo = tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected)
	var descripcion = descripcion_text.text
	var auditoria = auditoria_dropdown.get_item_text(auditoria_dropdown.selected)
	var severidad = severidad_dropdown.get_item_text(severidad_dropdown.selected)
	
	# Mapear severidad a prioridad numérica
	var prioridad = _mapear_severidad_a_prioridad(severidad)
	
	# Registrar NC en base de datos
	var resultado = registrar_no_conformidad_bd(codigo, tipo, descripcion, auditoria, prioridad)
	
	if resultado > 0:  # Éxito: ID insertado
		mostrar_exito("NC registrada exitosamente (ID: " + str(resultado) + ")")
		mensaje_exito.get_node("MensajeLabel").text = "✅ No Conformidad registrada exitosamente\nCódigo: " + codigo
		mensaje_exito.popup_centered()
		
		# Registrar en auditoría
		if bd and bd.has_method("registrar_auditoria"):
			bd.registrar_auditoria(usuario_actual_id, "REGISTRAR_NC", 
								  "RegistrarNCAuditoriaScene", 
								  "NC registrada: " + codigo + " - Tipo: " + tipo)
		
		# Notificar partes interesadas
		notificar_partes_interesadas(codigo, tipo, severidad)
		
		# Limpiar formulario y generar nuevo código
		await get_tree().create_timer(1.5).timeout
		_limpiar_formulario()
		_generar_codigo_nc()
		
	else:  # Error
		mensaje_error.get_node("MensajeLabel").text = "❌ Error al registrar No Conformidad\nVerifique la conexión a la base de datos"
		mensaje_error.popup_centered()
		mostrar_error("No se pudo registrar en la base de datos")
	
	# Rehabilitar botón
	registrar_button.disabled = false
	registrar_button.text = "Registrar NC"

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
	Registra la NC en la base de datos real.
	Retorna el ID insertado o -1 si hay error.
	"""
	# Preparar descripción completa
	var descripcion_completa = descripcion
	descripcion_completa += "\n\n--- DATOS DE AUDITORÍA ---"
	descripcion_completa += "\nTipo de Auditoría: " + tipo
	descripcion_completa += "\nAuditoría Específica: " + auditoria
	descripcion_completa += "\nRegistrado por: " + usuario_actual_nombre
	descripcion_completa += "\nSucursal: " + sucursal_actual
	
	# Preparar datos para la tabla no_conformidades
	var datos_nc = {
		"codigo_expediente": codigo,
		"tipo_nc": "Auditoría",  # Usamos "Auditoría" como tipo fijo para NC de auditoría
		"estado": "pendiente",
		"descripcion": descripcion_completa,
		"fecha_ocurrencia": Time.get_date_string_from_system(),
		"sucursal": sucursal_actual,
		"producto_servicio": "Auditoría de Calidad",
		"responsable_id": usuario_actual_id,
		"prioridad": prioridad,
		"creado_por": usuario_actual_id
	}
	
	print("📝 Insertando NC en BD con datos:", datos_nc)
	
	# Insertar en base de datos
	var nc_id = bd.insert("no_conformidades", datos_nc)
	
	if nc_id > 0:
		print("✅ NC registrada en BD con ID: ", nc_id)
		
		# Insertar traza en tabla de trazas_nc si existe
		if bd and bd.table_exists("trazas_nc"):
			var traza_data = {
				"id_nc": nc_id,
				"usuario_id": usuario_actual_id,
				"accion": "CREACION",
				"detalles": "NC creada desde formulario de auditoría: " + codigo,
				"ip_address": "SISTEMA"
			}
			bd.insert("trazas_nc", traza_data)
			print("✅ Traza registrada para NC ID:", nc_id)
	
	return nc_id

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
