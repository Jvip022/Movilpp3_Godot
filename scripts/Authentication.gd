extends Control

# Referencias a nodos
@onready var input_usuario: LineEdit = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputUsuario
@onready var input_password: LineEdit = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputPassword
@onready var check_recordar: CheckBox = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/CheckBox
@onready var boton_login: Button = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/BotonLogin
@onready var boton_registrar: Button = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/HBoxContainer/BotonRegistrar
@onready var boton_recuperar: Button = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/HBoxContainer/BotonRecuperar
@onready var mensaje_error: Label = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/MensajeError
@onready var panel_cargando: Panel = $CenterContainer/PanelLogin/PanelCargando
@onready var dialogo_recuperar: AcceptDialog = $DialogoRecuperar
@onready var dialogo_registro: AcceptDialog = $DialogoRegistro
@onready var dialogo_cambiar_password: AcceptDialog

# Base de datos
var db: SQLite
var usuario_actual: Dictionary

# Configuración persistente
var config_file = "user://config.cfg"

func _ready():
	# Inicializar base de datos
	db = SQLite.new()
	db.path = "user://sistema.db"  # Cambiado a user:// para guardar datos persistentes
	
	# Conectar señales
	boton_login.pressed.connect(_on_login_pressed)
	boton_registrar.pressed.connect(_on_registrar_pressed)
	boton_recuperar.pressed.connect(_on_recuperar_pressed)
	
	# Enter para login
	input_password.text_submitted.connect(_on_password_submitted)
	
	# Configurar diálogos
	configurar_dialogo_recuperar()
	configurar_dialogo_registro()
	
	# Crear tablas y verificar usuario admin
	inicializar_base_datos()
	
	# Crear diálogo para cambiar contraseña
	crear_dialogo_cambiar_password()
	
	# Cargar usuario recordado
	cargar_usuario_recordado()
	
	# Aplicar efectos visuales
	aplicar_efectos_visuales()

func inicializar_base_datos():
	# Abrir o crear base de datos
	var error = db.open_db()
	if error:
		print("❌ Error al abrir base de datos: ", error)
		mostrar_error("Error al inicializar base de datos")
		return
	
	# Crear tablas si no existen
	crear_tablas_si_no_existen()
	
	# Verificar usuario admin
	verificar_usuario_admin()
	
	db.close_db()
	print("✅ Base de datos inicializada")

func crear_tablas_si_no_existen():
	# Tabla de usuarios
	var usuarios_sql = """
	CREATE TABLE IF NOT EXISTS usuarios (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT UNIQUE NOT NULL,
		email TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL,
		nombre_completo TEXT NOT NULL,
		rol TEXT DEFAULT 'operador',
		cargo TEXT,
		departamento TEXT,
		estado_empleado TEXT DEFAULT 'activo',
		ultimo_login TEXT,
		intentos_fallidos INTEGER DEFAULT 0,
		bloqueado_hasta TEXT,
		token_recuperacion TEXT,
		token_expiracion TEXT,
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		updated_at TEXT DEFAULT CURRENT_TIMESTAMP
	);
	"""
	
	var error = db.query(usuarios_sql)
	if error:
		print("❌ Error al crear tabla usuarios: ", db.error_message)
	else:
		print("✅ Tabla 'usuarios' verificada/creada")

func verificar_usuario_admin():
	# Consulta para verificar si existe usuario admin
	var sql = "SELECT * FROM usuarios WHERE username = 'admin';"
	var error = db.query(sql)
	if error:
		print("❌ Error en consulta: ", db.error_message)
		return
	
	var resultado = []
	while db.fetch_row():
		var row = {}
		for i in range(db.get_column_count()):
			var column_name = db.get_column_name(i)
			row[column_name] = db.get_column_value(i)
		resultado.append(row)
	
	if resultado.is_empty():
		print("⚠️ Creando usuario admin...")
		# Crear usuario admin
		var admin_data = {
			"username": "admin",
			"email": "admin@sistema.com",
			"password_hash": hash_password("admin123"),
			"nombre_completo": "Administrador del Sistema",
			"rol": "administrador",
			"cargo": "Administrador",
			"departamento": "TI"
		}
		
		var columnas = []
		var valores = []
		var placeholders = []
		for key in admin_data.keys():
			columnas.append(key)
			valores.append(admin_data[key])
			placeholders.append("?")
		
		var insert_sql = "INSERT INTO usuarios (" + ", ".join(columnas) + ") VALUES (" + ", ".join(placeholders) + ");"
		
		# Usar consulta preparada
		error = db.query_with_bindings(insert_sql, valores)
		if error:
			print("❌ Error al crear usuario admin: ", db.error_message)
		else:
			print("✅ Usuario admin creado")
	else:
		print("✅ Usuario admin ya existe")

# =============================================
# CASO DE USO: AUTENTICAR USUARIO
# =============================================
func _on_login_pressed():
	autenticar_usuario()

func _on_password_submitted(_text):
	autenticar_usuario()

func autenticar_usuario():
	print("=== INICIANDO AUTENTICACIÓN ===")
	
	var usuario = input_usuario.text.strip_edges()
	var password = input_password.text
	
	# Validaciones básicas
	if usuario.is_empty() or password.is_empty():
		mostrar_error("Por favor, complete todos los campos")
		return
	
	# Mostrar estado de carga
	mostrar_carga(true)
	
	# Consultar usuario en la base de datos
	var error = db.open_db()
	if error:
		mostrar_error("Error al conectar con la base de datos")
		mostrar_carga(false)
		return
	
	# Consulta preparada para evitar SQL injection
	var sql = "SELECT * FROM usuarios WHERE (username = ? OR email = ?) AND estado_empleado = 'activo';"
	var bindings = [usuario, usuario]
	
	error = db.query_with_bindings(sql, bindings)
	if error:
		mostrar_error("Error en consulta de usuario")
		db.close_db()
		mostrar_carga(false)
		return
	
	var resultado = []
	while db.fetch_row():
		var row = {}
		for i in range(db.get_column_count()):
			var column_name = db.get_column_name(i)
			row[column_name] = db.get_column_value(i)
		resultado.append(row)
	
	if not resultado.is_empty():
		var user_data = resultado[0]
		print("✅ Usuario encontrado en BD")
		
		# Verificar si la cuenta está bloqueada
		if user_data.get("bloqueado_hasta"):
			var ahora = Time.get_datetime_string_from_system()
			var bloqueo_hasta = user_data["bloqueado_hasta"]
			if ahora < bloqueo_hasta:
				mostrar_error("Cuenta temporalmente bloqueada. Intente más tarde")
				db.close_db()
				mostrar_carga(false)
				return
		
		# Verificar contraseña
		if verificar_password(password, user_data["password_hash"]):
			print("✅ Contraseña correcta - Login exitoso")
			
			# Guardar datos del usuario actual
			usuario_actual = user_data
			
			# Actualizar último login y resetear intentos fallidos
			var update_sql = "UPDATE usuarios SET ultimo_login = datetime('now'), intentos_fallidos = 0 WHERE id = ?;"
			var update_error = db.query_with_bindings(update_sql, [user_data["id"]])
			if update_error:
				print("⚠️ Error al actualizar último login: ", db.error_message)
			
			# Guardar usuario recordado
			guardar_usuario_recordado(usuario, password)
			
			# Registrar actividad
			registrar_actividad(user_data["id"], "login_exitoso")
			
			# CASO DE USO CUMPLIDO: Usuario accede al sistema
			ingresar_al_sistema(user_data)
		else:
			print("❌ Contraseña incorrecta")
			
			# Incrementar intentos fallidos
			var intentos = user_data.get("intentos_fallidos", 0) + 1
			
			# Actualizar intentos fallidos
			var update_intentos_sql = "UPDATE usuarios SET intentos_fallidos = ? WHERE id = ?;"
			error = db.query_with_bindings(update_intentos_sql, [intentos, user_data["id"]])
			
			if intentos >= 5:
				# Bloquear cuenta por 30 minutos
				var bloqueo_sql = "UPDATE usuarios SET bloqueado_hasta = datetime('now', '+30 minutes') WHERE id = ?;"
				db.query_with_bindings(bloqueo_sql, [user_data["id"]])
				mostrar_error("Cuenta bloqueada por 30 minutos debido a múltiples intentos fallidos")
			else:
				var intentos_restantes = 5 - intentos
				mostrar_error("Credenciales incorrectas. Intentos restantes: " + str(intentos_restantes))
	else:
		print("❌ Usuario no encontrado")
		mostrar_error("Usuario o contraseña incorrectos")
	
	db.close_db()
	mostrar_carga(false)

func mostrar_error(mensaje: String):
	print("ERROR: ", mensaje)
	mensaje_error.text = mensaje
	mensaje_error.visible = true
	
	# Animación de error
	var tween = create_tween()
	tween.tween_property(mensaje_error, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(3.0).timeout
	tween = create_tween()
	tween.tween_property(mensaje_error, "modulate:a", 0.0, 0.5)

func mostrar_carga(mostrar: bool):
	panel_cargando.visible = mostrar
	boton_login.disabled = mostrar

func ingresar_al_sistema(user_data: Dictionary):
	print("=== INGRESANDO AL SISTEMA ===")
	print("Datos del usuario: ", user_data)
	
	# Guardar sesión actual globalmente
	# Primero verificar si existe el script Global.gd
	if not ResourceLoader.exists("res://scripts/Global.gd"):
		# Crear script global dinámicamente si no existe
		var global_script = GDScript.new()
		global_script.source_code = """
extends Node
class_name Global

var usuario_actual: Dictionary = {}

func _ready():
	pass
"""
		ResourceSaver.save(global_script, "res://scripts/Global.gd")
		print("✅ Script Global.gd creado")
	
	# Ahora cargarlo
	var Global = load("res://scripts/Global.gd")
	
	# Crear una instancia del singleton si no existe
	if not get_node("/root/Global"):
		var global_instance = Global.new()
		get_tree().root.add_child(global_instance)
		global_instance.name = "Global"
	
	# Acceder a la instancia
	var global_instance = get_node("/root/Global")
	global_instance.usuario_actual = {
		"id": user_data["id"],
		"username": user_data["username"],
		"nombre": user_data["nombre_completo"],
		"email": user_data["email"],
		"rol": user_data["rol"],
		"departamento": user_data.get("departamento", ""),
		"cargo": user_data.get("cargo", "")
	}
	
	# CASO DE USO CUMPLIDO: Usuario accede a pantalla principal con menú según rol
	cambiar_a_escena_principal()

func cambiar_a_escena_principal():
	# Transición suave
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	
	# Cargar escena principal
	var escena_principal_path = "res://escenas/GestorQuejas.tscn"
	if ResourceLoader.exists(escena_principal_path):
		var escena_principal = load(escena_principal_path).instantiate()
		get_tree().root.add_child(escena_principal)
		get_tree().current_scene = escena_principal
		
		# Eliminar esta escena
		queue_free()
	else:
		mostrar_error("Error: No se encontró la escena principal")
		print("❌ Error: No se encontró ", escena_principal_path)

# =============================================
# CASO DE USO: CAMBIAR CONTRASEÑA
# =============================================
func crear_dialogo_cambiar_password():
	# Crear diálogo para cambiar contraseña
	dialogo_cambiar_password = AcceptDialog.new()
	dialogo_cambiar_password.title = "Cambiar Contraseña"
	dialogo_cambiar_password.size = Vector2(400, 350)
	dialogo_cambiar_password.dialog_hide_on_ok = false
	
	# Contenedor principal
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Campo para contraseña actual
	var label_actual = Label.new()
	label_actual.text = "Contraseña actual:"
	vbox.add_child(label_actual)
	
	var input_actual = LineEdit.new()
	input_actual.name = "InputPasswordActual"
	input_actual.placeholder_text = "Ingrese su contraseña actual"
	input_actual.secret = true
	input_actual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(input_actual)
	
	# Campo para nueva contraseña
	var label_nueva = Label.new()
	label_nueva.text = "Nueva contraseña:"
	vbox.add_child(label_nueva)
	
	var input_nueva = LineEdit.new()
	input_nueva.name = "InputPasswordNueva"
	input_nueva.placeholder_text = "Ingrese nueva contraseña"
	input_nueva.secret = true
	input_nueva.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(input_nueva)
	
	# Campo para confirmar nueva contraseña
	var label_confirmar = Label.new()
	label_confirmar.text = "Confirmar nueva contraseña:"
	vbox.add_child(label_confirmar)
	
	var input_confirmar = LineEdit.new()
	input_confirmar.name = "InputPasswordConfirmar"
	input_confirmar.placeholder_text = "Confirme la nueva contraseña"
	input_confirmar.secret = true
	input_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(input_confirmar)
	
	# Mensaje de requisitos
	var label_requisitos = Label.new()
	label_requisitos.name = "LabelRequisitos"
	label_requisitos.text = "Requisitos: Mínimo 8 caracteres, 1 mayúscula, 1 número, 1 carácter especial"
	label_requisitos.autowrap_mode = TextServer.AUTOWRAP_WORD
	label_requisitos.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(label_requisitos)
	
	# Botones
	var hbox_botones = HBoxContainer.new()
	hbox_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var boton_confirmar = Button.new()
	boton_confirmar.name = "BotonConfirmarCambio"
	boton_confirmar.text = "Cambiar Contraseña"
	boton_confirmar.pressed.connect(_on_confirmar_cambio_password)
	
	var boton_cancelar = Button.new()
	boton_cancelar.name = "BotonCancelarCambio"
	boton_cancelar.text = "Cancelar"
	boton_cancelar.pressed.connect(_on_cancelar_cambio_password)
	
	hbox_botones.add_child(boton_confirmar)
	hbox_botones.add_child(boton_cancelar)
	vbox.add_child(hbox_botones)
	
	# Mensaje de error
	var label_error_cambio = Label.new()
	label_error_cambio.name = "LabelErrorCambio"
	label_error_cambio.visible = false
	label_error_cambio.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(label_error_cambio)
	
	dialogo_cambiar_password.add_child(vbox)
	add_child(dialogo_cambiar_password)
	
	print("✅ Diálogo para cambiar contraseña creado")

func mostrar_dialogo_cambiar_password():
	# Precondición: Usuario debe estar registrado y autenticado
	if usuario_actual.is_empty():
		mostrar_error("Debe iniciar sesión primero")
		return
	
	# Limpiar campos
	var input_actual = dialogo_cambiar_password.find_child("InputPasswordActual")
	var input_nueva = dialogo_cambiar_password.find_child("InputPasswordNueva")
	var input_confirmar = dialogo_cambiar_password.find_child("InputPasswordConfirmar")
	var label_error = dialogo_cambiar_password.find_child("LabelErrorCambio")
	
	if input_actual:
		input_actual.text = ""
	if input_nueva:
		input_nueva.text = ""
	if input_confirmar:
		input_confirmar.text = ""
	if label_error:
		label_error.visible = false
	
	dialogo_cambiar_password.popup_centered()

func _on_confirmar_cambio_password():
	var input_actual = dialogo_cambiar_password.find_child("InputPasswordActual")
	var input_nueva = dialogo_cambiar_password.find_child("InputPasswordNueva")
	var input_confirmar = dialogo_cambiar_password.find_child("InputPasswordConfirmar")
	var label_error = dialogo_cambiar_password.find_child("LabelErrorCambio")
	
	if not input_actual or not input_nueva or not input_confirmar:
		return
	
	var password_actual = input_actual.text
	var password_nueva = input_nueva.text
	var password_confirmar = input_confirmar.text
	
	# Validaciones
	if password_actual.is_empty() or password_nueva.is_empty() or password_confirmar.is_empty():
		mostrar_error_cambio_password("Todos los campos son obligatorios", label_error)
		return
	
	if password_nueva != password_confirmar:
		mostrar_error_cambio_password("Las nuevas contraseñas no coinciden", label_error)
		return
	
	# CASO DE USO: Validar requisitos de complejidad
	if not cumple_requisitos_complejidad(password_nueva):
		mostrar_error_cambio_password(
			"La contraseña no cumple con los requisitos: Mínimo 8 caracteres, 1 mayúscula, 1 número, 1 carácter especial",
			label_error
		)
		return
	
	# Verificar contraseña actual
	var error = db.open_db()
	if error:
		mostrar_error_cambio_password("Error al conectar con la base de datos", label_error)
		return
	
	var sql = "SELECT password_hash FROM usuarios WHERE id = ?;"
	var bindings = [usuario_actual["id"]]
	
	error = db.query_with_bindings(sql, bindings)
	if error:
		mostrar_error_cambio_password("Error en consulta", label_error)
		db.close_db()
		return
	
	var resultado = []
	while db.fetch_row():
		var row = {}
		for i in range(db.get_column_count()):
			var column_name = db.get_column_name(i)
			row[column_name] = db.get_column_value(i)
		resultado.append(row)
	
	if resultado.is_empty():
		mostrar_error_cambio_password("Error: Usuario no encontrado", label_error)
		db.close_db()
		return
	
	var password_hash_actual = resultado[0]["password_hash"]
	
	if not verificar_password(password_actual, password_hash_actual):
		mostrar_error_cambio_password("La contraseña actual es incorrecta", label_error)
		db.close_db()
		return
	
	# CASO DE USO: Validar que no sea igual a la anterior
	if verificar_password(password_nueva, password_hash_actual):
		mostrar_error_cambio_password("La nueva contraseña debe ser diferente a la actual", label_error)
		db.close_db()
		return
	
	# Actualizar contraseña
	var nuevo_hash = hash_password(password_nueva)
	var update_sql = "UPDATE usuarios SET password_hash = ?, updated_at = datetime('now') WHERE id = ?;"
	error = db.query_with_bindings(update_sql, [nuevo_hash, usuario_actual["id"]])
	if error:
		mostrar_error_cambio_password("Error al actualizar contraseña", label_error)
		db.close_db()
		return
	
	# Registrar actividad
	registrar_actividad(usuario_actual["id"], "cambio_password")
	
	db.close_db()
	
	print("✅ Contraseña actualizada exitosamente")
	
	# Postcondición: Contraseña cambiada exitosamente
	dialogo_cambiar_password.hide()
	mostrar_error("¡Contraseña cambiada exitosamente! (será válida en su próximo inicio de sesión)")
	
	# Limpiar campos de login
	input_password.text = ""

func _on_cancelar_cambio_password():
	dialogo_cambiar_password.hide()

func mostrar_error_cambio_password(mensaje: String, label_error: Label):
	if label_error:
		label_error.text = mensaje
		label_error.visible = true

func cumple_requisitos_complejidad(password: String) -> bool:
	# Mínimo 8 caracteres
	if password.length() < 8:
		return false
	
	# Al menos una mayúscula
	if not password.matchn(".*[A-Z].*"):
		return false
	
	# Al menos un número
	if not password.matchn(".*[0-9].*"):
		return false
	
	# Al menos un carácter especial
	if not password.matchn(".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?].*"):
		return false
	
	return true

# =============================================
# FUNCIONES AUXILIARES
# =============================================
func hash_password(password: String) -> String:
	# Usar SHA256 para hashing (en producción considerar bcrypt)
	return password.sha256_text()

func verificar_password(password: String, hash_almacenado: String) -> bool:
	return hash_password(password) == hash_almacenado

func registrar_actividad(usuario_id: int, tipo_evento: String, detalles: String = ""):
	# Primero crear tabla de historial si no existe
	var error = db.open_db()
	if error:
		return
	
	var crear_historial_sql = """
	CREATE TABLE IF NOT EXISTS historial_usuarios (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		usuario_id INTEGER NOT NULL,
		tipo_evento TEXT NOT NULL,
		descripcion TEXT,
		detalles TEXT,
		ip_address TEXT,
		user_agent TEXT,
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
	);
	"""
	db.query(crear_historial_sql)
	
	# Insertar registro de actividad
	var descripcion = get_descripcion_evento(tipo_evento)
	var insert_sql = """
	INSERT INTO historial_usuarios (usuario_id, tipo_evento, descripcion, detalles, ip_address, user_agent)
	VALUES (?, ?, ?, ?, ?, ?);
	"""
	
	var bindings = [
		usuario_id,
		tipo_evento,
		descripcion,
		detalles,
		"127.0.0.1",  # En producción, obtener IP real
		"Godot Engine"  # En producción, obtener user agent real
	]
	
	db.query_with_bindings(insert_sql, bindings)
	db.close_db()
	
	print("✅ Actividad registrada: ", tipo_evento)

func get_descripcion_evento(tipo: String) -> String:
	match tipo:
		"login_exitoso": return "Inicio de sesión exitoso"
		"cambio_password": return "Cambio de contraseña"
		"recuperacion_password": return "Solicitud de recuperación de contraseña"
		_: return "Actividad del sistema"

func guardar_usuario_recordado(usuario: String, password: String):
	var config = ConfigFile.new()
	var recordar = check_recordar.button_pressed if check_recordar else false
	
	config.set_value("recordar", "usuario", usuario if recordar else "")
	config.set_value("recordar", "password", password if recordar else "")
	config.set_value("recordar", "recordar", recordar)
	
	var err = config.save(config_file)
	if err:
		print("❌ Error al guardar configuración: ", err)

func cargar_usuario_recordado():
	var config = ConfigFile.new()
	var err = config.load(config_file)
	if not err:
		var usuario = config.get_value("recordar", "usuario", "")
		var password = config.get_value("recordar", "password", "")
		var recordar = config.get_value("recordar", "recordar", false)
		
		if recordar and not usuario.is_empty():
			input_usuario.text = usuario
			input_password.text = password
		if check_recordar:
			check_recordar.button_pressed = recordar

func aplicar_efectos_visuales():
	boton_login.focus_mode = Control.FOCUS_ALL
	boton_registrar.focus_mode = Control.FOCUS_ALL
	boton_recuperar.focus_mode = Control.FOCUS_ALL

# =============================================
# FUNCIONES PARA OTROS DIÁLOGOS
# =============================================
func configurar_dialogo_recuperar():
	# Configurar diálogo de recuperación existente
	pass

func configurar_dialogo_registro():
	# Configurar diálogo de registro existente
	pass

func _on_registrar_pressed():
	if dialogo_registro:
		dialogo_registro.popup_centered()

func _on_recuperar_pressed():
	if dialogo_recuperar:
		dialogo_recuperar.popup_centered()
