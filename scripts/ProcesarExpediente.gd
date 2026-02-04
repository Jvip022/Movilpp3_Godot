extends Control

# Referencias a nodos - VERSIÓN CORREGIDA
@onready var label_id: Label
@onready var label_tipo: Label
@onready var label_estado: Label
@onready var label_fecha: Label
@onready var label_desc: Label
@onready var lista_documentos: ItemList
@onready var boton_cargar: Button
@onready var boton_cerrar: Button
@onready var mensaje_estado: Label
@onready var boton_menu: Button
@onready var boton_actualizar: Button
@onready var dialogo_cargar: FileDialog
@onready var dialogo_confirmar: AcceptDialog
@onready var mensaje_exito: AcceptDialog
@onready var mensaje_error: AcceptDialog

# Variables
var id_expediente: String = "EXP-2024-00123"
var tipo_nc: String = "Incidencia Diaria"
var estado_nc: String = "analizado"
var fecha_registro: String = "2024-01-15"
var descripcion: String = "Producto con defecto de fabricación reportado por cliente"
var documentos: Array = ["informe_tecnico.pdf", "fotos_defecto.jpg", "testimonio_cliente.docx"]

func _ready():
	print("=== PROCESAR EXPEDIENTE - INICIO ===")
	
	# Asignar referencias MANUALMENTE para evitar problemas
	_asignar_referencias_manuales()
	
	# Verificar referencias
	_verificar_referencias()
	
	# Configurar filtros de archivo
	dialogo_cargar.filters = PackedStringArray([
		"*.pdf ; Documentos PDF",
		"*.doc, *.docx ; Documentos Word",
		"*.xls, *.xlsx ; Hojas de cálculo",
        "*.jpg, *.jpeg, *.png ; Imágenes"
	])
	
	# Conectar señales - VERIFICAR que no sean null
	if boton_cargar:
		boton_cargar.pressed.connect(_on_boton_cargar_pressed)
		print("✓ Señal conectada: boton_cargar.pressed")
	
	if boton_cerrar:
		boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
		print("✓ Señal conectada: boton_cerrar.pressed")
	
	if boton_menu:
		boton_menu.pressed.connect(_on_boton_menu_pressed)
		print("✓ Señal conectada: boton_menu.pressed")
	
	if boton_actualizar:
		boton_actualizar.pressed.connect(_on_boton_actualizar_pressed)
		print("✓ Señal conectada: boton_actualizar.pressed")
	
	if dialogo_cargar:
		dialogo_cargar.file_selected.connect(_on_archivo_seleccionado)
		print("✓ Señal conectada: dialogo_cargar.file_selected")
	
	if dialogo_confirmar:
		dialogo_confirmar.confirmed.connect(_on_accion_confirmada)
		print("✓ Señal conectada: dialogo_confirmar.confirmed")
	
	# Cargar datos iniciales
	_cargar_datos_iniciales()
	_actualizar_interfaz_segun_estado()
	
	print("=== PROCESAR EXPEDIENTE - LISTO ===")

func _asignar_referencias_manuales():
	"""Asigna referencias manualmente para evitar problemas con @onready"""
	print("--- Asignando referencias manualmente ---")
	
	# Buscar nodos por ruta - AJUSTA ESTAS RUTAS SEGÚN TU ESCENA REAL
	label_id = get_node_or_null("ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/IDExpediente")
	label_tipo = get_node_or_null("ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/TipoNC")
	label_estado = get_node_or_null("ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/EstadoNC")
	label_fecha = get_node_or_null("ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/FechaRegistro")
	label_desc = get_node_or_null("ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/Descripcion")
	lista_documentos = get_node_or_null("ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/ListaDocumentos")
	boton_cargar = get_node_or_null("ContentContainer/PanelDerecho/PanelAcciones/Acciones/BotonCargarDoc")
	boton_cerrar = get_node_or_null("ContentContainer/PanelDerecho/PanelAcciones/Acciones/BotonCerrarExp")
	mensaje_estado = get_node_or_null("ContentContainer/PanelDerecho/PanelAcciones/Acciones/MensajeEstado")
	boton_menu = get_node_or_null("Footer/FooterHBox/BtnVolverMenu")
	boton_actualizar = get_node_or_null("ContentContainer/PanelDerecho/PanelAcciones/Acciones/BtnActualizarInfo")
	dialogo_cargar = get_node_or_null("DialogoCargarDoc")
	dialogo_confirmar = get_node_or_null("DialogoConfirmacion")
	mensaje_exito = get_node_or_null("MensajeExito")
	mensaje_error = get_node_or_null("MensajeError")
	
	print("Referencias asignadas manualmente")

func _verificar_referencias():
	"""Verifica que todas las referencias estén correctas"""
	print("--- Verificando referencias ---")
	
	# Crear diccionario de referencias CORREGIDO
	var referencias = {
		"label_id": label_id,
		"label_tipo": label_tipo,
		"label_estado": label_estado,
		"label_fecha": label_fecha,
		"label_desc": label_desc,
		"lista_documentos": lista_documentos,
		"boton_cargar": boton_cargar,
		"boton_cerrar": boton_cerrar,
		"mensaje_estado": mensaje_estado,
		"boton_menu": boton_menu,
		"boton_actualizar": boton_actualizar,
		"dialogo_cargar": dialogo_cargar,
		"dialogo_confirmar": dialogo_confirmar,
		"mensaje_exito": mensaje_exito,
		"mensaje_error": mensaje_error
	}
	
	# Iterar CORRECTAMENTE sobre el diccionario
	for nombre in referencias.keys():
		var referencia = referencias[nombre]
		if referencia != null:
			print("✓ ", nombre, ": OK")
		else:
			print("✗ ", nombre, ": NULL - NO ENCONTRADO")

func _cargar_datos_iniciales():
	"""Carga los datos iniciales del expediente"""
	print("--- Cargando datos iniciales ---")
	
	if label_id: 
		label_id.text = "ID Expediente: " + id_expediente
	if label_tipo: 
		label_tipo.text = "Tipo No Conformidad: " + tipo_nc
	if label_estado: 
		label_estado.text = "Estado No Conformidad: " + estado_nc
	if label_fecha: 
		label_fecha.text = "Fecha Registro: " + fecha_registro
	if label_desc: 
		label_desc.text = "Descripción: " + descripcion
	
	# Limpiar y cargar documentos
	if lista_documentos:
		lista_documentos.clear()
		print("Lista de documentos limpiada")
		
		for doc in documentos:
			lista_documentos.add_item(doc)
			print("Añadido documento inicial: ", doc)
	
	print("Datos iniciales cargados")

func _actualizar_interfaz_segun_estado():
	"""Actualiza la interfaz según el estado de la no conformidad"""
	print("--- Actualizando interfaz según estado ---")
	
	if not mensaje_estado:
		print("ERROR: mensaje_estado es null")
		return
	
	if estado_nc == "analizado":
		mensaje_estado.text = "✓ Puede cargar documentos al expediente"
		mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
		if boton_cargar: 
			boton_cargar.disabled = false
		if boton_cerrar: 
			boton_cerrar.disabled = true
		print("Estado: analizado - Cargar habilitado, Cerrar deshabilitado")
	elif estado_nc == "cerrada":
		mensaje_estado.text = "✓ Puede proceder a cerrar el expediente"
		mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
		if boton_cargar: 
			boton_cargar.disabled = true
		if boton_cerrar: 
			boton_cerrar.disabled = false
		print("Estado: cerrada - Cargar deshabilitado, Cerrar habilitado")
	else:
		mensaje_estado.text = "✗ Espere a que la NC esté analizada o cerrada"
		mensaje_estado.add_theme_color_override("font_color", Color(0.8, 0.5, 0.1))
		if boton_cargar: 
			boton_cargar.disabled = true
		if boton_cerrar: 
			boton_cerrar.disabled = true
		print("Estado: otro - Ambos botones deshabilitados")

func _on_boton_cargar_pressed():
	"""Maneja el clic en el botón de cargar documento"""
	print("--- Botón Cargar presionado ---")
	
	if dialogo_cargar:
		print("Mostrando diálogo de carga")
		dialogo_cargar.popup_centered()
	else:
		print("ERROR: dialogo_cargar es null")

func _on_boton_cerrar_pressed():
	"""Maneja el clic en el botón de cerrar expediente"""
	print("--- Botón Cerrar presionado ---")
	
	if dialogo_confirmar:
		dialogo_confirmar.dialog_text = "¿Está seguro que desea cerrar este expediente?\nEsta acción no se puede deshacer."
		dialogo_confirmar.popup_centered()
		print("Diálogo de confirmación mostrado")
	else:
		print("ERROR: dialogo_confirmar es null")

func _on_boton_actualizar_pressed():
	"""Actualiza la información del expediente"""
	print("--- Botón Actualizar presionado ---")
	print("Actualizando TODA la información del expediente")
	
	# Forzar recarga completa
	_cargar_datos_iniciales()
	_actualizar_interfaz_segun_estado()
	
	# Mostrar mensaje de confirmación
	if mensaje_exito:
		mensaje_exito.dialog_text = "✓ Información del expediente actualizada"
		mensaje_exito.popup_centered()
		print("Mensaje de éxito mostrado")
	else:
		print("ERROR: mensaje_exito es null")

func _on_boton_menu_pressed():
	"""Regresa al menú principal"""
	print("--- Regresando al menú principal ---")
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_archivo_seleccionado(path: String):
	"""Procesa el archivo seleccionado para cargar"""
	print("--- Archivo seleccionado ---")
	print("Ruta completa: ", path)
	
	var nombre_archivo = path.get_file()
	print("Nombre de archivo: ", nombre_archivo)
	
	# Agregar documento al array
	documentos.append(nombre_archivo)
	print("Documento añadido al array. Total: ", documentos.size())
	print("Array completo: ", documentos)
	
	# Agregar documento a la lista visual
	if lista_documentos:
		lista_documentos.add_item(nombre_archivo)
		print("Documento añadido a ItemList. Total items: ", lista_documentos.item_count)
		
		# Forzar actualización visual
		lista_documentos.queue_redraw()
	else:
		print("ERROR: lista_documentos es null - no se puede mostrar el documento")
	
	# Mostrar mensaje de éxito
	if mensaje_exito:
		mensaje_exito.dialog_text = "✓ Documento '" + nombre_archivo + "' cargado exitosamente"
		mensaje_exito.popup_centered()
		print("Mensaje de éxito mostrado")
	else:
		print("ERROR: mensaje_exito es null")

func _on_accion_confirmada():
	"""Ejecuta la acción confirmada (cerrar expediente)"""
	print("--- Acción confirmada (cerrar expediente) ---")
	
	if estado_nc == "cerrada":
		# Cambiar estado
		estado_nc = "expediente_cerrado"
		print("Nuevo estado: ", estado_nc)
		
		if label_estado:
			label_estado.text = "Estado No Conformidad: " + estado_nc
			print("Texto de estado actualizado")
		
		# Deshabilitar botones
		if boton_cargar: 
			boton_cargar.disabled = true
		if boton_cerrar: 
			boton_cerrar.disabled = true
		print("Botones deshabilitados")
		
		# Mostrar mensaje de éxito
		if mensaje_exito:
			mensaje_exito.dialog_text = "✓ Expediente cerrado exitosamente"
			mensaje_exito.popup_centered()
			print("Mensaje de éxito mostrado")
		
		# Actualizar mensaje de estado
		if mensaje_estado:
			mensaje_estado.text = "✓ Expediente cerrado"
			mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
			print("Mensaje de estado actualizado")
		
		# Registrar traza (simulación)
		print("TRAZA - Expediente cerrado: ", id_expediente)

# Función para cambiar estado desde fuera (para pruebas)
func cambiar_estado(nuevo_estado: String):
	"""Cambia el estado de la no conformidad"""
	print("--- Cambiando estado manualmente ---")
	print("Estado anterior: ", estado_nc)
	print("Nuevo estado: ", nuevo_estado)
	
	estado_nc = nuevo_estado
	_cargar_datos_iniciales()
	_actualizar_interfaz_segun_estado()

# Función de prueba para verificar que el script funciona
func probar_carga_documento():
	"""Función de prueba para cargar un documento simulado"""
	print("--- Prueba de carga de documento ---")
	
	var documento_prueba = "documento_prueba_" + str(Time.get_unix_time_from_system()) + ".pdf"
	documentos.append(documento_prueba)
	
	if lista_documentos:
		lista_documentos.add_item(documento_prueba)
		print("Documento de prueba añadido: ", documento_prueba)
	else:
		print("ERROR: No se pudo añadir documento de prueba")
