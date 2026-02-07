# cambiar_password.gd - VERSIÓN CORREGIDA
extends Control

# Referencias a nodos UI
@onready var current_password = $Panel/MarginContainer/VBoxContainer/CurrentPasswordContainer/CurrentPassword
@onready var new_password = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/NewPassword
@onready var confirm_password = $Panel/MarginContainer/VBoxContainer/ConfirmPasswordContainer/ConfirmPassword
@onready var strength_bar = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthBar
@onready var strength_text = $Panel/MarginContainer/VBoxContainer/PasswordStrength/StrengthBarContainer/StrengthText
@onready var status_message = $Panel/MarginContainer/VBoxContainer/StatusMessage
@onready var success_dialog = $SuccessDialog
@onready var error_dialog = $ErrorDialog
@onready var btn_cancelar = $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCancelar
@onready var btn_cambiar = $Panel/MarginContainer/VBoxContainer/ActionButtons/BtnCambiar
@onready var password_requirements = $Panel/MarginContainer/VBoxContainer/NewPasswordContainer/PasswordRequirements

# Referencias a singletons
var global_node: Node
var bd: Node

# Configuración
var password_min_length = 8

func _ready():
	print("=== INICIALIZANDO CAMBIAR PASSWORD ===")
	
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
	
	# Prueba de diagnóstico de base de datos
	_ejecutar_diagnostico_bd()
	
	print("=== INICIALIZACIÓN COMPLETADA ===")

func _verificar_singletons() -> bool:
	"""Verifica que los singletons estén disponibles"""
	
	if not global_node:
		print("❌ ERROR: Global no encontrado")
		show_error("Error de sistema: Global no disponible")
		await get_tree().create_timer(2.0).timeout
		volver_al_menu()
		return false
	
	if not bd:
		print("❌ ERROR: BD no encontrada")
		show_error("Error de sistema: Base de datos no disponible")
		await get_tree().create_timer(2.0).timeout
		volver_al_menu()
		return false
	
	print("✅ Singletons encontrados")
	print("   Global: ", global_node.name)
	print("   BD: ", bd.name)
	
	return true

func _verificar_autenticacion() -> bool:
	"""Verifica que el usuario esté autenticado"""
	
	# Verificar método de autenticación en Global
	if global_node.has_method("esta_autenticado"):
		if not global_node.esta_autenticado():
			print("⚠️ Usuario no autenticado")
			show_error("Debe iniciar sesión para cambiar la contraseña")
			await get_tree().create_timer(2.0).timeout
			volver_al_menu()
			return false
	else:
		# Fallback: verificar si hay datos de usuario
		# CORRECCIÓN: Usar verificación directa en lugar de has()
		if not _global_tiene_usuario_actual():
			print("⚠️ No hay datos de usuario en Global")
			show_error("No hay sesión activa. Por favor, inicie sesión.")
			await get_tree().create_timer(2.0).timeout
			volver_al_menu()
			return false
	
	return true

func _global_tiene_usuario_actual() -> bool:
	"""Verifica si Global tiene usuario_actual y no está vacío"""
	# Verificar si existe la propiedad usuario_actual
	# En GDScript, podemos intentar acceder a la propiedad y verificar si es válida
	return global_node.get("usuario_actual") != null and not global_node.usuario_actual.is_empty()

func _mostrar_info_usuario():
	"""Muestra información del usuario actual"""
	
	print("👤 Usuario actual:")
	
	# Obtener ID de usuario
	var user_id = -1
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
		print("   ID: ", user_id)
	
	# Obtener nombre de usuario
	var username = "Desconocido"
	# CORRECCIÓN: Verificar directamente la propiedad usuario_actual
	if _global_tiene_usuario_actual() and "username" in global_node.usuario_actual:
		username = global_node.usuario_actual["username"]
		print("   Username: ", username)
	
	# Obtener rol
	var rol = "No definido"
	if global_node.has_method("obtener_rol"):
		rol = global_node.obtener_rol()
		print("   Rol: ", rol)
	# CORRECCIÓN: Verificar directamente la propiedad usuario_actual
	elif _global_tiene_usuario_actual() and "rol" in global_node.usuario_actual:
		rol = global_node.usuario_actual["rol"]
		print("   Rol: ", rol)

func _configurar_ui():
	"""Configura la interfaz de usuario y conecta señales"""
	
	# Conectar botones
	if btn_cambiar:
		btn_cambiar.pressed.connect(_on_cambiar_pressed)
		print("✅ BtnCambiar conectado")
	else:
		print("❌ BtnCambiar no encontrado")
	
	if btn_cancelar:
		btn_cancelar.pressed.connect(_on_cancelar_pressed)
		print("✅ BtnCancelar conectado")
	else:
		print("❌ BtnCancelar no encontrado")
	
	# Conectar validación en tiempo real
	if new_password:
		new_password.text_changed.connect(_on_new_password_changed)
	
	if confirm_password:
		confirm_password.text_changed.connect(_on_confirm_password_changed)
	
	# Configurar texto de requisitos
	if password_requirements:
		password_requirements.text = "Mínimo %d caracteres, incluir mayúsculas, minúsculas y números" % password_min_length

func _ejecutar_diagnostico_bd():
	"""Ejecuta diagnóstico de la base de datos"""
	
	print("\n🔍 DIAGNÓSTICO DE BD:")
	
	# Verificar conexión a BD
	if bd.has_method("test_conexion"):
		bd.test_conexion()
	
	# Verificar tabla auditoria
	if bd.has_method("probar_tabla_auditoria"):
		bd.probar_tabla_auditoria()
	
	# Verificar usuario actual en BD
	var user_id = -1
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
		
		if user_id > 0 and bd.has_method("obtener_usuario_por_id"):
			var usuario_bd = bd.obtener_usuario_por_id(user_id)
			if usuario_bd and not usuario_bd.is_empty():
				print("✅ Usuario encontrado en BD: ", usuario_bd.get("username", "Desconocido"))
			else:
				print("⚠️ Usuario no encontrado en BD")

# =========================
# MANEJO DE EVENTOS DE UI
# =========================
func _on_new_password_changed(new_text: String):
	"""Se llama cuando cambia el texto de la nueva contraseña"""
	update_password_strength(new_text)
	validate_passwords()

func _on_confirm_password_changed(_new_text: String):
	"""Se llama cuando cambia el texto de confirmación"""
	validate_passwords()

func update_password_strength(password: String):
	"""Calcula y muestra la fortaleza de la contraseña"""
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
	
	# Limitar score a 100
	score = min(score, 100)
	strength_bar.value = score
	
	# Actualizar texto y colores según la fortaleza
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

func validate_passwords() -> bool:
	"""Valida que las contraseñas coincidan"""
	var new_pass = new_password.text
	var confirm_pass = confirm_password.text
	
	if new_pass != "" and confirm_pass != "":
		if new_pass != confirm_pass:
			# Mostrar error visual
			_mostrar_error_campo(confirm_password, true)
			status_message.text = "❌ Las contraseñas no coinciden"
			status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
			return false
		else:
			# Restaurar estilo normal
			_mostrar_error_campo(confirm_password, false)
			status_message.text = "✅ Contraseñas coinciden"
			status_message.add_theme_color_override("font_color", Color(0.2, 0.4, 0.2, 1))
			return true
	
	return false

func _mostrar_error_campo(campo: LineEdit, mostrar_error: bool):
	"""Muestra u oculta el estilo de error en un campo"""
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
		# Restaurar estilo por defecto
		campo.remove_theme_stylebox_override("normal")

# =========================
# MANEJO DE BOTONES
# =========================
func _on_cambiar_pressed():
	"""Manejador del botón Cambiar Contraseña"""
	print("=== INTENTANDO CAMBIAR CONTRASEÑA ===")
	
	# Validar campos obligatorios
	if not _validar_campos():
		return
	
	# Validar que las contraseñas coincidan
	if not validate_passwords():
		show_error("Las contraseñas no coinciden")
		return
	
	# Validar longitud mínima
	if new_password.text.length() < password_min_length:
		show_error("La contraseña debe tener al menos %d caracteres" % password_min_length)
		return
	
	# Validar fortaleza mínima
	if strength_bar.value < 40:
		show_error("La contraseña es muy débil. Use mayúsculas, minúsculas y números")
		return
	
	# Verificar contraseña actual
	print("Verificando contraseña actual...")
	if not verify_current_password(current_password.text):
		show_error("Contraseña actual incorrecta")
		return
	
	print("✅ Contraseña actual verificada")
	
	# Cambiar contraseña
	print("Cambiando contraseña...")
	if change_password(new_password.text):
		print("✅ Contraseña cambiada exitosamente")
		
		# Registrar auditoría
		_registrar_auditoria_cambio_password()
		
		# Mostrar mensaje de éxito
		_mostrar_exito()
		
		# Limpiar campos y regresar al menú
		_limpiar_campos()
		await get_tree().create_timer(2.0).timeout
		volver_al_menu()
	else:
		show_error("Error al cambiar la contraseña en la base de datos")

func _on_cancelar_pressed():
	"""Manejador del botón Cancelar"""
	print("Cancelando - Volviendo al menú principal...")
	volver_al_menu()

# =========================
# VALIDACIONES
# =========================
func _validar_campos() -> bool:
	"""Valida que todos los campos estén completos"""
	
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

# =========================
# FUNCIONES DE BASE DE DATOS
# =========================
func verify_current_password(password: String) -> bool:
	"""Verifica que la contraseña actual sea correcta"""
	
	if not bd or not global_node:
		show_error("Error de conexión a la base de datos")
		return false
	
	# Obtener ID y username del usuario actual
	var user_id = -1
	var username = ""
	
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
	
	# CORRECCIÓN: Verificar directamente la propiedad usuario_actual
	if _global_tiene_usuario_actual() and "username" in global_node.usuario_actual:
		username = global_node.usuario_actual["username"]
	
	print("Verificando contraseña para usuario:")
	print("   ID: ", user_id)
	print("   Username: ", username)
	
	# Intentar autenticar con las credenciales actuales
	if bd.has_method("autenticar_usuario"):
		var resultado = bd.autenticar_usuario(username, password)
		
		if resultado and not resultado.is_empty():
			print("✅ Contraseña actual correcta")
			return true
	else:
		# Método alternativo: consulta directa
		print("⚠️ Usando método alternativo para verificar contraseña")
		return _verificar_password_alternativo(user_id, username, password)
	
	print("❌ Contraseña actual incorrecta")
	return false

func _verificar_password_alternativo(user_id: int, username: String, password: String) -> bool:
	"""Método alternativo para verificar contraseña"""
	
	# Usar una bandera para detectar errores
	var hay_error = false
	
	# Consulta directa a la tabla usuarios
	var sql = """
		SELECT id FROM usuarios 
		WHERE (id = ? OR username = ?) 
		AND password_hash = ? 
		AND estado_empleado = 'activo'
	"""
	
	var params = [user_id, username, password]
	
	# En GDScript, no hay try/catch como en Python, usamos verificación manual
	if bd.has_method("select_query"):
		var resultado = bd.select_query(sql, params)
		
		# Verificar si hubo error
		if resultado == null:
			hay_error = true
			print("❌ Error en consulta select_query")
		else:
			return resultado and resultado.size() > 0
	else:
		hay_error = true
		print("❌ BD no tiene método select_query")
	
	if hay_error:
		print("❌ Error en método alternativo de verificación")
		return false
	
	return false

func change_password(new_password_text: String) -> bool:
	"""Cambia la contraseña en la base de datos"""
	
	if not bd or not global_node:
		show_error("Error de conexión a la base de datos")
		return false
	
	var user_id = -1
	var username = ""
	
	# Obtener datos del usuario
	if global_node.has_method("obtener_id_usuario"):
		user_id = global_node.obtener_id_usuario()
	
	# CORRECCIÓN: Verificar directamente la propiedad usuario_actual
	if _global_tiene_usuario_actual() and "username" in global_node.usuario_actual:
		username = global_node.usuario_actual["username"]
	
	print("Cambiando contraseña para:")
	print("   ID: ", user_id)
	print("   Username: ", username)
	
	# Método 1: Usar la función cambiar_password de BD.gd si existe
	if bd.has_method("cambiar_password"):
		print("Usando función cambiar_password de BD...")
		var success = bd.cambiar_password(user_id, new_password_text)
		
		if success:
			print("✅ Contraseña actualizada usando función BD.cambiar_password")
			return true
		else:
			print("❌ Falló BD.cambiar_password, intentando método alternativo...")
	
	# Método 2: Consulta directa
	print("Usando método alternativo (consulta directa)...")
	return _cambiar_password_alternativo(user_id, new_password_text)

func _cambiar_password_alternativo(user_id: int, new_password_text: String) -> bool:
	"""Método alternativo para cambiar contraseña"""
	
	var success = false
	
	# Actualizar contraseña en la tabla usuarios
	var sql = """
		UPDATE usuarios 
		SET password_hash = ?, 
			requiere_cambio_password = 0,
			fecha_modificacion = CURRENT_TIMESTAMP
		WHERE id = ?
	"""
	
	var params = [new_password_text, user_id]
	success = bd.query(sql, params)
	
	if success:
		print("✅ Contraseña actualizada con método alternativo")
		
		# También actualizar en tabla nueva si existe
		_actualizar_password_tabla_nueva(user_id, new_password_text)
		
		return true
	else:
		print("❌ Error en consulta UPDATE")
		return false

func _actualizar_password_tabla_nueva(user_id: int, new_password_text: String):
	"""Actualiza la contraseña en la tabla nueva (si existe)"""
	
	# Verificar si existe la tabla usuarios_nueva
	if bd.has_method("table_exists"):
		if bd.table_exists("usuarios_nueva"):
			var sql_nueva = """
				UPDATE usuarios_nueva 
				SET password_hash = ?, 
					updated_at = CURRENT_TIMESTAMP
				WHERE id = ?
			"""
			
			var params = [new_password_text, user_id]
			var success = bd.query(sql_nueva, params)
			
			if success:
				print("✅ Contraseña actualizada en tabla nueva")
			else:
				print("⚠️ No se pudo actualizar en tabla nueva")

# =========================
# FUNCIONES AUXILIARES
# =========================
func _registrar_auditoria_cambio_password():
	"""Registra el cambio de contraseña en auditoría"""
	
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
			"Usuario cambió su contraseña exitosamente"
		)
		print("✅ Auditoría registrada")

func _mostrar_exito():
	"""Muestra mensaje de éxito"""
	
	success_dialog.dialog_text = "¡Contraseña cambiada exitosamente!"
	success_dialog.popup_centered()
	
	# Actualizar mensaje de estado
	status_message.text = "✅ Contraseña actualizada correctamente"
	status_message.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2, 1))

func _limpiar_campos():
	"""Limpia todos los campos de contraseña"""
	
	current_password.text = ""
	new_password.text = ""
	confirm_password.text = ""
	strength_bar.value = 0
	strength_text.text = "Débil"
	strength_text.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
	strength_bar.add_theme_color_override("fill_color", Color(0.8, 0.2, 0.2, 1))

func volver_al_menu():
	"""Vuelve al menú principal"""
	
	print("Volviendo al menú principal...")
	
	# Intentar diferentes métodos para regresar al menú
	
	# Método 1: Usar cambio de escena directo
	var ruta_menu = "res://escenas/menu_principal.tscn"
	
	if ResourceLoader.exists(ruta_menu):
		print("Cambiando a: ", ruta_menu)
		get_tree().change_scene_to_file(ruta_menu)
		return
	
	# Método 2: Ruta alternativa
	var ruta_alternativa = "res://scenes/menu_principal.tscn"
	if ResourceLoader.exists(ruta_alternativa):
		print("Cambiando a ruta alternativa: ", ruta_alternativa)
		get_tree().change_scene_to_file(ruta_alternativa)
		return
	
	# Método 3: Buscar SceneManager
	if has_node("/root/SceneManager"):
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager.has_method("change_scene_to"):
			print("Usando SceneManager para regresar al menú...")
			scene_manager.change_scene_to("menu_principal")
			return
	
	# Método 4: Último recurso - ir a login
	print("⚠️ No se encontró el menú, redirigiendo a login...")
	get_tree().change_scene_to_file("res://escenas/login.tscn")

func show_error(message: String):
	"""Muestra un mensaje de error"""
	
	print("❌ ERROR: ", message)
	
	# Mostrar en diálogo de error
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
	
	# Actualizar mensaje de estado
	status_message.text = "❌ Error: " + message
	status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))

# =========================
# FUNCIONES DE HASH (para producción)
# =========================
func hash_password(password: String) -> String:
	"""
	Función para hashear contraseñas.
	EN PRODUCCIÓN: Implementar con algoritmo seguro como bcrypt o PBKDF2
	"""
	
	# En desarrollo: usar SHA256 (NO SEGURO para producción)
	# En producción, implementar:
	# - bcrypt
	# - PBKDF2
	# - Argon2
	
	return password.sha256_text()

# =========================
# MANEJO DE TECLADO
# =========================
func _input(event):
	"""Maneja eventos de teclado"""
	
	if event is InputEventKey and event.pressed:
		# Tecla ESC para cancelar
		if event.keycode == KEY_ESCAPE:
			_on_cancelar_pressed()
		
		# Enter para cambiar contraseña
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_cambiar_pressed()
