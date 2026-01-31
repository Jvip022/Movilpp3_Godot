# InterfaceManager.gd
extends Control
class_name InterfaceManager

# Señales
signal queja_registrada(datos: Dictionary)
signal configuracion_guardada(config: Dictionary)

# Referencias a nodos (se llenarán en _ready)
var btn_registrar: Button
var lista_quejas: Tree
var lbl_total: Label
var lbl_pendientes: Label
var txt_buscar: LineEdit

func _ready():
	# Inicializar referencias
	btn_registrar = get_node_or_null("MainPanel/MainTabContainer/Registro/BtnRegistrar")
	lista_quejas = get_node_or_null("MainPanel/MainTabContainer/Seguimiento/ListaQuejas")
	lbl_total = get_node_or_null("MainPanel/MainTabContainer/Analiticas/StatsGrid/StatTotal/LblTotal")
	lbl_pendientes = get_node_or_null("MainPanel/MainTabContainer/Analiticas/StatsGrid/StatPendientes/LblPendientes")
	txt_buscar = get_node_or_null("MainPanel/MainTabContainer/Seguimiento/FiltrosPanel/TxtBuscar")
	
	# Conectar señales
	if btn_registrar:
		btn_registrar.pressed.connect(_on_btn_registrar_pressed)

func _on_btn_registrar_pressed():
	# Emitir señal con datos de ejemplo (aquí deberías obtener datos del formulario)
	emit_signal("queja_registrada", {
		"tipo_caso": "queja",
		"nombres": "Cliente",
		"asunto": "Asunto de ejemplo"
	})

func actualizar_lista_quejas(filtro: String = ""):
	print("Actualizando lista de quejas con filtro: ", filtro)
	if lista_quejas:
		lista_quejas.clear()

func actualizar_estadisticas():
	print("Actualizando estadísticas")
	if lbl_total:
		lbl_total.text = "Total Quejas: 0"
	if lbl_pendientes:
		lbl_pendientes.text = "Pendientes: 0"
