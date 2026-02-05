# cambiar_password.gd (versión corregida)
extends Control

@onready var current_password = $Panel/MarginContainer/VBoxContainer/CurrentPasswordContainer/CurrentPassword
@onready var new_password = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/NewPassword
@onready var confirm_password = $Panel/MarginContainer/VBoxContainer/ConfirmPasswordContainer/ConfirmPassword
@onready var strength_bar = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthBar
@onready var strength_text = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthText
@onready var status_message = $Panel/MarginContainer/VBoxContainer/StatusMessage
@onready var success_dialog = $SuccessDialog
@onready var error_dialog = $ErrorDialog
@onready var btn_cancelar = $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCancelar

# Referencia a la base de datos
var bd: BD
var current_user_id = 0
var current_username = ""
var password_min_length = 8

func _ready():
	print("Inicializando escena Cambiar Password...")
	
	# Obtener referencia a la base de datos
	bd = get_node("/root/Bd")
	if not bd:
		print("ERROR: No se encontró el nodo BD en la raíz")
		bd = get_node("/root/SceneManager/Bd")  
		if not bd:
			push_error("CRÍTICO: No se puede acceder a la base de datos")
			return
	print("✅ Base de datos conectada")
	
	# Asegurarse de que los nodos existen
	if not btn_cancelar:
		print("ERROR: BtnCancelar no encontrado en la ruta esperada")
		btn_cancelar = find_child("BtnCancelar", true, false)
		if btn_cancelar:
			print("BtnCancelar encontrado por búsqueda")
		else:
			print("ERROR: BtnCancelar no existe en la escena")
			return
	
	# Conectar señales
	if $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCambiar:
		$Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCambiar.button_up.connect(_on_cambiar_pressed)
		print("BtnCambiar conectado")
	else:
		print("ERROR: BtnCambiar no encontrado")
	
	if btn_cancelar:
		btn_cancelar.pressed.connect(_on_cancelar_pressed)
		print("BtnCancelar conectado exitosamente")
	
	# Conectar para validación en tiempo real
	if new_password:
		new_password.text_changed.connect(_on_new_password_changed)
	
	if confirm_password:
		confirm_password.text_changed.connect(_on_confirm_password_changed)
	
	# Obtener datos del usuario actual
	current_user_id = get_current_user_id()
	current_username = get_current_username()
	
	print("Usuario actual: ID=", current_user_id, ", Username=", current_username)

func get_current_user_id() -> int:
	# Esta función debe obtener el ID del usuario actualmente autenticado
	# Por ahora, devolveremos 1 (admin) como ejemplo
	return 1

func get_current_username() -> String:
	# Obtener el nombre de usuario actual
	# Por ahora, devolveremos "admin" como ejemplo
	return "admin"

func _on_new_password_changed(new_text):
	update_password_strength(new_text)
	validate_passwords()

func _on_confirm_password_changed(_new_text):
	validate_passwords()

func update_password_strength(password: String):
	var score = 0
	
	# Longitud
	if password.length() >= password_min_length:
		score += 25
	if password.length() >= 12:
		score += 15
	
	# Diferentes tipos de caracteres
	if password.matchn(".*[A-Z].*"):
		score += 20
	if password.matchn(".*[a-z].*"):
		score += 20
	if password.matchn(".*[0-9].*"):
		score += 20
	if password.matchn(".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?].*"):
		score += 20
	
	strength_bar.value = min(score, 100)
	
	# Actualizar texto y colores
	if score < 40:
		strength_text.text = "Débil"
		strength_text.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
		strength_bar.add_theme_color_override("fill_color", Color(0.8, 0.2, 0.2, 1))
	elif score < 70:
		strength_text.text = "Media"
		strength_text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2, 1))
		strength_bar.add_theme_color_override("fill_color", Color(0.8, 0.8, 0.2, 1))
	else:
		strength_text.text = "Fuerte"
		strength_text.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
		strength_bar.add_theme_color_override("fill_color", Color(0.2, 0.8, 0.2, 1))

func validate_passwords():
	var new_pass = new_password.text
	var confirm_pass = confirm_password.text
	
	# Validar que las contraseñas coincidan
	if new_pass != "" and confirm_pass != "":
		if new_pass != confirm_pass:
			var error_style = StyleBoxFlat.new()
			error_style.bg_color = Color(1, 0.9, 0.9, 1)
			error_style.border_color = Color(1, 0.5, 0.5, 1)
			error_style.border_width_left = 2
			error_style.border_width_top = 2
			error_style.border_width_right = 2
			error_style.border_width_bottom = 2
			error_style.corner_radius_top_left = 5
			error_style.corner_radius_top_right = 5
			error_style.corner_radius_bottom_right = 5
			error_style.corner_radius_bottom_left = 5
			
			confirm_password.add_theme_stylebox_override("normal", error_style)
			status_message.text = "Las contraseñas no coinciden"
			status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
			return false
		else:
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(1, 1, 1, 1)
			normal_style.border_color = Color(0.7, 0.7, 0.7, 1)
			normal_style.border_width_left = 1
			normal_style.border_width_top = 1
			normal_style.border_width_right = 1
			normal_style.border_width_bottom = 1
			normal_style.corner_radius_top_left = 5
			normal_style.corner_radius_top_right = 5
			normal_style.corner_radius_bottom_right = 5
			normal_style.corner_radius_bottom_left = 5
			
			confirm_password.add_theme_stylebox_override("normal", normal_style)
			status_message.text = "Contraseñas coinciden"
			status_message.add_theme_color_override("font_color", Color(0.2, 0.4, 0.2, 1))
			return true
	
	return false

func _on_cambiar_pressed():
	# Validaciones
	if current_password.text.strip_edges() == "":
		show_error("Ingrese su contraseña actual")
		return
	
	if new_password.text.strip_edges() == "":
		show_error("Ingrese la nueva contraseña")
		return
	
	if confirm_password.text.strip_edges() == "":
		show_error("Confirme la nueva contraseña")
		return
	
	if not validate_passwords():
		show_error("Las contraseñas no coinciden")
		return
	
	if new_password.text.length() < password_min_length:
		show_error("La contraseña debe tener al menos " + str(password_min_length) + " caracteres")
		return
	
	# Verificar fortaleza mínima
	var score = strength_bar.value
	if score < 40:
		show_error("La contraseña es muy débil. Use mayúsculas, minúsculas y números")
		return
	
	# Verificar contraseña actual
	if not verify_current_password(current_password.text):
		show_error("Contraseña actual incorrecta")
		return
	
	# Cambiar contraseña
	if change_password(new_password.text):
		# Registrar en auditoría
		if bd:
			bd.registrar_auditoria(current_user_id, "CAMBIO_PASSWORD", "cambiar_password", "Usuario cambió su contraseña")
		
		success_dialog.dialog_text = "Contraseña cambiada exitosamente"
		success_dialog.popup_centered()
		status_message.text = "Contraseña actualizada correctamente"
		
		# Limpiar campos después de éxito
		await get_tree().create_timer(2.0).timeout
		_on_cancelar_pressed()
	else:
		show_error("Error al cambiar la contraseña")

func _on_cancelar_pressed():
	print("Botón Cancelar presionado - Regresando al menú principal...")
	
	# Método 1: Usar SceneManager
	if has_node("/root/SceneManager"):
		print("Usando SceneManager para regresar al menú...")
		get_node("/root/SceneManager").change_scene_to("menu_principal")
		return
	
	# Método 2: Cambiar escena directamente
	var ruta_menu = "res://scenes/menu_principal.tscn"
	
	if ResourceLoader.exists(ruta_menu):
		print("Cambiando a: ", ruta_menu)
		get_tree().change_scene_to_file(ruta_menu)
	else:
		var ruta_alternativa = "res://escenas/menu_principal.tscn"
		if ResourceLoader.exists(ruta_alternativa):
			print("Cambiando a ruta alternativa: ", ruta_alternativa)
			get_tree().change_scene_to_file(ruta_alternativa)
		else:
			print("ERROR: No se encontró la escena del menú principal")
			show_error("No se pudo regresar al menú principal.\nContacte al administrador.")

# VERIFICAR CONTRASEÑA ACTUAL CON LA BASE DE DATOS
func verify_current_password(password: String) -> bool:
	if not bd:
		show_error("Error de conexión a la base de datos")
		return false
	
	# Buscar usuario en ambas tablas (antigua y nueva)
	
	# 1. Primero en tabla nueva (usuarios_nueva)
	var sql_nueva = "SELECT password_hash FROM usuarios_nueva WHERE id = ? OR username = ?"
	var resultado_nueva = bd.select_query(sql_nueva, [current_user_id, current_username])
	
	if resultado_nueva and resultado_nueva.size() > 0:
		var hash_almacenado = resultado_nueva[0].get("password_hash", "")
		# Comparación simple (en producción debería ser con hash)
		return hash_almacenado == password
	
	# 2. Si no existe en tabla nueva, buscar en tabla antigua (usuarios)
	var sql_antigua = "SELECT password_hash FROM usuarios WHERE id = ? OR username = ?"
	var resultado_antigua = bd.select_query(sql_antigua, [current_user_id, current_username])
	
	if resultado_antigua and resultado_antigua.size() > 0:
		var hash_almacenado = resultado_antigua[0].get("password_hash", "")
		# Comparación simple (en producción debería ser con hash)
		return hash_almacenado == password
	
	return false

# CAMBIAR CONTRASEÑA EN LA BASE DE DATOS
func change_password(new_password_text: String) -> bool:
	if not bd:
		show_error("Error de conexión a la base de datos")
		return false
	
	# Encriptar la contraseña (en producción usar un método seguro como bcrypt)
	# Por ahora, guardaremos en texto plano (solo para desarrollo)
	var password_hash = new_password_text  # En producción: hash_password(new_password_text)
	
	# Actualizar en ambas tablas para consistencia
	
	# 1. Actualizar tabla nueva
	var update_nueva = "UPDATE usuarios_nueva SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? OR username = ?"
	var success_nueva = bd.query(update_nueva, [password_hash, current_user_id, current_username])
	
	# 2. Actualizar tabla antigua
	var update_antigua = "UPDATE usuarios SET password_hash = ?, fecha_modificacion = CURRENT_TIMESTAMP WHERE id = ? OR username = ?"
	var success_antigua = bd.query(update_antigua, [password_hash, current_user_id, current_username])
	
	# También actualizar el campo requiere_cambio_password si existe
	var update_requiere = "UPDATE usuarios SET requiere_cambio_password = 0 WHERE id = ?"
	bd.query(update_requiere, [current_user_id])
	
	return success_nueva or success_antigua  # Éxito si al menos una se actualizó

# Función auxiliar para hashear contraseñas (implementar en producción)
func hash_password(password: String) -> String:
	# Implementar hashing seguro (bcrypt, PBKDF2, etc.)
	# Por ahora, devolver SHA256 como ejemplo
	return password.sha256_text()

func show_error(message: String):
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
	status_message.text = "Error: " + message
	status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
