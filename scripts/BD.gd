extends Node
class_name BD

var db = SQLite.new()
var database_path = "res://data/quejas.db"

func _ready():
	# Crear directorio de datos si no existe
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://data"):
		dir.make_dir("res://data")
	
	# Abrir conexión a la base de datos
	db.path = database_path
	db.open_db()
	
	# Crear tablas
	crear_tablas_quejas()
	
	# Inicializar usuario admin si no existe
	inicializar_usuario_admin()

func crear_tablas_quejas():
	# Tabla de USUARIOS para autenticación (PRIMERO)
	db.query("""
		CREATE TABLE IF NOT EXISTS usuarios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			
			-- Información básica
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			email TEXT UNIQUE NOT NULL,
			nombre_completo TEXT NOT NULL,
			
			-- Perfil del usuario
			avatar TEXT DEFAULT 'default.png',
			telefono TEXT,
			departamento TEXT,
			cargo TEXT,
			fecha_contratacion DATE,
			estado_empleado TEXT CHECK(estado_empleado IN ('activo', 'inactivo', 'suspendido', 'vacaciones')) DEFAULT 'activo',
			
			-- Roles y permisos
			rol TEXT CHECK(rol IN ('admin', 'supervisor', 'operador', 'analista', 'legal', 'gerente')) DEFAULT 'operador',
			permisos TEXT DEFAULT '["ver_dashboard", "crear_queja", "editar_perfil"]',
			
			-- Configuración de sistema
			tema_preferido TEXT DEFAULT 'claro',
			idioma TEXT DEFAULT 'es',
			zona_horaria TEXT DEFAULT 'America/Lima',
			notificaciones_email BOOLEAN DEFAULT TRUE,
			notificaciones_push BOOLEAN DEFAULT TRUE,
			
			-- Seguridad
			ultimo_login DATETIME,
			intentos_fallidos INTEGER DEFAULT 0,
			bloqueado_hasta DATETIME,
			requiere_cambio_password BOOLEAN DEFAULT FALSE,
			token_recuperacion TEXT,
			token_expiracion DATETIME,
			
			-- Auditoría
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			creado_por INTEGER,
			fecha_modificacion DATETIME,
			modificado_por INTEGER,
			
			-- Metadatos
			sesiones_activas INTEGER DEFAULT 0,
			preferencias TEXT DEFAULT '{}'
		)
	""")
	
	# Tabla de HISTORIAL de actividad de usuarios
	db.query("""
		CREATE TABLE IF NOT EXISTS historial_usuarios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			usuario_id INTEGER NOT NULL,
			fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
			tipo_evento TEXT CHECK(tipo_evento IN (
				'login', 'logout', 'cambio_password', 'actualizacion_perfil',
				'creacion_queja', 'modificacion_queja', 'cierre_caso',
				'acceso_denegado', 'error_sistema'
			)),
			descripcion TEXT NOT NULL,
			ip_address TEXT,
			user_agent TEXT,
			detalles TEXT,
			
			FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
		)
	""")
	
	# Tabla principal de QUEJAS y RECLAMACIONES
	db.query("""
		CREATE TABLE IF NOT EXISTS quejas_reclamaciones (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			
			-- Identificación única
			numero_caso TEXT UNIQUE,
			tipo_caso TEXT CHECK(tipo_caso IN ('queja', 'reclamacion', 'sugerencia', 'felicitacion')),
			canal_entrada TEXT CHECK(canal_entrada IN ('presencial', 'telefonico', 'email', 'web', 'redes_sociales', 'app', 'carta')),
			
			-- Datos del reclamante
			tipo_reclamante TEXT CHECK(tipo_reclamante IN ('cliente', 'proveedor', 'empleado', 'ciudadano', 'otro')),
			identificacion TEXT,
			nombres TEXT NOT NULL,
			apellidos TEXT,
			telefono TEXT,
			email TEXT,
			direccion TEXT,
			
			-- Datos de la queja
			asunto TEXT NOT NULL,
			descripcion_detallada TEXT NOT NULL,
			producto_servicio TEXT,
			numero_contrato TEXT,
			numero_factura TEXT,
			fecha_incidente DATE,
			lugar_incidente TEXT,
			
			-- Categorización
			categoria TEXT CHECK(categoria IN ('calidad_producto', 'atencion_cliente', 'plazos_entrega', 'facturacion', 'garantia', 'daños', 'perdidas', 'publicidad_enganosa', 'privacidad')),
			subcategoria TEXT,
			
			-- Valoración económica
			monto_reclamado REAL DEFAULT 0,
			moneda TEXT DEFAULT 'USD',
			tipo_compensacion TEXT CHECK(tipo_compensacion IN ('dinero', 'reemplazo', 'reparacion', 'descuento', 'servicio_gratis', 'disculpas', 'ninguna')),
			
			-- Estado y prioridad
			prioridad TEXT CHECK(prioridad IN ('baja', 'media', 'alta', 'urgente')),
			estado TEXT CHECK(estado IN ('recibida', 'en_revision', 'investigando', 'negociacion', 'resuelta', 'rechazada', 'escalada', 'judicial', 'archivada')),
			nivel_escalamiento INTEGER DEFAULT 1,
			
			-- Responsables
			recibido_por INTEGER,
			asignado_a INTEGER,
			equipo_responsable TEXT,
			
			-- Fechas del proceso
			fecha_recepcion DATETIME DEFAULT CURRENT_TIMESTAMP,
			fecha_limite_respuesta DATE,
			fecha_respuesta_cliente DATE,
			fecha_cierre DATETIME,
			
			-- Proceso de investigación
			hechos_constatados TEXT,
			pruebas_adjuntas TEXT,
			testigos TEXT,
			responsable_interno TEXT,
			
			-- Resolución
			decision TEXT CHECK(decision IN ('aceptada_parcial', 'aceptada_total', 'rechazada', 'mediacion')),
			solucion_propuesta TEXT,
			compensacion_otorgada REAL DEFAULT 0,
			descripcion_compensacion TEXT,
			
			-- Seguimiento post-resolución
			satisfaccion_cliente INTEGER,
			comentarios_finales TEXT,
			reincidente BOOLEAN DEFAULT FALSE,
			
			-- Datos legales
			requiere_legal BOOLEAN DEFAULT FALSE,
			numero_expediente_legal TEXT,
			asesor_legal TEXT,
			
			-- Auditoría
			creado_por INTEGER,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			modificado_por INTEGER,
			fecha_modificacion DATETIME,
			
			-- Metadatos
			tiempo_respuesta_horas INTEGER,
			tags TEXT,
			
			-- Foreign keys
			FOREIGN KEY (recibido_por) REFERENCES usuarios(id),
			FOREIGN KEY (asignado_a) REFERENCES usuarios(id),
			FOREIGN KEY (creado_por) REFERENCES usuarios(id)
		)
	""")
	
	# Tabla de SEGUIMIENTO de comunicación con cliente
	db.query("""
		CREATE TABLE IF NOT EXISTS seguimiento_comunicacion (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			queja_id INTEGER NOT NULL,
			fecha_contacto DATETIME DEFAULT CURRENT_TIMESTAMP,
			medio_contacto TEXT CHECK(medio_contacto IN ('llamada', 'email', 'carta', 'presencial', 'videollamada')),
			tipo_contacto TEXT CHECK(tipo_contacto IN ('inicial', 'seguimiento', 'propuesta', 'confirmacion', 'recordatorio')),
			
			-- Detalles del contacto
			contacto_con TEXT,
			resumen TEXT NOT NULL,
			acuerdos TEXT,
			proxima_accion TEXT,
			fecha_proximo_contacto DATE,
			
			-- Estado anímico del cliente
			estado_animo TEXT CHECK(estado_animo IN ('enojado', 'frustrado', 'tranquilo', 'cooperativo', 'indiferente')),
			compromiso_cliente BOOLEAN DEFAULT FALSE,
			
			-- Responsable
			realizado_por INTEGER,
			duracion_minutos INTEGER,
			
			FOREIGN KEY (queja_id) REFERENCES quejas_reclamaciones(id) ON DELETE CASCADE,
			FOREIGN KEY (realizado_por) REFERENCES usuarios(id)
		)
	""")
	
	# Tabla de DOCUMENTOS de la queja
	db.query("""
		CREATE TABLE IF NOT EXISTS documentos_queja (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			queja_id INTEGER NOT NULL,
			tipo_documento TEXT CHECK(tipo_documento IN (
				'identificacion', 'factura', 'contrato', 'foto', 'video',
				'audio', 'carta', 'informe_tecnico', 'dictamen_legal',
				'acuerdo_firmado', 'comprobante_pago'
			)),
			nombre_archivo TEXT NOT NULL,
			descripcion TEXT,
			ruta_almacenamiento TEXT,
			hash_archivo TEXT,
			fecha_subida DATETIME DEFAULT CURRENT_TIMESTAMP,
			subido_por INTEGER,
			verificado BOOLEAN DEFAULT FALSE,
			
			FOREIGN KEY (queja_id) REFERENCES quejas_reclamaciones(id) ON DELETE CASCADE,
			FOREIGN KEY (subido_por) REFERENCES usuarios(id)
		)
	""")
	
	# Tabla de COMPENSACIONES
	db.query("""
		CREATE TABLE IF NOT EXISTS compensaciones (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			queja_id INTEGER NOT NULL,
			tipo_compensacion TEXT CHECK(tipo_compensacion IN (
				'devolucion_dinero', 'voucher_descuento', 'producto_reemplazo',
				'servicio_gratis', 'puntos_fidelidad', 'disculpas_publicas',
				'donacion', 'otro'
			)),
			descripcion TEXT NOT NULL,
			monto REAL,
			moneda TEXT DEFAULT 'USD',
			estado TEXT CHECK(estado IN ('pendiente', 'aprobada', 'rechazada', 'entregada')),
			
			-- Proceso de aprobación
			aprobado_por INTEGER,
			fecha_aprobacion DATE,
			nivel_aprobacion INTEGER,
			
			-- Entrega
			metodo_entrega TEXT,
			fecha_entrega DATE,
			recibido_por TEXT,
			comprobante_entrega TEXT,
			
			FOREIGN KEY (queja_id) REFERENCES quejas_reclamaciones(id) ON DELETE CASCADE,
			FOREIGN KEY (aprobado_por) REFERENCES usuarios(id)
		)
	""")
	
	# Tabla de ANÁLISIS de tendencias
	db.query("""
		CREATE TABLE IF NOT EXISTS analisis_tendencias (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			periodo TEXT,
			categoria TEXT,
			total_quejas INTEGER DEFAULT 0,
			quejas_resueltas INTEGER DEFAULT 0,
			tiempo_promedio_respuesta REAL,
			costo_total_compensaciones REAL DEFAULT 0,
			indice_satisfaccion REAL,
			principales_problemas TEXT
		)
	""")

func inicializar_usuario_admin():
	# Verificar si ya existe un usuario admin
	var sql = "SELECT COUNT(*) as count FROM usuarios WHERE username = 'admin'"
	var result = select_one(sql)
	
	if result:
		# Obtener resultados - depende del addon SQLite que estés usando
		var results = obtener_resultados_query()
		
		if results and results.size() > 0:
			var row = results[0]
			if "count" in row and row["count"] == 0:
				# Crear usuario administrador por defecto
				var admin_data = {
					"username": "admin",
					"password_hash": "admin123",  # En producción usar hash!
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
					print("Usuario admin creado por defecto")
	else:
		print("Error al verificar usuario admin")

# Función genérica para obtener resultados de consulta
func obtener_resultados_query():
	# Intenta diferentes métodos según el addon SQLite que estés usando
	# Método 1: Si el addon tiene una propiedad query_result
	if db.has_method("get_query_result"):
		return db.get_query_result()
	
	# Método 2: Si el addon tiene una propiedad rows
	if "rows" in db:
		return db.rows
	
	# Método 3: Si el addon tiene fetch_rows
	if db.has_method("fetch_rows"):
		return db.fetch_rows()
	
	# Método 4: Si el addon tiene fetch_array (algunos lo tienen)
	if db.has_method("fetch_array"):
		return db.fetch_array()
	
	print("Error: No se pudo obtener resultados de la consulta")
	return []

func query(sql: String, params = []):
	# Si hay parámetros, usa query_with_bindings
	if params and params.size() > 0:
		return db.query_with_bindings(sql, params)
	else:
		return db.query(sql)

# Función para consultas SELECT que devuelven resultados
func select_query(sql: String, params = []):
	var success = query(sql, params)
	if success:
		return obtener_resultados_query()
	return []

func select_one(sql: String, params = []):
	var results = select_query(sql, params)
	if results and results.size() > 0:
		return results[0]
	return null

func insert(table: String, data: Dictionary) -> int:
	var keys = []
	var values = []
	var placeholders = []
	
	for key in data.keys():
		keys.append(key)
		values.append(data[key])
		placeholders.append("?")
	
	var sql = "INSERT INTO %s (%s) VALUES (%s)" % [
		table, 
		", ".join(keys), 
		", ".join(placeholders)
	]
	
	var success = query(sql, values)
	if success:
		return db.last_insert_rowid
	return -1

func update(table: String, data: Dictionary, where: String, where_params = []) -> bool:
	var sets = []
	var values = []
	
	for key in data.keys():
		sets.append("%s = ?" % key)
		values.append(data[key])
	
	# Agregar parámetros WHERE
	values.append_array(where_params)
	
	var sql = "UPDATE %s SET %s WHERE %s" % [table, ", ".join(sets), where]
	
	return query(sql, values)

func delete(table: String, where: String, params = []) -> bool:
	var sql = "DELETE FROM %s WHERE %s" % [table, where]
	return query(sql, params)

func close():
	db.close_db()

# Función para obtener el número de filas afectadas
func get_affected_rows() -> int:
	if db.has_method("get_affected_rows"):
		return db.get_affected_rows()
	return 0

# Función para comenzar una transacción
func begin_transaction():
	if db.has_method("begin_transaction"):
		db.begin_transaction()
	else:
		query("BEGIN TRANSACTION")

# Función para confirmar una transacción
func commit():
	if db.has_method("commit"):
		db.commit()
	else:
		query("COMMIT")

# Función para revertir una transacción
func rollback():
	if db.has_method("rollback"):
		db.rollback()
	else:
		query("ROLLBACK")
