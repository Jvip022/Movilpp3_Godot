extends Node

var current_user = {
	"username": "",
	"role": "",
	"permissions": []
}

func login(_username: String, _password: String) -> bool:
	# Lógica de autenticación
	# Asignar rol y permisos
	
	# EJEMPLO: Para propósitos de desarrollo
	# En producción, esto debería validar contra una base de datos o servicio
	current_user["username"] = _username
	current_user["role"] = "Usuario"  # Rol por defecto
	current_user["permissions"] = []
	
	# Simulación básica (eliminar en producción)
	if _username == "admin" and _password == "admin123":
		current_user["role"] = "Administrador"
		current_user["permissions"] = ["all"]
	elif _username == "supervisor" and _password == "super123":
		current_user["role"] = "Supervisor General"
		current_user["permissions"] = ["incidencias", "reportes"]
	
	return current_user["username"] != ""

func get_user_role() -> String:
	return current_user["role"]

func has_permission(scene_name: String) -> bool:
	var scene_permissions = {
		"AdministrarUsuarios": ["Administrador"],
		"VisualizarTrazas": ["Administrador"],
		"RegistrarIncidencia": ["Supervisor General", "Administrador"],
		"GestorQuejas": ["Especialista Calidad Sucursal", "Administrador"],
		"RegistrarNCAuditoria": ["Auditor", "Administrador"],
		"RegistrarEncuesta": ["Especialista Calidad Sucursal", "Administrador"],
		"ProcesarExpediente": ["Especialista Calidad Sucursal", "Administrador"],
		"GenerarReportes": ["Usuario", "Administrador"],
		"AccionesCorrectivas": ["Supervisor General", "Administrador"]
	}
	
	var user_role = get_user_role()
	var allowed_roles = scene_permissions.get(scene_name, [])
	
	return user_role in allowed_roles

func is_authenticated() -> bool:
	return current_user["username"] != ""

func logout() -> void:
	# Limpiar datos del usuario al cerrar sesión
	current_user["username"] = ""
	current_user["role"] = ""
	current_user["permissions"] = []
