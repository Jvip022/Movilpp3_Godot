# ConfigManager.gd
extends Node
class_name ConfigManager

# Valores por defecto
var config = {
	"notificaciones": true,
	"intervalo_actualizacion": 30,
	"mostrar_alertas": true,
	"limite_tiempo_respuesta": 7,
	"prioridad_por_defecto": "media"
}

func get_notificaciones() -> bool:
	return config.get("notificaciones", true)

func set_notificaciones(valor: bool):
	config["notificaciones"] = valor

func get_intervalo_actualizacion() -> int:
	return config.get("intervalo_actualizacion", 30)

func set_intervalo_actualizacion(valor: int):
	config["intervalo_actualizacion"] = valor

func get_limite_tiempo_respuesta() -> int:
	return config.get("limite_tiempo_respuesta", 7)

func get_prioridad_por_defecto() -> String:
	return config.get("prioridad_por_defecto", "media")
