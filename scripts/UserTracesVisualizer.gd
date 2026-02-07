extends Control
class_name UserTracesVisualizer

# Datos del usuario que se está visualizando
var usuario_id: int = 0
var datos_usuario: Dictionary = {}
var trazas_usuario: Array = []
var trazas_filtradas_actuales: Array = []

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
	
	# Si ya tenemos datos del usuario (pasados por set_usuario), los usamos
	if datos_usuario.is_empty() or not datos_usuario.has("id") or datos_usuario["id"] != usuario_id:
		# Cargar datos reales del usuario desde la BD
		var usuario_db = Bd.select_query("""
			SELECT id, username, email, nombre_completo as nombre, 
				   rol, estado_empleado as estado, departamento, 
				   ultimo_login, permisos, telefono, cargo
			FROM usuarios 
			WHERE id = ?
		""", [usuario_id])
		
		if usuario_db and usuario_db.size() > 0:
			datos_usuario = usuario_db[0]
		else:
			# Si no se encuentra, usar datos por defecto
			datos_usuario = {
				"id": usuario_id,
				"nombre": "Usuario no encontrado",
				"rol": "Desconocido",
				"estado": "No disponible",
				"ultimo_login": ""
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
	# Primero verificar si la tabla de trazas existe
	var tabla_existe = Bd.select_query("""
		SELECT name FROM sqlite_master 
		WHERE type='table' AND name='trazas_usuario'
	""")
	
	if tabla_existe and tabla_existe.size() > 0:
		# Tabla existe, consultar trazas del usuario
		var consulta = """
			SELECT fecha, accion, descripcion, modulo, ip, detalles
			FROM trazas_usuario 
			WHERE usuario_id = ?
			ORDER BY fecha DESC
			LIMIT 100
		"""
		
		var trazas_db = Bd.select_query(consulta, [usuario_id])
		
		if trazas_db:
			trazas_usuario.clear()
			for traza in trazas_db:
				trazas_usuario.append({
					"fecha": traza.get("fecha", ""),
					"accion": traza.get("accion", ""),
					"descripcion": traza.get("descripcion", ""),
					"modulo": traza.get("modulo", ""),
					"ip": traza.get("ip", ""),
					"detalles": traza.get("detalles", "")
				})
	
	# Si no hay trazas en la BD, usar datos de ejemplo (para desarrollo)
	if trazas_usuario.size() == 0:
		trazas_usuario = [
			{
				"fecha": "2024-02-15 14:30:00",
				"accion": "LOGIN",
				"descripcion": "Inicio de sesión exitoso",
				"modulo": "Autenticación",
				"ip": "192.168.1.100",
				"detalles": "Navegador: Chrome, Sistema: Windows 10"
			},
			{
				"fecha": "2024-02-15 14:35:00",
				"accion": "CONSULTA",
				"descripcion": "Consulta de usuarios del sistema",
				"modulo": "Administración de Usuarios",
				"ip": "192.168.1.100",
				"detalles": "Filtros aplicados: Estado=Activo"
			},
			{
				"fecha": "2024-02-15 14:40:00",
				"accion": "MODIFICACION",
				"descripcion": "Modificación de permisos del usuario 'jperez'",
				"modulo": "Administración de Usuarios",
				"ip": "192.168.1.100",
				"detalles": "Permisos añadidos: VER_TRAZAS, ADMINISTRAR_USUARIOS"
			},
			{
				"fecha": "2024-02-14 10:15:00",
				"accion": "CREACION",
				"descripcion": "Creación de nuevo usuario 'mrodriguez'",
				"modulo": "Administración de Usuarios",
				"ip": "192.168.1.101",
				"detalles": "Rol: Operador, Sucursal: La Habana"
			},
			{
				"fecha": "2024-02-13 09:20:00",
				"accion": "EXPORTACION",
				"descripcion": "Exportación de lista de usuarios a CSV",
				"modulo": "Administración de Usuarios",
				"ip": "192.168.1.102",
				"detalles": "Archivo: usuarios_2024-02-13.csv, Registros: 45"
			},
			{
				"fecha": "2024-02-10 16:45:00",
				"accion": "LOGIN",
				"descripcion": "Inicio de sesión exitoso",
				"modulo": "Autenticación",
				"ip": "192.168.1.103",
				"detalles": "Navegador: Firefox, Sistema: Linux"
			},
			{
				"fecha": "2024-02-08 11:20:00",
				"accion": "LOGOUT",
				"descripcion": "Cierre de sesión",
				"modulo": "Autenticación",
				"ip": "192.168.1.100",
				"detalles": "Sesión de 2 horas 15 minutos"
			},
			{
				"fecha": "2024-02-05 09:10:00",
				"accion": "ELIMINACION",
				"descripcion": "Eliminación de usuario inactivo",
				"modulo": "Administración de Usuarios",
				"ip": "192.168.1.104",
				"detalles": "Usuario eliminado: aprodriguez (ID: 45)"
			}
		]
	
	# Ordenar por fecha (más reciente primero)
	trazas_usuario.sort_custom(func(a, b): return a.fecha > b.fecha)
	
	# Inicializar trazas filtradas con todas las trazas
	trazas_filtradas_actuales = trazas_usuario.duplicate()
	
	# Mostrar las trazas
	mostrar_trazas(trazas_filtradas_actuales)
	
	# Ocultar mensaje de carga
	$MensajeCarga.visible = false
	
	# Actualizar contador
	actualizar_contador_trazas()

func actualizar_contador_trazas():
	var total = trazas_usuario.size()
	var mostrando = trazas_filtradas_actuales.size()
	$ContenedorPrincipal/ContenedorTrazas.text = "Mostrando %d de %d trazas" % [mostrando, total]
	
func mostrar_trazas(trazas: Array):
	var lista_trazas = $ContenedorPrincipal/ContenedorTrazas/ScrollTrazas/ListaTrazas
	
	# Limpiar lista actual
	for hijo in lista_trazas.get_children():
		hijo.queue_free()
	
	# Actualizar trazas filtradas actuales
	trazas_filtradas_actuales = trazas.duplicate()
	
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
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER  # CORREGIDO: Cambiado de HORIZONTAL_ALIGNMENT_LEFT
		lista_trazas.add_child(label)
	
	# Actualizar contador
	actualizar_contador_trazas()

func crear_item_traza(traza: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 100)
	
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
	estilo.content_margin_left = 12.0
	estilo.content_margin_top = 12.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_bottom = 12.0
	
	panel.add_theme_stylebox_override("panel", estilo)
	
	# Contenedor interno
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Ícono de acción
	var icono = Label.new()
	icono.text = obtener_icono_accion(traza.get("accion", ""))
	icono.custom_minimum_size = Vector2(50, 0)
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icono.add_theme_font_size_override("font_size", 24)
	hbox.add_child(icono)
	
	# Separador
	var separator = VSeparator.new()
	separator.custom_minimum_size = Vector2(2, 0)
	hbox.add_child(separator)
	
	# Información de la traza
	var vbox_info = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Fecha y acción
	var hbox_header = HBoxContainer.new()
	
	var label_fecha = Label.new()
	label_fecha.text = formatear_fecha(traza.get("fecha", ""))
	label_fecha.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
	label_fecha.add_theme_font_size_override("font_size", 13)
	hbox_header.add_child(label_fecha)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(spacer)
	
	var label_accion = Label.new()
	label_accion.text = traza.get("accion", "Desconocido")
	label_accion.add_theme_color_override("font_color", obtener_color_accion(traza.get("accion", "")))
	label_accion.add_theme_font_size_override("font_size", 14)
	label_accion.add_theme_font_override("font", load("res://fuentes/fuente_bold.tres"))
	hbox_header.add_child(label_accion)
	
	vbox_info.add_child(hbox_header)
	
	# Descripción
	var label_desc = Label.new()
	label_desc.text = traza.get("descripcion", "Sin descripción")
	label_desc.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	label_desc.add_theme_font_size_override("font_size", 14)
	label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_info.add_child(label_desc)
	
	# Detalles adicionales
	var detalles = traza.get("detalles", "")
	if detalles and detalles != "":
		var label_detalles = Label.new()
		label_detalles.text = "Detalles: " + detalles
		label_detalles.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		label_detalles.add_theme_font_size_override("font_size", 12)
		label_detalles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox_info.add_child(label_detalles)
	
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
		"LOGIN": return "🔐"
		"LOGOUT": return "🚪"
		"CREACION": return "➕"
		"MODIFICACION": return "✏️"
		"ELIMINACION": return "🗑️"
		"CONSULTA": return "🔍"
		"EXPORTACION": return "📤"
		_: return "📝"

func obtener_color_accion(accion: String) -> Color:
	match accion:
		"LOGIN": return Color(0.2, 0.6, 0.2)  # Verde
		"LOGOUT": return Color(0.6, 0.2, 0.2)  # Rojo oscuro
		"CREACION": return Color(0.2, 0.4, 0.8)         # Azul
		"MODIFICACION": return Color(0.8, 0.6, 0.2)     # Naranja
		"ELIMINACION": return Color(0.8, 0.2, 0.2)      # Rojo
		"CONSULTA": return Color(0.4, 0.2, 0.8)         # Púrpura
		"EXPORTACION": return Color(0.2, 0.8, 0.8)      # Cyan
		_: return Color(0.5, 0.5, 0.5)                  # Gris

func formatear_fecha(fecha_str: String) -> String:
	if fecha_str == "":
		return "Fecha desconocida"
	
	# Intentar parsear la fecha en formato "YYYY-MM-DD HH:MM:SS"
	var partes = fecha_str.split(" ")
	if partes.size() >= 2:
		var fecha_parts = partes[0].split("-")
		var tiempo_parts = partes[1].split(":")
		
		if fecha_parts.size() >= 3 and tiempo_parts.size() >= 2:
			# Formatear como "DD/MM/YYYY HH:MM"
			return "%s/%s/%s %s:%s" % [fecha_parts[2], fecha_parts[1], fecha_parts[0], tiempo_parts[0], tiempo_parts[1]]
	
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
	
	# Obtener fecha actual
	var ahora = Time.get_datetime_dict_from_system()
	var fecha_limite = calcular_fecha_limite_real(ahora, periodo_id)
	
	# Filtrar las trazas
	return trazas.filter(func(t):
		var fecha_traza = t.get("fecha", "")
		if fecha_traza == "":
			return false
		
		# Convertir string a diccionario de fecha
		var dict_traza = convertir_fecha_string_a_dict(fecha_traza)
		if dict_traza.is_empty():
			return false
		
		# Comparar fechas
		return es_fecha_mas_reciente_o_igual_real(dict_traza, fecha_limite)
	)

func calcular_fecha_limite_real(fecha_actual: Dictionary, periodo_id: int) -> Dictionary:
	var fecha_limite = fecha_actual.duplicate()
	var dias_atras = 0
	
	match periodo_id:
		PERIODO_FILTRO.ULTIMOS_7_DIAS: dias_atras = 7
		PERIODO_FILTRO.ULTIMOS_30_DIAS: dias_atras = 30
		PERIODO_FILTRO.ULTIMOS_90_DIAS: dias_atras = 90
	
	# Restar días
	fecha_limite["day"] -= dias_atras
	
	# Ajustar si el día es menor que 1
	while fecha_limite["day"] < 1:
		fecha_limite["month"] -= 1
		if fecha_limite["month"] < 1:
			fecha_limite["month"] = 12
			fecha_limite["year"] -= 1
		
		# Obtener días del mes anterior
		var dias_en_mes = obtener_dias_en_mes_real(fecha_limite["month"], fecha_limite["year"])
		fecha_limite["day"] += dias_en_mes
	
	return fecha_limite

func obtener_dias_en_mes_real(mes: int, anio: int) -> int:
	# Lista de días por mes
	var dias_por_mes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Ajustar febrero para años bisiestos
	if mes == 2:
		if (anio % 400 == 0) or (anio % 4 == 0 and anio % 100 != 0):
			return 29
	
	return dias_por_mes[mes - 1]

func convertir_fecha_string_a_dict(fecha_str: String) -> Dictionary:
	# Convertir formato "YYYY-MM-DD HH:MM:SS" a diccionario
	if fecha_str == "":
		return {}
	
	var partes = fecha_str.split(" ")
	if partes.size() < 2:
		return {}
	
	var fecha_parts = partes[0].split("-")
	var tiempo_parts = partes[1].split(":")
	
	if fecha_parts.size() < 3:
		return {}
	
	return {
		"year": int(fecha_parts[0]),
		"month": int(fecha_parts[1]),
		"day": int(fecha_parts[2]),
		"hour": int(tiempo_parts[0]) if tiempo_parts.size() > 0 else 0,
		"minute": int(tiempo_parts[1]) if tiempo_parts.size() > 1 else 0,
		"second": int(tiempo_parts[2]) if tiempo_parts.size() > 2 else 0
	}

func es_fecha_mas_reciente_o_igual_real(fecha1: Dictionary, fecha2: Dictionary) -> bool:
	# Comparar año
	if fecha1["year"] != fecha2["year"]:
		return fecha1["year"] > fecha2["year"]
	
	# Comparar mes
	if fecha1["month"] != fecha2["month"]:
		return fecha1["month"] > fecha2["month"]
	
	# Comparar día
	if fecha1["day"] != fecha2["day"]:
		return fecha1["day"] > fecha2["day"]
	
	# Si es el mismo día, comparar hora, minuto, segundo
	var hora1 = fecha1.get("hour", 0)
	var min1 = fecha1.get("minute", 0)
	var sec1 = fecha1.get("second", 0)
	
	var hora2 = fecha2.get("hour", 0)
	var min2 = fecha2.get("minute", 0)
	var sec2 = fecha2.get("second", 0)
	
	if hora1 != hora2:
		return hora1 > hora2
	if min1 != min2:
		return min1 > min2
	return sec1 >= sec2

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
	var csv = "Fecha,Acción,Descripción,Módulo,IP,Detalles\n"
	for traza in trazas_actuales:
		csv += "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" % [
			traza.get("fecha", ""),
			traza.get("accion", ""),
			traza.get("descripcion", ""),
			traza.get("modulo", ""),
			traza.get("ip", ""),
			traza.get("detalles", "").replace("\"", "'")
		]
	
	# Generar nombre de archivo con fecha y hora actual
	var fecha_actual = Time.get_datetime_string_from_system()
	fecha_actual = fecha_actual.replace(":", "-").replace(" ", "_")
	var nombre_archivo = "trazas_usuario_%d_%s.csv" % [usuario_id, fecha_actual]
	var ruta = "user://" + nombre_archivo
	
	var archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if archivo:
		archivo.store_string(csv)
		archivo.close()
		
		# Mostrar mensaje de éxito
		var ruta_completa = ProjectSettings.globalize_path(ruta)
		$MensajeExito.dialog_text = "Trazas exportadas exitosamente:\n%s" % nombre_archivo
		$MensajeExito.popup_centered()
		
		# Registrar en trazas que se exportó
		registrar_traza_exportacion()
	else:
		$MensajeError.dialog_text = "Error al exportar las trazas. Verifique permisos de escritura."
		$MensajeError.popup_centered()

func registrar_traza_exportacion():
	# Registrar esta acción como una traza en el sistema
	var datos_usuario_actual = null
	var ip_usuario = "Desconocida"
	
	# Intentar obtener el singleton Sistema si existe
	# CORREGIDO: Verificar si el singleton Sistema existe antes de usarlo
	if Engine.has_singleton("Sistema"):
		var Sistema = Engine.get_singleton("Sistema")
		datos_usuario_actual = Sistema.get_usuario_actual() if Sistema.has_method("get_usuario_actual") else null
		ip_usuario = Sistema.get_ip_usuario() if Sistema.has_method("get_ip_usuario") else "Desconocida"
	
	if datos_usuario_actual:
		var datos_traza = {
			"usuario_id": datos_usuario_actual.get("id", 0),
			"accion": "EXPORTACION",
			"descripcion": "Exportación de trazas del usuario ID: " + str(usuario_id),
			"modulo": "Visualización de Trazas",
			"ip": ip_usuario,
			"detalles": "Total de trazas exportadas: " + str(trazas_filtradas_actuales.size())
		}
		
		# Intentar insertar en la base de datos si la tabla existe
		var tabla_existe = Bd.select_query("""
			SELECT name FROM sqlite_master 
			WHERE type='table' AND name='trazas_usuario'
		""")
		
		if tabla_existe and tabla_existe.size() > 0:
			Bd.insert("trazas_usuario", datos_traza)

func obtener_trazas_actuales() -> Array:
	# Obtener las trazas que se están mostrando actualmente (filtradas)
	return trazas_filtradas_actuales

func volver_a_administracion():
	# Cambiar a la escena de AdministrarUsuarios
	get_tree().change_scene_to_file("res://escenas/AdministrarUsuarios.tscn")

# Función para establecer el usuario a visualizar
func set_usuario(id_usuario: int, datos: Dictionary = {}):
	usuario_id = id_usuario
	if not datos.is_empty():
		datos_usuario = datos
		# Actualizar la información del usuario inmediatamente si ya tenemos los datos
		if is_inside_tree():
			actualizar_info_usuario()

# Conectar el diálogo de confirmación
func _on_dialogo_confirmacion_confirmed():
	exportar_trazas()

# Función para limpiar filtros
func _on_btn_limpiar_filtros_pressed():
	# Restablecer combos a valores por defecto
	$ContenedorPrincipal/PanelFiltros/Filtros/ComboTipoAccion.select(0)
	$ContenedorPrincipal/PanelFiltros/Filtros/ComboPeriodo.select(1)
	
	# Mostrar todas las trazas
	mostrar_trazas(trazas_usuario.duplicate())
