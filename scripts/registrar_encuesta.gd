extends Control

func _ready():
	# Conectar botones
	$ContenedorPrincipal/BtnGuardar.connect("pressed", _on_guardar_encuesta)
	$ContenedorPrincipal/BtnLimpiar.connect("pressed", _on_limpiar_formulario)
	$ContenedorPrincipal/BtnVolverMenu.connect("pressed", _on_volver_menu)
	
	# Conectar cambios en los selectores para calcular satisfacción en tiempo real
	$ContenedorPrincipal/FormContainer/GridForm/SelectCalidad.connect("item_selected", _on_calcular_satisfaccion)
	$ContenedorPrincipal/FormContainer/GridForm/SelectTiempo.connect("item_selected", _on_calcular_satisfaccion)

func _on_guardar_encuesta():
	# Validar campos obligatorios
	var cliente = $ContenedorPrincipal/FormContainer/GridForm/InputCliente.text
	var producto = $ContenedorPrincipal/FormContainer/GridForm/SelectProducto.get_item_text(
		$ContenedorPrincipal/FormContainer/GridForm/SelectProducto.selected
	)
	
	if cliente.strip_edges() == "":
		mostrar_error("Debe ingresar el nombre del cliente")
		return
	
	if producto == "Seleccione...":
		mostrar_error("Debe seleccionar un producto/servicio")
		return
	
	# Obtener valores
	var fecha = $ContenedorPrincipal/FormContainer/GridForm/InputFecha.text
	var calidad = $ContenedorPrincipal/FormContainer/GridForm/SelectCalidad.selected + 1
	var tiempo = $ContenedorPrincipal/FormContainer/GridForm/SelectTiempo.selected + 1
	var observaciones = $ContenedorPrincipal/FormContainer/InputObservaciones.text
	
	# Calcular satisfacción promedio
	var satisfaccion = (calidad + tiempo) / 2.0
	
	print("=== ENCUESTA REGISTRADA ===")
	print("Cliente: ", cliente)
	print("Producto: ", producto)
	print("Fecha: ", fecha)
	print("Calidad: ", calidad)
	print("Tiempo respuesta: ", tiempo)
	print("Satisfacción: ", satisfaccion)
	print("Observaciones: ", observaciones)
	
	mostrar_mensaje("Éxito", "Encuesta registrada correctamente. Satisfacción: %.1f/5" % satisfaccion)
	
	# Aquí iría el código para guardar en base de datos

func _on_calcular_satisfaccion(_index = 0):
	var calidad = $ContenedorPrincipal/FormContainer/GridForm/SelectCalidad.selected + 1
	var tiempo = $ContenedorPrincipal/FormContainer/GridForm/SelectTiempo.selected + 1
	var satisfaccion = (calidad + tiempo) / 2.0
	
	$ContenedorPrincipal/FormContainer/PanelResultado/LabelResultado.text = "Satisfacción calculada: %.1f/5" % satisfaccion

func _on_limpiar_formulario():
	$ContenedorPrincipal/FormContainer/GridForm/InputCliente.text = ""
	$ContenedorPrincipal/FormContainer/GridForm/SelectProducto.selected = 0
	$ContenedorPrincipal/FormContainer/GridForm/InputFecha.text = "01/01/2024"
	$ContenedorPrincipal/FormContainer/GridForm/SelectCalidad.selected = 4
	$ContenedorPrincipal/FormContainer/GridForm/SelectTiempo.selected = 4
	$ContenedorPrincipal/FormContainer/InputObservaciones.text = ""
	$ContenedorPrincipal/FormContainer/PanelResultado/LabelResultado.text = "Satisfacción calculada: --/5"

func _on_volver_menu():
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func mostrar_error(mensaje):
	print("ERROR: ", mensaje)
	# Aquí se implementaría un diálogo visual de error

func mostrar_mensaje(titulo, mensaje):
	print(titulo, ": ", mensaje)
	# Aquí se implementaría un diálogo visual
