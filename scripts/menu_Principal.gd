extends Control

class_name MenuInicio

# Referencias a los botones
@onready var btn_admin_usuarios = $ContenedorPrincipal/BotonesContainer/BtnAdministrarUsuarios
@onready var btn_gestor_quejas = $ContenedorPrincipal/BotonesContainer/BtnGestorQuejas
@onready var btn_registrar_incidencia = $ContenedorPrincipal/BotonesContainer/BtnRegistrarIncidencia
@onready var btn_registrar_nc = $ContenedorPrincipal/BotonesContainer/BtnRegistrarNCAuditoria
@onready var btn_salir = $ContenedorPrincipal/BtnSalir

func _ready():
	# Conectar señales de los botones
	btn_admin_usuarios.connect("pressed", Callable(self, "_on_admin_usuarios_pressed"))
	btn_gestor_quejas.connect("pressed", Callable(self, "_on_gestor_quejas_pressed"))
	btn_registrar_incidencia.connect("pressed", Callable(self, "_on_registrar_incidencia_pressed"))
	btn_registrar_nc.connect("pressed", Callable(self, "_on_registrar_nc_pressed"))
	btn_salir.connect("pressed", Callable(self, "_on_salir_pressed"))
	
	print("Menú de inicio cargado correctamente")

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

func cambiar_escena(ruta_escena: String):
	# Verificar si la escena existe antes de intentar cargarla
	var file = FileAccess.open(ruta_escena, FileAccess.READ)
	if file:
		file.close()
		get_tree().change_scene_to_file(ruta_escena)
	else:
		print("ERROR: No se encontró la escena: ", ruta_escena)
		mostrar_mensaje_error("La escena solicitada no existe:\n" + ruta_escena)

func mostrar_mensaje_error(mensaje: String):
	var alerta = AcceptDialog.new()
	alerta.title = "Error"
	alerta.dialog_text = mensaje
	add_child(alerta)
	alerta.popup_centered()

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
