extends VBoxContainer

# Señales que emite el formulario
signal queja_registrada(datos_queja: Dictionary)

# Referencias a los nodos del formulario
@onready var opt_tipo_caso: OptionButton = $FormContainer/FormGrid/OptTipoCaso
@onready var txt_nombres: LineEdit = $FormContainer/FormGrid/TxtNombres
@onready var txt_identificacion: LineEdit = $FormContainer/FormGrid/TxtIdentificacion
@onready var txt_telefono: LineEdit = $FormContainer/FormGrid/TxtTelefono
@onready var txt_email: LineEdit = $FormContainer/FormGrid/TxtEmail
@onready var txt_asunto: LineEdit = $FormContainer/FormGrid/TxtAsunto
@onready var txt_descripcion: TextEdit = $FormContainer/FormGrid/TxtDescripcion
@onready var spin_monto: SpinBox = $FormContainer/FormGrid/SpinMonto
@onready var opt_prioridad: OptionButton = $FormContainer/FormGrid/OptPrioridad
@onready var btn_registrar: Button = $BtnRegistrar

func _ready():
	# Conectar señal del botón
	btn_registrar.pressed.connect(_on_btn_registrar_pressed)
	
	# Configurar validación en tiempo real
	txt_nombres.text_changed.connect(_validar_formulario)
	txt_asunto.text_changed.connect(_validar_formulario)
	txt_descripcion.text_changed.connect(_validar_formulario)
	
	# Validar inicialmente
	_validar_formulario()

func _validar_formulario():
	# Validar campos obligatorios
	var campos_validos = (
		txt_nombres.text.strip_edges().length() > 0 and
		txt_asunto.text.strip_edges().length() > 0 and
		txt_descripcion.text.strip_edges().length() > 10
	)
	
	btn_registrar.disabled = not campos_validos
	
	if not campos_validos:
		btn_registrar.tooltip_text = "Complete los campos obligatorios"
	else:
		btn_registrar.tooltip_text = "Listo para registrar"

func _on_btn_registrar_pressed():
	# Recoger datos del formulario
	var datos_queja = {
		"tipo_caso": opt_tipo_caso.get_item_text(opt_tipo_caso.selected),
		"tipo_reclamante": "cliente",  # Podría ser otro OptionButton
		"nombres": txt_nombres.text.strip_edges(),
		"identificacion": txt_identificacion.text.strip_edges(),
		"telefono": txt_telefono.text.strip_edges(),
		"email": txt_email.text.strip_edges(),
		"asunto": txt_asunto.text.strip_edges(),
		"descripcion_detallada": txt_descripcion.text.strip_edges(),
		"monto_reclamado": spin_monto.value,
		"prioridad": opt_prioridad.get_item_text(opt_prioridad.selected).to_lower(),
		"canal_entrada": "sistema_web",  # Puedes agregar otro control
		"recibido_por": "operador_web",
		"categoria": "calidad_producto"  # Podría ser otro OptionButton
	}
	
	# Emitir señal con los datos
	emit_signal("queja_registrada", datos_queja)
	
	# Limpiar formulario
	_limpiar_formulario()
	
	# Mostrar mensaje de confirmación
	_mostrar_mensaje_exito()

func _limpiar_formulario():
	txt_nombres.clear()
	txt_identificacion.clear()
	txt_telefono.clear()
	txt_email.clear()
	txt_asunto.clear()
	txt_descripcion.clear()
	spin_monto.value = 0
	opt_tipo_caso.selected = 0
	opt_prioridad.selected = 1  # Media por defecto

func _mostrar_mensaje_exito():
	# Crear un popup de confirmación temporal
	var mensaje = AcceptDialog.new()
	mensaje.title = "Registro Exitoso"
	mensaje.dialog_text = "La queja ha sido registrada exitosamente.\nSe ha generado un número de caso y el equipo correspondiente ha sido notificado."
	mensaje.ok_button_text = "Aceptar"
	
	add_child(mensaje)
	mensaje.popup_centered()
	
	# Auto-eliminar después de cerrar
	mensaje.confirmed.connect(func(): mensaje.queue_free())

# Función para cargar datos existentes (para edición)
func cargar_datos_queja(datos: Dictionary):
	if datos.has("tipo_caso"):
		# Buscar y seleccionar el tipo de caso
		for i in range(opt_tipo_caso.item_count):
			if opt_tipo_caso.get_item_text(i) == datos["tipo_caso"]:
				opt_tipo_caso.selected = i
				break
	
	txt_nombres.text = datos.get("nombres", "")
	txt_identificacion.text = datos.get("identificacion", "")
	txt_telefono.text = datos.get("telefono", "")
	txt_email.text = datos.get("email", "")
	txt_asunto.text = datos.get("asunto", "")
	txt_descripcion.text = datos.get("descripcion_detallada", "")
	spin_monto.value = datos.get("monto_reclamado", 0)
	
	# Prioridad
	var prioridad = datos.get("prioridad", "media")
	for i in range(opt_prioridad.item_count):
		if opt_prioridad.get_item_text(i).to_lower() == prioridad:
			opt_prioridad.selected = i
			break
