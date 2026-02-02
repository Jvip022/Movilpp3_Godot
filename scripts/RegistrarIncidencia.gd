extends Control
class_name RegistrarIncidencia

# Señales
signal incidencia_registrada(codigo_incidencia: String, datos: Dictionary)
signal error_registro(mensaje: String)

# Variables de conexión a base de datos
var db: BD
var usuario_actual: Dictionary = {}
var cliente_seleccionado: Dictionary = {}
@onready var date_picker = $DialogoCalendario/DatePicker
# Variables de estado
var formulario_valido: bool = false
var requiere_investigacion: bool = true  # Añadido: variable faltante

# Datos para combos
enum TIPOS_HALLAZGO {
	RETRASO = 0,
	DEFECTO_PRODUCTO = 1,
	ERROR_SERVICIO = 2,
	ATENCION_CLIENTE = 3,
	PROBLEMA_LOGISTICO = 4,
	OTRO = 5
}

enum NIVELES_GRAVEDAD {
	LEVE = 0,
	MODERADO = 1,
	GRAVE = 2,
	CRITICO = 3
}

func _ready():
	# Inicializar base de datos (asumiendo que BD es un autoload/singleton)
	if not _inicializar_base_datos():
		return
	
	# Inicializar interfaz
	inicializar_interfaz()
	
	# Cargar usuario actual (simulado para pruebas)
	cargar_usuario_actual()
	
	print("✅ Módulo de Registrar Incidencias listo")

func _inicializar_base_datos() -> bool:
	# Buscar el singleton de BD
	if has_node("/root/BD"):
		db = get_node("/root/BD")
		return true
	else:
		# Intentar crear instancia si no existe como singleton
		db = BD.new()
		if not db._ready():
			push_error("❌ No se pudo inicializar la base de datos")
			return false
		return true

func cargar_usuario_actual():
	# Simulación: cargar usuario desde sesión
	# En producción, esto vendría del sistema de autenticación
	usuario_actual = {
		"id": 1,
		"nombre_completo": "Supervisor General",
		"username": "supervisor",
		"rol": "Supervisor General"
	}
	
	print("👤 Usuario actual cargado: " + usuario_actual["nombre_completo"])

func inicializar_interfaz():
	# Inicializar combos
	inicializar_combos()
	
	# Conectar señales
	conectar_senales()
	
	# Configurar fecha actual
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha.text = obtener_fecha_actual()
	
	# Deshabilitar botón registrar inicialmente
	$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.disabled = true

func inicializar_combos():
	# Combo tipo de hallazgo
	var comboTipo = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo
	comboTipo.clear()
	comboTipo.add_item("Seleccionar tipo*", TIPOS_HALLAZGO.RETRASO)
	comboTipo.set_item_text(0, "Retraso en servicio")
	comboTipo.add_item("Defecto de producto", TIPOS_HALLAZGO.DEFECTO_PRODUCTO)
	comboTipo.add_item("Error en servicio", TIPOS_HALLAZGO.ERROR_SERVICIO)
	comboTipo.add_item("Atención al cliente", TIPOS_HALLAZGO.ATENCION_CLIENTE)
	comboTipo.add_item("Problema logístico", TIPOS_HALLAZGO.PROBLEMA_LOGISTICO)
	comboTipo.add_item("Otro", TIPOS_HALLAZGO.OTRO)
	
	# Combo producto/servicio
	var comboProducto = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto
	comboProducto.clear()
	comboProducto.add_item("Seleccionar producto/servicio*")
	comboProducto.add_item("Paquete turístico")
	comboProducto.add_item("Hospedaje")
	comboProducto.add_item("Transporte")
	comboProducto.add_item("Excursión")
	comboProducto.add_item("Seguro de viaje")
	comboProducto.add_item("Alquiler de auto")
	comboProducto.add_item("Asistencia al viajero")
	
	# Combo sucursal
	var comboSucursal = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal
	comboSucursal.clear()
	comboSucursal.add_item("Seleccionar sucursal*")
	comboSucursal.add_item("La Habana")
	comboSucursal.add_item("Varadero")
	comboSucursal.add_item("Viñales")
	comboSucursal.add_item("Trinidad")
	comboSucursal.add_item("Santiago de Cuba")
	comboSucursal.add_item("Internacional")
	
	# Combo gravedad
	var comboGravedad = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad
	comboGravedad.clear()
	comboGravedad.add_item("Seleccionar gravedad*")
	comboGravedad.add_item("Leve")
	comboGravedad.add_item("Moderado")
	comboGravedad.add_item("Grave")
	comboGravedad.add_item("Crítico")
	
	# Combo investigación
	var comboInvestigacion = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion
	comboInvestigacion.clear()
	comboInvestigacion.add_item("Seleccionar*")
	comboInvestigacion.add_item("Sí")
	comboInvestigacion.add_item("No")

func conectar_senales():
	# Botones principales
	$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/BtnBuscarCliente.pressed.connect(abrir_busqueda_cliente)
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/BtnCalendario.pressed.connect(abrir_calendario)
	$ContentContainer/FormContainer/SeccionAcciones/BtnCancelar.pressed.connect(cerrar_formulario)
	$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.pressed.connect(validar_y_registrar)
	
	# Diálogo de búsqueda de cliente
	$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/BtnBuscarClienteDialog.pressed.connect(buscar_cliente_bd)
	$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente.pressed.connect(seleccionar_cliente)
	$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnCancelarCliente.pressed.connect(cerrar_busqueda_cliente)
	
	# Diálogo de calendario
	$DialogoCalendario/BotonesFecha/BtnAceptarFecha.pressed.connect(seleccionar_fecha)
	$DialogoCalendario/BotonesFecha/BtnCancelarFecha.pressed.connect(cerrar_calendario)
	
	# Validación en tiempo real
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text_changed.connect(validar_formulario)
	$ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text_changed.connect(validar_formulario)
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion.item_selected.connect(on_investigacion_changed)
	
	# Confirmación
	$ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarSi.pressed.connect(registrar_incidencia_cerrada)
	$ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarNo.pressed.connect(cerrar_confirmacion_estado)

func abrir_busqueda_cliente():
	if not db:
		mostrar_error("Base de datos no disponible")
		return
	
	$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text = ""
	$DialogoBuscarCliente/BuscarClienteVBox/TablaClientes.clear()
	$DialogoBuscarCliente.popup_centered()

func buscar_cliente_bd():
	var termino = $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text.strip_edges()
	
	if termino == "":
		mostrar_error("Ingrese un término de búsqueda")
		return
	
	mostrar_carga("Buscando cliente en base de datos...")
	
	# Buscar en base de datos
	var clientes = db.buscar_cliente_oracle(termino)
	
	ocultar_carga()
	
	# Mostrar resultados
	mostrar_clientes_en_tabla(clientes)

func mostrar_clientes_en_tabla(clientes: Array):
	var tabla = $DialogoBuscarCliente/BuscarClienteVBox/TablaClientes
	tabla.clear()
	
	if clientes.size() == 0:
		mostrar_error("No se encontraron clientes")
		$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente.disabled = true
		return
	
	# Configurar columnas
	tabla.columns = 5
	tabla.column_titles = ["Código", "Nombre", "Apellidos", "Email", "Teléfono"]
	tabla.column_expand = [false, true, true, false, false]
	
	var root = tabla.create_item()
	
	for cliente in clientes:
		var item = tabla.create_item(root)
		item.set_text(0, cliente["codigo_cliente"])
		item.set_text(1, cliente["nombre"])
		item.set_text(2, cliente.get("apellidos", ""))
		item.set_text(3, cliente.get("email", ""))
		item.set_text(4, cliente.get("telefono", ""))
		
		# Guardar datos completos del cliente en metadata del item
		item.set_metadata(0, cliente)
	
	$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente.disabled = false

func seleccionar_cliente():
	var tabla = $DialogoBuscarCliente/BuscarClienteVBox/TablaClientes
	var seleccionado = tabla.get_selected()
	
	if not seleccionado:
		mostrar_error("Seleccione un cliente de la lista")
		return
	
	cliente_seleccionado = seleccionado.get_metadata(0)
	
	# Mostrar información del cliente en el formulario
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = true
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelNombreCliente.text = "Nombre: " + cliente_seleccionado["nombre"] + " " + cliente_seleccionado.get("apellidos", "")
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelCodigoCliente.text = "Código: " + cliente_seleccionado["codigo_cliente"]
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelContacto.text = "Contacto: " + cliente_seleccionado.get("email", "") + " / " + cliente_seleccionado.get("telefono", "")
	
	# Deshabilitar campo de búsqueda
	$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = cliente_seleccionado["nombre"] + " " + cliente_seleccionado.get("apellidos", "")
	
	$DialogoBuscarCliente.hide()
	validar_formulario()

func cerrar_busqueda_cliente():
	$DialogoBuscarCliente.hide()

func abrir_calendario():
	$DialogoCalendario.popup_centered()

func seleccionar_fecha():
	var date_picker = $DialogoCalendario/DatePicker
	var fecha = date_picker.date
	var fecha_str = "%02d/%02d/%04d" % [fecha["day"], fecha["month"], fecha["year"]]
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha.text = fecha_str
	$DialogoCalendario.hide()
	validar_formulario()

func cerrar_calendario():
	$DialogoCalendario.hide()

func on_investigacion_changed(index: int):
	if index == 1:  # "Sí" (sí requiere investigación)
		requiere_investigacion = true
	elif index == 2:  # "No" (no requiere investigación)
		requiere_investigacion = false
	validar_formulario()

func validar_formulario():
	# Verificar campos obligatorios
	var campos_ok = true
	
	# Cliente seleccionado
	if not cliente_seleccionado or cliente_seleccionado.is_empty():
		campos_ok = false
	
	# Campos de incidencia
	var inputTitulo = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo
	if inputTitulo.text.strip_edges() == "":
		campos_ok = false
	
	var comboInvestigacion = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion
	if comboInvestigacion.selected <= 0:
		campos_ok = false
	
	var inputDescripcion = $ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion
	if inputDescripcion.text.strip_edges() == "":
		campos_ok = false
	
	# Combo boxes
	var combos = [
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo,
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto,
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal,
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad
	]
	
	for combo in combos:
		if combo.selected <= 0:
			campos_ok = false
	
	# Fecha de ocurrencia
	var inputFecha = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha
	if inputFecha.text.strip_edges() == "":
		campos_ok = false
	
	formulario_valido = campos_ok
	$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.disabled = not formulario_valido
	
	return formulario_valido

func validar_y_registrar():
	if not validar_formulario():
		mostrar_error("Complete todos los campos obligatorios (*)")
		return
	
	# Verificar si requiere investigación usando la variable
	var comboInvestigacion = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion
	if comboInvestigacion.selected == 2:  # "No" (no requiere investigación)
		# Mostrar diálogo de confirmación
		$ConfirmacionEstado.popup_centered()
	else:
		registrar_incidencia_abierta()

func registrar_incidencia_abierta():
	# Registrar incidencia con estado "abierta" (requiere investigación)
	registrar_incidencia_con_estado("abierta")

func registrar_incidencia_cerrada():
	# Registrar incidencia con estado "cerrada" (no requiere investigación)
	registrar_incidencia_con_estado("cerrada")
	$ConfirmacionEstado.hide()

func cerrar_confirmacion_estado():
	$ConfirmacionEstado.hide()

func registrar_incidencia_con_estado(estado: String):
	if not db:
		mostrar_error("Base de datos no disponible")
		return
	
	# Generar código de incidencia
	var codigo_incidencia = db.generar_codigo_incidencia()
	
	# Obtener datos del formulario
	var datos_incidencia = obtener_datos_formulario()
	datos_incidencia["codigo_incidencia"] = codigo_incidencia
	datos_incidencia["cliente_id"] = cliente_seleccionado["id"]
	datos_incidencia["estado"] = estado
	datos_incidencia["supervisor_id"] = usuario_actual["id"]
	
	mostrar_carga("Registrando incidencia...")
	
	# Registrar en base de datos
	var incidencia_id = db.registrar_incidencia(datos_incidencia)
	
	if incidencia_id > 0:
		# Registrar traza
		db.registrar_traza(
			usuario_actual["id"],
			"REGISTRAR_INCIDENCIA",
			"Incidencias",
			"Incidente registrado: " + codigo_incidencia + " - " + datos_incidencia["titulo"]
		)
		
		ocultar_carga()
		
		# Mostrar mensaje de éxito
		var mensaje = "✅ Incidencia registrada exitosamente\n"
		mensaje += "Código: " + codigo_incidencia + "\n"
		mensaje += "Estado: " + estado + "\n"
		if estado == "cerrada":
			mensaje += "No requiere investigación"
		
		mostrar_exito(mensaje)
		
		# Emitir señal
		incidencia_registrada.emit(codigo_incidencia, datos_incidencia)
		
		# Limpiar formulario después de éxito
		limpiar_formulario()
	else:
		ocultar_carga()
		mostrar_error("Error al registrar la incidencia en la base de datos")

func obtener_datos_formulario() -> Dictionary:
	# Obtener tipo de hallazgo
	var comboTipo = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo
	var tipo_hallazgo = comboTipo.get_item_text(comboTipo.selected)
	
	# Obtener producto/servicio
	var comboProducto = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto
	var producto_servicio = comboProducto.get_item_text(comboProducto.selected)
	
	# Obtener sucursal
	var comboSucursal = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal
	var sucursal = comboSucursal.get_item_text(comboSucursal.selected)
	
	# Obtener gravedad
	var comboGravedad = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad
	var nivel_gravedad = comboGravedad.get_item_text(comboGravedad.selected)
	
	# Obtener investigación
	var comboInvestigacion = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion
	var requiere_investigacion_bool = (comboInvestigacion.selected == 1)  # 1=Sí, 2=No
	
	# Convertir fecha de formato DD/MM/AAAA a AAAA-MM-DD para SQLite
	var inputFecha = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha
	var fecha_parts = inputFecha.text.split("/")
	var fecha_sql = ""
	if fecha_parts.size() == 3:
		fecha_sql = "%s-%s-%s" % [fecha_parts[2], fecha_parts[1].pad_zeros(2), fecha_parts[0].pad_zeros(2)]
	
	return {
		"titulo": $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text.strip_edges(),
		"descripcion": $ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text.strip_edges(),
		"tipo_hallazgo": tipo_hallazgo,
		"producto_servicio": producto_servicio,
		"sucursal": sucursal,
		"fecha_ocurrencia": fecha_sql,
		"nivel_gravedad": nivel_gravedad,
		"requiere_investigacion": 1 if requiere_investigacion_bool else 0,
		"observaciones": ""
	}

func limpiar_formulario():
	# Limpiar cliente
	cliente_seleccionado = {}
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = false
	$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = ""
	
	# Limpiar campos de incidencia
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text = ""
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha.text = obtener_fecha_actual()
	$ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text = ""
	
	# Resetear combos
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo.select(0)
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto.select(0)
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal.select(0)
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad.select(0)
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion.select(0)
	
	# Restablecer variable requiere_investigacion a su valor por defecto
	requiere_investigacion = true
	
	# Deshabilitar botón registrar
	$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.disabled = true

func cerrar_formulario():
	# Verificar si hay datos sin guardar
	if formulario_valido:
		# Mostrar confirmación antes de cerrar
		mostrar_error("Hay datos sin guardar. ¿Está seguro de que desea cerrar?")
		# En producción, implementar diálogo de confirmación
		return
	
	# Cerrar la ventana/escena
	queue_free()

# ==================== FUNCIONES UTILITARIAS ====================

func obtener_fecha_actual() -> String:
	var fecha = Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [fecha["day"], fecha["month"], fecha["year"]]

func mostrar_carga(mensaje: String):
	$PanelCargando/MensajeCarga.text = mensaje
	$PanelCargando.visible = true

func ocultar_carga():
	$PanelCargando.visible = false

func mostrar_exito(mensaje: String):
	$MensajeExito.dialog_text = mensaje
	$MensajeExito.popup_centered()

func mostrar_error(mensaje: String):
	$MensajeError.dialog_text = mensaje
	$MensajeError.popup_centered()

func _process(_delta):
	# Animación de barra de progreso
	if $PanelCargando.visible:
		var progress = $PanelCargando/ProgressBar
		progress.value = fmod(progress.value + 1.0, 100.0)

# ==================== FUNCIONES PARA CASOS DE USO RELACIONADOS ====================

# RF04: Salvar/Restaurar Base de Datos
func realizar_backup():
	if not db:
		return false
	
	mostrar_carga("Realizando backup de base de datos...")
	
	# Generar nombre de archivo con fecha
	var fecha = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_").replace("-", "")
	var nombre_archivo = "backup_" + fecha + ".db"
	var ruta_backup = "user://backups/" + nombre_archivo
	
	# En producción, aquí se copiaría el archivo de base de datos
	# Simulación: registrar en tabla de backups
	var backup_id = db.registrar_backup(
		nombre_archivo,
		ruta_backup,
		usuario_actual["id"],
		"manual"
	)
	
	ocultar_carga()
	
	if backup_id > 0:
		mostrar_exito("✅ Backup realizado exitosamente\nArchivo: " + nombre_archivo)
		return true
	else:
		mostrar_error("❌ Error al realizar backup")
		return false

# RF03: Visualizar Trazas
func obtener_trazas_usuario(usuario_id: int = -1, desde: String = "", hasta: String = "") -> Array:
	if not db:
		return []
	
	return db.obtener_trazas(desde, hasta, usuario_id)

# RF02: Administrar Usuario (ya implementado en UserManagement.gd)
# Esta función sería para integración si se necesita desde este módulo
func obtener_usuarios_sistema() -> Array:
	if not db:
		return []
	
	return db.obtener_usuarios()
