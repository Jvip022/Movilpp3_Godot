extends Control
class_name InterfaceManager

# Señales
signal queja_registrada(datos: Dictionary)
signal configuracion_guardada(config: Dictionary)
signal cancelar_pressed()

# Referencias a nodos - ajustadas a la estructura de la escena proporcionada
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

func _ready():
	# Inicializar referencias a los nodos de la escena
	inicializar_referencias_nodos()
	
	# Configurar navegación entre pestañas
	configurar_navegacion()
	
	# Inicializar OptionButtons con valores por defecto
	inicializar_option_buttons()
	
	# Cargar configuración inicial
	cargar_configuracion()
	
	# Conectar señales
	conectar_senales()

func inicializar_referencias_nodos():
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

func configurar_navegacion():
	# Conectar botones de navegación
	if btn_registro_nav:
		btn_registro_nav.pressed.connect(func(): mostrar_pestana("registro"))
	
	if btn_seguimiento_nav:
		btn_seguimiento_nav.pressed.connect(func(): mostrar_pestana("seguimiento"))
	
	if btn_analiticas_nav:
		btn_analiticas_nav.pressed.connect(func(): mostrar_pestana("analiticas"))
	
	if btn_configuracion_nav:
		btn_configuracion_nav.pressed.connect(func(): mostrar_pestana("configuracion"))

func conectar_senales():
	# Conectar botones de acción
	if btn_registrar:
		btn_registrar.pressed.connect(_on_btn_registrar_pressed)
	
	if btn_back_menu:
		btn_back_menu.pressed.connect(_on_btn_back_menu_pressed)
	
	if btn_guardar_config:
		btn_guardar_config.pressed.connect(_on_btn_guardar_config_pressed)

func inicializar_option_buttons():
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

func mostrar_pestana(nombre_pestana: String):
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

# ===== FUNCIONES DEL FORMULARIO =====

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
		
		# Emitir señal con datos normalizados del formulario
		emit_signal("queja_registrada", datos_normalizados)
		
		# Limpiar formulario después de registrar
		limpiar_formulario()
		
		# Mostrar mensaje de éxito
		mostrar_mensaje_exito("Queja registrada exitosamente")
		
		# Actualizar estadísticas
		actualizar_estadisticas()
	else:
		mostrar_mensaje_error("No se pudo registrar la queja. Verifique los datos.")

func _on_btn_back_menu_pressed():
	print("Botón Volver al Menú presionado")
	emit_signal("cancelar_pressed")

func _on_btn_guardar_config_pressed():
	print("Botón Guardar Configuración presionado")
	
	var config = obtener_datos_configuracion()
	
	# Validar configuración
	if validar_configuracion(config):
		emit_signal("configuracion_guardada", config)
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

# ===== FUNCIONES DE SEGUIMIENTO =====

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas...")
	
	# Esta función debería cargar las quejas desde la base de datos
	# Por ahora, solo mostramos un mensaje
	mostrar_mensaje_info("Lista de quejas actualizada")
	
	# Si hay un campo de búsqueda, usar el filtro
	if txt_buscar and filtro != "":
		txt_buscar.text = filtro

# ===== FUNCIONES DE ESTADÍSTICAS =====

func actualizar_estadisticas():
	print("Actualizando estadísticas...")
	
	# Esta función debería cargar estadísticas reales desde la base de datos
	# Por ahora, actualizamos con valores de prueba
	
	if lbl_total_quejas:
		# Simular conteo de quejas
		lbl_total_quejas.text = "15"
	
	if lbl_pendientes_valor:
		# Simular quejas pendientes
		lbl_pendientes_valor.text = "3"
	
	mostrar_mensaje_info("Estadísticas actualizadas")

# ===== FUNCIONES DE CONFIGURACIÓN =====

func cargar_configuracion_en_ui():
	print("Cargando configuración en la UI...")
	
	# Esta función debería cargar la configuración desde el ConfigManager
	# Por ahora, establecemos valores por defecto
	
	if chk_notificaciones:
		chk_notificaciones.button_pressed = true
	
	if spin_intervalo:
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

# ===== FUNCIONES AUXILIARES =====

func mostrar_mensaje_error(mensaje: String):
	print("❌ Error: ", mensaje)
	# Aquí podrías implementar un sistema de notificaciones en la UI

func mostrar_mensaje_exito(mensaje: String):
	print("✅ Éxito: ", mensaje)
	# Aquí podrías implementar un sistema de notificaciones en la UI

func mostrar_mensaje_info(mensaje: String):
	print("ℹ️ Info: ", mensaje)

# ===== FUNCIONES PÚBLICAS PARA GESTOR_QUEJAS.GD =====

func actualizar_estadisticas_sidebar():
	# Actualizar las estadísticas en la barra lateral
	actualizar_estadisticas()

func actualizar_lista_no_conformidades():
	print("Actualizando lista de No Conformidades...")
	# Implementar cuando se agregue la pestaña de No Conformidades

# ===== FUNCIONES DE INICIALIZACIÓN EXTERNA =====

func conectar_senales_externas(gestor_quejas):
	# Conectar las señales del InterfaceManager al GestorQuejas
	queja_registrada.connect(gestor_quejas._on_queja_registrada_ui)
	configuracion_guardada.connect(gestor_quejas._on_configuracion_guardada_ui)
	cancelar_pressed.connect(gestor_quejas._on_cancelar_pressed_ui)

# ===== FUNCIONES PARA CARGA DE DATOS DE PRUEBA =====

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
