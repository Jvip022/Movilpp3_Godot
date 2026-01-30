# UI_DashboardQuejas.gd
extends Control

@onready var metricas = $PanelSuperior/Metricas
@onready var grafico_tendencias = $PanelCentral/GraficoTendencias
@onready var tabla_recientes = $PanelInferior/TablaRecientes
var bd = Bd.db

func _ready():
	cargar_metricas_en_tiempo_real()
	cargar_grafico_tendencias()
	cargar_quejas_recientes()
	
	# Actualizar cada 30 segundos
	var timer = Timer.new()
	timer.wait_time = 30
	timer.autostart = true
	timer.connect("timeout", cargar_metricas_en_tiempo_real)
	add_child(timer)

func cargar_metricas_en_tiempo_real():
	var hoy = Time.get_date_string_from_system()
	
	var datos = Bd.query("""
		SELECT
			COUNT(*) as total_hoy,
			COUNT(CASE WHEN estado = 'recibida' THEN 1 END) as pendientes,
			COUNT(CASE WHEN estado = 'resuelta' AND fecha_cierre >= ? THEN 1 END) as resueltas_hoy,
			COUNT(CASE WHEN prioridad = 'urgente' AND estado NOT IN ('resuelta', 'cerrada') THEN 1 END) as urgentes,
			AVG(tiempo_respuesta_horas) as tiempo_promedio,
			SUM(compensacion_otorgada) as costo_total_hoy
		FROM quejas_reclamaciones
		WHERE date(fecha_recepcion) = date(?)
	""", [hoy, hoy])[0]
	
	# Actualizar UI
	metricas.get_node("TotalHoy").text = "Total hoy: " + str(datos["total_hoy"])
	metricas.get_node("Pendientes").text = "Pendientes: " + str(datos["pendientes"])
	metricas.get_node("TiempoPromedio").text = "Tiempo respuesta: " + str(stepify(datos["tiempo_promedio"], 0.1)) + "h"
	metricas.get_node("CostoHoy").text = "Costo hoy: $" + str(stepify(datos["costo_total_hoy"], 0.01))

func cargar_grafico_tendencias():
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
	
	grafico_tendencias.dibujar_grafico(datos_mensuales)

func cargar_quejas_recientes():
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
	
	for queja in quejas:
		var fila = crear_fila_queja(queja)
		tabla_recientes.add_child(fila)
