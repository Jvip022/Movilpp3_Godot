
extends Control

# Colores para las líneas del gráfico
var COLOR_TOTAL = Color(0.2, 0.6, 1.0)     # Azul
var COLOR_RESUELTAS = Color(0.4, 0.8, 0.4)  # Verde
var COLOR_COSTO = Color(0.9, 0.3, 0.3)      # Rojo

var datos: Array = []

func dibujar_grafico(datos_mensuales: Array) -> void:
	# Almacenar los datos y solicitar redibujado
	datos = datos_mensuales
	queue_redraw()

func _draw() -> void:
	# Si no hay datos, no dibujar
	if datos.size() == 0:
		dibujar_mensaje_sin_datos()
		return
	
	# Configuración del gráfico
	var margen_x = 50.0
	var margen_y = 30.0
	var ancho_util = size.x - margen_x * 2
	var alto_util = size.y - margen_y * 2
	
	# Encontrar valores máximos para escalar
	var max_total = 0.0
	var max_costo = 0.0
	for dato in datos:
		max_total = max(max_total, float(dato.get("total", 0)))
		max_costo = max(max_costo, float(dato.get("costo", 0.0)))
	
	# Dibujar ejes
	dibujar_ejes(margen_x, margen_y, ancho_util, alto_util)
	
	# Dibujar líneas del gráfico
	dibujar_linea_grafico(margen_x, margen_y, ancho_util, alto_util, "total", max_total, COLOR_TOTAL)
	dibujar_linea_grafico(margen_x, margen_y, ancho_util, alto_util, "resueltas", max_total, COLOR_RESUELTAS)
	
	# Dibujar etiquetas
	dibujar_etiquetas(margen_x, margen_y, ancho_util, alto_util)
	
	# Dibujar leyenda
	dibujar_leyenda()

func dibujar_ejes(margen_x: float, margen_y: float, ancho: float, alto: float) -> void:
	# Eje X
	draw_line(
		Vector2(margen_x, margen_y + alto),
		Vector2(margen_x + ancho, margen_y + alto),
		Color(0.8, 0.8, 0.8),
		2.0
	)
	
	# Eje Y
	draw_line(
		Vector2(margen_x, margen_y),
		Vector2(margen_x, margen_y + alto),
		Color(0.8, 0.8, 0.8),
		2.0
	)

func dibujar_linea_grafico(margen_x: float, margen_y: float, ancho: float, alto: float, 
						  campo: String, max_valor: float, color: Color) -> void:
	if datos.size() < 2:
		return
	
	var puntos: PackedVector2Array = []
	
	for i in range(datos.size()):
		var dato = datos[i]
		var valor = float(dato.get(campo, 0.0))
		
		# Calcular posición X (distribuida uniformemente)
		var x = margen_x + (ancho / (datos.size() - 1)) * i
		
		# Calcular posición Y (invertida porque Y=0 es arriba)
		var y = margen_y + alto - (valor / max_valor * alto) if max_valor > 0 else margen_y + alto
		
		puntos.append(Vector2(x, y))
		
		# Dibujar punto
		draw_circle(Vector2(x, y), 4, color)
	
	# Dibujar línea conectando los puntos
	if puntos.size() > 1:
		for i in range(puntos.size() - 1):
			draw_line(puntos[i], puntos[i+1], color, 2.0)

func dibujar_etiquetas(margen_x: float, margen_y: float, ancho: float, alto: float) -> void:
	# Etiquetas de meses en eje X
	for i in range(datos.size()):
		var dato = datos[i]
		var mes = dato.get("mes", "??")
		# Extraer solo mes-año (ej: "2024-01" → "01/24")
		var mes_corto = mes.substr(5, 2) + "/" + mes.substr(2, 2)
		
		var x = margen_x + (ancho / (datos.size() - 1)) * i
		var y = margen_y + alto + 15
		
		draw_string(
			get_theme_default_font(),
			Vector2(x - 15, y),
			mes_corto,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color.WHITE
		)

func dibujar_leyenda() -> void:
	var leyendas = [
		{"nombre": "Total", "color": COLOR_TOTAL},
		{"nombre": "Resueltas", "color": COLOR_RESUELTAS},
		{"nombre": "Costo", "color": COLOR_COSTO}
	]
	
	var x = 10.0
	var y = 10.0
	
	for leyenda in leyendas:
		# Caja de color
		draw_rect(Rect2(x, y, 20, 10), leyenda["color"])
		# Texto
		draw_string(
			get_theme_default_font(),
			Vector2(x + 25, y + 10),
			leyenda["nombre"],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color.WHITE
		)
		y += 20

func dibujar_mensaje_sin_datos() -> void:
	var mensaje = "No hay datos para mostrar"
	var ancho_texto = get_theme_default_font().get_string_size(mensaje).x
	
	draw_string(
		get_theme_default_font(),
		Vector2((size.x - ancho_texto) / 2, size.y / 2),
		mensaje,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.6, 0.6, 0.6)
	)
