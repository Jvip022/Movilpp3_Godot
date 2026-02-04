extends Node

var current_user = {
	"username": "",
	"role": "",
	"permissions": []
}

func login(username: String, password: String) -> bool:
	# Lógica de autenticación
	# Asignar rol y permisos
	return true

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
