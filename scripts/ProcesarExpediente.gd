extends Control

# Variables del expediente
var id_expediente: String = ""
var tipo_nc: String = ""
var estado_nc: String = ""
var fecha_registro: String = ""
var descripcion: String = ""
var documentos: Array = []
var usuario_autenticado: bool = false
var expediente_cargado: bool = false

# Referencias a nodos
@onready var label_id = $PanelFondo/VBoxPrincipal/PanelInfo/ScrollContainer/InfoExpediente/IDExpediente
@onready var label_tipo = $PanelFondo/VBoxPrincipal/PanelInfo/ScrollContainer/InfoExpediente/TipoNC
@onready var label_estado = $PanelFondo/VBoxPrincipal/PanelInfo/ScrollContainer/InfoExpediente/EstadoNC
@onready var label_fecha = $PanelFondo/VBoxPrincipal/PanelInfo/ScrollContainer/InfoExpediente/FechaRegistro
@onready var label_desc = $PanelFondo/VBoxPrincipal/PanelInfo/ScrollContainer/InfoExpediente/Descripcion
@onready var lista_documentos = $PanelFondo/VBoxPrincipal/PanelInfo/ScrollContainer/InfoExpediente/DocumentosActuales/ListaDocumentos
@onready var boton_cargar = $PanelFondo/VBoxPrincipal/PanelAcciones/VBoxAcciones/BotonCargarDoc
@onready var boton_cerrar = $PanelFondo/VBoxPrincipal/PanelAcciones/VBoxAcciones/BotonCerrarExp
@onready var mensaje_estado = $PanelFondo/VBoxPrincipal/PanelAcciones/VBoxAcciones/MensajeEstado
@onready var boton_menu = $PanelFondo/VBoxPrincipal/PanelControles/BotonMenuPrincipal
@onready var dialogo_cargar = $DialogoCargarDoc
@onready var dialogo_confirmar = $DialogoConfirmacion
@onready var mensaje_exito = $MensajeExito
@onready var mensaje_error = $MensajeError

func _ready():
	# Conectar señales
	boton_cargar.connect("pressed", _on_boton_cargar_pressed)
	boton_cerrar.connect("pressed", _on_boton_cerrar_pressed)
	boton_menu.connect("pressed", _on_boton_menu_pressed)
	dialogo_cargar.connect("file_selected", _on_archivo_seleccionado)
	dialogo_confirmar.connect("confirmed", _on_accion_confirmada)
	mensaje_exito.connect("confirmed", _on_mensaje_exito_cerrado)
	
	# Inicializar verificación de precondiciones
	_verificar_precondiciones()

func _verificar_precondiciones():
	"""Verifica las precondiciones del caso de uso"""
	
	# 1. Verificar autenticación del usuario
	usuario_autenticado = _verificar_autenticacion()
	
	if not usuario_autenticado:
		mensaje_estado.text = "Error: Usuario no autenticado"
		mensaje_estado.modulate = Color(0.8, 0.1, 0.1)
		mensaje_error.dialog_text = "Debe autenticarse para procesar expedientes"
		mensaje_error.popup_centered()
		return
	
	# 2. Cargar datos del expediente (simulación)
	_cargar_expediente()
	
	if not expediente_cargado:
		mensaje_estado.text = "Error: No se pudo cargar el expediente"
		mensaje_estado.modulate = Color(0.8, 0.1, 0.1)
		return
	
	# 3. Verificar estado de la no conformidad y habilitar acciones correspondientes
	_actualizar_interfaz_segun_estado()

func _verificar_autenticacion() -> bool:
	"""Verifica si el usuario está autenticado (simulación)"""
	# En una implementación real, esto verificaría con el sistema de autenticación
	return true  # Simulación: usuario autenticado

func _cargar_expediente():
	"""Carga los datos del expediente (simulación)"""
	# Simulación de carga de datos
	id_expediente = "EXP-2024-00123"
	tipo_nc = "Incidencia Diaria"
	estado_nc = "analizado"  # Cambiar a "cerrada" para probar cierre
	fecha_registro = "2024-01-15"
	descripcion = "Producto con defecto de fabricación reportado por cliente"
	documentos = ["informe_tecnico.pdf", "fotos_defecto.jpg", "testimonio_cliente.docx"]
	
	expediente_cargado = true
	
	# Actualizar interfaz
	label_id.text = "ID Expediente: " + id_expediente
	label_tipo.text = "Tipo No Conformidad: " + tipo_nc
	label_estado.text = "Estado No Conformidad: " + estado_nc
	label_fecha.text = "Fecha Registro: " + fecha_registro
	label_desc.text = "Descripción: " + descripcion
	
	lista_documentos.clear()
	for doc in documentos:
		lista_documentos.add_item(doc)

func _actualizar_interfaz_segun_estado():
	"""Actualiza la interfaz según el estado de la no conformidad"""
	
	mensaje_estado.modulate = Color(0.2, 0.6, 0.2)
	
	if estado_nc == "analizado":
		mensaje_estado.text = "Puede cargar documentos al expediente"
		boton_cargar.disabled = false
		boton_cerrar.disabled = true
	elif estado_nc == "cerrada":
		mensaje_estado.text = "Puede proceder a cerrar el expediente"
		boton_cargar.disabled = true
		boton_cerrar.disabled = false
	else:
		mensaje_estado.text = "Espere a que la NC esté analizada o cerrada"
		mensaje_estado.modulate = Color(0.8, 0.5, 0.1)
		boton_cargar.disabled = true
		boton_cerrar.disabled = true

func _on_boton_cargar_pressed():
	"""Maneja el clic en el botón de cargar documento"""
	dialogo_cargar.popup_centered()

func _on_boton_cerrar_pressed():
	"""Maneja el clic en el botón de cerrar expediente"""
	dialogo_confirmar.dialog_text = "¿Está seguro que desea cerrar este expediente?\nEsta acción no se puede deshacer."
	dialogo_confirmar.popup_centered()

func _on_boton_menu_pressed():
	"""Regresa al menú principal"""
	# En una implementación real, esto cambiaría de escena
	print("Regresando al menú principal...")
	# get_tree().change_scene_to_file("res://MenuPrincipal.tscn")

func _on_archivo_seleccionado(path: String):
	"""Procesa el archivo seleccionado para cargar"""
	var nombre_archivo = path.get_file()
	
	# Simular carga del documento
	documentos.append(nombre_archivo)
	lista_documentos.add_item(nombre_archivo)
	
	# Mostrar mensaje de éxito
	mensaje_exito.dialog_text = "Documento '" + nombre_archivo + "' cargado exitosamente"
	mensaje_exito.popup_centered()
	
	# Registrar traza (RF03)
	_registrar_traza("Documento cargado", "Se cargó el documento: " + nombre_archivo)

func _on_accion_confirmada():
	"""Ejecuta la acción confirmada (cerrar expediente)"""
	
	if estado_nc == "cerrada":
		# Simular cierre del expediente
		estado_nc = "expediente_cerrado"
		label_estado.text = "Estado No Conformidad: expediente_cerrado"
		
		# Deshabilitar botones
		boton_cargar.disabled = true
		boton_cerrar.disabled = true
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "Expediente cerrado exitosamente"
		mensaje_exito.popup_centered()
		
		# Registrar traza (RF03)
		_registrar_traza("Expediente cerrado", "Expediente " + id_expediente + " cerrado")

func _on_mensaje_exito_cerrado():
	"""Acciones después de cerrar mensaje de éxito"""
	_actualizar_interfaz_segun_estado()

func _registrar_traza(accion: String, detalles: String):
	"""Registra una traza en el sistema (simulación)"""
	print("TRAZA - Acción: " + accion + " | Detalles: " + detalles + " | Usuario: EspecialistaCalidad | Fecha: " + Time.get_datetime_string_from_system())
	# En una implementación real, esto guardaría en la base de datos

# Funciones para integración con el sistema real
func set_expediente_datos(datos: Dictionary):
	"""Establece los datos del expediente desde el sistema externo"""
	id_expediente = datos.get("id", "")
	tipo_nc = datos.get("tipo", "")
	estado_nc = datos.get("estado", "")
	fecha_registro = datos.get("fecha", "")
	descripcion = datos.get("descripcion", "")
	documentos = datos.get("documentos", [])
	
	expediente_cargado = true
	
	# Actualizar interfaz
	_actualizar_interfaz()

func _actualizar_interfaz():
	"""Actualiza todos los elementos de la interfaz con los datos actuales"""
	label_id.text = "ID Expediente: " + id_expediente
	label_tipo.text = "Tipo No Conformidad: " + tipo_nc
	label_estado.text = "Estado No Conformidad: " + estado_nc
	label_fecha.text = "Fecha Registro: " + fecha_registro
	label_desc.text = "Descripción: " + descripcion
	
	lista_documentos.clear()
	for doc in documentos:
		lista_documentos.add_item(doc)
	
	_actualizar_interfaz_segun_estado()
