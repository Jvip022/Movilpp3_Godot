extends Control

@onready var input_usuario = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputUsuario
@onready var input_password = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/InputPassword
@onready var check_recordar = $CenterContainer/PanelLogin/VBoxContainer/ContenedorCampos/CheckRecordar
@onready var boton_login = $CenterContainer/PanelLogin/VBoxContainer/BotonLogin
@onready var boton_registrar = $CenterContainer/PanelLogin/VBoxContainer/HBoxContainer/BotonRegistrar
@onready var boton_recuperar = $CenterContainer/PanelLogin/VBoxContainer/HBoxContainer/BotonRecuperar
@onready var mensaje_error = $CenterContainer/PanelLogin/VBoxContainer/MensajeError
@onready var panel_cargando = $CenterContainer/PanelLogin/PanelCargando
@onready var dialogo_recuperar = $DialogoRecuperar
@onready var dialogo_registro = $DialogoRegistro

# Base de datos de usuarios (en producción usarías SQLite o API)
var usuarios_db = {
	"admin": {"password": "admin123", "nombre": "Administrador", "email": "admin@sistema.com", "rol": "admin"},
	"usuario1": {"password": "password123", "nombre": "Juan Pérez", "email": "juan@ejemplo.com", "rol": "usuario"}
}

# Configuración persistente
var config_file = "user://config.cfg"

func _ready():
	# Conectar señales
	boton_login.pressed.connect(_on_login_pressed)
	boton_registrar.pressed.connect(_on_registrar_pressed)
	boton_recuperar.pressed.connect(_on_recuperar_pressed)
	
	# Enter para login
	input_password.text_submitted.connect(_on_password_submitted)
	
	# Configurar diálogos
	dialogo_recuperar.get_ok_button().visible = false
	dialogo_recuperar.get_cancel_button().text = "Cancelar"
	dialogo_recuperar.register_text_enter(dialogo_recuperar.get_node("VBoxContainer/InputEmailRecuperar"))
	
	# Cargar usuario recordado
	cargar_usuario_recordado()
	
	# Aplicar efectos visuales
	aplicar_efectos_visuales()

func aplicar_efectos_visuales():
	# Crear gradiente para el fondo
	var gradient = Gradient.new()
	gradient.colors = [Color("#2c3e50"), Color("#3498db")]
	gradient.offsets = [0.0, 1.0]
	
	$ColorRect.material = ShaderMaterial.new()
	var shader_code = """
    shader_type canvas_item;
    uniform vec4 color1 : source_color;
    uniform vec4 color2 : source_color;
    
    void fragment() {
        COLOR = mix(color1, color2, UV.y);
    }
    """
	$ColorRect.material.shader = Shader.new()
	$ColorRect.material.shader.code = shader_code
	$ColorRect.material.set_shader_parameter("color1", Color("#2c3e50"))
	$ColorRect.material.set_shader_parameter("color2", Color("#3498db"))

func cargar_usuario_recordado():
	var config = ConfigFile.new()
	if config.load(config_file) == OK:
		if config.has_section_key("login", "recordar") and config.get_value("login", "recordar"):
			var usuario = config.get_value("login", "usuario", "")
			var password = config.get_value("login", "password", "")
			
			input_usuario.text = usuario
			input_password.text = password
			check_recordar.button_pressed = true

func guardar_usuario_recordado(usuario: String, password: String):
	var config = ConfigFile.new()
	
	if check_recordar.button_pressed:
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
	var usuario = input_usuario.text.strip_edges()
	var password = input_password.text
	
	# Validaciones básicas
	if usuario.is_empty() or password.is_empty():
		mostrar_error("Por favor, complete todos los campos")
		return
	
	# Mostrar estado de carga
	mostrar_carga(true)
	
	# Simular tiempo de verificación (en producción sería asíncrono)
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
	# Guardar sesión actual
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
	var escena_principal = preload("res://escenas/escena_principal.tscn").instantiate()
	get_tree().root.add_child(escena_principal)
	get_tree().current_scene = escena_principal
	
	# Eliminar esta escena
	queue_free()

func mostrar_error(mensaje: String):
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
	boton_registrar.disabled = mostrar
	boton_recuperar.disabled = mostrar

func _on_registrar_pressed():
	dialogo_registro.popup_centered(Vector2(400, 400))
	
	# Limpiar campos
	dialogo_registro.get_node("ScrollContainer/VBoxContainer/InputNombreRegistro").text = ""
	dialogo_registro.get_node("ScrollContainer/VBoxContainer/InputEmailRegistro").text = ""
	dialogo_registro.get_node("ScrollContainer/VBoxContainer/InputUsuarioRegistro").text = ""
	dialogo_registro.get_node("ScrollContainer/VBoxContainer/InputPasswordRegistro").text = ""
	dialogo_registro.get_node("ScrollContainer/VBoxContainer/InputConfirmarPassword").text = ""

func _on_recuperar_pressed():
	dialogo_recuperar.popup_centered()
	
	# Conectar botón de enviar
	var boton_enviar = dialogo_recuperar.get_node("VBoxContainer/BotonEnviarRecuperar")
	if not boton_enviar.is_connected("pressed", Callable(self, "_on_enviar_recuperar_pressed")):
		boton_enviar.pressed.connect(_on_enviar_recuperar_pressed)

func _on_enviar_recuperar_pressed():
	var email = dialogo_recuperar.get_node("VBoxContainer/InputEmailRecuperar").text
	
	if es_email_valido(email):
		# Aquí enviarías el email (simulado)
		print("Enviando enlace de recuperación a: ", email)
		mostrar_error("Se ha enviado un enlace de recuperación a su email")
		dialogo_recuperar.hide()
	else:
		mostrar_error("Email inválido")

func es_email_valido(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

# Función para registrar nuevo usuario (simplificada)
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
	dialogo_registro.hide()
	
	# Auto-login después de registro
	input_usuario.text = usuario
	input_password.text = password
	autenticar_usuario()
	
	return true
