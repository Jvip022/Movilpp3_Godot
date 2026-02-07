extends Control
class_name UserManagement

# Señales
signal usuario_creado(datos_usuario: Dictionary)
signal usuario_modificado(id_usuario: String, datos_usuario: Dictionary)
signal usuario_desactivado(id_usuario: String)


# Enumeración de roles según los tipos de usuario requeridos
enum ROLES_USUARIO {
	SUPERVISOR_GENERAL = 0,
	CLIENTE = 1,
	ESPECIALISTA_CALIDAD = 2,
	AUDITOR = 3,
	ADMINISTRADOR = 4  # Añadido para administración del sistema
}

# Enumeración de estados de usuario
enum ESTADOS_USUARIO {
	ACTIVO = 0,
	INACTIVO = 1,
	PENDIENTE = 2,
	BLOQUEADO = 3
}

# Datos de ejemplo para sucursales
var sucursales_disponibles = [
	"La Habana",
	"Varadero", 
	"Viñales",
	"Trinidad",
	"Santiago de Cuba",
	"Internacional"
]

# Variable para almacenar usuarios (simulación de base de datos)
var usuario_seleccionado: Dictionary = {}
var modo_edicion: bool = false
var usuario_actual: Dictionary = {}  # Para almacenar datos del usuario actual (si es necesario)

func _ready():
	# Quitar despues
	probar_conexion_bd()
	# Inicializar tabla de usuarios
	inicializar_tabla()
	# Aplicar estilos
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.9)  # Fondo blanco semi-transparente
	tabla.add_theme_stylebox_override("panel", style)

	# Botón temporal para crear usuarios de prueba
	var btn_prueba = Button.new()
	btn_prueba.text = "Crear Usuarios Prueba"
	btn_prueba.custom_minimum_size = Vector2(180, 40)

	# Conectar señales del diálogo de confirmación
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.connect(confirmar_operacion)
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.connect(cancelar_operacion)
	
	# Conectar señales de los botones principales
	$Header/HBoxContainer/BtnRegresar.pressed.connect(regresar_menu_principal)
	$ContentContainer/SearchBar/BtnBuscar.pressed.connect(buscar_usuarios)
	$ContentContainer/SearchBar/BtnNuevoUsuario.pressed.connect(abrir_dialogo_nuevo_usuario)
	$Header/HBoxContainer/BtnExportar.pressed.connect(exportar_lista_usuarios)
	$Header/HBoxContainer/BtnActualizar.pressed.connect(actualizar_lista_usuarios)
	
	# Conectar señales de los botones de acción
	$ContentContainer/ActionButtons/BtnModificar.pressed.connect(abrir_dialogo_modificar_usuario)
	$ContentContainer/ActionButtons/BtnDesactivar.pressed.connect(solicitar_desactivar_usuario)
	$ContentContainer/ActionButtons/BtnAsignarRol.pressed.connect(abrir_dialogo_asignar_rol)
	$ContentContainer/ActionButtons/BtnVerTrazas.pressed.connect(ver_trazas_usuario)
	
	# Conectar señales del diálogo de usuario
	$DialogoUsuario/VBoxContainer/HBoxContainer/BtnGenerarPass.pressed.connect(generar_contrasena_aleatoria)
	$DialogoUsuario/HBoxContainer/BtnCancelar.pressed.connect(cerrar_dialogo_usuario)
	$DialogoUsuario/HBoxContainer/BtnGuardar.pressed.connect(guardar_usuario)
	
	# Conectar señal de selección en la tabla
	$ContentContainer/UserTableContainer/TablaUsuarios.item_selected.connect(on_usuario_seleccionado)
	$ContentContainer/UserTableContainer/TablaUsuarios.nothing_selected.connect(on_nada_seleccionado)
	
	# Conectar señales del diálogo de confirmación
	if not $DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.is_connected(confirmar_operacion):
		$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.connect(confirmar_operacion)
	
	if not $DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.is_connected(cancelar_operacion):
		$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.connect(cancelar_operacion)
	
	# Conectar señal de búsqueda en tiempo real
	$ContentContainer/SearchBar/InputBuscar.text_changed.connect(on_busqueda_cambio)
	
	# Cargar roles en combobox
	inicializar_combo_roles()
	inicializar_combo_sucursales()
	
	# Deshabilitar botones de acción inicialmente
	actualizar_botones_accion(false)
	
	# Cargar usuarios iniciales
	actualizar_tabla_usuarios()
	
	# Inicializar usuario actual (simulado)
	usuario_actual = {
		"id": 1,
		"username": "admin",
		"nombre": "Administrador",
		"rol": "admin"
	}

func inicializar_tabla():
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	# Configurar columnas
	tabla.columns = 7
	
	
	# Establecer títulos de columna uno por uno
	tabla.set_column_title(0, "Nombre")
	tabla.set_column_title(1, "Usuario")
	tabla.set_column_title(2, "Rol")
	tabla.set_column_title(3, "Estado")
	tabla.set_column_title(4, "Último Acceso")
	tabla.set_column_title(5, "Sucursal")
	tabla.set_column_title(6, "Acciones")
	
	# Configurar expansión de columnas
	tabla.set_column_expand(0, true)
	tabla.set_column_expand(1, false)
	tabla.set_column_expand(2, false)
	tabla.set_column_expand(3, false)
	tabla.set_column_expand(4, false)
	tabla.set_column_expand(5, false)
	tabla.set_column_expand(6, false)
	
	# Configurar anchos mínimos
	tabla.set_column_custom_minimum_width(0, 200)
	tabla.set_column_custom_minimum_width(1, 100)
	tabla.set_column_custom_minimum_width(2, 120)
	tabla.set_column_custom_minimum_width(3, 80)
	tabla.set_column_custom_minimum_width(4, 120)
	tabla.set_column_custom_minimum_width(5, 100)
	tabla.set_column_custom_minimum_width(6, 120)

func inicializar_combo_roles():
	var combo = $DialogoUsuario/VBoxContainer/ComboRol
	combo.clear()
	combo.add_item("Seleccionar Rol*", 0)
	combo.set_item_text(0, "Seleccionar Rol*")
	combo.add_item("Administrador", 1)
	combo.add_item("Supervisor", 2)
	combo.add_item("Operador", 3)
	combo.add_item("Analista", 4)
	combo.add_item("Legal", 5)
	combo.add_item("Gerente", 6)

func inicializar_combo_sucursales():
	var combo = $DialogoUsuario/VBoxContainer/ComboSucursal
	combo.clear()
	combo.add_item("Seleccionar Sucursal*")
	for i in range(sucursales_disponibles.size()):
		combo.add_item(sucursales_disponibles[i])

func actualizar_tabla_usuarios():
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	tabla.clear()
	
	# Consulta a la base de datos
	var consulta = """
        SELECT id, username, email, nombre_completo, telefono, departamento, 
               cargo, rol, estado_empleado, fecha_creacion, ultimo_login
        FROM usuarios 
        ORDER BY nombre_completo
	"""
	
	print("🔍 Ejecutando consulta para obtener usuarios...")
	var usuarios_db = Bd.select_query(consulta)
	
	if usuarios_db == null:
		print("❌ Error en la consulta a la base de datos")
		mostrar_error("Error al cargar usuarios de la base de datos")
		return
	
	print("✅ Usuarios encontrados: " + str(usuarios_db.size()))
	
	# Mostrar debug de primer usuario
	if usuarios_db.size() > 0:
		print("📋 Primer usuario: ", usuarios_db[0])
	
	var root = tabla.create_item()
	
	for usuario in usuarios_db:
		var item = tabla.create_item(root)
		
		# Nombre completo
		item.set_text(0, usuario.get("nombre_completo", "Sin nombre"))
		
		# Usuario
		item.set_text(1, usuario.get("username", "Sin usuario"))
		
		# Rol
		var rol_str = usuario.get("rol", "")
		item.set_text(2, obtener_texto_rol_string(rol_str))
		
		# Estado
		var estado_str = usuario.get("estado_empleado", "")
		item.set_text(3, obtener_texto_estado_string(estado_str))
		item.set_custom_color(3, obtener_color_estado_string(estado_str))
		
		# Último acceso
		var ultimo_login = usuario.get("ultimo_login", "")
		if ultimo_login and ultimo_login != "":
			item.set_text(4, parse_date(ultimo_login))
		else:
			item.set_text(4, "Nunca")
		
		# Departamento/Sucursal
		item.set_text(5, usuario.get("departamento", "No asignado"))
		
		# Almacenar ID del usuario para referencia
		item.set_metadata(0, usuario.get("id", 0))
		
		# Botones de acción (iconos)
		item.set_text(6, "🔍 ✏️ ⚠️")
		item.set_tooltip_text(6, "Ver trazas | Modificar | Desactivar")
	
	# Limpiar selección
	usuario_seleccionado = {}
	actualizar_botones_accion(false)
	
func obtener_texto_rol_string(rol_string: String) -> String:
	if rol_string == null or rol_string == "":
		return "Sin rol"
	
	match rol_string.to_lower():
		"admin": return "Administrador"
		"supervisor": return "Supervisor"
		"operador": return "Operador"
		"analista": return "Analista"
		"legal": return "Legal"
		"gerente": return "Gerente"
		_: return rol_string.capitalize()

func obtener_texto_estado_string(estado_string: String) -> String:
	if estado_string == null or estado_string == "":
		return "Desconocido"
	
	match estado_string.to_lower():
		"activo": return "Activo"
		"inactivo": return "Inactivo"
		"pendiente": return "Pendiente"
		"bloqueado": return "Bloqueado"
		_: return estado_string.capitalize()

func obtener_texto_rol(rol_id: int) -> String:
	match rol_id:
		ROLES_USUARIO.SUPERVISOR_GENERAL: return "Supervisor General"
		ROLES_USUARIO.CLIENTE: return "Cliente"
		ROLES_USUARIO.ESPECIALISTA_CALIDAD: return "Especialista Calidad"
		ROLES_USUARIO.AUDITOR: return "Auditor"
		ROLES_USUARIO.ADMINISTRADOR: return "Administrador"
		_: return "Sin rol"

func obtener_color_estado_string(estado_string: String) -> Color:
	match estado_string.to_lower():
		"activo": return Color(0.2, 0.8, 0.2)  # Verde
		"inactivo": return Color(0.8, 0.8, 0.2)  # Amarillo
		"pendiente": return Color(0.2, 0.6, 0.8)  # Azul
		"bloqueado": return Color(0.8, 0.2, 0.2)  # Rojo
		_: return Color(0.5, 0.5, 0.5)  # Gris


func obtener_texto_estado(estado_id: int) -> String:
	match estado_id:
		ESTADOS_USUARIO.ACTIVO: return "Activo"
		ESTADOS_USUARIO.INACTIVO: return "Inactivo"
		ESTADOS_USUARIO.PENDIENTE: return "Pendiente"
		ESTADOS_USUARIO.BLOQUEADO: return "Bloqueado"
		_: return "Desconocido"

func obtener_color_estado(estado_id: int) -> Color:
	match estado_id:
		ESTADOS_USUARIO.ACTIVO: return Color(0.2, 0.8, 0.2)  # Verde
		ESTADOS_USUARIO.INACTIVO: return Color(0.8, 0.8, 0.2)  # Amarillo
		ESTADOS_USUARIO.PENDIENTE: return Color(0.2, 0.6, 0.8)  # Azul
		ESTADOS_USUARIO.BLOQUEADO: return Color(0.8, 0.2, 0.2)  # Rojo
		_: return Color(0.5, 0.5, 0.5)  # Gris
		

func parse_date(fecha_string: String) -> String:
	# Convertir fecha de la BD a formato legible
	if fecha_string == "" or fecha_string == null:
		return "N/A"
	
	# La fecha viene en formato SQLite: "2024-01-15 14:30:00"
	var partes = fecha_string.split(" ")
	if partes.size() > 0:
		var fecha_parts = partes[0].split("-")
		if fecha_parts.size() >= 3:
			# Formatear como DD/MM/YYYY
			return "%s/%s/%s" % [fecha_parts[2], fecha_parts[1], fecha_parts[0]]
		return partes[0]  # Retornar solo la fecha (YYYY-MM-DD)
	return fecha_string

func on_usuario_seleccionado():
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	var seleccionado = tabla.get_selected()
	
	if seleccionado:
		var id_usuario = seleccionado.get_metadata(0)
		
		if id_usuario != null:
			# Obtener TODOS los campos necesarios del usuario
			var usuario_encontrado = Bd.select_query("""
				SELECT id, username, email, nombre_completo as nombre, 
					   rol, estado_empleado as estado, departamento, 
					   ultimo_login, permisos, telefono, cargo
				FROM usuarios 
				WHERE id = ?
			""", [id_usuario])
			
			if usuario_encontrado and usuario_encontrado.size() > 0:
				usuario_seleccionado = usuario_encontrado[0]
				actualizar_botones_accion(true)
				
				# Habilitar botones según estado
				var estado = usuario_seleccionado.get("estado", "activo")
				$ContentContainer/ActionButtons/BtnDesactivar.disabled = (estado.to_lower() == "inactivo")
				
				# Actualizar información en la barra de estado
				$ContentContainer/EstadoSeleccion/TextoEstado.text = "Usuario seleccionado: " + usuario_seleccionado.get("nombre", "Sin nombre")
			else:
				usuario_seleccionado = {}
				actualizar_botones_accion(false)
				$ContentContainer/EstadoSeleccion/TextoEstado.text = "Ningún usuario seleccionado"
				
func on_nada_seleccionado():
	usuario_seleccionado = {}
	actualizar_botones_accion(false)
	$ContentContainer/EstadoSeleccion/TextoEstado.text = "Ningún usuario seleccionado"

func actualizar_botones_accion(habilitar: bool):
	$ContentContainer/ActionButtons/BtnModificar.disabled = not habilitar
	$ContentContainer/ActionButtons/BtnDesactivar.disabled = not habilitar
	$ContentContainer/ActionButtons/BtnAsignarRol.disabled = not habilitar
	$ContentContainer/ActionButtons/BtnVerTrazas.disabled = not habilitar

func buscar_usuarios():
	var texto_busqueda = $ContentContainer/SearchBar/InputBuscar.text.strip_edges()
	
	if texto_busqueda == "":
		actualizar_tabla_usuarios()
		return
	
	# Buscar en la base de datos usando consulta SQL
	var resultados = Bd.select_query("""
		SELECT id, username, email, nombre_completo, rol, estado_empleado, 
			   departamento, ultimo_login, fecha_creacion
		FROM usuarios 
		WHERE LOWER(nombre_completo) LIKE ? 
		   OR LOWER(username) LIKE ? 
		   OR LOWER(email) LIKE ?
		   OR LOWER(departamento) LIKE ?
		ORDER BY nombre_completo
	""", [
		"%" + texto_busqueda.to_lower() + "%",
		"%" + texto_busqueda.to_lower() + "%", 
		"%" + texto_busqueda.to_lower() + "%",
		"%" + texto_busqueda.to_lower() + "%"
	])
	
	if resultados != null:
		mostrar_usuarios_filtrados(resultados)
	else:
		print("❌ Error al buscar usuarios")
		mostrar_usuarios_filtrados([])
		
func on_busqueda_cambio(_nuevo_texto: String):
	# Búsqueda en tiempo real
	buscar_usuarios()

func mostrar_usuarios_filtrados(usuarios_filtrados: Array):
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	tabla.clear()
	
	if usuarios_filtrados == null:
		print("❌ Error: usuarios_filtrados es null")
		return
	
	var root = tabla.create_item()
	
	for usuario in usuarios_filtrados:
		var item = tabla.create_item(root)
		
		# Validar que usuario sea un Dictionary
		if not (usuario is Dictionary):
			print("⚠️ Advertencia: elemento no es Dictionary: ", usuario)
			continue
		
		# Usar claves con valores por defecto
		item.set_text(0, usuario.get("nombre_completo", "Sin nombre"))
		item.set_text(1, usuario.get("username", "Sin usuario"))
		item.set_text(2, obtener_texto_rol_string(usuario.get("rol", "")))
		item.set_text(3, obtener_texto_estado_string(usuario.get("estado_empleado", "")))
		
		# Color estado
		item.set_custom_color(3, obtener_color_estado_string(usuario.get("estado_empleado", "")))
		
		# Último acceso
		var ultimo_login = usuario.get("ultimo_login", "")
		if ultimo_login and ultimo_login != "":
			item.set_text(4, parse_date(ultimo_login))
		else:
			item.set_text(4, "Nunca")
		
		# Sucursal
		item.set_text(5, usuario.get("departamento", "No asignada"))
		
		# ID en metadata
		item.set_metadata(0, usuario.get("id", 0))
		
		# Botones de acción
		item.set_text(6, "🔍 ✏️ ⚠️")
		item.set_tooltip_text(6, "Ver trazas | Modificar | Desactivar")
		
func abrir_dialogo_nuevo_usuario():
	modo_edicion = false
	limpiar_formulario_usuario()
	$DialogoUsuario.title = "Nuevo Usuario"
	$DialogoUsuario/VBoxContainer/HBoxContainer/BtnGenerarPass.visible = true
	$DialogoUsuario.popup_centered()

func abrir_dialogo_modificar_usuario():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	modo_edicion = true
	llenar_formulario_usuario(usuario_seleccionado)
	$DialogoUsuario.title = "Modificar Usuario: " + usuario_seleccionado.get("nombre", "Sin nombre")
	$DialogoUsuario/VBoxContainer/HBoxContainer/BtnGenerarPass.visible = false
	$DialogoUsuario.popup_centered()

func limpiar_formulario_usuario():
	$DialogoUsuario/VBoxContainer/InputNombre.text = ""
	$DialogoUsuario/VBoxContainer/InputApellido.text = ""
	$DialogoUsuario/VBoxContainer/InputEmail.text = ""
	$DialogoUsuario/VBoxContainer/InputUsuario.text = ""
	$DialogoUsuario/VBoxContainer/HBoxContainer/InputPassword.text = ""
	$DialogoUsuario/VBoxContainer/ComboRol.select(0)
	$DialogoUsuario/VBoxContainer/ComboSucursal.select(0)
	$DialogoUsuario/VBoxContainer/CheckBoxNotificaciones.button_pressed = true
	
	# Limpiar checkboxes de permisos
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckProcesarIncidencias.button_pressed = false
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckProcesarQuejas.button_pressed = false
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckAdministrarUsuarios.button_pressed = false
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckVerTrazas.button_pressed = false
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckConfiguracion.button_pressed = false
	
	# Limpiar mensajes de error
	$MensajeError.text = ""
	
func llenar_formulario_usuario(usuario: Dictionary):
	# Separar nombre y apellido (simulación)
	# Usar .get() con valor por defecto
	var nombre_completo = usuario.get("nombre", "").split(" ")
	if nombre_completo.size() >= 2:
		$DialogoUsuario/VBoxContainer/InputNombre.text = nombre_completo[0]
		$DialogoUsuario/VBoxContainer/InputApellido.text = " ".join(nombre_completo.slice(1))
	else:
		$DialogoUsuario/VBoxContainer/InputNombre.text = usuario.get("nombre", "")
		$DialogoUsuario/VBoxContainer/InputApellido.text = ""
	
	$DialogoUsuario/VBoxContainer/InputEmail.text = usuario.get("email", "")
	$DialogoUsuario/VBoxContainer/InputUsuario.text = usuario.get("username", "")
	
	# Seleccionar rol en combo - mapear desde BD a ID del combo
	var rol_bd = usuario.get("rol", "")
	var rol_id = 0
	match rol_bd:
		"admin": rol_id = 1
		"supervisor": rol_id = 2
		"operador": rol_id = 3
		"analista": rol_id = 4
		"legal": rol_id = 5
		"gerente": rol_id = 6
	
	var combo_rol = $DialogoUsuario/VBoxContainer/ComboRol
	for i in range(combo_rol.item_count):
		if combo_rol.get_item_id(i) == rol_id:
			combo_rol.select(i)
			break
	
	# Seleccionar sucursal en combo
	var sucursal = usuario.get("departamento", "")
	var combo_sucursal = $DialogoUsuario/VBoxContainer/ComboSucursal
	for i in range(1, combo_sucursal.item_count):  # Empezar desde 1 (saltar "Seleccionar Sucursal*")
		if combo_sucursal.get_item_text(i) == sucursal:
			combo_sucursal.select(i)
			break
	
	# Configurar permisos según el usuario
	var permisos_str = usuario.get("permisos", "[]")
	var permisos = JSON.parse_string(permisos_str)
	if permisos == null:
		permisos = []
	
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckProcesarIncidencias.button_pressed = "PROCESAR_INCIDENCIAS" in permisos
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckProcesarQuejas.button_pressed = "PROCESAR_QUEJAS" in permisos
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckAdministrarUsuarios.button_pressed = "ADMINISTRAR_USUARIOS" in permisos
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckVerTrazas.button_pressed = "VER_TRAZAS" in permisos
	$DialogoUsuario/VBoxContainer/PermisosContainer/CheckConfiguracion.button_pressed = "CONFIGURACION" in permisos
	

func generar_contrasena_aleatoria():
	var caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%"
	var contrasena = ""
	for i in range(12):
		contrasena += caracteres[randi() % caracteres.length()]
	
	$DialogoUsuario/VBoxContainer/HBoxContainer/InputPassword.text = contrasena

func obtener_permisos_seleccionados() -> Array:
	var permisos = []
	
	if $DialogoUsuario/VBoxContainer/PermisosContainer/CheckProcesarIncidencias.button_pressed:
		permisos.append("PROCESAR_INCIDENCIAS")
	if $DialogoUsuario/VBoxContainer/PermisosContainer/CheckProcesarQuejas.button_pressed:
		permisos.append("PROCESAR_QUEJAS")
	if $DialogoUsuario/VBoxContainer/PermisosContainer/CheckAdministrarUsuarios.button_pressed:
		permisos.append("ADMINISTRAR_USUARIOS")
	if $DialogoUsuario/VBoxContainer/PermisosContainer/CheckVerTrazas.button_pressed:
		permisos.append("VER_TRAZAS")
	if $DialogoUsuario/VBoxContainer/PermisosContainer/CheckConfiguracion.button_pressed:
		permisos.append("CONFIGURACION")
	
	return permisos

func validar_formulario_usuario() -> bool:
	# Limpiar mensaje de error
	$DialogoUsuario/VBoxContainer/MensajeError.dialog_text = ""
	
	var campos_requeridos = [
		$DialogoUsuario/VBoxContainer/InputNombre.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/InputApellido.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges()
	]
	
	# En modo creación, validar contraseña también
	if not modo_edicion:
		campos_requeridos.append($DialogoUsuario/VBoxContainer/HBoxContainer/InputPassword.text.strip_edges())
	
	# Verificar que ningún campo requerido esté vacío
	for campo in campos_requeridos:
		if campo == "":
			$DialogoUsuario/VBoxContainer/MensajeError.text = "Todos los campos marcados con * son obligatorios"
			return false
	
	# Validar email
	var email = $DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges()
	if not "@" in email or not "." in email:
		$DialogoUsuario/VBoxContainer/MensajeError.text = "Ingrese un email válido"
		return false
	
	# Validar que se haya seleccionado un rol
	if $DialogoUsuario/VBoxContainer/ComboRol.selected == -1:
		$DialogoUsuario/VBoxContainer/MensajeError.text = "Debe seleccionar un rol"
		return false
	
	# Validar que se haya seleccionado una sucursal
	if $DialogoUsuario/VBoxContainer/ComboSucursal.selected == 0:
		$DialogoUsuario/VBoxContainer/MensajeError.text = "Debe seleccionar una sucursal"
		return false
	
	# Validar nombre de usuario único (solo en modo creación)
	if not modo_edicion:
		var nuevo_usuario = $DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges()
		var existe = Bd.select_query("SELECT COUNT(*) as count FROM usuarios WHERE username = ?", [nuevo_usuario])
		
		if existe and existe[0]["count"] > 0:
			$DialogoUsuario/VBoxContainer/MensajeError.text = "El nombre de usuario ya existe"
			return false
	
	return true
	
func obtener_permisos_de_json(permisos_json: String) -> Array:
	if permisos_json == "" or permisos_json == "[]":
		return []
	
	var result = JSON.parse_string(permisos_json)
	if result is Array:
		return result
	return []
	
func guardar_usuario():
	if not validar_formulario_usuario():
		return
	
	mostrar_carga("Guardando usuario...")
	
	# Simular operación de guardado con delay
	await get_tree().create_timer(0.5).timeout
	
	var exito = false
	if modo_edicion:
		# Modificar usuario existente en BD
		exito = modificar_usuario_existente()
	else:
		# Crear nuevo usuario en BD
		exito = crear_nuevo_usuario()
	
	ocultar_carga()
	
	if exito:
		$DialogoUsuario.hide()
		actualizar_tabla_usuarios()

func crear_nuevo_usuario():
	# Obtener datos del formulario
	var nombre_completo = $DialogoUsuario/VBoxContainer/InputNombre.text.strip_edges() + " " + $DialogoUsuario/VBoxContainer/InputApellido.text.strip_edges()
	var username = $DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges()
	var email = $DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges()
	var password = $DialogoUsuario/VBoxContainer/HBoxContainer/InputPassword.text.strip_edges()
	
	# Mapear el rol del combo al formato de la BD
	var rol_combo = $DialogoUsuario/VBoxContainer/ComboRol.get_item_id($DialogoUsuario/VBoxContainer/ComboRol.selected)
	var rol_bd = mapear_rol_a_bd(rol_combo)
	
	# Obtener sucursal
	var sucursal = $DialogoUsuario/VBoxContainer/ComboSucursal.get_item_text($DialogoUsuario/VBoxContainer/ComboSucursal.selected)
	
	# Obtener permisos como JSON string
	var permisos_json = JSON.stringify(obtener_permisos_seleccionados())
	
	# Crear hash de la contraseña (en producción usar bcrypt o similar)
	var password_hash = password.sha256_text()
	
	# Preparar datos para insertar en BD
	var datos_usuario = {
		"username": username,
		"password_hash": password_hash,
		"email": email,
		"nombre_completo": nombre_completo,
		"telefono": "",  # Puedes añadir campo en el formulario si lo necesitas
		"departamento": sucursal,
		"cargo": "Usuario",
		"rol": rol_bd,
		"estado_empleado": "activo",
		"permisos": permisos_json,
		"tema_preferido": "claro",
		"idioma": "es",
		"zona_horaria": "America/Havana",
		"notificaciones_email": $DialogoUsuario/VBoxContainer/CheckBoxNotificaciones.button_pressed,
		"notificaciones_push": true,
		"fecha_creacion": Time.get_datetime_string_from_system(),
		"creado_por": 1  # ID del administrador que crea el usuario
	}
	
	# Insertar en la base de datos
	var id_insertado = Bd.insert("usuarios", datos_usuario)
	
	if id_insertado > 0:
		print("✅ Usuario creado en BD con ID: ", id_insertado)
		usuario_creado.emit(datos_usuario)
		
		# Registrar en trazas la creación del usuario
		var datos_traza = {
			"usuario_id": usuario_actual.get("id", 0),
			"accion": "CREACION",
			"descripcion": "Creación de nuevo usuario: " + username,
			"modulo": "Administración de Usuarios",
			"ip": "localhost",
			"detalles": "Rol: " + rol_bd + ", Sucursal: " + sucursal
		}
		registrar_traza_bd(datos_traza)
		
		mostrar_exito("Usuario creado exitosamente en la base de datos")
		return true
	else:
		print("❌ Error al crear usuario en BD")
		mostrar_error("Error al guardar usuario en base de datos")
		return false

func modificar_usuario_existente() -> bool:
	if usuario_seleccionado.is_empty():
		return false
	
	# Obtener datos actualizados del formulario
	var nombre_completo = $DialogoUsuario/VBoxContainer/InputNombre.text.strip_edges() + " " + $DialogoUsuario/VBoxContainer/InputApellido.text.strip_edges()
	var email = $DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges()
	var username = $DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges()
	
	# Mapear rol
	var rol_combo = $DialogoUsuario/VBoxContainer/ComboRol.get_item_id($DialogoUsuario/VBoxContainer/ComboRol.selected)
	var rol_bd = mapear_rol_a_bd(rol_combo)
	
	# Obtener permisos como JSON
	var permisos_json = JSON.stringify(obtener_permisos_seleccionados())
	
	# Datos a actualizar
	var datos_actualizados = {
		"nombre_completo": nombre_completo,
		"email": email,
		"username": username,
		"rol": rol_bd,
		"departamento": $DialogoUsuario/VBoxContainer/ComboSucursal.get_item_text($DialogoUsuario/VBoxContainer/ComboSucursal.selected),
		"permisos": permisos_json,
		"notificaciones_email": $DialogoUsuario/VBoxContainer/CheckBoxNotificaciones.button_pressed,
		"fecha_modificacion": Time.get_datetime_string_from_system(),
		"modificado_por": 1
	}
	
	# Actualizar en la BD - CORREGIR: Manejar diferentes tipos de retorno
	var resultado = Bd.update("usuarios", datos_actualizados, "id = ?", [usuario_seleccionado.get("id", 0)])
	
	# Manejar diferentes tipos de retorno
	var exito = false
	
	if resultado is bool:
		exito = resultado
		print("✅ Resultado de update (bool): ", resultado)
	elif resultado is int:
		exito = resultado > 0
		print("✅ Filas afectadas (int): ", resultado)
	else:
		print("❌ Tipo de retorno desconocido: ", typeof(resultado))
	
	if exito:
		print("✅ Usuario actualizado en BD, ID: ", usuario_seleccionado.get("id", 0))
		usuario_modificado.emit(str(usuario_seleccionado.get("id", 0)), datos_actualizados)
		
		# Registrar en trazas la modificación del usuario
		var datos_traza = {
			"usuario_id": usuario_actual.get("id", 0),
			"accion": "MODIFICACION",
			"descripcion": "Modificación de usuario: " + usuario_seleccionado.get("username", ""),
			"modulo": "Administración de Usuarios",
			"ip": "localhost",
			"detalles": "Nuevo rol: " + rol_bd + ", Nuevo nombre: " + nombre_completo
		}
		registrar_traza_bd(datos_traza)
		
		mostrar_exito("Usuario modificado exitosamente")
		return true
	else:
		print("❌ Error al actualizar usuario en BD")
		mostrar_error("Error al actualizar usuario en base de datos")
		return false

func solicitar_desactivar_usuario():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	# Usar .get() con valor por defecto
	var estado = usuario_seleccionado.get("estado", "activo")
	if estado.to_lower() == "inactivo":
		mostrar_error("El usuario ya está inactivo")
		return
	
	# CORREGIR: La ruta correcta es VBoxContainer/MensajeConfirmacion
	$DialogoConfirmacion/VBoxContainer/MensajeConfirmacion.text = "¿Está seguro de que desea desactivar al usuario:\n" + usuario_seleccionado.get("nombre", "Usuario sin nombre") + "?"
	$DialogoConfirmacion.popup_centered()
	
func confirmar_operacion():
	$DialogoConfirmacion.hide()
	
	if usuario_seleccionado.is_empty():
		return
	
	# Actualizar estado en la BD
	var resultado = Bd.update("usuarios", 
		{"estado_empleado": "inactivo", "fecha_modificacion": Time.get_datetime_string_from_system()},
		"id = ?", 
		[usuario_seleccionado.get("id", 0)]
	)
	
	# Manejar diferentes tipos de retorno
	var exito = false
	
	if resultado is bool:
		exito = resultado
	elif resultado is int:
		exito = resultado > 0
	
	if exito:
		print("✅ Usuario desactivado en BD, ID: ", usuario_seleccionado.get("id", 0))
		usuario_desactivado.emit(str(usuario_seleccionado.get("id", 0)))
		
		# Registrar en trazas la desactivación del usuario
		var datos_traza = {
			"usuario_id": usuario_actual.get("id", 0),
			"accion": "MODIFICACION",
			"descripcion": "Desactivación de usuario: " + usuario_seleccionado.get("username", ""),
			"modulo": "Administración de Usuarios",
			"ip": "localhost",
			"detalles": "Usuario desactivado por administrador"
		}
		registrar_traza_bd(datos_traza)
		
		mostrar_exito("Usuario desactivado exitosamente")
		
		# Actualizar la tabla
		actualizar_tabla_usuarios()
	else:
		mostrar_error("Error al desactivar usuario en base de datos")
	
	# Limpiar selección
	usuario_seleccionado = {}
	actualizar_botones_accion(false)

func cancelar_operacion():
	$DialogoConfirmacion.hide()

func abrir_dialogo_asignar_rol():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	# Crear un diálogo de confirmación (mejor que AcceptDialog)
	var dialog = ConfirmationDialog.new()
	dialog.title = "Asignar Rol"
	dialog.dialog_text = "Asignar nuevo rol a: " + usuario_seleccionado.get("nombre", "Usuario sin nombre")
	dialog.size = Vector2(400, 250)
	
	# Agregar opciones de rol
	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = "Seleccione el nuevo rol:"
	vbox.add_child(label)
	
	var option_button = OptionButton.new()
	option_button.add_item("Administrador", 1)
	option_button.add_item("Supervisor", 2)
	option_button.add_item("Operador", 3)
	option_button.add_item("Analista", 4)
	option_button.add_item("Legal", 5)
	option_button.add_item("Gerente", 6)
	vbox.add_child(option_button)
	
	# Centrar contenido
	var container = CenterContainer.new()
	container.add_child(vbox)
	dialog.add_child(container)
	
	# Conectar señales
	dialog.confirmed.connect(
		func():
			var nuevo_rol_id = option_button.get_selected_id()
			asignar_nuevo_rol(nuevo_rol_id)
			dialog.queue_free()
	)
	
	dialog.canceled.connect(func(): dialog.queue_free())
	
	# Mostrar diálogo
	add_child(dialog)
	dialog.popup_centered()

func asignar_nuevo_rol(rol_id: int):
	# Convertir ID a string de rol
	var rol_bd = mapear_rol_a_bd(rol_id)
	
	# Actualizar en BD
	var resultado = Bd.update("usuarios", 
		{"rol": rol_bd, "fecha_modificacion": Time.get_datetime_string_from_system()},
		"id = ?", 
		[usuario_seleccionado.get("id", 0)]
	)
	
	# Manejar diferentes tipos de retorno
	var exito = false
	
	if resultado is bool:
		exito = resultado
	elif resultado is int:
		exito = resultado > 0
	
	if exito:
		# Registrar en trazas el cambio de rol
		var datos_traza = {
			"usuario_id": usuario_actual.get("id", 0),
			"accion": "MODIFICACION",
			"descripcion": "Cambio de rol para usuario: " + usuario_seleccionado.get("username", ""),
			"modulo": "Administración de Usuarios",
			"ip": "localhost",
			"detalles": "Nuevo rol: " + rol_bd + ", Rol anterior: " + usuario_seleccionado.get("rol", "")
		}
		registrar_traza_bd(datos_traza)
		
		mostrar_exito("Rol actualizado exitosamente")
		actualizar_tabla_usuarios()
	else:
		mostrar_error("Error al actualizar el rol")
		
func ver_trazas_usuario():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	mostrar_carga("Cargando trazas del usuario...")
	
	# Registrar en trazas que se está viendo las trazas de otro usuario
	var datos_traza = {
		"usuario_id": usuario_actual.get("id", 0),
		"accion": "CONSULTA",
		"descripcion": "Visualización de trazas del usuario: " + usuario_seleccionado.get("username", ""),
		"modulo": "Administración de Usuarios",
		"ip": "localhost",
		"detalles": "Usuario ID: " + str(usuario_seleccionado.get("id", 0))
	}
	registrar_traza_bd(datos_traza)
	
	# Cargar la escena de visualización de trazas
	var escena_trazas = load("res://escenas/TrazasVisualizar.tscn")
	if escena_trazas:
		var instancia_trazas = escena_trazas.instantiate()
		
		# Pasar datos del usuario seleccionado a la escena de trazas
		if instancia_trazas.has_method("set_usuario"):
			instancia_trazas.set_usuario(
				usuario_seleccionado.get("id", 0),
				usuario_seleccionado
			)
		
		# Cambiar a la escena de trazas
		get_tree().root.add_child(instancia_trazas)
		get_tree().root.remove_child(self)
		self.queue_free()
		ocultar_carga()
	else:
		ocultar_carga()
		mostrar_error("No se pudo cargar la escena de visualización de trazas")
				
func exportar_lista_usuarios():
	mostrar_carga("Exportando lista de usuarios...")
	
	# Obtener usuarios de la base de datos - CAMBIAR NOMBRE DE VARIABLE
	var usuarios_db = Bd.select_query("""
		SELECT username, email, nombre_completo, rol, estado_empleado, departamento
		FROM usuarios 
		ORDER BY username
	""")
	
	if usuarios_db == null or usuarios_db.size() == 0:
		ocultar_carga()
		mostrar_error("No hay usuarios para exportar")
		return
	
	# Crear CSV simple
	var csv = "Usuario,Email,Nombre,Rol,Estado,Sucursal\n"
	for usuario in usuarios_db:  # Usar la variable renombrada
		csv += "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" % [
			usuario.get("username", ""),
			usuario.get("email", ""),
			usuario.get("nombre_completo", ""),
			usuario.get("rol", ""),
			usuario.get("estado_empleado", ""),
			usuario.get("departamento", "")
		]
	
	# Guardar en archivo
	var fecha_actual = Time.get_datetime_string_from_system()
	fecha_actual = fecha_actual.replace(":", "-").replace(" ", "_")
	var nombre_archivo = "usuarios_%s.csv" % [fecha_actual]
	var archivo = FileAccess.open("user://" + nombre_archivo, FileAccess.WRITE)
	
	if archivo:
		archivo.store_string(csv)
		archivo.close()
		
		# Registrar en trazas la exportación
		var datos_traza = {
			"usuario_id": usuario_actual.get("id", 0),
			"accion": "EXPORTACION",
			"descripcion": "Exportación de lista de usuarios",
			"modulo": "Administración de Usuarios",
			"ip": "localhost",
			"detalles": "Archivo: " + nombre_archivo + ", Registros: " + str(usuarios_db.size())
		}
		registrar_traza_bd(datos_traza)
		
		print("✅ Exportados %d usuarios a: %s" % [usuarios_db.size(), nombre_archivo])
		ocultar_carga()
		mostrar_exito("Lista de usuarios exportada exitosamente:\n%s" % nombre_archivo)
	else:
		ocultar_carga()
		print("❌ Error al guardar archivo")
		mostrar_error("Error al guardar el archivo CSV")
		
		
func actualizar_lista_usuarios():
	mostrar_carga("Actualizando lista de usuarios...")
	
	# Simular actualización
	await get_tree().create_timer(0.5).timeout
	actualizar_tabla_usuarios()
	ocultar_carga()
	
	mostrar_exito("Lista de usuarios actualizada")

func cerrar_dialogo_usuario():
	$DialogoUsuario.hide()

func mostrar_carga(mensaje: String):
	$PanelCargando/MensajeCarga.text = mensaje
	$PanelCargando.visible = true

func ocultar_carga():
	$PanelCargando.visible = false

func mostrar_exito(mensaje: String):
	$MensajeExito.dialog_text = mensaje
	$MensajeExito.popup_centered()

func mostrar_error(mensaje: String):
	$MensajeError.dialog_text = mensaje
	$MensajeError.popup_centered()

func _process(_delta):
	# Actualizar barra de progreso (animación)
	if $PanelCargando.visible:
		var progress = $PanelCargando/ProgressBar
		progress.value = fmod(progress.value + 1.0, 100.0)
		
func regresar_menu_principal():
	# Mostrar diálogo de confirmación si hay cambios sin guardar
	if hay_cambios_sin_guardar():
		# CORREGIR: Usar la ruta correcta
		$DialogoConfirmacion/VBoxContainer/MensajeConfirmacion.text = "Hay cambios sin guardar. ¿Seguro que desea regresar al menú principal?"
		$DialogoConfirmacion.popup_centered()
		
		# Conectar señales temporales para manejar la confirmación
		$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.disconnect(confirmar_operacion)
		$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.disconnect(cancelar_operacion)
		
		$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.connect(confirmar_regreso.bind(true), CONNECT_ONE_SHOT)
		$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.connect(confirmar_regreso.bind(false), CONNECT_ONE_SHOT)
	else:
		# Si no hay cambios, regresar directamente
		cambiar_a_menu_principal()

func hay_cambios_sin_guardar() -> bool:
	# Esta función debería verificar si hay cambios pendientes
	# Por ahora, retornamos false si no hay diálogos abiertos
	return $DialogoUsuario.visible

func confirmar_regreso(confirmado: bool):
	$DialogoConfirmacion.hide()
	
	if confirmado:
		cambiar_a_menu_principal()
	
	# Reconectar las señales originales
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.disconnect(confirmar_regreso)
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.disconnect(confirmar_regreso)
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.connect(confirmar_operacion)
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.connect(cancelar_operacion)

func cambiar_a_menu_principal():
	# Cerrar cualquier diálogo abierto
	if $DialogoUsuario.visible:
		$DialogoUsuario.hide()
	
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

# pruebas




# Función mejorada para crear usuarios de prueba
func crear_varios_usuarios_prueba():
	print("📝 Creando usuarios de prueba...")
	
	# Lista de usuarios de prueba CON ROLES VÁLIDOS
	var usuarios_prueba = [
		{
			"username": "admin",
			"password_hash": "admin123",
			"email": "admin@sistema.com",
			"nombre_completo": "Administrador Sistema",
			"rol": "admin",  # VÁLIDO
			"estado_empleado": "activo",
			"departamento": "TI",
			"cargo": "Administrador",
			"permisos": "[\"todos_permisos\"]",
			"telefono": "555-0101"
		},
		{
			"username": "supervisor1",
			"password_hash": "pass123",
			"email": "supervisor@empresa.com",
			"nombre_completo": "Juan Pérez López",
			"rol": "supervisor",  # VÁLIDO
			"estado_empleado": "activo",
			"departamento": "Calidad",
			"cargo": "Supervisor de Calidad",
			"permisos": "[\"procesar_incidencias\", \"procesar_quejas\"]",
			"telefono": "555-0102"
		},
		{
			"username": "analista1",  # CAMBIADO de calidad1
			"password_hash": "pass123",
			"email": "analista@empresa.com",
			"nombre_completo": "María García Ruiz",
			"rol": "analista",  # VÁLIDO (en lugar de "especialista_calidad")
			"estado_empleado": "activo",
			"departamento": "Control Calidad",
			"cargo": "Analista de Calidad",  # CAMBIADO
			"permisos": "[\"procesar_incidencias\"]",
			"telefono": "555-0103"
		},
		{
			"username": "legal1",  # CAMBIADO de auditor1
			"password_hash": "pass123",
			"email": "legal@empresa.com",
			"nombre_completo": "Carlos López Méndez",
			"rol": "legal",  # VÁLIDO (en lugar de "auditor")
			"estado_empleado": "activo",
			"departamento": "Legal",
			"cargo": "Especialista Legal",  # CAMBIADO
			"permisos": "[\"ver_trazas\"]",
			"telefono": "555-0104"
		},
		{
			"username": "operador1",
			"password_hash": "pass123",
			"email": "operador@empresa.com",
			"nombre_completo": "Ana Martínez Sánchez",
			"rol": "operador",  # VÁLIDO
			"estado_empleado": "inactivo",
			"departamento": "Ventas",
			"cargo": "Operadora",
			"permisos": "[\"ver_dashboard\", \"crear_queja\"]",
			"telefono": "555-0105"
		}
	]
	
	var creados = 0
	for usuario in usuarios_prueba:
		# Verificar si ya existe
		var existe = Bd.select_query("SELECT COUNT(*) as count FROM usuarios WHERE username = ?", [usuario["username"]])
		
		if existe and existe[0]["count"] == 0:
			# Insertar usuario
			var id = Bd.insert("usuarios", usuario)
			if id > 0:
				creados += 1
				print("✅ Usuario creado: %s (ID: %d)" % [usuario["username"], id])
			else:
				print("❌ Error al crear usuario: %s" % usuario["username"])
		else:
			print("⚠️ Usuario ya existe: %s" % usuario["username"])
	
	print("🎉 Total usuarios creados/actualizados: %d" % creados)
	
	# Actualizar la tabla
	actualizar_tabla_usuarios()
	
	return creados





func probar_conexion_bd():
	print("🧪 Probando conexión a BD desde UserManagement...")
	
	# Prueba simple
	var test = Bd.select_query("SELECT COUNT(*) as total FROM usuarios")
	if test:
		print("✅ Conexión BD OK. Usuarios totales: ", test[0]["total"])
	else:
		print("❌ Error en conexión BD")
	
	# Verificar estructura de tabla
	var estructura = Bd.select_query("PRAGMA table_info(usuarios)")
	if estructura:
		print("📊 Columnas de tabla 'usuarios':")
		for col in estructura:
			print("  - ", col["name"], " (", col["type"], ")")
			
func mapear_rol_a_bd(rol_combo_id: int) -> String:
	# Mapear los IDs del combo a los valores de rol de la BD
	match rol_combo_id:
		1: return "admin"      # Administrador
		2: return "supervisor" # Supervisor
		3: return "operador"   # Operador
		4: return "analista"   # Analista
		5: return "legal"      # Legal
		6: return "gerente"    # Gerente
		_: return "operador"   # Valor por defecto

func registrar_traza_bd(datos_traza: Dictionary):
	# Verificar si la tabla de trazas existe
	var tabla_existe = Bd.select_query("""
		SELECT name FROM sqlite_master 
		WHERE type='table' AND name='trazas_usuario'
	""")
	
	if tabla_existe and tabla_existe.size() > 0:
		# Agregar fecha actual si no existe
		if not datos_traza.has("fecha"):
			datos_traza["fecha"] = Time.get_datetime_string_from_system()
		
		# Insertar la traza
		var id_insertado = Bd.insert("trazas_usuario", datos_traza)
		if id_insertado > 0:
			print("✅ Traza registrada en BD, ID: ", id_insertado)
		else:
			print("❌ Error al registrar traza en BD")
	else:
		print("⚠️ Tabla 'trazas_usuario' no existe. Traza no registrada.")
