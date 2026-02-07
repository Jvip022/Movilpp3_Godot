extends Control

# Referencias a nodos UI
@onready var current_password = $Panel/MarginContainer/VBoxContainer/CurrentPasswordContainer/HBoxContainer/CurrentPassword
@onready var new_password = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/HBoxContainer2/NewPassword
@onready var confirm_password = $Panel/MarginContainer/VBoxContainer/ConfirmPasswordContainer/HBoxContainer3/ConfirmPassword
@onready var strength_bar = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthBar
@onready var strength_text = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthText
@onready var status_message = $Panel/MarginContainer/VBoxContainer/StatusMessage
@onready var success_dialog = $SuccessDialog
@onready var error_dialog = $ErrorDialog
@onready var btn_cambiar = $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCambiar
@onready var btn_cancelar = $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCancelar
@onready var password_requirements = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/PasswordRequirements
@onready var modo_seguro_toggle = $Panel/MarginContainer/VBoxContainer/ModoSeguroContainer/ModoSeguroToggle

# Botones para mostrar/ocultar contraseña
@onready var btn_show_current = $Panel/MarginContainer/VBoxContainer/CurrentPasswordContainer/HBoxContainer/BtnShowCurrent
@onready var btn_show_new = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/HBoxContainer2/BtnShowNew
@onready var btn_show_confirm = $Panel/MarginContainer/VBoxContainer/ConfirmPasswordContainer/HBoxContainer3/BtnShowConfirm

# Referencias a singletons
var global_node: Node
var bd: Node

# Configuración
var password_min_length = 8
var modo_seguro = true  # Por defecto activado

# Lista de contraseñas débiles prohibidas
var contrasenas_debiles = [
	"123", "1234", "12345", "123456", "1234567", "12345678", "123456789", "1234567890",
	"password", "password1", "password123", "admin", "admin123", "adminadmin",
	"qwerty", "qwerty123", "qwertyuiop",
	"abc123", "abc1234", "abc12345",
	"letmein", "welcome", "monkey", "dragon", "sunshine", "iloveyou", "princess",
	"football", "baseball", "superman", "batman", "starwars", "harley",
	"mustang", "shadow", "master", "jennifer", "jordan", "michael", "michelle",
	"charlie", "daniel", "matthew", "robert", "thomas", "andrew", "joshua",
	"ashley", "emily", "samantha", "jessica", "amanda", "sarah", "elizabeth",
	"111111", "222222", "333333", "444444", "555555", "666666", "777777", "888888", "999999", "000000",
	"123123", "321321", "654321", "123abc", "abcabc", "abcd1234",
	"pass", "pass123", "passw0rd", "p@ssw0rd", "p@ssword",
	"test", "test123", "testing", "testing123",
	"guest", "guest123", "user", "user123",
	"hello", "hello123", "welcome123",
	"secret", "secret123", "security", "security123",
	"root", "root123", "toor", "toor123",
	"login", "login123", "signin", "signin123",
	"changeme", "changeme123", "newpassword", "newpassword123",
	"temp", "temp123", "temporary", "temporary123"
]

func _ready():
	print("=== INICIALIZANDO CAMBIAR PASSWORD ===")
	
	# Verificar que los nodos críticos existan
	if not _verificar_nodos_ui():
		return
	
	# Obtener referencias a los singletons
	global_node = get_node("/root/Global")
	bd = get_node("/root/BD")
	
	# Verificar que los singletons existan
	if not await _verificar_singletons():
		return
	
	# Verificar si hay usuario autenticado
	if not await _verificar_autenticacion():
		return
	
	# Mostrar información del usuario
	_mostrar_info_usuario()
	
	# Configurar UI y señales
	_configurar_ui()
	
	print("=== INICIALIZACIÓN COMPLETADA ===")

func _verificar_nodos_ui() -> bool:
	"""Verifica que los nodos críticos de UI existan"""
	var nodos_faltantes = []
	
	# Verificar nodos críticos
	if not current_password:
		nodos_faltantes.append("current_password")
	
	if not new_password:
		nodos_faltantes.append("new_password")
	
	if not confirm_password:
		nodos_faltantes.append("confirm_password")
	
	if not status_message:
		nodos_faltantes.append("status_message")
	
	if not btn_cambiar:
		nodos_faltantes.append("btn_cambiar")
	
	if not btn_cancelar:
		nodos_faltantes.append("btn_cancelar")
	
	if nodos_faltantes.size() > 0:
		print("❌ ERROR: Nodos de UI faltantes: ", nodos_faltantes)
		show_error_directo("Error crítico: Faltan elementos de la interfaz")
		return false
	
	return true

func show_error_directo(mensaje: String):
	"""Muestra error directamente sin depender de nodos de UI"""
	print("❌ ", mensaje)
	OS.alert(mensaje, "Error Crítico")

func _verificar_singletons() -> bool:
	"""Verifica que los singletons estén disponibles"""
	if not global_node:
		print("❌ ERROR: Global no encontrado")
		show_error_directo("Error de sistema: Global no disponible")
		await get_tree().create_timer(2.0).timeout
		volver_al_menu()
		return false
	
	if not bd:
		print("❌ ERROR: BD no encontrada")
		show_error_directo("Error de sistema: Base de datos no disponible")
		await get_tree().create_timer(2.0).timeout
		volver_al_menu()
		return false
	
	print("✅ Singletons encontrados")
	return true

func _verificar_autenticacion() -> bool:
	"""Verifica que el usuario esté autenticado"""
	if global_node.has_method("esta_autenticado"):
		if not global_node.esta_autenticado():
			print("⚠️ Usuario no autenticado")
			show_error("Debe iniciar sesión para cambiar la contraseña")
			await get_tree().create_timer(2.0).timeout
			volver_al_menu()
			return false
	else:
		if not _global_tiene_usuario_actual():
			print("⚠️ No hay datos de usuario en Global")
			show_error("No hay sesión activa. Por favor, inicie sesión.")
			await get_tree().create_timer(2.0).timeout
			volver_al_menu()
			return false
	
	return true

func _global_tiene_usuario_actual() -> bool:
	"""Verifica si Global tiene usuario_actual y no está vacío"""
	return global_node.get("usuario_actual") != null and not global_node.usuario_actual.is_empty()

func _mostrar_info_usuario():
	"""Muestra información del usuario actual"""
	print("👤 Usuario actual:")
	
	var user_id = -1
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
		print("   ID: ", user_id)
	
	var username = "Desconocido"
	if _global_tiene_usuario_actual() and "username" in global_node.usuario_actual:
		username = global_node.usuario_actual["username"]
		print("   Username: ", username)
	
	var rol = "No definido"
	if global_node.has_method("obtener_rol"):
		rol = global_node.obtener_rol()
		print("   Rol: ", rol)
	elif _global_tiene_usuario_actual() and "rol" in global_node.usuario_actual:
		rol = global_node.usuario_actual["rol"]
		print("   Rol: ", rol)

func _configurar_ui():
	"""Configura la interfaz de usuario y conecta señales"""
	# Conectar botones principales
	btn_cambiar.pressed.connect(_on_cambiar_pressed)
	btn_cancelar.pressed.connect(_on_cancelar_pressed)
	
	# Conectar botones de visibilidad
	btn_show_current.pressed.connect(_toggle_current_password_visibility)
	btn_show_new.pressed.connect(_toggle_new_password_visibility)
	btn_show_confirm.pressed.connect(_toggle_confirm_password_visibility)
	
	# Conectar validación en tiempo real
	new_password.text_changed.connect(_on_new_password_changed)
	confirm_password.text_changed.connect(_on_confirm_password_changed)
	
	# Configurar modo seguro
	_actualizar_requisitos_password()
	modo_seguro_toggle.button_pressed = modo_seguro
	modo_seguro_toggle.toggled.connect(_on_modo_seguro_toggled)
	
	# Inicializar barra de fortaleza
	strength_bar.visible = false
	strength_text.visible = false
	
	print("✅ UI configurada correctamente")

func _actualizar_requisitos_password():
	"""Actualiza el texto de requisitos según el modo seguro"""
	if modo_seguro:
		password_requirements.text = "Mínimo %d caracteres, incluir mayúsculas, minúsculas y números. Contraseñas débiles como '123' están prohibidas." % password_min_length
		password_requirements.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2, 1))
	else:
		password_requirements.text = "Mínimo %d caracteres (modo inseguro - no se verifican requisitos de complejidad)" % password_min_length
		password_requirements.add_theme_color_override("font_color", Color(0.8, 0.4, 0.2, 1))

func _on_modo_seguro_toggled(activado: bool):
	"""Se llama cuando cambia el toggle de modo seguro"""
	modo_seguro = activado
	_actualizar_requisitos_password()
	
	print("🔒 Modo seguro ", "ACTIVADO" if modo_seguro else "DESACTIVADO")

# Funciones de visibilidad de contraseñas
func _toggle_current_password_visibility():
	current_password.secret = not current_password.secret
	btn_show_current.text = "👁" if current_password.secret else "🔒"

func _toggle_new_password_visibility():
	new_password.secret = not new_password.secret
	btn_show_new.text = "👁" if new_password.secret else "🔒"

func _toggle_confirm_password_visibility():
	confirm_password.secret = not confirm_password.secret
	btn_show_confirm.text = "👁" if confirm_password.secret else "🔒"

# Manejo de eventos de UI
func _on_new_password_changed(new_text: String):
	update_password_strength(new_text)
	validate_passwords()

func _on_confirm_password_changed(_new_text: String):
	validate_passwords()

func update_password_strength(password: String):
	if not modo_seguro:
		return
	
	if password.length() == 0:
		strength_bar.visible = false
		strength_text.visible = false
		return
	
	strength_bar.visible = true
	strength_text.visible = true
	
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
	
	# Penalizar contraseñas débiles conocidas
	if _es_contrasena_debil(password):
		score = max(0, score - 50)
	
	score = min(score, 100)
	strength_bar.value = score
	
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

func _es_contrasena_debil(password: String) -> bool:
	var pass_lower = password.to_lower().strip_edges()
	
	for contrasena_debil in contrasenas_debiles:
		if pass_lower == contrasena_debil:
			return true
	
	if password.length() < 6:
		return true
	
	if password.matchn("^[0-9]+$"):
		var es_consecutivo = true
		for i in range(1, password.length()):
			if int(password[i]) != int(password[i-1]) + 1:
				es_consecutivo = false
				break
		if es_consecutivo:
			return true
	
	if password.matchn("^(.)\\1+$"):
		return true
	
	return false

func validate_passwords() -> bool:
	var new_pass = new_password.text
	var confirm_pass = confirm_password.text
	
	if new_pass != "" and confirm_pass != "":
		if new_pass != confirm_pass:
			_mostrar_error_campo(confirm_password, true)
			status_message.text = "❌ Las contraseñas no coinciden"
			status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
			return false
		else:
			_mostrar_error_campo(confirm_password, false)
			status_message.text = "✅ Contraseñas coinciden"
			status_message.add_theme_color_override("font_color", Color(0.2, 0.4, 0.2, 1))
			return true
	
	return false

func _mostrar_error_campo(campo: LineEdit, mostrar_error: bool):
	if mostrar_error:
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
		
		campo.add_theme_stylebox_override("normal", error_style)
	else:
		campo.remove_theme_stylebox_override("normal")

# Manejo de botones
func _on_cambiar_pressed():
	print("=== INTENTANDO CAMBIAR CONTRASEÑA ===")
	
	if not _validar_campos():
		return
	
	if not validate_passwords():
		show_error("Las contraseñas no coinciden")
		return
	
	if new_password.text.length() < password_min_length:
		show_error("La contraseña debe tener al menos %d caracteres" % password_min_length)
		return
	
	if modo_seguro:
		if strength_bar.value < 40:
			show_error("La contraseña es muy débil. Use mayúsculas, minúsculas y números")
			return
		
		if _es_contrasena_debil(new_password.text):
			show_error("❌ CONTRASEÑA DÉBIL DETECTADA\n\nEsta contraseña es muy común o predecible.\nPor seguridad, elija una contraseña más compleja.")
			return
	
	print("Verificando contraseña actual...")
	if not verify_current_password(current_password.text):
		show_error("Contraseña actual incorrecta")
		return
	
	print("✅ Contraseña actual verificada")
	
	print("Cambiando contraseña...")
	if change_password(new_password.text):
		print("✅ Contraseña cambiada exitosamente")
		
		_registrar_auditoria_cambio_password()
		
		_mostrar_exito()
		
		_limpiar_campos()
		await get_tree().create_timer(2.0).timeout
		volver_al_menu()
	else:
		show_error("Error al cambiar la contraseña en la base de datos")

func _on_cancelar_pressed():
	print("Cancelando - Volviendo al menú principal...")
	volver_al_menu()

# Validaciones
func _validar_campos() -> bool:
	var campos_faltantes = []
	
	if current_password.text.strip_edges() == "":
		campos_faltantes.append("Contraseña Actual")
		_mostrar_error_campo(current_password, true)
	
	if new_password.text.strip_edges() == "":
		campos_faltantes.append("Nueva Contraseña")
		_mostrar_error_campo(new_password, true)
	
	if confirm_password.text.strip_edges() == "":
		campos_faltantes.append("Confirmar Contraseña")
		_mostrar_error_campo(confirm_password, true)
	
	if campos_faltantes.size() > 0:
		show_error("Complete los campos requeridos:\n" + "\n".join(campos_faltantes))
		return false
	
	return true

# Funciones de base de datos
func verify_current_password(password: String) -> bool:
	if not bd or not global_node:
		show_error("Error de conexión a la base de datos")
		return false
	
	var user_id = -1
	var username = ""
	
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
	
	if _global_tiene_usuario_actual() and "username" in global_node.usuario_actual:
		username = global_node.usuario_actual["username"]
	
	print("Verificando contraseña para usuario ID: ", user_id, " Username: ", username)
	
	if bd.has_method("autenticar_usuario"):
		var resultado = bd.autenticar_usuario(username, password)
		
		if resultado and not resultado.is_empty():
			print("✅ Contraseña actual correcta")
			return true
	
	print("❌ Contraseña actual incorrecta")
	return false

func change_password(new_password_text: String) -> bool:
	if not bd or not global_node:
		show_error("Error de conexión a la base de datos")
		return false
	
	var user_id = -1
	var username = ""
	
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
	
	if _global_tiene_usuario_actual() and "username" in global_node.usuario_actual:
		username = global_node.usuario_actual["username"]
	
	print("Cambiando contraseña para ID: ", user_id, " Username: ", username)
	
	if bd.has_method("cambiar_password"):
		var success = bd.cambiar_password(user_id, new_password_text)
		
		if success:
			print("✅ Contraseña actualizada usando función BD.cambiar_password")
			return true
	
	return _cambiar_password_alternativo(user_id, new_password_text)

func _cambiar_password_alternativo(user_id: int, new_password_text: String) -> bool:
	var sql = """
		UPDATE usuarios 
		SET password_hash = ?, 
			requiere_cambio_password = 0,
			fecha_modificacion = CURRENT_TIMESTAMP
		WHERE id = ?
	"""
	
	var params = [new_password_text, user_id]
	var success = bd.query(sql, params)
	
	if success:
		print("✅ Contraseña actualizada con método alternativo")
		return true
	
	print("❌ Error en consulta UPDATE")
	return false

# Funciones auxiliares
func _registrar_auditoria_cambio_password():
	if not bd or not global_node:
		return
	
	var user_id = -1
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
	
	if user_id > 0 and bd.has_method("registrar_auditoria"):
		bd.registrar_auditoria(
			user_id,
			"CAMBIO_PASSWORD",
			"cambiar_password",
			"Usuario cambió su contraseña exitosamente (Modo seguro: %s)" % ("ACTIVADO" if modo_seguro else "DESACTIVADO")
		)
		print("✅ Auditoría registrada")

func _mostrar_exito():
	var mensaje = "¡Contraseña cambiada exitosamente!"
	if not modo_seguro:
		mensaje += "\n\n⚠️ ADVERTENCIA: Modo seguro desactivado\nSe aceptaron contraseñas débiles."
	
	success_dialog.dialog_text = mensaje
	success_dialog.popup_centered()
	
	status_message.text = "✅ Contraseña actualizada correctamente"
	status_message.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2, 1))

func _limpiar_campos():
	current_password.text = ""
	new_password.text = ""
	confirm_password.text = ""
	strength_bar.value = 0
	strength_text.text = "Débil"
	strength_text.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
	strength_bar.add_theme_color_override("fill_color", Color(0.8, 0.2, 0.2, 1))
	
	current_password.secret = true
	new_password.secret = true
	confirm_password.secret = true
	btn_show_current.text = "👁"
	btn_show_new.text = "👁"
	btn_show_confirm.text = "👁"

func volver_al_menu():
	print("Volviendo al menú principal...")
	
	var ruta_menu = "res://escenas/menu_principal.tscn"
	
	if ResourceLoader.exists(ruta_menu):
		get_tree().change_scene_to_file(ruta_menu)
		return
	
	var ruta_alternativa = "res://scenes/menu_principal.tscn"
	if ResourceLoader.exists(ruta_alternativa):
		get_tree().change_scene_to_file(ruta_alternativa)
		return
	
	if has_node("/root/SceneManager"):
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager.has_method("change_scene_to"):
			scene_manager.change_scene_to("menu_principal")
			return
	
	get_tree().change_scene_to_file("res://escenas/login.tscn")

func show_error(message: String, es_advertencia: bool = false):
	print("❌ ERROR: ", message)
	
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
	
	if status_message:
		if es_advertencia:
			status_message.text = "⚠️ Advertencia: " + message
			status_message.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
		else:
			status_message.text = "❌ Error: " + message
			status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))

# Manejo de teclado
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancelar_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_cambiar_pressed()
		elif event.keycode == KEY_S and event.ctrl_pressed and event.shift_pressed:
			modo_seguro = not modo_seguro
			modo_seguro_toggle.button_pressed = modo_seguro
			_on_modo_seguro_toggled(modo_seguro)
			print("🔧 Atajo de teclado: Modo seguro ", "ACTIVADO" if modo_seguro else "DESACTIVADO")
		elif event.keycode == KEY_V and event.alt_pressed:
			_toggle_current_password_visibility()
			_toggle_new_password_visibility()
			_toggle_confirm_password_visibility()
			print("🔧 Atajo de teclado: Visibilidad de contraseñas alternada")
