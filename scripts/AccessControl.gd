extends Control

@export var escena_requerida: String
@export var roles_permitidos: Array[String] = []

func _ready():
	verificar_acceso()

func verificar_acceso():
	if not AuthManager.is_authenticated():
		get_tree().change_scene_to_file("res://PantallaLogin.tscn")
		return
	
	var user_role = AuthManager.get_user_role()
	var tiene_acceso = false
	
	if roles_permitidos.size() > 0:
		tiene_acceso = user_role in roles_permitidos or user_role == "Administrador"
	else:
		# Si no se especifican roles, usar los predeterminados
		tiene_acceso = AuthManager.has_permission(escena_requerida)
	
	if not tiene_acceso:
		show_access_denied()
		return
	
	# Si tiene acceso, continuar con la inicialización normal
	initialize_scene()

func show_access_denied():
	var dialog = AcceptDialog.new()
	dialog.title = "Acceso Denegado"
	dialog.dialog_text = "No tiene permisos para acceder a esta función.\n\nRol actual: " + AuthManager.get_user_role()
	dialog.size = Vector2(400, 200)
	add_child(dialog)
	dialog.popup_centered()
	
	await dialog.confirmed
	get_tree().change_scene_to_file("res://menu_Principal.tscn")

func initialize_scene():
	# Método a sobrescribir en cada escena
	pass
