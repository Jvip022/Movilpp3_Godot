extends Node

#class_name Global

# Variable global para el usuario
var usuario_actual = null

# Instancia única (singleton)
static var instance: Global = null

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	print("Sistema Global inicializado")
	
	# Cargar configuración
	cargar_configuracion()

func cargar_configuracion():
	var config = ConfigFile.new()
	if config.load("user://config.cfg") == OK:
		print("Configuración cargada")
	else:
		print("Creando configuración por defecto")
		# Configuración por defecto
		config.set_value("app", "version", "1.0")
		config.save("user://config.cfg")

# Métodos de utilidad
func esta_autenticado() -> bool:
	return usuario_actual != null

func obtener_rol() -> String:
	if usuario_actual and usuario_actual.has("rol"):
		return usuario_actual["rol"]
	return "invitado"

func cerrar_sesion():
	usuario_actual = null
	print("Sesión cerrada")
	
	# Cambiar a pantalla de login
	get_tree().change_scene_to_file("res://escenas/autentificar.tscn")
