extends Control

# Referencias a nodos
@onready var label_id: Label = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelInfoExpediente/InfoExpediente/IDExpediente
@onready var label_tipo: Label = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelInfoExpediente/InfoExpediente/TipoNC
@onready var label_estado: Label = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelInfoExpediente/InfoExpediente/EstadoNC
@onready var label_fecha: Label = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelInfoExpediente/InfoExpediente/FechaRegistro
@onready var label_desc: Label = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelInfoExpediente/InfoExpediente/Descripcion
@onready var lista_documentos: ItemList = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelInfoExpediente/InfoExpediente/ListaDocumentos
@onready var boton_cargar: Button = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelAcciones/Acciones/BotonCargarDoc
@onready var boton_cerrar: Button = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelAcciones/Acciones/BotonCerrarExp
@onready var mensaje_estado: Label = $ContenedorPrincipal/ContenidoScroll/Contenido/PanelAcciones/Acciones/MensajeEstado
@onready var boton_menu: Button = $ContenedorPrincipal/PanelControles/BotonMenuPrincipal
@onready var dialogo_cargar: FileDialog = $DialogoCargarDoc
@onready var dialogo_confirmar: AcceptDialog = $DialogoConfirmacion
@onready var mensaje_exito: AcceptDialog = $MensajeExito
@onready var mensaje_error: AcceptDialog = $MensajeError

# Variables
var id_expediente: String = "EXP-2024-00123"
var tipo_nc: String = "Incidencia Diaria"
var estado_nc: String = "analizado"
var fecha_registro: String = "2024-01-15"
var descripcion: String = "Producto con defecto de fabricación reportado por cliente"
var documentos: Array = ["informe_tecnico.pdf", "fotos_defecto.jpg", "testimonio_cliente.docx"]

func _ready():
	# Configurar filtros de archivo
	dialogo_cargar.filters = PackedStringArray([
		"*.pdf ; Documentos PDF",
		"*.doc, *.docx ; Documentos Word",
		"*.xls, *.xlsx ; Hojas de cálculo",
        "*.jpg, *.jpeg, *.png ; Imágenes"
	])
	
	# Conectar señales
	boton_cargar.pressed.connect(_on_boton_cargar_pressed)
	boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
	boton_menu.pressed.connect(_on_boton_menu_pressed)
	dialogo_cargar.file_selected.connect(_on_archivo_seleccionado)
	dialogo_confirmar.confirmed.connect(_on_accion_confirmada)
	
	# Cargar datos iniciales
	_cargar_datos_iniciales()
	_actualizar_interfaz_segun_estado()

func _cargar_datos_iniciales():
	"""Carga los datos iniciales del expediente"""
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
	if estado_nc == "analizado":
		mensaje_estado.text = "✓ Puede cargar documentos al expediente"
		mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
		boton_cargar.disabled = false
		boton_cerrar.disabled = true
	elif estado_nc == "cerrada":
		mensaje_estado.text = "✓ Puede proceder a cerrar el expediente"
		mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
		boton_cargar.disabled = true
		boton_cerrar.disabled = false
	else:
		mensaje_estado.text = "✗ Espere a que la NC esté analizada o cerrada"
		mensaje_estado.add_theme_color_override("font_color", Color(0.8, 0.5, 0.1))
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
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_archivo_seleccionado(path: String):
	"""Procesa el archivo seleccionado para cargar"""
	var nombre_archivo = path.get_file()
	
	# Agregar documento a la lista
	documentos.append(nombre_archivo)
	lista_documentos.add_item(nombre_archivo)
	
	# Mostrar mensaje de éxito
	mensaje_exito.dialog_text = "✓ Documento '" + nombre_archivo + "' cargado exitosamente"
	mensaje_exito.popup_centered()
	
	# Registrar traza (simulación)
	print("TRAZA - Documento cargado: ", nombre_archivo)

func _on_accion_confirmada():
	"""Ejecuta la acción confirmada (cerrar expediente)"""
	if estado_nc == "cerrada":
		# Cambiar estado
		estado_nc = "expediente_cerrado"
		label_estado.text = "Estado No Conformidad: " + estado_nc
		
		# Deshabilitar botones
		boton_cargar.disabled = true
		boton_cerrar.disabled = true
		
		# Mostrar mensaje de éxito
		mensaje_exito.dialog_text = "✓ Expediente cerrado exitosamente"
		mensaje_exito.popup_centered()
		
		# Actualizar mensaje de estado
		mensaje_estado.text = "✓ Expediente cerrado"
		mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
		
		# Registrar traza (simulación)
		print("TRAZA - Expediente cerrado: ", id_expediente)

# Función para cambiar estado desde fuera (para pruebas)
func cambiar_estado(nuevo_estado: String):
	"""Cambia el estado de la no conformidad"""
	estado_nc = nuevo_estado
	_cargar_datos_iniciales()
	_actualizar_interfaz_segun_estado()
