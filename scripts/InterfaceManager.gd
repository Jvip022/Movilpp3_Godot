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
	
	# Inicializar OptionButtons con valores por defecto
	inicializar_option_buttons()
	
	# Conectar señales
	if btn_registrar:
		btn_registrar.pressed.connect(_on_btn_registrar_pressed)
	
	if btn_cancelar:
		btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	if btn_guardar_config:
		btn_guardar_config.pressed.connect(_on_btn_guardar_config_pressed)
	
	# Cargar configuración inicial
	cargar_configuracion()

# ===== NUEVA FUNCIÓN: Normalizar valores para la base de datos =====
func normalizar_valores_db(datos: Dictionary) -> Dictionary:
	var datos_normalizados = datos.duplicate(true)
	
	# Mapear tipo_caso a valores permitidos por la BD
	var mapa_tipo_caso = {
		"Queja": "queja",
		"Reclamo": "reclamacion",  # Cambiar "Reclamo" a "reclamacion"
		"Reclamación": "reclamacion",  # Para consistencia
		"Sugerencia": "sugerencia",
		"Consulta": "sugerencia",  # Mapear "Consulta" a "sugerencia" o podrías cambiarlo a otro valor
		"Felicitación": "felicitacion",
		"Felicitacion": "felicitacion"
	}
	
	if datos.has("tipo_caso"):
		var tipo_ui = datos["tipo_caso"]
		if mapa_tipo_caso.has(tipo_ui):
			datos_normalizados["tipo_caso"] = mapa_tipo_caso[tipo_ui]
		else:
			# Valor por defecto si no está en el mapa
			datos_normalizados["tipo_caso"] = "queja"
	
	# Asegurar que otros campos estén en minúsculas si es necesario
	if datos.has("tipo_reclamante"):
		datos_normalizados["tipo_reclamante"] = datos["tipo_reclamante"].to_lower()
	
	if datos.has("canal_entrada"):
		datos_normalizados["canal_entrada"] = datos["canal_entrada"].to_lower()
	
	if datos.has("recibido_por"):
		datos_normalizados["recibido_por"] = datos["recibido_por"].to_lower()
	
	if datos.has("estado"):
		datos_normalizados["estado"] = datos["estado"].to_lower()
	
	if datos.has("prioridad"):
		datos_normalizados["prioridad"] = datos["prioridad"].to_lower()
	
	return datos_normalizados

# Inicializar los OptionButtons con valores por defecto
func inicializar_option_buttons():
	# Inicializar tipos de caso - usar valores que se puedan mapear a la BD
	if opt_tipo_caso and opt_tipo_caso.get_item_count() == 0:
		opt_tipo_caso.add_item("Queja")
		opt_tipo_caso.add_item("Reclamo")  # Se mapeará a "reclamacion"
		opt_tipo_caso.add_item("Sugerencia")
		opt_tipo_caso.add_item("Felicitación")
		opt_tipo_caso.selected = 0  # Seleccionar el primer elemento por defecto
	
	# Inicializar prioridades
	if opt_prioridad and opt_prioridad.get_item_count() == 0:
		opt_prioridad.add_item("Baja")
		opt_prioridad.add_item("Media")
		opt_prioridad.add_item("Alta")
		opt_prioridad.add_item("Urgente")
		opt_prioridad.selected = 1  # Seleccionar "Media" por defecto
	
	# Inicializar OptionButton de estado en filtros (si existe)
	var opt_estado = get_node_or_null("MainPanel/MainTabContainer/Seguimiento/FiltrosPanel/OptEstado")
	if opt_estado and opt_estado.get_item_count() == 0:
		opt_estado.add_item("Todos")
		opt_estado.add_item("Pendiente")
		opt_estado.add_item("En Proceso")
		opt_estado.add_item("Resuelto")
		opt_estado.add_item("Cerrado")
		opt_estado.selected = 0

# ===== FUNCIONES AUXILIARES =====

func mostrar_mensaje_error(mensaje: String):
	print("❌ Error: ", mensaje)
	# Aquí podrías mostrar un label rojo con el mensaje de error

func mostrar_mensaje_exito(mensaje: String):
	print("✅ ", mensaje)
	# Aquí podrías mostrar un mensaje en la interfaz

func validar_formulario(datos: Dictionary) -> bool:
	# Validar campos obligatorios
	if datos.get("nombres", "").strip_edges() == "":
		mostrar_mensaje_error("El campo Nombres es obligatorio")
		return false
	
	if datos.get("asunto", "").strip_edges() == "":
		mostrar_mensaje_error("El campo Asunto es obligatorio")
		return false
	
	# Validar email si se proporcionó con una expresión regular básica
	var email = datos.get("email", "")
	if email != "":
		# Expresión regular simple para validar email
		var regex = RegEx.new()
		# Patrón básico para email
		regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
		var result = regex.search(email)
		if result == null:
			mostrar_mensaje_error("El email no es válido. Use formato: usuario@dominio.com")
			return false
	
	return true

func obtener_datos_formulario() -> Dictionary:
	var datos = {}
	
	# Obtener tipo de caso - verificar que haya selección válida
	if opt_tipo_caso and opt_tipo_caso.selected >= 0:
		datos["tipo_caso"] = opt_tipo_caso.get_item_text(opt_tipo_caso.selected)
	else:
		datos["tipo_caso"] = ""
	
	# Obtener otros campos
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
	
	# Obtener prioridad - verificar que haya selección válida
	if opt_prioridad and opt_prioridad.selected >= 0:
		datos["prioridad"] = opt_prioridad.get_item_text(opt_prioridad.selected)
	else:
		datos["prioridad"] = ""
	
	# Datos adicionales por defecto
	datos["tipo_reclamante"] = "cliente"
	datos["canal_entrada"] = "sistema"
	datos["recibido_por"] = "usuario"
	datos["fecha_registro"] = Time.get_datetime_string_from_system()
	datos["estado"] = "Pendiente"
	
	return datos

# ===== FUNCIÓN LIMPIAR FORMULARIO =====

func limpiar_formulario():
	print("Limpiando formulario...")
	
	# Restablecer OptionButtons a sus valores por defecto
	if opt_tipo_caso and opt_tipo_caso.get_item_count() > 0:
		opt_tipo_caso.selected = 0
	
	if opt_prioridad and opt_prioridad.get_item_count() > 0:
		opt_prioridad.selected = 1  # Media por defecto
	
	# Limpiar LineEdits
	if txt_nombres:
		txt_nombres.text = ""
	
	if txt_identificacion:
		txt_identificacion.text = ""
	
	if txt_telefono:
		txt_telefono.text = ""
	
	if txt_email:
		txt_email.text = ""
	
	if txt_asunto:
		txt_asunto.text = ""
	
	# Limpiar TextEdit
	if txt_descripcion:
		txt_descripcion.text = ""
	
	# Restablecer SpinBox a 0
	if spin_monto:
		spin_monto.value = 0.0
	
	print("✅ Formulario limpiado correctamente")

# ===== FUNCIONES DE MANEJO DE FORMULARIO =====

func formulario_tiene_datos() -> bool:
	var tiene_datos = false
	
	# Verificar si algún campo tiene datos
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
	elif opt_tipo_caso and opt_tipo_caso.selected > 0:
		tiene_datos = true
	elif opt_prioridad and opt_prioridad.selected != 1:  # Si no es "Media" (valor por defecto)
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
	
	# Cargar tipo de caso
	if opt_tipo_caso and datos.has("tipo_caso"):
		var tipo_caso = str(datos["tipo_caso"])
		# Buscar el índice del tipo de caso
		for i in range(opt_tipo_caso.get_item_count()):
			if opt_tipo_caso.get_item_text(i) == tipo_caso:
				opt_tipo_caso.selected = i
				break
	
	# Cargar otros campos
	if txt_nombres and datos.has("nombres"):
		txt_nombres.text = str(datos["nombres"])
	
	if txt_identificacion and datos.has("identificacion"):
		txt_identificacion.text = str(datos["identificacion"])
	
	if txt_telefono and datos.has("telefono"):
		txt_telefono.text = str(datos["telefono"])
	
	if txt_email and datos.has("email"):
		txt_email.text = str(datos["email"])
	
	if txt_asunto and datos.has("asunto"):
		txt_asunto.text = str(datos["asunto"])
	
	if txt_descripcion and datos.has("descripcion_detallada"):
		txt_descripcion.text = str(datos["descripcion_detallada"])
	
	if spin_monto and datos.has("monto_reclamado"):
		spin_monto.value = float(datos["monto_reclamado"])
	
	# Cargar prioridad
	if opt_prioridad and datos.has("prioridad"):
		var prioridad = str(datos["prioridad"])
		# Buscar el índice de la prioridad
		for i in range(opt_prioridad.get_item_count()):
			if opt_prioridad.get_item_text(i) == prioridad:
				opt_prioridad.selected = i
				break

func obtener_valor_campo(nombre_campo: String):
	match nombre_campo:
		"tipo_caso":
			if opt_tipo_caso and opt_tipo_caso.selected >= 0:
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
			if opt_prioridad and opt_prioridad.selected >= 0:
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
		mostrar_mensaje_error("El intervalo debe ser al menos 1 minuto")
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
	print("Botón Registrar presionado")
	
	# Obtener y validar datos del formulario
	var datos_formulario = obtener_datos_formulario()
	
	if validar_formulario(datos_formulario):
		# Normalizar valores para la base de datos
		var datos_normalizados = normalizar_valores_db(datos_formulario)
		
		# Mostrar datos en consola para depuración
		print("Datos normalizados para BD:")
		for key in datos_normalizados:
			print("  %s: %s" % [key, datos_normalizados[key]])
		
		# Emitir señal con datos normalizados del formulario
		emit_signal("queja_registrada", datos_normalizados)
		
		# Limpiar formulario después de registrar
		limpiar_formulario()
		
		mostrar_mensaje_exito("Queja registrada exitosamente")
	else:
		mostrar_mensaje_error("No se pudo registrar la queja. Verifique los datos.")

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

# ===== NUEVA FUNCIÓN: Cargar quejas de prueba para previsualización =====
func cargar_datos_prueba_ui():
	print("Cargando datos de prueba para previsualización...")
	
	# Lista de quejas de prueba
	var quejas_prueba = [
		{
			"tipo_caso": "Queja",
			"nombres": "Juan Pérez",
			"identificacion": "1701234567",
			"telefono": "+593991234567",
			"email": "juan.perez@email.com",
			"asunto": "Producto defectuoso",
			"descripcion_detallada": "El producto recibido presenta fallas en el funcionamiento desde el primer día de uso.",
			"monto_reclamado": 150.0,
			"prioridad": "Alta",
			"estado": "Pendiente"
		},
		{
			"tipo_caso": "Reclamo",
			"nombres": "María González",
			"identificacion": "1754321098",
			"telefono": "+593987654321",
			"email": "maria.gonzalez@email.com",
			"asunto": "Mala atención al cliente",
			"descripcion_detallada": "El personal de atención al cliente fue grosero y no resolvió mi problema.",
			"monto_reclamado": 0.0,
			"prioridad": "Media",
			"estado": "En Proceso"
		},
		{
			"tipo_caso": "Sugerencia",
			"nombres": "Carlos Rodríguez",
			"identificacion": "1711122233",
			"telefono": "+593998877665",
			"email": "carlos.rodriguez@email.com",
			"asunto": "Mejora en proceso de compra",
			"descripcion_detallada": "Sugiero agregar más métodos de pago y reducir los pasos en el proceso de checkout.",
			"monto_reclamado": 0.0,
			"prioridad": "Baja",
			"estado": "Resuelto"
		},
		{
			"tipo_caso": "Felicitación",
			"nombres": "Ana López",
			"identificacion": "1723344556",
			"telefono": "+593996655443",
			"email": "ana.lopez@email.com",
			"asunto": "Excelente servicio post-venta",
			"descripcion_detallada": "Quiero felicitar al equipo de servicio post-venta por su rápida respuesta y solución efectiva.",
			"monto_reclamado": 0.0,
			"prioridad": "Baja",
			"estado": "Cerrado"
		},
		{
			"tipo_caso": "Queja",
			"nombres": "Pedro Martínez",
			"identificacion": "1733445566",
			"telefono": "+593994433221",
			"email": "pedro.martinez@email.com",
			"asunto": "Retraso en la entrega",
			"descripcion_detallada": "Mi pedido tiene un retraso de 5 días hábiles sin ninguna explicación por parte de la empresa.",
			"monto_reclamado": 75.5,
			"prioridad": "Urgente",
			"estado": "Pendiente"
		}
	]
	
	# Actualizar la lista de quejas con los datos de prueba
	if lista_quejas:
		lista_quejas.clear()
		
		# Configurar columnas
		lista_quejas.set_column_title(0, "ID")
		lista_quejas.set_column_title(1, "Cliente")
		lista_quejas.set_column_title(2, "Asunto")
		lista_quejas.set_column_title(3, "Tipo")
		lista_quejas.set_column_title(4, "Prioridad")
		lista_quejas.set_column_title(5, "Estado")
		lista_quejas.set_column_title(6, "Fecha")
		
		# Crear items para cada queja de prueba
		var id = 1
		for queja in quejas_prueba:
			var item = lista_quejas.create_item()
			item.set_text(0, str(id))
			item.set_text(1, queja["nombres"])
			item.set_text(2, queja["asunto"])
			item.set_text(3, queja["tipo_caso"])
			item.set_text(4, queja["prioridad"])
			item.set_text(5, queja["estado"])
			item.set_text(6, "2024-01-%02d" % id)  # Fecha ficticia
			
			# Opcional: agregar metadatos para referencia
			item.set_metadata(0, queja)
			
			id += 1
	
	# Actualizar estadísticas
	actualizar_estadisticas_prueba(len(quejas_prueba))
	
	mostrar_mensaje_exito("Datos de prueba cargados exitosamente")

# ===== NUEVA FUNCIÓN: Actualizar estadísticas con datos de prueba =====
func actualizar_estadisticas_prueba(total_quejas: int):
	print("Actualizando estadísticas con datos de prueba")
	
	if lbl_total:
		lbl_total.text = "Total Quejas: %d" % total_quejas
	
	if lbl_pendientes:
		# Simular que 2 de 5 están pendientes (40%)
		var pendientes = int(total_quejas * 0.4)
		lbl_pendientes.text = "Pendientes: %d" % pendientes

# ===== FUNCIONES PÚBLICAS =====

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas con filtro: ", filtro)
	
	# Si no hay filtro, mostrar todos los datos
	if filtro == "":
		# Si queremos cargar datos de prueba automáticamente cuando no hay filtro
		cargar_datos_prueba_ui()
	elif lista_quejas:
		lista_quejas.clear()
		var _root = lista_quejas.create_item()  # Variable con _ para indicar que no se usa
		lista_quejas.set_column_title(0, "ID")
		lista_quejas.set_column_title(1, "Cliente")
		lista_quejas.set_column_title(2, "Asunto")
		lista_quejas.set_column_title(3, "Tipo")
		lista_quejas.set_column_title(4, "Prioridad")
		lista_quejas.set_column_title(5, "Estado")
		lista_quejas.set_column_title(6, "Fecha")

func actualizar_estadisticas():
	print("Actualizando estadísticas")
	
	# Si no hay datos reales, cargar estadísticas de prueba
	cargar_datos_prueba_ui()
