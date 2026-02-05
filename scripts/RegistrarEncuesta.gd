extends Control

# Referencias a nodos principales
var db = null  # Referencia a la base de datos (se inicializa más tarde)
var usuario_actual: Dictionary = {}  # Información del usuario actual

# Variables para almacenar datos del formulario
var datos_encuesta: Dictionary = {}
var producto_seleccionado: String = ""
var satisfaccion_calculada: float = 0.0

func _ready():
	# Obtener instancia de la base de datos desde el autoload
	inicializar_base_datos()
	
	# Inicializar controles del formulario
	inicializar_formulario()
	
	# Conectar señales de los botones
	conectar_señales()
	
	# Verificar/cargar la tabla de encuestas
	verificar_tabla_encuestas()
	
	# Llenar opciones por defecto
	cargar_opciones_por_defecto()
	
	# Mostrar fecha actual por defecto
	mostrar_fecha_actual()

func inicializar_base_datos():
	"""Inicializa la conexión a la base de datos"""
	# Buscar la base de datos en diferentes formas
	var posibles_rutas = [
		"/root/Bd",  # Si BD está en el árbol como nodo
		"/root/Bd",  # Otra posible ruta
		"BD",        # Si está como singleton
		"Bd"         # Versión en minúsculas
	]
	
	for ruta in posibles_rutas:
		var posible_db = get_node_or_null(ruta)
		if posible_db and posible_db.has_method("query"):
			db = posible_db
			print("✅ Base de datos encontrada en: " + ruta)
			break
	
	if db == null:
		# Intentar crear una instancia nueva
		print("⚠️ Base de datos no encontrada, intentando crear nueva instancia...")
		var script_bd = load("res://scripts/BD.gd")
		if script_bd:
			db = script_bd.new()
			if db.has_method("_ready"):
				db._ready()
			print("✅ Base de datos creada localmente")
		else:
			print("❌ No se pudo cargar BD.gd")
	
	# Intentar obtener usuario actual si existe un singleton Global
	var global_singleton = get_node_or_null("/root/Global")
	if global_singleton:
		# Verificar si tiene la propiedad usuario_actual usando get()
		var usuario = global_singleton.get("usuario_actual")
		if usuario != null:
			usuario_actual = usuario
			print("✅ Usuario actual obtenido")
		# O si tiene un método para obtenerlo
		elif global_singleton.has_method("obtener_usuario_actual"):
			usuario_actual = global_singleton.obtener_usuario_actual()
			print("✅ Usuario actual obtenido mediante método")
	
	# Si después de todo no tenemos usuario, crear uno por defecto
	if usuario_actual.is_empty():
		print("⚠️ No se pudo obtener usuario actual, usando valores por defecto")
		usuario_actual = {
			"id": 1,
			"nombre": "Usuario Temporal",
			"rol": "operador"
		}

func inicializar_formulario():
	"""Inicializa todos los controles del formulario con valores por defecto"""
	print("📋 Inicializando formulario de encuestas...")
	
	# Limpiar todos los campos
	limpiar_campos()
	
	# Configurar tema visual
	configurar_apariencia()

func conectar_señales():
	"""Conecta todas las señales de los botones y controles"""
	print("🔗 Conectando señales...")
	
	# Botones principales
	var btn_guardar = $ContenedorPrincipal/VBoxContainer/BotonesAccion/BtnGuardar
	var btn_limpiar = $ContenedorPrincipal/VBoxContainer/BotonesAccion/BtnLimpiar
	var btn_volver = $ContenedorPrincipal/VBoxContainer/BotonesAccion/BtnVolverMenu
	
	if btn_guardar:
		btn_guardar.connect("pressed", _on_guardar_encuesta)
	if btn_limpiar:
		btn_limpiar.connect("pressed", _on_limpiar_formulario)
	if btn_volver:
		btn_volver.connect("pressed", _on_volver_menu)
	
	# Señales para cálculo en tiempo real
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	
	if select_calidad:
		select_calidad.connect("item_selected", _on_calcular_satisfaccion)
	if select_tiempo:
		select_tiempo.connect("item_selected", _on_calcular_satisfaccion)
	
	# Señales para validación en tiempo real
	var input_cliente = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputCliente
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	
	if input_cliente:
		input_cliente.connect("text_changed", _on_validar_campos)
	if select_producto:
		select_producto.connect("item_selected", _on_validar_campos)
	
	print("✅ Señales conectadas correctamente")

func configurar_apariencia():
	"""Configura la apariencia visual del formulario"""
	# Configurar tooltips - ThemeDB no es necesario para esto básico
	var input_cliente = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputCliente
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	var input_fecha = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputFecha
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	
	if input_cliente:
		input_cliente.tooltip_text = "Ingrese el nombre completo del cliente"
	if select_producto:
		select_producto.tooltip_text = "Seleccione el producto o servicio evaluado"
	if input_fecha:
		input_fecha.tooltip_text = "Fecha en formato DD/MM/AAAA"
	if select_calidad:
		select_calidad.tooltip_text = "Califique la calidad del 1 (muy mala) a 5 (excelente)"
	if select_tiempo:
		select_tiempo.tooltip_text = "Califique el tiempo de respuesta del 1 (muy lento) a 5 (muy rápido)"

func verificar_tabla_encuestas() -> bool:
	"""Verifica si la tabla de encuestas existe, si no, la crea"""
	if db == null:
		print("⚠️ Base de datos no inicializada")
		return false
	
	# Verificar si la tabla existe
	if db.has_method("table_exists"):
		if not db.table_exists("encuestas_satisfaccion"):
			print("📊 Creando tabla 'encuestas_satisfaccion'...")
			
			var sql_tabla_encuestas = """
                CREATE TABLE IF NOT EXISTS encuestas_satisfaccion (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    codigo_encuesta TEXT UNIQUE,
                    cliente TEXT NOT NULL,
                    producto_servicio TEXT NOT NULL,
                    fecha_aplicacion DATE NOT NULL,
                    calidad INTEGER NOT NULL,
                    tiempo_respuesta INTEGER NOT NULL,
                    observaciones TEXT,
                    satisfaccion_promedio REAL NOT NULL,
                    categoria_satisfaccion TEXT,
                    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
                    registrado_por INTEGER,
                    estado TEXT DEFAULT 'activa',
                    analizado_por TEXT,
                    fecha_analisis DATE,
                    acciones_mejora TEXT,
                    notas_internas TEXT
                )
			"""
			
			if db.has_method("query") and db.query(sql_tabla_encuestas):
				print("✅ Tabla 'encuestas_satisfaccion' creada exitosamente")
				
				# Crear índice para búsquedas más rápidas
				var sql_indices = """
                    CREATE INDEX IF NOT EXISTS idx_encuestas_cliente ON encuestas_satisfaccion(cliente);
                    CREATE INDEX IF NOT EXISTS idx_encuestas_fecha ON encuestas_satisfaccion(fecha_aplicacion);
                    CREATE INDEX IF NOT EXISTS idx_encuestas_satisfaccion ON encuestas_satisfaccion(satisfaccion_promedio);
				"""
				
				# Ejecutar índices uno por uno para mayor compatibilidad
				var indices = sql_indices.split(";")
				for indice in indices:
					
					if indice.strip_edges().length() > 0:
						if db.has_method("query"):
							db.query(indice + ";")
				
				print("✅ Índices creados correctamente")
				return true
			else:
				print("❌ Error al crear tabla 'encuestas_satisfaccion'")
				return false
		else:
			print("✅ Tabla 'encuestas_satisfaccion' ya existe")
			return true
	else:
		print("❌ DB no tiene método table_exists")
		return false
		
func cargar_opciones_por_defecto():
	"""Carga las opciones por defecto en los dropdowns"""
	print("📝 Cargando opciones por defecto...")
	
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	
	if not select_producto or not select_calidad or not select_tiempo:
		print("⚠️ No se encontraron todos los controles necesarios")
		return
	
	# Limpiar opciones existentes
	select_producto.clear()
	select_calidad.clear()
	select_tiempo.clear()
	
	# Cargar opciones de productos/servicios
	var productos = [
		"Seleccione...",
		"Servicio Técnico",
		"Venta de Productos", 
		"Consultoría",
		"Soporte en Línea",
		"Capacitación",
		"Desarrollo de Software",
		"Mantenimiento",
		"Auditoría"
	]
	
	for producto in productos:
		select_producto.add_item(producto)
	
	# Cargar opciones de calificación (1-5)
	for i in range(1, 6):
		select_calidad.add_item(str(i) + " ★")
		select_tiempo.add_item(str(i) + " ★")
	
	# Establecer valores por defecto (5 estrellas)
	select_calidad.selected = 4  # Índice 4 = 5 estrellas
	select_tiempo.selected = 4   # Índice 4 = 5 estrellas
	
	print("✅ Opciones cargadas correctamente")
	
	# Calcular satisfacción inicial
	_on_calcular_satisfaccion()

func mostrar_fecha_actual():
	"""Muestra la fecha actual en el campo de fecha"""
	var input_fecha = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputFecha
	if input_fecha:
		var fecha_actual = Time.get_date_dict_from_system()
		var fecha_formateada = "%02d/%02d/%04d" % [fecha_actual.day, fecha_actual.month, fecha_actual.year]
		input_fecha.text = fecha_formateada

func _on_guardar_encuesta():
	"""Guarda la encuesta en la base de datos"""
	print("💾 Iniciando guardado de encuesta...")
	
	# Validar campos obligatorios
	if not validar_formulario():
		mostrar_mensaje_error("Validación", "Por favor complete todos los campos obligatorios (*)")
		return
	
	# Preparar datos para la base de datos
	preparar_datos_encuesta()
	
	# Generar código único para la encuesta
	var codigo_encuesta = generar_codigo_encuesta()
	
	# Calcular categoría de satisfacción
	var categoria = determinar_categoria_satisfaccion()
	
	# Preparar diccionario para la base de datos
	var datos_encuesta_db = {
		"codigo_encuesta": codigo_encuesta,
		"cliente": datos_encuesta.get("cliente", ""),
		"producto_servicio": datos_encuesta.get("producto_servicio", ""),
		"fecha_aplicacion": datos_encuesta.get("fecha_aplicacion", ""),
		"calidad": datos_encuesta.get("calidad", 0),
		"tiempo_respuesta": datos_encuesta.get("tiempo_respuesta", 0),
		"observaciones": datos_encuesta.get("observaciones", ""),
		"satisfaccion_promedio": satisfaccion_calculada,
		"categoria_satisfaccion": categoria,
		"registrado_por": usuario_actual.get("id", 1),  # Usuario actual o admin por defecto
		"estado": "activa"
	}
	
	# Insertar en la base de datos
	if db and db.has_method("insert"):
		print("📝 Insertando encuesta en la base de datos...")
		var id_encuesta = db.insert("encuestas_satisfaccion", datos_encuesta_db)
		
		if id_encuesta > 0:
			print("✅ Encuesta guardada exitosamente con ID: ", id_encuesta)
			
			# Registrar en el historial si es posible
			registrar_historial("encuesta_creada", "Se registró encuesta de satisfacción: " + codigo_encuesta)
			
			# Mostrar mensaje de éxito
			mostrar_mensaje_exito("Encuesta Registrada", 
				"✅ Encuesta registrada exitosamente\n\n" +
				"Código: " + codigo_encuesta + "\n" +
				"Cliente: " + datos_encuesta.get("cliente", "") + "\n" +
				"Satisfacción: " + ("%.1f" % satisfaccion_calculada) + "/5\n" +
				"Categoría: " + categoria)
			
			# Limpiar formulario para nueva encuesta
			_on_limpiar_formulario()
			
			# Actualizar estadísticas
			actualizar_estadisticas()
		else:
			print("❌ Error al guardar la encuesta")
			mostrar_mensaje_error("Error", "No se pudo guardar la encuesta en la base de datos")
	else:
		print("❌ Base de datos no disponible")
		mostrar_mensaje_error("Error", "Base de datos no disponible. No se puede guardar la encuesta.")

func preparar_datos_encuesta():
	"""Prepara los datos del formulario para ser guardados"""
	var input_cliente = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputCliente
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	var input_fecha = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputFecha
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	var input_observaciones = $ContenedorPrincipal/VBoxContainer/FormContainer/InputObservaciones
	
	if not all([input_cliente, select_producto, input_fecha, select_calidad, select_tiempo, input_observaciones]):
		print("⚠️ No se encontraron todos los controles del formulario")
		return
	
	datos_encuesta = {
		"cliente": input_cliente.text.strip_edges(),
		"producto_servicio": select_producto.get_item_text(select_producto.selected),
		"fecha_aplicacion": input_fecha.text,
		"calidad": select_calidad.selected + 1,
		"tiempo_respuesta": select_tiempo.selected + 1,
		"observaciones": input_observaciones.text.strip_edges()
	}
	
	# Calcular satisfacción promedio
	satisfaccion_calculada = (datos_encuesta.get("calidad", 0) + datos_encuesta.get("tiempo_respuesta", 0)) / 2.0

func all(nodes: Array) -> bool:
	"""Verifica que todos los nodos en el array existan"""
	for node in nodes:
		if node == null:
			return false
	return true

func generar_codigo_encuesta() -> String:
	"""Genera un código único para la encuesta"""
	var fecha_actual = Time.get_date_dict_from_system()
	var año = fecha_actual.year
	var mes = fecha_actual.month
	var dia = fecha_actual.day
	
	# Obtener número secuencial para el día
	var contador = 1
	if db and db.has_method("select_query"):
		var sql_contador = "SELECT COUNT(*) as total FROM encuestas_satisfaccion WHERE DATE(fecha_registro) = DATE('now')"
		var resultado = db.select_query(sql_contador)
		
		if resultado and resultado.size() > 0:
			contador = int(resultado[0].get("total", 0)) + 1
	
	return "ENC-%04d-%02d-%02d-%03d" % [año, mes, dia, contador]

func determinar_categoria_satisfaccion() -> String:
	"""Determina la categoría de satisfacción basada en el promedio"""
	if satisfaccion_calculada >= 4.5:
		return "Excelente"
	elif satisfaccion_calculada >= 4.0:
		return "Muy Buena"
	elif satisfaccion_calculada >= 3.0:
		return "Buena"
	elif satisfaccion_calculada >= 2.0:
		return "Regular"
	else:
		return "Mala"

func validar_formulario() -> bool:
	"""Valida todos los campos del formulario"""
	print("🔍 Validando formulario...")
	
	var input_cliente = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputCliente
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	var input_fecha = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputFecha
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	
	if not all([input_cliente, select_producto, input_fecha, select_calidad, select_tiempo]):
		print("❌ No se encontraron todos los controles de validación")
		return false
	
	# Validar cliente
	var cliente = input_cliente.text.strip_edges()
	if cliente == "":
		resaltar_error(input_cliente, "Debe ingresar el nombre del cliente")
		return false
	remover_error(input_cliente)
	
	# Validar producto/servicio
	var producto = select_producto.get_item_text(select_producto.selected)
	if producto == "Seleccione...":
		resaltar_error(select_producto, "Debe seleccionar un producto/servicio")
		return false
	remover_error(select_producto)
	
	# Validar fecha
	var fecha = input_fecha.text.strip_edges()
	if not validar_formato_fecha(fecha):
		resaltar_error(input_fecha, "Formato de fecha inválido. Use DD/MM/AAAA")
		return false
	remover_error(input_fecha)
	
	# Validar calificaciones
	var calidad = select_calidad.selected
	var tiempo = select_tiempo.selected
	
	if calidad < 0 or tiempo < 0:
		resaltar_error(select_calidad, "Debe seleccionar calificaciones válidas")
		return false
	
	print("✅ Formulario validado correctamente")
	return true

func validar_formato_fecha(fecha: String) -> bool:
	"""Valida el formato de fecha DD/MM/AAAA"""
	var regex = RegEx.new()
	var compile_result = regex.compile("^\\d{2}/\\d{2}/\\d{4}$")
	
	if compile_result == OK and regex.search(fecha):
		# Validar partes de la fecha
		var partes = fecha.split("/")
		if partes.size() == 3:
			var dia = int(partes[0])
			var mes = int(partes[1])
			var año = int(partes[2])
			
			# Validaciones básicas
			if año < 2000 or año > 2100:
				return false
			if mes < 1 or mes > 12:
				return false
			if dia < 1 or dia > 31:
				return false
			
			# Validar meses con 30 días
			if mes in [4, 6, 9, 11] and dia > 30:
				return false
			
			# Validar febrero
			if mes == 2:
				var es_bisiesto = (año % 4 == 0 and (año % 100 != 0 or año % 400 == 0))
				if dia > (29 if es_bisiesto else 28):
					return false
			
			return true
	
	return false

func resaltar_error(control: Control, mensaje: String):
	"""Resalta visualmente un control con error - Versión simplificada"""
	print("❌ Error en campo: " + mensaje)
	if control:
		control.tooltip_text = mensaje
		# Podemos cambiar el color usando add_theme_color_override
		control.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # Rojo

func remover_error(control: Control):
	"""Remueve el resaltado de error de un control - Versión simplificada"""
	if control:
		control.tooltip_text = ""
		# Restaurar color original
		control.remove_theme_color_override("font_color")

func _on_calcular_satisfaccion(_index = 0):
	"""Calcula la satisfacción en tiempo real cuando cambian las calificaciones"""
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	var label_resultado = $ContenedorPrincipal/VBoxContainer/PanelResultado/LabelResultado
	
	if not all([select_calidad, select_tiempo, label_resultado]):
		return
	
	var calidad = select_calidad.selected + 1
	var tiempo = select_tiempo.selected + 1
	satisfaccion_calculada = (calidad + tiempo) / 2.0
	
	# Actualizar visualización
	label_resultado.text = "Satisfacción calculada: %.1f/5" % satisfaccion_calculada
	
	# Actualizar color según la satisfacción
	var color_resultado = Color(0.2, 0.2, 0.2)  # Gris por defecto
	
	if satisfaccion_calculada >= 4.0:
		color_resultado = Color(0.0, 0.6, 0.0)  # Verde para satisfacción alta
	elif satisfaccion_calculada >= 3.0:
		color_resultado = Color(0.9, 0.6, 0.0)  # Naranja para satisfacción media
	else:
		color_resultado = Color(0.8, 0.2, 0.2)  # Rojo para satisfacción baja
	
	label_resultado.add_theme_color_override("font_color", color_resultado)

func _on_validar_campos():
	"""Realiza validación en tiempo real de los campos"""
	# Esta función puede usarse para validaciones mientras el usuario escribe
	# Por ahora, solo verificamos si los campos requeridos están llenos
	var input_cliente = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputCliente
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	
	if input_cliente and select_producto:
		var cliente = input_cliente.text.strip_edges()
		var producto = select_producto.get_item_text(select_producto.selected)
		
		if cliente != "" and producto != "Seleccione...":
			# Calcular satisfacción automáticamente
			_on_calcular_satisfaccion()

func _on_limpiar_formulario():
	"""Limpia todos los campos del formulario"""
	print("🧹 Limpiando formulario...")
	
	var input_cliente = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputCliente
	var select_producto = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectProducto
	var input_fecha = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/InputFecha
	var select_calidad = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectCalidad
	var select_tiempo = $ContenedorPrincipal/VBoxContainer/FormContainer/GridForm/SelectTiempo
	var input_observaciones = $ContenedorPrincipal/VBoxContainer/FormContainer/InputObservaciones
	var label_resultado = $ContenedorPrincipal/VBoxContainer/PanelResultado/LabelResultado
	
	if input_cliente:
		input_cliente.text = ""
	if select_producto:
		select_producto.selected = 0
	if input_fecha:
		# Mostrar fecha actual
		mostrar_fecha_actual()
	if select_calidad:
		select_calidad.selected = 4  # 5 estrellas
	if select_tiempo:
		select_tiempo.selected = 4   # 5 estrellas
	if input_observaciones:
		input_observaciones.text = ""
	if label_resultado:
		label_resultado.text = "Satisfacción calculada: --/5"
		label_resultado.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	
	# Remover errores visuales
	if input_cliente:
		remover_error(input_cliente)
	if select_producto:
		remover_error(select_producto)
	if input_fecha:
		remover_error(input_fecha)
	
	print("✅ Formulario limpiado correctamente")
	
	# Enfocar primer campo
	if input_cliente:
		input_cliente.grab_focus()

func limpiar_campos():
	"""Función pública para limpiar todos los campos"""
	_on_limpiar_formulario()

func _on_volver_menu():
	"""Regresa al menú principal"""
	print("🏠 Volviendo al menú principal...")
	
	# Intentar cambiar a la escena del menú principal
	var escena_menu = "res://escenas/menu_principal.tscn"
	if ResourceLoader.exists(escena_menu):
		get_tree().change_scene_to_file(escena_menu)
	else:
		print("⚠️ No se encontró la escena del menú principal")
		mostrar_mensaje_error("Error de navegación", "No se pudo encontrar la escena del menú principal.")

func mostrar_mensaje_exito(titulo: String, mensaje: String):
	"""Muestra un mensaje de éxito"""
	print("✅ " + titulo + ": " + mensaje)
	
	var label_resultado = $ContenedorPrincipal/VBoxContainer/PanelResultado/LabelResultado
	if label_resultado:
		var mensaje_display = "✅ " + titulo + "\n" + mensaje
		label_resultado.text = mensaje_display
		label_resultado.add_theme_color_override("font_color", Color(0.0, 0.6, 0.0))

func mostrar_mensaje_error(titulo: String, mensaje: String):
	"""Muestra un mensaje de error"""
	print("❌ " + titulo + ": " + mensaje)
	
	var label_resultado = $ContenedorPrincipal/VBoxContainer/PanelResultado/LabelResultado
	if label_resultado:
		var mensaje_display = "❌ " + titulo + "\n" + mensaje
		label_resultado.text = mensaje_display
		label_resultado.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

func registrar_historial(tipo_evento: String, descripcion: String):
	"""Registra un evento en el historial"""
	if db == null:
		return
	
	# Solo registrar si la tabla de historial existe y tiene método insert
	if db.has_method("table_exists") and db.has_method("insert"):
		if db.table_exists("historial_usuarios"):
			var datos_historial = {
				"usuario_id": usuario_actual.get("id", 1),
				"tipo_evento": tipo_evento,
				"descripcion": descripcion,
				"ip_address": "127.0.0.1",  # En producción, obtener IP real
				"user_agent": "Godot 4.6"
			}
			
			var id_historial = db.insert("historial_usuarios", datos_historial)
			if id_historial > 0:
				print("📝 Evento registrado en historial: " + descripcion)
			else:
				print("⚠️ No se pudo registrar en historial")

func actualizar_estadisticas():
	"""Actualiza las estadísticas de satisfacción"""
	if db == null or not db.has_method("select_query"):
		return
	
	print("📊 Actualizando estadísticas...")
	
	# Ejemplo: Calcular promedio de satisfacción del día
	var sql_promedio = """
		SELECT 
			COUNT(*) as total_encuestas,
			AVG(satisfaccion_promedio) as promedio_dia,
			MIN(satisfaccion_promedio) as minima_dia,
			MAX(satisfaccion_promedio) as maxima_dia
		FROM encuestas_satisfaccion 
		WHERE DATE(fecha_registro) = DATE('now')
	"""
	
	var resultado = db.select_query(sql_promedio)
	if resultado and resultado.size() > 0:
		var stats = resultado[0]
		print("📈 Estadísticas del día:")
		print("   Total encuestas: " + str(stats.get("total_encuestas", 0)))
		print("   Promedio: " + str(stats.get("promedio_dia", 0.0)))
		print("   Mínima: " + str(stats.get("minima_dia", 0.0)))
		print("   Máxima: " + str(stats.get("maxima_dia", 0.0)))

# Funciones de utilidad adicionales
func obtener_estadisticas_cliente(cliente: String) -> Dictionary:
	"""Obtiene estadísticas históricas para un cliente específico"""
	if db == null or not db.has_method("select_query"):
		return {}
	
	var sql_estadisticas = """
		SELECT 
			cliente,
			COUNT(*) as total_encuestas,
			AVG(satisfaccion_promedio) as promedio_general,
			AVG(calidad) as promedio_calidad,
			AVG(tiempo_respuesta) as promedio_tiempo,
			MIN(fecha_aplicacion) as primera_encuesta,
			MAX(fecha_aplicacion) as ultima_encuesta
		FROM encuestas_satisfaccion 
		WHERE cliente LIKE ?
		GROUP BY cliente
	"""
	
	var resultado = db.select_query(sql_estadisticas, ["%" + cliente + "%"])
	if resultado and resultado.size() > 0:
		return resultado[0]
	
	return {}

func obtener_encuestas_recientes(limite: int = 10) -> Array:
	"""Obtiene las encuestas más recientes"""
	if db == null or not db.has_method("select_query"):
		return []
	
	var sql_recientes = """
		SELECT 
			codigo_encuesta,
			cliente,
			producto_servicio,
			fecha_aplicacion,
			satisfaccion_promedio,
			categoria_satisfaccion,
			fecha_registro
		FROM encuestas_satisfaccion 
		ORDER BY fecha_registro DESC 
		LIMIT ?
	"""
	
	var resultado = db.select_query(sql_recientes, [limite])
	return resultado if resultado else []

# Función para obtener resumen del día
func obtener_resumen_dia() -> Dictionary:
	"""Obtiene un resumen de las encuestas del día actual"""
	if db == null or not db.has_method("select_query"):
		return {}
	
	var sql_resumen = """
		SELECT 
			COUNT(*) as total,
			AVG(satisfaccion_promedio) as promedio,
			MIN(satisfaccion_promedio) as minima,
			MAX(satisfaccion_promedio) as maxima,
			SUM(CASE WHEN satisfaccion_promedio >= 4.0 THEN 1 ELSE 0 END) as positivas,
			SUM(CASE WHEN satisfaccion_promedio < 3.0 THEN 1 ELSE 0 END) as negativas
		FROM encuestas_satisfaccion 
		WHERE DATE(fecha_registro) = DATE('now')
	"""
	
	var resultado = db.select_query(sql_resumen)
	if resultado and resultado.size() > 0:
		return resultado[0]
	
	return {}

# Señales del teclado
func _input(event: InputEvent):
	"""Maneja eventos del teclado"""
	if event is InputEventKey and event.pressed:
		# Ctrl+S para guardar
		if event.keycode == KEY_S and (event.ctrl_pressed or event.meta_pressed):
			_on_guardar_encuesta()
			get_viewport().set_input_as_handled()
		
		# Ctrl+L para limpiar
		elif event.keycode == KEY_L and (event.ctrl_pressed or event.meta_pressed):
			_on_limpiar_formulario()
			get_viewport().set_input_as_handled()
		
		# Escape para salir
		elif event.keycode == KEY_ESCAPE:
			_on_volver_menu()
			get_viewport().set_input_as_handled()

# Función para mostrar ayuda contextual
func mostrar_ayuda_campo(campo: String):
	"""Muestra ayuda contextual para un campo específico"""
	var ayudas = {
		"cliente": "Ingrese el nombre completo del cliente tal como aparece en el sistema.",
		"producto_servicio": "Seleccione el producto o servicio específico que el cliente está evaluando.",
		"fecha": "Ingrese la fecha en que se aplicó la encuesta en formato DD/MM/AAAA.",
		"calidad": "Califique la calidad percibida por el cliente de 1 (muy mala) a 5 (excelente).",
		"tiempo_respuesta": "Califique el tiempo de respuesta del servicio de 1 (muy lento) a 5 (muy rápido).",
		"observaciones": "Capture cualquier comentario, sugerencia o queja específica del cliente."
	}
	
	if campo in ayudas:
		print("ℹ️ Ayuda para " + campo + ": " + ayudas[campo])

# Función para autocompletar cliente
func buscar_cliente_sugerencias(parte_nombre: String) -> Array:
	"""Busca sugerencias de clientes basadas en entrada parcial"""
	if db == null or not db.has_method("select_query") or parte_nombre.length() < 2:
		return []
	
	var sql_sugerencias = """
		SELECT DISTINCT cliente 
		FROM encuestas_satisfaccion 
		WHERE cliente LIKE ? 
		ORDER BY cliente 
		LIMIT 10
	"""
	
	var resultado = db.select_query(sql_sugerencias, ["%" + parte_nombre + "%"])
	var sugerencias = []
	
	if resultado:
		for fila in resultado:
			sugerencias.append(fila.get("cliente", ""))
	
	return sugerencias

# Función para verificar duplicados
func verificar_duplicado_encuesta() -> bool:
	"""Verifica si ya existe una encuesta similar"""
	if db == null or not db.has_method("select_query"):
		return false
	
	var sql_verificacion = """
		SELECT COUNT(*) as total 
		FROM encuestas_satisfaccion 
		WHERE cliente = ? 
		AND producto_servicio = ? 
		AND fecha_aplicacion = ?
	"""
	
	var resultado = db.select_query(sql_verificacion, [
		datos_encuesta.get("cliente", ""),
		datos_encuesta.get("producto_servicio", ""),
		datos_encuesta.get("fecha_aplicacion", "")
	])
	
	if resultado and resultado.size() > 0:
		return int(resultado[0].get("total", 0)) > 0
	
	return false

# Finalizar y limpiar cuando se cierra
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Limpieza antes de eliminar
		print("🧹 Limpiando recursos del formulario de encuestas...")

# Función para verificar si la base de datos está disponible
func base_datos_disponible() -> bool:
	return db != null and db.has_method("query")
