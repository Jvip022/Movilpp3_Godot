extends Popup

func _ready():
	# Conectar botones - RUTAS CORREGIDAS
	$VBoxContainer/HBoxContainer/BtnGuardarTarea.connect("pressed", get_parent()._on_dialogo_tareas_guardar)
	$VBoxContainer/HBoxContainer/BtnCancelar.connect("pressed", self.hide)

func _on_InputTareaFechaLimite_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# Aquí puedes añadir un selector de fecha si lo necesitas
		# Por ahora, solo muestra un mensaje
		print("Seleccionar fecha para tarea")
		
func _on_Calendario_date_selected(date):
	var fecha_str = "%02d/%02d/%04d" % [date.day, date.month, date.year]
	$VBoxContainer/InputTareaFechaLimite.text = fecha_str
	$Calendario.hide()
