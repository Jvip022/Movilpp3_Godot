extends Node
# Sistema completo de gestión de quejas
class_name GestorQuejas

var bd = Bd.db

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
	
	# === ETAPA 2: VALIDACIÓN Y ASIGNACIÓN ===
	validar_documentacion(id_queja)
	asignar_queja(id_queja, "supervisor_calidad", 2)  # Nivel 2: Supervisor
	
	# === ETAPA 3: INVESTIGACIÓN TÉCNICA ===
	var resultado_investigacion = investigar_queja(id_queja, {
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
	var id_compensacion = aprobar_compensacion(id_queja, {
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
		"monto_reclamado": datos.get("monto_reclamado", 0),
		"tipo_compensacion": datos.get("tipo_compensacion", "ninguna"),
		
		"canal_entrada": datos.get("canal_entrada", "presencial"),
		"recibido_por": datos.get("recibido_por", "sistema"),
		"prioridad": calcular_prioridad(datos),
		"estado": "recibida",
		"fecha_limite_respuesta": datos.get("fecha_limite_respuesta", calcular_fecha_limite()),
		
		"creado_por": datos.get("creado_por", "sistema"),
		"tags": JSON.stringify(datos.get("tags", []))
	}
	
	# Insertar en base de datos
	var id_queja_local = Bd.insert("quejas_reclamaciones", queja)
	
	# Registrar en historial
	registrar_historial_queja(id_queja_local, "queja_registrada", 
		"Queja registrada por " + queja["recibido_por"])
	
	# Notificar al equipo asignado
	notificar_nueva_queja(id_queja_local, queja["prioridad"])
	
	return id_queja_local

func generar_numero_caso() -> String:
		var year = Time.get_date_string_from_system().substr(0, 4)
	# Usar BD singleton para la consulta
		var result = Bd.query("SELECT COUNT(*) as total FROM quejas_reclamaciones WHERE strftime('%Y', fecha_recepcion) = ?", [year])
		var numero = 1
		if result and result.size() > 0:
			numero = result[0]["total"] + 1
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
		"fecha_aprobacion": Time.get_date_string_from_system(),
		"nivel_aprobacion": nivel_requerido
	}
	
	var id_compensacion_local = insertar("compensaciones", compensacion)
	
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

# Las siguientes funciones deben ser implementadas según tu lógica específica
func calcular_prioridad(datos: Dictionary) -> String:
	# Implementa tu lógica de prioridad aquí
	return "media"

func calcular_fecha_limite() -> String:
	# Implementa tu lógica para calcular fecha límite
	return ""

func insertar(tabla: String, datos: Dictionary) -> int:
	# Implementa tu lógica de inserción en BD
	return 1

func registrar_historial_queja(id_queja: int, evento: String, descripcion: String):	
	"""
	Registra un evento en el historial de la queja.
	"""
	var historial = {
		"queja_id": id_queja,
		"evento": evento,
		"descripcion": descripcion,
		"fecha": Time.get_datetime_string_from_system(),
		"usuario": "sistema"  # En un sistema real, obtendrías el usuario actual
	}
	
	# Insertar en la tabla de historial (debes crearla)
	print("📝 Historial: " + evento + " - " + descripcion)
	
	# Hay una tabla para historial, descomenta:?
	Bd.insert("historial_quejas", historial)
	pass

func notificar_nueva_queja(id_queja: int, prioridad: String):
	# Implementa tu lógica de notificación
	pass

func validar_documentacion(id_queja: int):
	pass

func asignar_queja(id_queja: int, asignado_a: String, nivel: int):
	pass

func investigar_queja(id_queja: int, datos: Dictionary):
	pass

func registrar_contacto_cliente(id_queja: int, datos: Dictionary):
	pass

func realizar_encuesta_satisfaccion(id_queja: int, datos: Dictionary):
	pass

func cerrar_queja(id_queja: int, responsable: String, datos: Dictionary):
	pass

func actualizar_analisis_tendencias(id_queja: int):
	pass

func obtener_queja_por_id(id_queja: int):
	return null

func obtener_supervisor_disponible():
	return ""

func obtener_gerente_area(categoria: String):
	return ""

func obtener_contacto_legal():
	return ""

func actualizar_campo(id_queja: int, campo: String, valor):
	pass

func generar_comprobante_compensacion(id_compensacion: int):
	pass


func notificar_escalamiento(id_queja: int, responsable: String, motivo: String, urgente: bool = false):
	"""
	Notifica sobre el escalamiento de una queja a diferentes niveles.
	
	Args:
		id_queja: ID de la queja escalada
		responsable: Persona/departamento asignado
		motivo: Razón del escalamiento
		urgente: Si requiere atención inmediata
	"""
	
	# Obtener información de la queja
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
		# Notificación urgente (múltiples canales)
		print("=== NOTIFICACIÓN URGENTE ===")
		print(mensaje)
		
		# Enviar por correo (simulado)
		enviar_notificacion_email(responsable, "Escalamiento Urgente - Caso " + numero_caso, mensaje)
		
		# Registrar alerta en sistema
		registrar_alerta_sistema(id_queja, "escalamiento_urgente", mensaje)
		
		# Puedes agregar notificaciones push o SMS aquí
		enviar_notificacion_push(responsable, "Queja escalada urgentemente - " + numero_caso)
	else:
		# Notificación normal
		print("=== Notificación de Escalamiento ===")
		print(mensaje)
		
		# Enviar por correo (simulado)
		enviar_notificacion_email(responsable, "Nueva queja asignada - Caso " + numero_caso, mensaje)
	
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
	En un sistema real, aquí integrarías con un servicio de email.
	"""
	# En desarrollo, solo mostramos en consola
	print("   Email enviado a: " + destinatario)
	print("   Asunto: " + asunto)
	print("   Mensaje: " + mensaje.substr(0, 100) + "...")
	
	# Aquí iría el código real para enviar email
	# Ejemplo con SMTP:
	# var email = Email.new()
	# email.send(destinatario, asunto, mensaje)

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
	
	# Insertar en tabla de alertas (debes crear esta tabla)
	#Bd.insert("alertas_sistema", alerta)
	print(" Alerta registrada en sistema: " + tipo_alerta)
