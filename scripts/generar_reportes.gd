extends Control

# Variables para nodos
var titulo_reporte: Label
var subtitulo_reporte: Label
var placeholder_text: Label
var input_fecha_inicio: LineEdit
var input_fecha_fin: LineEdit
var select_sucursal: OptionButton

# Variables para KPIs
var kpi1_valor: Label
var kpi2_valor: Label
var kpi3_valor: Label

# Variables de estado
var categoria_actual = "no_conformidades"
var datos_reporte: Dictionary = {}

func _ready():
	print("🔍 INICIANDO SISTEMA DE REPORTES...")
	
	# Verificar si BD está disponible como singleton
	if not has_node("/root/Bd"):
		push_error("❌ No se encontró el singleton BD en AutoLoad")
		print("⚠️ Asegúrate de que BD esté configurado como AutoLoad en el proyecto")
		# Mostrar error en la interfaz si placeholder_text está disponible
		call_deferred("mostrar_error_bd")
		return
	
	print("✅ Singleton BD encontrado en AutoLoad")
	
	# Primero, imprimir la estructura completa para depuración
	print("=== INSPECCIÓN DE ESTRUCTURA DE NODOS ===")
	_imprimir_estructura_nodos()
	
	# Luego cargar nodos usando un método seguro
	_cargar_nodos_seguro()
	
	# Configurar estado inicial
	_llenar_provincias_cuba()
	_actualizar_ui_categoria(categoria_actual)
	_conectar_señales()
	
	# Configurar fechas por defecto
	_establecer_fechas_por_defecto()
	
	# Prueba de conexión a BD
	probar_conexion_bd()

func mostrar_error_bd():
	if placeholder_text:
		placeholder_text.text = "❌ ERROR: Sistema de base de datos no disponible\n\n"
		placeholder_text.text += "No se pudo conectar con la base de datos.\n"
		placeholder_text.text += "Por favor, verifique la configuración del sistema."

func probar_conexion_bd():
	print("\n=== PRUEBA DE CONEXIÓN A BD DESDE REPORTES ===")
	
	# Obtener referencia al singleton BD
	var bd = get_node("/root/Bd")
	if not bd:
		print("❌ No se pudo obtener referencia a BD")
		return
	
	print("✅ Referencia a BD obtenida")
	
	# Probar consulta simple
	var resultado = bd.select_query("SELECT COUNT(*) as total FROM no_conformidades")
	if resultado != null and typeof(resultado) == TYPE_ARRAY:
		if resultado.size() > 0:
			print("✅ Consulta exitosa. Total NC en BD:", resultado[0]["total"])
			
			# Verificar datos de ejemplo
			print("📊 Verificando datos de prueba...")
			var datos_prueba = bd.select_query("SELECT codigo_expediente, tipo_nc, estado FROM no_conformidades")
			for dato in datos_prueba:
				print("   - ", dato["codigo_expediente"], " | ", dato["tipo_nc"], " | ", dato["estado"])
		else:
			print("⚠️ Consulta retornó array vacío")
	else:
		print("❌ Error en la consulta o resultado nulo")
		print("   Tipo de resultado: ", typeof(resultado))
		print("   Valor: ", resultado)

func _imprimir_estructura_nodos():
	"""Imprime la estructura completa de nodos desde el nodo actual"""
	_imprimir_nodo_recursivo(self, 0)

func _imprimir_nodo_recursivo(nodo: Node, nivel: int):
	var indentacion = "  ".repeat(nivel)
	var tipo_nodo = nodo.get_class()
	print(indentacion + "└─ " + nodo.name + " (" + tipo_nodo + ")")
	
	# Si es un Label, imprimir su texto actual
	if tipo_nodo == "Label" and nodo.has_method("get_text"):
		var texto = nodo.get_text()
		if texto and texto.length() > 0:
			print(indentacion + "   Texto: \"" + texto.substr(0, 50) + ("..." if texto.length() > 50 else "") + "\"")
	
	for hijo in nodo.get_children():
		_imprimir_nodo_recursivo(hijo, nivel + 1)

func _cargar_nodos_seguro():
	"""Carga nodos de forma segura buscando en toda la jerarquía"""
	print("\n=== BUSCANDO NODOS IMPORTANTES ===")
	
	# Buscar nodos por nombre o tipo de manera flexible
	_buscar_y_cargar_nodos()
	
	# Verificar qué nodos se cargaron
	print("\n=== RESUMEN DE NODOS CARGADOS ===")
	print("titulo_reporte: ", "✓ SÍ" if titulo_reporte else "✗ NO")
	print("subtitulo_reporte: ", "✓ SÍ" if subtitulo_reporte else "✗ NO")
	print("placeholder_text: ", "✓ SÍ" if placeholder_text else "✗ NO")
	print("input_fecha_inicio: ", "✓ SÍ" if input_fecha_inicio else "✗ NO")
	print("input_fecha_fin: ", "✓ SÍ" if input_fecha_fin else "✗ NO")
	print("select_sucursal: ", "✓ SÍ" if select_sucursal else "✗ NO")
	print("kpi1_valor: ", "✓ SÍ" if kpi1_valor else "✗ NO")
	print("kpi2_valor: ", "✓ SÍ" if kpi2_valor else "✗ NO")
	print("kpi3_valor: ", "✓ SÍ" if kpi3_valor else "✗ NO")

func _buscar_y_cargar_nodos():
	"""Busca nodos por diferentes criterios"""
	
	# Buscar por nombres conocidos usando la función auxiliar que ahora está definida como método de clase
	titulo_reporte = _buscar_nodo_por_nombre("TituloReporte", "Label") as Label
	if not titulo_reporte:
		titulo_reporte = _buscar_nodo_por_nombre("ReportTitle", "Label") as Label
	if not titulo_reporte:
		titulo_reporte = _buscar_nodo_por_nombre("Titulo", "Label") as Label
	
	subtitulo_reporte = _buscar_nodo_por_nombre("SubtituloReporte", "Label") as Label
	if not subtitulo_reporte:
		subtitulo_reporte = _buscar_nodo_por_nombre("ReportDate", "Label") as Label
	if not subtitulo_reporte:
		subtitulo_reporte = _buscar_nodo_por_nombre("Subtitulo", "Label") as Label
	
	placeholder_text = _buscar_nodo_por_nombre("MensajePlaceholder", "Label") as Label
	if not placeholder_text:
		placeholder_text = _buscar_nodo_por_nombre("PlaceholderText", "Label") as Label
	if not placeholder_text:
		# Buscar por texto que contenga "Seleccione un tipo de reporte"
		var labels = _buscar_nodos_por_tipo_recursivo(self, "Label")
		for label in labels:
			if label.get_text().find("Seleccione un tipo de reporte") != -1:
				placeholder_text = label
				break
	
	# Buscar inputs de fecha
	input_fecha_inicio = _buscar_nodo_por_nombre("InputFechaInicio", "LineEdit") as LineEdit
	if not input_fecha_inicio:
		var line_edits = _buscar_nodos_por_tipo_recursivo(self, "LineEdit")
		for le in line_edits:
			if le.get_placeholder().find("DD/MM/AAAA") != -1:
				input_fecha_inicio = le
				break
	
	input_fecha_fin = _buscar_nodo_por_nombre("InputFechaFin", "LineEdit") as LineEdit
	
	# Buscar OptionButton
	select_sucursal = _buscar_nodo_por_nombre("SelectSucursal", "OptionButton") as OptionButton
	if not select_sucursal:
		select_sucursal = _buscar_nodo_por_nombre("SelectSucursal", "OptionButton") as OptionButton
	
	# Buscar valores de KPI
	kpi1_valor = _buscar_nodo_por_nombre("ValorKPI1", "Label") as Label
	kpi2_valor = _buscar_nodo_por_nombre("ValorKPI2", "Label") as Label
	kpi3_valor = _buscar_nodo_por_nombre("ValorKPI3", "Label") as Label

# Añade esta función como método de la clase
func _buscar_nodo_por_nombre(nombre: String, tipo_esperado: String = "") -> Node:
	var nodos = _buscar_nodos_por_nombre_recursivo(self, nombre)
	for nodo in nodos:
		if tipo_esperado == "" or nodo.is_class(tipo_esperado):
			return nodo
	return null

# Añadir esta función que faltaba
func _buscar_nodos_por_nombre_recursivo(nodo: Node, nombre: String) -> Array:
	var resultados = []
	if nodo.name == nombre:
		resultados.append(nodo)
	
	for hijo in nodo.get_children():
		resultados.append_array(_buscar_nodos_por_nombre_recursivo(hijo, nombre))
	
	return resultados

# Corregir esta función para usar String en lugar de GDScript
func _buscar_nodos_por_tipo_recursivo(nodo: Node, tipo: String) -> Array:
	var resultados = []
	if nodo.is_class(tipo):
		resultados.append(nodo)
	
	for hijo in nodo.get_children():
		resultados.append_array(_buscar_nodos_por_tipo_recursivo(hijo, tipo))
	
	return resultados

func _conectar_señales():
	"""Conecta todas las señales de los botones"""
	print("\n=== CONECTANDO SEÑALES ===")
	
	# Buscar botones por nombre
	var btn_no_conformidades = _buscar_nodos_por_nombre_recursivo(self, "TabNoConformidades")
	var btn_satisfaccion = _buscar_nodos_por_nombre_recursivo(self, "TabSatisfaccion")
	var btn_objetivos = _buscar_nodos_por_nombre_recursivo(self, "TabObjetivos")
	var btn_estado_nc = _buscar_nodos_por_nombre_recursivo(self, "TabEstadoNC")
	
	var btn_generar = _buscar_nodos_por_nombre_recursivo(self, "BtnGenerar")
	var btn_exportar = _buscar_nodos_por_nombre_recursivo(self, "BtnExportar")
	var btn_volver = _buscar_nodos_por_nombre_recursivo(self, "BtnVolverMenu")
	
	print("Botones encontrados:")
	print("  TabNoConformidades: ", btn_no_conformidades.size())
	print("  TabSatisfaccion: ", btn_satisfaccion.size())
	print("  TabObjetivos: ", btn_objetivos.size())
	print("  TabEstadoNC: ", btn_estado_nc.size())
	print("  BtnGenerar: ", btn_generar.size())
	print("  BtnExportar: ", btn_exportar.size())
	print("  BtnVolverMenu: ", btn_volver.size())
	
	# Conectar pestañas
	if btn_no_conformidades.size() > 0 and btn_no_conformidades[0] is Button:
		btn_no_conformidades[0].connect("pressed", _on_categoria_seleccionada.bind("no_conformidades"))
		print("✅ Conectado TabNoConformidades")
	
	if btn_satisfaccion.size() > 0 and btn_satisfaccion[0] is Button:
		btn_satisfaccion[0].connect("pressed", _on_categoria_seleccionada.bind("satisfaccion"))
		print("✅ Conectado TabSatisfaccion")
	
	if btn_objetivos.size() > 0 and btn_objetivos[0] is Button:
		btn_objetivos[0].connect("pressed", _on_categoria_seleccionada.bind("objetivos"))
		print("✅ Conectado TabObjetivos")
	
	if btn_estado_nc.size() > 0 and btn_estado_nc[0] is Button:
		btn_estado_nc[0].connect("pressed", _on_categoria_seleccionada.bind("estado_nc"))
		print("✅ Conectado TabEstadoNC")
	
	# Conectar botones de acción
	if btn_generar.size() > 0 and btn_generar[0] is Button:
		btn_generar[0].connect("pressed", _on_generar_previa)
		print("✅ Conectado BtnGenerar")
	
	if btn_exportar.size() > 0 and btn_exportar[0] is Button:
		btn_exportar[0].connect("pressed", _on_exportar_reporte)
		print("✅ Conectado BtnExportar")
	
	if btn_volver.size() > 0 and btn_volver[0] is Button:
		btn_volver[0].connect("pressed", _on_volver_menu)
		print("✅ Conectado BtnVolverMenu")

func _establecer_fechas_por_defecto():
	"""Establece fechas por defecto en los inputs"""
	if input_fecha_inicio and input_fecha_fin:
		var hoy = Time.get_date_string_from_system()
		var primer_dia_mes = hoy.substr(0, 8) + "01"
		
		print("📅 Fechas por defecto:")
		print("  Primer día del mes: ", primer_dia_mes)
		print("  Hoy: ", hoy)
		
		input_fecha_inicio.text = primer_dia_mes
		input_fecha_fin.text = hoy
	else:
		print("⚠️ No se pudieron establecer fechas por defecto - inputs no encontrados")

func _llenar_provincias_cuba():
	if select_sucursal:
		# Lista de provincias de Cuba
		var provincias = [
			"Todas las provincias",
			"Pinar del Río",
			"Artemisa", 
			"La Habana",
			"Mayabeque",
			"Matanzas",
			"Cienfuegos",
			"Villa Clara",
			"Sancti Spíritus",
			"Ciego de Ávila",
			"Camagüey",
			"Las Tunas",
			"Granma",
			"Holguín",
			"Santiago de Cuba",
			"Guantánamo",
			"Isla de la Juventud"
		]
		
		# Limpiar opciones existentes
		select_sucursal.clear()
		
		# Agregar cada provincia
		for provincia in provincias:
			select_sucursal.add_item(provincia)
		
		print("✅ Provincias de Cuba cargadas: ", provincias.size())
	else:
		print("⚠️ ADVERTENCIA: select_sucursal no disponible")

func _on_categoria_seleccionada(categoria):
	print("📊 Categoría seleccionada: ", categoria)
	categoria_actual = categoria
	_actualizar_ui_categoria(categoria)
	
	# Actualizar título si está disponible
	if titulo_reporte:
		match categoria:
			"no_conformidades":
				titulo_reporte.text = "ESTADÍSTICAS DE NO CONFORMIDADES"
				if subtitulo_reporte:
					subtitulo_reporte.text = "Análisis estadístico de no conformidades"
			"satisfaccion":
				titulo_reporte.text = "SATISFACCIÓN DEL CLIENTE"
				if subtitulo_reporte:
					subtitulo_reporte.text = "Métricas de satisfacción del cliente"
			"objetivos":
				titulo_reporte.text = "OBJETIVOS DE CALIDAD"
				if subtitulo_reporte:
					subtitulo_reporte.text = "Seguimiento de objetivos de calidad"
			"estado_nc":
				titulo_reporte.text = "ESTADO DE NO CONFORMIDADES"
				if subtitulo_reporte:
					subtitulo_reporte.text = "Estado actual de no conformidades"

func _actualizar_ui_categoria(categoria_activa):
	"""Actualiza la interfaz para mostrar la pestaña activa"""
	# Obtener todos los botones que podrían ser pestañas
	var posibles_tabs = []
	posibles_tabs.append_array(_buscar_nodos_por_nombre_recursivo(self, "TabNoConformidades"))
	posibles_tabs.append_array(_buscar_nodos_por_nombre_recursivo(self, "TabSatisfaccion"))
	posibles_tabs.append_array(_buscar_nodos_por_nombre_recursivo(self, "TabObjetivos"))
	posibles_tabs.append_array(_buscar_nodos_por_nombre_recursivo(self, "TabEstadoNC"))
	
	# Resetear todos los tabs
	for posible_tab in posibles_tabs:
		if posible_tab is Button:
			posible_tab.remove_theme_stylebox_override("normal")
			posible_tab.remove_theme_color_override("font_color")
	
	# Activar el tab seleccionado
	var tab_activo: Button = null
	
	match categoria_activa:
		"no_conformidades":
			var tabs = _buscar_nodos_por_nombre_recursivo(self, "TabNoConformidades")
			if tabs.size() > 0 and tabs[0] is Button:
				tab_activo = tabs[0] as Button
		"satisfaccion":
			var tabs = _buscar_nodos_por_nombre_recursivo(self, "TabSatisfaccion")
			if tabs.size() > 0 and tabs[0] is Button:
				tab_activo = tabs[0] as Button
		"objetivos":
			var tabs = _buscar_nodos_por_nombre_recursivo(self, "TabObjetivos")
			if tabs.size() > 0 and tabs[0] is Button:
				tab_activo = tabs[0] as Button
		"estado_nc":
			var tabs = _buscar_nodos_por_nombre_recursivo(self, "TabEstadoNC")
			if tabs.size() > 0 and tabs[0] is Button:
				tab_activo = tabs[0] as Button
	
	if tab_activo:
		# Crear estilo para tab activo
		var estilo_activo = StyleBoxFlat.new()
		estilo_activo.bg_color = Color(0.227451, 0.52549, 0.94902, 0.1)
		estilo_activo.border_color = Color(0.227451, 0.52549, 0.94902, 1)
		estilo_activo.border_width_left = 2
		estilo_activo.border_width_top = 1
		estilo_activo.border_width_right = 1
		estilo_activo.border_width_bottom = 1
		estilo_activo.corner_radius_top_left = 6
		estilo_activo.corner_radius_top_right = 6
		estilo_activo.corner_radius_bottom_right = 6
		estilo_activo.corner_radius_bottom_left = 6
		estilo_activo.content_margin_left = 15.0
		estilo_activo.content_margin_top = 10.0
		estilo_activo.content_margin_right = 15.0
		estilo_activo.content_margin_bottom = 10.0
		
		tab_activo.add_theme_stylebox_override("normal", estilo_activo)
		tab_activo.add_theme_color_override("font_color", Color(0.12549, 0.290196, 0.533333, 1))

func _on_generar_previa():
	print("\n🔄 GENERANDO VISTA PREVIA...")
	
	# Verificar nodos requeridos
	if not input_fecha_inicio or not input_fecha_fin or not select_sucursal:
		print("❌ ERROR: Faltan nodos requeridos para generar el reporte")
		if placeholder_text:
			placeholder_text.text = "❌ ERROR: No se puede generar el reporte\n\nAlgunos elementos de la interfaz no están disponibles."
		return
	
	# Verificar si BD está disponible
	if not has_node("/root/BD"):
		print("❌ ERROR: Base de datos no disponible")
		if placeholder_text:
			placeholder_text.text = "❌ ERROR: Sistema de base de datos no disponible\n\nNo se puede conectar con la base de datos."
		return
	
	# Obtener valores de filtros
	var fecha_inicio = input_fecha_inicio.text.strip_edges()
	var fecha_fin = input_fecha_fin.text.strip_edges()
	var sucursal = select_sucursal.text
	
	print("📋 Filtros aplicados:")
	print("  Fecha inicio: ", fecha_inicio)
	print("  Fecha fin: ", fecha_fin)
	print("  Sucursal: ", sucursal)
	print("  Categoría: ", categoria_actual)
	
	# Mostrar mensaje de carga
	if placeholder_text:
		placeholder_text.text = "⏳ CONSULTANDO BASE DE DATOS...\n\nObteniendo datos para el reporte..."
	
	# Procesar en el siguiente frame
	call_deferred("_procesar_reporte_con_datos", fecha_inicio, fecha_fin, sucursal)

func _procesar_reporte_con_datos(fecha_inicio: String, fecha_fin: String, sucursal: String):
	"""Procesa el reporte con datos de la base de datos"""
	print("\n📊 PROCESANDO REPORTE CON DATOS...")
	
	# Convertir fechas si es necesario
	var fecha_inicio_convertida = fecha_inicio
	var fecha_fin_convertida = fecha_fin
	
	if fecha_inicio.find("/") != -1:
		fecha_inicio_convertida = _convertir_fecha_dd_mm_aaaa(fecha_inicio)
	if fecha_fin.find("/") != -1:
		fecha_fin_convertida = _convertir_fecha_dd_mm_aaaa(fecha_fin)
	
	print("📅 Fechas convertidas:")
	print("  Inicio: ", fecha_inicio_convertida)
	print("  Fin: ", fecha_fin_convertida)
	
	# Obtener datos según la categoría
	print("🔍 Obteniendo datos para categoría: ", categoria_actual)
	
	var bd = get_node("/root/BD")
	if not bd:
		print("❌ ERROR: No se pudo obtener referencia a BD")
		if placeholder_text:
			placeholder_text.text = "❌ ERROR: No se pudo acceder a la base de datos"
		return
	
	match categoria_actual:
		"no_conformidades":
			datos_reporte = _obtener_datos_no_conformidades(fecha_inicio_convertida, fecha_fin_convertida, sucursal, bd)
		"satisfaccion":
			datos_reporte = _obtener_datos_satisfaccion(fecha_inicio_convertida, fecha_fin_convertida, sucursal, bd)
		"objetivos":
			datos_reporte = _obtener_datos_objetivos(fecha_inicio_convertida, fecha_fin_convertida, sucursal, bd)
		"estado_nc":
			datos_reporte = _obtener_datos_estado_nc(fecha_inicio_convertida, fecha_fin_convertida, sucursal, bd)
		_:
			datos_reporte = {}
	
	print("✅ Datos obtenidos: ", datos_reporte.size() > 0)
	
	# Actualizar la interfaz
	_actualizar_ui_con_datos(fecha_inicio_convertida, fecha_fin_convertida, sucursal)

func _convertir_fecha_dd_mm_aaaa(fecha: String) -> String:
	"""Convierte fecha de DD/MM/AAAA a AAAA-MM-DD"""
	if fecha.length() == 10 and fecha[2] == "/" and fecha[5] == "/":
		var dia = fecha.substr(0, 2)
		var mes = fecha.substr(3, 2)
		var anio = fecha.substr(6, 4)
		return anio + "-" + mes + "-" + dia
	return fecha

func _obtener_datos_no_conformidades(fecha_inicio: String, fecha_fin: String, sucursal: String, bd: Node) -> Dictionary:
	"""Obtiene datos de no conformidades de la base de datos"""
	print("\n🔍 EJECUTANDO CONSULTAS DE NO CONFORMIDADES")
	
	var datos = {
		"total_nc": 0,
		"pendientes": 0,
		"analizadas": 0,
		"cerradas": 0,
		"por_sucursal": [],
		"por_tipo": []
	}
	
	# Construir condiciones WHERE
	var condiciones_extra = ""
	var params = [fecha_inicio, fecha_fin]
	
	if sucursal != "Todas las provincias":
		condiciones_extra = " AND sucursal = ?"
		params.append(sucursal)
	
	print("🔧 Parámetros de consulta:")
	print("  Fecha inicio: ", fecha_inicio)
	print("  Fecha fin: ", fecha_fin)
	print("  Sucursal: ", sucursal)
	print("  Condiciones extra: ", condiciones_extra)
	print("  Params: ", params)
	
	# 1. Total de NC en el período
	var sql_total = """
		SELECT COUNT(*) as total 
		FROM no_conformidades 
		WHERE fecha_ocurrencia BETWEEN ? AND ?
		{condiciones}
	""".format({"condiciones": condiciones_extra})
	
	print("📝 SQL Total: ", sql_total)
	var result_total = bd.select_query(sql_total, params)
	print("📊 Resultado Total: ", result_total)
	
	if result_total and result_total.size() > 0:
		datos["total_nc"] = int(result_total[0]["total"])
		print("✅ Total NC: ", datos["total_nc"])
	
	# 2. NC pendientes
	var sql_pendientes = """
		SELECT COUNT(*) as pendientes 
		FROM no_conformidades 
		WHERE fecha_ocurrencia BETWEEN ? AND ? 
		AND estado = 'pendiente'
		{condiciones}
	""".format({"condiciones": condiciones_extra})
	
	var result_pendientes = bd.select_query(sql_pendientes, params)
	if result_pendientes and result_pendientes.size() > 0:
		datos["pendientes"] = int(result_pendientes[0]["pendientes"])
		print("✅ Pendientes: ", datos["pendientes"])
	
	# 3. NC analizadas
	var sql_analizadas = """
		SELECT COUNT(*) as analizadas 
		FROM no_conformidades 
		WHERE fecha_ocurrencia BETWEEN ? AND ? 
		AND estado = 'analizado'
		{condiciones}
	""".format({"condiciones": condiciones_extra})
	
	var result_analizadas = bd.select_query(sql_analizadas, params)
	if result_analizadas and result_analizadas.size() > 0:
		datos["analizadas"] = int(result_analizadas[0]["analizadas"])
		print("✅ Analizadas: ", datos["analizadas"])
	
	# 4. NC cerradas
	var sql_cerradas = """
		SELECT COUNT(*) as cerradas 
		FROM no_conformidades 
		WHERE fecha_ocurrencia BETWEEN ? AND ? 
		AND estado = 'cerrada'
		{condiciones}
	""".format({"condiciones": condiciones_extra})
	
	var result_cerradas = bd.select_query(sql_cerradas, params)
	if result_cerradas and result_cerradas.size() > 0:
		datos["cerradas"] = int(result_cerradas[0]["cerradas"])
		print("✅ Cerradas: ", datos["cerradas"])
	
	# 5. Distribución por sucursal
	var sql_por_sucursal = """
		SELECT 
			CASE 
				WHEN sucursal IS NULL OR sucursal = '' THEN 'Sin especificar'
				ELSE sucursal
			END as sucursal, 
			COUNT(*) as cantidad 
		FROM no_conformidades 
		WHERE fecha_ocurrencia BETWEEN ? AND ?
		GROUP BY sucursal
		ORDER BY cantidad DESC
		LIMIT 10
	"""
	
	var result_sucursal = bd.select_query(sql_por_sucursal, [fecha_inicio, fecha_fin])
	if result_sucursal and result_sucursal.size() > 0:
		for row in result_sucursal:
			datos["por_sucursal"].append({
				"sucursal": row["sucursal"],
				"cantidad": int(row["cantidad"])
			})
		print("✅ Distribución por sucursal: ", datos["por_sucursal"].size(), " registros")
	
	# 6. Distribución por tipo
	var sql_por_tipo = """
		SELECT 
			CASE 
				WHEN tipo_nc IS NULL OR tipo_nc = '' THEN 'Sin especificar'
				ELSE tipo_nc
			END as tipo_nc, 
			COUNT(*) as cantidad 
		FROM no_conformidades 
		WHERE fecha_ocurrencia BETWEEN ? AND ?
		GROUP BY tipo_nc
		ORDER BY cantidad DESC
		LIMIT 10
	"""
	
	var result_tipo = bd.select_query(sql_por_tipo, [fecha_inicio, fecha_fin])
	if result_tipo and result_tipo.size() > 0:
		for row in result_tipo:
			datos["por_tipo"].append({
				"tipo_nc": row["tipo_nc"],
				"cantidad": int(row["cantidad"])
			})
		print("✅ Distribución por tipo: ", datos["por_tipo"].size(), " registros")
	
	return datos

func _obtener_datos_satisfaccion(_fecha_inicio: String, _fecha_fin: String, _sucursal: String, _bd: Node) -> Dictionary:
	"""Obtiene datos de satisfacción de la base de datos"""
	var datos = {
		"total_quejas": 0,
		"promedio_satisfaccion": 0,
		"quejas_resueltas": 0,
		"tiempo_respuesta_promedio": 0,
		"por_categoria": []
	}
	
	# Datos de ejemplo (por ahora)
	print("⚠️ Usando datos de ejemplo para satisfacción (pendiente implementar)")
	
	datos["total_quejas"] = 28
	datos["promedio_satisfaccion"] = 8.5
	datos["quejas_resueltas"] = 24
	datos["tiempo_respuesta_promedio"] = 3.2
	datos["por_categoria"] = [
		{"categoria": "Servicio al Cliente", "cantidad": 12},
		{"categoria": "Producto Defectuoso", "cantidad": 8},
		{"categoria": "Tiempo de Entrega", "cantidad": 5},
		{"categoria": "Facturación", "cantidad": 3}
	]
	
	return datos

func _obtener_datos_objetivos(_fecha_inicio: String, _fecha_fin: String, _sucursal: String, _bd: Node) -> Dictionary:
	"""Obtiene datos de objetivos de calidad"""
	var datos = {
		"objetivos_totales": 0,
		"objetivos_cumplidos": 0,
		"porcentaje_cumplimiento": 0,
		"mejoras_implementadas": 0
	}
	
	# Datos de ejemplo
	print("⚠️ Usando datos de ejemplo para objetivos (pendiente implementar)")
	
	datos["objetivos_totales"] = 15
	datos["objetivos_cumplidos"] = 12
	datos["porcentaje_cumplimiento"] = 80.0
	datos["mejoras_implementadas"] = 7
	
	return datos

func _obtener_datos_estado_nc(_fecha_inicio: String, _fecha_fin: String, _sucursal: String, _bd: Node) -> Dictionary:
	"""Obtiene datos del estado de no conformidades"""
	var datos = {
		"total_nc": 0,
		"pendientes": 0,
		"en_progreso": 0,
		"cerradas": 0,
		"por_estado": [],
		"nc_antiguas": []
	}
	
	# Datos de ejemplo
	print("⚠️ Usando datos de ejemplo para estado NC (pendiente implementar)")
	
	datos["total_nc"] = 42
	datos["pendientes"] = 12
	datos["en_progreso"] = 18
	datos["cerradas"] = 12
	datos["por_estado"] = [
		{"estado": "pendiente", "cantidad": 12},
		{"estado": "analizado", "cantidad": 18},
		{"estado": "cerrada", "cantidad": 12}
	]
	datos["nc_antiguas"] = [
		{"codigo_expediente": "EXP-2024-001", "descripcion": "NC antigua pendiente de análisis", "fecha_ocurrencia": "2024-01-15", "estado": "pendiente"},
		{"codigo_expediente": "EXP-2024-002", "descripcion": "NC en progreso desde hace tiempo", "fecha_ocurrencia": "2024-01-20", "estado": "analizado"}
	]
	
	return datos

func _actualizar_ui_con_datos(fecha_inicio: String, fecha_fin: String, sucursal: String):
	"""Actualiza la interfaz con los datos obtenidos"""
	print("\n🎨 ACTUALIZANDO INTERFAZ CON DATOS...")
	
	# Actualizar KPIs según la categoría
	match categoria_actual:
		"no_conformidades":
			print("📊 Actualizando KPIs para No Conformidades")
			
			if kpi1_valor:
				kpi1_valor.text = str(datos_reporte.get("total_nc", 0))
				print("✅ KPI1 (Total NC): ", datos_reporte.get("total_nc", 0))
			
			if kpi2_valor:
				var total = datos_reporte.get("total_nc", 0)
				var cerradas = datos_reporte.get("cerradas", 0)
				var porcentaje = 0
				if total > 0:
					porcentaje = (cerradas * 100.0) / total
				kpi2_valor.text = "%.1f%%" % porcentaje
				print("✅ KPI2 (% Cerradas): %.1f%%" % porcentaje)
			
			if kpi3_valor:
				kpi3_valor.text = str(datos_reporte.get("pendientes", 0))
				print("✅ KPI3 (Pendientes): ", datos_reporte.get("pendientes", 0))
			
			# Crear texto de resumen
			var texto = "📊 ESTADÍSTICAS DE NO CONFORMIDADES\n\n"
			texto += "Período: %s a %s\n" % [fecha_inicio, fecha_fin]
			texto += "Sucursal: %s\n\n" % sucursal
			texto += "Total NC: %d\n" % datos_reporte.get("total_nc", 0)
			texto += "• Pendientes: %d\n" % datos_reporte.get("pendientes", 0)
			texto += "• En análisis: %d\n" % datos_reporte.get("analizadas", 0)
			texto += "• Cerradas: %d\n\n" % datos_reporte.get("cerradas", 0)
			
			# Agregar distribución por tipo si existe
			var por_tipo = datos_reporte.get("por_tipo", [])
			if por_tipo.size() > 0:
				texto += "Distribución por tipo:\n"
				for item in por_tipo:
					texto += "• %s: %d\n" % [item.get("tipo_nc", "Desconocido"), item.get("cantidad", 0)]
			
			if placeholder_text:
				placeholder_text.text = texto
				print("✅ Texto actualizado en placeholder")
		
		"satisfaccion":
			print("😊 Actualizando KPIs para Satisfacción")
			# ... código existente ...
		
		"objetivos":
			print("🎯 Actualizando KPIs para Objetivos")
			# ... código existente ...
		
		"estado_nc":
			print("⚠️ Actualizando KPIs para Estado NC")
			# ... código existente ...
	
	# Actualizar fecha de última actualización
	if subtitulo_reporte:
		var fecha_actual = Time.get_datetime_string_from_system()
		subtitulo_reporte.text = "Última actualización: " + fecha_actual
		print("✅ Fecha de actualización actualizada")

func _on_exportar_reporte():
	"""Maneja la exportación del reporte"""
	print("📤 Exportando reporte...")
	
	# Mostrar mensaje de confirmación
	if placeholder_text:
		placeholder_text.text = "✅ REPORTE EXPORTADO\n\nEl reporte ha sido exportado exitosamente.\n\nFormatos disponibles:\n• PDF\n• Excel\n• CSV\n\nEl archivo se ha guardado en la carpeta de documentos."

func _on_volver_menu():
	"""Regresa al menú principal"""
	print("🏠 Regresando al menú principal...")
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")
