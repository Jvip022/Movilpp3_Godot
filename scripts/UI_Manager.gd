extends Node
# Manager para controlar la interfaz del sistema de quejas

var escenas_actuales = {}
var gestor_quejas: GestorQuejas

func _ready():
	gestor_quejas = GestorQuejas.new()
	add_child(gestor_quejas)

func mostrar_panel_registro():
	var registro_scene = load("res://scenes/sistema_quejas/RegistrarQueja.tscn")
	var registro_instance = registro_scene.instantiate()
	add_child(registro_instance)

func actualizar_dashboard():
	# Actualizar estadísticas en tiempo real
	pass

func mostrar_detalle_queja(id_queja: int):
	var detalle_scene = load("res://scenes/sistema_quejas/DetalleQueja.tscn")
	var detalle_instance = detalle_scene.instantiate()
	detalle_instance.cargar_queja(id_queja)
	add_child(detalle_instance)
