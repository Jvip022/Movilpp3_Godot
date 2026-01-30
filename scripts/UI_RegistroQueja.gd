# UI_RegistroQueja.gd - Formulario inteligente
extends Control

@onready var campos_dinamicos = $ScrollContainer/VBoxContainer/CamposDinamicos
@onready var boton_adjuntar = $PanelInferior/BotonAdjuntar
@onready var vista_previa = $PanelDerecho/VistaPrevia


var archivos_adjuntos = []
var tipo_reclamante_actual = "cliente"
var regex_email = RegEx.new()

func _ready():
	configurar_validadores()
	cargar_opciones_desde_bd()
	conectar_eventos()
	# Inicializar expresión regular para email
	regex_email.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")

func es_email_valido(email: String) -> bool:
	email = email.strip_edges()
	if email.is_empty():
		return false
	
	var resultado = regex_email.search(email)
	return resultado != null
	
func configurar_validadores():
	# Validar email
	if has_node("Email"):
		$Email.text_changed.connect(_on_email_text_changed)
	# Validar teléfono
	if has_node("Telefono"):
		$Telefono.text_changed.connect(_on_telefono_text_changed)
	# Validar monto
	if has_node("MontoReclamado"):
		$MontoReclamado.text_changed.connect(_on_monto_text_changed)

func cargar_opciones_desde_bd():
	# Aquí cargarías opciones desde una base de datos
	# Ejemplo básico:
	if has_node("Categoria"):
		$Categoria.clear()
		$Categoria.add_item("Seleccione categoría", 0)
		$Categoria.add_item("Calidad del producto", 1)
		$Categoria.add_item("Servicio postventa", 2)
		$Categoria.add_item("Tiempo de entrega", 3)
	
	if has_node("TipoCompensacion"):
		$TipoCompensacion.clear()
		$TipoCompensacion.add_item("Seleccione compensación", 0)
		$TipoCompensacion.add_item("Reembolso", 1)
		$TipoCompensacion.add_item("Reemplazo", 2)
		$TipoCompensacion.add_item("Descuento futuro", 3)

func conectar_eventos():
	# Conectar botones y señales
	if has_node("PanelInferior/BotonAdjuntar"):
		$PanelInferior/BotonAdjuntar.pressed.connect(_on_adjuntar_archivo_pressed)
	
	if has_node("PanelInferior/BotonEnviar"):
		$PanelInferior/BotonEnviar.pressed.connect(_on_enviar_queja_pressed)
	
	if has_node("TipoReclamante"):
		$TipoReclamante.item_selected.connect(_on_tipo_reclamante_selected)

func _on_tipo_reclamante_selected(index):
	if $TipoReclamante.get_item_count() > 0:
		tipo_reclamante_actual = $TipoReclamante.get_item_text(index)
		mostrar_campos_relevantes()

func mostrar_campos_relevantes():
	# Asegurarse de que los nodos existen antes de acceder a ellos
	if has_node("CamposCliente") and has_node("CamposProveedor") and has_node("CamposEmpleado"):
		# Mostrar/ocultar campos según tipo de reclamante
		match tipo_reclamante_actual:
			"cliente":
				$CamposCliente.visible = true
				$CamposProveedor.visible = false
				$CamposEmpleado.visible = false
			"proveedor":
				$CamposCliente.visible = false
				$CamposProveedor.visible = true
				$CamposEmpleado.visible = false
			"empleado":
				$CamposCliente.visible = false
				$CamposProveedor.visible = false
				$CamposEmpleado.visible = true

func _on_adjuntar_archivo_pressed():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = ["*.png, *.jpg, *.jpeg ; Imágenes", "*.pdf ; Documentos PDF", "*.txt ; Texto"]
	
	dialog.files_selected.connect(_archivos_seleccionados)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

func _archivos_seleccionados(rutas: PackedStringArray):
	for ruta in rutas:
		var nombre_archivo = ruta.get_file()
		archivos_adjuntos.append({
			"ruta": ruta,
			"nombre": nombre_archivo,
			"tipo": nombre_archivo.get_extension()
		})
	
	actualizar_lista_adjuntos()
	if has_node("PanelInferior/LabelAdjuntos"):
		$PanelInferior/LabelAdjuntos.text = str(archivos_adjuntos.size()) + " archivos adjuntos"

func actualizar_lista_adjuntos():
	# Actualizar la UI con la lista de archivos adjuntos
	if has_node("PanelDerecho/ListaAdjuntos"):
		var lista = $PanelDerecho/ListaAdjuntos
		lista.clear()
		for archivo in archivos_adjuntos:
			lista.add_item(archivo.nombre)

func _on_enviar_queja_pressed():
	if not validar_formulario():
		mostrar_error("Complete todos los campos obligatorios")
		return
	
	var datos_queja = recopilar_datos_formulario()
	
	# Mostrar resumen antes de enviar
	if has_node("DialogoConfirmacion"):
		$DialogoConfirmacion.mostrar_resumen(datos_queja)

func validar_formulario() -> bool:
	# Validación básica de campos obligatorios
	var campos_obligatorios = [
		{"nodo": "Nombres", "mensaje": "El nombre es obligatorio"},
		{"nodo": "Identificacion", "mensaje": "La identificación es obligatoria"},
		{"nodo": "Email", "mensaje": "El email es obligatorio"},
		{"nodo": "Asunto", "mensaje": "El asunto es obligatorio"},
		{"nodo": "Descripcion", "mensaje": "La descripción es obligatoria"}
	]
	
	for campo in campos_obligatorios:
		if has_node(campo.nodo):
			var texto = get_node(campo.nodo).text
			if texto.strip_edges().is_empty():
				mostrar_error(campo.mensaje)
				return false
	
	# Validar email si existe
	if has_node("Email"):
		var email = $Email.text
		if not email.es_email_valido():
			mostrar_error("Ingrese un email válido")
			return false
	
	return true

func mostrar_error(mensaje: String):
	# Mostrar mensaje de error (puedes usar un Label o un popup)
	print("Error: ", mensaje)  # Temporal: solo para debug
	
	# Ejemplo con un Label de error si existe
	if has_node("MensajeError"):
		$MensajeError.text = mensaje
		$MensajeError.visible = true
		await get_tree().create_timer(3.0).timeout
		$MensajeError.visible = false

func recopilar_datos_formulario():
	var datos = {
		"tipo_reclamante": tipo_reclamante_actual,
		"nombres": $Nombres.text if has_node("Nombres") else "",
		"identificacion": $Identificacion.text if has_node("Identificacion") else "",
		"telefono": $Telefono.text if has_node("Telefono") else "",
		"email": $Email.text if has_node("Email") else "",
		
		"asunto": $Asunto.text if has_node("Asunto") else "",
		"descripcion_detallada": $Descripcion.text if has_node("Descripcion") else "",
		"producto_servicio": $ProductoServicio.text if has_node("ProductoServicio") else "",
		"numero_factura": $NumeroFactura.text if has_node("NumeroFactura") else "",
		"fecha_incidente": $FechaIncidente.text if has_node("FechaIncidente") else "",
		
		"categoria": $Categoria.get_item_text($Categoria.selected) if has_node("Categoria") and $Categoria.selected >= 0 else "",
		"monto_reclamado": float($MontoReclamado.text) if has_node("MontoReclamado") and $MontoReclamado.text else 0.0,
		"tipo_compensacion": $TipoCompensacion.get_item_text($TipoCompensacion.selected) if has_node("TipoCompensacion") and $TipoCompensacion.selected >= 0 else "",
		
		"archivos_adjuntos": archivos_adjuntos,
		"prioridad": calcular_prioridad_automatica(),
		"fecha_registro": Time.get_datetime_string_from_system()
	}
	
	return datos

func calcular_prioridad_automatica() -> String:
	# Lógica para calcular prioridad automáticamente
	var prioridad = "media"
	
	if has_node("MontoReclamado"):
		var monto_texto = $MontoReclamado.text
		if monto_texto:
			var monto = float(monto_texto)
			if monto > 1000:
				prioridad = "alta"
			elif monto < 100:
				prioridad = "baja"
	
	# También considerar categoría
	if has_node("Categoria"):
		var categoria = $Categoria.get_item_text($Categoria.selected)
		if categoria in ["Seguridad", "Fraude"]:
			prioridad = "alta"
	
	return prioridad

# Funciones de validación individuales
func _on_email_text_changed(nuevo_texto: String):
	if has_node("Email"):
		var email_valido = es_email_valido(nuevo_texto)
		# Cambiar color del campo según validez
		var color = Color.GREEN if email_valido else Color.RED
		$Email.add_theme_color_override("font_color", color)
		
		# También puedes mostrar un mensaje de ayuda
		if has_node("EmailError"):
			if email_valido or nuevo_texto.is_empty():
				$EmailError.visible = false
			else:
				$EmailError.text = "Formato de email inválido"
				$EmailError.visible = true

func _on_telefono_text_changed(nuevo_texto: String):
	if has_node("Telefono"):
		# Validar que solo tenga números
		var solo_numeros = nuevo_texto.is_valid_int()
		$Telefono.add_theme_color_override("font_color", Color.GREEN if solo_numeros else Color.RED)

func _on_monto_text_changed(nuevo_texto: String):
	if has_node("MontoReclamado"):
		# Validar que sea un número válido
		var es_numero = nuevo_texto.is_valid_float() or nuevo_texto.is_valid_int()
		$MontoReclamado.add_theme_color_override("font_color", Color.GREEN if es_numero else Color.RED)

# Función para limpiar el formulario
func limpiar_formulario():
	archivos_adjuntos.clear()
	actualizar_lista_adjuntos()
	
	# Limpiar todos los campos de texto
	var campos = [
		"Nombres", "Identificacion", "Telefono", "Email",
		"Asunto", "Descripcion", "ProductoServicio", 
		"NumeroFactura", "MontoReclamado"
	]
	
	for campo_nombre in campos:
		if has_node(campo_nombre):
			get_node(campo_nombre).text = ""
	
	# Restablecer selecciones
	if has_node("Categoria"):
		$Categoria.selected = 0
	if has_node("TipoCompensacion"):
		$TipoCompensacion.selected = 0
	if has_node("TipoReclamante"):
		$TipoReclamante.selected = 0
		_on_tipo_reclamante_selected(0)
		
