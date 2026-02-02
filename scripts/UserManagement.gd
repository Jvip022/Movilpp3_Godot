extends Control
class_name UserManagement

# Señales
signal usuario_creado(datos_usuario: Dictionary)
signal usuario_modificado(id_usuario: String, datos_usuario: Dictionary)
signal usuario_desactivado(id_usuario: String)
signal error_operacion(mensaje: String)

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
var usuarios: Array = []  # Change from Array[Dictionary] to Array
var usuario_seleccionado: Dictionary = {}
var modo_edicion: bool = false

func _ready():
	# Inicializar tabla de usuarios
	inicializar_tabla()
	
	# Cargar usuarios de ejemplo
	cargar_usuarios_ejemplo()
	
	# Conectar señales de los botones principales
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
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarSi.pressed.connect(confirmar_operacion)
	$DialogoConfirmacion/VBoxContainer/HBoxContainer/BtnConfirmarNo.pressed.connect(cancelar_operacion)
	
	# Conectar señal de búsqueda en tiempo real
	$ContentContainer/SearchBar/InputBuscar.text_changed.connect(on_busqueda_cambio)
	
	# Cargar roles en combobox
	inicializar_combo_roles()
	inicializar_combo_sucursales()
	
	# Deshabilitar botones de acción inicialmente
	actualizar_botones_accion(false)

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
	combo.add_item("Seleccionar Rol*", ROLES_USUARIO.SUPERVISOR_GENERAL)
	combo.set_item_text(ROLES_USUARIO.SUPERVISOR_GENERAL, "Supervisor General")
	combo.add_item("Cliente", ROLES_USUARIO.CLIENTE)
	combo.add_item("Especialista de Calidad", ROLES_USUARIO.ESPECIALISTA_CALIDAD)
	combo.add_item("Auditor", ROLES_USUARIO.AUDITOR)
	combo.add_item("Administrador", ROLES_USUARIO.ADMINISTRADOR)

func inicializar_combo_sucursales():
	var combo = $DialogoUsuario/VBoxContainer/ComboSucursal
	combo.clear()
	combo.add_item("Seleccionar Sucursal*")
	for i in range(sucursales_disponibles.size()):
		combo.add_item(sucursales_disponibles[i])

func cargar_usuarios_ejemplo():
	# Crear usuarios de ejemplo para pruebas
	var usuarios_ejemplo = [
		{
			"id": "USR001",
			"nombre": "Carlos Méndez",
			"usuario": "cmendez",
			"email": "cmendez@empresa.com",
			"rol": ROLES_USUARIO.ADMINISTRADOR,
			"estado": ESTADOS_USUARIO.ACTIVO,
			"sucursal": "La Habana",
			"ultimo_acceso": "15/02/2024 09:30",
			"permisos": ["ADMINISTRAR_USUARIOS", "VER_TRAZAS", "CONFIGURACION"]
		},
		{
			"id": "USR002",
			"nombre": "Ana Rodríguez",
			"usuario": "arodriguez",
			"email": "arodriguez@empresa.com",
			"rol": ROLES_USUARIO.SUPERVISOR_GENERAL,
			"estado": ESTADOS_USUARIO.ACTIVO,
			"sucursal": "Varadero",
			"ultimo_acceso": "14/02/2024 14:20",
			"permisos": ["PROCESAR_INCIDENCIAS", "PROCESAR_QUEJAS"]
		},
		{
			"id": "USR003",
			"nombre": "Luis Fernández",
			"usuario": "lfernandez",
			"email": "lfernandez@empresa.com",
			"rol": ROLES_USUARIO.ESPECIALISTA_CALIDAD,
			"estado": ESTADOS_USUARIO.ACTIVO,
			"sucursal": "Viñales",
			"ultimo_acceso": "13/02/2024 11:15",
			"permisos": ["PROCESAR_INCIDENCIAS"]
		},
		{
			"id": "USR004",
			"nombre": "María López",
			"usuario": "mlopez",
			"email": "mlopez@empresa.com",
			"rol": ROLES_USUARIO.AUDITOR,
			"estado": ESTADOS_USUARIO.ACTIVO,
			"sucursal": "Trinidad",
			"ultimo_acceso": "12/02/2024 16:45",
			"permisos": ["VER_TRAZAS"]
		},
		{
			"id": "USR005",
			"nombre": "Juan Pérez",
			"usuario": "jperez",
			"email": "jperez@empresa.com",
			"rol": ROLES_USUARIO.CLIENTE,
			"estado": ESTADOS_USUARIO.ACTIVO,
			"sucursal": "Santiago de Cuba",
			"ultimo_acceso": "10/02/2024 10:00",
			"permisos": []
		}
	]
	
	usuarios = usuarios_ejemplo
	actualizar_tabla_usuarios()

func actualizar_tabla_usuarios():
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	tabla.clear()  # Clear first
	
	# Create root item AFTER clearing
	var root = tabla.create_item()
	
	for usuario in usuarios:
		var item = tabla.create_item(root)  # Create as child of root
		
		# Nombre completo
		item.set_text(0, usuario["nombre"])
		
		# Usuario
		item.set_text(1, usuario["usuario"])
		
		# Rol
		var rol_text = obtener_texto_rol(usuario["rol"])
		item.set_text(2, rol_text)
		
		# Estado
		var estado_text = obtener_texto_estado(usuario["estado"])
		var estado_color = obtener_color_estado(usuario["estado"])
		item.set_text(3, estado_text)
		item.set_custom_color(3, estado_color)
		
		# Último acceso
		item.set_text(4, usuario.get("ultimo_acceso", "Nunca"))
		
		# Sucursal
		item.set_text(5, usuario.get("sucursal", "No asignada"))
		
		# Botones de acción en la última columna (simulado con texto)
		item.set_text(6, "🔍 ✏️ ⚠️")
		
func obtener_texto_rol(rol_id: int) -> String:
	match rol_id:
		ROLES_USUARIO.SUPERVISOR_GENERAL: return "Supervisor General"
		ROLES_USUARIO.CLIENTE: return "Cliente"
		ROLES_USUARIO.ESPECIALISTA_CALIDAD: return "Especialista Calidad"
		ROLES_USUARIO.AUDITOR: return "Auditor"
		ROLES_USUARIO.ADMINISTRADOR: return "Administrador"
		_: return "Sin rol"

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

func on_usuario_seleccionado():
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	var seleccionado = tabla.get_selected()
	
	if seleccionado:
		var index = seleccionado.get_index()
		if index >= 0 and index < usuarios.size():
			usuario_seleccionado = usuarios[index]
			actualizar_botones_accion(true)
			
			# Habilitar botones según el estado del usuario
			var estado = usuario_seleccionado.get("estado", ESTADOS_USUARIO.ACTIVO)
			$ContentContainer/ActionButtons/BtnDesactivar.disabled = (estado == ESTADOS_USUARIO.INACTIVO)

func on_nada_seleccionado():
	usuario_seleccionado = {}
	actualizar_botones_accion(false)

func actualizar_botones_accion(habilitar: bool):
	$ContentContainer/ActionButtons/BtnModificar.disabled = not habilitar
	$ContentContainer/ActionButtons/BtnDesactivar.disabled = not habilitar
	$ContentContainer/ActionButtons/BtnAsignarRol.disabled = not habilitar
	$ContentContainer/ActionButtons/BtnVerTrazas.disabled = not habilitar

func buscar_usuarios():
	var texto_busqueda = $ContentContainer/SearchBar/InputBuscar.text.strip_edges().to_lower()
	
	if texto_busqueda == "":
		actualizar_tabla_usuarios()
		return
	
	var resultados = []
	for usuario in usuarios:
		var nombre_completo = usuario["nombre"].to_lower()
		var nombre_usuario = usuario["usuario"].to_lower()
		var email = usuario["email"].to_lower()
		
		if (texto_busqueda in nombre_completo or 
			texto_busqueda in nombre_usuario or 
			texto_busqueda in email):
			resultados.append(usuario)
	
	# Mostrar resultados filtrados
	mostrar_usuarios_filtrados(resultados)

func on_busqueda_cambio(_nuevo_texto: String):
	# Búsqueda en tiempo real
	buscar_usuarios()

func mostrar_usuarios_filtrados(usuarios_filtrados: Array):
	var tabla = $ContentContainer/UserTableContainer/TablaUsuarios
	tabla.clear()  # Clear first
	
	# Create root item AFTER clearing
	var root = tabla.create_item()
	
	for usuario in usuarios_filtrados:
		var item = tabla.create_item(root)  # Create as child of root
		item.set_text(0, usuario["nombre"])
		item.set_text(1, usuario["usuario"])
		item.set_text(2, obtener_texto_rol(usuario["rol"]))
		item.set_text(3, obtener_texto_estado(usuario["estado"]))
		item.set_custom_color(3, obtener_color_estado(usuario["estado"]))
		item.set_text(4, usuario.get("ultimo_acceso", "Nunca"))
		item.set_text(5, usuario.get("sucursal", "No asignada"))
		item.set_text(6, "🔍 ✏️ ⚠️")

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
	$DialogoUsuario.title = "Modificar Usuario: " + usuario_seleccionado["nombre"]
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

func llenar_formulario_usuario(usuario: Dictionary):
	# Separar nombre y apellido (simulación)
	var nombre_completo = usuario["nombre"].split(" ")
	if nombre_completo.size() >= 2:
		$DialogoUsuario/VBoxContainer/InputNombre.text = nombre_completo[0]
		$DialogoUsuario/VBoxContainer/InputApellido.text = " ".join(nombre_completo.slice(1))
	else:
		$DialogoUsuario/VBoxContainer/InputNombre.text = usuario["nombre"]
		$DialogoUsuario/VBoxContainer/InputApellido.text = ""
	
	$DialogoUsuario/VBoxContainer/InputEmail.text = usuario["email"]
	$DialogoUsuario/VBoxContainer/InputUsuario.text = usuario["usuario"]
	
	# Seleccionar rol en combo
	var combo_rol = $DialogoUsuario/VBoxContainer/ComboRol
	for i in range(combo_rol.item_count):
		if combo_rol.get_item_id(i) == usuario["rol"]:
			combo_rol.select(i)
			break
	
	# Seleccionar sucursal en combo
	var combo_sucursal = $DialogoUsuario/VBoxContainer/ComboSucursal
	for i in range(1, combo_sucursal.item_count):  # Empezar desde 1 (saltar "Seleccionar Sucursal*")
		if combo_sucursal.get_item_text(i) == usuario.get("sucursal", ""):
			combo_sucursal.select(i)
			break
	
	# Configurar permisos según el usuario
	var permisos = usuario.get("permisos", [])
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

func obtener_permisos_seleccionados() -> Array[String]:
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
	var campos_requeridos = [
		$DialogoUsuario/VBoxContainer/InputNombre.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/InputApellido.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges(),
		$DialogoUsuario/VBoxContainer/HBoxContainer/InputPassword.text.strip_edges()
	]
	
	# Verificar que ningún campo requerido esté vacío
	for campo in campos_requeridos:
		if campo == "":
			mostrar_error("Todos los campos marcados con * son obligatorios")
			return false
	
	# Validar email
	var email = $DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges()
	if not "@" in email or not "." in email:
		mostrar_error("Ingrese un email válido")
		return false
	
	# Validar que se haya seleccionado un rol
	if $DialogoUsuario/VBoxContainer/ComboRol.selected == -1:
		mostrar_error("Debe seleccionar un rol")
		return false
	
	# Validar que se haya seleccionado una sucursal (excepto para clientes)
	var rol_seleccionado = $DialogoUsuario/VBoxContainer/ComboRol.get_item_id($DialogoUsuario/VBoxContainer/ComboRol.selected)
	if rol_seleccionado != ROLES_USUARIO.CLIENTE and $DialogoUsuario/VBoxContainer/ComboSucursal.selected == 0:
		mostrar_error("Debe seleccionar una sucursal")
		return false
	
	# Validar nombre de usuario único (solo en modo creación)
	if not modo_edicion:
		var nuevo_usuario = $DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges()
		for usuario in usuarios:
			if usuario["usuario"].to_lower() == nuevo_usuario.to_lower():
				mostrar_error("El nombre de usuario ya existe")
				return false
	
	return true

func guardar_usuario():
	if not validar_formulario_usuario():
		return
	
	mostrar_carga("Guardando usuario...")
	
	# Simular operación de guardado con delay
	await get_tree().create_timer(1.0).timeout
	
	if modo_edicion:
		# Modificar usuario existente
		modificar_usuario_existente()
	else:
		# Crear nuevo usuario
		crear_nuevo_usuario()
	
	ocultar_carga()
	$DialogoUsuario.hide()
	actualizar_tabla_usuarios()

func crear_nuevo_usuario():
	var nuevo_id = "USR" + str(usuarios.size() + 1).pad_zeros(3)
	
	var nuevo_usuario = {
		"id": nuevo_id,
		"nombre": $DialogoUsuario/VBoxContainer/InputNombre.text.strip_edges() + " " + $DialogoUsuario/VBoxContainer/InputApellido.text.strip_edges(),
		"usuario": $DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges(),
		"email": $DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges(),
		"contrasena": $DialogoUsuario/VBoxContainer/HBoxContainer/InputPassword.text.strip_edges(),
		"rol": $DialogoUsuario/VBoxContainer/ComboRol.get_item_id($DialogoUsuario/VBoxContainer/ComboRol.selected),
		"estado": ESTADOS_USUARIO.ACTIVO,
		"sucursal": $DialogoUsuario/VBoxContainer/ComboSucursal.get_item_text($DialogoUsuario/VBoxContainer/ComboSucursal.selected),
		"ultimo_acceso": "Nunca",
		"permisos": obtener_permisos_seleccionados(),
		"notificaciones": $DialogoUsuario/VBoxContainer/CheckBoxNotificaciones.button_pressed
	}
	
	usuarios.append(nuevo_usuario)
	usuario_creado.emit(nuevo_usuario)
	mostrar_exito("Usuario creado exitosamente")

func modificar_usuario_existente():
	if usuario_seleccionado.is_empty():
		return
	
	var index = usuarios.find(usuario_seleccionado)
	if index == -1:
		return
	
	# Actualizar datos del usuario
	var usuario_actualizado = usuario_seleccionado.duplicate()
	usuario_actualizado["nombre"] = $DialogoUsuario/VBoxContainer/InputNombre.text.strip_edges() + " " + $DialogoUsuario/VBoxContainer/InputApellido.text.strip_edges()
	usuario_actualizado["email"] = $DialogoUsuario/VBoxContainer/InputEmail.text.strip_edges()
	usuario_actualizado["usuario"] = $DialogoUsuario/VBoxContainer/InputUsuario.text.strip_edges()
	usuario_actualizado["rol"] = $DialogoUsuario/VBoxContainer/ComboRol.get_item_id($DialogoUsuario/VBoxContainer/ComboRol.selected)
	usuario_actualizado["sucursal"] = $DialogoUsuario/VBoxContainer/ComboSucursal.get_item_text($DialogoUsuario/VBoxContainer/ComboSucursal.selected)
	usuario_actualizado["permisos"] = obtener_permisos_seleccionados()
	
	usuarios[index] = usuario_actualizado
	usuario_modificado.emit(usuario_seleccionado["id"], usuario_actualizado)
	mostrar_exito("Usuario modificado exitosamente")

func solicitar_desactivar_usuario():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	if usuario_seleccionado["estado"] == ESTADOS_USUARIO.INACTIVO:
		mostrar_error("El usuario ya está inactivo")
		return
	
	$DialogoConfirmacion/MensajeConfirmacion.text = "¿Está seguro de que desea desactivar al usuario:\n" + usuario_seleccionado["nombre"] + "?"
	$DialogoConfirmacion.popup_centered()

func confirmar_operacion():
	$DialogoConfirmacion.hide()
	
	if usuario_seleccionado.is_empty():
		return
	
	var index = usuarios.find(usuario_seleccionado)
	if index == -1:
		return
	
	# Cambiar estado a INACTIVO
	usuarios[index]["estado"] = ESTADOS_USUARIO.INACTIVO
	usuario_desactivado.emit(usuario_seleccionado["id"])
	
	mostrar_exito("Usuario desactivado exitosamente")
	actualizar_tabla_usuarios()
	
	# Limpiar selección
	usuario_seleccionado = {}
	actualizar_botones_accion(false)

func cancelar_operacion():
	$DialogoConfirmacion.hide()

func abrir_dialogo_asignar_rol():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	$DialogoAsignarRol/LabelUsuario.text = "Usuario: " + usuario_seleccionado["nombre"]
	$DialogoAsignarRol.popup_centered()

func ver_trazas_usuario():
	if usuario_seleccionado.is_empty():
		mostrar_error("No hay usuario seleccionado")
		return
	
	mostrar_carga("Cargando trazas del usuario...")
	
	# Simular carga de trazas
	await get_tree().create_timer(1.5).timeout
	ocultar_carga()
	
	# En un sistema real, aquí se abriría una ventana con las trazas
	mostrar_exito("Trazas cargadas para: " + usuario_seleccionado["nombre"] + "\n(Esta funcionalidad se implementará en la ventana de trazas)")

func exportar_lista_usuarios():
	mostrar_carga("Exportando lista de usuarios...")
	
	# Simular exportación
	await get_tree().create_timer(2.0).timeout
	ocultar_carga()
	
	mostrar_exito("Lista de usuarios exportada exitosamente a CSV")

func actualizar_lista_usuarios():
	mostrar_carga("Actualizando lista de usuarios...")
	
	# Simular actualización
	await get_tree().create_timer(1.0).timeout
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
