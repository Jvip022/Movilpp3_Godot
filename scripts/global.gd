extends Node

# Datos del usuario actual
var usuario_actual = null

# Configuración de la aplicación
var config = {
	"tema_oscuro": false,
	"idioma": "es",
	"notificaciones": true
}

# Datos de la sesión
var token_sesion = ""
var tiempo_inicio_sesion = 0

func _ready():
	# Inicializar variables globales
	cargar_configuracion()

func cargar_configuracion():
	var file = FileAccess.open("user://config.json", FileAccess.READ)
	if file:
		var contenido = file.get_as_text()
		config = JSON.parse_string(contenido)
		file.close()

func guardar_configuracion():
	var file = FileAccess.open("user://config.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(config))
	file.close()

func esta_autenticado() -> bool:
	return usuario_actual != null

func obtener_rol() -> String:
	if usuario_actual and usuario_actual.has("rol"):
		return usuario_actual["rol"]
	return "invitado"

func cerrar_sesion():
	usuario_actual = null
	token_sesion = ""
	
	# Guardar configuración
	guardar_configuracion()
	
	# Volver a pantalla de login
	get_tree().change_scene_to_file("res://PantallaLogin.tscn")
