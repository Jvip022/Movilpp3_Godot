extends Node

var bd = Bd.db
var ui_manager: InterfaceManager = null
var config_manager: ConfigManager = null

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
	# Crear e inicializar ConfigManager
	config_manager = ConfigManager.new()
	config_manager.name = "ConfigManager"  # Asignar nombre
	add_child(config_manager)
	
	# Inicializar la interfaz
	ui_manager = get_node("InterfaceManager")
	if ui_manager:
		inicializar_interfaz()
	
	# Conectar el timer
	var timer = get_node("AutoUpdateTimer")
	if timer:
		timer.timeout.connect(_on_timer_timeout)
		timer.wait_time = config_manager.get_intervalo_actualizacion()
	
	# Cargar datos iniciales
	cargar_datos_iniciales()
	var db_info = Bd.get_database_info()
	print("📊 Tablas en la base de datos: ", db_info["tables"])
	if "quejas_reclamaciones" in db_info["tables"]:
		print("✅ Tabla quejas_reclamaciones existe")
		var structure = Bd.get_table_structure("quejas_reclamaciones")
		print("📋 Estructura de quejas_reclamaciones: ", structure)
	else:
		print("❌ Tabla quejas_reclamaciones NO existe")

func inicializar_interfaz():
	# Conectar señales del InterfaceManager
	ui_manager.queja_registrada.connect(_on_queja_registrada_ui)
	ui_manager.configuracion_guardada.connect(_on_configuracion_guardada_ui)  # Asegúrate que esta línea existe
	ui_manager.cancelar_pressed.connect(_on_cancelar_pressed_ui)
	
	# Configurar pestañas
	var tab_container = ui_manager.get_node("MainPanel/MainTabContainer")
	if tab_container:
		tab_container.tab_changed.connect(_on_tab_changed)
	
	# Cargar configuración en la UI
	cargar_configuracion_en_ui() 
	
func _on_queja_registrada_ui(datos: Dictionary):
	# Agregar datos adicionales de configuración
	datos["prioridad"] = datos.get("prioridad", config_manager.get_prioridad_por_defecto())
	datos["fecha_limite_respuesta"] = calcular_fecha_limite_con_config()
	
	# Registrar la queja
	var id_queja = registrar_queja_completa(datos)
	
	if id_queja != -1:
		print("Queja registrada desde UI con ID: ", id_queja)
		
		# Actualizar la interfaz
		ui_manager.actualizar_lista_quejas()
		ui_manager.actualizar_estadisticas()

func _on_configuracion_guardada_ui(config: Dictionary):
	# Guardar en ConfigManager
	config_manager.set_notificaciones(config.get("notificaciones", true))
	config_manager.set_intervalo_actualizacion(config.get("intervalo_actualizacion", 30))
	
	# Actualizar el timer
	var timer = get_node("AutoUpdateTimer")
	if timer:
		timer.wait_time = config_manager.get_intervalo_actualizacion()

func cargar_configuracion_en_ui():
	# Cargar configuración desde ConfigManager a la UI
	if ui_manager:
		# Esto debería hacerse a través de métodos específicos en InterfaceManager
		pass

func _on_timer_timeout():
	# Usar configuración para determinar qué actualizar
	if config_manager.get_notificaciones():
		actualizar_notificaciones()
	
	actualizar_lista_quejas()
	actualizar_estadisticas()

# FUNCIÓN CORREGIDA: NUEVO NOMBRE PARA EVITAR CONFLICTO
func calcular_fecha_limite_con_config(dias: int = -1) -> String:
	if dias == -1:
		dias = config_manager.get_limite_tiempo_respuesta()
	
	var hoy = Time.get_datetime_dict_from_system()
	
	# Crear un objeto Time para manipular fechas
	var fecha_limite = Time.get_unix_time_from_datetime_dict(hoy)
	fecha_limite += dias * 24 * 60 * 60  # Agregar días en segundos
	
	var fecha_dict = Time.get_datetime_dict_from_unix_time(fecha_limite)
	
	return "%04d-%02d-%02d" % [fecha_dict["year"], fecha_dict["month"], fecha_dict["day"]]

func _on_tab_changed(tab_index):
	match tab_index:
		0:  # Registro
			pass  # No necesita actualización
		1:  # Seguimiento
			actualizar_lista_quejas()
		2:  # Análticas
			actualizar_estadisticas()
		3:  # Configuración
			cargar_configuracion()

func actualizar_lista_quejas():
	# Lógica para actualizar la lista de quejas
	print("Actualizando lista de quejas...")
	if ui_manager:
		ui_manager.actualizar_lista_quejas()
	
func actualizar_notificaciones():
	# Lógica para actualizar notificaciones
	print("Actualizando notificaciones...")

func actualizar_estadisticas():
	# Lógica para actualizar estadísticas
	print("Actualizando estadísticas...")
	if ui_manager:
		ui_manager.actualizar_estadisticas()

func cargar_pestana_registro():
	# Lógica para cargar datos en pestaña de registro
	print("Cargando pestaña de registro...")

func cargar_pestana_seguimiento():
	# Lógica para cargar datos en pestaña de seguimiento
	print("Cargando pestaña de seguimiento...")

func cargar_configuracion():
	# Lógica para cargar configuración
	print("Cargando configuración...")

func cargar_datos_iniciales():
	# Cargar datos necesarios al iniciar
	print("Cargando datos iniciales del sistema...")

func ejecutar_flujo_queja_completo():
	# === ETAPA 1: RECEPCIÓN Y REGISTRO ===
	var id_queja = registrar_queja_completa({
		"tipo_caso": "reclamacion",
		"tipo_reclamante": "cliente",
		"nombres": "María González",
		"identificacion": "12345678",
		"telefono": "+593991234567",
		"email": "maria.g@email.com",
		
		"asunto": "Producto defectuoso recibido",
		"descripcion_detallada": "El televisor LG modelo 2024 presenta rayas en la pantalla desde el primer encendido. Comprado el 15/01/2024.",
		"producto_servicio": "Televisor LG 55' OLED",
		"numero_factura": "FAC-001-2024",
		"fecha_incidente": "2024-01-16",
		
		"categoria": "calidad_producto",
		"subcategoria": "defecto_fabricacion",
		"monto_reclamado": 899.99,
		"tipo_compensacion": "reemplazo",
		
		"canal_entrada": "email",
		"recibido_por": "operador_juan",
		"prioridad": "alta",
		"fecha_limite_respuesta": "2024-01-23"  # 7 días según ley
	})
	
	if id_queja == -1:
		push_error("No se pudo registrar la queja")
		return
	
	# === ETAPA 2: VALIDACIÓN Y ASIGNACIÓN ===
	validar_documentacion(id_queja)
	asignar_queja(id_queja, "supervisor_calidad", 2)  # Nivel 2: Supervisor
	
	# === ETAPA 3: INVESTIGACIÓN TÉCNICA ===
	var _resultado_investigacion = investigar_queja(id_queja, {
		"responsable_interno": "almacen_central",
		"hechos_constatados": "Producto con defecto de fábrica confirmado. No hay daños por transporte.",
		"pruebas": ["foto_pantalla.jpg", "reporte_tecnico.pdf"]
	})
	
	# === ETAPA 4: NEGOCIACIÓN CON CLIENTE ===
	registrar_contacto_cliente(id_queja, {
		"medio_contacto": "llamada",
		"tipo_contacto": "propuesta",
		"resumen": "Se ofreció reemplazo inmediato o devolución total",
		"estado_animo": "frustrado",
		"acuerdos": "Cliente acepta reemplazo, solicita instalación incluida",
		"proxima_accion": "Enviar producto nuevo",
		"fecha_proximo_contacto": "2024-01-18"
	})
	
	# === ETAPA 5: RESOLUCIÓN Y COMPENSACIÓN ===
	var _id_compensacion = aprobar_compensacion(id_queja, {
		"tipo_compensacion": "producto_reemplazo",
		"descripcion": "Televisor LG 55' OLED nuevo + instalación gratuita",
		"monto": 899.99,
		"aprobado_por": "gerente_calidad",
		"nivel_aprobacion": 3
	})
	
	# === ETAPE 6: SEGUIMIENTO POST-RESOLUCIÓN ===
	realizar_encuesta_satisfaccion(id_queja, {
		"satisfaccion_cliente": 4,  # 4/5 estrellas
		"comentarios_finales": "Solución aceptable, pero tardó 5 días",
		"recomendaria": true
	})
	
	# === ETAPA 7: CIERRE Y ANÁLISIS ===
	cerrar_queja(id_queja, "supervisor_calidad", {
		"decision": "aceptada_total",
		"lecciones_aprendidas": "Mejorar inspección en almacén",
		"acciones_preventivas": ["Auditar lote completo", "Capacitar personal de almacén"]
	})
	
	# Generar reporte para análisis de tendencias
	actualizar_analisis_tendencias(id_queja)

func registrar_queja_completa(datos: Dictionary) -> int:
	# Generar número de caso único
	var numero_caso = generar_numero_caso()
	
	# Validar datos obligatorios
	if not datos.has("nombres") or not datos.has("asunto"):
		push_error("Faltan datos obligatorios")
		return -1
	
	# Estructura completa de la queja
	var queja = {
		"numero_caso": numero_caso,
		"tipo_caso": datos.get("tipo_caso", "queja"),
		"tipo_reclamante": datos.get("tipo_reclamante", "cliente"),
		"nombres": datos["nombres"],
		"apellidos": datos.get("apellidos", ""),
		"identificacion": datos.get("identificacion", ""),
		"telefono": datos.get("telefono", ""),
		"email": datos.get("email", ""),
		
		"asunto": datos["asunto"],
		"descripcion_detallada": datos.get("descripcion_detallada", ""),
		"producto_servicio": datos.get("producto_servicio", ""),
		"numero_factura": datos.get("numero_factura", ""),
		"fecha_incidente": datos.get("fecha_incidente", ""),
		
		"categoria": datos.get("categoria", "atencion_cliente"),
		"monto_reclamado": float(datos.get("monto_reclamado", 0)),
		"tipo_compensacion": datos.get("tipo_compensacion", "ninguna"),
		
		"canal_entrada": datos.get("canal_entrada", "presencial"),
		"recibido_por": datos.get("recibido_por", "sistema"),
		"prioridad": calcular_prioridad(datos),
		"estado": "recibida",
		"fecha_limite_respuesta": datos.get("fecha_limite_respuesta", calcular_fecha_limite()),
		
		# Usar null en lugar de string "sistema" para clave foránea
		"creado_por": null,
		"tags": JSON.stringify(datos.get("tags", []))
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
	# En una implementación real, aquí generarías un PDF o documento
	# con los detalles de la compensación

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
			Nuevo nivel: %d
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

func _on_cancelar_pressed_ui():
	print("Recibida señal de cancelar desde InterfaceManager")
	
	# Opcional: Limpiar formulario antes de salir
	if ui_manager.has_method("limpiar_formulario"):
		ui_manager.limpiar_formulario()
	
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_cambiar_password_pressed():
	# Abrir diálogo de cambio de contraseña
	var dialogo = preload("res://escenas/autentificar.tscn").instantiate()
	add_child(dialogo)
	dialogo.mostrar_dialogo_cambiar_password()

func _on_perfil_pressed():
	# Mostrar menú de perfil con opción para cambiar contraseña
	var menu_perfil = $MenuPerfil
	var opcion_cambiar_password = menu_perfil.find_child("OpcionCambiarPassword")
	opcion_cambiar_password.pressed.connect(_on_cambiar_password_pressed)
	menu_perfil.visible = true
