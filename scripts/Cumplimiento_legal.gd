extends Node
# Sistema de cumplimiento regulatorio
class_name CumplimientoLegal

var bd = Bd.db

# Funciones auxiliares para acceso a datos
func obtener_queja_por_id(queja_id: int) -> Dictionary:
	var sql = """
		SELECT * FROM quejas_reclamaciones 
		WHERE id = %d
	""" % queja_id
	var resultado = bd.query(sql)
	
	if resultado is Array and resultado.size() > 0:
		return resultado[0]
	return {}

func calcular_dias_abierta(queja: Dictionary) -> int:
	if queja.is_empty():
		return 0
	
	var fecha_recepcion = queja.get("fecha_recepcion", Time.get_datetime_string_from_system())
	var fecha_actual = Time.get_datetime_string_from_system()
	
	# Parsear fechas manualmente (formato: "YYYY-MM-DD HH:MM:SS")
	var fecha_inicio_parts = fecha_recepcion.substr(0, 10).split("-")
	var fecha_fin_parts = fecha_actual.substr(0, 10).split("-")
	
	if fecha_inicio_parts.size() < 3 or fecha_fin_parts.size() < 3:
		return 0
	
	var fecha_inicio = {
		"year": int(fecha_inicio_parts[0]),
		"month": int(fecha_inicio_parts[1]),
		"day": int(fecha_inicio_parts[2])
	}
	
	var fecha_fin = {
		"year": int(fecha_fin_parts[0]),
		"month": int(fecha_fin_parts[1]),
		"day": int(fecha_fin_parts[2])
	}
	
	# Calcular diferencia simple en días
	var dias_inicio = fecha_inicio["year"] * 365 + fecha_inicio["month"] * 30 + fecha_inicio["day"]
	var dias_fin = fecha_fin["year"] * 365 + fecha_fin["month"] * 30 + fecha_fin["day"]
	
	return dias_fin - dias_inicio

func obtener_documentos_queja(queja_id: int) -> Array:
	var sql = """
		SELECT * FROM documentos 
		WHERE queja_id = %d AND activo = 1
		ORDER BY fecha_subida DESC
	""" % queja_id
	var resultado = bd.query(sql)
	
	if resultado is Array:
		return resultado
	return []

func obtener_notificaciones_cliente(queja_id: int) -> Array:
	var sql = """
		SELECT * FROM notificaciones 
		WHERE queja_id = %d AND tipo = 'cliente'
		AND estado = 'enviado'
		ORDER BY fecha_envio DESC
	""" % queja_id
	var resultado = bd.query(sql)
	
	if resultado is Array:
		return resultado
	return []

func generar_recomendaciones(incumplimientos: Array) -> Array:
	var recomendaciones = []
	
	for inc in incumplimientos:
		match inc:
			"Excede plazo máximo de respuesta (30 días)":
				recomendaciones.append("Priorizar resolución inmediata y notificar al cliente sobre el retraso")
			"Reclamo mayor a $1000 requiere expediente legal":
				recomendaciones.append("Crear expediente legal con número formal y asignar abogado responsable")
			"Falta factura para reclamo mayor a $500":
				recomendaciones.append("Solicitar documentación complementaria al cliente")
			"Notificaciones insuficientes al cliente":
				recomendaciones.append("Enviar notificación de seguimiento y documentar en sistema")
			_:
				recomendaciones.append("Revisar procedimiento aplicable")
	
	return recomendaciones

func calcular_riesgo_legal(incumplimientos: Array) -> String:
	var nivel_riesgo = "Bajo"
	
	if incumplimientos.size() == 0:
		nivel_riesgo = "Nulo"
	elif incumplimientos.size() == 1:
		nivel_riesgo = "Bajo"
	elif incumplimientos.size() == 2:
		nivel_riesgo = "Medio"
	elif incumplimientos.size() == 3:
		nivel_riesgo = "Alto"
	elif incumplimientos.size() >= 4:
		nivel_riesgo = "Crítico"
	
	return nivel_riesgo

func guardar_reporte_cumplimiento(reporte: Dictionary) -> void:
	var sql = """
		INSERT INTO reportes_cumplimiento (
			queja_id, fecha_verificacion, cumplimiento_total,
			incumplimientos, recomendaciones, riesgo_legal
		) VALUES (%d, '%s', %d, '%s', '%s', '%s')
	""" % [
		reporte["queja_id"],
		reporte["fecha_verificacion"],
		1 if reporte["cumplimiento_total"] else 0,
		JSON.stringify(reporte["incumplimientos"]).replace("'", "''"),
		JSON.stringify(reporte["recomendaciones"]).replace("'", "''"),
		reporte["riesgo_legal"]
	]
	bd.query(sql)

func notificar_riesgo_legal(responsable_id: int, reporte: Dictionary) -> void:
	var sql = "SELECT email, nombre FROM usuarios WHERE id = %d" % responsable_id
	var responsable = bd.query(sql)
	
	if responsable is Array and responsable.size() > 0:
		var responsable_data = responsable[0]
		if responsable_data is Dictionary:
			var mensaje = """
				ALERTA DE RIESGO LEGAL
				
				Queja ID: %d
				Riesgo: %s
				Incumplimientos: %s
				
				Se requiere atención inmediata.
				""" % [
					reporte["queja_id"],
					reporte["riesgo_legal"],
					", ".join(reporte["incumplimientos"])
				]
			
			enviar_email(responsable_data.get("email", ""), mensaje, "alta")

func cargar_plantilla_legal() -> String:
	var plantilla = """
		CARTA DE RESPUESTA LEGAL
		
		Número de caso: {NUMERO_CASO}
		Fecha: {FECHA}
		
		Señor(es): {RECLAMANTE}
		
		Referencia: {ASUNTO}
		
		Por medio de la presente respondemos a su reclamo presentado 
		ante nuestra institución. 
		
		Base legal aplicable:
		{LEYES}
		
		Después de revisar cuidadosamente su caso, informamos que
		se han tomado las medidas correspondientes.
		
		Atentamente,
		
		{FIRMA_RESPONSABLE}
		
		{SELLO_EMPRESA}
		"""
	
	return plantilla

func identificar_leyes_aplicables(queja: Dictionary) -> String:
	var leyes = []
	
	# Determinar leyes según el país y tipo de reclamo
	var pais = queja.get("pais", "EC")  # Ecuador por defecto
	var categoria = queja.get("categoria", "")
	
	if pais == "EC":  # Ecuador
		leyes.append("- Ley Orgánica de Defensa del Consumidor (LODC)")
		leyes.append("- Código Orgánico de la Producción, Comercio e Inversiones")
		
		if categoria == "financiero":
			leyes.append("- Ley de Régimen Monetario y Banco del Estado")
	
	elif pais == "CO":  # Colombia
		leyes.append("- Estatuto del Consumidor (Ley 1480 de 2011)")
		leyes.append("- Código de Comercio")
	
	return "\n".join(leyes)

func obtener_firma_digital(responsable_id: int) -> String:
	var sql = """
		SELECT firma_digital FROM usuarios 
		WHERE id = %d
	""" % responsable_id
	var firma = bd.query(sql)
	
	if firma is Array and firma.size() > 0:
		var firma_data = firma[0]
		if firma_data is Dictionary and firma_data.get("firma_digital"):
			return firma_data["firma_digital"]
	
	return "_________________________\n" + obtener_nombre_responsable(responsable_id)

func obtener_sello_empresa() -> String:
	var sql = "SELECT sello_empresa FROM configuracion WHERE id = 1"
	var config = bd.query(sql)
	
	if config is Array and config.size() > 0:
		var config_data = config[0]
		if config_data is Dictionary:
			return config_data.get("sello_empresa", "SELLO OFICIAL DE LA EMPRESA")
	
	return "SELLO OFICIAL DE LA EMPRESA"

func guardar_carta(carta: String, queja_id: int) -> void:
	var sql = """
		INSERT INTO documentos (
			queja_id, tipo_documento, contenido,
			fecha_subida, nombre_archivo
		) VALUES (%d, 'carta_respuesta', '%s', '%s', 'carta_respuesta_legal_%d.txt')
	""" % [
		queja_id,
		carta.replace("'", "''"),
		Time.get_datetime_string_from_system(),
		queja_id
	]
	bd.query(sql)

func programar_recordatorios_equipo() -> void:
	# Programar recordatorios diarios
	var timer = Timer.new()
	timer.wait_time = 86400  # 24 horas
	timer.autostart = true
	timer.timeout.connect(_enviar_recordatorios_diarios)
	add_child(timer)

func programar_alertas_gerenciales() -> void:
	# Programar alertas semanales
	var timer = Timer.new()
	timer.wait_time = 604800  # 7 días
	timer.autostart = true
	timer.timeout.connect(_enviar_alertas_gerenciales)
	add_child(timer)

func _enviar_recordatorios_diarios() -> void:
	var sql = """
		SELECT q.id, q.numero_caso, u.email, u.nombre
		FROM quejas_reclamaciones q
		JOIN usuarios u ON q.asignado_a = u.id
		WHERE q.estado = 'en_proceso'
		AND date('now') - date(q.fecha_recepcion) >= 5
	"""
	var pendientes = bd.query(sql)
	
	if pendientes is Array:
		for pendiente in pendientes:
			if pendiente is Dictionary:
				var mensaje = "Recordatorio: Caso %s pendiente por 5+ días" % pendiente.get("numero_caso", "")
				enviar_email(pendiente.get("email", ""), mensaje, "media")

func _enviar_alertas_gerenciales() -> void:
	var sql = "SELECT email FROM usuarios WHERE rol = 'gerente'"
	var gerentes = bd.query(sql)
	
	# Calcular fecha hace 7 días
	var ahora = Time.get_datetime_string_from_system()
	var fecha_hace_7_dias = Time.get_datetime_string_from_system(-604800)
	
	var reporte = generar_reporte_calidad_servicio({
		"desde": fecha_hace_7_dias,
		"hasta": ahora
	})
	
	if gerentes is Array:
		for gerente in gerentes:
			if gerente is Dictionary:
				var mensaje = "Reporte semanal de calidad de servicio\n\n" + str(reporte)
				enviar_email(gerente.get("email", ""), mensaje, "baja")

# Funciones de notificación (implementaciones básicas)
func enviar_email(destino: String, mensaje: String, urgencia: String) -> void:
	print("Enviando email a ", destino)
	print("Urgencia: ", urgencia)
	print("Mensaje: ", mensaje)
	# Aquí iría la lógica real de envío de email

func enviar_sms(telefono: String, mensaje: String) -> void:
	print("Enviando SMS a ", telefono)
	print("Mensaje: ", mensaje)
	# Aquí iría la lógica real de envío de SMS

func enviar_push_notification(usuario_app: String, mensaje: String) -> void:
	print("Enviando push a usuario: ", usuario_app)
	print("Mensaje: ", mensaje)
	# Aquí iría la lógica real de push notification

func tiene_whatsapp_business() -> bool:
	var sql = "SELECT valor FROM configuracion WHERE clave = 'whatsapp_business'"
	var config = bd.query(sql)
	
	if config is Array and config.size() > 0:
		var config_data = config[0]
		if config_data is Dictionary:
			return config_data.get("valor", "") == "true"
	return false

func enviar_whatsapp_template(destino: String, nombre_template: String, parametros: Dictionary) -> void:
	print("Enviando WhatsApp a: ", destino)
	print("Template: ", nombre_template)
	print("Parámetros: ", parametros)
	# Aquí iría la lógica real de envío por WhatsApp

# Función auxiliar adicional
func obtener_nombre_responsable(responsable_id: int) -> String:
	var sql = "SELECT nombre FROM usuarios WHERE id = %d" % responsable_id
	var resultado = bd.query(sql)
	
	if resultado is Array and resultado.size() > 0:
		var resultado_data = resultado[0]
		if resultado_data is Dictionary:
			return resultado_data.get("nombre", "Responsable")
	return "Responsable"

# Función principal original (con ajustes)
func verificar_cumplimiento_ley(queja_id: int):
	var queja = obtener_queja_por_id(queja_id)
	if queja.is_empty():
		return {"error": "Queja no encontrada"}
	
	var incumplimientos = []
	
	# Verificar plazos máximos según ley
	var dias_abierto = calcular_dias_abierta(queja)
	if dias_abierto > 30:  # Ley establece máximo 30 días
		incumplimientos.append("Excede plazo máximo de respuesta (30 días)")
	
	# Verificar monto mínimo para reclamo formal
	var monto_reclamado = queja.get("monto_reclamado", 0)
	var numero_expediente = queja.get("numero_expediente_legal", "")
	
	if monto_reclamado > 1000 and numero_expediente == "":
		incumplimientos.append("Reclamo mayor a $1000 requiere expediente legal")
	
	# Verificar documentación obligatoria
	if monto_reclamado > 500:
		var docs = obtener_documentos_queja(queja_id)
		var tiene_factura = false
		for doc in docs:
			if doc is Dictionary and doc.get("tipo_documento") == "factura":
				tiene_factura = true
				break
		
		if not tiene_factura:
			incumplimientos.append("Falta factura para reclamo mayor a $500")
	
	# Verificar notificaciones al cliente
	var notificaciones = obtener_notificaciones_cliente(queja_id)
	if notificaciones.size() < 2:  # Mínimo 2 notificaciones requeridas
		incumplimientos.append("Notificaciones insuficientes al cliente")
	
	# Generar reporte de cumplimiento
	var reporte = {
		"queja_id": queja_id,
		"fecha_verificacion": Time.get_datetime_string_from_system(),
		"cumplimiento_total": incumplimientos.size() == 0,
		"incumplimientos": incumplimientos,
		"recomendaciones": generar_recomendaciones(incumplimientos),
		"riesgo_legal": calcular_riesgo_legal(incumplimientos)
	}
	
	guardar_reporte_cumplimiento(reporte)
	
	if incumplimientos.size() > 0:
		var asignado_a = queja.get("asignado_a", 0)
		if asignado_a > 0:
			notificar_riesgo_legal(asignado_a, reporte)
	
	return reporte

func generar_carta_respuesta_legal(queja_id: int):
	var queja = obtener_queja_por_id(queja_id)
	if queja.is_empty():
		return "Error: Queja no encontrada"
	
	var plantilla = cargar_plantilla_legal()
	
	var carta = plantilla.replace("{NUMERO_CASO}", str(queja.get("numero_caso", "")))
	carta = carta.replace("{FECHA}", Time.get_date_string_from_system())
	carta = carta.replace("{RECLAMANTE}", str(queja.get("nombres", "")) + " " + str(queja.get("apellidos", "")))
	carta = carta.replace("{ASUNTO}", str(queja.get("asunto", "")))
	
	# Agregar base legal según país
	var leyes_aplicables = identificar_leyes_aplicables(queja)
	carta = carta.replace("{LEYES}", leyes_aplicables)
	
	# Firmas digitales
	var asignado_a = queja.get("asignado_a", 0)
	if asignado_a > 0:
		carta = carta.replace("{FIRMA_RESPONSABLE}", obtener_firma_digital(asignado_a))
	else:
		carta = carta.replace("{FIRMA_RESPONSABLE}", "_________________________")
	
	carta = carta.replace("{SELLO_EMPRESA}", obtener_sello_empresa())
	
	guardar_carta(carta, queja_id)
	return carta

func configurar_notificaciones_automaticas():
	# Notificación al cliente
	programar_notificacion_cliente()
	
	# Notificaciones internas
	programar_recordatorios_equipo()
	
	# Alertas gerenciales
	programar_alertas_gerenciales()

func programar_notificacion_cliente():
	# Esta función configura las plantillas, pero no las ejecuta directamente
	# La implementación real dependería de tu sistema de scheduling
	pass

func enviar_notificacion_multicanal(destinatario: Dictionary, mensaje: String, urgencia: String):
	# Email
	if destinatario.has("email") and destinatario["email"] != "":
		enviar_email(destinatario["email"], mensaje, urgencia)
	
	# SMS
	if destinatario.has("telefono") and urgencia == "alta":
		enviar_sms(destinatario["telefono"], mensaje.substr(0, 160))
	
	# Notificación en app
	if destinatario.has("usuario_app"):
		enviar_push_notification(destinatario["usuario_app"], mensaje)
	
	# WhatsApp Business
	if destinatario.has("whatsapp") and tiene_whatsapp_business():
		enviar_whatsapp_template(destinatario["whatsapp"], "actualizacion_queja", {
			"numero_caso": "{NUMERO_CASO}",
			"estado": "{ESTADO}"
		})


func generar_reporte_calidad_servicio(periodo: Dictionary):
	var reporte = {}
	
	# 1. Indicadores clave
	var sql_kpis = """
		SELECT
			COUNT(*) as total_quejas,
			COUNT(CASE WHEN estado = 'resuelta' THEN 1 END) as resueltas,
			COUNT(CASE WHEN fecha_cierre <= fecha_limite_respuesta THEN 1 END) as a_tiempo,
			AVG(satisfaccion_cliente) as satisfaccion_promedio,
			SUM(compensacion_otorgada) as costo_total,
			COUNT(CASE WHEN reincidente = 1 THEN 1 END) as reincidentes
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN '%s' AND '%s'
	""" % [periodo["desde"], periodo["hasta"]]
	
	var resultado_kpis = bd.query(sql_kpis)
	if resultado_kpis is Array and resultado_kpis.size() > 0:
		reporte["kpis"] = resultado_kpis[0]
	else:
		reporte["kpis"] = {}
	
	# 2. Análisis por categoría
	var sql_categoria = """
		SELECT
			categoria,
			COUNT(*) as cantidad,
			AVG(tiempo_respuesta_horas) as tiempo_promedio,
			AVG(satisfaccion_cliente) as satisfaccion,
			SUM(compensacion_otorgada) as costo
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN '%s' AND '%s'
		GROUP BY categoria
		ORDER BY cantidad DESC
	""" % [periodo["desde"], periodo["hasta"]]
	
	var resultado_categoria = bd.query(sql_categoria)
	if resultado_categoria is Array:
		reporte["por_categoria"] = resultado_categoria
	else:
		reporte["por_categoria"] = []
	
	# 3. Análisis de causas raíz
	var sql_causas = """
		SELECT
			qr.categoria,
			qr.subcategoria,
			COUNT(*) as frecuencia,
			GROUP_CONCAT(DISTINCT qr.responsable_interno) as responsables,
			GROUP_CONCAT(DISTINCT qr.producto_servicio) as productos_afectados
		FROM quejas_reclamaciones qr
		LEFT JOIN medidas m ON qr.id = m.incidencia_id
		WHERE qr.fecha_recepcion BETWEEN '%s' AND '%s'
		AND m.tipo = 'accion_correctiva'
		GROUP BY qr.categoria, qr.subcategoria
		HAVING COUNT(*) > 1
		ORDER BY frecuencia DESC
	""" % [periodo["desde"], periodo["hasta"]]
	
	var resultado_causas = bd.query(sql_causas)
	if resultado_causas is Array:
		reporte["analisis_causas"] = resultado_causas
	else:
		reporte["analisis_causas"] = []
	
	# 4. Eficiencia por canal
	var sql_canal = """
		SELECT
			canal_entrada,
			COUNT(*) as cantidad,
			AVG(tiempo_respuesta_horas) as tiempo_respuesta,
			AVG(satisfaccion_cliente) as satisfaccion
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN '%s' AND '%s'
		GROUP BY canal_entrada
		ORDER BY cantidad DESC
	""" % [periodo["desde"], periodo["hasta"]]
	
	var resultado_canal = bd.query(sql_canal)
	if resultado_canal is Array:
		reporte["por_canal"] = resultado_canal
	else:
		reporte["por_canal"] = []
	
	# 5. Clientes recurrentes
	var sql_clientes = """
		SELECT
			identificacion,
			nombres || ' ' || apellidos as cliente,
			COUNT(*) as total_quejas,
			SUM(monto_reclamado) as total_reclamado,
			SUM(compensacion_otorgada) as total_compensado,
			AVG(satisfaccion_cliente) as satisfaccion_promedio
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN '%s' AND '%s'
		AND identificacion != ''
		GROUP BY identificacion
		HAVING COUNT(*) > 2
		ORDER BY total_quejas DESC
	""" % [periodo["desde"], periodo["hasta"]]
	
	var resultado_clientes = bd.query(sql_clientes)
	if resultado_clientes is Array:
		reporte["clientes_recurrentes"] = resultado_clientes
	else:
		reporte["clientes_recurrentes"] = []
	
	# 6. Análisis económico
	var sql_economico = """
		SELECT
			strftime('%%Y-%%m', fecha_recepcion) as mes,
			SUM(monto_reclamado) as total_reclamado,
			SUM(compensacion_otorgada) as total_compensado,
			COUNT(*) as cantidad,
			AVG(compensacion_otorgada) as promedio_por_queja
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN '%s' AND '%s'
		GROUP BY strftime('%%Y-%%m', fecha_recepcion)
		ORDER BY mes
	""" % [periodo["desde"], periodo["hasta"]]
	
	var resultado_economico = bd.query(sql_economico)
	if resultado_economico is Array:
		reporte["analisis_economico"] = resultado_economico
	else:
		reporte["analisis_economico"] = []
	
	return reporte
