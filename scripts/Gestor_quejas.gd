extends Node

var bd = Bd.db
var config_manager: Node = null  # Cambiado a Node

# Señales del InterfaceManager
signal queja_registrada(datos: Dictionary)
signal configuracion_guardada(config: Dictionary)
signal cancelar_pressed()

# Referencias a nodos de la UI - ajustadas a la estructura de la escena proporcionada
var btn_registrar: Button
var btn_cancelar: Button
var btn_guardar_config: Button
var btn_back_menu: Button
var btn_registro_nav: Button
var btn_seguimiento_nav: Button
var btn_analiticas_nav: Button
var btn_configuracion_nav: Button

# Campos del formulario
var opt_tipo_caso: OptionButton
var txt_nombres: LineEdit
var txt_identificacion: LineEdit
var txt_telefono: LineEdit
var txt_email: LineEdit
var txt_asunto: LineEdit
var txt_descripcion: TextEdit
var txt_monto: LineEdit
var opt_prioridad: OptionButton

# Campos de configuración
var chk_notificaciones: CheckBox
var spin_intervalo: SpinBox

# Pestañas
var registro_tab: VBoxContainer
var seguimiento_tab: VBoxContainer
var analiticas_tab: VBoxContainer
var configuracion_tab: VBoxContainer

# Estadísticas
var lbl_total_quejas: Label
var lbl_pendientes_valor: Label

# Elementos de seguimiento
var txt_buscar: LineEdit
var opt_status_filter: OptionButton
var quejas_tree: Tree  # NUEVO: Control para mostrar la lista de quejas

# Botones de acción en seguimiento
var btn_resolver: Button
var btn_ver_detalles: Button
var btn_cerrar_caso: Button

# Variable para almacenar la queja seleccionada
var queja_seleccionada_id: int = -1

# Estadísticas de analíticas
var lbl_resueltas_valor: Label
var lbl_promedio_valor: Label

# FUNCIÓN AUXILIAR PARA MANEJAR CONSULTAS DE FORMA SEGURA
func query_safe(query: String, args: Array = []) -> Array:
	"""
    Ejecuta una consulta SQL de forma segura, manejando errores.
    Retorna siempre un Array, incluso si hay errores.
	"""
	var result = Bd.select_query(query, args)

	if not result or typeof(result) != TYPE_ARRAY:
		return []
	
	return result

func _ready():
	# Inicializar referencias a los nodos de la interfaz
	inicializar_referencias_nodos()
	
	# Configurar navegación entre pestañas
	configurar_navegacion()
	
	# Inicializar OptionButtons con valores por defecto
	inicializar_option_buttons()
	
	# Conectar señales de UI
	conectar_senales_ui()
	
	# Verificar si hay datos en la BD y cargar datos de prueba si está vacía
	var resultado = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones")
	if resultado and resultado.size() > 0:
		var total = resultado[0].get("total", 0)
		if total == 0:
			print("Base de datos vacía. Cargando datos de prueba...")
			cargar_datos_prueba_db()
	
	# Crear e inicializar ConfigManager - SOLO UNA VEZ
	if ClassDB.class_exists("ConfigManager"):
		print("ConfigManager ya existe globalmente")
		config_manager = Node.new()
		config_manager.name = "ConfigManager"
		add_child(config_manager)
	else:
		config_manager = Node.new()
		config_manager.name = "ConfigManager"
		add_child(config_manager)
		config_manager.set_script(preload("res://scripts/ConfigManager.gd"))
	
	# Cargar configuración inicial
	cargar_configuracion()
	
	# Conectar el timer
	var timer = get_node_or_null("AutoUpdateTimer")
	if timer:
		timer.timeout.connect(_on_timer_timeout)
		if config_manager and config_manager.has_method("get_intervalo_actualizacion"):
			timer.wait_time = config_manager.get_intervalo_actualizacion()
		else:
			timer.wait_time = 30.0
		print("✅ Timer configurado")
	
	# Cargar datos iniciales
	cargar_datos_iniciales()
	
	# Mostrar pestaña de registro por defecto
	mostrar_pestana("registro")
	
	# Verificar que las tablas existan
	var db_info = Bd.get_database_info()
	print("📊 Tablas en la base de datos: ", db_info["tables"])
	if "quejas_reclamaciones" in db_info["tables"]:
		print("✅ Tabla quejas_reclamaciones existe")
		# Probar una consulta simple
		var test_result = query_safe("SELECT COUNT(*) as count FROM quejas_reclamaciones")
		if test_result and test_result.size() > 0:
			print("📈 Total registros en tabla: ", test_result[0].get("count", 0))
	else:
		print("❌ Tabla quejas_reclamaciones NO existe")
		crear_tabla_quejas()

# ===== FUNCIONES DE INICIALIZACIÓN DE INTERFAZ =====

func inicializar_referencias_nodos():
	print("Inicializando referencias de nodos de interfaz...")
	
	# Botones de navegación en sidebar
	btn_registro_nav = get_node_or_null("LayoutPrincipal/MainContent/Sidebar/Navigation/BtnRegistro")
	btn_seguimiento_nav = get_node_or_null("LayoutPrincipal/MainContent/Sidebar/Navigation/BtnSeguimiento")
	btn_analiticas_nav = get_node_or_null("LayoutPrincipal/MainContent/Sidebar/Navigation/BtnAnaliticas")
	btn_configuracion_nav = get_node_or_null("LayoutPrincipal/MainContent/Sidebar/Navigation/BtnConfiguracion")
	
	# Pestañas
	registro_tab = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab")
	seguimiento_tab = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab")
	analiticas_tab = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/AnaliticasTab")
	configuracion_tab = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/ConfiguracionTab")
	
	# Botones de acción
	btn_registrar = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormActions/SubmitButton")
	btn_back_menu = get_node_or_null("LayoutPrincipal/Footer/FooterContent/BackButton")
	btn_guardar_config = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/ConfiguracionTab/ConfigActions/SaveConfigButton")
	
	# Botones de acción en seguimiento
	btn_resolver = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/QuejasList/BtnResolver")
	btn_ver_detalles = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/QuejasList/BtnVerDetalles")
	btn_cerrar_caso = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/QuejasList/BtnCerrarCaso")
	
	# Campos del formulario
	opt_tipo_caso = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/CaseTypeDropdown")
	txt_nombres = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/NameInput")
	txt_identificacion = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/IDInput")
	txt_telefono = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/PhoneInput")
	txt_email = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/EmailInput")
	txt_asunto = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/SubjectInput")
	txt_descripcion = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/DescriptionInput")
	txt_monto = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/AmountInput")
	opt_prioridad = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/RegistroTab/FormGrid/PriorityDropdown")
	
	# Campos de configuración
	chk_notificaciones = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/ConfiguracionTab/ConfigContent/NotificationsToggle")
	spin_intervalo = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/ConfiguracionTab/ConfigContent/IntervalInput")
	
	# Estadísticas en sidebar
	lbl_total_quejas = get_node_or_null("LayoutPrincipal/MainContent/Sidebar/StatsPanel/TotalQuejas/TotalQuejasContent/TotalQuejasValue")
	lbl_pendientes_valor = get_node_or_null("LayoutPrincipal/MainContent/Sidebar/StatsPanel/Pendientes/PendientesContent/PendientesValue")
	
	# Elementos de seguimiento
	txt_buscar = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/Filters/SearchInput")
	opt_status_filter = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/Filters/StatusFilter")
	quejas_tree = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/QuejasList/QuejasTree")
	
	# Estadísticas de analíticas
	lbl_resueltas_valor = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/AnaliticasTab/AnalyticsContent/StatsGrid/StatResueltas/StatResueltasContent/StatResueltasValue")
	lbl_promedio_valor = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/AnaliticasTab/AnalyticsContent/StatsGrid/StatPromedio/StatPromedioContent/StatPromedioValue")
	
	if not quejas_tree:
		print("⚠️ No se encontró el control Tree para mostrar quejas")
	
	print("✅ Referencias de interfaz inicializadas")

func crear_tabla_quejas():
	"""
	Crea la tabla de quejas si no existe.
	"""
	var create_table_sql = """
		CREATE TABLE IF NOT EXISTS quejas_reclamaciones (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			numero_caso TEXT UNIQUE,
			tipo_caso TEXT,
			tipo_reclamante TEXT,
			nombres TEXT,
			apellidos TEXT,
			identificacion TEXT,
			telefono TEXT,
			email TEXT,
			asunto TEXT,
			descripcion_detallada TEXT,
			producto_servicio TEXT,
			numero_factura TEXT,
			fecha_incidente TEXT,
			categoria TEXT,
			monto_reclamado REAL,
			tipo_compensacion TEXT,
			canal_entrada TEXT,
			recibido_por TEXT,
			prioridad TEXT,
			estado TEXT,
			fecha_limite_respuesta TEXT,
			creado_por INTEGER,
			fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
			fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	"""
	
	Bd.query(create_table_sql)
	print("✅ Tabla 'quejas_reclamaciones' creada o ya existente")

func configurar_navegacion():
	print("Configurando navegación entre pestañas...")
	
	# Conectar botones de navegación
	if btn_registro_nav:
		btn_registro_nav.pressed.connect(func(): mostrar_pestana("registro"))
	
	if btn_seguimiento_nav:
		btn_seguimiento_nav.pressed.connect(func(): mostrar_pestana("seguimiento"))
	
	if btn_analiticas_nav:
		btn_analiticas_nav.pressed.connect(func(): mostrar_pestana("analiticas"))
	
	if btn_configuracion_nav:
		btn_configuracion_nav.pressed.connect(func(): mostrar_pestana("configuracion"))
	
	print("✅ Navegación configurada")

func inicializar_option_buttons():
	print("Inicializando OptionButtons...")
	
	# Inicializar tipos de caso
	if opt_tipo_caso and opt_tipo_caso.get_item_count() == 0:
		opt_tipo_caso.add_item("Queja")
		opt_tipo_caso.add_item("Reclamo")
		opt_tipo_caso.add_item("Sugerencia")
		opt_tipo_caso.add_item("Felicitación")
		opt_tipo_caso.selected = 0
	
	# Inicializar prioridades
	if opt_prioridad and opt_prioridad.get_item_count() == 0:
		opt_prioridad.add_item("Baja")
		opt_prioridad.add_item("Media")
		opt_prioridad.add_item("Alta")
		opt_prioridad.add_item("Urgente")
		opt_prioridad.selected = 1
	
	# Inicializar filtro de estado en seguimiento
	if opt_status_filter and opt_status_filter.get_item_count() == 0:
		opt_status_filter.add_item("Todos")
		opt_status_filter.add_item("Pendiente")
		opt_status_filter.add_item("En proceso")
		opt_status_filter.add_item("Resuelto")
		opt_status_filter.add_item("Cerrado")
		opt_status_filter.selected = 0
	
	print("✅ OptionButtons inicializados")

func conectar_senales_ui():
	print("Conectando señales de UI...")
	
	# Conectar botones de acción
	if btn_registrar:
		btn_registrar.pressed.connect(_on_btn_registrar_pressed)
	
	if btn_back_menu:
		btn_back_menu.pressed.connect(_on_btn_back_menu_pressed)
	
	if btn_guardar_config:
		btn_guardar_config.pressed.connect(_on_btn_guardar_config_pressed)
	
	# Conectar botones de seguimiento
	if btn_resolver:
		btn_resolver.pressed.connect(_on_btn_resolver_pressed)
	
	if btn_ver_detalles:
		btn_ver_detalles.pressed.connect(_on_btn_ver_detalles_pressed)
	
	if btn_cerrar_caso:
		btn_cerrar_caso.pressed.connect(_on_btn_cerrar_caso_pressed)
	
	# Conectar filtros de seguimiento
	if txt_buscar:
		txt_buscar.text_changed.connect(_on_buscar_text_changed)
	
	if opt_status_filter:
		opt_status_filter.item_selected.connect(_on_status_filter_changed)
	
	# Conectar señal de selección en el Tree
	if quejas_tree:
		quejas_tree.item_selected.connect(_on_queja_seleccionada)
		quejas_tree.item_activated.connect(_on_queja_activada)  # Doble clic
	
	# Deshabilitar botones inicialmente
	if btn_resolver:
		btn_resolver.disabled = true
	if btn_cerrar_caso:
		btn_cerrar_caso.disabled = true
	if btn_ver_detalles:
		btn_ver_detalles.disabled = true
	
	print("✅ Señales de UI conectadas")

func _on_buscar_text_changed(new_text: String):
	# Actualizar lista después de un breve delay para evitar múltiples consultas
	if seguimiento_tab and seguimiento_tab.visible:
		call_deferred("actualizar_lista_quejas")

func _on_status_filter_changed(index: int):
	# Actualizar lista cuando cambia el filtro de estado
	if seguimiento_tab and seguimiento_tab.visible:
		actualizar_lista_quejas()

func mostrar_pestana(nombre_pestana: String):
	print("Mostrando pestaña: ", nombre_pestana)
	
	# Ocultar todas las pestañas
	if registro_tab:
		registro_tab.visible = false
	if seguimiento_tab:
		seguimiento_tab.visible = false
	if analiticas_tab:
		analiticas_tab.visible = false
	if configuracion_tab:
		configuracion_tab.visible = false
	
	# Mostrar la pestaña seleccionada
	match nombre_pestana:
		"registro":
			if registro_tab:
				registro_tab.visible = true
				actualizar_opciones_formulario()
		
		"seguimiento":
			if seguimiento_tab:
				seguimiento_tab.visible = true
				actualizar_lista_quejas()  # Actualizar al mostrar
				# Deseleccionar cualquier queja previa
				if quejas_tree:
					quejas_tree.deselect_all()
					queja_seleccionada_id = -1
				# Deshabilitar botones de acción
				if btn_resolver:
					btn_resolver.disabled = true
				if btn_cerrar_caso:
					btn_cerrar_caso.disabled = true
				if btn_ver_detalles:
					btn_ver_detalles.disabled = true
		
		"analiticas":
			if analiticas_tab:
				analiticas_tab.visible = true
				actualizar_estadisticas_detalladas()  # Actualizar al mostrar
				actualizar_estadisticas()
		
		"configuracion":
			if configuracion_tab:
				configuracion_tab.visible = true
				cargar_configuracion_en_ui()

# ===== FUNCIONES DEL FORMULARIO DE UI =====

func _on_btn_registrar_pressed():
	print("Botón Registrar presionado")
	
	# Obtener y validar datos del formulario
	var datos_formulario = obtener_datos_formulario()
	
	if validar_formulario(datos_formulario):
		# Normalizar valores para la base de datos
		var datos_normalizados = normalizar_valores_db(datos_formulario)
		
		print("Datos normalizados para BD:")
		for key in datos_normalizados:
			print("  %s: %s" % [key, datos_normalizados[key]])
		
		# Agregar datos adicionales de configuración
		if config_manager and config_manager.has_method("get_prioridad_por_defecto"):
			datos_normalizados["prioridad"] = datos_normalizados.get("prioridad", config_manager.get_prioridad_por_defecto())
		else:
			datos_normalizados["prioridad"] = datos_normalizados.get("prioridad", "media")
		
		datos_normalizados["fecha_limite_respuesta"] = calcular_fecha_limite_con_config()
		
		# Registrar la queja
		var id_queja = registrar_queja_completa(datos_normalizados)
		
		if id_queja != -1:
			print("Queja registrada desde UI con ID: ", id_queja)
			
			# Registrar como No Conformidad si corresponde
			if debe_registrar_como_nc(datos_normalizados):
				var id_nc = registrar_no_conformidad_desde_queja(id_queja, datos_normalizados)
				if id_nc != -1:
					print("📄 Queja registrada también como No Conformidad")
					# Actualizar la queja con referencia a la NC
					Bd.update("quejas_reclamaciones", {"no_conformidad_id": id_nc}, "id = ?", [id_queja])
			
			# Limpiar formulario después de registrar
			limpiar_formulario()
			
			# Mostrar mensaje de éxito
			mostrar_mensaje_exito("Queja registrada exitosamente")
			
			# Actualizar estadísticas INMEDIATAMENTE
			actualizar_estadisticas()
			actualizar_estadisticas_detalladas()
			
			# Si estamos en seguimiento, actualizar lista también
			if seguimiento_tab and seguimiento_tab.visible:
				actualizar_lista_quejas()
		else:
			mostrar_mensaje_error("No se pudo registrar la queja en la base de datos")
	else:
		mostrar_mensaje_error("No se pudo registrar la queja. Verifique los datos.")

func _on_btn_back_menu_pressed():
	print("Botón Volver al Menú presionado")
	emit_signal("cancelar_pressed")
	
	# Limpiar formulario antes de salir
	limpiar_formulario()
	
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_btn_guardar_config_pressed():
	print("Botón Guardar Configuración presionado")
	
	var config = obtener_datos_configuracion()
	
	# Validar configuración
	if validar_configuracion(config):
		emit_signal("configuracion_guardada", config)
		
		# Guardar en ConfigManager si tiene los métodos
		if config_manager:
			if config_manager.has_method("set_notificaciones"):
				config_manager.set_notificaciones(config.get("notificaciones", true))
			if config_manager.has_method("set_intervalo_actualizacion"):
				config_manager.set_intervalo_actualizacion(config.get("intervalo_actualizacion", 30))
		
		# Actualizar el timer
		var timer = get_node_or_null("AutoUpdateTimer")
		if timer and config_manager and config_manager.has_method("get_intervalo_actualizacion"):
			timer.wait_time = config_manager.get_intervalo_actualizacion()
		
		mostrar_mensaje_exito("Configuración guardada correctamente")
	else:
		mostrar_mensaje_error("Error en la configuración")

func obtener_datos_formulario() -> Dictionary:
	var datos = {}
	
	# Obtener tipo de caso
	if opt_tipo_caso and opt_tipo_caso.selected >= 0:
		datos["tipo_caso"] = opt_tipo_caso.get_item_text(opt_tipo_caso.selected)
	
	# Obtener datos del cliente
	if txt_nombres:
		datos["nombres"] = txt_nombres.text.strip_edges()
	
	if txt_identificacion:
		datos["identificacion"] = txt_identificacion.text.strip_edges()
	
	if txt_telefono:
		datos["telefono"] = txt_telefono.text.strip_edges()
	
	if txt_email:
		datos["email"] = txt_email.text.strip_edges()
	
	# Obtener asunto y descripción
	if txt_asunto:
		datos["asunto"] = txt_asunto.text.strip_edges()
	
	if txt_descripcion:
		datos["descripcion_detallada"] = txt_descripcion.text.strip_edges()
	
	# Obtener monto
	if txt_monto:
		var monto_texto = txt_monto.text.strip_edges()
		if monto_texto.is_valid_float():
			datos["monto_reclamado"] = float(monto_texto)
		else:
			datos["monto_reclamado"] = 0.0
	
	# Obtener prioridad
	if opt_prioridad and opt_prioridad.selected >= 0:
		datos["prioridad"] = opt_prioridad.get_item_text(opt_prioridad.selected)
	
	# Datos adicionales por defecto
	datos["tipo_reclamante"] = "cliente"
	datos["canal_entrada"] = "sistema"
	datos["recibido_por"] = "usuario"
	datos["fecha_registro"] = Time.get_datetime_string_from_system()
	datos["estado"] = "pendiente"
	
	return datos

func normalizar_valores_db(datos: Dictionary) -> Dictionary:
	var datos_normalizados = datos.duplicate(true)
	
	# Mapear tipo_caso a valores permitidos por la BD
	var mapa_tipo_caso = {
		"Queja": "queja",
		"Reclamo": "reclamacion",
		"Reclamación": "reclamacion",
		"Sugerencia": "sugerencia",
		"Felicitación": "felicitacion",
		"Felicitacion": "felicitacion"
	}
	
	if datos.has("tipo_caso"):
		var tipo_ui = datos["tipo_caso"]
		if mapa_tipo_caso.has(tipo_ui):
			datos_normalizados["tipo_caso"] = mapa_tipo_caso[tipo_ui]
		else:
			datos_normalizados["tipo_caso"] = "queja"
	
	# Convertir a minúsculas para consistencia
	var campos_a_minusculas = ["tipo_reclamante", "canal_entrada", "recibido_por", "estado", "prioridad"]
	for campo in campos_a_minusculas:
		if datos.has(campo):
			datos_normalizados[campo] = str(datos[campo]).to_lower()
	
	return datos_normalizados

func validar_formulario(datos: Dictionary) -> bool:
	# Validar campos obligatorios
	if datos.get("nombres", "").strip_edges() == "":
		mostrar_mensaje_error("El campo Nombre Completo es obligatorio")
		return false
	
	if datos.get("asunto", "").strip_edges() == "":
		mostrar_mensaje_error("El campo Asunto es obligatorio")
		return false
	
	# Validar identificación
	var identificacion = datos.get("identificacion", "").strip_edges()
	if identificacion == "":
		mostrar_mensaje_error("El campo Identificación es obligatorio")
		return false
	
	# Validar email si se proporcionó
	var email = datos.get("email", "").strip_edges()
	if email != "":
		# Expresión regular básica para validar email
		if not email.contains("@") or not email.contains("."):
			mostrar_mensaje_error("El email no es válido. Use formato: usuario@dominio.com")
			return false
	
	return true

func limpiar_formulario():
	print("Limpiando formulario...")
	
	# Restablecer OptionButtons a valores por defecto
	if opt_tipo_caso:
		opt_tipo_caso.selected = 0
	
	if opt_prioridad:
		opt_prioridad.selected = 1  # Media por defecto
	
	# Limpiar campos de texto
	var campos_texto = [txt_nombres, txt_identificacion, txt_telefono, txt_email, txt_asunto, txt_descripcion, txt_monto]
	for campo in campos_texto:
		if campo:
			campo.text = ""
	
	print("✅ Formulario limpiado correctamente")

func actualizar_opciones_formulario():
	# Esta función puede usarse para cargar opciones dinámicas en el formulario
	pass

# ===== FUNCIONES DE MANEJO DE SEÑALES =====

func _on_queja_registrada_ui(datos: Dictionary):
	# Esta función ya no es necesaria ya que el registro se maneja en _on_btn_registrar_pressed
	pass

func _on_configuracion_guardada_ui(config: Dictionary):
	# Esta función ya no es necesaria ya que la configuración se maneja en _on_btn_guardar_config_pressed
	pass

func _on_cancelar_pressed_ui():
	# Esta función ya no es necesaria ya que se maneja en _on_btn_back_menu_pressed
	pass

func _on_timer_timeout():
	# Usar configuración para determinar qué actualizar
	if config_manager and config_manager.has_method("get_notificaciones") and config_manager.get_notificaciones():
		actualizar_notificaciones()
	
	# Actualizar interfaz
	actualizar_estadisticas()
	actualizar_estadisticas_detalladas()
	
	# Si estamos en la pestaña de seguimiento, actualizar lista
	if seguimiento_tab and seguimiento_tab.visible:
		actualizar_lista_quejas()

func _on_tab_changed(tab_index):
	match tab_index:
		0:  # Registro
			pass  # No necesita actualización
		1:  # Seguimiento
			actualizar_lista_quejas()
		2:  # Analíticas
			actualizar_estadisticas_detalladas()
			actualizar_estadisticas()
		3:  # Configuración
			cargar_configuracion_en_ui()
		4:  # No Conformidades
			actualizar_lista_no_conformidades()

# ===== FUNCIONES DE GESTIÓN DE ESTADOS =====

func _on_queja_seleccionada():
	"""Maneja la selección de una queja en el Tree."""
	var selected_item = quejas_tree.get_selected()
	if selected_item:
		# Obtener el ID de la queja seleccionada (columna 0)
		queja_seleccionada_id = int(selected_item.get_text(0))
		print("Queja seleccionada ID: ", queja_seleccionada_id)
		
		# Habilitar botones según el estado actual
		actualizar_estado_botones(selected_item.get_text(4).to_lower())
		
		# Habilitar botón ver detalles
		if btn_ver_detalles:
			btn_ver_detalles.disabled = false

func actualizar_estado_botones(estado_actual: String):
	"""Habilita/deshabilita botones según el estado de la queja."""
	if btn_resolver:
		btn_resolver.disabled = (estado_actual == "resuelto" or estado_actual == "cerrado")
		if not btn_resolver.disabled:
			btn_resolver.text = "Marcar como Resuelta"
	
	if btn_cerrar_caso:
		btn_cerrar_caso.disabled = (estado_actual != "resuelto")
		if not btn_cerrar_caso.disabled:
			btn_cerrar_caso.text = "Cerrar Caso"

func _on_btn_resolver_pressed():
	"""Marca la queja seleccionada como resuelta."""
	if queja_seleccionada_id == -1:
		mostrar_mensaje_error("Seleccione una queja primero")
		return
	
	# Actualizar estado a "resuelto"
	var query = "UPDATE quejas_reclamaciones SET estado = ?, fecha_modificacion = ? WHERE id = ?"
	var result = bd.query_with_args(query, ["resuelto", Time.get_datetime_string_from_system(), queja_seleccionada_id])
	
	if result:
		mostrar_mensaje_exito("✅ Queja marcada como resuelta")
		
		# Registrar en historial
		registrar_historial_queja(queja_seleccionada_id, "queja_resuelta",
			"Queja marcada como resuelta desde la interfaz")
		
		# Actualizar interfaz
		actualizar_lista_quejas()
		actualizar_estadisticas()
		actualizar_estadisticas_detalladas()
		
		# Deseleccionar y deshabilitar botones
		if quejas_tree:
			quejas_tree.deselect_all()
		queja_seleccionada_id = -1
		
		if btn_resolver:
			btn_resolver.disabled = true
		if btn_cerrar_caso:
			btn_cerrar_caso.disabled = true
		if btn_ver_detalles:
			btn_ver_detalles.disabled = true
	else:
		mostrar_mensaje_error("❌ No se pudo actualizar la queja")

func _on_btn_cerrar_caso_pressed():
	"""Cierra completamente una queja resuelta."""
	if queja_seleccionada_id == -1:
		mostrar_mensaje_error("Seleccione una queja resuelta primero")
		return
	
	# Actualizar estado a "cerrado"
	var query = "UPDATE quejas_reclamaciones SET estado = ?, fecha_cierre = ?, fecha_modificacion = ? WHERE id = ?"
	var result = bd.query_with_args(query, ["cerrado", Time.get_datetime_string_from_system(), 
		Time.get_datetime_string_from_system(), queja_seleccionada_id])
	
	if result:
		mostrar_mensaje_exito("✅ Caso cerrado exitosamente")
		
		# Registrar en historial
		registrar_historial_queja(queja_seleccionada_id, "queja_cerrada",
			"Caso cerrado desde la interfaz")
		
		# Calcular tiempo de respuesta
		calcular_tiempo_respuesta(queja_seleccionada_id)
		
		# Actualizar interfaz
		actualizar_lista_quejas()
		actualizar_estadisticas()
		actualizar_estadisticas_detalladas()
		
		# Deseleccionar y deshabilitar botones
		if quejas_tree:
			quejas_tree.deselect_all()
		queja_seleccionada_id = -1
		
		if btn_resolver:
			btn_resolver.disabled = true
		if btn_cerrar_caso:
			btn_cerrar_caso.disabled = true
		if btn_ver_detalles:
			btn_ver_detalles.disabled = true
	else:
		mostrar_mensaje_error("❌ No se pudo cerrar el caso")

func _on_btn_ver_detalles_pressed():
	"""Muestra los detalles completos de la queja seleccionada."""
	if queja_seleccionada_id == -1:
		mostrar_mensaje_error("Seleccione una queja primero")
		return
	
	mostrar_detalles_queja(queja_seleccionada_id)

func _on_queja_activada():
	"""Maneja el doble clic en una queja (mostrar detalles)."""
	_on_queja_seleccionada()
	if queja_seleccionada_id != -1:
		_on_btn_ver_detalles_pressed()

func mostrar_detalles_queja(id_queja: int):
	"""Muestra un diálogo con los detalles completos de la queja."""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		mostrar_mensaje_error("No se pudo cargar la queja")
		return
	
	# Aquí podrías implementar un diálogo personalizado
	# Por ahora, mostrar en consola
	print("📋 DETALLES DE QUEJA #" + str(id_queja))
	print("📄 Número Caso:", queja.get("numero_caso", "N/A"))
	print("🏷️ Tipo:", queja.get("tipo_caso", "N/A").capitalize())
	print("👤 Cliente:", queja.get("nombres", "N/A"))
	print("🆔 Identificación:", queja.get("identificacion", "N/A"))
	print("📞 Teléfono:", queja.get("telefono", "N/A"))
	print("📧 Email:", queja.get("email", "N/A"))
	print("📝 Asunto:", queja.get("asunto", "N/A"))
	print("📋 Descripción:", queja.get("descripcion_detallada", "N/A"))
	print("💰 Monto:", "$" + str(queja.get("monto_reclamado", 0)))
	print("🚦 Estado:", queja.get("estado", "N/A").capitalize())
	print("⚠️ Prioridad:", queja.get("prioridad", "N/A").capitalize())
	print("📅 Fecha Registro:", queja.get("fecha_registro", "N/A"))
	print("📅 Fecha Modificación:", queja.get("fecha_modificacion", "N/A"))

	
	# Mostrar mensaje en pantalla
	mostrar_mensaje_info("📋 Detalles mostrados en consola (F8)")

# ===== FUNCIONES DE SEGUIMIENTO =====

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas...")
	
	if not quejas_tree:
		print("❌ No se encontró el control Tree para mostrar quejas")
		return
	
	# Limpiar el Tree actual
	quejas_tree.clear()
	
	# Configurar columnas
	quejas_tree.set_columns(6)
	quejas_tree.set_column_title(0, "ID")
	quejas_tree.set_column_title(1, "Número Caso")
	quejas_tree.set_column_title(2, "Asunto")
	quejas_tree.set_column_title(3, "Cliente")
	quejas_tree.set_column_title(4, "Estado")
	quejas_tree.set_column_title(5, "Prioridad")
	
	# Configurar anchos de columna
	quejas_tree.set_column_expand(0, false)  # ID no muy ancho
	quejas_tree.set_column_min_width(0, 40)
	
	quejas_tree.set_column_expand(1, false)  # Número caso
	quejas_tree.set_column_min_width(1, 80)
	
	quejas_tree.set_column_expand(2, true)   # Asunto más ancho
	quejas_tree.set_column_min_width(2, 150)
	
	quejas_tree.set_column_expand(3, true)   # Cliente
	quejas_tree.set_column_min_width(3, 120)
	
	quejas_tree.set_column_expand(4, false)  # Estado
	quejas_tree.set_column_min_width(4, 80)
	
	quejas_tree.set_column_expand(5, false)  # Prioridad
	quejas_tree.set_column_min_width(5, 70)
	
	# Construir consulta SQL con filtros
	var query = "SELECT id, numero_caso, asunto, nombres, estado, prioridad FROM quejas_reclamaciones"
	var args = []
	
	# Aplicar filtro de estado
	if opt_status_filter and opt_status_filter.selected > 0:
		var estado_filtro = opt_status_filter.get_item_text(opt_status_filter.selected).to_lower()
		if estado_filtro != "todos":
			if "WHERE" in query:
				query += " AND estado = ?"
			else:
				query += " WHERE estado = ?"
			args.append(estado_filtro)
	
	# Aplicar filtro de búsqueda si existe
	var texto_buscar = ""
	if txt_buscar:
		texto_buscar = txt_buscar.text.strip_edges()
	
	if texto_buscar != "":
		if "WHERE" in query:
			query += " AND (numero_caso LIKE ? OR asunto LIKE ? OR nombres LIKE ? OR identificacion LIKE ?)"
		else:
			query += " WHERE (numero_caso LIKE ? OR asunto LIKE ? OR nombres LIKE ? OR identificacion LIKE ?)"
		
		var like_term = "%" + texto_buscar + "%"
		args.append(like_term)
		args.append(like_term)
		args.append(like_term)
		args.append(like_term)
	
	# Ordenar por fecha de registro descendente (las más recientes primero)
	query += " ORDER BY fecha_registro DESC"
	
	# Ejecutar consulta
	var quejas = query_safe(query, args)
	
	# Crear el nodo raíz
	var root = quejas_tree.create_item()
	
	# Llenar el Tree con los datos
	for queja in quejas:
		var item = quejas_tree.create_item(root)
		item.set_text(0, str(queja["id"]))
		item.set_text(1, queja.get("numero_caso", "N/A"))
		item.set_text(2, queja.get("asunto", "Sin asunto"))
		item.set_text(3, queja.get("nombres", "Sin nombre"))
		item.set_text(4, queja.get("estado", "desconocido").capitalize())
		item.set_text(5, queja.get("prioridad", "media").capitalize())
		
		# Cambiar color según estado
		var estado = queja.get("estado", "").to_lower()
		match estado:
			"pendiente":
				item.set_custom_color(4, Color(1, 0.5, 0))  # Naranja
			"en proceso":
				item.set_custom_color(4, Color(0, 0.5, 1))  # Azul
			"resuelto":
				item.set_custom_color(4, Color(0, 0.8, 0))  # Verde
			"cerrado":
				item.set_custom_color(4, Color(0.5, 0.5, 0.5))  # Gris
		
		# Cambiar color según prioridad
		var prioridad = queja.get("prioridad", "").to_lower()
		match prioridad:
			"urgente":
				item.set_custom_color(5, Color(1, 0, 0))  # Rojo
				item.set_text(5, "URGENTE")
			"alta":
				item.set_custom_color(5, Color(1, 0.5, 0))  # Naranja
			"media":
				item.set_custom_color(5, Color(1, 1, 0))  # Amarillo
			"baja":
				item.set_custom_color(5, Color(0, 1, 0))  # Verde
	
	print("📋 Lista actualizada: " + str(quejas.size()) + " quejas encontradas")
	
	# Deseleccionar cualquier elemento previo
	quejas_tree.deselect_all()
	queja_seleccionada_id = -1
	
	# Deshabilitar botones de acción
	if btn_resolver:
		btn_resolver.disabled = true
	if btn_cerrar_caso:
		btn_cerrar_caso.disabled = true
	if btn_ver_detalles:
		btn_ver_detalles.disabled = true
	
	# Si hay filtro en parámetro, establecerlo en el campo de búsqueda
	if filtro != "" and txt_buscar:
		txt_buscar.text = filtro

func actualizar_notificaciones():
	# Lógica para actualizar notificaciones
	print("Actualizando notificaciones...")

# ===== FUNCIONES DE ESTADÍSTICAS =====

func actualizar_estadisticas():
	print("Actualizando estadísticas...")
	
	# Obtener total de quejas
	var result_total = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones")
	
	if lbl_total_quejas:
		if result_total and result_total.size() > 0:
			var total = result_total[0].get("total", 0)
			print("📊 Total de quejas: ", total)
			lbl_total_quejas.text = str(total)
		else:
			print("⚠️ No se pudo obtener total de quejas")
			lbl_total_quejas.text = "0"
	
	# Obtener quejas pendientes
	var result_pendientes = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones WHERE estado = 'pendiente'")
	
	if lbl_pendientes_valor:
		if result_pendientes and result_pendientes.size() > 0:
			var total = result_pendientes[0].get("total", 0)
			print("📊 Quejas pendientes: ", total)
			lbl_pendientes_valor.text = str(total)
		else:
			print("⚠️ No se pudo obtener quejas pendientes")
			lbl_pendientes_valor.text = "0"
	
	mostrar_mensaje_info("Estadísticas actualizadas")

func actualizar_estadisticas_detalladas():
	print("Actualizando estadísticas detalladas...")
	
	# Obtener estadísticas de resueltas (suma de resuelto + cerrado)
	var result_resueltas = query_safe("""
		SELECT COUNT(*) as total 
		FROM quejas_reclamaciones 
		WHERE estado = 'resuelto' OR estado = 'cerrado'
	""")
	
	if lbl_resueltas_valor:
		if result_resueltas and result_resueltas.size() > 0:
			var total = result_resueltas[0].get("total", 0)
			print("📊 Quejas resueltas/cerradas: ", total)
			lbl_resueltas_valor.text = str(total)
		else:
			print("⚠️ No se pudo obtener quejas resueltas")
			lbl_resueltas_valor.text = "0"
	
	# Obtener promedio de tiempo de respuesta de casos cerrados
	if lbl_promedio_valor:
		var result_promedio = query_safe("""
			SELECT AVG(
				julianday(fecha_modificacion) - julianday(fecha_registro)
			) as promedio_dias 
			FROM quejas_reclamaciones 
			WHERE estado = 'cerrado' 
			AND fecha_registro IS NOT NULL 
			AND fecha_modificacion IS NOT NULL
		""")
		
		if result_promedio and result_promedio.size() > 0:
			var promedio = result_promedio[0].get("promedio_dias", 0)
			if promedio:
				promedio = round(promedio * 10) / 10.0  # Redondear a 1 decimal
				lbl_promedio_valor.text = str(promedio) + " días"
				print("📊 Tiempo promedio de resolución: ", promedio, " días")
			else:
				lbl_promedio_valor.text = "0 días"
		else:
			print("⚠️ No se pudo obtener promedio de respuesta")
			lbl_promedio_valor.text = "0 días"
	
	print("📊 Estadísticas detalladas actualizadas")

func actualizar_lista_no_conformidades():
	# Lógica para actualizar lista de No Conformidades
	print("Actualizando lista de No Conformidades...")

# ===== FUNCIONES DE CONFIGURACIÓN =====

func cargar_configuracion_en_ui():
	print("Cargando configuración en la UI...")
	
	# Esta función debería cargar la configuración desde el ConfigManager
	# Por ahora, establecemos valores por defecto
	
	if chk_notificaciones:
		if config_manager and config_manager.has_method("get_notificaciones"):
			chk_notificaciones.button_pressed = config_manager.get_notificaciones()
		else:
			chk_notificaciones.button_pressed = true
	
	if spin_intervalo:
		if config_manager and config_manager.has_method("get_intervalo_actualizacion"):
			spin_intervalo.value = float(config_manager.get_intervalo_actualizacion())
		else:
			spin_intervalo.value = 30.0

func obtener_datos_configuracion() -> Dictionary:
	var config = {}
	
	if chk_notificaciones:
		config["notificaciones"] = chk_notificaciones.button_pressed
	
	if spin_intervalo:
		config["intervalo_actualizacion"] = int(spin_intervalo.value)
	
	return config

func validar_configuracion(config: Dictionary) -> bool:
	# Validar intervalo mínimo
	if config.get("intervalo_actualizacion", 0) < 1:
		mostrar_mensaje_error("El intervalo debe ser al menos 1 minuto")
		return false
	
	# Validar intervalo máximo
	if config.get("intervalo_actualizacion", 0) > 120:
		mostrar_mensaje_error("El intervalo no puede exceder 120 minutos")
		return false
	
	return true

func cargar_configuracion():
	print("Cargando configuración...")
	
	# Valores por defecto
	var config_default = {
		"notificaciones": true,
		"intervalo_actualizacion": 30
	}
	
	# Aplicar a la UI
	aplicar_configuracion_ui(config_default)

func aplicar_configuracion_ui(config: Dictionary):
	if chk_notificaciones and config.has("notificaciones"):
		chk_notificaciones.button_pressed = config["notificaciones"]
	
	if spin_intervalo and config.has("intervalo_actualizacion"):
		spin_intervalo.value = float(config["intervalo_actualizacion"])

# ===== FUNCIONES AUXILIARES DE UI =====

func mostrar_mensaje_error(mensaje: String):
	print("❌ Error: ", mensaje)
	# Aquí podrías implementar un sistema de notificaciones en la UI

func mostrar_mensaje_exito(mensaje: String):
	print("✅ Éxito: ", mensaje)
	# Aquí podrías implementar un sistema de notificaciones en la UI

func mostrar_mensaje_info(mensaje: String):
	print("ℹ️ Info: ", mensaje)

# ===== FUNCIONES PARA CARGA DE DATOS DE PRUEBA EN UI =====

func cargar_datos_prueba_ui():
	print("Cargando datos de prueba para previsualización...")
	
	# Cargar algunos datos de ejemplo en el formulario
	if txt_nombres:
		txt_nombres.text = "Juan Pérez"
	
	if txt_identificacion:
		txt_identificacion.text = "1234567890"
	
	if txt_telefono:
		txt_telefono.text = "+593991234567"
	
	if txt_email:
		txt_email.text = "juan.perez@email.com"
	
	if txt_asunto:
		txt_asunto.text = "Producto defectuoso"
	
	if txt_descripcion:
		txt_descripcion.text = "El producto recibido presenta fallas en el funcionamiento desde el primer día de uso."
	
	if txt_monto:
		txt_monto.text = "150.00"
	
	# Actualizar estadísticas de prueba
	actualizar_estadisticas_prueba()

func actualizar_estadisticas_prueba():
	# Datos de prueba para estadísticas
	if lbl_total_quejas:
		lbl_total_quejas.text = "25"
	
	if lbl_pendientes_valor:
		lbl_pendientes_valor.text = "5"
	
	if lbl_resueltas_valor:
		lbl_resueltas_valor.text = "18"
	
	if lbl_promedio_valor:
		lbl_promedio_valor.text = "3.5 días"

# ===== FUNCIONES DE INICIALIZACIÓN =====

func inicializar_interfaz():
	print("Inicializando interfaz...")
	
	# Esta función ya se maneja en _ready
	pass

func cargar_datos_iniciales():
	# Cargar datos necesarios al iniciar
	print("Cargando datos iniciales del sistema...")
	actualizar_estadisticas()  # NUEVO: Cargar estadísticas al iniciar
	actualizar_estadisticas_detalladas()  # NUEVO: Cargar estadísticas detalladas

# ============================================================
# FUNCIONES DE NO CONFORMIDADES (MANTENIDAS DEL SCRIPT ORIGINAL)
# ============================================================

func debe_registrar_como_nc(datos: Dictionary) -> bool:
	"""
    Determina si una queja debe registrarse como no conformidad.
	"""
	var tipo_caso = datos.get("tipo_caso", "")
	var categoria = datos.get("categoria", "")
	var monto = float(datos.get("monto_reclamado", 0))
	
	# Criterios para registrar como NC:
	# 1. Todas las reclamaciones con monto > 0
	# 2. Quejas de categorías específicas
	# 3. Prioridad alta o urgente
	
	if tipo_caso == "reclamacion" and monto > 0:
		return true
	
	var categorias_nc = ["calidad_producto", "daños", "perdidas", "privacidad", "plazos_entrega"]
	if categoria in categorias_nc:
		return true
	
	var prioridad = calcular_prioridad(datos)
	if prioridad in ["alta", "urgente"]:
		return true
	
	# Consultar configuración del sistema si está disponible
	if config_manager and config_manager.has_method("get_registrar_todas_como_nc"):
		return config_manager.get_registrar_todas_como_nc()
	
	return false

func registrar_no_conformidad_desde_queja(id_queja: int, _datos_queja: Dictionary) -> int:
	"""
    Registra una no conformidad a partir de una queja.
    Retorna el ID de la no conformidad creada.
	"""
	# Obtener la queja completa
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		print("❌ No se pudo obtener la queja para crear NC")
		return -1
	
	# Generar código de expediente único
	var codigo_expediente = generar_codigo_expediente_nc()
	
	# Determinar el responsable (por defecto, el usuario que recibió la queja)
	var responsable_id = obtener_responsable_nc()
	
	# Crear la No Conformidad
	var nc_data = {
		"codigo_expediente": codigo_expediente,
		"tipo_nc": "Queja",
		"estado": "pendiente",
		"descripcion": "No conformidad generada desde queja #%s: %s" % [queja.get("numero_caso", ""), queja.get("asunto", "")],
		"fecha_ocurrencia": queja.get("fecha_incidente", Time.get_datetime_string_from_system().substr(0, 10)),
		"sucursal": "Central",  # Esto debería venir de la configuración
		"producto_servicio": queja.get("producto_servicio", ""),
		"cliente_id": null,  # Podríamos buscar el cliente en la tabla clientes si existe
		"responsable_id": responsable_id,
		"prioridad": prioridad_a_numero(queja.get("prioridad", "media")),
		"creado_por": queja.get("creado_por", null)
	}
	
	var id_nc = Bd.insert("no_conformidades", nc_data)
	
	if id_nc != -1:
		print("✅ No conformidad registrada desde queja ID: ", id_queja)
		print("   Código expediente: ", codigo_expediente)
		
		# Registrar en trazas
		registrar_traza_nc(id_nc, "nc_creada", 
			"No conformidad creada desde queja #%s" % queja.get("numero_caso", ""))
		
		# Notificar al responsable
		notificar_nueva_nc(id_nc, nc_data["prioridad"])
	
	return id_nc

func generar_codigo_expediente_nc() -> String:
	"""
    Genera un código único para el expediente de NC.
    Formato: EXP-YYYY-NNNNN
	"""
	var year = Time.get_datetime_string_from_system().substr(0, 4)
	
	var result = query_safe(
		"SELECT COUNT(*) as total FROM no_conformidades WHERE strftime('%Y', fecha_registro) = ?", 
		[year]
	)
	
	var numero = 1
	if result.size() > 0:
		var count = result[0].get("total", 0)
		numero = int(count) + 1
	
	return "EXP-%s-%05d" % [year, numero]

func prioridad_a_numero(prioridad: String) -> int:
	"""
    Convierte prioridad de texto a número (1-3)
	"""
	match prioridad:
		"urgente", "alta":
			return 1
		"media":
			return 2
		"baja":
			return 3
		_:
			return 2

func obtener_responsable_nc() -> int:
	"""
	Obtiene el ID del responsable para la NC.
	Por defecto, busca el usuario con rol 'supervisor_calidad'
	"""
	var result = query_safe(
        "SELECT id FROM usuarios WHERE rol LIKE '%calidad%' OR cargo LIKE '%calidad%' LIMIT 1"
	)
	
	if result.size() > 0:
		return result[0]["id"]
	
	# Si no hay responsable de calidad, usar el usuario admin
	return 1  # ID del usuario admin

func registrar_traza_nc(id_nc: int, accion: String, detalles: String = ""):
	"""
	Registra una traza para la No Conformidad.
	"""
	var traza = {
		"id_nc": id_nc,
		"usuario_id": 1,  # Por defecto, sistema
		"accion": accion,
		"detalles": detalles,
		"fecha_hora": Time.get_datetime_string_from_system(),
		"ip_address": "127.0.0.1"
	}
	
	Bd.insert("trazas_nc", traza)

func notificar_nueva_nc(id_nc: int, prioridad: int):
	"""
	Notifica sobre una nueva no conformidad.
	"""
	var nc = obtener_nc_por_id(id_nc)
	if not nc:
		return
	
	var mensaje = """
    🚨 NUEVA NO CONFORMIDAD DETECTADA
    Código: %s
    Tipo: %s
    Prioridad: %d
    Descripción: %s
	""" % [
		nc["codigo_expediente"],
		nc["tipo_nc"],
		prioridad,
		nc["descripcion"].substr(0, 100) + "..."
	]
	
	print("📢 Notificación de nueva NC: ", mensaje)
	
	# En un sistema real, aquí enviarías un email o notificación

func obtener_nc_por_id(id_nc: int) -> Dictionary:
	"""
	Obtiene una no conformidad por su ID.
	"""
	var result = query_safe("SELECT * FROM no_conformidades WHERE id_nc = ?", [id_nc])
	
	if result.size() > 0:
		return result[0]
	
	return {}

func obtener_no_conformidades_pendientes() -> Array:
	"""
	Obtiene todas las no conformidades pendientes.
	"""
	var query_str = """
    SELECT nc.*, u.nombre_completo as responsable_nombre
    FROM no_conformidades nc
    LEFT JOIN usuarios u ON nc.responsable_id = u.id
    WHERE nc.estado IN ('pendiente', 'analizado')
    ORDER BY 
        CASE nc.prioridad
            WHEN 1 THEN 1
            WHEN 2 THEN 2
            WHEN 3 THEN 3
            ELSE 4
        END,
        nc.fecha_registro DESC
	"""
	
	return query_safe(query_str)

func cerrar_no_conformidad(id_nc: int, responsable: String, datos: Dictionary):
	"""
	Cierra una no conformidad.
	"""
	var nc_data = {
		"estado": "cerrada",
		"expediente_cerrado": 1,
		"fecha_cierre": Time.get_datetime_string_from_system(),
		"usuario_cierre": 1  # Por defecto, sistema
	}
	
	Bd.update("no_conformidades", nc_data, "id_nc = ?", [id_nc])
	
	# Registrar traza
	registrar_traza_nc(id_nc, "nc_cerrada", 
		"No conformidad cerrada por %s. Resultado: %s" % [responsable, datos.get("resultado", "")])
	
	print("✅ No conformidad cerrada: ", id_nc)

# ============================================================
# FUNCIONES PRINCIPALES DE GESTIÓN DE QUEJAS (MANTENIDAS)
# ============================================================

func registrar_queja_completa(datos: Dictionary):
	# Normalizar datos antes de enviar a la BD
	var datos_normalizados = normalizar_datos_para_bd(datos)
	# Generar número de caso único
	var numero_caso = generar_numero_caso()
	
	# Validar datos obligatorios usando datos_normalizados
	if not datos_normalizados.has("nombres") or not datos_normalizados.has("asunto"):
		push_error("Faltan datos obligatorios")
		return -1
	
	# Estructura completa de la queja usando datos_normalizados
	var queja = {
		"numero_caso": numero_caso,
		"tipo_caso": datos_normalizados.get("tipo_caso", "queja"),
		"tipo_reclamante": datos_normalizados.get("tipo_reclamante", "cliente"),
		"nombres": datos_normalizados["nombres"],
		"apellidos": datos_normalizados.get("apellidos", ""),
		"identificacion": datos_normalizados.get("identificacion", ""),
		"telefono": datos_normalizados.get("telefono", ""),
		"email": datos_normalizados.get("email", ""),
		
		"asunto": datos_normalizados["asunto"],
		"descripcion_detallada": datos_normalizados.get("descripcion_detallada", ""),
		"producto_servicio": datos_normalizados.get("producto_servicio", ""),
		"numero_factura": datos_normalizados.get("numero_factura", ""),
		"fecha_incidente": datos_normalizados.get("fecha_incidente", ""),
		
		"categoria": datos_normalizados.get("categoria", "atencion_cliente"),
		"monto_reclamado": float(datos_normalizados.get("monto_reclamado", 0)),
		"tipo_compensacion": datos_normalizados.get("tipo_compensacion", "ninguna"),
		
		"canal_entrada": datos_normalizados.get("canal_entrada", "presencial"),
		"recibido_por": datos_normalizados.get("recibido_por", "sistema"),
		"prioridad": calcular_prioridad(datos_normalizados),
		"estado": "recibida",
		"fecha_limite_respuesta": datos_normalizados.get("fecha_limite_respuesta", calcular_fecha_limite()),
		
		# Usar null en lugar de string "sistema" para clave foránea
		"creado_por": null,
		"tags": JSON.stringify(datos_normalizados.get("tags", []))
	}
	
	print("📝 Insertando queja con datos:")
	print("   Número caso: ", numero_caso)
	print("   Asunto: ", queja["asunto"])
	print("   Cliente: ", queja["nombres"])
	
	# Insertar en base de datos
	var id_queja_local = Bd.insert("quejas_reclamaciones", queja)
	
	if id_queja_local == -1:
		push_error("Error al insertar la queja en la base de datos")
		# Verificar si la tabla existe
		if not Bd.table_exists("quejas_reclamaciones"):
			push_error("La tabla 'quejas_reclamaciones' no existe")
		return -1
	
	print("✅ Queja registrada con ID: ", id_queja_local)
	
	# Registrar en historial
	registrar_historial_queja(id_queja_local, "queja_registrada",
		"Queja registrada por " + queja["recibido_por"])
	
	# Notificar al equipo asignado
	notificar_nueva_queja(id_queja_local, queja["prioridad"])
	
	return id_queja_local

# FUNCIÓN ACTUALIZADA PARA USAR query_safe
func generar_numero_caso() -> String:
	var year = Time.get_datetime_string_from_system().substr(0, 4)
	
	var result = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones")
	
	var numero = 1
	if result.size() > 0:
		var count = result[0].get("total", 0)
		numero = int(count) + 1
	
	return "Q-%s-%03d" % [year, numero]

func escalar_queja(id_queja: int, motivo: String):
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	var nuevo_nivel = queja.get("nivel_escalamiento", 1) + 1
	
	# Reglas de escalamiento
	match nuevo_nivel:
		2:  # Supervisor
			var supervisor = obtener_supervisor_disponible()
			asignar_queja(id_queja, supervisor, nuevo_nivel)
			notificar_escalamiento(id_queja, supervisor, motivo)
			
		3:  # Gerencia
			var gerente = obtener_gerente_area(queja["categoria"])
			asignar_queja(id_queja, gerente, nuevo_nivel)
			notificar_escalamiento(id_queja, gerente, motivo, true)  # Urgente
			
		4:  # Legal/Área jurídica
			var legal = obtener_contacto_legal()
			asignar_queja(id_queja, legal, nuevo_nivel)
			actualizar_campo(id_queja, "requiere_legal", true)
			notificar_escalamiento(id_queja, legal, motivo, true)
	
	# Actualizar nivel
	bd.query_with_args(
		"UPDATE quejas_reclamaciones SET nivel_escalamiento = ? WHERE id = ?",
		[nuevo_nivel, id_queja]
	)
	
	registrar_historial_queja(id_queja, "escalada_nivel_" + str(nuevo_nivel), motivo)

func aprobar_compensacion(queja_id: int, datos_compensacion: Dictionary) -> int:
	# Verificar límites de aprobación
	var monto = datos_compensacion.get("monto", 0)
	var nivel_requerido = calcular_nivel_aprobacion(monto)
	
	if datos_compensacion.get("nivel_aprobacion", 1) < nivel_requerido:
		push_error("Nivel de aprobación insuficiente para monto: $" + str(monto))
		return -1
	
	# Crear registro de compensación
	var compensacion = {
		"queja_id": queja_id,
		"tipo_compensacion": datos_compensacion.get("tipo_compensacion", "devolucion_dinero"),
		"descripcion": datos_compensacion.get("descripcion", ""),
		"monto": monto,
		"moneda": datos_compensacion.get("moneda", "USD"),
		"estado": "aprobada",
		"aprobado_por": datos_compensacion.get("aprobado_por", ""),
		"fecha_aprobacion": Time.get_datetime_string_from_system(),
		"nivel_aprobacion": nivel_requerido
	}
	
	var id_compensacion_local = Bd.insert("compensaciones", compensacion)
	
	if id_compensacion_local == -1:
		push_error("Error al registrar la compensación")
		return -1
	
	# Actualizar estado de la queja
	bd.query_with_args(
		"""UPDATE quejas_reclamaciones SET
            estado = 'resuelta',
            decision = 'aceptada_total',
            compensacion_otorgada = ?,
            descripcion_compensacion = ?
		WHERE id = ?""",
		[monto, compensacion["descripcion"], queja_id]
	)
	
	# Generar comprobante
	generar_comprobante_compensacion(id_compensacion_local)
	
	return id_compensacion_local

func calcular_nivel_aprobacion(monto: float) -> int:
	if monto <= 100:
		return 1  # Operador
	elif monto <= 1000:
		return 2  # Supervisor
	elif monto <= 5000:
		return 3  # Gerente
	else:
		return 4  # Director

func calcular_prioridad(datos: Dictionary) -> String:
	# Lógica de prioridad basada en varios factores
	var prioridad = "baja"
	
	# Prioridad basada en monto reclamado
	var monto = datos.get("monto_reclamado", 0)
	if monto > 1000:
		prioridad = "urgente"
	elif monto > 500:
		prioridad = "alta"
	elif monto > 100:
		prioridad = "media"
	
	# Prioridad basada en categoría
	var categoria = datos.get("categoria", "")
	if categoria in ["daños", "perdidas", "privacidad"]:
		if prioridad != "urgente":
			prioridad = "alta"
	
	# Prioridad basada en tipo de cliente
	var tipo_reclamante = datos.get("tipo_reclamante", "")
	if tipo_reclamante == "cliente_vip":
		if prioridad in ["baja", "media"]:
			prioridad = "alta"
	
	return prioridad

# FUNCIÓN ORIGINAL - VERSIÓN SIMPLIFICADA PARA GODOT 4
func calcular_fecha_limite(dias: int = 7) -> String:
	# Calcular fecha límite de respuesta (7 días naturales por defecto)
	# En Godot 4, usar get_unix_time_from_system()
	var fecha_actual_unix = Time.get_unix_time_from_system()
	var dias_en_segundos = int(dias) * 24 * 60 * 60
	var fecha_limite_unix = fecha_actual_unix + dias_en_segundos
	
	# Convertir a fecha legible
	var fecha_limite = Time.get_datetime_dict_from_unix_time(fecha_limite_unix)
	
	return "%04d-%02d-%02d" % [fecha_limite["year"], fecha_limite["month"], fecha_limite["day"]]

# FUNCIÓN CORREGIDA: VERSIÓN SIMPLIFICADA PARA GODOT 4
func calcular_fecha_limite_con_config(dias: int = -1) -> String:
	# Intentar obtener el límite del config_manager si está disponible
	if dias == -1 and config_manager and config_manager.has_method("get_limite_tiempo_respuesta"):
		dias = int(config_manager.get_limite_tiempo_respuesta())
	elif dias == -1:
		dias = 7  # Valor por defecto
	
	# Asegurarse de que dias sea un entero
	dias = int(dias)
	
	# En Godot 4, usar get_unix_time_from_system()
	var fecha_actual_unix = Time.get_unix_time_from_system()
	var dias_en_segundos = dias * 24 * 60 * 60
	var fecha_limite_unix = fecha_actual_unix + dias_en_segundos
	
	# Convertir a fecha legible
	var fecha_limite = Time.get_datetime_dict_from_unix_time(fecha_limite_unix)
	
	return "%04d-%02d-%02d" % [fecha_limite["year"], fecha_limite["month"], fecha_limite["day"]]
	
	
func registrar_historial_queja(id_queja: int, evento: String, descripcion: String):
	"""
	Registra un evento en el historial de la queja.
	"""
	var historial = {
		"queja_id": id_queja,
		"evento": evento,
		"descripcion": descripcion,
		"fecha": Time.get_datetime_string_from_system(),
		"usuario": "sistema"
	}
	
	# Insertar en la tabla de historial
	Bd.insert("historial_quejas", historial)

func notificar_nueva_queja(id_queja: int, prioridad: String):
	"""
	Notifica sobre una nueva queja al equipo correspondiente.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	var mensaje = """
        NUEVA QUEJA REGISTRADA
        Caso: %s
        Asunto: %s
        Prioridad: %s
        Cliente: %s %s
        Monto Reclamado: $%.2f
        Fecha Límite: %s
	""" % [
		queja["numero_caso"],
		queja["asunto"],
		prioridad,
		queja["nombres"],
		queja.get("apellidos", ""),
		queja.get("monto_reclamado", 0),
		queja.get("fecha_limite_respuesta", "No establecida")
	]
	
	print("📢 Notificación de nueva queja:")
	print(mensaje)
	
	# Determinar destinatarios según prioridad
	var destinatarios = []
	match prioridad:
		"urgente", "alta":
			destinatarios = ["supervisor@empresa.com", "gerente@empresa.com"]
		_:
			destinatarios = ["operador@empresa.com"]
	
	# Enviar notificaciones
	for destinatario in destinatarios:
		enviar_notificacion_email(destinatario, "Nueva Queja - " + queja["numero_caso"], mensaje)
	
	registrar_historial_queja(id_queja, "notificacion_nueva_queja",
		"Notificación enviada al equipo - Prioridad: " + prioridad)

func validar_documentacion(id_queja: int):
	"""
	Valida la documentación adjunta a la queja.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	# Verificar documentos requeridos según el tipo de caso
	var documentos_faltantes = []
	
	# Para reclamaciones con monto > 0, se requiere factura
	if queja.get("tipo_caso") == "reclamacion" and queja.get("monto_reclamado", 0) > 0:
		if not queja.get("numero_factura"):
			documentos_faltantes.append("Factura o comprobante de pago")
	
	# Para problemas de calidad, se requiere descripción detallada
	if queja.get("categoria") == "calidad_producto":
		if not queja.get("descripcion_detallada") or len(queja.get("descripcion_detallada", "")) < 50:
			documentos_faltantes.append("Descripción detallada del problema")
	
	if documentos_faltantes.size() > 0:
		var mensaje = "Documentación faltante: " + ", ".join(documentos_faltantes)
		registrar_historial_queja(id_queja, "validacion_documentacion",
			"Documentación incompleta - " + mensaje)
		
		# Actualizar estado
		actualizar_campo(id_queja, "estado", "en_revision")
		
		# Solicitar documentación al cliente
		solicitar_documentacion_cliente(id_queja, documentos_faltantes)
	else:
		registrar_historial_queja(id_queja, "validacion_documentacion",
			"Documentación completa y válida")
		actualizar_campo(id_queja, "estado", "investigando")

func asignar_queja(id_queja: int, asignado_a: String, nivel: int):
	"""
	Asigna una queja a un responsable específico.
	"""
	# Actualizar la asignación en la base de datos
	actualizar_campo(id_queja, "asignado_a", asignado_a)
	actualizar_campo(id_queja, "nivel_escalamiento", nivel)
	
	# Determinar equipo responsable basado en el nivel
	var equipo = ""
	match nivel:
		1: equipo = "Servicio al Cliente"
		2: equipo = "Supervisión"
		3: equipo = "Gerencia"
		4: equipo = "Legal"
	
	actualizar_campo(id_queja, "equipo_responsable", equipo)
	
	# Registrar en historial
	registrar_historial_queja(id_queja, "asignacion",
		"Queja asignada a " + asignado_a + " (Nivel " + str(nivel) + ", Equipo: " + equipo + ")")
	
	# Notificar al asignado
	enviar_notificacion_email(asignado_a + "@empresa.com",
		"Nueva queja asignada - Caso " + obtener_numero_caso(id_queja),
		"Se te ha asignado una nueva queja. Por favor revisa el caso en el sistema.")

func investigar_queja(id_queja: int, datos: Dictionary) -> Dictionary:
	"""
	Realiza la investigación de una queja y registra los hallazgos.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return {"error": "Queja no encontrada"}
	
	# Registrar hechos constatados
	if datos.has("hechos_constatados"):
		actualizar_campo(id_queja, "hechos_constatados", datos["hechos_constatados"])
	
	# Registrar responsable interno
	if datos.has("responsable_interno"):
		actualizar_campo(id_queja, "responsable_interno", datos["responsable_interno"])
	
	# Registrar pruebas adjuntas
	if datos.has("pruebas"):
		var pruebas_json = JSON.stringify(datos["pruebas"])
		actualizar_campo(id_queja, "pruebas_adjuntas", pruebas_json)
	
	# Registrar testigos
	if datos.has("testigos"):
		actualizar_campo(id_queja, "testigos", datos["testigos"])
	
	# Actualizar estado
	actualizar_campo(id_queja, "estado", "negociacion")
	
	# Registrar en historial
	registrar_historial_queja(id_queja, "investigacion_completada",
		"Investigación completada. Responsable interno identificado: " +
		datos.get("responsable_interno", "No identificado"))
	
	return {
		"estado": "completado",
		"queja_id": id_queja,
		"fecha_investigacion": Time.get_datetime_string_from_system()
	}

func registrar_contacto_cliente(id_queja: int, datos: Dictionary):
	"""
	Registra un contacto con el cliente.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	# Crear registro de contacto
	var contacto = {
		"queja_id": id_queja,
		"medio_contacto": datos.get("medio_contacto", ""),
		"tipo_contacto": datos.get("tipo_contacto", ""),
		"resumen": datos.get("resumen", ""),
		"estado_animo": datos.get("estado_animo", ""),
		"acuerdos": datos.get("acuerdos", ""),
		"proxima_accion": datos.get("proxima_accion", ""),
		"fecha_proximo_contacto": datos.get("fecha_proximo_contacto", ""),
		"fecha_contacto": Time.get_datetime_string_from_system(),
		"realizado_por": datos.get("realizado_por", "sistema")
	}
	
	# Insertar en base de datos
	Bd.insert("contactos_cliente", contacto)
	
	# Actualizar fecha de respuesta al cliente
	if datos.get("tipo_contacto") == "respuesta":
		actualizar_campo(id_queja, "fecha_respuesta_cliente", contacto["fecha_contacto"])
	
	# Registrar en historial
	registrar_historial_queja(id_queja, "contacto_cliente",
		"Contacto con cliente via " + contacto["medio_contacto"] + " - " + contacto["tipo_contacto"])

func realizar_encuesta_satisfaccion(id_queja: int, datos: Dictionary):
	"""
	Registra los resultados de la encuesta de satisfacción.
	"""
	# Actualizar campos de satisfacción
	if datos.has("satisfaccion_cliente"):
		actualizar_campo(id_queja, "satisfaccion_cliente", datos["satisfaccion_cliente"])
	
	if datos.has("comentarios_finales"):
		actualizar_campo(id_queja, "comentarios_finales", datos["comentarios_finales"])
	
	# Determinar si es reincidente basado en historial
	var es_reincidente = es_cliente_reincidente(obtener_identificacion_cliente(id_queja))
	actualizar_campo(id_queja, "reincidente", es_reincidente)
	
	# Registrar en historial
	registrar_historial_queja(id_queja, "encuesta_satisfaccion",
		"Encuesta completada. Satisfacción: " + str(datos.get("satisfaccion_cliente", 0)) + "/5")

func cerrar_queja(id_queja: int, responsable: String, datos: Dictionary):
	"""
	Cierra una queja y registra las lecciones aprendidas.
	"""
	# Actualizar campos de cierre
	actualizar_campo(id_queja, "estado", "archivada")
	actualizar_campo(id_queja, "fecha_cierre", Time.get_datetime_string_from_system())
	
	if datos.has("decision"):
		actualizar_campo(id_queja, "decision", datos["decision"])
	
	# Registrar lecciones aprendidas en una tabla separada
	if datos.has("lecciones_aprendidas") or datos.has("acciones_preventivas"):
		var lecciones = {
			"queja_id": id_queja,
			"lecciones_aprendidas": datos.get("lecciones_aprendidas", ""),
			"acciones_preventivas": JSON.stringify(datos.get("acciones_preventivas", [])),
			"responsable_cierre": responsable,
			"fecha_cierre": Time.get_datetime_string_from_system()
		}
		Bd.insert("lecciones_aprendidas", lecciones)
	
	# Calcular tiempo de respuesta
	calcular_tiempo_respuesta(id_queja)
	
	# Registrar en historial
	registrar_historial_queja(id_queja, "queja_cerrada",
		"Queja cerrada por " + responsable + ". Lecciones: " + datos.get("lecciones_aprendidas", "Ninguna"))

func actualizar_analisis_tendencias(id_queja: int):
	"""
	Actualiza el análisis de tendencias con los datos de la queja cerrada.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	# Datos para análisis de tendencias
	var tendencia = {
		"categoria": queja.get("categoria", ""),
		"subcategoria": queja.get("subcategoria", ""),
		"producto_servicio": queja.get("producto_servicio", ""),
		"monto_reclamado": queja.get("monto_reclamado", 0),
		"compensacion_otorgada": queja.get("compensacion_otorgada", 0),
		"satisfaccion_cliente": queja.get("satisfaccion_cliente", 0),
		"reincidente": queja.get("reincidente", false),
		"mes": Time.get_datetime_string_from_system().substr(0, 7),
		"fecha_cierre": queja.get("fecha_cierre", "")
	}
	
	# Insertar en tabla de tendencias
	Bd.insert("tendencias_quejas", tendencia)

func obtener_queja_por_id(id_queja: int) -> Dictionary:
	"""
	Obtiene una queja por su ID.
	"""
	var query = "SELECT * FROM quejas_reclamaciones WHERE id = ?"
	var result = query_safe(query, [id_queja])
	
	if result.size() > 0:
		return result[0]
	
	return {}

func obtener_supervisor_disponible() -> String:
	"""
	Obtiene un supervisor disponible para asignar quejas.
	"""
	# En una implementación real, aquí consultarías la base de datos
	# para encontrar un supervisor con menor carga de trabajo
	var supervisores = ["supervisor_calidad", "supervisor_servicio", "supervisor_ventas"]
	
	# Simulación: seleccionar aleatoriamente
	randomize()
	var indice = randi() % supervisores.size()
	return supervisores[indice]

func obtener_gerente_area(categoria: String) -> String:
	"""
	Obtiene el gerente del área correspondiente a la categoría.
	"""
	# Mapeo de categorías a gerentes
	var gerentes_por_categoria = {
		"calidad_producto": "gerente_calidad",
		"atencion_cliente": "gerente_servicio",
		"plazos_entrega": "gerente_logistica",
		"facturacion": "gerente_finanzas",
		"garantia": "gerente_postventa",
		"daños": "gerente_logistica",
		"perdidas": "gerente_logistica",
		"publicidad_enganosa": "gerente_marketing",
		"privacidad": "gerente_sistemas"
	}
	
	return gerentes_por_categoria.get(categoria, "gerente_general")

func obtener_contacto_legal() -> String:
	"""
	Obtiene el contacto del departamento legal.
	"""
	return "departamento_legal"

func actualizar_campo(id_queja: int, campo: String, valor):
	"""
	Actualiza un campo específico de una queja.
	"""
	# Construir la consulta SQL de manera segura
	var query = "UPDATE quejas_reclamaciones SET %s = ?, fecha_modificacion = ? WHERE id = ?" % campo
	bd.query_with_args(query, [valor, Time.get_datetime_string_from_system(), id_queja])

func generar_comprobante_compensacion(id_compensacion: int):
	"""
	Genera un comprobante de compensación.
	"""
	print("🖨️ Generando comprobante de compensación #" + str(id_compensacion))

func notificar_escalamiento(id_queja: int, responsable: String, motivo: String, urgente: bool = false):
	"""
	Notifica sobre el escalamiento de una queja a diferentes niveles.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		push_warning("No se pudo obtener información de la queja para notificación")
		return
	
	var numero_caso = queja.get("numero_caso", "N/A")
	var prioridad = queja.get("prioridad", "media")
	var asignado_anterior = queja.get("asignado_a", "Sin asignar")
	
	# Construir mensaje de notificación
	var titulo = " Queja Escalada"
	if urgente:
		titulo = " ESCALAMIENTO URGENTE"
	
	var mensaje = """
        %s
        Caso: %s
        Asunto: %s
        ---
            Nivel anterior: %d
            Nivel nuevo: %d
            Responsable anterior: %s
            Nuevo responsable: %s
            Motivo: %s
            Prioridad: %s
            Fecha límite: %s
	""" % [
		titulo,
		numero_caso,
		queja.get("asunto", "Sin asunto"),
		queja.get("nivel_escalamiento", 1),
		queja.get("nivel_escalamiento", 1) + 1,
		asignado_anterior,
		responsable,
		motivo,
		prioridad,
		queja.get("fecha_limite_respuesta", "No establecida")
	]
	
	# Registrar en historial
	registrar_historial_queja(id_queja, "notificacion_escalamiento",
		"Notificación enviada a " + responsable + " - Motivo: " + motivo)
	
	# Métodos de notificación según urgencia
	if urgente:
		print("=== NOTIFICACIÓN URGENTE ===")
		print(mensaje)
		enviar_notificacion_email(responsable + "@empresa.com", "Escalamiento Urgente - Caso " + numero_caso, mensaje)
		registrar_alerta_sistema(id_queja, "escalamiento_urgente", mensaje)
		enviar_notificacion_push(responsable, "Queja escalada urgentemente - " + numero_caso)
	else:
		print("=== Notificación de Escalamiento ===")
		print(mensaje)
		enviar_notificacion_email(responsable + "@empresa.com", "Nueva queja asignada - Caso " + numero_caso, mensaje)
	
	# Actualizar el campo asignado_a en la base de datos
	actualizar_asignacion_queja(id_queja, responsable)

func actualizar_asignacion_queja(id_queja: int, nuevo_responsable: String):
	"""
	Actualiza la asignación de la queja en la base de datos.
	"""
	Bd.query_with_args(
		"UPDATE quejas_reclamaciones SET asignado_a = ? WHERE id = ?",
		[nuevo_responsable, id_queja]
	)

func enviar_notificacion_email(destinatario: String, asunto: String, mensaje: String):
	"""
	Simula el envío de notificación por email.
	"""
	print("   Email enviado a: " + destinatario)
	print("   Asunto: " + asunto)
	print("   Mensaje: " + mensaje.substr(0, 100) + "...")

func enviar_notificacion_push(destinatario: String, mensaje: String):
	"""
	Simula el envío de notificación push.
	"""
	print("📱 Notificación push a: " + destinatario)
	print("   Mensaje: " + mensaje)

func registrar_alerta_sistema(id_queja: int, tipo_alerta: String, mensaje: String):
	"""
	Registra una alerta en el sistema para seguimiento.
	"""
	var alerta = {
		"queja_id": id_queja,
		"tipo_alerta": tipo_alerta,
		"mensaje": mensaje,
		"fecha": Time.get_datetime_string_from_system(),
		"estado": "pendiente"
	}
	
	print("⚠️ Alerta registrada en sistema: " + tipo_alerta)
	Bd.insert("alertas_sistema", alerta)

# Funciones auxiliares adicionales

func obtener_numero_caso(id_queja: int) -> String:
	"""
	Obtiene el número de caso de una queja.
	"""
	var queja = obtener_queja_por_id(id_queja)
	return queja.get("numero_caso", "N/A") if queja else "N/A"

func obtener_identificacion_cliente(id_queja: int) -> String:
	"""
	Obtiene la identificación del cliente de una queja.
	"""
	var queja = obtener_queja_por_id(id_queja)
	return queja.get("identificacion", "") if queja else ""

func es_cliente_reincidente(identificacion: String) -> bool:
	"""
	Verifica si un cliente es reincidente en quejas.
	"""
	if not identificacion or identificacion == "":
		return false
	
	var result = query_safe(
		"SELECT COUNT(*) as total FROM quejas_reclamaciones WHERE identificacion = ? AND reincidente = 1",
		[identificacion]
	)
	
	if result.size() > 0:
		var count = result[0].get("total", 0)
		return int(count) > 0
	
	return false
	
func calcular_tiempo_respuesta(id_queja: int):
	"""
	Calcula el tiempo de respuesta de una queja.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	var fecha_recepcion = queja.get("fecha_recepcion")
	var fecha_cierre = queja.get("fecha_cierre")
	
	if fecha_recepcion and fecha_cierre:
		# Calcular diferencia en horas
		var tiempo_horas = 24  # Simulación - implementar cálculo real
		actualizar_campo(id_queja, "tiempo_respuesta_horas", tiempo_horas)

func solicitar_documentacion_cliente(id_queja: int, documentos: Array):
	"""
	Solicita documentación faltante al cliente.
	"""
	var queja = obtener_queja_por_id(id_queja)
	if not queja:
		return
	
	# Construir la lista de documentos
	var lista_documentos = ""
	for doc in documentos:
		lista_documentos += "- " + doc + "\n"
	
	var mensaje = """
        Estimado/a %s,
    
        Hemos recibido su queja #%s y necesitamos la siguiente documentación adicional para procesarla:
    
        %s
    
        Por favor, envíe estos documentos a la mayor brevedad.
    
        Saludos,
        Departamento de Atención al Cliente
	""" % [
		queja.get("nombres", "Cliente"),
		queja.get("numero_caso", "N/A"),
		lista_documentos
	]
	
	# Enviar solicitud por email
	enviar_notificacion_email(queja.get("email", ""),
		"Solicitud de documentación - Caso " + queja.get("numero_caso", ""),
		mensaje)
	
	registrar_historial_queja(id_queja, "solicitud_documentacion",
		"Solicitud de documentación enviada al cliente")
		
func test_insercion_simple():
	var test_data = {
		"nombres": "Test Cliente",
		"asunto": "Test de inserción",
		"descripcion_detallada": "Prueba de funcionamiento",
		"prioridad": "media",
		"estado": "recibida"
	}
	
	var id = Bd.insert("quejas_reclamaciones", test_data)
	print("Test inserción - ID: ", id)

func normalizar_datos_para_bd(datos: Dictionary) -> Dictionary:
	var datos_normalizados = datos.duplicate(true)
	
	# Asegurar que todos los campos de texto estén en el formato correcto
	if datos_normalizados.has("tipo_caso"):
		var tipo_caso = str(datos_normalizados["tipo_caso"])
		# Convertir a minúsculas y eliminar acentos
		tipo_caso = tipo_caso.to_lower()
		tipo_caso = tipo_caso.replace("ó", "o").replace("á", "a").replace("é", "e").replace("í", "i").replace("ú", "u")
		datos_normalizados["tipo_caso"] = tipo_caso
	
	# Convertir otros campos a minúsculas si es necesario
	var campos_a_minusculas = ["tipo_reclamante", "canal_entrada", "recibido_por", "estado", "prioridad"]
	for campo in campos_a_minusculas:
		if datos_normalizados.has(campo):
			var valor = str(datos_normalizados[campo]).strip_edges()
			if valor == "":
				# Asignar valor por defecto según el campo
				match campo:
					"canal_entrada":
						datos_normalizados[campo] = "presencial"
					"recibido_por":
						datos_normalizados[campo] = "admin"
					"estado":
						datos_normalizados[campo] = "recibida"
					"prioridad":
						datos_normalizados[campo] = "media"
					_:
						datos_normalizados[campo] = valor
			else:
				datos_normalizados[campo] = valor.to_lower()
	
	# Validación específica para canal_entrada
	if datos_normalizados.has("canal_entrada"):
		var canal = str(datos_normalizados["canal_entrada"]).strip_edges().to_lower()
		if canal == "" or canal == "sistema":
			# Asignar un canal válido por defecto
			datos_normalizados["canal_entrada"] = "presencial"
		else:
			datos_normalizados["canal_entrada"] = canal
	
	# Asegurar que el monto sea float
	if datos_normalizados.has("monto_reclamado"):
		var monto_str = str(datos_normalizados["monto_reclamado"])
		if monto_str.is_valid_float():
			datos_normalizados["monto_reclamado"] = float(monto_str)
		else:
			datos_normalizados["monto_reclamado"] = 0.0
	
	return datos_normalizados

func cargar_datos_prueba_db():
	print("Cargando datos de prueba en la base de datos...")
	
	var datos_prueba = [
		{
			"tipo_caso": "queja",
			"tipo_reclamante": "cliente",
			"nombres": "Juan Pérez",
			"identificacion": "1701234567",
			"telefono": "+593991234567",
			"email": "juan.perez@email.com",
			"asunto": "Producto defectuoso",
			"descripcion_detallada": "El producto recibido presenta fallas en el funcionamiento desde el primer día de uso.",
			"monto_reclamado": 150.0,
			"prioridad": "alta",
			"estado": "pendiente",
			"canal_entrada": "sistema",
			"recibido_por": "admin"
		},
		{
			"tipo_caso": "reclamacion",
			"tipo_reclamante": "cliente",
			"nombres": "María González",
			"identificacion": "1754321098",
			"telefono": "+593987654321",
			"email": "maria.gonzalez@email.com",
			"asunto": "Mala atención al cliente",
			"descripcion_detallada": "El personal de atención al cliente fue grosero y no resolvió mi problema.",
			"monto_reclamado": 0.0,
			"prioridad": "media",
			"estado": "en_proceso",
			"canal_entrada": "sistema",
			"recibido_por": "admin"
		},
		{
			"tipo_caso": "sugerencia",
			"tipo_reclamante": "cliente",
			"nombres": "Carlos Rodríguez",
			"identificacion": "1711122233",
			"telefono": "+593998877665",
			"email": "carlos.rodriguez@email.com",
			"asunto": "Mejora en proceso de compra",
			"descripcion_detallada": "Sugiero agregar más métodos de pago y reducir los pasos en el proceso de checkout.",
			"monto_reclamado": 0.0,
			"prioridad": "baja",
			"estado": "resuelto",
			"canal_entrada": "sistema",
			"recibido_por": "admin"
		},
		{
			"tipo_caso": "felicitacion",
			"tipo_reclamante": "cliente",
			"nombres": "Ana López",
			"identificacion": "1723344556",
			"telefono": "+593996655443",
			"email": "ana.lopez@email.com",
			"asunto": "Excelente servicio post-venta",
			"descripcion_detallada": "Quiero felicitar al equipo de servicio post-venta por su rápida respuesta y solución efectiva.",
			"monto_reclamado": 0.0,
			"prioridad": "baja",
			"estado": "cerrado",
			"canal_entrada": "sistema",
			"recibido_por": "admin"
		}
	]
	
	var contador_exitos = 0
	var contador_errores = 0
	
	for datos in datos_prueba:
		# Llamar a la función existente de registro
		var resultado = registrar_queja_completa(datos)
		if resultado > 0:
			contador_exitos += 1
			
			# Registrar como NC si corresponde
			if debe_registrar_como_nc(datos):
				var id_nc = registrar_no_conformidad_desde_queja(resultado, datos)
				if id_nc != -1:
					print("📄 Queja registrada también como No Conformidad")
		else:
			contador_errores += 1
	
	print("✅ Datos de prueba cargados: %d exitos, %d errores" % [contador_exitos, contador_errores])
	return contador_exitos > 0
