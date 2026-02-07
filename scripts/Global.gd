extends Node
class_name GB

# Datos del usuario actual
var usuario_actual: Dictionary = {}

# Permisos del usuario
var permisos: Array = []

# Configuración del sistema
var config_sistema: Dictionary = {
	"modo_oscuro": false,
	"idioma": "es",
	"notificaciones": true
}

# Base de datos - Ahora como referencia a la instancia singleton
var db: BD

func _ready():
	print("🔧 Inicializando sistema global...")
	
	# Verificar si BD ya está inicializada en la escena principal
	var bd_node = get_node("/root/BD")
	
	if bd_node:
		print("✅ BD encontrada en el árbol de escenas")
		db = bd_node
	else:
		# Si no existe BD, verificar si estamos en el contexto correcto
		print("⚠️ BD no encontrada en /root/BD, buscando en otros nodos...")
		
		# Buscar BD en cualquier nodo del árbol
		var all_nodes = get_tree().get_nodes_in_group("bd")
		if all_nodes.size() > 0:
			db = all_nodes[0]
			print("✅ BD encontrada en grupo 'bd'")
		else:
			# Último recurso: buscar por tipo en toda la escena
			var found_bd = _find_node_by_type(get_tree().root, "BD")
			if found_bd:
				db = found_bd
				print("✅ BD encontrada por tipo en la escena")
			else:
				print("❌ BD no encontrada en la escena, la inicialización se hará desde BD.gd directamente")
	
	# Verificar si ya hay una sesión activa
	if not usuario_actual.is_empty():
		print("👤 Sesión de usuario ya cargada en memoria")
	else:
		# Intentar cargar sesión desde disco
		cargar_sesion()
		if usuario_actual.is_empty():
			print("🔓 No hay sesión activa, usuario debe autenticarse")
		else:
			print("✅ Sesión cargada para usuario: ", usuario_actual.get("username", "Desconocido"))

func _find_node_by_type(node: Node, type_name: String) -> Node:
	"""Busca recursivamente un nodo por tipo en el árbol"""
	if node.get_class() == type_name:
		return node
	
	for child in node.get_children():
		var found = _find_node_by_type(child, type_name)
		if found:
			return found
	
	return null

func esta_autenticado() -> bool:
	return not usuario_actual.is_empty()

func obtener_rol() -> String:
	return usuario_actual.get("rol", "")

func obtener_id_usuario() -> int:
	return usuario_actual.get("id", -1)

func obtener_nombre_usuario() -> String:
	return usuario_actual.get("nombre_completo", usuario_actual.get("username", "Usuario"))

func obtener_sucursal() -> String:
	return usuario_actual.get("sucursal", "Central")

func cargar_sesion():
	"""Carga la sesión del usuario desde el archivo de configuración"""
	var config = ConfigFile.new()
	
	if config.load("user://sesion.cfg") == OK:
		print("📂 Cargando sesión desde user://sesion.cfg")
		
		usuario_actual = config.get_value("sesion", "usuario", {})
		permisos = config.get_value("sesion", "permisos", [])
		
		if not usuario_actual.is_empty():
			print("✅ Sesión cargada para: ", usuario_actual.get("username", "Desconocido"))
			print("   Rol: ", usuario_actual.get("rol", "No definido"))
			print("   Sucursal: ", usuario_actual.get("sucursal", "No definida"))
	else:
		print("📂 No se encontró archivo de sesión, usuario debe autenticarse")

func guardar_sesion():
	"""Guarda la sesión actual en el archivo de configuración"""
	if usuario_actual.is_empty():
		print("⚠️ No hay usuario para guardar sesión")
		return
	
	var config = ConfigFile.new()
	
	config.set_value("sesion", "usuario", usuario_actual)
	config.set_value("sesion", "permisos", permisos)
	config.set_value("sesion", "timestamp", Time.get_datetime_string_from_system())
	
	if config.save("user://sesion.cfg") == OK:
		print("💾 Sesión guardada para: ", usuario_actual.get("username", "Desconocido"))
	else:
		print("❌ Error al guardar sesión")

func iniciar_sesion(usuario: Dictionary, recordar_sesion: bool = false):
	"""Inicia sesión con los datos del usuario"""
	print("🔐 Iniciando sesión para: ", usuario.get("username", "Desconocido"))
	
	usuario_actual = usuario
	
	# Convertir permisos de JSON si es necesario
	if usuario_actual.has("permisos") and typeof(usuario_actual["permisos"]) == TYPE_STRING:
		var json = JSON.new()
		if json.parse(usuario_actual["permisos"]) == OK:
			permisos = json.data
		else:
			permisos = []
	else:
		permisos = usuario_actual.get("permisos", [])
	
	# Guardar sesión si el usuario lo solicitó
	if recordar_sesion:
		guardar_sesion()
	
	print("✅ Sesión iniciada:")
	print("   Usuario: ", usuario_actual.get("username", "Desconocido"))
	print("   Nombre: ", usuario_actual.get("nombre_completo", "No definido"))
	print("   Rol: ", usuario_actual.get("rol", "No definido"))
	print("   Departamento: ", usuario_actual.get("departamento", "No definido"))
	print("   Sucursal: ", usuario_actual.get("sucursal", "No definida"))

func cerrar_sesion():
	"""Cierra la sesión actual y limpia los datos"""
	print("🔒 Cerrando sesión...")
	
	if not usuario_actual.is_empty():
		print("   Usuario anterior: ", usuario_actual.get("username", "Desconocido"))
	
	# Limpiar datos en memoria
	usuario_actual = {}
	permisos.clear()
	
	# Eliminar archivo de sesión
	var dir = DirAccess.open("user://")
	if dir.file_exists("sesion.cfg"):
		if dir.remove("sesion.cfg") == OK:
			print("🗑️ Archivo de sesión eliminado")
		else:
			print("⚠️ No se pudo eliminar el archivo de sesión")
	
	print("✅ Sesión cerrada")
	
	# Redirigir a la pantalla de login
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.get_name() != "Login":
		print("🔄 Redirigiendo a pantalla de login...")
		get_tree().change_scene_to_file("res://escenas/autentificar.tscn")

# Función para verificar permisos
func tiene_permiso(permiso: String) -> bool:
	"""Verifica si el usuario actual tiene un permiso específico"""
	
	if usuario_actual.is_empty():
		print("⚠️ Usuario no autenticado, no puede verificar permisos")
		return false
	
	# Admin tiene todos los permisos
	if usuario_actual.get("rol") == "admin" or usuario_actual.get("rol") == "SUPER_ADMIN":
		return true
	
	# Verificar en la lista de permisos
	if permisos.has(permiso):
		return true
	
	# Verificar permisos básicos por rol (backup)
	var rol = usuario_actual.get("rol", "").to_lower()
	
	match rol:
		"admin", "super_admin":
			return true
		"supervisor", "gerente":
			return permiso in ["VER_REPORTES", "REGISTRAR_INCIDENCIA", "PROCESAR_EXPEDIENTE", "VER_PROPIOS", "GESTIONAR_QUEJAS"]
		"analista", "especialista_calidad":
			return permiso in ["CREAR_EXPEDIENTE", "PROCESAR_EXPEDIENTE", "GESTIONAR_QUEJAS", "VER_PROPIOS", "VER_REPORTES"]
		"auditor":
			return permiso in ["REGISTRAR_NC", "VER_REPORTES", "VER_PROPIOS", "VER_TRAZAS"]
		"operador":
			return permiso in ["VER_PROPIOS", "CREAR_EXPEDIENTE", "REGISTRAR_INCIDENCIA"]
		"legal":
			return permiso in ["VER_REPORTES", "PROCESAR_EXPEDIENTE", "VER_PROPIOS"]
		_:
			return false

func tiene_permiso_por_clave(permiso_key: String) -> bool:
	"""Verifica permisos usando la clave del permiso"""
	return tiene_permiso(permiso_key)

func tiene_permiso_por_descripcion(descripcion: String) -> bool:
	"""Verifica permisos por descripción (menos eficiente)"""
	# Esto requeriría una consulta a la BD para mapear descripción -> clave
	# Por ahora, usamos la función principal
	return tiene_permiso(descripcion)

func obtener_permisos_disponibles() -> Array:
	"""Retorna la lista de permisos del usuario actual"""
	if usuario_actual.is_empty():
		return []
	
	return permisos

func obtener_permisos_como_texto() -> String:
	"""Retorna los permisos como texto legible"""
	if permisos.is_empty():
		return "Sin permisos específicos"
	
	return ", ".join(PackedStringArray(permisos))

# Funciones de utilidad para el sistema
func cambiar_configuracion(clave: String, valor):
	"""Cambia una configuración del sistema"""
	if config_sistema.has(clave):
		config_sistema[clave] = valor
		print("⚙️ Configuración actualizada: ", clave, " = ", valor)
		
		# Guardar configuración persistente
		guardar_configuracion()
	else:
		print("⚠️ Configuración no encontrada: ", clave)

func guardar_configuracion():
	"""Guarda la configuración en disco"""
	var config = ConfigFile.new()
	
	for clave in config_sistema.keys():
		config.set_value("sistema", clave, config_sistema[clave])
	
	if config.save("user://config.cfg") == OK:
		print("💾 Configuración guardada")
	else:
		print("❌ Error al guardar configuración")

func cargar_configuracion():
	"""Carga la configuración desde disco"""
	var config = ConfigFile.new()
	
	if config.load("user://config.cfg") == OK:
		print("📂 Cargando configuración del sistema")
		
		var seccion = "sistema"
		if config.has_section(seccion):
			for clave in config_sistema.keys():
				if config.has_section_key(seccion, clave):
					config_sistema[clave] = config.get_value(seccion, clave, config_sistema[clave])
		
		print("✅ Configuración cargada")
	else:
		print("📂 No se encontró archivo de configuración, usando valores por defecto")

# Funciones de navegación
func ir_a_escena(ruta_escena: String):
	"""Navega a una escena específica"""
	print("🔄 Navegando a escena: ", ruta_escena)
	
	if ResourceLoader.exists(ruta_escena):
		get_tree().change_scene_to_file(ruta_escena)
	else:
		print("❌ Escena no encontrada: ", ruta_escena)

func mostrar_mensaje(titulo: String, mensaje: String, tipo: String = "info"):
	"""Muestra un mensaje al usuario (para implementar con UI)"""
	print("[", tipo.to_upper(), "] ", titulo, ": ", mensaje)
	
	# Aquí se podría integrar con un sistema de notificaciones UI
	match tipo:
		"error":
			push_error(mensaje)
		"warning":
			push_warning(mensaje)
		_:
			print(mensaje)

# Singleton pattern - asegurar única instancia
static var instance: GB

func _enter_tree():
	# Implementación de singleton simple
	if instance:
		queue_free()
		print("⚠️ Múltiples instancias de Global detectadas, eliminando duplicado")
	else:
		instance = self
		print("🌐 Instancia Global creada")
		set_name("Global")

func _exit_tree():
	if instance == self:
		instance = null
		print("🌐 Instancia Global eliminada")
