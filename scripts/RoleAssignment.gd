extends Window
class_name RoleAssignment

# Señal para notificar cuando se actualizan los roles
signal roles_actualizados(id_usuario: String, nuevos_roles: Array)

# Enumeración de roles
enum ROLES {
	ADMINISTRADOR = 0,
	SUPERVISOR_CALIDAD = 1,
	INSPECTOR_CALIDAD = 2,
	AUDITOR_INTERNO = 3,
	CLIENTE_EXTERNO = 4,
	CONSULTA_GENERAL = 5
}

# Diccionario para mapear checkboxes a roles
var checkboxes_roles: Dictionary = {}

# Usuario actual cuyos roles se están asignando
var usuario_actual: Dictionary = {}
var id_usuario_actual: String = ""

# Referencias a los checkboxes de roles
@onready var checkbox_admin: CheckBox = $VBoxContainer/ScrollContainer/RolesContainer/CheckAdmin
@onready var checkbox_supervisor: CheckBox = $VBoxContainer/ScrollContainer/RolesContainer/CheckSupervisor
@onready var checkbox_inspector: CheckBox = $VBoxContainer/ScrollContainer/RolesContainer/CheckInspector
@onready var checkbox_auditor: CheckBox = $VBoxContainer/ScrollContainer/RolesContainer/CheckAuditor
@onready var checkbox_cliente: CheckBox = $VBoxContainer/ScrollContainer/RolesContainer/CheckCliente
@onready var checkbox_consulta: CheckBox = $VBoxContainer/ScrollContainer/RolesContainer/CheckConsulta

# Botones
@onready var btn_cancelar: Button = $VBoxContainer/HBoxContainer/BtnCancelarRol
@onready var btn_guardar: Button = $VBoxContainer/HBoxContainer/BtnGuardarRol
@onready var label_usuario: Label = $VBoxContainer/LabelUsuario

func _ready():
	# Inicializar mapeo de checkboxes a roles
	inicializar_mapeo_roles()
	
	# Conectar señales de los botones
	btn_cancelar.pressed.connect(cerrar_dialogo)
	btn_guardar.pressed.connect(guardar_roles)
	
	# Conectar señales de los checkboxes para validación
	conectar_checkboxes()

func inicializar_mapeo_roles():
	# Mapear cada checkbox a su respectivo rol
	checkboxes_roles = {
		checkbox_admin: ROLES.ADMINISTRADOR,
		checkbox_supervisor: ROLES.SUPERVISOR_CALIDAD,
		checkbox_inspector: ROLES.INSPECTOR_CALIDAD,
		checkbox_auditor: ROLES.AUDITOR_INTERNO,
		checkbox_cliente: ROLES.CLIENTE_EXTERNO,
		checkbox_consulta: ROLES.CONSULTA_GENERAL
	}

func conectar_checkboxes():
	# Conectar cada checkbox para realizar validaciones
	for checkbox in checkboxes_roles.keys():
		checkbox.toggled.connect(_on_checkbox_toggled.bind(checkbox))

func _on_checkbox_toggled(toggled_on: bool, checkbox: CheckBox):
	# Validar que no se seleccionen roles incompatibles
	if toggled_on:
		validar_compatibilidad_roles(checkbox)

func validar_compatibilidad_roles(checkbox_activado: CheckBox):
	# Definir reglas de compatibilidad
	var rol_activado = checkboxes_roles[checkbox_activado]
	
	# Si se activa el rol de Administrador, desactivar otros roles
	if rol_activado == ROLES.ADMINISTRADOR:
		for checkbox in checkboxes_roles.keys():
			if checkbox != checkbox_activado and checkbox.button_pressed:
				checkbox.button_pressed = false
				mostrar_mensaje_incompatibilidad("Los administradores no pueden tener otros roles asignados.")
	
	# Si se activa el rol de Cliente Externo, limitar otros roles
	elif rol_activado == ROLES.CLIENTE_EXTERNO:
		if checkbox_admin.button_pressed:
			checkbox_admin.button_pressed = false
			mostrar_mensaje_incompatibilidad("Los clientes externos no pueden ser administradores.")
	
	# Si se activa el rol de Consulta General, limitar roles de gestión
	elif rol_activado == ROLES.CONSULTA_GENERAL:
		if checkbox_admin.button_pressed or checkbox_supervisor.button_pressed:
			if checkbox_admin.button_pressed:
				checkbox_admin.button_pressed = false
			if checkbox_supervisor.button_pressed:
				checkbox_supervisor.button_pressed = false
			mostrar_mensaje_incompatibilidad("Los usuarios de solo consulta no pueden tener roles de gestión.")

func mostrar_mensaje_incompatibilidad(mensaje: String):
	# En un sistema real, mostrarías una notificación
	# Por ahora, simplemente imprimimos en consola
	print("Advertencia de compatibilidad: ", mensaje)

func cargar_usuario(usuario: Dictionary):
	"""Carga los datos del usuario para asignar/editar roles"""
	usuario_actual = usuario
	id_usuario_actual = usuario.get("id", "")
	
	# Actualizar label con nombre del usuario
	var nombre_completo = usuario.get("nombre", "Usuario Desconocido")
	label_usuario.text = "Usuario: " + nombre_completo
	
	# Cargar roles actuales del usuario
	cargar_roles_usuario(usuario)

func cargar_roles_usuario(usuario: Dictionary):
	"""Carga los roles actuales del usuario en los checkboxes"""
	# Limpiar todos los checkboxes primero
	for checkbox in checkboxes_roles.keys():
		checkbox.button_pressed = false
	
	# Obtener el rol principal del usuario (del sistema existente)
	var rol_principal = usuario.get("rol", -1)
	
	# Si el usuario tiene un rol principal en el sistema antiguo,
	# mapearlo al nuevo sistema de roles
	if rol_principal != -1:
		mapear_rol_antiguo_a_nuevo(rol_principal)
	
	# También cargar roles adicionales si existen
	var roles_adicionales = usuario.get("roles_adicionales", [])
	for rol_adicional in roles_adicionales:
		activar_checkbox_por_rol(rol_adicional)

func mapear_rol_antiguo_a_nuevo(rol_antiguo: int):
	"""Mapea los roles del sistema antiguo al nuevo sistema"""
	# Este mapeo depende de cómo estaban definidos los roles en UserManagement.gd
	# Ajusta según sea necesario
	
	match rol_antiguo:
		0:  # SUPERVISOR_GENERAL
			checkbox_supervisor.button_pressed = true
		1:  # CLIENTE
			checkbox_cliente.button_pressed = true
		2:  # ESPECIALISTA_CALIDAD
			checkbox_inspector.button_pressed = true
		3:  # AUDITOR
			checkbox_auditor.button_pressed = true
		4:  # ADMINISTRADOR
			checkbox_admin.button_pressed = true

func activar_checkbox_por_rol(rol_id: int):
	"""Activa el checkbox correspondiente a un rol ID"""
	for checkbox in checkboxes_roles.keys():
		if checkboxes_roles[checkbox] == rol_id:
			checkbox.button_pressed = true
			break

func obtener_roles_seleccionados() -> Array:
	"""Obtiene la lista de IDs de roles seleccionados"""
	var roles_seleccionados = []
	
	for checkbox in checkboxes_roles.keys():
		if checkbox.button_pressed:
			roles_seleccionados.append(checkboxes_roles[checkbox])
	
	return roles_seleccionados

func guardar_roles():
	"""Guarda los roles seleccionados para el usuario actual"""
	# Validar que al menos un rol esté seleccionado
	var roles_seleccionados = obtener_roles_seleccionados()
	
	if roles_seleccionados.is_empty():
		mostrar_error("Debe seleccionar al menos un rol para el usuario.")
		return
	
	# Validar roles especiales
	if not validar_roles_especiales(roles_seleccionados):
		return
	
	# Emitir señal con los nuevos roles
	roles_actualizados.emit(id_usuario_actual, roles_seleccionados)
	
	# Cerrar el diálogo
	cerrar_dialogo()
	
	# Mostrar mensaje de éxito
	mostrar_mensaje_exito("Roles asignados exitosamente al usuario.")

func validar_roles_especiales(roles: Array) -> bool:
	"""Valida combinaciones especiales de roles"""
	# Verificar si es Administrador y tiene otros roles
	if ROLES.ADMINISTRADOR in roles and roles.size() > 1:
		mostrar_error("Los administradores no pueden tener otros roles asignados.")
		return false
	
	# Verificar si es Cliente Externo y tiene roles de gestión
	if ROLES.CLIENTE_EXTERNO in roles:
		for rol in roles:
			if rol != ROLES.CLIENTE_EXTERNO:
				mostrar_error("Los clientes externos solo pueden tener el rol de Cliente.")
				return false
	
	return true

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error"""
	# En un sistema real, usarías un diálogo de error
	# Por ahora, simplemente imprimimos en consola
	print("Error: ", mensaje)
	
	# Podrías mostrar una notificación en pantalla aquí
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = mensaje
	add_child(error_dialog)
	error_dialog.popup_centered()

func mostrar_mensaje_exito(mensaje: String):
	"""Muestra un mensaje de éxito"""
	# En un sistema real, usarías un diálogo de éxito
	print("Éxito: ", mensaje)

func cerrar_dialogo():
	"""Cierra el diálogo de asignación de roles"""
	self.hide()
	
	# Limpiar datos del usuario actual
	usuario_actual = {}
	id_usuario_actual = ""
	
	# Limpiar checkboxes
	for checkbox in checkboxes_roles.keys():
		checkbox.button_pressed = false

func _on_close_requested():
	"""Manejador para cuando se solicita cerrar la ventana"""
	cerrar_dialogo()

# Funciones de utilidad para obtener información de roles
func obtener_nombre_rol(rol_id: int) -> String:
	"""Obtiene el nombre legible de un rol"""
	match rol_id:
		ROLES.ADMINISTRADOR: return "Administrador"
		ROLES.SUPERVISOR_CALIDAD: return "Supervisor de Calidad"
		ROLES.INSPECTOR_CALIDAD: return "Inspector de Calidad"
		ROLES.AUDITOR_INTERNO: return "Auditor Interno"
		ROLES.CLIENTE_EXTERNO: return "Cliente Externo"
		ROLES.CONSULTA_GENERAL: return "Consulta General"
		_: return "Rol Desconocido"

func obtener_descripcion_rol(rol_id: int) -> String:
	"""Obtiene la descripción de un rol"""
	match rol_id:
		ROLES.ADMINISTRADOR: return "Acceso completo al sistema. Puede administrar usuarios, configuraciones y todos los módulos."
		ROLES.SUPERVISOR_CALIDAD: return "Gestiona incidencias, quejas e indicadores. Supervisa el trabajo de inspectores."
		ROLES.INSPECTOR_CALIDAD: return "Registra y procesa incidencias de calidad. Realiza inspecciones y reportes."
		ROLES.AUDITOR_INTERNO: return "Realiza auditorías internas. Genera informes de auditoría y seguimiento."
		ROLES.CLIENTE_EXTERNO: return "Acceso de solo lectura a informes públicos y estado de quejas."
		ROLES.CONSULTA_GENERAL: return "Acceso de solo visualización a datos generales del sistema."
		_: return "Sin descripción disponible."

func obtener_permisos_por_rol(rol_id: int) -> Array[String]:
	"""Obtiene los permisos asociados a un rol específico"""
	var permisos = []
	
	match rol_id:
		ROLES.ADMINISTRADOR:
			permisos = [
				"ADMINISTRAR_USUARIOS",
				"VER_TRAZAS", 
				"CONFIGURACION",
				"PROCESAR_INCIDENCIAS",
				"PROCESAR_QUEJAS",
				"GENERAR_REPORTES",
				"ADMINISTRAR_ROLES"
			]
		
		ROLES.SUPERVISOR_CALIDAD:
			permisos = [
				"PROCESAR_INCIDENCIAS",
				"PROCESAR_QUEJAS",
				"GENERAR_REPORTES",
				"VER_INDICADORES",
				"SUPERVISAR_INSPECTORES"
			]
		
		ROLES.INSPECTOR_CALIDAD:
			permisos = [
				"PROCESAR_INCIDENCIAS",
				"REGISTRAR_INSPECCIONES",
				"GENERAR_REPORTES_BASICOS"
			]
		
		ROLES.AUDITOR_INTERNO:
			permisos = [
				"REALIZAR_AUDITORIAS",
				"GENERAR_INFORMES_AUDITORIA",
				"VER_TRAZAS_AUDITORIA"
			]
		
		ROLES.CLIENTE_EXTERNO:
			permisos = [
				"VER_INFORMES_PUBLICOS",
				"CONSULTAR_ESTADO_QUEJAS"
			]
		
		ROLES.CONSULTA_GENERAL:
			permisos = [
				"VER_DATOS_GENERALES",
				"CONSULTAR_REPORTES"
			]
	
	return permisos
