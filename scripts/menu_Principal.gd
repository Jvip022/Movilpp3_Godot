extends Control

class_name MenuInicio

# Referencias a todos los botones
@onready var btn_admin_usuarios = $ContenedorPrincipal/BotonesContainer/BtnAdministrarUsuarios
@onready var btn_gestor_quejas = $ContenedorPrincipal/BotonesContainer/BtnGestorQuejas
@onready var btn_registrar_incidencia = $ContenedorPrincipal/BotonesContainer/BtnRegistrarIncidencia
@onready var btn_registrar_nc = $ContenedorPrincipal/BotonesContainer/BtnRegistrarNCAuditoria
@onready var btn_generar_reportes = $ContenedorPrincipal/BotonesContainer/BtnGenerarReportes
@onready var btn_registrar_encuesta = $ContenedorPrincipal/BotonesContainer/BtnRegistrarEncuesta
@onready var btn_procesar_expediente = $ContenedorPrincipal/BotonesContainer/BtnProcesarExpediente
@onready var btn_procesar_correctivas = $ContenedorPrincipal/BotonesContainer/BtnProcesarCorrectivas
@onready var btn_procesar_mejoras = $ContenedorPrincipal/BotonesContainer/BtnProcesarMejoras
@onready var btn_salir = $ContenedorPrincipal/BtnSalir

func _ready():
	# Conectar señales de todos los botones
	_conectar_botones()
	print("Menú de inicio cargado correctamente")

func _conectar_botones():
	# Conectar cada botón a su función correspondiente
	btn_admin_usuarios.connect("pressed", Callable(self, "_on_admin_usuarios_pressed"))
	btn_gestor_quejas.connect("pressed", Callable(self, "_on_gestor_quejas_pressed"))
	btn_registrar_incidencia.connect("pressed", Callable(self, "_on_registrar_incidencia_pressed"))
	btn_registrar_nc.connect("pressed", Callable(self, "_on_registrar_nc_pressed"))
	btn_generar_reportes.connect("pressed", Callable(self, "_on_generar_reportes_pressed"))
	btn_registrar_encuesta.connect("pressed", Callable(self, "_on_registrar_encuesta_pressed"))
	btn_procesar_expediente.connect("pressed", Callable(self, "_on_procesar_expediente_pressed"))
	btn_procesar_correctivas.connect("pressed", Callable(self, "_on_procesar_correctivas_pressed"))
	btn_salir.connect("pressed", Callable(self, "_on_salir_pressed"))

# Funciones para cada botón
func _on_admin_usuarios_pressed():
	print("Cargando: Administrar Usuarios")
	cambiar_escena("res://escenas/AdministrarUsuarios.tscn")

func _on_gestor_quejas_pressed():
	print("Cargando: Gestor de Quejas")
	cambiar_escena("res://escenas/GestorQuejas.tscn")

func _on_registrar_incidencia_pressed():
	print("Cargando: Registrar Incidencia")
	cambiar_escena("res://escenas/RegistrarIncidencia.tscn")

func _on_registrar_nc_pressed():
	print("Cargando: Registrar NC Auditoría")
	cambiar_escena("res://escenas/RegistrarNCAuditoria.tscn")

func _on_generar_reportes_pressed():
	print("Cargando: Generar Reportes")
	cambiar_escena("res://escenas/GenerarReportes.tscn")

func _on_registrar_encuesta_pressed():
	#print("Cargando: Registrar Encuesta")
	cambiar_escena("res://escenas/GenerarEncuestas.tscn")

func _on_procesar_expediente_pressed():
	print("Cargando: Procesar Expediente")
	# Aquí puedes cambiar a la escena de procesar expediente cuando la crees
	cambiar_escena("res://escenas/ProcesarExpediente.tscn")
	#mostrar_mensaje_temporal("Módulo en desarrollo", "Procesar Expediente estará disponible pronto")

func _on_procesar_correctivas_pressed():
	print("Cargando: Acciones Correctivas")
	cambiar_escena("res://escenas/AccionesCorrectivas.tscn")
	


func _on_salir_pressed():
	print("Saliendo del sistema...")
	
	# Crear diálogo de confirmación
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirmar salida"
	dialog.dialog_text = "¿Está seguro que desea salir del sistema?"
	dialog.confirmed.connect(_confirmar_salida)
	dialog.canceled.connect(_cancelar_salida)
	
	add_child(dialog)
	dialog.popup_centered()

# Funciones de utilidad
func cambiar_escena(ruta_escena: String):
	# Verificar si la escena existe antes de intentar cargarla
	if ResourceLoader.exists(ruta_escena):
		get_tree().change_scene_to_file(ruta_escena)
	else:
		print("ERROR: No se encontró la escena: ", ruta_escena)
		mostrar_mensaje_error("La escena solicitada no existe:\n" + ruta_escena)

func mostrar_mensaje_error(mensaje: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()

func mostrar_mensaje_temporal(titulo: String, mensaje: String):
	var dialog = AcceptDialog.new()
	dialog.title = titulo
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()
	
	# Opcional: cerrar automáticamente después de 3 segundos
	await get_tree().create_timer(3.0).timeout
	dialog.queue_free()

func _confirmar_salida():
	print("Saliendo del sistema...")
	get_tree().quit()

func _cancelar_salida():
	print("Salida cancelada")

# Función para manejar la tecla ESC para salir
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_salir_pressed()

# Función para manejar teclas de atajo (opcional)
func _unhandled_input(event):
	if event is InputEventKey:
		# Atajos de teclado (opcional)
		if event.pressed and event.ctrl_pressed:
			match event.keycode:
				KEY_1:
					_on_admin_usuarios_pressed()
				KEY_2:
					_on_gestor_quejas_pressed()
				KEY_3:
					_on_registrar_incidencia_pressed()
				KEY_4:
					_on_registrar_nc_pressed()
				KEY_5:
					_on_generar_reportes_pressed()
				KEY_6:
					_on_registrar_encuesta_pressed()
				KEY_7:
					_on_procesar_expediente_pressed()
				KEY_8:
					_on_procesar_correctivas_pressed()
