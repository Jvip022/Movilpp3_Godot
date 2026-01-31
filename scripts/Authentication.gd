extends Control

# Referencias a nodos (con @onready)
@onready var input_usuario: LineEdit = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputUsuario
@onready var input_password: LineEdit = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputPassword
@onready var check_recordar: CheckBox = find_child("CheckRecordar")  # Búsqueda flexible
@onready var boton_login: Button = find_child("BotonLogin")
@onready var boton_registrar: Button = find_child("BotonRegistrar")
@onready var boton_recuperar: Button = find_child("BotonRecuperar")
@onready var mensaje_error: Label = find_child("MensajeError")
@onready var panel_cargando: Panel = find_child("PanelCargando")
@onready var dialogo_recuperar: AcceptDialog = $DialogoRecuperar
@onready var dialogo_registro: AcceptDialog = $DialogoRegistro

# Base de datos de usuarios (en producción usarías SQLite o API)
var usuarios_db = {
	"admin": {"password": "admin123", "nombre": "Administrador", "email": "admin@sistema.com", "rol": "admin"},
	"usuario1": {"password": "password123", "nombre": "Juan Pérez", "email": "juan@ejemplo.com", "rol": "usuario"}
}

# Configuración persistente
var config_file = "user://config.cfg"

func _ready():
	# Verificar que los nodos existen
	print("Verificando nodos...")
	print("- InputUsuario: ", input_usuario != null)
	print("- InputPassword: ", input_password != null)
	print("- CheckRecordar: ", check_recordar != null)
	print("- BotonLogin: ", boton_login != null)
	print("- BotonRegistrar: ", boton_registrar != null)
	print("- BotonRecuperar: ", boton_recuperar != null)
	
	# Conectar señales SOLO si los nodos existen
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
	
	# Configurar diálogos si existen
	if dialogo_recuperar:
		dialogo_recuperar.get_ok_button().visible = false
		var cancel_button = dialogo_recuperar.get_cancel_button()
		if cancel_button:
			cancel_button.text = "Cancelar"
		
		# Buscar el input de email dentro del diálogo
		var input_email = dialogo_recuperar.find_child("InputEmailRecuperar")
		if input_email:
			dialogo_recuperar.register_text_enter(input_email)
	
	# Cargar usuario recordado
	cargar_usuario_recordado()
	
	# Aplicar efectos visuales
	aplicar_efectos_visuales()

func aplicar_efectos_visuales():
	# Fondo simple si no hay shader
	var color_rect = $ColorRect
	if color_rect:
		# Gradiente simple con ColorRect
		color_rect.color = Color("#2c3e50")
		
		# Opcional: agregar segundo ColorRect para gradiente
		var color_rect2 = ColorRect.new()
		color_rect2.color = Color("#3498db")
		color_rect2.anchor_left = 0
		color_rect2.anchor_top = 0.5
		color_rect2.anchor_right = 1
		color_rect2.anchor_bottom = 1
		color_rect2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		color_rect.add_child(color_rect2)

func cargar_usuario_recordado():
	var config = ConfigFile.new()
	if config.load(config_file) == OK:
		if config.has_section_key("login", "recordar") and config.get_value("login", "recordar"):
			var usuario = config.get_value("login", "usuario", "")
			var password = config.get_value("login", "password", "")
			
			if input_usuario:
				input_usuario.text = usuario
			
			if input_password:
				input_password.text = password
			
			if check_recordar:
				check_recordar.button_pressed = true

func guardar_usuario_recordado(usuario: String, password: String):
	var config = ConfigFile.new()
	
	if check_recordar and check_recordar.button_pressed:
		config.set_value("login", "usuario", usuario)
		config.set_value("login", "password", password)
		config.set_value("login", "recordar", true)
	else:
		config.set_value("login", "recordar", false)
	
	config.save(config_file)

func _on_login_pressed():
	autenticar_usuario()

func _on_password_submitted(_new_text: String):
	autenticar_usuario()

func autenticar_usuario():
	if not input_usuario or not input_password:
		mostrar_error("Error: Campos de entrada no encontrados")
		return
	
	var usuario = input_usuario.text.strip_edges()
	var password = input_password.text
	
	# Validaciones básicas
	if usuario.is_empty() or password.is_empty():
		mostrar_error("Por favor, complete todos los campos")
		return
	
	# Mostrar estado de carga
	mostrar_carga(true)
	
	# Simular tiempo de verificación
	await get_tree().create_timer(1.0).timeout
	
	# Verificar credenciales
	if usuarios_db.has(usuario):
		if usuarios_db[usuario]["password"] == password:
			# Login exitoso
			guardar_usuario_recordado(usuario, password)
			ingresar_al_sistema(usuario)
		else:
			mostrar_error("Contraseña incorrecta")
	else:
		# Intentar buscar por email
		var usuario_por_email = buscar_usuario_por_email(usuario)
		if usuario_por_email and usuarios_db[usuario_por_email]["password"] == password:
			guardar_usuario_recordado(usuario_por_email, password)
			ingresar_al_sistema(usuario_por_email)
		else:
			mostrar_error("Usuario o contraseña incorrectos")
	
	mostrar_carga(false)

func buscar_usuario_por_email(email: String) -> String:
	for usuario in usuarios_db:
		if usuarios_db[usuario]["email"] == email:
			return usuario
	return ""

func ingresar_al_sistema(usuario: String):
	# Guardar sesión actual en variable global
	if not Global:
		mostrar_error("Error: Sistema Global no inicializado")
		return
	
	Global.usuario_actual = {
		"username": usuario,
		"nombre": usuarios_db[usuario]["nombre"],
		"email": usuarios_db[usuario]["email"],
		"rol": usuarios_db[usuario]["rol"]
	}
	
	print("Login exitoso: ", Global.usuario_actual)
	
	# Cargar escena principal
	cambiar_a_escena_principal()

func cambiar_a_escena_principal():
	# Transición suave
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	await tween.finished
	
	# Cargar escena principal (dashboard)
	var escena_principal =preload("res://escenas/escena_principal.tscn") .instantiate()
	get_tree().root.add_child(escena_principal)
	get_tree().current_scene = escena_principal
	
	# Eliminar esta escena
	queue_free()

func mostrar_error(mensaje: String):
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
	
	if boton_login:
		boton_login.disabled = mostrar
	
	if boton_registrar:
		boton_registrar.disabled = mostrar
	
	if boton_recuperar:
		boton_recuperar.disabled = mostrar

func _on_registrar_pressed():
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
		mostrar_error("Diálogo de registro no disponible")

func _on_recuperar_pressed():
	if dialogo_recuperar:
		dialogo_recuperar.popup_centered()
		
		# Conectar botón de enviar
		var boton_enviar = dialogo_recuperar.find_child("BotonEnviarRecuperar")
		if boton_enviar:
			if not boton_enviar.is_connected("pressed", Callable(self, "_on_enviar_recuperar_pressed")):
				boton_enviar.pressed.connect(_on_enviar_recuperar_pressed)
	else:
		mostrar_error("Diálogo de recuperación no disponible")

func _on_enviar_recuperar_pressed():
	var input_email = dialogo_recuperar.find_child("InputEmailRecuperar")
	if not input_email:
		mostrar_error("Campo de email no encontrado")
		return
	
	var email = input_email.text.strip_edges()
	
	if es_email_valido(email):
		# Aquí enviarías el email (simulado)
		print("Enviando enlace de recuperación a: ", email)
		mostrar_error("Se ha enviado un enlace de recuperación a su email")
		dialogo_recuperar.hide()
	else:
		mostrar_error("Email inválido")

func es_email_valido(email: String) -> bool:
	if email.is_empty():
		return false
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

# Función para registrar nuevo usuario
func registrar_usuario(nombre: String, email: String, usuario: String, password: String) -> bool:
	if usuarios_db.has(usuario):
		mostrar_error("El nombre de usuario ya existe")
		return false
	
	if not es_email_valido(email):
		mostrar_error("Email inválido")
		return false
	
	# Validar fortaleza de contraseña
	if password.length() < 8:
		mostrar_error("La contraseña debe tener al menos 8 caracteres")
		return false
	
	# Agregar usuario a la base de datos (simulada)
	usuarios_db[usuario] = {
		"password": password,
		"nombre": nombre,
		"email": email,
		"rol": "usuario"
	}
	
	mostrar_error("¡Cuenta creada exitosamente! Ya puede iniciar sesión")
	
	if dialogo_registro:
		dialogo_registro.hide()
	
	# Auto-login después de registro
	if input_usuario and input_password:
		input_usuario.text = usuario
		input_password.text = password
		autenticar_usuario()
	
	return true
