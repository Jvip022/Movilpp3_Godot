extends Node
class_name global

# Datos del usuario actual
var usuario_actual: Dictionary = {}

# Permisos del usuario
var permisos: Array = []

# Configuración del sistema
var config_sistema: Dictionary = {
	"modo_oscuro": false,
	"idioma": "es",
	"notificaciones": true
}

# Base de datos
var db: BD

func _ready():
	# Inicializar base de datos
	db = BD.new()
	db._ready()
	
	# Cargar sesión guardada
	cargar_sesion()

func esta_autenticado() -> bool:
	return not usuario_actual.is_empty()

func obtener_rol() -> String:
	return usuario_actual.get("rol", "")

func obtener_id_usuario() -> int:
	return usuario_actual.get("id", -1)

func cargar_sesion():
	var config = ConfigFile.new()
	if config.load("user://sesion.cfg") == OK:
		usuario_actual = config.get_value("sesion", "usuario", {})
		# También podrías cargar permisos si los guardas
		permisos = config.get_value("sesion", "permisos", [])

func guardar_sesion():
	var config = ConfigFile.new()
	config.set_value("sesion", "usuario", usuario_actual)
	config.set_value("sesion", "permisos", permisos)
	config.save("user://sesion.cfg")

func cerrar_sesion():
	usuario_actual = {}
	permisos.clear()
	
	# Eliminar archivo de sesión
	var dir = DirAccess.open("user://")
	if dir.file_exists("sesion.cfg"):
		dir.remove("sesion.cfg")
	
	# Cerrar base de datos
	if db:
		db.close()
	
	# Cargar escena de login
	get_tree().change_scene_to_file("res://escenas/login.tscn")

# Función para verificar permisos
func tiene_permiso(permiso: String) -> bool:
	if usuario_actual.is_empty():
		return false
	
	if usuario_actual.rol == "admin":
		return true
	
	# Aquí puedes agregar lógica más compleja de permisos
	match permiso:
		"ver_dashboard":
			return usuario_actual.rol in ["admin", "supervisor", "gerente"]
		"crear_queja":
			return usuario_actual.rol in ["admin", "operador", "supervisor"]
		"aprobar_compensacion":
			return usuario_actual.rol in ["admin", "supervisor", "gerente"]
		"ver_reportes":
			return usuario_actual.rol in ["admin", "analista", "gerente"]
		_:
			return false
