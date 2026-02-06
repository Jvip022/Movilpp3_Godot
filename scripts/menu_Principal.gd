extends Control

# Definición de roles
enum Roles {
	NO_AUTENTICADO,
	ADMINISTRADOR,
	SUPERVISOR_GENERAL,
	ESPECIALISTA_CALIDAD_SUCURSAL,
	AUDITOR,
	USUARIO,
	SISTEMA,
	SUPER_ADMIN  # Nuevo rol con acceso a todo
}

# Diccionario de botones y sus roles permitidos (actualizado para coincidir con los roles de BD)
var permisos_botones = {
	# Botones para SUPER_ADMIN + rol específico
	"BtnAdministrarUsuarios": [Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"BtnVisualizarTrazas": [Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"BtnBackupRestore": [Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"BtnConfigSistema": [Roles.ADMINISTRADOR, Roles.SUPER_ADMIN],
	"BtnRegistrarIncidencia": [Roles.SUPERVISOR_GENERAL, Roles.SUPER_ADMIN],
	"BtnGestorQuejas": [Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.SUPER_ADMIN],
	"BtnRegistrarNCAuditoria": [Roles.AUDITOR, Roles.SUPER_ADMIN],
	"BtnRegistrarEncuesta": [Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.SUPER_ADMIN],
	"BtnProcesarExpediente": [Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.SUPER_ADMIN],
	"BtnProcesarCorrectivas": [Roles.SUPERVISOR_GENERAL, Roles.SUPER_ADMIN],
	# Botones para múltiples roles + SUPER_ADMIN
	"BtnGenerarReportes": [Roles.ADMINISTRADOR, Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.AUDITOR, Roles.USUARIO, Roles.SUPER_ADMIN],
	"BtnCambiarPassword": [Roles.ADMINISTRADOR, Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.AUDITOR, Roles.USUARIO, Roles.SUPER_ADMIN],
	# Botones especiales
	"BtnConfiguracion": [Roles.SISTEMA, Roles.SUPER_ADMIN],
	"BtnCerrarSesion": [Roles.ADMINISTRADOR, Roles.SUPERVISOR_GENERAL, Roles.ESPECIALISTA_CALIDAD_SUCURSAL, Roles.AUDITOR, Roles.USUARIO, Roles.SUPER_ADMIN, Roles.SISTEMA]
}

# Rutas de las escenas (añadiendo la escena de cambio de contraseña)
var rutas_escenas = {
	"BtnAdministrarUsuarios": "res://escenas/AdministrarUsuarios.tscn",
	"BtnVisualizarTrazas": "res://escenas/TrazasVisualizar.tscn",
	"BtnRegistrarIncidencia": "res://escenas/RegistrarIncidencia.tscn",
	"BtnRegistrarNCAuditoria": "res://escenas/RegistrarNCAuditoria.tscn",
	"BtnGenerarReportes": "res://escenas/GenerarReportes.tscn",
	"BtnRegistrarEncuesta": "res://escenas/GenerarEncuestas.tscn",
	"BtnProcesarExpediente": "res://escenas/ProcesarExpediente.tscn",
	"BtnProcesarCorrectivas": "res://escenas/AccionesCorrectivas.tscn",
	"BtnGestorQuejas": "res://escenas/GestorQuejas.tscn",
	"BtnConfiguracion": "res://escenas/ConfiguracionSistema.tscn",
	"BtnBackupRestore": "res://escenas/BackupRestoreDB.tscn",
	"BtnConfigSistema": "res://escenas/ConfiguracionAvanzada.tscn",
	"BtnCambiarPassword": "res://escenas/cambiarPassword.tscn"
}

# Variables para los nodos
@onready var user_name_label: Label = $ContenedorPrincipal/Header/UserInfoPanel/UserInfoContainer/UserName
@onready var user_role_label: Label = $ContenedorPrincipal/Header/UserInfoPanel/UserInfoContainer/UserRole
@onready var botones_grid: GridContainer = $ContenedorPrincipal/BotonesGrid
@onready var btn_cerrar_sesion: Button = $ContenedorPrincipal/ActionButtons/BtnCerrarSesion
@onready var btn_salir: Button = $ContenedorPrincipal/ActionButtons/BtnSalir
@onready var mensaje_acceso_denegado: AcceptDialog = $MensajeAccesoDenegado
@onready var mensaje_no_autenticado: AcceptDialog = $MensajeNoAutenticado

# Variables de estado
var usuario_actual = {
	"nombre": "Invitado",
	"rol": Roles.NO_AUTENTICADO,
	"id": null,
	"email": "",
	"sucursal": ""
}

# Variables para acceso rápido a botones
var botones = {}

# Referencia a Global
var global_node

func _ready():
	# Obtener referencia a Global
	global_node = get_node("/root/Global") if has_node("/root/Global") else null
	
	
	# Inicializar diccionario de botones para acceso rápido
	inicializar_botones()
	
	# Conectar señales de todos los botones
	conectar_botones()
	
	# Verificar si hay una sesión activa
	verificar_sesion()
	
	# Configurar atajos de teclado
	configurar_atajos_teclado()

func configurar_atajos_teclado():
	# Hacer que el botón de cerrar sesión responda a Ctrl+Q
	btn_cerrar_sesion.shortcut = crear_atajo_teclado(KEY_Q, true, false, false)
	
	# Hacer que el botón de salir responda a Ctrl+Shift+Q
	btn_salir.shortcut = crear_atajo_teclado(KEY_Q, true, true, false)

func crear_atajo_teclado(keycode: int, ctrl: bool = false, shift: bool = false, alt: bool = false) -> Shortcut:
	var shortcut = Shortcut.new()
	var input_event = InputEventKey.new()
	input_event.keycode = keycode
	input_event.ctrl_pressed = ctrl
	input_event.shift_pressed = shift
	input_event.alt_pressed = alt
	shortcut.events = [input_event]
	return shortcut

func inicializar_botones():
	# Recoger todos los botones del grid
	for nodo in botones_grid.get_children():
		if nodo is Button:
			botones[nodo.name] = nodo

func conectar_botones():
	# Conectar todos los botones del grid
	for boton_nombre in botones:
		var boton = botones[boton_nombre]
		boton.pressed.connect(_on_boton_pressed.bind(boton_nombre))
	
	# Conectar botones de acción
	btn_cerrar_sesion.pressed.connect(_on_btn_cerrar_sesion_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)

func verificar_sesion():
	# Verificar si Global está disponible
	if not global_node:
		print("⚠️ Global no está disponible, usando modo invitado")
		configurar_modo_invitado()
		return
	
	# Verificar si hay usuario autenticado en Global
	if global_node.esta_autenticado():
		# Obtener datos del usuario desde Global
		var usuario_global = global_node.usuario_actual
		
		# Mapear el rol de BD al enum de Dashboard
		var rol_enum = mapear_rol_bd_a_enum(usuario_global.rol)
		
		usuario_actual = {
			"nombre": usuario_global.nombre,
			"rol": rol_enum,
			"id": usuario_global.id,
			"email": usuario_global.email,
			"sucursal": usuario_global.get("sucursal", ""),
			"departamento": usuario_global.get("departamento", ""),
			"cargo": usuario_global.get("cargo", "")
		}
		
		user_name_label.text = "Usuario: " + usuario_actual["nombre"]
		user_role_label.text = "Rol: " + usuario_global.rol
		
		print("✅ Sesión activa para: " + usuario_actual["nombre"] + " (Rol: " + usuario_global.rol + ")")
	else:
		# No hay sesión activa
		configurar_modo_invitado()
	
	# Actualizar visibilidad de botones según rol
	actualizar_visibilidad_botones()

func configurar_modo_invitado():
	usuario_actual = {
		"nombre": "Invitado",
		"rol": Roles.NO_AUTENTICADO,
		"id": null,
		"email": "",
		"sucursal": ""
	}
	user_name_label.text = "Usuario: Invitado"
	user_role_label.text = "Rol: No autenticado"
	mensaje_no_autenticado.popup_centered()

func mapear_rol_bd_a_enum(rol_bd: String) -> int:
	"""
	Convierte el rol de la base de datos (string) al enum del Dashboard.
	"""
	match rol_bd.to_upper():
		"SUPER_ADMIN", "SUPERADMIN":
			return Roles.SUPER_ADMIN
		"ADMIN", "ADMINISTRADOR":
			return Roles.ADMINISTRADOR
		"SUPERVISOR", "SUPERVISOR_GENERAL":
			return Roles.SUPERVISOR_GENERAL
		"ESPECIALISTA_CALIDAD", "ESPECIALISTA":
			return Roles.ESPECIALISTA_CALIDAD_SUCURSAL
		"AUDITOR":
			return Roles.AUDITOR
		"SISTEMA":
			return Roles.SISTEMA
		"USUARIO", "OPERADOR", "USER":
			return Roles.USUARIO
		_:
			return Roles.NO_AUTENTICADO

func actualizar_visibilidad_botones():
	# Ocultar todos los botones primero
	for boton_nombre in botones:
		botones[boton_nombre].visible = false
	
	# Si no está autenticado, solo mostrar botón de salir
	if usuario_actual["rol"] == Roles.NO_AUTENTICADO:
		btn_cerrar_sesion.visible = false
		return
	
	# Si es SUPER_ADMIN, mostrar todos los botones excepto Configuración (solo SISTEMA)
	if usuario_actual["rol"] == Roles.SUPER_ADMIN:
		for boton_nombre in botones:
			if boton_nombre == "BtnConfiguracion":
				# Configuración solo para SISTEMA, no para SUPER_ADMIN
				botones[boton_nombre].visible = false
			else:
				botones[boton_nombre].visible = true
		btn_cerrar_sesion.visible = true
		return
	
	# Para otros roles, mostrar solo los botones permitidos
	for boton_nombre in permisos_botones:
		var boton = botones.get(boton_nombre)
		if boton:
			var roles_permitidos = permisos_botones[boton_nombre]
			if usuario_actual["rol"] in roles_permitidos:
				boton.visible = true
	
	# Manejar botón de cerrar sesión
	btn_cerrar_sesion.visible = (usuario_actual["rol"] != Roles.NO_AUTENTICADO)

func _on_boton_pressed(boton_nombre: String):
	print("Botón presionado: ", boton_nombre)
	
	# Verificar autenticación primero
	if usuario_actual["rol"] == Roles.NO_AUTENTICADO:
		mensaje_no_autenticado.popup_centered()
		return
	
	# Verificar si el usuario tiene permiso
	var roles_permitidos = permisos_botones.get(boton_nombre, [])
	
	if usuario_actual["rol"] in roles_permitidos or usuario_actual["rol"] == Roles.SUPER_ADMIN:
		# SUPER_ADMIN tiene acceso a todo excepto Configuración
		if boton_nombre == "BtnConfiguracion" and usuario_actual["rol"] == Roles.SUPER_ADMIN:
			mensaje_acceso_denegado.popup_centered()
			return
		
		# Si tiene permiso, cargar la escena correspondiente
		if boton_nombre in rutas_escenas:
			var ruta_escena = rutas_escenas[boton_nombre]
			
			# Verificar si la escena existe antes de cargarla
			if ResourceLoader.exists(ruta_escena):
				get_tree().change_scene_to_file(ruta_escena)
			else:
				print("ERROR: Escena no encontrada: ", ruta_escena)
				mostrar_mensaje_error("La funcionalidad no está disponible todavía.\nEscena: " + ruta_escena)
		else:
			mostrar_mensaje_temporal("En desarrollo", "Módulo en construcción.")
	else:
		mensaje_acceso_denegado.popup_centered()

func _on_btn_cerrar_sesion_pressed():
	print("Cerrando sesión...")
	
	# Crear diálogo de confirmación
	var dialog = ConfirmationDialog.new()
	dialog.title = "Cerrar Sesión"
	dialog.dialog_text = "¿Está seguro que desea cerrar la sesión actual?"
	dialog.confirmed.connect(_confirmar_cerrar_sesion)
	dialog.canceled.connect(_cancelar_cerrar_sesion)
	
	add_child(dialog)
	dialog.popup_centered()

func _confirmar_cerrar_sesion():
	print("Sesión cerrada")
	
	# Cerrar sesión en Global si está disponible
	if global_node:
		global_node.cerrar_sesion()
	else:
		# Resetear usuario local si Global no está disponible
		usuario_actual = {
			"nombre": "Invitado",
			"rol": Roles.NO_AUTENTICADO,
			"id": null,
			"email": "",
			"sucursal": ""
		}
		
		# Actualizar UI
		user_name_label.text = "Usuario: Invitado"
		user_role_label.text = "Rol: No autenticado"
		
		# Actualizar visibilidad de botones
		actualizar_visibilidad_botones()
	
	# Mostrar mensaje
	mostrar_mensaje_temporal("Sesión cerrada", "Se ha cerrado la sesión correctamente.")
	
	# Redirigir a pantalla de login
	get_tree().change_scene_to_file("res://escenas/login.tscn")

func _cancelar_cerrar_sesion():
	print("Cierre de sesión cancelado")

func _on_btn_salir_pressed():
	print("Saliendo del sistema...")
	
	# Crear diálogo de confirmación
	var dialog = ConfirmationDialog.new()
	dialog.title = "Salir del Sistema"
	dialog.dialog_text = "¿Está seguro que desea salir del sistema?"
	dialog.confirmed.connect(_confirmar_salida)
	dialog.canceled.connect(_cancelar_salida)
	
	add_child(dialog)
	dialog.popup_centered()

func _confirmar_salida():
	print("Saliendo del sistema...")
	
	# Si hay sesión activa, cerrarla primero
	if global_node and global_node.esta_autenticado():
		global_node.cerrar_sesion()
	
	# Salir de la aplicación
	get_tree().quit()

func _cancelar_salida():
	print("Salida cancelada")

# Funciones de utilidad
func mostrar_mensaje_error(mensaje: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()

func mostrar_mensaje_temporal(titulo: String, mensaje: String):
	var dialog = AcceptDialog.new()
	dialog.title = titulo
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()
	
	# Cerrar automáticamente después de 3 segundos
	await get_tree().create_timer(3.0).timeout
	dialog.queue_free()

# Función para manejar la tecla ESC para salir
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_btn_salir_pressed()

# Función para manejar teclas de atajo (opcional)
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		# Atajos de teclado para desarrollo (Ctrl + Shift + Letra)
		if event.ctrl_pressed and event.shift_pressed:
			match event.keycode:
				KEY_A:  # Cambiar a Admin
					if global_node:
						global_node.usuario_actual = {
							"id": 1,
							"username": "admin",
							"nombre": "Admin Debug",
							"email": "admin@debug.com",
							"rol": "ADMIN",
							"sucursal": "Central",
							"departamento": "TI",
							"cargo": "Administrador"
						}
						verificar_sesion()
						mostrar_mensaje_temporal("Debug", "Ahora eres: Admin Debug")
				KEY_S:  # Cambiar a Super Admin
					if global_node:
						global_node.usuario_actual = {
							"id": 999,
							"username": "superadmin",
							"nombre": "Super Admin Debug",
							"email": "superadmin@debug.com",
							"rol": "SUPER_ADMIN",
							"sucursal": "Central",
							"departamento": "TI",
							"cargo": "Super Administrador"
						}
						verificar_sesion()
						mostrar_mensaje_temporal("Debug", "Ahora eres: Super Admin Debug")
				KEY_I:  # Cambiar a Invitado
					if global_node:
						global_node.usuario_actual = {}
						verificar_sesion()
						mostrar_mensaje_temporal("Debug", "Ahora eres: Invitado")
				KEY_R:  # Recargar interfaz
					verificar_sesion()
				KEY_L:  # Listar usuarios en consola
					if global_node and global_node.db:
						listar_usuarios_bd()

# Función para listar usuarios de la BD (debug)
func listar_usuarios_bd():
	if global_node and global_node.db:
		print("\n=== LISTA DE USUARIOS EN BD ===")
		var usuarios = global_node.db.obtener_todos_usuarios()
		for usuario in usuarios:
			print("ID: %d, Usuario: %s, Nombre: %s, Rol: %s, Email: %s" % [
				usuario.id, usuario.username, usuario.nombre, usuario.rol, usuario.email
			])
		print("=== FIN DE LISTA ===")

# Función para simular autenticación (para pruebas) - Mantenida para compatibilidad
func simular_autenticacion(nombre: String, rol: int):
	# Mapear rol enum a string de BD
	var rol_bd = ""
	match rol:
		Roles.SUPER_ADMIN: rol_bd = "SUPER_ADMIN"
		Roles.ADMINISTRADOR: rol_bd = "ADMIN"
		Roles.SUPERVISOR_GENERAL: rol_bd = "SUPERVISOR"
		Roles.ESPECIALISTA_CALIDAD_SUCURSAL: rol_bd = "ESPECIALISTA_CALIDAD"
		Roles.AUDITOR: rol_bd = "AUDITOR"
		Roles.USUARIO: rol_bd = "USUARIO"
		Roles.SISTEMA: rol_bd = "SISTEMA"
		_: rol_bd = "INVITADO"
	
	# Actualizar Global si está disponible
	if global_node:
		global_node.usuario_actual = {
			"id": 100,
			"username": nombre.to_lower().replace(" ", "_"),
			"nombre": nombre,
			"email": nombre.to_lower().replace(" ", ".") + "@havanatur.ec",
			"rol": rol_bd,
			"sucursal": "Central",
			"departamento": "Pruebas",
			"cargo": "Usuario de Prueba"
		}
		verificar_sesion()
	else:
		# Fallback: actualizar localmente
		usuario_actual = {
			"nombre": nombre,
			"rol": rol,
			"id": 100,
			"email": nombre.to_lower().replace(" ", ".") + "@havanatur.ec",
			"sucursal": "Central"
		}
		
		user_name_label.text = "Usuario: " + nombre
		match rol:
			Roles.SUPER_ADMIN:
				user_role_label.text = "Rol: Super Administrador"
			Roles.ADMINISTRADOR:
				user_role_label.text = "Rol: Administrador"
			Roles.SUPERVISOR_GENERAL:
				user_role_label.text = "Rol: Supervisor General"
			Roles.ESPECIALISTA_CALIDAD_SUCURSAL:
				user_role_label.text = "Rol: Especialista Calidad"
			Roles.AUDITOR:
				user_role_label.text = "Rol: Auditor"
			Roles.USUARIO:
				user_role_label.text = "Rol: Usuario"
			Roles.SISTEMA:
				user_role_label.text = "Rol: Sistema"
		
		actualizar_visibilidad_botones()

# Función para aplicar tema del usuario
func aplicar_tema_usuario():
	if global_node and global_node.usuario_actual.has("tema_preferido"):
		var tema = global_node.usuario_actual.tema_preferido
		match tema:
			"oscuro":
				# Aquí puedes aplicar un tema oscuro
				# Por ejemplo: self.theme = preload("res://temas/tema_oscuro.tres")
				pass
			"claro":
				# Tema claro por defecto
				pass

# Función para mostrar información del sistema
func mostrar_info_sistema():
	var info = {
		"usuario": usuario_actual["nombre"],
		"rol": user_role_label.text,
		"hora": Time.get_time_string_from_system(),
		"fecha": Time.get_date_string_from_system()
	}
	
	var dialog = AcceptDialog.new()
	dialog.title = "Información del Sistema"
	dialog.dialog_text = """
	Sistema de Gestión de Calidad - Havanatur
	
	Usuario: {usuario}
	Rol: {rol}
	Fecha: {fecha}
	Hora: {hora}
	
	Versión: 1.0.0
	Sesión activa: {sesion_activa}
	""".format({
		"usuario": info.usuario,
		"rol": info.rol,
		"fecha": info.fecha,
		"hora": info.hora,
		"sesion_activa": "Sí" if usuario_actual["rol"] != Roles.NO_AUTENTICADO else "No"
	})
	
	add_child(dialog)
	dialog.popup_centered()
