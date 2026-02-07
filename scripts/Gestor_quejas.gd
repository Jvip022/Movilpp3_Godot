extends Node

var bd = Bd.db
var config_manager: Node = null

# Señales
signal queja_registrada(datos: Dictionary)
signal configuracion_guardada(config: Dictionary)
signal cancelar_pressed()

# Referencias a nodos de la UI
var btn_registrar: Button
var btn_back_menu: Button
var btn_guardar_config: Button
var btn_registro_nav: Button
var btn_seguimiento_nav: Button
var btn_analiticas_nav: Button
var btn_configuracion_nav: Button
var btn_filtrar: Button  # Botón de filtrar en seguimiento

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

# Estadísticas en sidebar
var lbl_total_quejas: Label
var lbl_pendientes_valor: Label

# Elementos de seguimiento
var txt_buscar: LineEdit
var opt_status_filter: OptionButton

# Variable para almacenar la queja seleccionada
var queja_seleccionada_id: int = -1

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
	
	# Crear e inicializar ConfigManager
	if not config_manager:
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
	if Bd.has_method("get_database_info"):
		var db_info = Bd.get_database_info()
		print("📊 Tablas en la base de datos: ", db_info["tables"])
		if "quejas_reclamaciones" in db_info["tables"]:
			print("✅ Tabla quejas_reclamaciones existe")
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
	btn_filtrar = get_node_or_null("LayoutPrincipal/MainContent/ContentArea/SeguimientoTab/Filters/FilterButton")
	
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
	
	if btn_filtrar:
		btn_filtrar.pressed.connect(_on_btn_filtrar_pressed)
	
	# Conectar filtros de seguimiento
	if txt_buscar:
		txt_buscar.text_changed.connect(_on_buscar_text_changed)
	
	if opt_status_filter:
		opt_status_filter.item_selected.connect(_on_status_filter_changed)
	
	print("✅ Señales de UI conectadas")

func _on_buscar_text_changed(new_text: String):
	# Actualizar lista después de un breve delay para evitar múltiples consultas
	if seguimiento_tab and seguimiento_tab.visible:
		call_deferred("actualizar_lista_quejas")

func _on_status_filter_changed(index: int):
	# Actualizar lista cuando cambia el filtro de estado
	if seguimiento_tab and seguimiento_tab.visible:
		actualizar_lista_quejas()

func _on_btn_filtrar_pressed():
	# Actualizar lista cuando se presiona el botón de filtrar
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
				queja_seleccionada_id = -1
		
		"analiticas":
			if analiticas_tab:
				analiticas_tab.visible = true
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

func _on_timer_timeout():
	# Usar configuración para determinar qué actualizar
	if config_manager and config_manager.has_method("get_notificaciones") and config_manager.get_notificaciones():
		actualizar_notificaciones()
	
	# Actualizar interfaz
	actualizar_estadisticas()
	
	# Si estamos en la pestaña de seguimiento, actualizar lista
	if seguimiento_tab and seguimiento_tab.visible:
		actualizar_lista_quejas()

# ===== FUNCIONES DE SEGUIMIENTO =====

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas...")
	
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
	
	print("📋 " + str(quejas.size()) + " quejas encontradas:")
	
	# Mostrar en consola con formato
	for queja in quejas:
		var estado = queja.get("estado", "desconocido").capitalize()
		var prioridad = queja.get("prioridad", "media").capitalize()
		var icono_estado = get_icono_estado(estado)
		var icono_prioridad = get_icono_prioridad(prioridad)
		
		print("  %s ID: %s | %s Caso: %s | 👤 Cliente: %s | %s Estado: %s | %s Prioridad: %s" % [
			icono_estado, queja["id"], icono_prioridad, queja.get("numero_caso", "N/A"), 
			queja.get("nombres", "Sin nombre"), icono_estado, estado, icono_prioridad, prioridad
		])
	
	queja_seleccionada_id = -1
	
	# Si hay filtro en parámetro, establecerlo en el campo de búsqueda
	if filtro != "" and txt_buscar:
		txt_buscar.text = filtro

func get_icono_estado(estado: String) -> String:
	match estado.to_lower():
		"pendiente":
			return "🟡"
		"en proceso", "en_proceso":
			return "🔵"
		"resuelto":
			return "🟢"
		"cerrado":
			return "⚫"
		_:
			return "❓"

func get_icono_prioridad(prioridad: String) -> String:
	match prioridad.to_lower():
		"urgente":
			return "🔴"
		"alta":
			return "🟠"
		"media":
			return "🟡"
		"baja":
			return "🟢"
		_:
			return "⚪"

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

# ===== FUNCIONES DE CONFIGURACIÓN =====

func cargar_configuracion_en_ui():
	print("Cargando configuración en la UI...")
	
	# Cargar configuración desde ConfigManager o valores por defecto
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

# ===== FUNCIONES DE INICIALIZACIÓN =====

func cargar_datos_iniciales():
	# Cargar datos necesarios al iniciar
	print("Cargando datos iniciales del sistema...")
	actualizar_estadisticas()  # Cargar estadísticas al iniciar

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

func obtener_nc_por_id(id_nc: int) -> Dictionary:
	"""
	Obtiene una no conformidad por su ID.
	"""
	var result = query_safe("SELECT * FROM no_conformidades WHERE id_nc = ?", [id_nc])
	
	if result.size() > 0:
		return result[0]
	
	return {}

# ============================================================
# FUNCIONES PRINCIPALES DE GESTIÓN DE QUEJAS (MANTENIDAS)
# ============================================================

func registrar_queja_completa(datos: Dictionary) -> int:
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
		"creado_por": null
	}
	
	print("📝 Insertando queja con datos:")
	print("   Número caso: ", numero_caso)
	print("   Asunto: ", queja["asunto"])
	print("   Cliente: ", queja["nombres"])
	
	# Insertar en base de datos
	var id_queja_local = Bd.insert("quejas_reclamaciones", queja)
	
	if id_queja_local == -1:
		push_error("Error al insertar la queja en la base de datos")
		return -1
	
	print("✅ Queja registrada con ID: ", id_queja_local)
	
	# Registrar en historial
	registrar_historial_queja(id_queja_local, "queja_registrada",
		"Queja registrada por " + queja["recibido_por"])
	
	# Notificar al equipo asignado
	notificar_nueva_queja(id_queja_local, queja["prioridad"])
	
	return id_queja_local

func generar_numero_caso() -> String:
	var year = Time.get_datetime_string_from_system().substr(0, 4)
	
	var result = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones")
	
	var numero = 1
	if result.size() > 0:
		var count = result[0].get("total", 0)
		numero = int(count) + 1
	
	return "Q-%s-%03d" % [year, numero]

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

func calcular_fecha_limite(dias: int = 7) -> String:
	# Calcular fecha límite de respuesta (7 días naturales por defecto)
	var fecha_actual_unix = Time.get_unix_time_from_system()
	var dias_en_segundos = int(dias) * 24 * 60 * 60
	var fecha_limite_unix = fecha_actual_unix + dias_en_segundos
	
	# Convertir a fecha legible
	var fecha_limite = Time.get_datetime_dict_from_unix_time(fecha_limite_unix)
	
	return "%04d-%02d-%02d" % [fecha_limite["year"], fecha_limite["month"], fecha_limite["day"]]

func calcular_fecha_limite_con_config(dias: int = -1) -> String:
	# Intentar obtener el límite del config_manager si está disponible
	if dias == -1 and config_manager and config_manager.has_method("get_limite_tiempo_respuesta"):
		dias = int(config_manager.get_limite_tiempo_respuesta())
	elif dias == -1:
		dias = 7  # Valor por defecto
	
	# Asegurarse de que dias sea un entero
	dias = int(dias)
	
	# Calcular fecha límite
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
	
	# Insertar en la tabla de historial si existe
	if Bd.table_exists("historial_quejas"):
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
        Cliente: %s
        Monto Reclamado: $%.2f
        Fecha Límite: %s
	""" % [
		queja["numero_caso"],
		queja["asunto"],
		prioridad,
		queja["nombres"],
		queja.get("monto_reclamado", 0),
		queja.get("fecha_limite_respuesta", "No establecida")
	]
	
	print("📢 Notificación de nueva queja:")
	print(mensaje)

func obtener_queja_por_id(id_queja: int) -> Dictionary:
	"""
	Obtiene una queja por su ID.
	"""
	var query = "SELECT * FROM quejas_reclamaciones WHERE id = ?"
	var result = query_safe(query, [id_queja])
	
	if result.size() > 0:
		return result[0]
	
	return {}

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
		else:
			contador_errores += 1
	
	print("✅ Datos de prueba cargados: %d exitos, %d errores" % [contador_exitos, contador_errores])
	return contador_exitos > 0
