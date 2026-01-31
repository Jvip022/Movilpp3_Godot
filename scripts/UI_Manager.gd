extends Control

# Referencias a nodos de interfaz
@onready var tab_container = $MainPanel/MainTabContainer
@onready var lista_quejas = $MainPanel/MainTabContainer/Seguimiento/ListaQuejas
@onready var txt_buscar = $MainPanel/MainTabContainer/Seguimiento/FiltrosPanel/TxtBuscar
@onready var stat_total = $MainPanel/MainTabContainer/Analiticas/StatsGrid/StatTotal/LblTotal

func actualizar_lista_quejas(filtro: String = ""):
	# Limpiar lista
	lista_quejas.clear()
	
	# Agregar columnas si no existen
	if lista_quejas.get_column_count() == 0:
		lista_quejas.set_column_titles_visible(true)
		lista_quejas.set_column_title(0, "Caso")
		lista_quejas.set_column_title(1, "Cliente")
		lista_quejas.set_column_title(2, "Asunto")
		lista_quejas.set_column_title(3, "Estado")
		lista_quejas.set_column_title(4, "Prioridad")
		lista_quejas.set_column_title(5, "Fecha")
	
	# Obtener quejas de la base de datos
	var quejas = Bd.query("SELECT * FROM quejas_reclamaciones WHERE estado != 'archivada'")
	
	for queja in quejas:
		var item = lista_quejas.create_item()
		item.set_text(0, queja.get("numero_caso", "N/A"))
		item.set_text(1, queja.get("nombres", ""))
		item.set_text(2, queja.get("asunto", ""))
		item.set_text(3, queja.get("estado", ""))
		item.set_text(4, queja.get("prioridad", ""))
		item.set_text(5, queja.get("fecha_recepcion", ""))

func actualizar_estadisticas():
	var total = Bd.query("SELECT COUNT(*) as total FROM quejas_reclamaciones")[0]["total"]
	var pendientes = Bd.query("SELECT COUNT(*) as total FROM quejas_reclamaciones WHERE estado IN ('recibida', 'investigando')")[0]["total"]
	
	stat_total.text = "Total Quejas: " + str(total)
	# Actualizar otros stats...

func mostrar_detalle_queja(id_queja: int):
	# Implementar lógica para mostrar detalles
	pass

func _on_buscar_text_changed(new_text: String):
	actualizar_lista_quejas(new_text)
