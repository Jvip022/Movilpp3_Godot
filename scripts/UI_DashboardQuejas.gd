# UI_DashboardQuejas.gd - VERSIÓN CORREGIDA
extends Control

@onready var metricas = $PanelSuperior/Metricas
@onready var grafico_tendencias = $PanelCentral/GraficoTendencias
@onready var tabla_recientes = $PanelInferior/TablaRecientes
@onready var panel_superior = $PanelSuperior
@onready var panel_inferior = $PanelInferior
var bd = Bd.db

func _ready():
	# Verificar que los paneles existan antes de aplicar estilos
	if panel_superior:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.179, 0.581, 0.534, 0.8)
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.2, 0.2, 0.2)
		panel_superior.add_theme_stylebox_override("panel", style_box)
	else:
		push_warning("PanelSuperior no encontrado en la escena")

	if panel_inferior:
		var style_box_inferior = StyleBoxFlat.new()
		style_box_inferior.bg_color = Color(0.179, 0.581, 0.534, 0.8)
		style_box_inferior.border_width_bottom = 2
		style_box_inferior.border_color = Color(0.2, 0.2, 0.2)
		panel_inferior.add_theme_stylebox_override("panel", style_box_inferior)
	else:
		push_warning("PanelInferior no encontrado en la escena")
	
	# Cargar datos
	cargar_metricas_en_tiempo_real()
	cargar_grafico_tendencias()
	cargar_quejas_recientes()
	
	# Actualizar cada 30 segundos
	var timer = Timer.new()
	timer.wait_time = 30
	timer.autostart = true
	timer.timeout.connect(cargar_metricas_en_tiempo_real)
	add_child(timer)

func cargar_metricas_en_tiempo_real():
	var hoy = Time.get_date_string_from_system()
	
	# Obtener resultados como array
	var resultados = Bd.query("""
		SELECT
			COUNT(*) as total_hoy,
			COUNT(CASE WHEN estado = 'recibida' THEN 1 END) as pendientes,
			COUNT(CASE WHEN estado = 'resuelta' AND fecha_cierre >= ? THEN 1 END) as resueltas_hoy,
			COUNT(CASE WHEN prioridad = 'urgente' AND estado NOT IN ('resuelta', 'cerrada') THEN 1 END) as urgentes,
			AVG(tiempo_respuesta_horas) as tiempo_promedio,
			SUM(compensacion_otorgada) as costo_total_hoy
		FROM quejas_reclamaciones
		WHERE date(fecha_recepcion) = date(?)
	""", [hoy, hoy])
	
	# VERIFICAR SI HAY RESULTADOS
	if resultados is Array and resultados.size() > 0:
		var datos = resultados[0]
		
		# Usar valores por defecto si son nulos
		var total_hoy = datos.get("total_hoy", 0)
		var pendientes = datos.get("pendientes", 0)
		var tiempo_promedio = datos.get("tiempo_promedio", 0.0)
		if tiempo_promedio == null:
			tiempo_promedio = 0.0
		var costo_total = datos.get("costo_total_hoy", 0.0)
		if costo_total == null:
			costo_total = 0.0
		
		# Actualizar UI - Verificar que los nodos existan
		if metricas:
			if metricas.has_node("TotalHoy"):
				metricas.get_node("TotalHoy").text = "Total hoy: " + str(total_hoy)
			if metricas.has_node("Pendientes"):
				metricas.get_node("Pendientes").text = "Pendientes: " + str(pendientes)
			if metricas.has_node("TiempoPromedio"):
				metricas.get_node("TiempoPromedio").text = "Tiempo respuesta: " + str(snapped(tiempo_promedio, 0.1)) + "h"
			if metricas.has_node("CostoHoy"):
				metricas.get_node("CostoHoy").text = "Costo hoy: $" + str(snapped(costo_total, 0.01))
	else:
		# Si no hay resultados, mostrar valores por defecto
		print("No se encontraron datos o hubo un error")
		if metricas:
			if metricas.has_node("TotalHoy"):
				metricas.get_node("TotalHoy").text = "Total hoy: 0"
			if metricas.has_node("Pendientes"):
				metricas.get_node("Pendientes").text = "Pendientes: 0"
			if metricas.has_node("TiempoPromedio"):
				metricas.get_node("TiempoPromedio").text = "Tiempo respuesta: 0.0h"
			if metricas.has_node("CostoHoy"):
				metricas.get_node("CostoHoy").text = "Costo hoy: $0.00"

func cargar_grafico_tendencias():
	if not grafico_tendencias:
		push_warning("GraficoTendencias no encontrado")
		return
	
	var datos_mensuales = Bd.query("""
		SELECT
			strftime('%Y-%m', fecha_recepcion) as mes,
			COUNT(*) as total,
			COUNT(CASE WHEN estado = 'resuelta' THEN 1 END) as resueltas,
			SUM(compensacion_otorgada) as costo
		FROM quejas_reclamaciones
		WHERE fecha_recepcion >= date('now', '-6 months')
		GROUP BY strftime('%Y-%m', fecha_recepcion)
		ORDER BY mes
	""")
	
	# Verificar que sea un array
	if datos_mensuales is Array:
		grafico_tendencias.dibujar_grafico(datos_mensuales)
	else:
		print("Error al cargar datos para gráfico")
		grafico_tendencias.dibujar_grafico([])

func cargar_quejas_recientes():
	if not tabla_recientes:
		push_warning("TablaRecientes no encontrado")
		return
	
	# Limpiar tabla primero
	for child in tabla_recientes.get_children():
		child.queue_free()
	
	var quejas = Bd.query("""
		SELECT
			numero_caso,
			asunto,
			nombres || ' ' || apellidos as reclamante,
			prioridad,
			estado,
			julianday('now') - julianday(fecha_recepcion) as dias_abierto
		FROM quejas_reclamaciones
		WHERE estado NOT IN ('resuelta', 'archivada')
		ORDER BY fecha_recepcion DESC
		LIMIT 10
	""")
	
	# Verificar que sea un array
	if quejas is Array:
		for queja in quejas:
			var fila = crear_fila_queja(queja)
			tabla_recientes.add_child(fila)
	else:
		print("Error al cargar quejas recientes")

func crear_fila_queja(queja: Dictionary) -> Control:
	# Crea un contenedor para la fila
	var fila = HBoxContainer.new()
	fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Usar get() para evitar errores si faltan claves
	var etiquetas = [
		queja.get("numero_caso", "N/A"),
		queja.get("asunto", "Sin asunto"),
		queja.get("reclamante", "Desconocido"),
		queja.get("prioridad", "normal"),
		queja.get("estado", "desconocido"),
		str(queja.get("dias_abierto", 0))
	]
	
	for texto in etiquetas:
		var label = Label.new()
		label.text = str(texto)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		
		# Usar get() aquí también
		match queja.get("prioridad", "normal"):
			"urgente":
				label.add_theme_color_override("font_color", Color.RED)
			"alta":
				label.add_theme_color_override("font_color", Color.ORANGE)
		
		fila.add_child(label)
	
	return fila
