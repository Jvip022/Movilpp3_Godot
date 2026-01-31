extends Control

# Referencias a nodos
@onready var input_usuario: LineEdit = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputUsuario
@onready var input_password: LineEdit = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputPassword
@onready var check_recordar: CheckBox = find_child("CheckRecordar")
@onready var boton_login: Button = find_child("BotonLogin")
@onready var boton_registrar: Button = find_child("BotonRegistrar")
@onready var boton_recuperar: Button = find_child("BotonRecuperar")
@onready var mensaje_error: Label = find_child("MensajeError")
@onready var panel_cargando: Panel = find_child("PanelCargando")
@onready var dialogo_recuperar: AcceptDialog = $DialogoRecuperar
@onready var dialogo_registro: AcceptDialog = $DialogoRegistro

# Base de datos - USA BD EN LUGAR DE SQLite
var db: BD

# Configuración persistente
var config_file = "user://config.cfg"

func _ready():
	# Inicializar base de datos usando BD.gd
	db = BD.new()
	
	# Llamar a _ready de la base de datos para inicializar
	if db.has_method("_ready"):
		db._ready()
		print("Base de datos BD inicializada")
	
	# Verificar que los nodos existen
	print("Verificando nodos...")
	print("InputUsuario: ", input_usuario != null)
	print("InputPassword: ", input_password != null)
	print("MensajeError: ", mensaje_error != null)
	
	# Verificar si la tabla usuarios existe usando BD
	verificar_tabla_usuarios()
	
	# Verificar si existe usuario admin
	verificar_usuario_admin()
	
	# Conectar señales
	if boton_login:
		boton_login.pressed.connect(_on_login_pressed)
		print("BotonLogin conectado")
	
	if boton_registrar:
		boton_registrar.pressed.connect(_on_registrar_pressed)
		print("BotonRegistrar conectado")
	
	if boton_recuperar:
		boton_recuperar.pressed.connect(_on_recuperar_pressed)
		print("BotonRecuperar conectado")
	
	# Enter para login
	if input_password:
		input_password.text_submitted.connect(_on_password_submitted)
	
	# Configurar diálogos
	configurar_dialogo_recuperar()
	configurar_dialogo_registro()
	
	# Cargar usuario recordado
	cargar_usuario_recordado()
	
	# Aplicar efectos visuales
	aplicar_efectos_visuales()
	
	# AUTO-PRUEBA: Llenar campos con usuario demo (solo para pruebas)
	input_usuario.text = "admin"
	input_password.text = "admin123"

func verificar_tabla_usuarios():
	print("=== VERIFICANDO TABLA USUARIOS ===")
	
	if db.has_method("select_one"):
		# Verificar si existe la tabla usuarios
		var check_sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='usuarios'"
		var result = db.select_one(check_sql)
		
		if result:
			print("✅ La tabla 'usuarios' existe")
			
			# Contar usuarios
			var count_sql = "SELECT COUNT(*) as total FROM usuarios"
			var count_result = db.select_one(count_sql)
			if count_result:
				print("Total de usuarios en la tabla: ", count_result.total)
			return true
		else:
			print("❌ La tabla 'usuarios' NO existe")
			print("NOTA: BD._ready() debería haber creado las tablas automáticamente")
			return false
	return false

func verificar_usuario_admin():
	print("=== VERIFICANDO USUARIO ADMIN ===")
	
	if db.has_method("select_one"):
		# Buscar usuario admin
		var result = db.select_one("SELECT * FROM usuarios WHERE username = 'admin'")
		
		if result:
			print("✅ Usuario admin encontrado:")
			print("   ID: ", result.id)
			print("   Username: ", result.username)
			print("   Email: ", result.email)
			print("   Rol: ", result.rol)
			return true
		else:
			print("❌ Usuario admin NO encontrado")
			
			# Intentar crear usuario admin
			print("Intentando crear usuario admin...")
			crear_usuario_admin()
			return false
	return false

func crear_usuario_admin():
	# Crear usuario admin usando BD.insert
	var admin_data = {
		"username": "admin",
		"password_hash": "admin123",
		"email": "admin@sistema.com",
		"nombre_completo": "Administrador del Sistema",
		"rol": "administrador",
		"cargo": "Administrador",
		"departamento": "TI",
		"estado_empleado": "activo"
	}
	
	if db.has_method("insert"):
		var user_id = db.insert("usuarios", admin_data)
		if user_id > 0:
			print("✅ Usuario admin creado exitosamente con ID: ", user_id)
			print("   Usuario: admin")
			print("   Contraseña: admin123")
			return true
		else:
			print("❌ Error al crear usuario admin usando BD.insert")
			
			# Intentar con query directo
			var sql = """
			INSERT INTO usuarios (username, password_hash, email, nombre_completo, rol, cargo, departamento, estado_empleado)
			VALUES ('admin', 'admin123', 'admin@sistema.com', 'Administrador del Sistema', 'administrador', 'Administrador', 'TI', 'activo')
			"""
			
			if db.has_method("query"):
				var result = db.query(sql)
				if result:
					print("✅ Usuario admin creado exitosamente (vía query)")
					return true
				else:
					print("❌ Error al crear usuario admin (vía query)")
					return false
	return false

# Funciones faltantes que estaban causando errores
func _on_login_pressed():
	print("Botón login presionado")
	autenticar_usuario()

func _on_password_submitted(_text):
	print("Enter presionado en campo contraseña")
	autenticar_usuario()

func configurar_dialogo_recuperar():
	if dialogo_recuperar:
		# Conectar señales del diálogo de recuperación
		var boton_confirmar = dialogo_recuperar.find_child("BotonConfirmarRecuperar")
		var boton_cancelar = dialogo_recuperar.find_child("BotonCancelarRecuperar")
		var input_email = dialogo_recuperar.find_child("InputEmailRecuperar")
		
		if boton_confirmar:
			boton_confirmar.pressed.connect(_on_recuperar_confirmado)
		if boton_cancelar:
			boton_cancelar.pressed.connect(_on_recuperar_cancelado)
		if input_email:
			input_email.text_submitted.connect(_on_recuperar_email_submitted)
		print("Diálogo recuperar configurado")
	else:
		print("⚠️ Diálogo recuperar no encontrado")

func configurar_dialogo_registro():
	if dialogo_registro:
		# Conectar señales del diálogo de registro
		var boton_confirmar = dialogo_registro.find_child("BotonConfirmarRegistro")
		var boton_cancelar = dialogo_registro.find_child("BotonCancelarRegistro")
		
		if boton_confirmar:
			boton_confirmar.pressed.connect(_on_registro_confirmado)
		if boton_cancelar:
			boton_cancelar.pressed.connect(_on_registro_cancelado)
		print("Diálogo registro configurado")
	else:
		print("⚠️ Diálogo registro no encontrado")

func _on_registro_cancelado():
	if dialogo_registro:
		dialogo_registro.hide()

func cargar_usuario_recordado():
	var config = ConfigFile.new()
	var err = config.load(config_file)
	if err == OK:
		var usuario = config.get_value("recordar", "usuario", "")
		var password = config.get_value("recordar", "password", "")
		var recordar = config.get_value("recordar", "recordar", false)
		
		if recordar and not usuario.is_empty():
			if input_usuario:
				input_usuario.text = usuario
			if input_password:
				input_password.text = password
		if check_recordar:
			check_recordar.button_pressed = recordar
		
		print("Configuración cargada: usuario=", usuario, ", recordar=", recordar)
	else:
		print("No se encontró configuración previa")

func aplicar_efectos_visuales():
	# Aplicar algunos efectos visuales básicos
	if boton_login:
		boton_login.focus_mode = Control.FOCUS_ALL
	if boton_registrar:
		boton_registrar.focus_mode = Control.FOCUS_ALL
	if boton_recuperar:
		boton_recuperar.focus_mode = Control.FOCUS_ALL

func guardar_usuario_recordado(usuario: String, password: String):
	var config = ConfigFile.new()
	var recordar = check_recordar.button_pressed if check_recordar else false
	
	config.set_value("recordar", "usuario", usuario if recordar else "")
	config.set_value("recordar", "password", password if recordar else "")
	config.set_value("recordar", "recordar", recordar)
	config.save(config_file)
	print("Configuración guardada: usuario=", usuario, ", recordar=", recordar)

# Resto del código existente...
func autenticar_usuario():
	print("=== INICIANDO AUTENTICACIÓN ===")
	
	if not input_usuario or not input_password:
		mostrar_error("Error: Campos de entrada no encontrados")
		return
	
	var usuario = input_usuario.text.strip_edges()
	var password = input_password.text
	
	print("Usuario ingresado: ", usuario)
	print("Contraseña ingresada: ", password)
	
	# Validaciones básicas
	if usuario.is_empty() or password.is_empty():
		mostrar_error("Por favor, complete todos los campos")
		return
	
	# Mostrar estado de carga
	mostrar_carga(true)
	
	# Consultar usuario en la base de datos usando BD.select_one
	var result = null
	if db.has_method("select_one"):
		result = db.select_one("SELECT * FROM usuarios WHERE (username = ? OR email = ?) AND estado_empleado = 'activo'", [usuario, usuario])
	
	await get_tree().create_timer(0.5).timeout  # Reducido para pruebas
	
	if result:
		print("✅ Usuario encontrado en BD:")
		print("   ID: ", result.id)
		print("   Username: ", result.username)
		print("   Email: ", result.email)
		print("   Contraseña en BD: ", result.get("password_hash", "NO ENCONTRADA"))
		print("   Rol: ", result.get("rol", "NO ESPECIFICADO"))
		
		# Comparar contraseñas
		var password_hash = result.get("password_hash", "")
		if str(password_hash) == password:
			print("✅ Contraseña correcta - Login exitoso")
			# Login exitoso
			guardar_usuario_recordado(usuario, password)
			
			# Actualizar último login usando BD.update
			if db.has_method("update"):
				db.update("usuarios", {
					"ultimo_login": "CURRENT_TIMESTAMP",
					"intentos_fallidos": 0
				}, "id = ?", [result.id])
			
			# Registrar actividad
			registrar_actividad_usuario(result.id, "login")
			
			ingresar_al_sistema(result)
		else:
			print("❌ Contraseña incorrecta")
			print("   Contraseña ingresada: ", password)
			print("   Contraseña en BD: ", password_hash)
			
			# Incrementar intentos fallidos
			var intentos = result.get("intentos_fallidos", 0) + 1
			
			if db.has_method("update"):
				db.update("usuarios", {
					"intentos_fallidos": intentos
				}, "id = ?", [result.id])
			
			if intentos >= 5:
				if db.has_method("update"):
					db.update("usuarios", {
						"bloqueado_hasta": "datetime('now', '+30 minutes')"
					}, "id = ?", [result.id])
				mostrar_error("Cuenta bloqueada por 30 minutos debido a múltiples intentos fallidos")
			else:
				mostrar_error("Contraseña incorrecta. Intentos restantes: %d" % (5 - intentos))
	else:
		print("❌ Usuario no encontrado o inactivo")
		# Mostrar más información de depuración
		print("Verificando estructura de BD...")
		verificar_tabla_usuarios()
		mostrar_error("Usuario no encontrado o inactivo")
	
	mostrar_carga(false)

func registrar_actividad_usuario(user_id: int, tipo_evento: String, detalles: String = ""):
	var actividad_data = {
		"usuario_id": user_id,
		"tipo_evento": tipo_evento,
		"descripcion": get_descripcion_evento(tipo_evento),
		"ip_address": obtener_ip_cliente(),
		"user_agent": obtener_user_agent(),
		"detalles": detalles
	}
	
	print("Registrando actividad: ", actividad_data)
	
	# Usar BD.insert para registrar actividad
	if db.has_method("insert"):
		var result = db.insert("historial_usuarios", actividad_data)
		print("Actividad registrada con ID: ", result)
		return result
	return -1

func get_descripcion_evento(tipo: String) -> String:
	match tipo:
		"login": return "Inicio de sesión exitoso"
		"logout": return "Cierre de sesión"
		"cambio_password": return "Cambio de contraseña"
		_: return "Actividad del sistema"

func obtener_ip_cliente() -> String:
	return "127.0.0.1"

func obtener_user_agent() -> String:
	var os = OS.get_name()
	var version = Engine.get_version_info()
	return "Godot/%s (%s)" % [version.string, os]

func ingresar_al_sistema(user_data):
	print("=== INGRESANDO AL SISTEMA ===")
	print("Datos del usuario: ", user_data)
	
	# Guardar sesión actual
	var Global_node = get_node("/root/Global") if get_tree().root.has_node("Global") else null
	
	if Global_node:
		Global_node.usuario_actual = {
			"id": user_data.id,
			"username": user_data.username,
			"nombre": user_data.nombre_completo if user_data.has("nombre_completo") else user_data.username,
			"email": user_data.email if user_data.has("email") else "",
			"rol": user_data.rol if user_data.has("rol") else "operador",
			"departamento": user_data.departamento if user_data.has("departamento") else "",
			"cargo": user_data.cargo if user_data.has("cargo") else ""
		}
		
		print("✅ Login exitoso: ", Global_node.usuario_actual)
		
		# Cargar escena principal
		cambiar_a_escena_principal()
	else:
		print("⚠️ No se encontró el nodo Global, creando configuración temporal...")
		# Si no existe Global, crear configuración temporal
		var config = ConfigFile.new()
		config.set_value("sesion", "usuario", {
			"id": user_data.id,
			"username": user_data.username,
			"nombre": user_data.nombre_completo if user_data.has("nombre_completo") else user_data.username,
			"email": user_data.email if user_data.has("email") else "",
			"rol": user_data.rol if user_data.has("rol") else "operador"
		})
		config.save("user://sesion_temp.cfg")
		
		print("✅ Login exitoso (sin Global)")
		cambiar_a_escena_principal()

func cambiar_a_escena_principal():
	print("=== CAMBIANDO A ESCENA PRINCIPAL ===")
	
	# Transición suave
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	
	# Cargar escena principal
	var escena_principal_path = "res://escenas/GestorQuejas.tscn"
	
	print("Intentando cargar: ", escena_principal_path)
	
	if ResourceLoader.exists(escena_principal_path):
		print("✅ Escena principal encontrada, cargando...")
		var escena_principal = load(escena_principal_path).instantiate()
		get_tree().root.add_child(escena_principal)
		
		# Eliminar esta escena
		queue_free()
		print("✅ Escena de login eliminada")
	else:
		print("❌ Error: No se encontró la escena principal en: ", escena_principal_path)
		mostrar_error("Error: No se encontró la escena principal")
		# Volver a mostrar login
		var tween2 = create_tween()
		tween2.tween_property(self, "modulate", Color.WHITE, 0.3)

func mostrar_error(mensaje: String):
	print("ERROR: ", mensaje)
	if mensaje_error:
		mensaje_error.text = mensaje
		mensaje_error.visible = true
		
		# Animación de error
		var tween = create_tween()
		tween.tween_property(mensaje_error, "modulate:a", 1.0, 0.2)
		await get_tree().create_timer(3.0).timeout
		tween = create_tween()
		tween.tween_property(mensaje_error, "modulate:a", 0.0, 0.5)
	else:
		print("Error (sin UI): ", mensaje)

func mostrar_carga(mostrar: bool):
	if panel_cargando:
		panel_cargando.visible = mostrar
		print("Panel carga: ", mostrar)
	
	if boton_login:
		boton_login.disabled = mostrar
	
	if boton_registrar:
		boton_registrar.disabled = mostrar
	
	if boton_recuperar:
		boton_recuperar.disabled = mostrar

func _on_registrar_pressed():
	print("Botón registrar presionado")
	if dialogo_registro:
		dialogo_registro.popup_centered(Vector2(400, 400))
		
		# Limpiar campos
		var campos = [
			"InputNombreRegistro",
			"InputEmailRegistro", 
			"InputUsuarioRegistro",
			"InputPasswordRegistro",
			"InputConfirmarPassword"
		]
		
		for campo_nombre in campos:
			var campo = dialogo_registro.find_child(campo_nombre)
			if campo:
				campo.text = ""
	else:
		print("⚠️ Diálogo de registro no disponible")

func _on_recuperar_pressed():
	print("Botón recuperar presionado")
	if dialogo_recuperar:
		dialogo_recuperar.popup_centered()
	else:
		print("⚠️ Diálogo de recuperación no disponible")

func _on_recuperar_confirmado():
	var input_email = dialogo_recuperar.find_child("InputEmailRecuperar")
	if input_email:
		var email = input_email.text.strip_edges()
		procesar_recuperacion(email)

func _on_recuperar_cancelado():
	print("Recuperación cancelada")

func _on_recuperar_email_submitted(_text: String):
	_on_recuperar_confirmado()

func procesar_recuperacion(email: String):
	if es_email_valido(email):
		# Buscar usuario por email usando BD.select_one
		if db.has_method("select_one"):
			var result = db.select_one("SELECT * FROM usuarios WHERE email = ?", [email])
			
			if result:
				# Generar token de recuperación
				var token = generar_token_recuperacion()
				
				# Guardar token en la base de datos
				if db.has_method("update"):
					db.update("usuarios", {
						"token_recuperacion": token,
						"token_expiracion": "datetime('now', '+1 hour')"
					}, "id = ?", [result.id])
				
				print("Token de recuperación generado para: ", email)
				mostrar_error("Se ha enviado un enlace de recuperación a su email")
				dialogo_recuperar.hide()
			else:
				mostrar_error("No existe una cuenta con este email")
	else:
		mostrar_error("Email inválido")

func generar_token_recuperacion() -> String:
	# Generar un token aleatorio simple
	# En producción, usar un método más seguro
	randomize()
	var caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var token = ""
	for i in range(32):
		token += caracteres[randi() % caracteres.length()]
	return token

func _on_registro_confirmado():
	var nombre = dialogo_registro.find_child("InputNombreRegistro")
	var email = dialogo_registro.find_child("InputEmailRegistro")
	var usuario = dialogo_registro.find_child("InputUsuarioRegistro")
	var password = dialogo_registro.find_child("InputPasswordRegistro")
	var confirmar = dialogo_registro.find_child("InputConfirmarPassword")
	
	if nombre and email and usuario and password and confirmar:
		procesar_registro(
			nombre.text.strip_edges(),
			email.text.strip_edges(),
			usuario.text.strip_edges(),
			password.text,
			confirmar.text
		)

func procesar_registro(nombre: String, email: String, usuario: String, password: String, confirmar: String):
	print("Procesando registro...")
	print("Nombre: ", nombre)
	print("Email: ", email)
	print("Usuario: ", usuario)
	
	# Validaciones
	if password != confirmar:
		mostrar_error("Las contraseñas no coinciden")
		return
	
	# Verificar si usuario existe usando BD.select_one
	if db.has_method("select_one"):
		var result = db.select_one("SELECT COUNT(*) as count FROM usuarios WHERE username = ? OR email = ?", [usuario, email])
		
		if result and result.get("count", 0) > 0:
			mostrar_error("El nombre de usuario o email ya existen")
			return
	
	if not es_email_valido(email):
		mostrar_error("Email inválido")
		return
	
	if password.length() < 8:
		mostrar_error("La contraseña debe tener al menos 8 caracteres")
		return
	
	# Crear usuario en base de datos usando BD.insert
	var user_data = {
		"username": usuario,
		"password_hash": password,  # ¡En producción usar hash!
		"email": email,
		"nombre_completo": nombre,
		"rol": "operador",
		"cargo": "Operador",
		"departamento": "Atención al Cliente",
		"estado_empleado": "activo"
	}
	
	if db.has_method("insert"):
		var user_id = db.insert("usuarios", user_data)
		
		if user_id > 0:
			print("✅ Usuario creado exitosamente con ID: ", user_id)
			mostrar_error("¡Cuenta creada exitosamente! Ya puede iniciar sesión")
			dialogo_registro.hide()
			
			# Auto-login después de registro
			if input_usuario and input_password:
				input_usuario.text = usuario
				input_password.text = password
				autenticar_usuario()
		else:
			mostrar_error("Error al crear la cuenta")
	else:
		mostrar_error("Error: No se puede insertar en la base de datos")

func es_email_valido(email: String) -> bool:
	if email.is_empty():
		return false
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null
