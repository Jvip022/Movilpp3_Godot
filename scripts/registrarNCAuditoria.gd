extends Control

class_name RegistrarNCAuditoriaScene

# Variables del formulario (actualizadas para la nueva estructura)
@onready var codigo_nc_label = $ContentContainer/FormContainer/CodigoNCLabel
@onready var tipo_nc_dropdown = $ContentContainer/FormContainer/GridContainer/TipoNCDropdown
@onready var descripcion_text = $ContentContainer/FormContainer/DescripcionTextEdit
@onready var auditoria_dropdown = $ContentContainer/FormContainer/GridContainer/AuditoriaDropdown
@onready var severidad_dropdown = $ContentContainer/FormContainer/GridContainer/SeveridadDropdown
@onready var registrar_button = $ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar
@onready var status_label = $StatusLabel
@onready var notificacion_panel = $NotificacionPanel
@onready var btn_regresar = $HeaderPanel/HeaderHBox/BtnRegresar

# Diálogos de la nueva estructura
@onready var mensaje_exito = $MensajeExito
@onready var mensaje_error = $MensajeError
@onready var validacion_campos = $ValidacionCampos

# Prefijos para codificación según tipo
var prefijos_codigo = {
	"INTERNA": "NC-AUD-INT",
	"EXTERNA": "NC-AUD-EXT",
	"PROVEEDOR": "NC-AUD-PRV"
}

var contador_nc = 0
var auditor_autenticado = false

func _ready():
	# Simular autenticación previa del auditor
	auditor_autenticado = true
	setup_ui()
	
func setup_ui():
	# Configurar opciones de tipo de NC
	tipo_nc_dropdown.add_item("INTERNA", 0)
	tipo_nc_dropdown.add_item("EXTERNA", 1)
	tipo_nc_dropdown.add_item("PROVEEDOR", 2)
	
	# Configurar opciones de auditoría
	auditoria_dropdown.add_item("Auditoría Interna - Procesos 2024", 0)
	auditoria_dropdown.add_item("Auditoría Externa - Certificación ISO", 1)
	auditoria_dropdown.add_item("Auditoría Proveedor - Logística", 2)
	
	# Configurar severidad
	severidad_dropdown.add_item("Crítica", 0)
	severidad_dropdown.add_item("Mayor", 1)
	severidad_dropdown.add_item("Menor", 2)
	severidad_dropdown.add_item("Observación", 3)
	
	# Conectar señales
	registrar_button.connect("pressed", Callable(self, "_on_registrar_pressed"))
	btn_regresar.connect("pressed", Callable(self, "_on_regresar_pressed"))
	tipo_nc_dropdown.connect("item_selected", Callable(self, "_on_tipo_nc_changed"))
	auditoria_dropdown.connect("item_selected", Callable(self, "_on_auditoria_changed"))
	
	# Generar código inicial
	_generar_codigo_nc()

func _generar_codigo_nc():
	contador_nc += 1
	var prefijo = prefijos_codigo[tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected)]
	var codigo = "%s-%04d-%s" % [prefijo, contador_nc, Time.get_date_string_from_system()]
	codigo_nc_label.text = "Código NC: " + codigo
	return codigo

func _on_tipo_nc_changed(_index):
	_generar_codigo_nc()

func _on_auditoria_changed(index):
	# Actualizar tipo según auditoría seleccionada
	match index:
		0: # Interna
			tipo_nc_dropdown.select(0)
		1: # Externa
			tipo_nc_dropdown.select(1)
		2: # Proveedor
			tipo_nc_dropdown.select(2)

func _on_regresar_pressed():
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_registrar_pressed():
	if not auditor_autenticado:
		mostrar_error("Auditor no autenticado")
		return
		
	# Validar campos obligatorios
	# CORRECCIÓN: usar strip_edges() en lugar de strip() que no existe en Godot 4
	if descripcion_text.text.strip_edges().is_empty():
		validacion_campos.popup_centered()
		return
	
	# Obtener datos del formulario
	var codigo = codigo_nc_label.text.replace("Código NC: ", "")
	var tipo = tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected)
	var descripcion = descripcion_text.text
	var auditoria = auditoria_dropdown.get_item_text(auditoria_dropdown.selected)
	var severidad = severidad_dropdown.get_item_text(severidad_dropdown.selected)
	
	# Registrar NC
	var resultado = registrar_no_conformidad(codigo, tipo, descripcion, auditoria, severidad)
	
	if resultado:
		mensaje_exito.popup_centered()
		notificar_partes_interesadas(codigo, tipo, severidad)
		_limpiar_formulario()
		_generar_codigo_nc()
	else:
		mensaje_error.popup_centered()

func registrar_no_conformidad(codigo, tipo, descripcion, auditoria, severidad):
	# Simular registro en base de datos
	print("Registrando NC Auditoría:")
	print("Código: ", codigo)
	print("Tipo: ", tipo)
	print("Auditoría: ", auditoria)
	print("Severidad: ", severidad)
	print("Descripción: ", descripcion)
	
	# Aquí iría la lógica real de conexión a base de datos
	# Por ahora simulamos éxito
	return true

func notificar_partes_interesadas(codigo, _tipo, _severidad):
	# Simular notificación
	print("Notificando partes interesadas...")
	
	# Mostrar panel de notificación
	notificacion_panel.visible = true
	notificacion_panel.get_node("MensajeLabel").text = "Notificaciones enviadas para NC: " + codigo
	
	# Ocultar después de 3 segundos
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_ocultar_notificacion)

func _ocultar_notificacion():
	notificacion_panel.visible = false

func mostrar_exito(mensaje):
	status_label.text = mensaje
	status_label.modulate = Color.GREEN
	status_label.visible = true

func mostrar_error(mensaje):
	status_label.text = "ERROR: " + mensaje
	status_label.modulate = Color.RED
	status_label.visible = true

func _limpiar_formulario():
	descripcion_text.text = ""
	severidad_dropdown.select(0)

# Función para exportar datos (simulación)
func exportar_datos_nc():
	return {
		"codigo": codigo_nc_label.text.replace("Código NC: ", ""),
		"tipo": tipo_nc_dropdown.get_item_text(tipo_nc_dropdown.selected),
		"descripcion": descripcion_text.text,
		"auditoria": auditoria_dropdown.get_item_text(auditoria_dropdown.selected),
		"severidad": severidad_dropdown.get_item_text(severidad_dropdown.selected),
		"fecha_registro": Time.get_datetime_string_from_system()
	}
