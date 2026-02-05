extends Node
class_name BD

var db: SQLite
var database_path := "res://data/quejas.db"

# =========================
# CICLO DE VIDA
# =========================
func _ready():
	print("🔧 Inicializando Base de Datos...")
	
	if not ClassDB.class_exists("SQLite"):
		push_error("❌ El plugin SQLite no está disponible")
		return
	
	_preparar_directorio()
	_abrir_bd()
	_habilitar_fk()
	
	if not crear_tablas_base():
		push_error("❌ Error creando tablas base")
		return
	
	if not crear_tablas_dominio():
		push_error("❌ Error creando tablas de dominio")
		return
	
	# Crear tablas adicionales del sistema antiguo
	if not crear_tablas_quejas():
		push_error("❌ Error creando tablas de quejas")
		return
	
	if not crear_tablas_calidad():
		push_error("❌ Error creando tablas de calidad")
		return
	
	if not crear_tablas_no_conformidades():
		push_error("❌ Error creando tablas de no conformidades")
		return
	
	inicializar_roles_y_permisos()
	inicializar_usuario_admin()
	
	print("✅ Base de datos lista y operativa")
	
	# Pruebas de conexión
	test_conexion()
	call_deferred("inspeccionar_bd")

# =========================
# INICIALIZACIÓN
# =========================
func _preparar_directorio():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://data"):
		if dir.make_dir("res://data") != OK:
			push_error("No se pudo crear el directorio data")

func _abrir_bd():
	db = SQLite.new()
	db.path = database_path
	
	print("🔓 Abriendo base de datos en: " + database_path)
	if not db.open_db():
		push_error("❌ No se pudo abrir la base de datos: " + database_path)
		# Intentar crear una base de datos vacía
		print("🆕 Intentando crear nueva base de datos...")
		if not db.open_db():
			push_error("❌ Fatal: No se pudo crear/abrir la base de datos")
	else:
		print("✅ Base de datos abierta correctamente")

func _habilitar_fk():
	query("PRAGMA foreign_keys = ON;")

# =========================
# CREACIÓN DE TABLAS - NUEVA ESTRUCTURA
# =========================
func crear_tablas_base() -> bool:
	return (
		_crear_tabla_roles()
		and _crear_tabla_permisos()
		and _crear_tabla_rol_permiso()
		and _crear_tabla_usuarios_nueva()
		and _crear_tabla_auditoria()
	)

func crear_tablas_dominio() -> bool:
	return (
		_crear_tabla_expedientes()
		and _crear_tabla_incidencias()
	)

# ---------- SEGURIDAD (Nueva estructura) ----------
func _crear_tabla_roles() -> bool:
	return query("""
		CREATE TABLE IF NOT EXISTS roles (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			nombre TEXT UNIQUE NOT NULL,
			descripcion TEXT
		)
	""")

func _crear_tabla_permisos() -> bool:
	return query("""
		CREATE TABLE IF NOT EXISTS permisos (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			nombre TEXT UNIQUE NOT NULL,
			descripcion TEXT
		)
	""")

func _crear_tabla_rol_permiso() -> bool:
	return query("""
		CREATE TABLE IF NOT EXISTS rol_permiso (
			rol_id INTEGER NOT NULL,
			permiso_id INTEGER NOT NULL,
			PRIMARY KEY (rol_id, permiso_id),
			FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE,
			FOREIGN KEY (permiso_id) REFERENCES permisos(id) ON DELETE CASCADE
		)
	""")

func _crear_tabla_usuarios_nueva() -> bool:
	# Tabla de usuarios simplificada para la nueva estructura
	return query("""
		CREATE TABLE IF NOT EXISTS usuarios_nueva (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			nombre TEXT,
			email TEXT,
			rol_id INTEGER NOT NULL,
			activo INTEGER DEFAULT 1,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME,
			FOREIGN KEY (rol_id) REFERENCES roles(id)
		)
	""")

func _crear_tabla_auditoria() -> bool:
	return query("""
		CREATE TABLE IF NOT EXISTS auditoria (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER,
			accion TEXT NOT NULL,
			escena TEXT,
			detalles TEXT,
			fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES usuarios_nueva(id)
		)
	""")

# ---------- DOMINIO (Nueva estructura) ----------
func _crear_tabla_expedientes() -> bool:
	return query("""
		CREATE TABLE IF NOT EXISTS expedientes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			titulo TEXT,
			descripcion TEXT,
			estado TEXT,
			user_id INTEGER,
			gestor_id INTEGER,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			fecha_actualizacion DATETIME,
			FOREIGN KEY (user_id) REFERENCES usuarios_nueva(id),
			FOREIGN KEY (gestor_id) REFERENCES usuarios_nueva(id)
		)
	""")

func _crear_tabla_incidencias() -> bool:
	return query("""
		CREATE TABLE IF NOT EXISTS incidencias_nueva (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			expediente_id INTEGER NOT NULL,
			descripcion TEXT NOT NULL,
			creada_por INTEGER,
			estado TEXT,
			fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (expediente_id) REFERENCES expedientes(id) ON DELETE CASCADE,
			FOREIGN KEY (creada_por) REFERENCES usuarios_nueva(id)
		)
	""")

# =========================
# CREACIÓN DE TABLAS - ESTRUCTURA ANTIGUA (MANTENIDA)
# =========================
func crear_tablas_quejas() -> bool:
	print("=== CREANDO TABLAS DE LA BASE DE DATOS ===")
	
	# Tabla de USUARIOS para autenticación (estructura antigua)
	print("Creando tabla 'usuarios'...")
	var sql_usuarios = """
		CREATE TABLE IF NOT EXISTS usuarios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			email TEXT UNIQUE NOT NULL,
			nombre_completo TEXT NOT NULL,
			avatar TEXT DEFAULT 'default.png',
			telefono TEXT,
			departamento TEXT,
			cargo TEXT,
			fecha_contratacion DATE,
			estado_empleado TEXT DEFAULT 'activo',
			rol TEXT DEFAULT 'operador',
			permisos TEXT DEFAULT '["ver_dashboard", "crear_queja", "editar_perfil"]',
			tema_preferido TEXT DEFAULT 'claro',
			idioma TEXT DEFAULT 'es',
			zona_horaria TEXT DEFAULT 'America/Lima',
			notificaciones_email INTEGER DEFAULT 1,
			notificaciones_push INTEGER DEFAULT 1,
			ultimo_login DATETIME,
			intentos_fallidos INTEGER DEFAULT 0,
			bloqueado_hasta DATETIME,
			requiere_cambio_password INTEGER DEFAULT 0,
			token_recuperacion TEXT,
			token_expiracion DATETIME,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			creado_por INTEGER,
			fecha_modificacion DATETIME,
			modificado_por INTEGER,
			sesiones_activas INTEGER DEFAULT 0,
			preferencias TEXT DEFAULT '{}'
		)
	"""
	
	if not query(sql_usuarios):
		push_error("ERROR: No se pudo crear la tabla 'usuarios'")
		return false
	
	# Tabla de HISTORIAL de actividad de usuarios
	print("Creando tabla 'historial_usuarios'...")
	if not query("""
		CREATE TABLE IF NOT EXISTS historial_usuarios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			usuario_id INTEGER NOT NULL,
			fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
			tipo_evento TEXT,
			descripcion TEXT NOT NULL,
			ip_address TEXT,
			user_agent TEXT,
			detalles TEXT
		)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'historial_usuarios'")
		return false
	
	# Tabla principal de QUEJAS y RECLAMACIONES
	print("Verificando y recreando tabla 'quejas_reclamaciones'...")
	query("DROP TABLE IF EXISTS quejas_reclamaciones")
	
	if not query("""
		CREATE TABLE IF NOT EXISTS quejas_reclamaciones (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			numero_caso TEXT UNIQUE,
			tipo_caso TEXT,
			canal_entrada TEXT,
			tipo_reclamante TEXT,
			identificacion TEXT,
			nombres TEXT NOT NULL,
			apellidos TEXT,
			telefono TEXT,
			email TEXT,
			direccion TEXT,
			asunto TEXT NOT NULL,
			descripcion_detallada TEXT NOT NULL,
			producto_servicio TEXT,
			numero_contrato TEXT,
			numero_factura TEXT,
			fecha_incidente DATE,
			lugar_incidente TEXT,
			categoria TEXT,
			subcategoria TEXT,
			monto_reclamado REAL DEFAULT 0,
			moneda TEXT DEFAULT 'USD',
			tipo_compensacion TEXT,
			prioridad TEXT,
			estado TEXT,
			nivel_escalamiento INTEGER DEFAULT 1,
			recibido_por INTEGER,
			asignado_a INTEGER,
			equipo_responsable TEXT,
			fecha_recepcion DATETIME DEFAULT CURRENT_TIMESTAMP,
			fecha_limite_respuesta DATE,
			fecha_respuesta_cliente DATE,
			fecha_cierre DATETIME,
			hechos_constatados TEXT,
			pruebas_adjuntas TEXT,
			testigos TEXT,
			responsable_interno TEXT,
			decision TEXT,
			solucion_propuesta TEXT,
			compensacion_otorgada REAL DEFAULT 0,
			descripcion_compensacion TEXT,
			satisfaccion_cliente INTEGER,
			comentarios_finales TEXT,
			reincidente INTEGER DEFAULT 0,
			requiere_legal INTEGER DEFAULT 0,
			numero_expediente_legal TEXT,
			asesor_legal TEXT,
			creado_por INTEGER,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			modificado_por INTEGER,
			fecha_modificacion DATETIME,
			tiempo_respuesta_horas INTEGER,
			tags TEXT
		)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'quejas_reclamaciones'")
		return false
	
	# Tablas adicionales
	var tablas_adicionales = [
		["seguimiento_comunicacion", """
			CREATE TABLE IF NOT EXISTS seguimiento_comunicacion (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				queja_id INTEGER NOT NULL,
				fecha_contacto DATETIME DEFAULT CURRENT_TIMESTAMP,
				medio_contacto TEXT,
				tipo_contacto TEXT,
				contacto_con TEXT,
				resumen TEXT NOT NULL,
				acuerdos TEXT,
				proxima_accion TEXT,
				fecha_proximo_contacto DATE,
				estado_animo TEXT,
				compromiso_cliente INTEGER DEFAULT 0,
				realizado_por INTEGER,
				duracion_minutos INTEGER
			)
		"""],
		["documentos_queja", """
			CREATE TABLE IF NOT EXISTS documentos_queja (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				queja_id INTEGER NOT NULL,
				tipo_documento TEXT,
				nombre_archivo TEXT NOT NULL,
				descripcion TEXT,
				ruta_almacenamiento TEXT,
				hash_archivo TEXT,
				fecha_subida DATETIME DEFAULT CURRENT_TIMESTAMP,
				subido_por INTEGER,
				verificado INTEGER DEFAULT 0
			)
		"""]
	]
	
	for tabla in tablas_adicionales:
		print("Creando tabla '%s'..." % tabla[0])
		if not query(tabla[1]):
			push_error("ERROR: No se pudo crear la tabla '%s'" % tabla[0])
			return false
	
	print("✅ Todas las tablas de quejas creadas correctamente")
	return true

func crear_tablas_calidad() -> bool:
	print("=== CREANDO TABLAS DEL SISTEMA DE CALIDAD ===")
	
	# Nota: La tabla usuarios ya existe, no la volvemos a crear
	
	# Tabla de CLIENTES (simula Oracle DB)
	print("Creando tabla 'clientes'...")
	if not query("""
		CREATE TABLE IF NOT EXISTS clientes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			codigo_cliente TEXT UNIQUE NOT NULL,
			nombre TEXT NOT NULL,
			apellidos TEXT,
			email TEXT,
			telefono TEXT,
			direccion TEXT,
			tipo_cliente TEXT,
			fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'clientes'")
		return false
	
	# Tabla de INCIDENCIAS
	print("Creando tabla 'incidencias_calidad'...")
	if not query("""
		CREATE TABLE IF NOT EXISTS incidencias_calidad (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			codigo_incidencia TEXT UNIQUE NOT NULL,
			cliente_id INTEGER NOT NULL,
			titulo TEXT NOT NULL,
			descripcion TEXT NOT NULL,
			tipo_hallazgo TEXT NOT NULL,
			producto_servicio TEXT NOT NULL,
			sucursal TEXT NOT NULL,
			fecha_ocurrencia DATE NOT NULL,
			fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
			nivel_gravedad TEXT NOT NULL,
			requiere_investigacion BOOLEAN DEFAULT 1,
			estado TEXT DEFAULT 'abierta',
			supervisor_id INTEGER NOT NULL,
			observaciones TEXT
		)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'incidencias_calidad'")
		return false
	
	# Tabla de TRAZAS
	print("Creando tabla 'trazas_calidad'...")
	if not query("""
		CREATE TABLE IF NOT EXISTS trazas_calidad (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			usuario_id INTEGER,
			fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
			accion TEXT NOT NULL,
			modulo TEXT NOT NULL,
			detalles TEXT,
			ip_address TEXT
		)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'trazas_calidad'")
		return false
	
	# Tabla de BACKUPS
	print("Creando tabla 'backups'...")
	if not query("""
		CREATE TABLE IF NOT EXISTS backups (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			nombre_archivo TEXT UNIQUE NOT NULL,
			ruta TEXT NOT NULL,
			tamano_bytes INTEGER,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			usuario_id INTEGER,
			tipo TEXT DEFAULT 'manual',
			estado TEXT DEFAULT 'completado'
		)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'backups'")
		return false
	
	print("✅ Todas las tablas de calidad creadas correctamente")
	
	# Insertar datos de prueba
	_insertar_datos_prueba_calidad()
	
	return true

func crear_tablas_no_conformidades() -> bool:
	"""Crea las tablas específicas para No Conformidades (NC)"""
	print("=== CREANDO TABLAS DE NO CONFORMIDADES ===")
	
	# Tabla principal de NO CONFORMIDADES
	print("Creando tabla 'no_conformidades'...")
	if not query("""
	CREATE TABLE IF NOT EXISTS no_conformidades (
		id_nc INTEGER PRIMARY KEY AUTOINCREMENT,
		codigo_expediente TEXT UNIQUE NOT NULL,
		tipo_nc TEXT NOT NULL, -- 'Incidencia Diaria', 'Auditoría', 'Queja'
		estado TEXT NOT NULL DEFAULT 'pendiente', -- 'pendiente', 'analizado', 'cerrada', 'expediente_cerrado'
		descripcion TEXT NOT NULL,
		fecha_ocurrencia DATE,
		fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
		sucursal TEXT,
		producto_servicio TEXT,
		cliente_id INTEGER,
		responsable_id INTEGER,
		prioridad INTEGER DEFAULT 3, -- 1: Alta, 2: Media, 3: Baja
		expediente_cerrado BOOLEAN DEFAULT 0,
		fecha_cierre DATETIME,
		usuario_cierre INTEGER,
		creado_por INTEGER,
		fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
		modificado_por INTEGER,
		fecha_modificacion DATETIME
	)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'no_conformidades'")
		return false
	
	# Tabla de DOCUMENTOS para NC
	print("Creando tabla 'documentos_nc'...")
	if not query("""
	CREATE TABLE IF NOT EXISTS documentos_nc (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		id_nc INTEGER NOT NULL,
		nombre_archivo TEXT NOT NULL,
		ruta_archivo TEXT NOT NULL,
		tipo_archivo TEXT,
		tamanio_bytes INTEGER,
		fecha_carga DATETIME DEFAULT CURRENT_TIMESTAMP,
		usuario_carga INTEGER,
		descripcion TEXT,
		verificado BOOLEAN DEFAULT 0
	)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'documentos_nc'")
		return false
	
	# Tabla de TRAZAS para NC
	print("Creando tabla 'trazas_nc'...")
	if not query("""
	CREATE TABLE IF NOT EXISTS trazas_nc (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		id_nc INTEGER NOT NULL,
		usuario_id INTEGER NOT NULL,
		fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
		accion TEXT NOT NULL,
		detalles TEXT,
		ip_address TEXT
	)
	"""):
		push_error("ERROR: No se pudo crear la tabla 'trazas_nc'")
		return false
	
	print("✅ Tablas de NC creadas correctamente")
	
	# Insertar datos de prueba
	_insertar_datos_prueba_nc()
	
	return true

# =========================
# DATOS INICIALES Y PRUEBA
# =========================
func _insertar_datos_prueba_calidad():
	# Insertar clientes de prueba
	var clientes_count = count("clientes")
	if clientes_count == 0:
		print("Insertando clientes de prueba...")
		
		var clientes_prueba = [
			{
				"codigo_cliente": "CLI001",
				"nombre": "Juan",
				"apellidos": "Pérez García",
				"email": "juan.perez@email.com",
				"telefono": "+34 600 111 222",
				"tipo_cliente": "Regular"
			},
			{
				"codigo_cliente": "CLI002", 
				"nombre": "María",
				"apellidos": "López Fernández",
				"email": "maria.lopez@email.com",
				"telefono": "+34 600 333 444",
				"tipo_cliente": "VIP"
			}
		]
		
		for cliente in clientes_prueba:
			insert("clientes", cliente)

func _insertar_datos_prueba_nc():
	"""Inserta datos de prueba en las tablas de NC"""
	print("=== INSERTANDO DATOS DE PRUEBA DE NC ===")
	
	# Verificar si ya hay datos
	var count_nc = count("no_conformidades")
	if count_nc == 0:
		print("Insertando NC de prueba...")
		
		# Primero, necesitamos algunos usuarios y clientes existentes
		var usuarios = select_query("SELECT id FROM usuarios LIMIT 2")
		var clientes = select_query("SELECT id FROM clientes LIMIT 2")
		
		if usuarios.size() > 0 and clientes.size() > 0:
			var usuario_id = usuarios[0]["id"]
			var cliente_id = clientes[0]["id"]
			
			var nc_prueba = [
				{
					"codigo_expediente": "EXP-2024-00123",
					"tipo_nc": "Incidencia Diaria",
					"estado": "analizado",
					"descripcion": "Producto con defecto de fabricación reportado por cliente",
					"fecha_ocurrencia": "2024-01-15",
					"sucursal": "Central",
					"producto_servicio": "Paquete Turístico Premium",
					"cliente_id": cliente_id,
					"responsable_id": usuario_id,
					"prioridad": 2,
					"creado_por": usuario_id
				},
				{
					"codigo_expediente": "EXP-2024-00124",
					"tipo_nc": "Auditoría Interna",
					"estado": "pendiente",
					"descripcion": "No conformidad en proceso de check-in",
					"fecha_ocurrencia": "2024-01-16",
					"sucursal": "Sucursal Norte",
					"producto_servicio": "Servicio de Check-in",
					"cliente_id": null,
					"responsable_id": usuario_id,
					"prioridad": 1,
					"creado_por": usuario_id
				}
			]
			
			for nc in nc_prueba:
				var nc_id = insert("no_conformidades", nc)
				if nc_id > 0:
					print("✅ NC de prueba insertada con ID: ", nc_id)
					
					# Insertar documentos de prueba para la primera NC
					if nc_id == 1:  # Solo para la primera NC
						var documentos_prueba = [
							{
								"id_nc": nc_id,
								"nombre_archivo": "informe_tecnico.pdf",
								"ruta_archivo": "/documentos/nc/informe_tecnico.pdf",
								"tipo_archivo": "pdf",
								"tamanio_bytes": 1024000,
								"usuario_carga": usuario_id,
								"descripcion": "Informe técnico del defecto"
							},
							{
								"id_nc": nc_id,
								"nombre_archivo": "fotos_defecto.jpg",
								"ruta_archivo": "/documentos/nc/fotos_defecto.jpg",
								"tipo_archivo": "jpg",
								"tamanio_bytes": 2048000,
								"usuario_carga": usuario_id,
								"descripcion": "Fotografías del producto defectuoso"
							}
						]
						
						for doc in documentos_prueba:
							var doc_id = insert("documentos_nc", doc)
							if doc_id > 0:
								print("✅ Documento de prueba insertado con ID: ", doc_id)
		else:
			print("⚠️ No hay usuarios o clientes para crear NC de prueba")
	else:
		print("✅ Ya existen datos en la tabla 'no_conformidades' (total: ", count_nc, ")")

func inicializar_roles_y_permisos():
	var roles = [
		["ADMIN", "Acceso total"],
		["GESTOR", "Gestión de expedientes"],
		["USUARIO", "Acceso limitado"]
	]

	for r in roles:
		query("INSERT OR IGNORE INTO roles (nombre, descripcion) VALUES (?, ?)", r)

	var permisos = [
		"VER_TODO",
		"GESTIONAR_USUARIOS",
		"CREAR_EXPEDIENTE",
		"PROCESAR_EXPEDIENTE",
		"VER_PROPIOS"
	]

	for p in permisos:
		query("INSERT OR IGNORE INTO permisos (nombre) VALUES (?)", [p])

	# ADMIN = todos los permisos
	var admin_id = _get_id("roles", "nombre", "ADMIN")
	var perm_ids = _get_ids("permisos")

	for pid in perm_ids:
		query(
			"INSERT OR IGNORE INTO rol_permiso (rol_id, permiso_id) VALUES (?, ?)",
			[admin_id, pid]
		)

func inicializar_usuario_admin():
	# Verificar en ambas tablas de usuarios
	var existe_nuevo = _scalar("SELECT COUNT(*) FROM usuarios_nueva WHERE username = 'admin'")
	var existe_antiguo = _scalar("SELECT COUNT(*) FROM usuarios WHERE username = 'admin'")
	
	if existe_antiguo == 0:
		print("⚠️ No existe usuario admin en tabla antigua, creando...")
		# Crear usuario administrador por defecto en tabla antigua
		var admin_data = {
			"username": "admin",
			"password_hash": "admin123",
			"email": "admin@sistema.com",
			"nombre_completo": "Administrador del Sistema",
			"rol": "admin",
			"permisos": "[\"todos_permisos\"]",
			"cargo": "Administrador",
			"departamento": "TI",
			"estado_empleado": "activo"
		}
		
		var user_id = insert("usuarios", admin_data)
		if user_id > 0:
			print("✅ Usuario admin creado en tabla antigua con ID: ", user_id)
		else:
			push_error("❌ No se pudo crear el usuario admin en tabla antigua")
	else:
		print("✅ Usuario admin ya existe en tabla antigua")
	
	if existe_nuevo == 0:
		print("⚠️ No existe usuario admin en tabla nueva, creando...")
		var rol_admin = _get_id("roles", "nombre", "ADMIN")
		query("""
			INSERT INTO usuarios_nueva (username, password_hash, nombre, rol_id)
			VALUES ('admin', 'admin123', 'Administrador', ?)
		""", [rol_admin])
		print("👑 Usuario admin creado en tabla nueva")

# =========================
# FUNCIONES DE CONSULTA (del código antiguo)
# =========================
func query(sql: String, params = []) -> bool:
	"""
	Ejecuta una consulta SQL.
	Retorna true si fue exitosa, false si hubo error.
	"""
	if db == null:
		push_error("Base de datos no inicializada en query()")
		return false
	
	print("🔍 Ejecutando SQL: ", sql.substr(0, 100) + ("..." if sql.length() > 100 else ""))
	if params.size() > 0:
		print("   Parámetros: ", params)
	
	var success = false
	
	if params and params.size() > 0:
		if db.has_method("query_with_bindings"):
			success = db.query_with_bindings(sql, params)
		elif db.has_method("query_with_args"):
			success = db.query_with_args(sql, params)
		else:
			var formatted_sql = sql
			for i in range(params.size()):
				var param = str(params[i]).replace("'", "''")
				var pos = formatted_sql.find("?")
				if pos != -1:
					formatted_sql = formatted_sql.substr(0, pos) + "'" + param + "'" + formatted_sql.substr(pos + 1)
			success = db.query(formatted_sql)
	else:
		success = db.query(sql)
		
	if not success:
		var error_msg = "Error desconocido"
		if "last_error" in db:
			error_msg = db.last_error
		elif "error" in db:
			error_msg = db.error
		elif "error_message" in db:
			error_msg = db.error_message
		elif db.has_method("get_error_message"):
			error_msg = db.get_error_message()
		
		push_error("❌ Error SQL: " + str(error_msg))
		push_error("   Consulta: " + sql)
			
	return success

func select_query(sql: String, params = []) -> Array:
	"""
	Ejecuta una consulta SELECT y retorna los resultados como array.
	Si hay error, retorna array vacío.
	"""
	if db == null:
		push_error("Base de datos no inicializada")
		return []
	
	var success = query(sql, params)
	if not success:
		print("❌ Error en consulta SELECT: " + sql)
		return []
	
	var results = []
	
	# Método 1: Si el addon tiene fetch_array()
	if db.has_method("fetch_array"):
		var row = db.fetch_array()
		while row != null and row.size() > 0:
			var dict = {}
			var column_names = _obtener_nombres_columnas()
			for i in range(min(row.size(), column_names.size())):
				dict[column_names[i]] = row[i]
			results.append(dict)
			row = db.fetch_array()
	
	# Método 2: Si el addon tiene rows property
	elif "rows" in db and typeof(db.rows) == TYPE_ARRAY:
		results = db.rows
	
	# Método 3: Si el addon tiene query_result property
	elif "query_result" in db and typeof(db.query_result) == TYPE_ARRAY:
		results = db.query_result
	
	else:
		results = _metodo_alternativo_obtener_resultados()
	
	return results

func _obtener_nombres_columnas() -> Array:
	if db.has_method("get_columns"):
		return db.get_columns()
	elif db.has_method("column_names"):
		return db.column_names
	else:
		return []

func _metodo_alternativo_obtener_resultados() -> Array:
	var results = []
	
	if db.has_method("fetch_array"):
		var row = db.fetch_array()
		while row != null and row.size() > 0:
			var dict = {}
			var column_names = []
			if db.has_method("get_column_names"):
				column_names = db.get_column_names()
			elif db.has_method("column_names"):
				column_names = db.column_names
			
			for i in range(min(row.size(), column_names.size())):
				dict[column_names[i]] = row[i]
			results.append(dict)
			row = db.fetch_array()
	
	elif db.has_method("fetch_row"):
		var row = db.fetch_row()
		while row != null:
			results.append(row)
			row = db.fetch_row()
	
	elif "rows" in db and db.rows != null:
		results = db.rows
	
	elif "query_result" in db and db.query_result != null:
		results = db.query_result
	
	else:
		print("⚠️ No se pudo obtener resultados de la consulta")
	
	return results

func select_one(sql: String, params = []) -> Dictionary:
	"""
	Ejecuta una consulta SELECT y retorna la primera fila como diccionario.
	"""
	var results = select_query(sql, params)
	if results and results.size() > 0:
		return results[0]
	return {}

func insert(table: String, data: Dictionary) -> int:
	"""
	Inserta un registro en la tabla y retorna el ID insertado.
	"""
	if data.is_empty():
		push_error("No hay datos para insertar en la tabla " + table)
		return -1
	
	var keys = []
	var values = []
	var placeholders = []
	
	for key in data.keys():
		keys.append(key)
		values.append(str(data[key]))
		placeholders.append("?")
	
	var sql = "INSERT INTO %s (%s) VALUES (%s)" % [
		table,
		", ".join(PackedStringArray(keys)),
		", ".join(PackedStringArray(placeholders))
	]
	
	print("📝 Ejecutando INSERT: ", sql)
	print("📝 Valores: ", values)
	
	if query(sql, values):
		if db.has_method("last_insert_rowid"):
			var id = db.last_insert_rowid
			print("✅ Insertado en " + table + " con ID: " + str(id))
			return id
		else:
			var result = select_query("SELECT last_insert_rowid() as id")
			if result and result.size() > 0:
				return result[0]["id"]
	
	print("❌ Error al insertar en " + table)
	return -1

func update(table: String, data: Dictionary, where: String, where_params = []) -> bool:
	var sets = []
	var values = []
	
	for key in data.keys():
		sets.append("%s = ?" % key)
		values.append(str(data[key]))
	
	if where_params is Array:
		for param in where_params:
			values.append(str(param))
	
	var sql = "UPDATE %s SET %s WHERE %s" % [table, ", ".join(PackedStringArray(sets)), where]
	
	print("📝 Ejecutando UPDATE: ", sql)
	print("📝 Valores: ", values)
	
	return query(sql, values)

func delete(table: String, where: String, params = []) -> bool:
	var sql = "DELETE FROM %s WHERE %s" % [table, where]
	print("📝 Ejecutando DELETE: ", sql)
	return query(sql, params)

# =========================
# FUNCIONES UTILITARIAS
# =========================
func obtener_queja_por_id(id_queja: int) -> Dictionary:
	"""
	Obtiene una queja por su ID.
	"""
	print("DEBUG: Ejecutando query para id: ", id_queja)
	
	var result = select_query("SELECT * FROM quejas_reclamaciones WHERE id = ?", [id_queja])
	
	print("DEBUG - Tipo de result: ", typeof(result))
	print("DEBUG - Valor de result: ", result)
	
	if result and typeof(result) == TYPE_ARRAY and result.size() > 0:
		print("DEBUG - Primer elemento tipo: ", typeof(result[0]))
		return result[0]
	
	if typeof(result) == TYPE_BOOL:
		print("DEBUG - Result es booleano, no array. Valor: ", result)
	
	print("DEBUG - Retornando diccionario vacío")
	return {}

func table_exists(table_name: String) -> bool:
	var sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
	var result = select_query(sql, [table_name])
	return result and result.size() > 0

func get_database_info() -> Dictionary:
	var info = {
		"path": database_path,
		"tables": []
	}
	
	var tables = select_query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
	for table in tables:
		info["tables"].append(table["name"])
	
	return info

func get_table_structure(table_name: String) -> Array:
	return select_query("PRAGMA table_info(%s)" % table_name)

func count(table: String, where: String = "", params = []) -> int:
	var sql = "SELECT COUNT(*) as count FROM %s" % table
	if where:
		sql += " WHERE " + where
	
	var result = select_query(sql, params)
	if result and result.size() > 0:
		return int(result[0]["count"])
	return 0

func _scalar(sql: String) -> int:
	var result = select_query(sql)
	if result and result.size() > 0:
		return int(result[0].values()[0])
	return 0

func _get_id(tabla: String, campo: String, valor) -> int:
	var result = select_query("SELECT id FROM %s WHERE %s = ?" % [tabla, campo], [valor])
	if result and result.size() > 0:
		return int(result[0]["id"])
	return 0

func _get_ids(tabla: String) -> Array:
	var result = select_query("SELECT id FROM %s" % tabla)
	var ids := []
	for r in result:
		ids.append(r["id"])
	return ids

# =========================
# AUDITORÍA Y DIAGNÓSTICO
# =========================
func registrar_auditoria(user_id: int, accion: String, escena := "", detalles := ""):
	query("""
		INSERT INTO auditoria (user_id, accion, escena, detalles)
		VALUES (?, ?, ?, ?)
	""", [user_id, accion, escena, detalles])

func verificar_estructura():
	print("\n=== DIAGNÓSTICO DE BASE DE DATOS ===")
	
	if db == null:
		print("❌ Base de datos no inicializada")
		return
	
	print("📊 Ruta de base de datos: " + database_path)
	
	var tablas = select_query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
	if tablas != null and tablas.size() > 0:
		print("📋 Tablas encontradas (" + str(tablas.size()) + "):")
		for tabla in tablas:
			print("   - " + tabla["name"])
	else:
		print("⚠️ No se encontraron tablas en la base de datos")
	
	var usuarios = select_query("SELECT COUNT(*) as total FROM usuarios")
	if usuarios != null and usuarios.size() > 0:
		print("👥 Usuarios en sistema (tabla antigua): " + str(usuarios[0]["total"]))
	
	var usuarios_nueva = select_query("SELECT COUNT(*) as total FROM usuarios_nueva")
	if usuarios_nueva != null and usuarios_nueva.size() > 0:
		print("👥 Usuarios en sistema (tabla nueva): " + str(usuarios_nueva[0]["total"]))
	
	print("=== FIN DIAGNÓSTICO ===\n")

func test_conexion():
	print("\n🧪 TEST DE CONEXIÓN A BD")
	
	var test_sql = "SELECT 1 as test_value"
	var result = select_query(test_sql)
	
	if result != null and result.size() > 0:
		print("✅ Test de conexión exitoso")
		print("   Resultado: " + str(result[0]))
	else:
		print("❌ Test de conexión falló")
	
	var tablas = select_query("SELECT name FROM sqlite_master WHERE type='table'")
	if tablas != null:
		print("📋 Tablas en BD: " + str(tablas.size()))

func inspeccionar_bd():
	print("=== INSPECCIÓN DE BD ===")
	
	print("Tipo de self: ", typeof(self))
	
	print("\nPropiedades de self (BD):")
	for propiedad in get_property_list():
		if propiedad.name not in ["script", "Script Variables", "Node"]:
			print("  - ", propiedad.name, " (", typeof(get(propiedad.name)), ")")
	
	print("\n=== PRUEBAS DE OPERACIONES ===")
	
	print("\nProbando select_query...")
	var resultado_select = select_query("SELECT 1 as test")
	print("  Resultado: ", resultado_select)
	print("  Tipo: ", typeof(resultado_select))
	
	print("\nVerificando tabla 'quejas_reclamaciones'...")
	var existe = table_exists("quejas_reclamaciones")
	print("  Existe: ", existe)
	
	if resultado_select != null and typeof(resultado_select) == TYPE_ARRAY:
		print("\nEstructura de array resultante:")
		print("  Tamaño: ", resultado_select.size())
		if resultado_select.size() > 0:
			print("  Primer elemento tipo: ", typeof(resultado_select[0]))
			if typeof(resultado_select[0]) == TYPE_DICTIONARY:
				print("  Keys del primer elemento: ", resultado_select[0].keys())
	
	print("\n=== FIN DE INSPECCIÓN ===")

func debug_query(sql: String, params = []):
	print("\n🔍 DEBUG QUERY:")
	print("SQL: " + sql)
	if params.size() > 0:
		print("Params: " + str(params))
	
	var start_time = Time.get_ticks_msec()
	var success = query(sql, params)
	var end_time = Time.get_ticks_msec()
	
	print("Resultado: " + ("✅ Éxito" if success else "❌ Error"))
	print("Tiempo: " + str(end_time - start_time) + "ms")
	
	if success:
		var results = select_query(sql, params)
		print("Filas retornadas: " + str(results.size()))
		if results.size() > 0:
			print("Primera fila: " + str(results[0]))
	
	print("---\n")
	return success

func close():
	if db:
		db.close_db()
		print("🔒 Base de datos cerrada")

# =========================
# MÉTODOS DE PRUEBA
# =========================
func probar_consultas():
	print("\n=== PRUEBA DE CONSULTAS DIFERENTES ===")
	
	var consultas = [
		"SELECT * FROM quejas_reclamaciones LIMIT 1",
		"SELECT COUNT(*) as total FROM quejas_reclamaciones",
		"SELECT name FROM sqlite_master WHERE type='table'",
		"PRAGMA table_info(quejas_reclamaciones)"
	]
	
	for consulta in consultas:
		_try_query(consulta)
		
func _try_query(sql: String):
	print("\nConsulta: ", sql)
	var result = select_query(sql)
	print("  Resultado tipo: ", typeof(result))
	
	if typeof(result) == TYPE_ARRAY:
		print("  Tamaño array: ", result.size())
		if result.size() > 0:
			if typeof(result[0]) == TYPE_DICTIONARY:
				print("  Keys: ", result[0].keys())
				if result[0].size() < 10:
					print("  Valores: ", result[0])
			else:
				print("  Primer valor: ", result[0])
	elif result != null:
		print("  Valor: ", result)
	else:
		print("  Nulo")

func verificar_funciones_bd():
	print("\n=== VERIFICACIÓN DE FUNCIONES ESPECÍFICAS ===")
	
	var funciones_a_verificar = [
		"insert",
		"update",
		"delete",
		"query",
		"select_query",
		"table_exists",
		"get_database_info",
		"get_table_structure",
		"count"
	]
	
	for funcion in funciones_a_verificar:
		if has_method(funcion):
			print("✓ ", funcion, " - DISPONIBLE")
		else:
			print("✗ ", funcion, " - NO DISPONIBLE")
