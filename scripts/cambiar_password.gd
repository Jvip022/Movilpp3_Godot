# cambiar_password.gd
extends Control

@onready var current_password = $Panel/MarginContainer/VBoxContainer/CurrentPasswordContainer/CurrentPassword
@onready var new_password = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/NewPassword
@onready var confirm_password = $Panel/MarginContainer/VBoxContainer/ConfirmPasswordContainer/ConfirmPassword
@onready var strength_bar = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthBar
@onready var strength_text = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthText
@onready var status_message = $Panel/MarginContainer/VBoxContainer/StatusMessage
@onready var success_dialog = $SuccessDialog
@onready var error_dialog = $ErrorDialog
@onready var btn_cancelar = $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCancelar  # Añadido referencia directa

var current_user_id = 0
var password_min_length = 8

func _ready():
	print("Inicializando escena Cambiar Password...")
	
	# Asegurarse de que los nodos existen
	if not btn_cancelar:
		print("ERROR: BtnCancelar no encontrado en la ruta esperada")
		# Buscar el botón en toda la escena
		btn_cancelar = find_child("BtnCancelar", true, false)
		if btn_cancelar:
			print("BtnCancelar encontrado por búsqueda")
		else:
			print("ERROR: BtnCancelar no existe en la escena")
			return
	
	# Conectar señales con verificación
	if $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCambiar:
		$Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCambiar.button_up.connect(_on_cambiar_pressed)
		print("BtnCambiar conectado")
	else:
		print("ERROR: BtnCambiar no encontrado")
	
	if btn_cancelar:
		# Usar pressed en lugar de button_up para mayor compatibilidad
		btn_cancelar.pressed.connect(_on_cancelar_pressed)
		print("BtnCancelar conectado exitosamente")
	
	# Conectar para validación en tiempo real
	if new_password:
		new_password.text_changed.connect(_on_new_password_changed)
	
	if confirm_password:
		confirm_password.text_changed.connect(_on_confirm_password_changed)
	
	# Obtener ID del usuario actual
	current_user_id = get_current_user_id()

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
			# Crear estilo de error dinámicamente
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
			# Restaurar estilo normal
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
	
	# Método 1: Usar SceneManager (recomendado si está configurado)
	if has_node("/root/SceneManager"):
		print("Usando SceneManager para regresar al menú...")
		get_node("/root/SceneManager").change_scene_to("menu_principal")
		return
	
	# Método 2: Cambiar escena directamente
	var ruta_menu = "res://scenes/menu_principal.tscn"
	
	# Verificar si la escena existe
	if ResourceLoader.exists(ruta_menu):
		print("Cambiando a: " + ruta_menu)  # CORRECCIÓN: Usar concatenación
		get_tree().change_scene_to_file(ruta_menu)
	else:
		# Intentar con otra ruta común
		var ruta_alternativa = "res://escenas/menu_principal.tscn"
		if ResourceLoader.exists(ruta_alternativa):
			print("Cambiando a ruta alternativa: " + ruta_alternativa)  # CORRECCIÓN: Usar concatenación
			get_tree().change_scene_to_file(ruta_alternativa)
		else:
			print("ERROR: No se encontró la escena del menú principal")
			show_error("No se pudo regresar al menú principal.\nContacte al administrador.")

func get_current_user_id() -> int:
	# Aquí deberías obtener el ID del usuario actual desde tu sistema de autenticación
	return 1  # ID por defecto

func verify_current_password(_password: String) -> bool:
	# Aquí iría la lógica para verificar la contraseña actual con la base de datos
	return true  # Simulación

func change_password(_new_password_text: String) -> bool:
	# Aquí iría la lógica para actualizar la contraseña en la base de datos
	print("Contraseña cambiada para usuario ID: ", current_user_id)
	return true  # Simulación

func show_error(message: String):
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
	status_message.text = "Error: " + message
	status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
