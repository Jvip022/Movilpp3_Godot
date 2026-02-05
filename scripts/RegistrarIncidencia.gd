extends Control
class_name RegistrarIncidencia

# Señales
signal incidencia_registrada(codigo_incidencia: String, datos: Dictionary)
signal error_registro(mensaje: String)

# Variables de conexión a base de datos
var db = Bd.db
var usuario_actual: Dictionary = {}
var cliente_seleccionado: Dictionary = {}

# Variables de estado
var formulario_valido: bool = false
var requiere_investigacion: bool = true

# Base de datos simulada
var clientes_falsos: Array = []
var incidencias_registradas: Array = []
var codigo_incidencia_counter: int = 1000

func _ready():
	print("🔧 Inicializando módulo de Registrar Incidencia...")
	
	# Inicializar datos de prueba
	inicializar_datos_prueba()
	
	# Cargar usuario actual (simulado para pruebas)
	cargar_usuario_actual()
	
	# Inicializar la interfaz visual
	inicializar_interfaz()
	
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
		}
	]
	
	print("📋 Cargados " + str(clientes_falsos.size()) + " clientes de prueba")
	
	# Crear base de datos simulada
	db = {
		"buscar_cliente": func(termino: String) -> Array:
			return await buscar_cliente_simulado(termino),
		
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
	
	# Pequeña pausa para simular procesamiento (no bloqueante)
	await get_tree().create_timer(0.1).timeout
	
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
	print("🎨 Inicializando interfaz...")
	
	# Esperar un frame para asegurar que todos los nodos estén cargados
	await get_tree().process_frame
	
	# Inicializar combos
	inicializar_combos()
	
	# Configurar diálogo de búsqueda de cliente
	if has_node("DialogoBuscarCliente"):
		$DialogoBuscarCliente.size = Vector2(700, 500)
		$DialogoBuscarCliente.min_size = Vector2(700, 500)
	
	# Conectar señales
	conectar_senales()
	
	# Configurar fecha actual
	var inputFecha = find_child("InputFecha", true, false)
	if inputFecha:
		inputFecha.text = obtener_fecha_actual()
	
	# Deshabilitar botón registrar inicialmente
	var btnRegistrar = find_child("BtnRegistrar", true, false)
	if btnRegistrar:
		btnRegistrar.disabled = true
	
	print("✅ Interfaz inicializada")

func inicializar_combos():
	print("⚙️ Inicializando combos...")
	
	# Mapeo de nombres lógicos a nombres reales en la escena
	var nombre_mapping = {
		"ComboTipo": "ComboTipo",
		"ComboProducto": "ComboProducto", 
		"ComboSucursal": "ComboSucursal",
		"ComboGravedad": "ComboGravedad",
		"ComboInvestigacion": "ComboInvestigacion"
	}
	
	# Datos para cada combo
	var combos_data = {
		"ComboTipo": ["Seleccionar tipo*", "Retraso en servicio", "Defecto de producto", 
					 "Error en servicio", "Atención al cliente", "Problema logístico", "Otro"],
		"ComboProducto": ["Seleccionar producto/servicio*", "Paquete turístico", "Hospedaje",
					 "Transporte aéreo", "Transporte terrestre", "Excursión", 
					 "Seguro de viaje", "Alquiler de auto", "Asistencia al viajero", "Tour guiado"],
		"ComboSucursal": ["Seleccionar sucursal*","Pinar del Río" ,"Artemisa","La Habana","Mayabeque" ,"Matanzas" ,"Cienfuegos" ,"Villa Clara","Sancti Spíritus","Ciego de Ávila" ,"Camagüey","Las Tunas" ,"Granma" ,"Holguín" ,"Santiago", "Guantánamo" ],
		"ComboGravedad": ["Seleccionar gravedad*", "Leve (sin impacto operativo)", 
					 "Moderado (impacto parcial)", "Grave (impacto significativo)", 
					 "Crítico (paro operativo)"],
		"ComboInvestigacion": ["Seleccionar*", "Sí", "No"]
	}
	
	for nombre_logico in combos_data.keys():
		var nombre_real = nombre_mapping.get(nombre_logico, nombre_logico)
		var combo = find_child(nombre_real, true, false)
		
		if combo:
			combo.clear()
			for item in combos_data[nombre_logico]:
				combo.add_item(item)
			print("✅ Inicializado: " + nombre_logico + " (nodo: " + nombre_real + ")")
		else:
			print("⚠️ No se encontró: " + nombre_logico + " (buscando: " + nombre_real + ")")

func conectar_senales():
	print("🔌 Conectando señales...")
	
	# Botones principales
	var btnBuscarCliente = find_child("BtnBuscarCliente", true, false)
	if btnBuscarCliente:
		btnBuscarCliente.pressed.connect(abrir_busqueda_cliente)
	
	var btnCancelar = find_child("BtnCancelar", true, false)
	if btnCancelar:
		btnCancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	var btnRegistrar = find_child("BtnRegistrar", true, false)
	if btnRegistrar:
		btnRegistrar.pressed.connect(validar_y_registrar)
	
	var btnCerrar = find_child("BtnCerrar", true, false)
	if btnCerrar:
		btnCerrar.pressed.connect(_on_btn_cerrar_pressed)
	
	# Diálogo de búsqueda de cliente
	var btnBuscarClienteDialog = get_node_or_null("DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/BtnBuscarClienteDialog")
	if btnBuscarClienteDialog:
		btnBuscarClienteDialog.pressed.connect(buscar_cliente_bd_safe)
	
	var btnSeleccionarCliente = get_node_or_null("DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente")
	if btnSeleccionarCliente:
		btnSeleccionarCliente.pressed.connect(seleccionar_cliente)
	
	var btnCancelarCliente = get_node_or_null("DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnCancelarCliente")
	if btnCancelarCliente:
		btnCancelarCliente.pressed.connect(cerrar_busqueda_cliente)
	
	if has_node("DialogoBuscarCliente"):
		$DialogoBuscarCliente.close_requested.connect(cerrar_busqueda_cliente)
	
	# Botones de confirmación
	if has_node("ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarSi"):
		$ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarSi.pressed.connect(registrar_incidencia_cerrada)
	
	if has_node("ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarNo"):
		$ConfirmacionEstado/ConfirmacionVBox/BotonesConfirmacion/BtnConfirmarNo.pressed.connect(cerrar_confirmacion_estado)
	
	# Campos de texto
	var inputTitulo = find_child("InputTitulo", true, false)
	if inputTitulo:
		inputTitulo.text_changed.connect(
			func(_texto = ""): validar_formulario()
		)
	
	var inputDescripcion = find_child("InputDescripcion", true, false)
	if inputDescripcion:
		inputDescripcion.text_changed.connect(
			func(): validar_formulario()
		)
	
	# Campo de fecha
	var inputFecha = find_child("InputFecha", true, false)
	if inputFecha:
		inputFecha.text_changed.connect(
			func(_texto = ""): validar_formulario()
		)
	
	# Combobox
	var comboNombres = ["ComboTipo", "ComboProducto", "s", "ComboGravedad", "ComboInvestigacion"]
	for nombre in comboNombres:
		var combo = find_child(nombre, true, false)
		if combo:
			combo.item_selected.connect(
				func(_idx = -1): validar_formulario()
			)
	
	print("✅ Señales conectadas")

func abrir_busqueda_cliente():
	print("📂 Abriendo búsqueda de cliente...")
	
	if has_node("DialogoBuscarCliente"):
		$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text = ""
		
		var tabla = $DialogoBuscarCliente/BuscarClienteVBox/TablaClientes
		if tabla:
			tabla.clear()
		
		$DialogoBuscarCliente.popup_centered()
		
		var inputBuscar = $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente
		if inputBuscar:
			inputBuscar.grab_focus()
	
func cerrar_busqueda_cliente():
	if has_node("DialogoBuscarCliente"):
		$DialogoBuscarCliente.hide()

func buscar_cliente_bd_safe():
	print("🔍 Iniciando búsqueda segura...")
	
	if not has_node("DialogoBuscarCliente"):
		print("❌ Diálogo no encontrado")
		return
	
	var inputBuscar = $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente
	if not inputBuscar:
		print("❌ Campo de búsqueda no encontrado")
		return
	
	var termino = inputBuscar.text.strip_edges()
	
	if termino == "":
		mostrar_error("Ingrese un término de búsqueda")
		return
	
	print("🔍 Buscando cliente: '" + termino + "'")
	
	# Deshabilitar botón temporalmente
	var btnBuscar = $DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/BtnBuscarClienteDialog
	if btnBuscar:
		btnBuscar.disabled = true
		btnBuscar.text = "Buscando..."
	
	# Permitir que se procesen eventos de la interfaz
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	
	# Realizar búsqueda (ahora es asíncrona) con manejo de errores simplificado
	var clientes = []
	
	# En GDScript no hay try-catch, usamos un método simple
	var resultado = await db["buscar_cliente"].call(termino)
	
	if resultado is Array:
		clientes = resultado
	else:
		print("❌ Error en búsqueda: resultado no es un array")
		mostrar_error("Error al buscar clientes")
		# Restaurar botón
		if btnBuscar:
			btnBuscar.disabled = false
			btnBuscar.text = "Buscar en Base Datos"
		return
	
	# Mostrar resultados
	mostrar_clientes_en_tabla(clientes)
	
	# Restaurar botón
	if btnBuscar:
		btnBuscar.disabled = false
		btnBuscar.text = "Buscar en Base Datos"
	
	print("✅ Búsqueda completada")

func mostrar_clientes_en_tabla(clientes: Array):
	print("📊 Mostrando " + str(clientes.size()) + " clientes en tabla")
	
	if not has_node("DialogoBuscarCliente"):
		print("❌ Diálogo no encontrado")
		return
	
	var tabla = $DialogoBuscarCliente/BuscarClienteVBox/TablaClientes
	if not tabla:
		print("❌ Tabla no encontrada")
		return
	
	# Limpiar tabla
	tabla.clear()
	tabla.columns = 4
	tabla.set_column_title(0, "Código")
	tabla.set_column_title(1, "Nombre")
	tabla.set_column_title(2, "Email")
	tabla.set_column_title(3, "Teléfono")
	
	# Configurar ancho de columnas
	tabla.set_column_custom_minimum_width(0, 100)
	tabla.set_column_custom_minimum_width(1, 250)
	tabla.set_column_custom_minimum_width(2, 200)
	tabla.set_column_custom_minimum_width(3, 120)
	
	# Obtener referencia al botón UNA SOLA VEZ
	var btnSeleccionar = $DialogoBuscarCliente/BuscarClienteVBox/BotonesSeleccionCliente/BtnSeleccionarCliente
	
	if clientes.size() == 0:
		print("ℹ️ No se encontraron resultados")
		if btnSeleccionar:
			btnSeleccionar.disabled = true
		return
	
	# Crear items (sin root para simplificar)
	for i in range(clientes.size()):
		var cliente = clientes[i]
		var item = tabla.create_item()
		item.set_text(0, cliente.get("codigo_cliente", ""))
		item.set_text(1, cliente.get("nombre", "") + " " + cliente.get("apellidos", ""))
		item.set_text(2, cliente.get("email", ""))
		item.set_text(3, cliente.get("telefono", ""))
		item.set_metadata(0, cliente)
		
		# Permitir que se procesen eventos periódicamente
		if i % 5 == 0:
			await get_tree().process_frame
	
	print("✅ Tabla actualizada con " + str(clientes.size()) + " clientes")
	
	if btnSeleccionar:
		btnSeleccionar.disabled = false

func seleccionar_cliente():
	print("✅ Seleccionando cliente...")
	
	if not has_node("DialogoBuscarCliente"):
		return
	
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
	if has_node("ContentContainer/FormContainer/SeccionCliente/InfoCliente"):
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = true
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelNombreCliente.text = "Nombre: " + cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelCodigoCliente.text = "Código: " + cliente_seleccionado.get("codigo_cliente", "")
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelContacto.text = "Contacto: " + cliente_seleccionado.get("email", "") + " / " + cliente_seleccionado.get("telefono", "")
	
	# Actualizar campo de búsqueda
	if has_node("ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente"):
		$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
	
	$DialogoBuscarCliente.hide()
	print("✅ Cliente seleccionado: " + cliente_seleccionado.get("nombre", ""))
	validar_formulario()

func validar_formulario():
	# Verificar campos obligatorios
	var campos_ok = true
	
	# Cliente seleccionado
	if not cliente_seleccionado or cliente_seleccionado.is_empty():
		campos_ok = false
	
	# Campos de incidencia
	var inputTitulo = find_child("InputTitulo", true, false)
	if inputTitulo and inputTitulo.text.strip_edges() == "":
		campos_ok = false
	
	var comboInvestigacion = find_child("ComboInvestigacion", true, false)
	if comboInvestigacion and comboInvestigacion.selected <= 0:
		campos_ok = false
	
	var inputDescripcion = find_child("InputDescripcion", true, false)
	if inputDescripcion and inputDescripcion.text.strip_edges() == "":
		campos_ok = false
	
	# Combo boxes
	var combos = [
		find_child("ComboTipo", true, false),
		find_child("ComboProducto", true, false),
		find_child("s", true, false),  # Nodo real para sucursal
		find_child("ComboGravedad", true, false)
	]
	
	for combo in combos:
		if combo and combo.selected <= 0:
			campos_ok = false
	
	# Fecha de ocurrencia
	var inputFecha = find_child("InputFecha", true, false)
	if inputFecha:
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
	
	var btnRegistrar = find_child("BtnRegistrar", true, false)
	if btnRegistrar:
		btnRegistrar.disabled = not formulario_valido
	
	# Actualizar variable requiere_investigacion
	if comboInvestigacion:
		requiere_investigacion = (comboInvestigacion.selected == 1)  # 1=Sí, 2=No
	
	return formulario_valido

func validar_y_registrar():
	if not validar_formulario():
		mostrar_error("Complete todos los campos obligatorios (*)")
		return
	
	print("✅ Formulario válido, procediendo con registro...")
	
	# Verificar si requiere investigación
	if not requiere_investigacion:  # "No" (no requiere investigación)
		# Mostrar diálogo de confirmación
		if has_node("ConfirmacionEstado"):
			$ConfirmacionEstado.popup_centered()
	else:
		registrar_incidencia_abierta()

func registrar_incidencia_abierta():
	# Registrar incidencia con estado "abierta" (requiere investigación)
	registrar_incidencia_con_estado("abierta")

func registrar_incidencia_cerrada():
	# Registrar incidencia con estado "cerrada" (no requiere investigación)
	registrar_incidencia_con_estado("cerrada")
	if has_node("ConfirmacionEstado"):
		$ConfirmacionEstado.hide()

func cerrar_confirmacion_estado():
	if has_node("ConfirmacionEstado"):
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
	var comboTipo = find_child("ComboTipo", true, false)
	var tipo_hallazgo = comboTipo.get_item_text(comboTipo.selected) if comboTipo and comboTipo.selected > 0 else ""
	
	# Obtener producto/servicio
	var comboProducto = find_child("ComboProducto", true, false)
	var producto_servicio = comboProducto.get_item_text(comboProducto.selected) if comboProducto and comboProducto.selected > 0 else ""
	
	# Obtener sucursal - usar nodo real "s"
	var comboSucursal = find_child("s", true, false)
	var sucursal = comboSucursal.get_item_text(comboSucursal.selected) if comboSucursal and comboSucursal.selected > 0 else ""
	
	# Obtener gravedad
	var comboGravedad = find_child("ComboGravedad", true, false)
	var nivel_gravedad = comboGravedad.get_item_text(comboGravedad.selected) if comboGravedad and comboGravedad.selected > 0 else ""
	
	# Convertir fecha de formato DD/MM/AAAA a AAAA-MM-DD
	var inputFecha = find_child("InputFecha", true, false)
	var fecha_sql = obtener_fecha_actual_sql()
	if inputFecha:
		var fecha_parts = inputFecha.text.split("/")
		if fecha_parts.size() == 3:
			fecha_sql = "%s-%s-%s" % [fecha_parts[2], fecha_parts[1].pad_zeros(2), fecha_parts[0].pad_zeros(2)]
	
	return {
		"titulo": find_child("InputTitulo", true, false).text.strip_edges() if find_child("InputTitulo", true, false) else "",
		"descripcion": find_child("InputDescripcion", true, false).text.strip_edges() if find_child("InputDescripcion", true, false) else "",
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
	if has_node("ContentContainer/FormContainer/SeccionCliente/InfoCliente"):
		$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = false
		$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = ""
	
	# Limpiar campos de incidencia
	var inputTitulo = find_child("InputTitulo", true, false)
	if inputTitulo:
		inputTitulo.text = ""
	
	var inputFecha = find_child("InputFecha", true, false)
	if inputFecha:
		inputFecha.text = obtener_fecha_actual()
	
	var inputDescripcion = find_child("InputDescripcion", true, false)
	if inputDescripcion:
		inputDescripcion.text = ""
	
	# Resetear combos
	var combos = ["ComboTipo", "ComboProducto", "s", "ComboGravedad", "ComboInvestigacion"]
	for nombre in combos:
		var combo = find_child(nombre, true, false)
		if combo:
			combo.select(0)
	
	# Restablecer variable requiere_investigacion a su valor por defecto
	requiere_investigacion = true
	
	# Deshabilitar botón registrar
	var btnRegistrar = find_child("BtnRegistrar", true, false)
	if btnRegistrar:
		btnRegistrar.disabled = true
	
	print("🧹 Formulario limpiado")

func _on_btn_cancelar_pressed():
	cerrar_formulario()

func _on_btn_cerrar_pressed():
	cerrar_formulario()

func cerrar_formulario():
	# Verificar si hay datos ingresados
	var hay_datos = false
	
	# Verificar campos principales
	if has_node("ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente"):
		if $ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text != "":
			hay_datos = true
	
	var inputTitulo = find_child("InputTitulo", true, false)
	if inputTitulo and inputTitulo.text != "":
		hay_datos = true
	
	var inputDescripcion = find_child("InputDescripcion", true, false)
	if inputDescripcion and inputDescripcion.text != "":
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
	if has_node("PanelCargando"):
		$PanelCargando/MensajeCarga.text = mensaje
		$PanelCargando.visible = true

func ocultar_carga():
	if has_node("PanelCargando"):
		$PanelCargando.visible = false

func mostrar_exito(mensaje: String):
	if has_node("MensajeExito"):
		$MensajeExito.dialog_text = mensaje
		$MensajeExito.popup_centered()

func mostrar_error(mensaje: String):
	error_registro.emit(mensaje)  # Emitir la señal
	if has_node("MensajeError"):
		$MensajeError.dialog_text = mensaje
		$MensajeError.popup_centered()

func _process(_delta):
	# Animación de barra de progreso
	if has_node("PanelCargando") and $PanelCargando.visible:
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
	if has_node("DialogoBuscarCliente"):
		$DialogoBuscarCliente/BuscarClienteVBox/BuscarClienteHBox/InputBuscarCliente.text = "Juan"
		buscar_cliente_bd_safe()

# Función para llenar formulario automáticamente para pruebas
func prueba_formulario_completo():
	print("🧪 Llenando formulario automáticamente...")
	
	# Seleccionar primer cliente
	if clientes_falsos.size() > 0:
		cliente_seleccionado = clientes_falsos[0]
		if has_node("ContentContainer/FormContainer/SeccionCliente/InfoCliente"):
			$ContentContainer/FormContainer/SeccionCliente/InfoCliente.visible = true
			$ContentContainer/FormContainer/SeccionCliente/InfoCliente/LabelNombreCliente.text = "Nombre: " + cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
			$ContentContainer/FormContainer/SeccionCliente/ClienteHBox/InputCliente.text = cliente_seleccionado.get("nombre", "") + " " + cliente_seleccionado.get("apellidos", "")
	
	# Llenar campos
	var inputTitulo = find_child("InputTitulo", true, false)
	if inputTitulo:
		inputTitulo.text = "Prueba: Retraso en entrega de paquete turístico"
	
	var inputDescripcion = find_child("InputDescripcion", true, false)
	if inputDescripcion:
		inputDescripcion.text = "El cliente reporta que su paquete turístico no fue entregado en la fecha acordada, causando inconvenientes en su viaje programado."
	
	# Seleccionar combos
	var comboTipo = find_child("ComboTipo", true, false)
	if comboTipo:
		comboTipo.select(1)  # Retraso en servicio
	
	var comboProducto = find_child("ComboProducto", true, false)
	if comboProducto:
		comboProducto.select(1)  # Paquete turístico
	
	var comboSucursal = find_child("s", true, false)
	if comboSucursal:
		comboSucursal.select(1)  # Quito - Centro
	
	var comboGravedad = find_child("ComboGravedad", true, false)
	if comboGravedad:
		comboGravedad.select(2)  # Moderado
	
	var comboInvestigacion = find_child("ComboInvestigacion", true, false)
	if comboInvestigacion:
		comboInvestigacion.select(1)  # Sí
	
	validar_formulario()
	print("✅ Formulario llenado automáticamente")
	mostrar_estado_sistema()
