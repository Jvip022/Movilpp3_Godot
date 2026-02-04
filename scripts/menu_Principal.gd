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

# Diccionario de botones y sus roles permitidos
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

func _ready():
	# Inicializar diccionario de botones para acceso rápido
	inicializar_botones()
	
	# Conectar señales de todos los botones
	conectar_botones()
	
	# Verificar si hay una sesión activa
	verificar_sesion()

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
	# Simulamos diferentes usuarios para pruebas
	# En producción, esto vendría de tu sistema de autenticación
	
	# Para probar diferentes roles, cambia esta línea:
	var usuario_prueba = "super_admin"  # Opciones: invitado, admin, supervisor, especialista, auditor, usuario, sistema, super_admin
	
	match usuario_prueba:
		"invitado":
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
		
		"admin":
			usuario_actual = {
				"nombre": "Admin Principal",
				"rol": Roles.ADMINISTRADOR,
				"id": 1,
				"email": "admin@havanatur.ec",
				"sucursal": "Central"
			}
			user_name_label.text = "Usuario: Admin Principal"
			user_role_label.text = "Rol: Administrador"
		
		"supervisor":
			usuario_actual = {
				"nombre": "Supervisor General",
				"rol": Roles.SUPERVISOR_GENERAL,
				"id": 2,
				"email": "supervisor@havanatur.ec",
				"sucursal": "Central"
			}
			user_name_label.text = "Usuario: Supervisor General"
			user_role_label.text = "Rol: Supervisor General"
		
		"especialista":
			usuario_actual = {
				"nombre": "Especialista Calidad",
				"rol": Roles.ESPECIALISTA_CALIDAD_SUCURSAL,
				"id": 3,
				"email": "calidad@havanatur.ec",
				"sucursal": "Sucursal Norte"
			}
			user_name_label.text = "Usuario: Especialista Calidad"
			user_role_label.text = "Rol: Especialista Calidad Sucursal"
		
		"auditor":
			usuario_actual = {
				"nombre": "Auditor Interno",
				"rol": Roles.AUDITOR,
				"id": 4,
				"email": "auditor@havanatur.ec",
				"sucursal": "Central"
			}
			user_name_label.text = "Usuario: Auditor Interno"
			user_role_label.text = "Rol: Auditor"
		
		"usuario":
			usuario_actual = {
				"nombre": "Usuario General",
				"rol": Roles.USUARIO,
				"id": 5,
				"email": "usuario@havanatur.ec",
				"sucursal": "Sucursal Sur"
			}
			user_name_label.text = "Usuario: Usuario General"
			user_role_label.text = "Rol: Usuario"
		
		"sistema":
			usuario_actual = {
				"nombre": "Sistema",
				"rol": Roles.SISTEMA,
				"id": 0,
				"email": "sistema@havanatur.ec",
				"sucursal": "Central"
			}
			user_name_label.text = "Usuario: Sistema"
			user_role_label.text = "Rol: Sistema"
		
		"super_admin":
			usuario_actual = {
				"nombre": "Super Administrador",
				"rol": Roles.SUPER_ADMIN,
				"id": 999,
				"email": "superadmin@havanatur.ec",
				"sucursal": "Central"
			}
			user_name_label.text = "Usuario: Super Administrador"
			user_role_label.text = "Rol: Super Admin"
		
		_:  # Por defecto, invitado
			usuario_actual = {
				"nombre": "Invitado",
				"rol": Roles.NO_AUTENTICADO,
				"id": null,
				"email": "",
				"sucursal": ""
			}
			user_name_label.text = "Usuario: Invitado"
			user_role_label.text = "Rol: No autenticado"
	
	# Actualizar visibilidad de botones según rol
	actualizar_visibilidad_botones()

func actualizar_visibilidad_botones():
	# Ocultar todos los botones primero
	for boton_nombre in botones:
		botones[boton_nombre].visible = false
	
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
			
			# MODIFICACIÓN: Verificar si la escena existe antes de cargarla
			if FileAccess.file_exists(ruta_escena):
				# Usar SceneManager si está disponible
				if has_node("/root/SceneManager"):
					var scene_manager = get_node("/root/SceneManager")
					var scene_key = boton_nombre.replace("Btn", "").to_lower()
					scene_manager.change_scene_to(scene_key)
				else:
					# Fallback: cambiar escena directamente
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
	
	# Resetear usuario a invitado
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
	
	# Opcional: Redirigir a pantalla de login
	# get_tree().change_scene_to_file("res://escenas/autentificar.tscn")

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

func _confirmar_salida():
	print("Saliendo del sistema...")
	get_tree().quit()

func _cancelar_salida():
	print("Salida cancelada")

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
					usuario_actual["rol"] = Roles.ADMINISTRADOR
					user_name_label.text = "Usuario: Admin (Debug)"
					user_role_label.text = "Rol: Administrador (Debug)"
					actualizar_visibilidad_botones()
				KEY_S:  # Cambiar a Super Admin
					usuario_actual["rol"] = Roles.SUPER_ADMIN
					user_name_label.text = "Usuario: Super Admin (Debug)"
					user_role_label.text = "Rol: Super Admin (Debug)"
					actualizar_visibilidad_botones()
				KEY_I:  # Cambiar a Invitado
					usuario_actual["rol"] = Roles.NO_AUTENTICADO
					user_name_label.text = "Usuario: Invitado (Debug)"
					user_role_label.text = "Rol: No autenticado (Debug)"
					actualizar_visibilidad_botones()
				KEY_R:  # Recargar interfaz
					actualizar_visibilidad_botones()

# Función para simular autenticación (para pruebas) - CORREGIDA
func simular_autenticacion(nombre: String, rol: int):
	usuario_actual = {
		"nombre": nombre,
		"rol": rol,
		"id": 100,
		"email": nombre.to_lower().replace(" ", ".") + "@havanatur.ec",  # CORRECCIÓN: to_lower() en lugar de lower()
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
