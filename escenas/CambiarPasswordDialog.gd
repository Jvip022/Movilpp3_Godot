extends AcceptDialog

# Referencias a nodos
@onready var input_actual: LineEdit = $VBoxContainer/InputPasswordActual
@onready var input_nueva: LineEdit = $VBoxContainer/InputPasswordNueva
@onready var input_confirmar: LineEdit = $VBoxContainer/InputPasswordConfirmar
@onready var label_error: Label = $VBoxContainer/LabelErrorCambio
@onready var boton_confirmar: Button = $VBoxContainer/HBoxContainer/BotonConfirmarCambio
@onready var boton_cancelar: Button = $VBoxContainer/HBoxContainer/BotonCancelarCambio

var usuario_id: int = -1

func _ready():
	title = "Cambiar Contraseña"
	
	# Conectar señales
	if boton_confirmar:
		boton_confirmar.pressed.connect(_on_confirmar_pressed)
	else:
		printerr("❌ Botón de confirmar no encontrado")
		
	if boton_cancelar:
		boton_cancelar.pressed.connect(_on_cancelar_pressed)
	else:
		printerr("❌ Botón de cancelar no encontrado")
	
	# Obtener ID del usuario desde Global si está disponible
	if Global and Global.usuario_actual:
		usuario_id = Global.usuario_actual.get("id", -1)
	else:
		printerr("⚠️ Global no disponible o usuario no autenticado")

func mostrar():
	# Obtener ID del usuario actual
	if Global and Global.usuario_actual:
		usuario_id = Global.usuario_actual.get("id", -1)
	else:
		usuario_id = -1
	
	if usuario_id == -1:
		if label_error:
			label_error.text = "Error: No hay usuario autenticado"
			label_error.visible = true
		print("❌ No hay usuario autenticado")
		return
	
	# Mostrar diálogo
	popup_centered(Vector2(400, 350))
	
	# Limpiar campos
	if input_actual:
		input_actual.text = ""
	if input_nueva:
		input_nueva.text = ""
	if input_confirmar:
		input_confirmar.text = ""
	if label_error:
		label_error.text = ""
		label_error.visible = false

func _on_confirmar_pressed():
	if usuario_id == -1:
		if label_error:
			label_error.text = "Error: No hay usuario autenticado"
			label_error.visible = true
		return
	
	var password_actual = input_actual.text if input_actual else ""
	var password_nueva = input_nueva.text if input_nueva else ""
	var password_confirmar = input_confirmar.text if input_confirmar else ""
	
	# Validaciones básicas
	if password_actual.is_empty() or password_nueva.is_empty() or password_confirmar.is_empty():
		if label_error:
			label_error.text = "Todos los campos son obligatorios"
			label_error.visible = true
		return
	
	if password_nueva != password_confirmar:
		if label_error:
			label_error.text = "Las contraseñas no coinciden"
			label_error.visible = true
		return
	
	# Validar requisitos de complejidad
	if not cumple_requisitos_complejidad(password_nueva):
		if label_error:
			label_error.text = "La contraseña debe tener mínimo 8 caracteres, 1 mayúscula, 1 número y 1 carácter especial"
			label_error.visible = true
		return
	
	# Obtener base de datos
	var db = SQLite.new()
	db.path = "res://data/sistema.db"
	db.open_db()
	
	# Verificar contraseña actual
	var resultado = db.fetch_array("SELECT password_hash FROM usuarios WHERE id = %d" % usuario_id)
	
	if resultado.is_empty():
		if label_error:
			label_error.text = "Error: Usuario no encontrado"
			label_error.visible = true
		db.close_db()
		return
	
	var password_hash_actual = resultado[0]["password_hash"]
	
	# Verificar que la contraseña actual sea correcta
	if password_actual.sha256_text() != password_hash_actual:
		if label_error:
			label_error.text = "La contraseña actual es incorrecta"
			label_error.visible = true
		db.close_db()
		return
	
	# Verificar que la nueva contraseña no sea igual a la anterior
	if password_nueva.sha256_text() == password_hash_actual:
		if label_error:
			label_error.text = "La nueva contraseña debe ser diferente a la actual"
			label_error.visible = true
		db.close_db()
		return
	
	# Actualizar contraseña
	var nuevo_hash = password_nueva.sha256_text()
	db.query("UPDATE usuarios SET password_hash = '%s', updated_at = CURRENT_TIMESTAMP WHERE id = %d" % [nuevo_hash, usuario_id])
	
	# Registrar actividad (si existe la tabla)
	registrar_actividad_cambio()
	
	db.close_db()
	
	print("✅ Contraseña cambiada exitosamente")
	hide()
	
	# Mostrar mensaje de éxito
	var mensaje_exito = AcceptDialog.new()
	mensaje_exito.title = "Éxito"
	mensaje_exito.dialog_text = "¡Contraseña cambiada exitosamente!"
	get_tree().root.add_child(mensaje_exito)
	mensaje_exito.popup_centered()
	
	# Limpiar después de cerrar
	mensaje_exito.confirmed.connect(mensaje_exito.queue_free)

func _on_cancelar_pressed():
	hide()

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

func registrar_actividad_cambio():
	# Registrar actividad en la base de datos
	var db = SQLite.new()
	db.path = "res://data/sistema.db"
	db.open_db()
	
	# Crear tabla de historial si no existe
	var crear_historial_sql = """
	CREATE TABLE IF NOT EXISTS historial_usuarios (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		usuario_id INTEGER NOT NULL,
		tipo_evento TEXT NOT NULL,
		descripcion TEXT,
		detalles TEXT,
		ip_address TEXT DEFAULT '127.0.0.1',
		user_agent TEXT DEFAULT 'Godot',
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
	)
	"""
	db.query(crear_historial_sql)
	
	# Insertar registro
	var insert_sql = """
	INSERT INTO historial_usuarios (usuario_id, tipo_evento, descripcion, detalles)
	VALUES (%d, 'cambio_password', 'Cambio de contraseña exitoso', 'Usuario cambió su contraseña')
	""" % usuario_id
	db.query(insert_sql)
	
	db.close_db()
	print("✅ Actividad registrada en historial")
