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

# Base de datos
var db: SQLite
var usuario_actual: Dictionary
var db_path = "res://data/quejas.db"  # Cambiado para usar la BD principal

# Configuración persistente
var config_file = "user://config.cfg"

func _ready():
	# Inicializar base de datos
	db = SQLite.new()
	
	# Conectar señales
	boton_login.pressed.connect(_on_login_pressed)
	boton_registrar.pressed.connect(_on_registrar_pressed)
	boton_recuperar.pressed.connect(_on_recuperar_pressed)
	
	# Enter para login
	input_password.text_submitted.connect(_on_password_submitted)
	
	# Cargar usuario recordado
	cargar_usuario_recordado()
	
	# Aplicar efectos visuales
	aplicar_efectos_visuales()

func _on_registrar_pressed():
	mostrar_error("Funcionalidad de registro no disponible en esta versión")

func _on_recuperar_pressed():
	mostrar_error("Funcionalidad de recuperación no disponible en esta versión")

func _on_password_submitted(_text):
	_on_login_pressed()

func _on_login_pressed():
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
	
	# CONEXIÓN A BASE DE DATOS
	db.path = db_path
	var success = db.open_db()
	if not success:
		mostrar_error("Error al conectar con la base de datos")
		mostrar_carga(false)
		return
	
	print("🔗 Conexión a BD establecida")
	
	# IMPORTANTE: Usar consultas preparadas para evitar SQL injection
	var sql = "SELECT * FROM usuarios WHERE username = ? OR email = ?"
	
	# Usar query_with_bindings si está disponible, sino construir manualmente
	var params = [usuario, usuario]
	var resultado = []
	
	# Intentar diferentes métodos de consulta
	if db.has_method("query_with_bindings"):
		print("📊 Usando query_with_bindings")
		if db.query_with_bindings(sql, params):
			resultado = obtener_resultados()
	else:
		# Método alternativo: construir consulta manualmente
		print("📊 Usando método alternativo")
		var sql_manual = "SELECT * FROM usuarios WHERE username = '%s' OR email = '%s'" % [usuario.replace("'", "''"), usuario.replace("'", "''")]
		if db.query(sql_manual):
			resultado = obtener_resultados()
	
	if resultado.size() > 0:
		var user_data = resultado[0]
		print("✅ Usuario encontrado en BD")
		
		# Verificar contraseña
		if verificar_password(password, user_data.get("password_hash", "")):
			print("✅ Contraseña correcta - Login exitoso")
			
			# Guardar usuario recordado
			guardar_usuario_recordado(usuario, password)
			
			# CASO DE USO CUMPLIDO: Usuario accede al sistema
			ingresar_al_sistema(user_data)
		else:
			print("❌ Contraseña incorrecta")
			mostrar_error("Usuario o contraseña incorrectos")
	else:
		print("❌ Usuario no encontrado")
		mostrar_error("Usuario o contraseña incorrectos")
	
	db.close_db()
	mostrar_carga(false)

func obtener_resultados() -> Array:
	var resultados = []
	
	# Intentar diferentes métodos para obtener resultados
	if db.has_method("fetch_array"):
		print("📊 Obteniendo resultados con fetch_array")
		var row = db.fetch_array()
		while row != null and row.size() > 0:
			# Convertir array a diccionario
			var dict = {}
			var column_names = obtener_nombres_columnas()
			
			if column_names.size() > 0:
				for i in range(min(row.size(), column_names.size())):
					dict[column_names[i]] = row[i]
			else:
				# Si no tenemos nombres de columnas, usar índices
				for i in range(row.size()):
					dict["col_%d" % i] = row[i]
			
			resultados.append(dict)
			row = db.fetch_array()
	elif "rows" in db and typeof(db.rows) == TYPE_ARRAY:
		print("📊 Obteniendo resultados con rows property")
		resultados = db.rows
	elif "query_result" in db and typeof(db.query_result) == TYPE_ARRAY:
		print("📊 Obteniendo resultados con query_result property")
		resultados = db.query_result
	else:
		print("⚠️ No se pudo obtener resultados")
	
	return resultados

func obtener_nombres_columnas() -> Array:
	var column_names = []
	
	if db.has_method("get_columns"):
		column_names = db.get_columns()
	elif db.has_method("column_names"):
		column_names = db.column_names
	elif "column_names" in db:
		column_names = db.column_names
	
	return column_names

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
	
	# Crear un singleton Global temporal si no existe
	if get_node_or_null("/root/Global"):
		var global_singleton = get_node("/root/Global")  
		global_singleton.usuario_actual = {
			"id": user_data.get("id", 0),
			"username": user_data.get("username", ""),
			"nombre": user_data.get("nombre_completo", ""),
			"email": user_data.get("email", ""),
			"rol": user_data.get("rol", "operador"),
			"departamento": user_data.get("departamento", ""),
			"cargo": user_data.get("cargo", "")
		}
	else:
		# Si no existe Global, crear uno temporal
		print("⚠️ Global no encontrado, creando sesión local")
		usuario_actual = user_data
	
	# CASO DE USO CUMPLIDO: Usuario accede a pantalla principal
	cambiar_a_escena_principal()

func cambiar_a_escena_principal():
	# Transición suave
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	# Cargar escena principal
	var escena_principal_path = "res://escenas/GestorQuejas.tscn"
	if ResourceLoader.exists(escena_principal_path):
		get_tree().change_scene_to_file(escena_principal_path)
	else:
		# Intentar otra ruta común
		escena_principal_path = "res://GestorQuejas.tscn"
		if ResourceLoader.exists(escena_principal_path):
			get_tree().change_scene_to_file(escena_principal_path)
		else:
			mostrar_error("Error: No se encontró la escena principal")
			print("❌ Error: No se encontró la escena principal")
			# Volver a mostrar la pantalla de login
			var tween2 = create_tween()
			tween2.tween_property(self, "modulate:a", 1.0, 0.3)

func cargar_usuario_recordado():
	var config = ConfigFile.new()
	var err = config.load(config_file)
	if err == OK:
		var usuario = config.get_value("recordar", "usuario", "")
		var password = config.get_value("recordar", "password", "")
		var recordar = config.get_value("recordar", "recordar", false)
		
		if recordar and not usuario.is_empty():
			input_usuario.text = usuario
			input_password.text = password
		if check_recordar:
			check_recordar.button_pressed = recordar
	else:
		print("ℹ️ No se encontró configuración previa")

func aplicar_efectos_visuales():
	# Configurar focus
	boton_login.focus_mode = Control.FOCUS_ALL
	boton_registrar.focus_mode = Control.FOCUS_ALL
	boton_recuperar.focus_mode = Control.FOCUS_ALL
	
	# Aplicar estilos adicionales si es necesario
	mensaje_error.add_theme_color_override("font_color", Color("#ff4444"))
	mensaje_error.add_theme_font_size_override("font_size", 14)

func hash_password(password: String) -> String:
	# Usar SHA256 para hashing
	return password.sha256_text()

func verificar_password(password: String, hash_almacenado: String) -> bool:
	# Nota: En la base de datos original, la contraseña no está hasheada (es "admin123")
	# Para compatibilidad, primero intentamos verificar el hash, luego la contraseña en texto plano
	if hash_password(password) == hash_almacenado:
		return true
	# Si el hash no coincide, verificar si la contraseña está en texto plano
	elif password == hash_almacenado:
		return true
	return false

func guardar_usuario_recordado(usuario: String, password: String):
	var config = ConfigFile.new()
	var recordar = check_recordar.button_pressed if check_recordar else false
	
	config.set_value("recordar", "usuario", usuario if recordar else "")
	config.set_value("recordar", "password", password if recordar else "")
	config.set_value("recordar", "recordar", recordar)
	
	var err = config.save(config_file)
	if err != OK:
		print("❌ Error al guardar configuración: ", err)
	else:
		print("✅ Configuración guardada")
