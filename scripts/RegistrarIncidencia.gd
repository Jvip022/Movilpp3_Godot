extends Control
class_name RegistrarIncidencia

# Señales
signal incidencia_registrada(codigo_incidencia: String, datos: Dictionary)
signal error_registro(mensaje: String)

# Variables de conexión a base de datos
var db = null
var usuario_actual: Dictionary = {}
var cliente_seleccionado: Dictionary = {}

# Variables de estado
var formulario_valido: bool = false
var requiere_investigacion: bool = true

# Base de datos simulada
var clientes_falsos: Array = []
var incidencias_registradas: Array = []
var codigo_incidencia_counter: int = 1000

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
	# Inicializar datos de prueba
	inicializar_datos_prueba()
	
	# Inicializar la interfaz visual
	inicializar_interfaz()
	
	# Cargar usuario actual (simulado para pruebas)
	cargar_usuario_actual()
	
	print("✅ Módulo de Registrar Incidencias listo (Modo de Prueba)")

func inicializar_datos_prueba():
	# Crear clientes falsos para pruebas
	clientes_falsos = [
		{
			"id": 1,
			"codigo_cliente": "CLI001",
			"nombre": "Juan Carlos",
			"apellidos": "Pérez García",
			"email": "juan.perez@ejemplo.com",
			"telefono": "0991234567",
			"direccion": "Av. Principal 123",
			"ciudad": "Quito",
			"tipo_cliente": "Regular"
		},
		{
			"id": 2,
			"codigo_cliente": "CLI002",
			"nombre": "María Fernanda",
			"apellidos": "Gómez Rodríguez",
			"email": "maria.gomez@ejemplo.com",
			"telefono": "0987654321",
			"direccion": "Calle Secundaria 456",
			"ciudad": "Guayaquil",
			"tipo_cliente": "Premium"
		},
		{
			"id": 3,
			"codigo_cliente": "CLI003",
			"nombre": "Carlos Alberto",
			"apellidos": "Rodríguez López",
			"email": "carlos.rodriguez@ejemplo.com",
			"telefono": "0971122334",
			"direccion": "Av. Amazonas 789",
			"ciudad": "Cuenca",
			"tipo_cliente": "Regular"
		},
		{
			"id": 4,
			"codigo_cliente": "CLI004",
			"nombre": "Ana Lucía",
			"apellidos": "López Martínez",
			"email": "ana.lopez@ejemplo.com",
			"telefono": "0969988776",
			"direccion": "Calle Bolívar 321",
			"ciudad": "Ambato",
			"tipo_cliente": "VIP"
		},
		{
			"id": 5,
			"codigo_cliente": "CLI005",
			"nombre": "Pedro José",
			"apellidos": "Martínez Sánchez",
			"email": "pedro.martinez@ejemplo.com",
			"telefono": "0955544332",
			"direccion": "Av. Shyris 654",
			"ciudad": "Quito",
			"tipo_cliente": "Regular"
		},
		{
			"id": 6,
			"codigo_cliente": "CLI006",
			"nombre": "Laura Patricia",
			"apellidos": "Sánchez Fernández",
			"email": "laura.sanchez@ejemplo.com",
			"telefono": "0944455566",
			"direccion": "Av. 6 de Diciembre 987",
			"ciudad": "Quito",
			"tipo_cliente": "Premium"
		},
		{
			"id": 7,
			"codigo_cliente": "CLI007",
			"nombre": "David Alejandro",
			"apellidos": "Fernández Pérez",
			"email": "david.fernandez@ejemplo.com",
			"telefono": "0933344455",
			"direccion": "Calle Rumiñahui 147",
			"ciudad": "Manta",
			"tipo_cliente": "Regular"
		},
		{
			"id": 8,
			"codigo_cliente": "CLI008",
			"nombre": "Elena Beatriz",
			"apellidos": "Pérez Gómez",
			"email": "elena.perez@ejemplo.com",
			"telefono": "0922233344",
			"direccion": "Av. del Ejército 258",
			"ciudad": "Guayaquil",
			"tipo_cliente": "VIP"
		},
		{
			"id": 9,
			"codigo_cliente": "CLI009",
			"nombre": "Miguel Ángel",
			"apellidos": "Gómez López",
			"email": "miguel.gomez@ejemplo.com",
			"telefono": "0911122233",
			"direccion": "Av. Amazonas N35-12",
			"ciudad": "Quito",
			"tipo_cliente": "Regular"
		},
		{
			"id": 10,
			"codigo_cliente": "CLI010",
			"nombre": "Sofía Isabel",
			"apellidos": "López Rodríguez",
			"email": "sofia.lopez@ejemplo.com",
			"telefono": "0900099887",
			"direccion": "Av. González Suárez 369",
			"ciudad": "Cuenca",
			"tipo_cliente": "Premium"
		}
	]
	
	print("📋 Cargados " + str(clientes_falsos.size()) + " clientes de prueba")
	
	# Crear base de datos simulada
	db = {
		"buscar_cliente": func(termino: String) -> Array:
			return buscar_cliente_simulado(termino),
		
		"generar_codigo_incidencia": func() -> String:
			return generar_codigo_incidencia_simulado(),
		
		"registrar_incidencia": func(datos: Dictionary) -> int:
			return registrar_incidencia_simulado(datos),
		
		"registrar_traza": func(usuario_id: int, accion: String, modulo: String, descripcion: String) -> void:
			registrar_traza_simulada(usuario_id, accion, modulo, descripcion),
		
		"registrar_backup": func(nombre: String, ruta: String, usuario_id: int, tipo: String) -> int:
			return registrar_backup_simulado(nombre, ruta, usuario_id, tipo),
		
		"obtener_trazas": func(desde: String, hasta: String, usuario_id: int) -> Array:
			return obtener_trazas_simuladas(desde, hasta, usuario_id),
		
		"obtener_usuarios": func() -> Array:
			return obtener_usuarios_simulados()
	}

func buscar_cliente_simulado(termino: String) -> Array:
	print("🔍 Búsqueda simulada: '" + termino + "'")
	var resultados = []
	var termino_lower = termino.to_lower().strip_edges()
	
	if termino_lower == "":
		return []
	
	for cliente in clientes_falsos:
		if (termino_lower in cliente["nombre"].to_lower() or
			termino_lower in cliente["apellidos"].to_lower() or
			termino_lower in cliente["codigo_cliente"].to_lower() or
			termino_lower in cliente["email"].to_lower() or
			termino_lower in cliente["telefono"] or
			termino_lower in cliente["ciudad"].to_lower()):
			resultados.append(cliente)
	
	print("📊 Resultados encontrados: " + str(resultados.size()))
	return resultados

func generar_codigo_incidencia_simulado() -> String:
	codigo_incidencia_counter += 1
	var fecha_actual = Time.get_datetime_dict_from_system()
	var codigo = "INC-%04d%02d%02d-%04d" % [
		fecha_actual["year"],
		fecha_actual["month"],
		fecha_actual["day"],
		codigo_incidencia_counter
	]
	return codigo

func registrar_incidencia_simulado(datos: Dictionary) -> int:
	print("💾 Registrando incidencia simulada:")
	for key in datos:
		print("   " + key + ": " + str(datos[key]))
	
	# Agregar ID único
	var id_incidencia = incidencias_registradas.size() + 1
	datos["id"] = id_incidencia
	datos["fecha_registro"] = Time.get_datetime_string_from_system()
	
	incidencias_registradas.append(datos)
	print("✅ Incidencia registrada con ID: " + str(id_incidencia))
	print("📊 Total de incidencias registradas: " + str(incidencias_registradas.size()))
	
	return id_incidencia

func registrar_traza_simulada(usuario_id: int, accion: String, modulo: String, descripcion: String) -> void:
	print("📝 Traza simulada - Usuario: " + str(usuario_id) + ", Acción: " + accion + ", Módulo: " + modulo + ", Descripción: " + descripcion)

func registrar_backup_simulado(_nombre: String, _ruta: String, _usuario_id: int, _tipo: String) -> int:
	print("💾 Backup simulado realizado")
	return 1

func obtener_trazas_simuladas(_desde: String, _hasta: String, _usuario_id: int) -> Array:
	return []

func obtener_usuarios_simulados() -> Array:
	return [
		{"id": 1, "nombre": "Supervisor General", "username": "supervisor", "rol": "Supervisor"},
		{"id": 2, "nombre": "Analista de Calidad", "username": "analista", "rol": "Analista"},
		{"id": 3, "nombre": "Administrador", "username": "admin", "rol": "Administrador"}
	]

func cargar_usuario_actual():
	# Simulación: cargar usuario desde sesión
	usuario_actual = {
		"id": 1,
		"nombre_completo": "Supervisor General",
		"username": "supervisor",
		"rol": "Supervisor General"
	}
	
	print("👤 Usuario actual cargado: " + usuario_actual["nombre_completo"])

func inicializar_interfaz():
	# Inicializar combos primero
	inicializar_combos()
	
	# Configurar diálogo de búsqueda de cliente
	if has_node("DialogoBuscarCliente"):
		$DialogoBuscarCliente.size = Vector2(700, 500)
		$DialogoBuscarCliente.min_size = Vector2(700, 500)
	
	# Conectar señales después de que todos los nodos estén listos
	await get_tree().process_frame
	conectar_senales()
	
	# Configurar fecha actual
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha.text = obtener_fecha_actual()
	
	# Deshabilitar botón registrar inicialmente
	$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.disabled = true
	
	# Si el diálogo de calendario tiene un DatePicker, eliminarlo o desactivarlo
	if has_node("DialogoCalendario"):
		# Ocultar el diálogo de calendario ya que no funciona
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/BtnCalendario.visible = false
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/BtnCalendario.disabled = true
		print("⚠️ Selector de fecha desactivado")

func inicializar_combos():
	# Combo tipo de hallazgo
	var comboTipo = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo
	if comboTipo:
		comboTipo.clear()
		comboTipo.add_item("Seleccionar tipo*")
		comboTipo.add_item("Retraso en servicio")
		comboTipo.add_item("Defecto de producto")
		comboTipo.add_item("Error en servicio")
		comboTipo.add_item("Atención al cliente")
		comboTipo.add_item("Problema logístico")
		comboTipo.add_item("Otro")
	
	# Combo producto/servicio
	var comboProducto = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto
	if comboProducto:
		comboProducto.clear()
		comboProducto.add_item("Seleccionar producto/servicio*")
		comboProducto.add_item("Paquete turístico")
		comboProducto.add_item("Hospedaje")
		comboProducto.add_item("Transporte aéreo")
		comboProducto.add_item("Transporte terrestre")
		comboProducto.add_item("Excursión")
		comboProducto.add_item("Seguro de viaje")
		comboProducto.add_item("Alquiler de auto")
		comboProducto.add_item("Asistencia al viajero")
		comboProducto.add_item("Tour guiado")
	
	# Combo sucursal
	var comboSucursal = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal
	if comboSucursal:
		comboSucursal.clear()
		comboSucursal.add_item("Seleccionar sucursal*")
		comboSucursal.add_item("Quito - Centro")
		comboSucursal.add_item("Quito - Norte")
		comboSucursal.add_item("Guayaquil")
		comboSucursal.add_item("Cuenca")
		comboSucursal.add_item("Manta")
		comboSucursal.add_item("Ambato")
		comboSucursal.add_item("Portoviejo")
		comboSucursal.add_item("Machala")
	
	# Combo gravedad
	var comboGravedad = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad
	if comboGravedad:
		comboGravedad.clear()
		comboGravedad.add_item("Seleccionar gravedad*")
		comboGravedad.add_item("Leve (sin impacto operativo)")
		comboGravedad.add_item("Moderado (impacto parcial)")
		comboGravedad.add_item("Grave (impacto significativo)")
		comboGravedad.add_item("Crítico (paro operativo)")
	
	# Combo investigación
	var comboInvestigacion = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion
	if comboInvestigacion:
		comboInvestigacion.clear()
		comboInvestigacion.add_item("Seleccionar*")
		comboInvestigacion.add_item("Sí")
		comboInvestigacion.add_item("No")

func conectar_senales():
	# Botones principales
	if $ContentContainer/FormContainer/SeccionCliente/ClienteHBox/BtnBuscarCliente:
		$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/BtnBuscarCliente.pressed.connect(abrir_busqueda_cliente)
	
	if $ContentContainer/FormContainer/SeccionAcciones/BtnCancelar:
		$ContentContainer/FormContainer/SeccionAcciones/BtnCancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	if $ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar:
		$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.pressed.connect(validar_y_registrar)
	
	if $Header/HeaderHBox/BtnCerrar:
		$Header/HeaderHBox/BtnCerrar.pressed.connect(_on_btn_cerrar_pressed)
	
	# Diálogo de búsqueda de cliente
	if $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/BtnBuscarClienteDialog:
		$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/BtnBuscarClienteDialog.pressed.connect(buscar_cliente_bd)
	
	if $DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente:
		$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente.pressed.connect(seleccionar_cliente)
	
	if $DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnCancelarCliente:
		$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnCancelarCliente.pressed.connect(cerrar_busqueda_cliente)
	
	if $DialogoBuscarCliente:
		$DialogoBuscarCliente.close_requested.connect(cerrar_busqueda_cliente)
	
	# Botones de confirmación
	if $ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarSi:
		$ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarSi.pressed.connect(registrar_incidencia_cerrada)
	
	if $ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarNo:
		$ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarNo.pressed.connect(cerrar_confirmacion_estado)
	
	# Campos de texto
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text_changed.connect(
			func(_texto = ""): validar_formulario()
		)
	
	if $ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion:
		$ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text_changed.connect(
			func(): validar_formulario()
		)
	
	# Campo de fecha
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha.text_changed.connect(
			func(_texto = ""): validar_formulario()
		)
	
	# Combobox - usar funciones lambda para evitar problemas de parámetros
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo.item_selected.connect(
			func(_idx = -1): validar_formulario()
		)
	
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto.item_selected.connect(
			func(_idx = -1): validar_formulario()
		)
	
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal.item_selected.connect(
			func(_idx = -1): validar_formulario()
		)
	
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad.item_selected.connect(
			func(_idx = -1): validar_formulario()
		)
	
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion:
		$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion.item_selected.connect(
			func(_idx = -1): validar_formulario()
		)

func abrir_busqueda_cliente():
	$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text = ""
	$DialogoBuscarCliente/BuscarClienteVBox/TablaClientes.clear()
	$DialogoBuscarCliente.popup_centered()
	$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.grab_focus()
	
func cerrar_busqueda_cliente():
	$DialogoBuscarCliente.hide()

func buscar_cliente_bd():
	var termino = $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text.strip_edges()
	
	if termino == "":
		mostrar_error("Ingrese un término de búsqueda")
		return
	
	print("🔍 Buscando cliente: '" + termino + "'")
	
	# Buscar en base de datos simulada
	var clientes = db["buscar_cliente"].call(termino)
	
	# Mostrar resultados
	mostrar_clientes_en_tabla(clientes)

func mostrar_clientes_en_tabla(clientes: Array):
	var tabla = $DialogoBuscarCliente/BuscarClienteVBox/TablaClientes
	if not tabla:
		mostrar_error("Tabla de clientes no disponible")
		return
	
	tabla.clear()
	
	# Configurar columnas
	tabla.columns = 4
	
	# Establecer títulos de columnas
	tabla.set_column_title(0, "Código")
	tabla.set_column_title(1, "Nombre")
	tabla.set_column_title(2, "Email")
	tabla.set_column_title(3, "Teléfono")
	
	# Configurar ancho de columnas
	tabla.set_column_custom_minimum_width(0, 100)
	tabla.set_column_custom_minimum_width(1, 250)
	tabla.set_column_custom_minimum_width(2, 200)
	tabla.set_column_custom_minimum_width(3, 120)
	
	if clientes.size() == 0:
		mostrar_error("No se encontraron clientes para: '" + $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text + "'")
		$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente.disabled = true
		return
	
	var root = tabla.create_item()
	
	for cliente in clientes:
		var item = tabla.create_item(root)
		item.set_text(0, cliente.get("codigo_cliente", ""))
		item.set_text(1, cliente.get("nombre", "") + " " + cliente.get("apellidos", ""))
		item.set_text(2, cliente.get("email", ""))
		item.set_text(3, cliente.get("telefono", ""))
		
		# Guardar datos completos del cliente en metadata del item
		item.set_metadata(0, cliente)
	
	print("📊 Mostrando " + str(clientes.size()) + " cliente(s) encontrado(s)")
	$DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente.disabled = false

func seleccionar_cliente():
	var tabla = $DialogoBuscarCliente/BuscarClienteVBox/TablaClientes
	if not tabla:
		mostrar_error("Tabla de clientes no disponible")
		return
	
	var seleccionado = tabla.get_selected()
	
	if not seleccionado:
		mostrar_error("Seleccione un cliente de la lista")
		return
	
	cliente_seleccionado = seleccionado.get_metadata(0)
	
	# Mostrar información del cliente en el formulario
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = true
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelNombreCliente.text = "Nombre: " + cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelCodigoCliente.text = "Código: " + cliente_seleccionado.get("codigo_cliente", "")
	$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelContacto.text = "Contacto: " + cliente_seleccionado.get("email", "") + " / " + cliente_seleccionado.get("telefono", "")
	
	# Deshabilitar campo de búsqueda
	$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
	
	$DialogoBuscarCliente.hide()
	print("✅ Cliente seleccionado: " + cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", ""))
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
	else:
		# Validar formato de fecha (DD/MM/AAAA)
		var fecha_parts = inputFecha.text.split("/")
		if fecha_parts.size() != 3:
			campos_ok = false
		else:
			var dia = fecha_parts[0].to_int()
			var mes = fecha_parts[1].to_int()
			var anio = fecha_parts[2].to_int()
			
			if dia < 1 or dia > 31 or mes < 1 or mes > 12 or anio < 2000 or anio > 2100:
				campos_ok = false
	
	formulario_valido = campos_ok
	$ContentContainer/FormContainer/SeccionAcciones/BtnRegistrar.disabled = not formulario_valido
	
	# Actualizar variable requiere_investigacion basada en combo seleccionado
	var idxInvestigacion = comboInvestigacion.selected
	requiere_investigacion = (idxInvestigacion == 1)  # 1=Sí, 2=No
	
	return formulario_valido

func validar_y_registrar():
	if not validar_formulario():
		mostrar_error("Complete todos los campos obligatorios (*)")
		return
	
	print("✅ Formulario válido, procediendo con registro...")
	
	# Verificar si requiere investigación
	if not requiere_investigacion:  # "No" (no requiere investigación)
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
	# Generar código de incidencia
	var codigo_incidencia = db["generar_codigo_incidencia"].call()
	
	# Obtener datos del formulario
	var datos_incidencia = obtener_datos_formulario()
	datos_incidencia["codigo_incidencia"] = codigo_incidencia
	datos_incidencia["cliente_id"] = cliente_seleccionado.get("id", 0)
	datos_incidencia["cliente_nombre"] = cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
	datos_incidencia["cliente_codigo"] = cliente_seleccionado.get("codigo_cliente", "")
	datos_incidencia["estado"] = estado
	datos_incidencia["supervisor_id"] = usuario_actual.get("id", 1)
	datos_incidencia["supervisor_nombre"] = usuario_actual.get("nombre_completo", "")
	
	mostrar_carga("Registrando incidencia...")
	
	# Pequeña pausa para simular procesamiento
	await get_tree().create_timer(1.0).timeout
	
	# Registrar en base de datos simulada
	var incidencia_id = db["registrar_incidencia"].call(datos_incidencia)
	
	if incidencia_id > 0:
		# Registrar traza
		db["registrar_traza"].call(
			usuario_actual.get("id", 1),
			"REGISTRAR_INCIDENCIA",
			"Incidencias",
			"Incidente registrado: " + codigo_incidencia + " - " + datos_incidencia.get("titulo", "")
		)
		
		ocultar_carga()
		
		# Mostrar mensaje de éxito
		var mensaje = "✅ INCIDENCIA REGISTRADA EXITOSAMENTE\n\n"
		mensaje += "Código: " + codigo_incidencia + "\n"
		mensaje += "Cliente: " + cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "") + "\n"
		mensaje += "Estado: " + estado.to_upper() + "\n"
		mensaje += "Fecha: " + obtener_fecha_actual() + "\n\n"
		
		if estado == "cerrada":
			mensaje += "🔒 ESTADO: CERRADO (No requiere investigación)\n"
		else:
			mensaje += "🔓 ESTADO: ABIERTO (Requiere investigación)\n"
		
		mensaje += "\nLa incidencia ha sido registrada en el sistema."
		
		mostrar_exito(mensaje)
		
		# Emitir señal
		incidencia_registrada.emit(codigo_incidencia, datos_incidencia)
		
		# Limpiar formulario después de éxito
		limpiar_formulario()
	else:
		ocultar_carga()
		mostrar_error("Error al registrar la incidencia en el sistema")

func obtener_datos_formulario() -> Dictionary:
	# Obtener tipo de hallazgo
	var comboTipo = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo
	var tipo_hallazgo = comboTipo.get_item_text(comboTipo.selected) if comboTipo.selected > 0 else ""
	
	# Obtener producto/servicio
	var comboProducto = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto
	var producto_servicio = comboProducto.get_item_text(comboProducto.selected) if comboProducto.selected > 0 else ""
	
	# Obtener sucursal
	var comboSucursal = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal
	var sucursal = comboSucursal.get_item_text(comboSucursal.selected) if comboSucursal.selected > 0 else ""
	
	# Obtener gravedad
	var comboGravedad = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad
	var nivel_gravedad = comboGravedad.get_item_text(comboGravedad.selected) if comboGravedad.selected > 0 else ""
	
	# Convertir fecha de formato DD/MM/AAAA a AAAA-MM-DD
	var inputFecha = $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputFecha
	var fecha_parts = inputFecha.text.split("/")
	var fecha_sql = ""
	if fecha_parts.size() == 3:
		fecha_sql = "%s-%s-%s" % [fecha_parts[2], fecha_parts[1].pad_zeros(2), fecha_parts[0].pad_zeros(2)]
	else:
		fecha_sql = obtener_fecha_actual_sql()
	
	return {
		"titulo": $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text.strip_edges(),
		"descripcion": $ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text.strip_edges(),
		"tipo_hallazgo": tipo_hallazgo,
		"producto_servicio": producto_servicio,
		"sucursal": sucursal,
		"fecha_ocurrencia": fecha_sql,
		"nivel_gravedad": nivel_gravedad,
		"requiere_investigacion": 1 if requiere_investigacion else 0,
		"observaciones": "Registrado desde sistema de pruebas"
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
	
	print("🧹 Formulario limpiado")

func _on_btn_cancelar_pressed():
	cerrar_formulario()

func _on_btn_cerrar_pressed():
	cerrar_formulario()

func cerrar_formulario():
	# Verificar si hay datos ingresados
	var hay_datos = false
	
	# Verificar campos principales
	if $ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text != "":
		hay_datos = true
	
	if $ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text != "":
		hay_datos = true
	
	if $ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text != "":
		hay_datos = true
	
	if hay_datos:
		# Mostrar diálogo de confirmación
		var confirmacion = AcceptDialog.new()
		confirmacion.title = "Confirmar Salida"
		confirmacion.dialog_text = "⚠️ Tiene datos sin guardar.\n¿Está seguro que desea salir?"
		confirmacion.get_ok_button().text = "Sí, salir"
		confirmacion.add_cancel_button("No, quedarme")
		
		confirmacion.confirmed.connect(func():
			confirmacion.queue_free()
			volver_al_menu()
		)
		
		confirmacion.canceled.connect(func():
			confirmacion.queue_free()
		)
		
		add_child(confirmacion)
		confirmacion.popup_centered()
	else:
		volver_al_menu()

func volver_al_menu():
	print("↩️ Volviendo al menú principal...")
	
	# Intentar cargar diferentes rutas posibles del menú
	var rutas_posibles = [
		"res://menu_principal.tscn",
		"res://escenas/menu_principal.tscn",
		"res://scenes/menu_principal.tscn",
		"res://MenuPrincipal.tscn",
		"res://MainMenu.tscn",
		"res://interfaces/MenuPrincipal.tscn"
	]
	
	for ruta in rutas_posibles:
		if ResourceLoader.exists(ruta):
			print("📍 Cargando: " + ruta)
			get_tree().change_scene_to_file(ruta)
			return
	
	# Si no se encuentra, mostrar error y ofrecer cerrar
	print("❌ No se encontró la escena del menú principal")
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = "No se pudo encontrar el menú principal.\n¿Desea cerrar la aplicación?"
	error_dialog.get_ok_button().text = "Sí, cerrar"
	error_dialog.add_cancel_button("No, quedarme")
	
	error_dialog.confirmed.connect(func():
		get_tree().quit()
	)
	
	add_child(error_dialog)
	error_dialog.popup_centered()
	
func obtener_fecha_actual() -> String:
	var fecha = Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [fecha.day, fecha.month, fecha.year]

func obtener_fecha_actual_sql() -> String:
	var fecha = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [fecha.year, fecha.month, fecha.day]

func mostrar_carga(mensaje: String):
	$PanelCargando/MensajeCarga.text = mensaje
	$PanelCargando.visible = true

func ocultar_carga():
	$PanelCargando.visible = false

func mostrar_exito(mensaje: String):
	$MensajeExito.dialog_text = mensaje
	$MensajeExito.popup_centered()

func mostrar_error(mensaje: String):
	error_registro.emit(mensaje)  # Emitir la señal
	$MensajeError.dialog_text = mensaje
	$MensajeError.popup_centered()

func _process(_delta):
	# Animación de barra de progreso
	if $PanelCargando.visible:
		var progress = $PanelCargando/ProgressBar
		if progress:
			progress.value = fmod(progress.value + 2.0, 100.0)

# ==================== FUNCIONES DE PRUEBA Y DIAGNÓSTICO ====================

func mostrar_estado_sistema():
	print("\n=== ESTADO DEL SISTEMA ===")
	print("📋 Clientes de prueba: " + str(clientes_falsos.size()))
	print("📝 Incidencias registradas: " + str(incidencias_registradas.size()))
	print("👤 Usuario actual: " + usuario_actual.get("nombre_completo", ""))
	print("✅ Cliente seleccionado: " + ("Sí" if cliente_seleccionado and not cliente_seleccionado.is_empty() else "No"))
	print("📊 Formulario válido: " + str(formulario_valido))
	print("🔍 Requiere investigación: " + str(requiere_investigacion))
	print("==========================\n")

# Función para probar búsqueda rápida
func prueba_busqueda_rapida():
	print("🧪 Iniciando prueba de búsqueda...")
	$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text = "Juan"
	buscar_cliente_bd()

# Función para llenar formulario automáticamente para pruebas
func prueba_formulario_completo():
	print("🧪 Llenando formulario automáticamente...")
	
	# Seleccionar primer cliente
	if clientes_falsos.size() > 0:
		cliente_seleccionado = clientes_falsos[0]
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = true
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelNombreCliente.text = "Nombre: " + cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
		$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
	
	# Llenar campos
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/InputTitulo.text = "Prueba: Retraso en entrega de paquete turístico"
	$ContentContainer/FormContainer/SeccionIncidencia/InputDescripcion.text = "El cliente reporta que su paquete turístico no fue entregado en la fecha acordada, causando inconvenientes en su viaje programado."
	
	# Seleccionar combos
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboTipo.select(1)  # Retraso en servicio
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboProducto.select(1)  # Paquete turístico
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboSucursal.select(1)  # Quito - Centro
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboGravedad.select(2)  # Moderado
	$ContentContainer/FormContainer/SeccionIncidencia/GridContainer/ComboInvestigacion.select(1)  # Sí
	
	validar_formulario()
	print("✅ Formulario llenado automáticamente")
	mostrar_estado_sistema()
