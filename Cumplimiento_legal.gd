extends Node
# Sistema de cumplimiento regulatorio
class_name CumplimientoLegal

func verificar_cumplimiento_ley(queja_id: int):
	var queja = obtener_queja_por_id(queja_id)
	var incumplimientos = []
	
	# Verificar plazos máximos según ley
	var dias_abierto = calcular_dias_abierta(queja)
	if dias_abierto > 30:  # Ley establece máximo 30 días
		incumplimientos.append("Excede plazo máximo de respuesta (30 días)")
	
	# Verificar monto mínimo para reclamo formal
	if queja["monto_reclamado"] > 1000 and queja["numero_expediente_legal"] == "":
		incumplimientos.append("Reclamo mayor a $1000 requiere expediente legal")
	
	# Verificar documentación obligatoria
	if queja["monto_reclamado"] > 500:
		var docs = obtener_documentos_queja(queja_id)
		var tiene_factura = false
		for doc in docs:
			if doc["tipo_documento"] == "factura":
				tiene_factura = true
		
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
		notificar_riesgo_legal(queja["asignado_a"], reporte)
	
	return reporte

func generar_carta_respuesta_legal(queja_id: int):
	var queja = obtener_queja_por_id(queja_id)
	var plantilla = cargar_plantilla_legal()
	
	var carta = plantilla.replace("{NUMERO_CASO}", queja["numero_caso"])
	carta = carta.replace("{FECHA}", Time.get_date_string_from_system())
	carta = carta.replace("{RECLAMANTE}", queja["nombres"] + " " + queja["apellidos"])
	carta = carta.replace("{ASUNTO}", queja["asunto"])
	
	# Agregar base legal según país
	var leyes_aplicables = identificar_leyes_aplicables(queja)
	carta = carta.replace("{LEYES}", leyes_aplicables)
	
	# Firmas digitales
	carta = carta.replace("{FIRMA_RESPONSABLE}", obtener_firma_digital(queja["asignado_a"]))
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
	# Al registrar queja
	var plantilla = """
		Estimado/a {NOMBRES},
    
		Hemos recibido su {TIPO_CASO} número {NUMERO_CASO}.
		Asunto: {ASUNTO}
    
		Nuestro equipo la revisará y le dará una respuesta antes del {FECHA_LIMITE}.
    
		Puede seguir el estado en: {ENLACE_SEGUIMIENTO}
    
		Saludos,
		Departamento de Atención al Cliente
		"""
	
	# Al resolver queja
	var plantilla_resolucion = """
		Buenas noticias!
    
		Su caso {NUMERO_CASO} ha sido resuelto.
		Decisión: {DECISION}
		Compensación: {COMPENSACION}
    
		{ENCUESTA_SATISFACCION}
    
		Agradecemos su paciencia.
		"""

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
	reporte["kpis"] = db.query("""
		SELECT
			COUNT(*) as total_quejas,
			COUNT(CASE WHEN estado = 'resuelta' THEN 1 END) as resueltas,
			COUNT(CASE WHEN fecha_cierre <= fecha_limite_respuesta THEN 1 END) as a_tiempo,
			AVG(satisfaccion_cliente) as satisfaccion_promedio,
			SUM(compensacion_otorgada) as costo_total,
			COUNT(CASE WHEN reincidente = 1 THEN 1 END) as reincidentes
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN ? AND ?
	""", [periodo["desde"], periodo["hasta"]])[0]
	
	# 2. Análisis por categoría
	reporte["por_categoria"] = db.query("""
		SELECT
			categoria,
			COUNT(*) as cantidad,
			AVG(tiempo_respuesta_horas) as tiempo_promedio,
			AVG(satisfaccion_cliente) as satisfaccion,
			SUM(compensacion_otorgada) as costo
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN ? AND ?
		GROUP BY categoria
		ORDER BY cantidad DESC
	""", [periodo["desde"], periodo["hasta"]])
	
	# 3. Análisis de causas raíz
	reporte["analisis_causas"] = db.query("""
		SELECT
			qr.categoria,
			qr.subcategoria,
			COUNT(*) as frecuencia,
			GROUP_CONCAT(DISTINCT qr.responsable_interno) as responsables,
			GROUP_CONCAT(DISTINCT qr.producto_servicio) as productos_afectados
		FROM quejas_reclamaciones qr
		LEFT JOIN medidas m ON qr.id = m.incidencia_id
		WHERE qr.fecha_recepcion BETWEEN ? AND ?
		AND m.tipo = 'accion_correctiva'
		GROUP BY qr.categoria, qr.subcategoria
		HAVING COUNT(*) > 1
		ORDER BY frecuencia DESC
	""", [periodo["desde"], periodo["hasta"]])
	
	# 4. Eficiencia por canal
	reporte["por_canal"] = db.query("""
		SELECT
			canal_entrada,
			COUNT(*) as cantidad,
			AVG(tiempo_respuesta_horas) as tiempo_respuesta,
			AVG(satisfaccion_cliente) as satisfaccion
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN ? AND ?
		GROUP BY canal_entrada
		ORDER BY cantidad DESC
	""", [periodo["desde"], periodo["hasta"]])
	
	# 5. Clientes recurrentes
	reporte["clientes_recurrentes"] = db.query("""
		SELECT
			identificacion,
			nombres || ' ' || apellidos as cliente,
			COUNT(*) as total_quejas,
			SUM(monto_reclamado) as total_reclamado,
			SUM(compensacion_otorgada) as total_compensado,
			AVG(satisfaccion_cliente) as satisfaccion_promedio
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN ? AND ?
		AND identificacion != ''
		GROUP BY identificacion
		HAVING COUNT(*) > 2
		ORDER BY total_quejas DESC
	""", [periodo["desde"], periodo["hasta"]])
	
	# 6. Análisis económico
	reporte["analisis_economico"] = db.query("""
		SELECT
			strftime('%Y-%m', fecha_recepcion) as mes,
			SUM(monto_reclamado) as total_reclamado,
			SUM(compensacion_otorgada) as total_compensado,
			COUNT(*) as cantidad,
			AVG(compensacion_otorgada) as promedio_por_queja
		FROM quejas_reclamaciones
		WHERE fecha_recepcion BETWEEN ? AND ?
		GROUP BY strftime('%Y-%m', fecha_recepcion)
		ORDER BY mes
	""", [periodo["desde"], periodo["hasta"]])
	
	return reporte
