extends Node
class_name ConfigManager

# Configuración por defecto
var config_data = {}

func _ready():
	cargar_configuracion()

func cargar_configuracion():
	# Configuración por defecto
	config_data = {
		"notificaciones": true,
		"intervalo_actualizacion": 30.0,
		"prioridad_por_defecto": "media",
		"limite_tiempo_respuesta": 7,
		"registrar_todas_como_nc": false,
		"tiempo_maximo_resolucion": 72,  # horas
		"autoclasificar_prioridad": true,
		"generar_reportes_automaticos": true,
		"idioma": "es",
		"tema": "claro"
	}

func get_config_value(key: String, default_value = null):
	return config_data.get(key, default_value)

func set_config_value(key: String, value):
	config_data[key] = value
	# Aquí podrías guardar a archivo/BD si es necesario

# ================== MÉTODOS DE CONFIGURACIÓN ==================

func get_notificaciones() -> bool:
	return get_config_value("notificaciones", true)

func set_notificaciones(valor: bool):
	set_config_value("notificaciones", valor)

func get_intervalo_actualizacion() -> float:
	return get_config_value("intervalo_actualizacion", 30.0)

func set_intervalo_actualizacion(intervalo: float):
	set_config_value("intervalo_actualizacion", intervalo)

func get_prioridad_por_defecto() -> String:
	return get_config_value("prioridad_por_defecto", "media")

func get_limite_tiempo_respuesta() -> int:
	return get_config_value("limite_tiempo_respuesta", 7)

func get_registrar_todas_como_nc() -> bool:
	return get_config_value("registrar_todas_como_nc", false)

func set_registrar_todas_como_nc(valor: bool):
	set_config_value("registrar_todas_como_nc", valor)

# ================== MÉTODOS ADICIONALES ==================

func get_tiempo_maximo_resolucion() -> int:
	"""Retorna el tiempo máximo de resolución en horas"""
	return get_config_value("tiempo_maximo_resolucion", 72)

func get_autoclasificar_prioridad() -> bool:
	"""Retorna si se debe autoclasificar la prioridad"""
	return get_config_value("autoclasificar_prioridad", true)

func get_generar_reportes_automaticos() -> bool:
	"""Retorna si se generan reportes automáticos"""
	return get_config_value("generar_reportes_automaticos", true)

func get_idioma() -> String:
	"""Retorna el idioma del sistema"""
	return get_config_value("idioma", "es")

func get_tema() -> String:
	"""Retorna el tema de la interfaz"""
	return get_config_value("tema", "claro")

# ================== MÉTODOS PARA GESTIONAR CONFIGURACIÓN ==================

func guardar_configuracion():
	"""Guarda la configuración en un archivo"""
	var config_path = "user://config_sistema.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config_data))
		file.close()
		print("ConfigManager: Configuración guardada en " + config_path)
	else:
		print("ConfigManager: Error al guardar configuración")

func cargar_configuracion_desde_archivo():
	"""Carga la configuración desde un archivo"""
	var config_path = "user://config_sistema.json"
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(content)
		if parsed:
			config_data = parsed
			print("ConfigManager: Configuración cargada desde archivo")
		else:
			print("ConfigManager: Error al parsear configuración, usando valores por defecto")
	else:
		print("ConfigManager: Archivo de configuración no encontrado, usando valores por defecto")

# ================== MÉTODOS ESPECÍFICOS PARA QUEJAS ==================

func get_categorias_nc() -> Array:
	"""Retorna las categorías que deben registrar como No Conformidad"""
	return [
		"calidad_producto",
		"daños",
		"perdidas", 
		"privacidad",
		"plazos_entrega",
        "seguridad"
	]

func get_limite_monto_nc() -> float:
	"""Retorna el monto mínimo para registrar como NC"""
	return get_config_value("limite_monto_nc", 0.0)

func get_notificar_responsable_nc() -> bool:
	"""Retorna si se debe notificar al responsable de NC"""
	return get_config_value("notificar_responsable_nc", true)

# ================== MÉTODOS DE VALIDACIÓN ==================

func es_campo_obligatorio(seccion: String, campo: String) -> bool:
	"""Determina si un campo es obligatorio según la configuración"""
	var campos_obligatorios = {
		"queja": ["nombres", "asunto", "descripcion_detallada"],
		"reclamacion": ["nombres", "asunto", "descripcion_detallada", "monto_reclamado"]
	}
	
	if campos_obligatorios.has(seccion):
		return campo in campos_obligatorios[seccion]
	
	return false

func get_formato_fecha() -> String:
	"""Retorna el formato de fecha configurado"""
	return get_config_value("formato_fecha", "YYYY-MM-DD")

func get_zona_horaria() -> String:
	"""Retorna la zona horaria configurada"""
	return get_config_value("zona_horaria", "America/Lima")

# ================== MÉTODOS DE DEPURACIÓN ==================

func imprimir_configuracion():
	"""Imprime la configuración actual en consola"""
	print("=== CONFIGURACIÓN DEL SISTEMA ===")
	for key in config_data.keys():
		print("  %s: %s" % [key, config_data[key]])
	print("=================================")

func obtener_todas_configuraciones() -> Dictionary:
	"""Retorna todas las configuraciones como diccionario"""
	return config_data.duplicate()

func establecer_configuraciones_completas(nuevas_config: Dictionary):
	"""Establece múltiples configuraciones a la vez"""
	for key in nuevas_config.keys():
		config_data[key] = nuevas_config[key]
	guardar_configuracion()
