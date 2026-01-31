extends Control

# Referencias a nodos
@onready var label_bienvenida = $PanelSuperior/HBoxContainer/InfoUsuario/LabelBienvenida
@onready var label_rol = $PanelSuperior/HBoxContainer/InfoUsuario/LabelRol
@onready var boton_cerrar_sesion = $PanelSuperior/HBoxContainer/BotonCerrarSesion
@onready var boton_notificaciones = $PanelSuperior/HBoxContainer/BotonNotificaciones
@onready var boton_perfil = $PanelSuperior/HBoxContainer/BotonPerfil

@onready var boton_inicio = $HSplitContainer/PanelLateral/MenuLateral/BotonInicio
@onready var boton_nueva_queja = $HSplitContainer/PanelLateral/MenuLateral/BotonNuevaQueja
@onready var boton_mis_quejas = $HSplitContainer/PanelLateral/MenuLateral/BotonMisQuejas
@onready var boton_seguimiento = $HSplitContainer/PanelLateral/MenuLateral/BotonSeguimiento
@onready var boton_reportes = $HSplitContainer/PanelLateral/MenuLateral/BotonReportes

@onready var tabs_contenido = $HSplitContainer/PanelContenido/TabsContenido
@onready var panel_cargando = $HSplitContainer/PanelContenido/PanelCargandoContenido

@onready var panel_notificaciones = $PanelNotificaciones
@onready var lista_notificaciones = $PanelNotificaciones/VBoxContainer/ScrollContainer/VBoxContainer/ListaNotificaciones
@onready var boton_cerrar_notificaciones = $PanelNotificaciones/VBoxContainer/HBoxContainer/BotonCerrarNotificaciones
@onready var boton_limpiar_notificaciones = $PanelNotificaciones/VBoxContainer/BotonLimpiarNotificaciones

@onready var dialogo_cerrar_sesion = $DialogoCerrarSesion
@onready var check_recordar_proxima = $DialogoCerrarSesion/VBoxContainer/CheckRecordarProxima

# Variables
var notificaciones = []
var pestaña_actual = 0
var formulario_queja_instancia = null

func _ready():
	# Verificar autenticación
	if not Global or not Global.esta_autenticado():
		print("Usuario no autenticado, redirigiendo a login...")
		get_tree().change_scene_to_file("res://PantallaLogin.tscn")
		return
	
	# Configurar interfaz con datos del usuario
	configurar_interfaz_usuario()
	
	# Conectar señales
	conectar_señales()
	
	# Cargar contenido inicial
	cargar_pestaña_inicio()
	
	# Cargar notificaciones
	cargar_notificaciones()
	
	# Actualizar estado del sistema
	actualizar_estado_sistema()

func configurar_interfaz_usuario():
	if Global.usuario_actual:
		var nombre = Global.usuario_actual.get("nombre", "Usuario")
		var rol = Global.usuario_actual.get("rol", "usuario")
		
		label_bienvenida.text = "Bienvenido, " + nombre
		label_rol.text = rol.capitalize()
		
		# Mostrar/ocultar opciones según rol
		if rol == "admin":
			boton_reportes.visible = true
		else:
			boton_reportes.visible = false

func conectar_señales():
	# Botones superiores
	boton_cerrar_sesion.pressed.connect(_on_cerrar_sesion_pressed)
	boton_notificaciones.pressed.connect(_on_notificaciones_pressed)
	boton_perfil.pressed.connect(_on_perfil_pressed)
	
	# Menú lateral
	boton_inicio.pressed.connect(_on_inicio_pressed)
	boton_nueva_queja.pressed.connect(_on_nueva_queja_pressed)
	boton_mis_quejas.pressed.connect(_on_mis_quejas_pressed)
	boton_seguimiento.pressed.connect(_on_seguimiento_pressed)
	boton_reportes.pressed.connect(_on_reportes_pressed)
	
	# Panel de notificaciones
	boton_cerrar_notificaciones.pressed.connect(_on_cerrar_notificaciones_pressed)
	boton_limpiar_notificaciones.pressed.connect(_on_limpiar_notificaciones_pressed)
	
	# Diálogo cerrar sesión
	dialogo_cerrar_sesion.get_ok_button().text = "Sí, salir"
	dialogo_cerrar_sesion.get_cancel_button().text = "Cancelar"
	dialogo_cerrar_sesion.confirmed.connect(_confirmar_cerrar_sesion)

func _on_inicio_pressed():
	cambiar_pestaña(0)
	actualizar_botones_menu(boton_inicio)

func _on_nueva_queja_pressed():
	cambiar_pestaña(1)
	actualizar_botones_menu(boton_nueva_queja)
	
	# Cargar formulario de queja si no está cargado
	if not formulario_queja_instancia:
		cargar_formulario_queja()

func _on_mis_quejas_pressed():
	cambiar_pestaña(2)
	actualizar_botones_menu(boton_mis_quejas)
	cargar_mis_quejas()

func _on_seguimiento_pressed():
	cambiar_pestaña(3)
	actualizar_botones_menu(boton_seguimiento)
	cargar_seguimiento()

func _on_reportes_pressed():
	cambiar_pestaña(4)
	actualizar_botones_menu(boton_reportes)
	cargar_reportes()

func _on_perfil_pressed():
	mostrar_perfil_usuario()

func _on_notificaciones_pressed():
	panel_notificaciones.visible = not panel_notificaciones.visible

func _on_cerrar_notificaciones_pressed():
	panel_notificaciones.visible = false

func _on_limpiar_notificaciones_pressed():
	notificaciones.clear()
	actualizar_lista_notificaciones()

func _on_cerrar_sesion_pressed():
	dialogo_cerrar_sesion.popup_centered()

func _confirmar_cerrar_sesion():
	# Guardar preferencia de recordar sesión
	if check_recordar_proxima.button_pressed:
		# Aquí guardarías la preferencia
		pass
	
	# Cerrar sesión
	Global.cerrar_sesion()

func cambiar_pestaña(indice: int):
	pestaña_actual = indice
	tabs_contenido.current_tab = indice

func actualizar_botones_menu(boton_presionado: Button):
	# Desmarcar todos los botones
	for boton in [boton_inicio, boton_nueva_queja, boton_mis_quejas, boton_seguimiento, boton_reportes]:
		if boton:
			boton.button_pressed = false
	
	# Marcar el botón presionado
	if boton_presionado:
		boton_presionado.button_pressed = true

func cargar_pestaña_inicio():
	var contenido_inicio = tabs_contenido.get_node("TabInicio/ScrollContainer/ContenidoInicio")
	if contenido_inicio:
		# Limpiar contenido previo
		for nodo in contenido_inicio.get_children():
			nodo.queue_free()
		
		# Crear widgets de inicio
		crear_widgets_inicio(contenido_inicio)

func crear_widgets_inicio(contenedor: VBoxContainer):
	# Widget de bienvenida
	var card_bienvenida = crear_card("Bienvenido al Sistema", "Aquí puede gestionar sus quejas y reclamaciones de manera eficiente.")
	contenedor.add_child(card_bienvenida)
	
	# Widget de estadísticas rápidas
	var card_stats = crear_card("Estadísticas Rápidas")
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 10)
	
	# Agregar estadísticas
	var stats = [
		{"label": "Quejas pendientes", "valor": "3", "color": Color.ORANGE},
		{"label": "Quejas resueltas", "valor": "12", "color": Color.GREEN},
		{"label": "Tiempo promedio de respuesta", "valor": "48h", "color": Color.CORNFLOWER_BLUE}
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = stat["label"]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var valor = Label.new()
		valor.text = stat["valor"]
		valor.add_theme_color_override("font_color", stat["color"])
		
		hbox.add_child(label)
		hbox.add_child(valor)
		stats_container.add_child(hbox)
	
	card_stats.add_child(stats_container)
	contenedor.add_child(card_stats)
	
	# Widget de acciones rápidas
	var card_acciones = crear_card("Acciones Rápidas")
	var grid_acciones = GridContainer.new()
	grid_acciones.columns = 2
	
	var acciones = [
		{"texto": "Nueva Queja", "funcion": "_on_nueva_queja_pressed"},
		{"texto": "Ver Mis Quejas", "funcion": "_on_mis_quejas_pressed"},
		{"texto": "Ver Seguimiento", "funcion": "_on_seguimiento_pressed"},
		{"texto": "Descargar Reporte", "funcion": "_descargar_reporte"}
	]
	
	for accion in acciones:
		var boton = Button.new()
		boton.text = accion["texto"]
		boton.pressed.connect(Callable(self, accion["funcion"]))
		grid_acciones.add_child(boton)
	
	card_acciones.add_child(grid_acciones)
	contenedor.add_child(card_acciones)

func crear_card(titulo: String, descripcion: String = "") -> Panel:
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var label_titulo = Label.new()
	label_titulo.text = titulo
	label_titulo.add_theme_font_size_override("font_size", 16)
	
	vbox.add_child(label_titulo)
	
	if descripcion:
		var label_desc = Label.new()
		label_desc.text = descripcion
		label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(label_desc)
	
	panel.add_child(vbox)
	return panel

func cargar_formulario_queja():
	mostrar_carga(true)
	
	# Cargar formulario de queja asíncronamente
	await get_tree().create_timer(0.5).timeout
	
	var tab = tabs_contenido.get_node("TabNuevaQueja")
	if tab:
		# Limpiar contenido previo
		for nodo in tab.get_children():
			nodo.queue_free()
		
		# Cargar el formulario de queja
		var formulario_scene = preload("res://escenas/registroQueja.tscn")
		if formulario_scene:
			formulario_queja_instancia = formulario_scene.instantiate()
			tab.add_child(formulario_queja_instancia)
			
			# Conectar señales del formulario si es necesario
			# formulario_queja_instancia.connect("queja_enviada", Callable(self, "_on_queja_enviada"))
	
	mostrar_carga(false)

func cargar_mis_quejas():
	mostrar_carga(true)
	
	await get_tree().create_timer(0.5).timeout
	
	var tab = tabs_contenido.get_node("TabMisQuejas")
	if tab:
		# Limpiar contenido previo
		for nodo in tab.get_children():
			nodo.queue_free()
		
		# Crear lista de quejas
		var scroll = ScrollContainer.new()
		scroll.anchor_right = 1
		scroll.anchor_bottom = 1
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 5)
		
		# Datos de ejemplo
		var quejas = [
			{"id": "Q-2024-001", "asunto": "Producto defectuoso", "estado": "En revisión", "fecha": "2024-01-15"},
			{"id": "Q-2024-002", "asunto": "Retraso en entrega", "estado": "Resuelto", "fecha": "2024-01-10"},
			{"id": "Q-2024-003", "asunto": "Atención al cliente", "estado": "Pendiente", "fecha": "2024-01-05"}
		]
		
		for queja in quejas:
			var card = crear_card_queja(queja)
			vbox.add_child(card)
		
		scroll.add_child(vbox)
		tab.add_child(scroll)
	
	mostrar_carga(false)

func crear_card_queja(datos: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))
	panel.custom_minimum_size = Vector2(0, 80)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	
	# ID de queja
	var label_id = Label.new()
	label_id.text = datos.get("id", "N/A")
	label_id.custom_minimum_size = Vector2(100, 0)
	
	# Asunto
	var vbox_asunto = VBoxContainer.new()
	var label_asunto = Label.new()
	label_asunto.text = datos.get("asunto", "Sin asunto")
	label_asunto.add_theme_font_size_override("font_size", 14)
	
	var label_fecha = Label.new()
	label_fecha.text = datos.get("fecha", "")
	label_fecha.add_theme_font_size_override("font_size", 12)
	label_fecha.add_theme_color_override("font_color", Color.GRAY)
	
	vbox_asunto.add_child(label_asunto)
	vbox_asunto.add_child(label_fecha)
	
	# Estado
	var label_estado = Label.new()
	label_estado.text = datos.get("estado", "Desconocido")
	label_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_estado.custom_minimum_size = Vector2(100, 0)
	
	# Color según estado
	match datos.get("estado", ""):
		"Resuelto":
			label_estado.add_theme_color_override("font_color", Color.GREEN)
		"En revisión":
			label_estado.add_theme_color_override("font_color", Color.ORANGE)
		"Pendiente":
			label_estado.add_theme_color_override("font_color", Color.RED)
		_:
			label_estado.add_theme_color_override("font_color", Color.GRAY)
	
	hbox.add_child(label_id)
	hbox.add_child(vbox_asunto)
	hbox.add_theme_constant_override("separation", 10)
	hbox.add_child(label_estado)
	
	panel.add_child(hbox)
	return panel

func cargar_seguimiento():
	mostrar_carga(true)
	
	await get_tree().create_timer(0.5).timeout
	
	var tab = tabs_contenido.get_node("TabSeguimiento")
	if tab:
		# Limpiar contenido previo
		for nodo in tab.get_children():
			nodo.queue_free()
		
		var label = Label.new()
		label.text = "Seguimiento de quejas\n\nPróximamente..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_right = 1
		label.anchor_bottom = 1
		
		tab.add_child(label)
	
	mostrar_carga(false)

func cargar_reportes():
	mostrar_carga(true)
	
	await get_tree().create_timer(0.5).timeout
	
	var tab = tabs_contenido.get_node("TabReportes")
	if tab:
		# Limpiar contenido previo
		for nodo in tab.get_children():
			nodo.queue_free()
		
		var label = Label.new()
		label.text = "Reportes y estadísticas\n\nPróximamente..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_right = 1
		label.anchor_bottom = 1
		
		tab.add_child(label)
	
	mostrar_carga(false)

func mostrar_perfil_usuario():
	var dialogo = AcceptDialog.new()
	dialogo.title = "Mi Perfil"
	dialogo.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	if Global.usuario_actual:
		var datos = [
			{"label": "Nombre:", "valor": Global.usuario_actual.get("nombre", "N/A")},
			{"label": "Usuario:", "valor": Global.usuario_actual.get("username", "N/A")},
			{"label": "Email:", "valor": Global.usuario_actual.get("email", "N/A")},
			{"label": "Rol:", "valor": Global.usuario_actual.get("rol", "N/A")}
		]
		
		for dato in datos:
			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.text = dato["label"]
			label.custom_minimum_size = Vector2(100, 0)
			
			var valor = Label.new()
			valor.text = dato["valor"]
			
			hbox.add_child(label)
			hbox.add_child(valor)
			vbox.add_child(hbox)
	
	# Botón para editar perfil
	var boton_editar = Button.new()
	boton_editar.text = "Editar Perfil"
	vbox.add_child(boton_editar)
	
	dialogo.add_child(vbox)
	add_child(dialogo)
	dialogo.popup_centered()

func cargar_notificaciones():
	# Notificaciones de ejemplo
	notificaciones = [
		{"id": 1, "mensaje": "Nueva queja asignada", "tipo": "info", "fecha": "Hoy 10:30"},
		{"id": 2, "mensaje": "Queja #Q-2024-001 actualizada", "tipo": "success", "fecha": "Ayer 15:45"},
		{"id": 3, "mensaje": "Recordatorio: Revisar quejas pendientes", "tipo": "warning", "fecha": "02 Ene"}
	]
	
	actualizar_lista_notificaciones()

func actualizar_lista_notificaciones():
	# Limpiar lista
	for nodo in lista_notificaciones.get_children():
		nodo.queue_free()
	
	# Agregar notificaciones
	for notif in notificaciones:
		var panel = Panel.new()
		panel.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))
		panel.custom_minimum_size = Vector2(0, 60)
		
		var vbox = VBoxContainer.new()
		
		var label_mensaje = Label.new()
		label_mensaje.text = notif["mensaje"]
		label_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var label_fecha = Label.new()
		label_fecha.text = notif["fecha"]
		label_fecha.add_theme_font_size_override("font_size", 12)
		label_fecha.add_theme_color_override("font_color", Color.GRAY)
		
		vbox.add_child(label_mensaje)
		vbox.add_child(label_fecha)
		panel.add_child(vbox)
		
		lista_notificaciones.add_child(panel)

func actualizar_estado_sistema():
	# Aquí podrías verificar conexión a servidor, etc.
	var label_estado = $HSplitContainer/PanelLateral/PanelEstado/LabelEstado
	if label_estado:
		label_estado.text = "🟢 En línea"

func mostrar_carga(mostrar: bool):
	if panel_cargando:
		panel_cargando.visible = mostrar

func _descargar_reporte():
	print("Descargando reporte...")
	# Aquí implementarías la descarga de reportes

# Manejo de redimensionamiento
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		# Ajustar contenido según tamaño de ventana
		ajustar_contenido()

func ajustar_contenido():
	# Ajustar contenido responsive
	var tamaño = get_viewport().size
	if tamaño.x < 800:
		# Modo móvil/tablet
		$HSplitContainer/PanelLateral.visible = false
	else:
		# Modo escritorio
		$HSplitContainer/PanelLateral.visible = true
