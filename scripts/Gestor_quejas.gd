extends Node

var bd = Bd.db
var config_manager: Node = null  # Cambiado a Node

# ===== SISTEMA DE AUTENTICACIÓN Y ROLES (COPIADO DE MENU_PRINCIPAL) =====

# Definición de roles (idéntico al menu_Principal)
enum Roles {
	NO_AUTENTICADO,
	ADMINISTRADOR,
	SUPERVISOR_GENERAL,
	ESPECIALISTA_CALIDAD_SUCURSAL,
	AUDITOR,
	USUARIO,
	SISTEMA,
	SUPER_ADMIN  # Nuevo rol con acceso a todo
}

# Variables de estado del usuario
var usuario_actual = {
	"nombre": "Invitado",
	"rol": Roles.NO_AUTENTICADO,
	"id": null,
	"email": "",
	"sucursal": "",
	"departamento": "",
	"cargo": ""
}

# Referencia a Global (autoload)
var global_node

# ===== PERMISOS BASADOS EN ROL PARA GESTOR_QUEJAS =====

var permisos_elementos = {
	# Elementos de navegación
	"btn_seguimiento_nav": [Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.AUDITOR, Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"btn_analiticas_nav": [Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"btn_configuracion_nav": [Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	
	# Funcionalidades específicas
	"btn_registrar": [Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.SUPERVISOR_GENERAL, Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"btn_guardar_config": [Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	
	# Campos sensibles
	"opt_prioridad": [Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"txt_monto": [Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.SUPERVISOR_GENERAL, Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	
	# Botones de acción especial
	"btn_back_menu": [Roles.ADMINISTRADOR, Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.AUDITOR, Roles.USUARIO, Roles.SUPER_ADMIN]
}

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

# ===== NODOS DE USER PROFILE (AGREGADOS) =====
var user_profile_container: Control
var user_name_label: Label
var user_role_label: Label
var user_sucursal_label: Label

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
	# Obtener referencia a Global (autoload)
	global_node = get_node("/root/Global") if has_node("/root/Global") else null
	
	# Verificar sesión y cargar datos del usuario
	verificar_sesion()
	
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
	
	var db_info = Bd.get_database_info()
	print("📊 Tablas en la base de datos: ", db_info["tables"])
	if "quejas_reclamaciones" in db_info["tables"]:
		print("✅ Tabla quejas_reclamaciones existe")
		var structure = Bd.get_table_structure("quejas_reclamaciones")
		print("📋 Estructura de quejas_reclamaciones: ", structure)
	else:
		print("❌ Tabla quejas_reclamaciones NO existe")

# ===== FUNCIONES DE AUTENTICACIÓN Y ROLES (COPIADAS DE MENU_PRINCIPAL) =====

func verificar_sesion():
	print("DEBUG: Verificando sesión en GestorQuejas...")
	
	if not global_node:
		print("❌ Global no está disponible")
		configurar_modo_invitado()
		return
	
	print("DEBUG: Global encontrado: %s" % global_node.name)
	print("DEBUG: Usuario en Global: %s" % str(global_node.usuario_actual))
	
	# Verificar si hay usuario autenticado en Global
	if global_node.esta_autenticado():
		var usuario_global = global_node.usuario_actual
		
		# Debug detallado
		print("=== DATOS DE USUARIO DESDE GLOBAL ===")
		print("  ID: %s" % usuario_global.get('id', 'N/A'))
		print("  Username: %s" % usuario_global.get('username', 'N/A'))
		print("  Nombre: %s" % usuario_global.get('nombre', 'N/A'))
		print("  Rol (raw): %s" % usuario_global.get('rol', 'N/A'))
		print("  Email: %s" % usuario_global.get('email', 'N/A'))
		print("  Sucursal: %s" % usuario_global.get('sucursal', 'N/A'))
		print("=====================================")
		
		# Mapear el rol de BD al enum de Dashboard
		var rol_bd = str(usuario_global.get("rol", ""))
		var rol_enum = mapear_rol_bd_a_enum(rol_bd)
		
		usuario_actual = {
			"nombre": usuario_global.get("nombre", usuario_global.get("nombre_completo", "Usuario")),
			"rol": rol_enum,
			"id": usuario_global.get("id", -1),
			"email": usuario_global.get("email", ""),
			"sucursal": usuario_global.get("sucursal", ""),
			"departamento": usuario_global.get("departamento", ""),
			"cargo": usuario_global.get("cargo", "")
		}
		
		# Actualizar UI del UserProfile
		actualizar_user_profile_ui()
		
		print("✅ Sesión activa para: %s (Rol: %s)" % [usuario_actual["nombre"], obtener_nombre_rol(rol_enum)])
	else:
		print("DEBUG: No hay sesión activa en Global")
		configurar_modo_invitado()
	
	# Actualizar permisos y visibilidad según el rol
	actualizar_permisos_por_rol()

func mapear_rol_bd_a_enum(rol_bd: String) -> int:
	"""
    Convierte el rol de la base de datos (string) al enum del Dashboard.
	"""
	var rol_normalizado = rol_bd.to_lower().strip_edges()
	
	match rol_normalizado:
		"super_admin", "superadmin", "admin_super":
			return Roles.SUPER_ADMIN
		"admin", "administrador":
			return Roles.ADMINISTRADOR
		"supervisor", "supervisor_general":
			return Roles.SUPERVISOR_GENERAL
		"especialista", "especialista_calidad", "analista":
			return Roles.ESPECIALISTA_CALIDAD_SUCURSAL
		"auditor":
			return Roles.AUDITOR
		"sistema":
			return Roles.SISTEMA
		"usuario", "operador", "user":
			return Roles.USUARIO
		_:
			return Roles.NO_AUTENTICADO

func obtener_nombre_rol(rol_enum: int) -> String:
	"""Convierte el enum de rol a nombre legible"""
	match rol_enum:
		Roles.SUPER_ADMIN: return "Super Administrador"
		Roles.ADMINISTRADOR: return "Administrador"
		Roles.SUPERVISOR_GENERAL: return "Supervisor General"
		Roles.ESPECIALISTA_CALIDAD_SUCURSAL: return "Especialista de Calidad"
		Roles.AUDITOR: return "Auditor"
		Roles.USUARIO: return "Usuario"
		Roles.SISTEMA: return "Sistema"
		_: return "No autenticado"

func configurar_modo_invitado():
	usuario_actual = {
		"nombre": "Invitado",
		"rol": Roles.NO_AUTENTICADO,
		"id": null,
		"email": "",
		"sucursal": ""
	}
	
	# Actualizar UI del UserProfile
	if user_name_label:
		user_name_label.text = "Usuario: Invitado"
	if user_role_label:
		user_role_label.text = "Rol: No autenticado"
	if user_sucursal_label:
		user_sucursal_label.text = "Sucursal: No disponible"
	
	# Mostrar mensaje de advertencia
	print("⚠️ Usuario no autenticado. Algunas funcionalidades estarán limitadas.")

func actualizar_user_profile_ui():
	"""Actualiza la interfaz del perfil de usuario"""
	if user_name_label:
		user_name_label.text = "Usuario: " + usuario_actual["nombre"]
	
	if user_role_label:
		user_role_label.text = "Rol: " + obtener_nombre_rol(usuario_actual["rol"])
	
	if user_sucursal_label:
		var sucursal_text = "Sucursal: " + (usuario_actual.get("sucursal", "No disponible") if usuario_actual.get("sucursal") else "No disponible")
		user_sucursal_label.text = sucursal_text

func actualizar_permisos_por_rol():
	"""Actualiza la visibilidad y estado de los elementos según el rol del usuario"""
	print("Actualizando permisos para rol: %s" % obtener_nombre_rol(usuario_actual["rol"]))
	
	# Si no está autenticado, ocultar elementos sensibles
	if usuario_actual["rol"] == Roles.NO_AUTENTICADO:
		ocultar_elementos_no_autorizados()
		return
	
	# Si es SUPER_ADMIN, mostrar todos los elementos
	if usuario_actual["rol"] == Roles.SUPER_ADMIN:
		mostrar_todos_elementos()
		return
	
	# Para otros roles, verificar permisos elemento por elemento
	actualizar_elementos_segun_permisos()

func ocultar_elementos_no_autorizados():
	"""Oculta elementos para usuarios no autenticados"""
	print("Ocultando elementos no autorizados para invitados...")
	
	# Ocultar navegación avanzada
	if btn_seguimiento_nav:
		btn_seguimiento_nav.visible = false
	if btn_analiticas_nav:
		btn_analiticas_nav.visible = false
	if btn_configuracion_nav:
		btn_configuracion_nav.visible = false
	
	# Deshabilitar funcionalidades sensibles
	if btn_registrar:
		btn_registrar.disabled = true
		btn_registrar.text = "Registrar (Invitado)"
	
	if opt_prioridad:
		opt_prioridad.disabled = true
	
	if txt_monto:
		txt_monto.editable = false
		txt_monto.placeholder_text = "Requiere autenticación"

func mostrar_todos_elementos():
	"""Muestra todos los elementos para SUPER_ADMIN"""
	print("Mostrando todos los elementos para SUPER_ADMIN...")
	
	# Mostrar toda la navegación
	if btn_seguimiento_nav:
		btn_seguimiento_nav.visible = true
	if btn_analiticas_nav:
		btn_analiticas_nav.visible = true
	if btn_configuracion_nav:
		btn_configuracion_nav.visible = true
	
	# Habilitar todas las funcionalidades
	if btn_registrar:
		btn_registrar.disabled = false
		btn_registrar.text = "Registrar Queja"
	
	if opt_prioridad:
		opt_prioridad.disabled = false
	
	if txt_monto:
		txt_monto.editable = true
		txt_monto.placeholder_text = "0.00"

func actualizar_elementos_segun_permisos():
	"""Actualiza cada elemento según los permisos del rol"""
	
	# Función auxiliar para verificar permiso
	func tiene_permiso(elemento_id: String) -> bool:
		var roles_permitidos = permisos_elementos.get(elemento_id, [])
		return usuario_actual["rol"] in roles_permitidos
	
	# Actualizar elementos de navegación
	if btn_seguimiento_nav:
		btn_seguimiento_nav.visible = tiene_permiso("btn_seguimiento_nav")
	
	if btn_analiticas_nav:
		btn_analiticas_nav.visible = tiene_permiso("btn_analiticas_nav")
	
	if btn_configuracion_nav:
		btn_configuracion_nav.visible = tiene_permiso("btn_configuracion_nav")
	
	# Actualizar funcionalidades
	if btn_registrar:
		var puede_registrar = tiene_permiso("btn_registrar")
		btn_registrar.disabled = !puede_registrar
		if !puede_registrar:
			btn_registrar.text = "Registrar (No autorizado)"
	
	if opt_prioridad:
		opt_prioridad.disabled = !tiene_permiso("opt_prioridad")
	
	if txt_monto:
		txt_monto.editable = tiene_permiso("txt_monto")
		if !txt_monto.editable:
			txt_monto.placeholder_text = "No autorizado"

# ===== FUNCIONES DE INICIALIZACIÓN DE INTERFAZ =====

func inicializar_referencias_nodos():
	print("Inicializando referencias de nodos de interfaz...")
	
	# ===== NODOS DE USER PROFILE (AGREGADOS) =====
	user_profile_container = get_node_or_null("LayoutPrincipal/Header/UserProfile")
	if user_profile_container:
		print("✅ UserProfile encontrado")
		
		# Intentar diferentes rutas posibles para los labels
		user_name_label = get_node_or_null("LayoutPrincipal/Header/UserProfile/UserName")
		if not user_name_label:
			user_name_label = get_node_or_null("LayoutPrincipal/Header/UserProfile/UserInfo/UserName")
		
		user_role_label = get_node_or_null("LayoutPrincipal/Header/UserProfile/UserRole")
		if not user_role_label:
			user_role_label = get_node_or_null("LayoutPrincipal/Header/UserProfile/UserInfo/UserRole")
		
		user_sucursal_label = get_node_or_null("LayoutPrincipal/Header/UserProfile/UserSucursal")
		if not user_sucursal_label:
			user_sucursal_label = get_node_or_null("LayoutPrincipal/Header/UserProfile/UserInfo/UserSucursal")
		
		print("   UserName Label: %s" % ("✅" if user_name_label else "❌"))
		print("   UserRole Label: %s" % ("✅" if user_role_label else "❌"))
		print("   UserSucursal Label: %s" % ("✅" if user_sucursal_label else "❌"))
	else:
		print("❌ UserProfile no encontrado")
	
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
	
	print("✅ Señales de UI conectadas")

func mostrar_pestana(nombre_pestana: String):
	print("Mostrando pestaña: ", nombre_pestana)
	
	# Verificar permisos antes de mostrar pestañas
	if usuario_actual["rol"] == Roles.NO_AUTENTICADO:
		# Invitados solo pueden ver registro
		if nombre_pestana != "registro":
			mostrar_mensaje_error("Requiere autenticación para acceder a esta funcionalidad")
			nombre_pestana = "registro"
	
	# Verificar permisos específicos
	match nombre_pestana:
		"seguimiento":
			if usuario_actual["rol"] not in permisos_elementos["btn_seguimiento_nav"]:
				mostrar_mensaje_error("No tiene permisos para acceder al seguimiento")
				nombre_pestana = "registro"
		
		"analiticas":
			if usuario_actual["rol"] not in permisos_elementos["btn_analiticas_nav"]:
				mostrar_mensaje_error("No tiene permisos para acceder a las analíticas")
				nombre_pestana = "registro"
		
		"configuracion":
			if usuario_actual["rol"] not in permisos_elementos["btn_configuracion_nav"]:
				mostrar_mensaje_error("No tiene permisos para acceder a la configuración")
				nombre_pestana = "registro"
	
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
				actualizar_lista_quejas()
		
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
	
	# Verificar permisos
	if usuario_actual["rol"] == Roles.NO_AUTENTICADO:
		mostrar_mensaje_error("Debe iniciar sesión para registrar quejas")
		return
	
	if usuario_actual["rol"] not in permisos_elementos["btn_registrar"]:
		mostrar_mensaje_error("No tiene permisos para registrar quejas")
		return
	
	# Obtener y validar datos del formulario
	var datos_formulario = obtener_datos_formulario()
	
	if validar_formulario(datos_formulario):
		# Normalizar valores para la base de datos
		var datos_normalizados = normalizar_valores_db(datos_formulario)
		
		print("Datos normalizados para BD:")
		for key in datos_normalizados:
			print("  %s: %s" % [key, datos_normalizados[key]])
		
		# Agregar datos del usuario que registra
		datos_normalizados["creado_por"] = usuario_actual["id"]
		datos_normalizados["usuario_registro"] = usuario_actual["nombre"]
		datos_normalizados["sucursal_registro"] = usuario_actual.get("sucursal", "Desconocida")
		
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
			
			# Actualizar estadísticas
			actualizar_estadisticas()
		else:
			mostrar_mensaje_error("No se pudo registrar la queja en la base de datos")
	else:
		mostrar_mensaje_error("No se pudo registrar la queja. Verifique los datos.")

func _on_btn_back_menu_pressed():
	print("Botón Volver al Menú presionado")
	
	# Verificar permisos
	if usuario_actual["rol"] not in permisos_elementos["btn_back_menu"]:
		mostrar_mensaje_error("No tiene permisos para esta acción")
		return
	
	emit_signal("cancelar_pressed")
	
	# Limpiar formulario antes de salir
	limpiar_formulario()
	
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_btn_guardar_config_pressed():
	print("Botón Guardar Configuración presionado")
	
	# Verificar permisos
	if usuario_actual["rol"] not in permisos_elementos["btn_guardar_config"]:
		mostrar_mensaje_error("No tiene permisos para modificar la configuración")
		return
	
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
	datos["recibido_por"] = usuario_actual["nombre"]
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
			actualizar_estadisticas()
		3:  # Configuración
			cargar_configuracion_en_ui()
		4:  # No Conformidades
			actualizar_lista_no_conformidades()

# ===== FUNCIONES DE SEGUIMIENTO =====

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas...")
	
	# Esta función debería cargar las quejas desde la base de datos
	# Por ahora, solo mostramos un mensaje
	mostrar_mensaje_info("Lista de quejas actualizada")
	
	# Si hay un campo de búsqueda, usar el filtro
	if txt_buscar and filtro != "":
		txt_buscar.text = filtro

func actualizar_notificaciones():
	# Lógica para actualizar notificaciones
	print("Actualizando notificaciones...")

# ===== FUNCIONES DE ESTADÍSTICAS =====

func actualizar_estadisticas():
	print("Actualizando estadísticas...")
	
	# Esta función debería cargar estadísticas reales desde la base de datos
	# Por ahora, actualizamos con valores de prueba
	
	if lbl_total_quejas:
		# Obtener conteo real desde la base de datos
		var result = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones")
		if result and result.size() > 0:
			var total = result[0].get("total", 0)
			lbl_total_quejas.text = str(total)
		else:
			lbl_total_quejas.text = "0"
	
	if lbl_pendientes_valor:
		# Obtener conteo de pendientes
		var result = query_safe("SELECT COUNT(*) as total FROM quejas_reclamaciones WHERE estado = 'pendiente'")
		if result and result.size() > 0:
			var total = result[0].get("total", 0)
			lbl_pendientes_valor.text = str(total)
		else:
			lbl_pendientes_valor.text = "0"
	
	mostrar_mensaje_info("Estadísticas actualizadas")

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

# ===== FUNCIONES DE INICIALIZACIÓN =====

func inicializar_interfaz():
	print("Inicializando interfaz...")
	
	# Esta función ya se maneja en _ready
	pass

func cargar_datos_iniciales():
	# Cargar datos necesarios al iniciar
	print("Cargando datos iniciales del sistema...")

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

# FUNCIÓN ORIGINAL - NO MODIFICAR NOMBRE
func calcular_fecha_limite(dias: int = 7) -> String:
	# Calcular fecha límite de respuesta (7 días naturales por defecto)
	var hoy = Time.get_datetime_dict_from_system()
	
	# Crear un objeto Time para manipular fechas
	var fecha_limite = Time.get_unix_time_from_datetime_dict(hoy)
	fecha_limite += dias * 24 * 60 * 60  # Agregar días en segundos
	
	var fecha_dict = Time.get_datetime_dict_from_unix_time(fecha_limite)
	
	return "%04d-%02d-%02d" % [fecha_dict["year"], fecha_dict["month"], fecha_dict["day"]]

# FUNCIÓN CORREGIDA: NUEVO NOMBRE PARA EVITAR CONFLICTO
func calcular_fecha_limite_con_config(dias: int = -1) -> String:
	# Intentar obtener el límite del config_manager si está disponible
	if dias == -1 and config_manager and config_manager.has_method("get_limite_tiempo_respuesta"):
		dias = config_manager.get_limite_tiempo_respuesta()
	elif dias == -1:
		dias = 7  # Valor por defecto
	
	var hoy = Time.get_datetime_dict_from_system()
	
	# Crear un objeto Time para manipular fechas
	var fecha_limite = Time.get_unix_time_from_datetime_dict(hoy)
	fecha_limite += dias * 24 * 60 * 60  # Agregar días en segundos
	
	var fecha_dict = Time.get_datetime_dict_from_unix_time(fecha_limite)
	
	return "%04d-%02d-%02d" % [fecha_dict["year"], fecha_dict["month"], fecha_dict["day"]]

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
