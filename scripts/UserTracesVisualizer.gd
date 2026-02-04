extends Control
class_name UserTracesVisualizer

# Datos del usuario que se está visualizando
var usuario_id: int = 0
var datos_usuario: Dictionary = {}
var trazas_usuario: Array = []

# Tipos de acciones para filtrar
enum TIPO_ACCION {
	TODAS = 0,
	LOGIN = 1,
	LOGOUT = 2,
	CREACION = 3,
	MODIFICACION = 4,
	ELIMINACION = 5,
	CONSULTA = 6,
	EXPORTACION = 7
}

# Períodos para filtrar
enum PERIODO_FILTRO {
	ULTIMOS_7_DIAS = 0,
	ULTIMOS_30_DIAS = 1,
	ULTIMOS_90_DIAS = 2,
	TODO_EL_TIEMPO = 3
}

func _ready():
	# Aplicar estilos iniciales
	aplicar_estilos()
	
	# Conectar señales
	$ContenedorPrincipal/PanelControles/BtnVolver.pressed.connect(volver_a_administracion)
	$ContenedorPrincipal/PanelFiltros/Filtros/BtnAplicarFiltro.pressed.connect(aplicar_filtros)
	$ContenedorPrincipal/PanelFiltros/Filtros/BtnExportar.pressed.connect(solicitar_exportacion)
	
	# Conectar señal del diálogo de confirmación
	$DialogoConfirmacion.confirmed.connect(_on_dialogo_confirmacion_confirmed)
	
	# Configurar combos de filtro
	inicializar_filtros()
	
	# Cargar datos del usuario y sus trazas
	cargar_datos_usuario()

func aplicar_estilos():
	# Configurar estilos de los ítems de traza
	var estilo_item = StyleBoxFlat.new()
	estilo_item.bg_color = Color(0.95, 0.96, 0.98, 1)
	estilo_item.border_width_left = 1
	estilo_item.border_width_top = 1
	estilo_item.border_width_right = 1
	estilo_item.border_width_bottom = 1
	estilo_item.border_color = Color(0.8, 0.85, 0.9, 1)
	estilo_item.corner_radius_top_left = 8
	estilo_item.corner_radius_top_right = 8
	estilo_item.corner_radius_bottom_right = 8
	estilo_item.corner_radius_bottom_left = 8
	estilo_item.content_margin_left = 10.0
	estilo_item.content_margin_top = 10.0
	estilo_item.content_margin_right = 10.0
	estilo_item.content_margin_bottom = 10.0

func inicializar_filtros():
	var combo_accion = $ContenedorPrincipal/PanelFiltros/Filtros/ComboTipoAccion
	combo_accion.clear()
	combo_accion.add_item("Todas las acciones", TIPO_ACCION.TODAS)
	combo_accion.add_item("Login", TIPO_ACCION.LOGIN)
	combo_accion.add_item("Logout", TIPO_ACCION.LOGOUT)
	combo_accion.add_item("Creación", TIPO_ACCION.CREACION)
	combo_accion.add_item("Modificación", TIPO_ACCION.MODIFICACION)
	combo_accion.add_item("Eliminación", TIPO_ACCION.ELIMINACION)
	combo_accion.add_item("Consulta", TIPO_ACCION.CONSULTA)
	combo_accion.add_item("Exportación", TIPO_ACCION.EXPORTACION)
	
	var combo_periodo = $ContenedorPrincipal/PanelFiltros/Filtros/ComboPeriodo
	combo_periodo.clear()
	combo_periodo.add_item("Últimos 7 días", PERIODO_FILTRO.ULTIMOS_7_DIAS)
	combo_periodo.add_item("Últimos 30 días", PERIODO_FILTRO.ULTIMOS_30_DIAS)
	combo_periodo.add_item("Últimos 90 días", PERIODO_FILTRO.ULTIMOS_90_DIAS)
	combo_periodo.add_item("Todo el tiempo", PERIODO_FILTRO.TODO_EL_TIEMPO)
	
	# Seleccionar valores por defecto
	combo_accion.select(0)
	combo_periodo.select(1)  # Últimos 30 días

func cargar_datos_usuario():
	# Mostrar mensaje de carga
	$MensajeCarga.visible = true
	
	# Simular carga de datos (en un sistema real, esto vendría de la BD)
	await get_tree().create_timer(0.5).timeout
	
	# Aquí deberías cargar los datos reales del usuario desde la BD
	# Por ahora, usamos datos de ejemplo
	datos_usuario = {
		"id": usuario_id,
		"nombre": "Usuario de Prueba",
		"rol": "Administrador",
		"estado": "Activo",
		"ultimo_login": "2024-02-15 14:30:00"
	}
	
	# Actualizar la información del usuario
	actualizar_info_usuario()
	
	# Cargar las trazas
	cargar_trazas_usuario()

func actualizar_info_usuario():
	$ContenedorPrincipal/PanelInfoUsuario/InfoUsuario/ValorNombre.text = datos_usuario.get("nombre", "Desconocido")
	$ContenedorPrincipal/PanelInfoUsuario/InfoUsuario/ValorRol.text = datos_usuario.get("rol", "Sin rol")
	$ContenedorPrincipal/PanelInfoUsuario/InfoUsuario/ValorEstado.text = datos_usuario.get("estado", "Desconocido")
	
	var ultimo_login = datos_usuario.get("ultimo_login", "")
	if ultimo_login:
		$ContenedorPrincipal/PanelInfoUsuario/InfoUsuario/ValorUltimoLogin.text = formatear_fecha(ultimo_login)
	else:
		$ContenedorPrincipal/PanelInfoUsuario/InfoUsuario/ValorUltimoLogin.text = "Nunca"

func cargar_trazas_usuario():
	# Obtener trazas del usuario desde la base de datos
	# Por ahora, usamos datos de ejemplo
	trazas_usuario = [
		{
			"fecha": "2024-02-15 14:30:00",
			"accion": "LOGIN",
			"descripcion": "Inicio de sesión exitoso",
			"modulo": "Autenticación",
			"ip": "192.168.1.100"
		},
		{
			"fecha": "2024-02-15 14:35:00",
			"accion": "CONSULTA",
			"descripcion": "Consulta de usuarios del sistema",
			"modulo": "Administración de Usuarios",
			"ip": "192.168.1.100"
		},
		{
			"fecha": "2024-02-15 14:40:00",
			"accion": "MODIFICACION",
			"descripcion": "Modificación de permisos del usuario 'jperez'",
			"modulo": "Administración de Usuarios",
			"ip": "192.168.1.100"
		},
		{
			"fecha": "2024-02-14 10:15:00",
			"accion": "CREACION",
			"descripcion": "Creación de nuevo usuario 'mrodriguez'",
			"modulo": "Administración de Usuarios",
			"ip": "192.168.1.101"
		},
		{
			"fecha": "2024-02-13 09:20:00",
			"accion": "EXPORTACION",
			"descripcion": "Exportación de lista de usuarios a CSV",
			"modulo": "Administración de Usuarios",
			"ip": "192.168.1.102"
		},
		{
			"fecha": "2024-02-10 16:45:00",
			"accion": "LOGIN",
			"descripcion": "Inicio de sesión exitoso",
			"modulo": "Autenticación",
			"ip": "192.168.1.103"
		}
	]
	
	# Ordenar por fecha (más reciente primero)
	trazas_usuario.sort_custom(func(a, b): return a.fecha > b.fecha)
	
	# Mostrar las trazas
	mostrar_trazas(trazas_usuario)
	
	# Ocultar mensaje de carga
	$MensajeCarga.visible = false

func mostrar_trazas(trazas: Array):
	var lista_trazas = $ContenedorPrincipal/ContenedorTrazas/ScrollTrazas/ListaTrazas
	
	# Limpiar lista actual
	for hijo in lista_trazas.get_children():
		hijo.queue_free()
	
	# Agregar nuevas trazas
	for traza in trazas:
		var item = crear_item_traza(traza)
		lista_trazas.add_child(item)
	
	# Si no hay trazas, mostrar mensaje
	if trazas.size() == 0:
		var label = Label.new()
		label.text = "No se encontraron trazas para este usuario en el período seleccionado."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		lista_trazas.add_child(label)

func crear_item_traza(traza: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	# Estilo del panel
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.95, 0.96, 0.98, 1)
	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1
	estilo.border_color = Color(0.8, 0.85, 0.9, 1)
	estilo.corner_radius_top_left = 8
	estilo.corner_radius_top_right = 8
	estilo.corner_radius_bottom_right = 8
	estilo.corner_radius_bottom_left = 8
	estilo.content_margin_left = 10.0
	estilo.content_margin_top = 10.0
	estilo.content_margin_right = 10.0
	estilo.content_margin_bottom = 10.0
	
	panel.add_theme_stylebox_override("panel", estilo)
	
	# Contenedor interno
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Ícono de acción
	var icono = Label.new()
	icono.text = obtener_icono_accion(traza.get("accion", ""))
	icono.custom_minimum_size = Vector2(40, 0)
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icono)
	
	# Información de la traza
	var vbox_info = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Fecha y acción
	var hbox_header = HBoxContainer.new()
	
	var label_fecha = Label.new()
	label_fecha.text = formatear_fecha(traza.get("fecha", ""))
	label_fecha.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	hbox_header.add_child(label_fecha)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(spacer)
	
	var label_accion = Label.new()
	label_accion.text = traza.get("accion", "Desconocido")
	label_accion.add_theme_color_override("font_color", obtener_color_accion(traza.get("accion", "")))
	label_accion.add_theme_font_size_override("font_size", 14)
	hbox_header.add_child(label_accion)
	
	vbox_info.add_child(hbox_header)
	
	# Descripción
	var label_desc = Label.new()
	label_desc.text = traza.get("descripcion", "Sin descripción")
	label_desc.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	vbox_info.add_child(label_desc)
	
	# Módulo e IP
	var hbox_footer = HBoxContainer.new()
	
	var label_modulo = Label.new()
	label_modulo.text = "Módulo: " + traza.get("modulo", "Desconocido")
	label_modulo.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	label_modulo.add_theme_font_size_override("font_size", 12)
	hbox_footer.add_child(label_modulo)
	
	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_footer.add_child(spacer2)
	
	var label_ip = Label.new()
	label_ip.text = "IP: " + traza.get("ip", "Desconocida")
	label_ip.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	label_ip.add_theme_font_size_override("font_size", 12)
	hbox_footer.add_child(label_ip)
	
	vbox_info.add_child(hbox_footer)
	
	hbox.add_child(vbox_info)
	
	# Añadir todo al panel
	panel.add_child(hbox)
	
	return panel

func obtener_icono_accion(accion: String) -> String:
	match accion:
		"LOGIN", "LOGOUT": return "🔐"
		"CREACION": return "➕"
		"MODIFICACION": return "✏️"
		"ELIMINACION": return "🗑️"
		"CONSULTA": return "🔍"
		"EXPORTACION": return "📤"
		_: return "📝"

func obtener_color_accion(accion: String) -> Color:
	match accion:
		"LOGIN", "LOGOUT": return Color(0.2, 0.6, 0.2)  # Verde
		"CREACION": return Color(0.2, 0.4, 0.8)         # Azul
		"MODIFICACION": return Color(0.8, 0.6, 0.2)     # Naranja
		"ELIMINACION": return Color(0.8, 0.2, 0.2)      # Rojo
		"CONSULTA": return Color(0.4, 0.2, 0.8)         # Púrpura
		"EXPORTACION": return Color(0.2, 0.8, 0.8)      # Cyan
		_: return Color(0.5, 0.5, 0.5)                  # Gris

func formatear_fecha(fecha_str: String) -> String:
	if fecha_str == "":
		return "Fecha desconocida"
	
	# Intentar parsear la fecha
	# En un sistema real, usarías Time o DateTime
	var partes = fecha_str.split(" ")
	if partes.size() > 0:
		return partes[0] + " " + (partes[1] if partes.size() > 1 else "")
	
	return fecha_str

func aplicar_filtros():
	var tipo_accion = $ContenedorPrincipal/PanelFiltros/Filtros/ComboTipoAccion.get_selected_id()
	var periodo = $ContenedorPrincipal/PanelFiltros/Filtros/ComboPeriodo.get_selected_id()
	
	# Obtener las trazas del usuario
	var trazas_filtradas = trazas_usuario.duplicate()
	
	# Filtrar por período (esto es básico, en un sistema real usarías Time)
	trazas_filtradas = filtrar_por_periodo(trazas_filtradas, periodo)
	
	# Filtrar por tipo de acción
	if tipo_accion != TIPO_ACCION.TODAS:
		trazas_filtradas = filtrar_por_accion(trazas_filtradas, tipo_accion)
	
	# Mostrar trazas filtradas
	mostrar_trazas(trazas_filtradas)

func filtrar_por_accion(trazas: Array, tipo_accion_id: int) -> Array:
	var tipo_accion_str = ""
	match tipo_accion_id:
		TIPO_ACCION.LOGIN: tipo_accion_str = "LOGIN"
		TIPO_ACCION.LOGOUT: tipo_accion_str = "LOGOUT"
		TIPO_ACCION.CREACION: tipo_accion_str = "CREACION"
		TIPO_ACCION.MODIFICACION: tipo_accion_str = "MODIFICACION"
		TIPO_ACCION.ELIMINACION: tipo_accion_str = "ELIMINACION"
		TIPO_ACCION.CONSULTA: tipo_accion_str = "CONSULTA"
		TIPO_ACCION.EXPORTACION: tipo_accion_str = "EXPORTACION"
	
	if tipo_accion_str == "":
		return trazas
	
	# Filtrar las trazas
	return trazas.filter(func(t): 
		return t.get("accion", "") == tipo_accion_str
	)

func filtrar_por_periodo(trazas: Array, periodo_id: int) -> Array:
	if periodo_id == PERIODO_FILTRO.TODO_EL_TIEMPO:
		return trazas
	
	# Calcular la fecha de inicio según el período
	var dias_atras = 0
	match periodo_id:
		PERIODO_FILTRO.ULTIMOS_7_DIAS: dias_atras = 7
		PERIODO_FILTRO.ULTIMOS_30_DIAS: dias_atras = 30
		PERIODO_FILTRO.ULTIMOS_90_DIAS: dias_atras = 90
	
	# Obtener la fecha actual
	var ahora = Time.get_date_string_from_system() + " " + Time.get_time_string_from_system()
	var fecha_limite = calcular_fecha_limite(ahora, dias_atras)
	
	# Filtrar las trazas
	return trazas.filter(func(t):
		var fecha_traza = t.get("fecha", "")
		if fecha_traza == "":
			return false
		
		# Comparar fechas (esto es simplificado, en un sistema real usarías Time)
		return es_fecha_mas_reciente_o_igual(fecha_traza, fecha_limite)
	)

func calcular_fecha_limite(fecha_actual: String, dias_atras: int) -> String:
	# Esta es una implementación simplificada
	# En un sistema real, usarías Time o DateTime para calcular esto correctamente
	
	# Para el ejemplo, simplemente restamos días de la fecha
	# Nota: Esto no maneja cambios de mes/año correctamente
	var partes = fecha_actual.split(" ")
	if partes.size() < 2:
		return ""
	
	var fecha_parts = partes[0].split("-")
	if fecha_parts.size() < 3:
		return ""
	
	var dia = int(fecha_parts[2])
	dia -= dias_atras
	
	# Ajustar si el día es menor que 1
	while dia < 1:
		dia += 30  # Simplificación, deberías manejar meses reales
	
	# Crear nueva fecha string
	return "%s-%02d-%02d %s" % [fecha_parts[0], fecha_parts[1], dia, partes[1]]

func es_fecha_mas_reciente_o_igual(fecha1: String, fecha2: String) -> bool:
	# Comparación simplificada de fechas
	# En un sistema real, convertirías a timestamp y compararías
	return fecha1 >= fecha2

func solicitar_exportacion():
	$DialogoConfirmacion.dialog_text = "¿Exportar las trazas filtradas a archivo CSV?"
	$DialogoConfirmacion.popup_centered()

func exportar_trazas():
	var trazas_actuales = obtener_trazas_actuales()
	
	if trazas_actuales.size() == 0:
		$MensajeError.dialog_text = "No hay trazas para exportar."
		$MensajeError.popup_centered()
		return
	
	# Crear contenido CSV
	var csv = "Fecha,Acción,Descripción,Módulo,IP\n"
	for traza in trazas_actuales:
		csv += "%s,%s,%s,%s,%s\n" % [
			traza.get("fecha", ""),
			traza.get("accion", ""),
			traza.get("descripcion", ""),
			traza.get("modulo", ""),
			traza.get("ip", "")
		]
	
	# Guardar archivo
	var nombre_archivo = "trazas_usuario_%d_%d.csv" % [usuario_id, Time.get_unix_time_from_system()]
	var ruta = "user://" + nombre_archivo
	
	var archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if archivo:
		archivo.store_string(csv)
		archivo.close()
		
		# Mostrar mensaje de éxito
		var ruta_completa = ProjectSettings.globalize_path(ruta)
		$MensajeExito.dialog_text = "Trazas exportadas exitosamente:\n%s" % ruta_completa
		$MensajeExito.popup_centered()
	else:
		$MensajeError.dialog_text = "Error al exportar las trazas."
		$MensajeError.popup_centered()

func obtener_trazas_actuales() -> Array:
	# Obtener las trazas que se están mostrando actualmente
	# (en un sistema real, esto dependería de los filtros aplicados)
	return trazas_usuario

func volver_a_administracion():
	get_tree().change_scene_to_file("res://escenas/AdministrarUsuarios.tscn")

# Función para establecer el usuario a visualizar
func set_usuario(id_usuario: int, datos: Dictionary = {}):
	usuario_id = id_usuario
	if not datos.is_empty():
		datos_usuario = datos
		actualizar_info_usuario()

# Conectar el diálogo de confirmación
func _on_dialogo_confirmacion_confirmed():
	exportar_trazas()

# También necesitas conectar esto en _ready()
# $DialogoConfirmacion.confirmed.connect(_on_dialogo_confirmacion_confirmed)
