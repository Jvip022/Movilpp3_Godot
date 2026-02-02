extends Control
class_name InterfaceManager

# Señales
signal queja_registrada(datos: Dictionary)
signal configuracion_guardada(config: Dictionary)
signal cancelar_pressed()

# Referencias a nodos (se llenarán en _ready)
var btn_registrar: Button
var btn_cancelar: Button
var btn_guardar_config: Button
var lista_quejas: Tree
var lbl_total: Label
var lbl_pendientes: Label
var txt_buscar: LineEdit

# Referencias a los campos del formulario
var opt_tipo_caso: OptionButton
var txt_nombres: LineEdit
var txt_identificacion: LineEdit
var txt_telefono: LineEdit
var txt_email: LineEdit
var txt_asunto: LineEdit
var txt_descripcion: TextEdit
var spin_monto: SpinBox
var opt_prioridad: OptionButton

# Referencias a campos de configuración
var chk_notificaciones: CheckBox
var spin_intervalo: SpinBox

func _ready():
	# Inicializar referencias
	btn_registrar = get_node_or_null("MainPanel/MainTabContainer/Registro/BtnRegistrar")
	btn_cancelar = get_node_or_null("MainPanel/MainTabContainer/Registro/BtnCancelar")
	btn_guardar_config = get_node_or_null("MainPanel/MainTabContainer/Configuracion/BtnGuardar")
	lista_quejas = get_node_or_null("MainPanel/MainTabContainer/Seguimiento/ListaQuejas")
	lbl_total = get_node_or_null("MainPanel/MainTabContainer/Analiticas/StatsGrid/StatTotal/LblTotal")
	lbl_pendientes = get_node_or_null("MainPanel/MainTabContainer/Analiticas/StatsGrid/StatPendientes/LblPendientes")
	txt_buscar = get_node_or_null("MainPanel/MainTabContainer/Seguimiento/FiltrosPanel/TxtBuscar")
	
	# Inicializar referencias del formulario
	opt_tipo_caso = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/OptTipoCaso")
	txt_nombres = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/TxtNombres")
	txt_identificacion = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/TxtIdentificacion")
	txt_telefono = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/TxtTelefono")
	txt_email = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/TxtEmail")
	txt_asunto = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/TxtAsunto")
	txt_descripcion = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/TxtDescripcion")
	spin_monto = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/SpinMonto")
	opt_prioridad = get_node_or_null("MainPanel/MainTabContainer/Registro/FormContainer/FormGrid/OptPrioridad")
	
	# Inicializar referencias de configuración
	chk_notificaciones = get_node_or_null("MainPanel/MainTabContainer/Configuracion/ConfigGrid/ChkNotificaciones")
	spin_intervalo = get_node_or_null("MainPanel/MainTabContainer/Configuracion/ConfigGrid/SpinIntervalo")
	
	# Conectar señales
	if btn_registrar:
		btn_registrar.pressed.connect(_on_btn_registrar_pressed)
	
	if btn_cancelar:
		btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	if btn_guardar_config:
		btn_guardar_config.pressed.connect(_on_btn_guardar_config_pressed)
	
	# Cargar configuración inicial
	cargar_configuracion()

# ===== FUNCIONES AUXILIARES =====

func mostrar_mensaje_error(mensaje: String):
	print("❌ Error: ", mensaje)
	# Aquí podrías mostrar un label rojo con el mensaje de error

func mostrar_mensaje_exito(mensaje: String):
	print("✅ ", mensaje)
	# Aquí podrías mostrar un mensaje en la interfaz

func validar_formulario(datos: Dictionary) -> bool:
	if datos.get("nombres", "").strip_edges() == "":
		return false
	
	if datos.get("asunto", "").strip_edges() == "":
		return false
	
	return true

func obtener_datos_formulario() -> Dictionary:
	var datos = {}
	
	if opt_tipo_caso:
		datos["tipo_caso"] = opt_tipo_caso.get_item_text(opt_tipo_caso.selected)
	
	if txt_nombres:
		datos["nombres"] = txt_nombres.text.strip_edges()
	
	if txt_identificacion:
		datos["identificacion"] = txt_identificacion.text.strip_edges()
	
	if txt_telefono:
		datos["telefono"] = txt_telefono.text.strip_edges()
	
	if txt_email:
		datos["email"] = txt_email.text.strip_edges()
	
	if txt_asunto:
		datos["asunto"] = txt_asunto.text.strip_edges()
	
	if txt_descripcion:
		datos["descripcion_detallada"] = txt_descripcion.text.strip_edges()
	
	if spin_monto:
		datos["monto_reclamado"] = spin_monto.value
	
	if opt_prioridad:
		datos["prioridad"] = opt_prioridad.get_item_text(opt_prioridad.selected)
	
	# Datos adicionales por defecto
	datos["tipo_reclamante"] = "cliente"
	datos["canal_entrada"] = "sistema"
	datos["recibido_por"] = "usuario"
	
	return datos

# ===== FUNCIÓN LIMPIAR FORMULARIO =====

func limpiar_formulario():
	print("Limpiando formulario...")
	
	# Restablecer OptionButtons a la primera opción
	if opt_tipo_caso:
		opt_tipo_caso.selected = 0
	
	if opt_prioridad:
		opt_prioridad.selected = 0
	
	# Limpiar LineEdits
	if txt_nombres:
		txt_nombres.text = ""
		txt_nombres.placeholder_text = "Ingrese nombres completos"
	
	if txt_identificacion:
		txt_identificacion.text = ""
		txt_identificacion.placeholder_text = "Cédula/RUC/Pasaporte"
	
	if txt_telefono:
		txt_telefono.text = ""
		txt_telefono.placeholder_text = "+593..."
	
	if txt_email:
		txt_email.text = ""
		txt_email.placeholder_text = "cliente@email.com"
	
	if txt_asunto:
		txt_asunto.text = ""
		txt_asunto.placeholder_text = "Resumen breve del problema"
	
	# Limpiar TextEdit
	if txt_descripcion:
		txt_descripcion.text = ""
		txt_descripcion.placeholder_text = "Describa el problema en detalle..."
	
	# Restablecer SpinBox a 0
	if spin_monto:
		spin_monto.value = 0.0
	
	print("✅ Formulario limpiado correctamente")

# ===== FUNCIONES DE MANEJO DE FORMULARIO =====

func formulario_tiene_datos() -> bool:
	var tiene_datos = false
	
	if txt_nombres and txt_nombres.text.strip_edges() != "":
		tiene_datos = true
	elif txt_identificacion and txt_identificacion.text.strip_edges() != "":
		tiene_datos = true
	elif txt_asunto and txt_asunto.text.strip_edges() != "":
		tiene_datos = true
	elif txt_descripcion and txt_descripcion.text.strip_edges() != "":
		tiene_datos = true
	elif spin_monto and spin_monto.value > 0:
		tiene_datos = true
	
	return tiene_datos

func mostrar_dialogo_confirmacion():
	print("⚠️  Hay datos en el formulario. ¿Seguro que desea cancelar?")
	
	# En una implementación real, aquí mostrarías un diálogo de confirmación
	# Por ahora, simplemente emitimos la señal después de un mensaje de consola
	emit_signal("cancelar_pressed")

func cargar_datos_en_formulario(datos: Dictionary):
	if not datos:
		return
	
	if opt_tipo_caso and datos.has("tipo_caso"):
		# Buscar el índice del tipo de caso
		for i in range(opt_tipo_caso.item_count):
			if opt_tipo_caso.get_item_text(i) == datos["tipo_caso"]:
				opt_tipo_caso.selected = i
				break
	
	if txt_nombres and datos.has("nombres"):
		txt_nombres.text = datos["nombres"]
	
	if txt_identificacion and datos.has("identificacion"):
		txt_identificacion.text = str(datos["identificacion"])
	
	if txt_telefono and datos.has("telefono"):
		txt_telefono.text = datos["telefono"]
	
	if txt_email and datos.has("email"):
		txt_email.text = datos["email"]
	
	if txt_asunto and datos.has("asunto"):
		txt_asunto.text = datos["asunto"]
	
	if txt_descripcion and datos.has("descripcion_detallada"):
		txt_descripcion.text = datos["descripcion_detallada"]
	
	if spin_monto and datos.has("monto_reclamado"):
		spin_monto.value = float(datos["monto_reclamado"])
	
	if opt_prioridad and datos.has("prioridad"):
		# Buscar el índice de la prioridad
		for i in range(opt_prioridad.item_count):
			if opt_prioridad.get_item_text(i) == datos["prioridad"]:
				opt_prioridad.selected = i
				break

func obtener_valor_campo(nombre_campo: String):
	match nombre_campo:
		"tipo_caso":
			if opt_tipo_caso:
				return opt_tipo_caso.get_item_text(opt_tipo_caso.selected)
		"nombres":
			if txt_nombres:
				return txt_nombres.text
		"identificacion":
			if txt_identificacion:
				return txt_identificacion.text
		"telefono":
			if txt_telefono:
				return txt_telefono.text
		"email":
			if txt_email:
				return txt_email.text
		"asunto":
			if txt_asunto:
				return txt_asunto.text
		"descripcion":
			if txt_descripcion:
				return txt_descripcion.text
		"monto":
			if spin_monto:
				return spin_monto.value
		"prioridad":
			if opt_prioridad:
				return opt_prioridad.get_item_text(opt_prioridad.selected)
	
	return ""

# ===== FUNCIONES DE CONFIGURACIÓN =====

func obtener_datos_configuracion() -> Dictionary:
	var config = {}
	
	if chk_notificaciones:
		config["notificaciones"] = chk_notificaciones.button_pressed
	
	if spin_intervalo:
		config["intervalo_actualizacion"] = int(spin_intervalo.value)
	
	# Puedes agregar más campos de configuración aquí
	
	return config

func validar_configuracion(config: Dictionary) -> bool:
	# Validaciones básicas
	if config.get("intervalo_actualizacion", 0) < 1:
		return false
	
	return true

func cargar_configuracion():
	print("Cargando configuración...")
	
	# Aquí deberías cargar la configuración desde un archivo o base de datos
	# Por ahora, cargamos valores por defecto
	var config_default = {
		"notificaciones": true,
		"intervalo_actualizacion": 30
	}
	
	# Aplicar valores por defecto a la interfaz
	aplicar_configuracion_ui(config_default)

func aplicar_configuracion_ui(config: Dictionary):
	if chk_notificaciones and config.has("notificaciones"):
		chk_notificaciones.button_pressed = config["notificaciones"]
	
	if spin_intervalo and config.has("intervalo_actualizacion"):
		spin_intervalo.value = float(config["intervalo_actualizacion"])

# ===== FUNCIONES DE SEÑALES =====

func _on_btn_registrar_pressed():
	# Emitir señal con datos del formulario
	var datos_formulario = obtener_datos_formulario()
	
	if validar_formulario(datos_formulario):
		emit_signal("queja_registrada", datos_formulario)
		limpiar_formulario()  # Limpiar después de registrar
	else:
		mostrar_mensaje_error("Por favor complete los campos obligatorios")

func _on_btn_cancelar_pressed():
	print("Botón Cancelar presionado")
	
	# Verificar si hay datos en el formulario
	if formulario_tiene_datos():
		mostrar_dialogo_confirmacion()
	else:
		emit_signal("cancelar_pressed")

func _on_btn_guardar_config_pressed():
	print("Guardando configuración...")
	
	var config = obtener_datos_configuracion()
	
	# Validar configuración
	if validar_configuracion(config):
		emit_signal("configuracion_guardada", config)
		mostrar_mensaje_exito("Configuración guardada correctamente")
	else:
		mostrar_mensaje_error("Error en la configuración")

# ===== FUNCIONES PÚBLICAS =====

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas con filtro: ", filtro)
	if lista_quejas:
		lista_quejas.clear()
		# Aquí puedes agregar la lógica para cargar las quejas desde la base de datos

func actualizar_estadisticas():
	print("Actualizando estadísticas")
	if lbl_total:
		lbl_total.text = "Total Quejas: 0"
	if lbl_pendientes:
		lbl_pendientes.text = "Pendientes: 0"
