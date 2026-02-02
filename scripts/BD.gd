extends Node
class_name BD

var db = SQLite.new()
var database_path = "res://data/quejas.db"
func _ready():
	print("🔧 Inicializando base de datos...")
	
	# Verificar si SQLite está disponible
	if not ClassDB.class_exists("SQLite"):
		push_error("❌ Clase SQLite no encontrada. Asegúrate de tener el addon SQLite instalado.")
		return
	
	# Crear directorio de datos si no existe
	var dir = DirAccess.open("res://")
	if dir == null:
		push_error("No se pudo abrir el directorio res://")
		return
	
	if not dir.dir_exists("res://data"):
		print("📁 Creando directorio 'data'...")
		var error = dir.make_dir("res://data")
		if error != OK:
			push_error("No se pudo crear el directorio data: " + str(error))
			return
	
	# Abrir conexión a la base de datos
	db = SQLite.new()
	db.path = database_path
	
	print("🔓 Abriendo base de datos en: " + database_path)
	if db.open_db() != true:
		push_error("❌ No se pudo abrir la base de datos: " + database_path)
		
		# Intentar crear una base de datos vacía
		print("🆕 Intentando crear nueva base de datos...")
		# Simplemente intentar abrir de nuevo
		if db.open_db() != true:
			push_error("❌ Fatal: No se pudo crear/abrir la base de datos")
			return
		else:
			print("✅ Nueva base de datos creada")
	
	print("✅ Base de datos abierta correctamente")
	
	# Crear tablas
	if not crear_tablas_quejas():
		push_error("❌ Error crítico al crear tablas")
		return
	
	# Inicializar usuario admin si no existe
	inicializar_usuario_admin()
	
	# Verificar estructura
	verificar_estructura()
	
	print("🚀 Base de datos inicializada correctamente")
	
	# Prueba simple de conexión
	test_conexion()
	call_deferred("inspeccionar_bd")
	
func crear_tablas_quejas():
	print("=== CREANDO TABLAS DE LA BASE DE DATOS ===")
	
	# Tabla de USUARIOS para autenticación (PRIMERO)
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
	var sql_historial = """
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
	"""
	
	if not query(sql_historial):
		push_error("ERROR: No se pudo crear la tabla 'historial_usuarios'")
		return false
	
	# Tabla principal de QUEJAS y RECLAMACIONES
	print("Creando tabla 'quejas_reclamaciones'...")
	var sql_quejas = """
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
	"""
	
	if not query(sql_quejas):
		push_error("ERROR: No se pudo crear la tabla 'quejas_reclamaciones'")
		return false
	
	# Tablas adicionales (simplificadas para evitar errores)
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
	
	print("✅ Todas las tablas creadas correctamente")
	return true
	
	
func crear_tablas_calidad():
	print("=== CREANDO TABLAS DEL SISTEMA DE CALIDAD ===")
	
	# Tabla de USUARIOS
	print("Creando tabla 'usuarios'...")
	var sql_usuarios = """
		CREATE TABLE IF NOT EXISTS usuarios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			nombre_completo TEXT NOT NULL,
			email TEXT UNIQUE NOT NULL,
			telefono TEXT,
			rol TEXT NOT NULL,
			sucursal TEXT,
			estado TEXT DEFAULT 'activo',
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			ultimo_login DATETIME,
			permisos TEXT DEFAULT '[]'
		)
	"""
	
	if not query(sql_usuarios):
		push_error("ERROR: No se pudo crear la tabla 'usuarios'")
		return false
	
	# Tabla de CLIENTES (simula Oracle DB)
	print("Creando tabla 'clientes'...")
	var sql_clientes = """
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
	"""
	
	if not query(sql_clientes):
		push_error("ERROR: No se pudo crear la tabla 'clientes'")
		return false
	
	# Tabla de INCIDENCIAS
	print("Creando tabla 'incidencias'...")
	var sql_incidencias = """
		CREATE TABLE IF NOT EXISTS incidencias (
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
			observaciones TEXT,
			FOREIGN KEY (cliente_id) REFERENCES clientes(id),
			FOREIGN KEY (supervisor_id) REFERENCES usuarios(id)
		)
	"""
	
	if not query(sql_incidencias):
		push_error("ERROR: No se pudo crear la tabla 'incidencias'")
		return false
	
	# Tabla de TRAZAS
	print("Creando tabla 'trazas'...")
	var sql_trazas = """
		CREATE TABLE IF NOT EXISTS trazas (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			usuario_id INTEGER,
			fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
			accion TEXT NOT NULL,
			modulo TEXT NOT NULL,
			detalles TEXT,
			ip_address TEXT,
			FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
		)
	"""
	
	if not query(sql_trazas):
		push_error("ERROR: No se pudo crear la tabla 'trazas'")
		return false
	
	# Tabla de BACKUPS
	print("Creando tabla 'backups'...")
	var sql_backups = """
		CREATE TABLE IF NOT EXISTS backups (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			nombre_archivo TEXT UNIQUE NOT NULL,
			ruta TEXT NOT NULL,
			tamano_bytes INTEGER,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			usuario_id INTEGER,
			tipo TEXT DEFAULT 'manual',
			estado TEXT DEFAULT 'completado',
			FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
		)
	"""
	
	if not query(sql_backups):
		push_error("ERROR: No se pudo crear la tabla 'backups'")
		return false
	
	print("✅ Todas las tablas creadas correctamente")
	
	# Insertar datos de prueba si las tablas están vacías
	insertar_datos_prueba()
	
	return true

func insertar_datos_prueba():
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
			
func inicializar_usuario_admin():
	print("=== VERIFICANDO USUARIO ADMIN ===")
	
	# Verificar si ya existe un usuario admin
	var result = select_query("SELECT COUNT(*) as count FROM usuarios WHERE username = 'admin'")
	
	if result != null and result.size() > 0:
		var row = result[0]
		if row.has("count") and int(row["count"]) == 0:
			print("⚠️ No existe usuario admin, creando...")
			# Crear usuario administrador por defecto
			var admin_data = {
				"username": "admin",
				"password_hash": "admin123",  # EN PRODUCCIÓN DEBES ENCRIPTAR ESTA CONTRASEÑA
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
				print("✅ Usuario admin creado por defecto con ID: ", user_id)
			else:
				push_error("❌ No se pudo crear el usuario admin")
		else:
			print("✅ Usuario admin ya existe")
	else:
		print("⚠️ No se pudo verificar la existencia del usuario admin")
		
func obtener_queja_por_id(id_queja: int) -> Dictionary:
	"""
	Obtiene una queja por su ID.
	"""
	print("DEBUG: Ejecutando query para id: ", id_queja)
	
	# ERROR: Bd.query retorna boolean, no array
	# var result = Bd.query("SELECT * FROM quejas_reclamaciones WHERE id = ?", [id_queja])
	
	# CORRECCIÓN: Usar select_query que retorna array
	var result = select_query("SELECT * FROM quejas_reclamaciones WHERE id = ?", [id_queja])
	
	print("DEBUG - Tipo de result: ", typeof(result))
	print("DEBUG - Valor de result: ", result)
	
	if result and typeof(result) == TYPE_ARRAY and result.size() > 0:
		print("DEBUG - Primer elemento tipo: ", typeof(result[0]))
		return result[0]
	
	# Si result es booleano (por usar query en lugar de select_query)
	if typeof(result) == TYPE_BOOL:
		print("DEBUG - Result es booleano, no array. Valor: ", result)
	
	print("DEBUG - Retornando diccionario vacío")
	return {}

func verificar_estructura():
	print("\n=== DIAGNÓSTICO DE BASE DE DATOS ===")
	
	# Verificar si la base de datos está abierta
	if db == null:
		print("❌ Base de datos no inicializada")
		return
	
	print("📊 Ruta de base de datos: " + database_path)
	
	# Verificar tablas existentes
	var tablas = select_query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
	if tablas != null and tablas.size() > 0:
		print("📋 Tablas encontradas (" + str(tablas.size()) + "):")
		for tabla in tablas:
			print("   - " + tabla["name"])
	else:
		print("⚠️ No se encontraron tablas en la base de datos")
	
	# Verificar usuarios
	var usuarios = select_query("SELECT COUNT(*) as total FROM usuarios")
	if usuarios != null and usuarios.size() > 0:
		print("👥 Usuarios en sistema: " + str(usuarios[0]["total"]))
	
	print("=== FIN DIAGNÓSTICO ===\n")
	
	

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
	
	# Usar la sintaxis correcta de replace (sin el tercer argumento)
	if params and params.size() > 0:
		# Diferentes addons usan diferentes métodos
		if db.has_method("query_with_bindings"):
			success = db.query_with_bindings(sql, params)
		elif db.has_method("query_with_args"):
			success = db.query_with_args(sql, params)
		else:
			# Si no tiene métodos con parámetros, construir la query manualmente
			var formatted_sql = sql
			for i in range(params.size()):
				var param = str(params[i]).replace("'", "''")
				# Reemplazar solo el primer "?" encontrado
				var pos = formatted_sql.find("?")
				if pos != -1:
					formatted_sql = formatted_sql.substr(0, pos) + "'" + param + "'" + formatted_sql.substr(pos + 1)
			success = db.query(formatted_sql)
	else:
		success = db.query(sql)
		
	if not success:
		# Intentar diferentes métodos para obtener el mensaje de error
		var error_msg = "Error desconocido"
		
		# Verificar propiedades, no llamar como funciones
		if "last_error" in db:
			error_msg = db.last_error
		elif "error" in db:
			error_msg = db.error
		elif "error_message" in db:  # Esta es una propiedad, no una función
			error_msg = db.error_message
		elif db.has_method("get_error_message"):  # Este sí podría ser un método
			error_msg = db.get_error_message()
		
		push_error("❌ Error SQL: " + str(error_msg))
		push_error("   Consulta: " + sql)
			
	return success
	
func obtener_nombres_columnas() -> Array:
	"""
	Intenta obtener los nombres de las columnas.
	"""
	if db.has_method("get_columns"):
		return db.get_columns()
	elif db.has_method("column_names"):
		return db.column_names
	else:
		return []


func metodo_alternativo_obtener_resultados() -> Array:
	"""
	Método alternativo para obtener resultados.
	"""
	var results = []
	
	# Método 1: Si el addon tiene fetch_array()
	if db.has_method("fetch_array"):
		var row = db.fetch_array()
		while row != null and row.size() > 0:
			# Convertir array a diccionario
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
	
	# Método 2: Si el addon tiene fetch_row()
	elif db.has_method("fetch_row"):
		var row = db.fetch_row()
		while row != null:
			results.append(row)
			row = db.fetch_row()
	
	# Método 3: Si el addon tiene rows property
	elif "rows" in db and db.rows != null:
		results = db.rows
	
	# Método 4: Si el addon tiene query_result property
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
		values.append(str(data[key]))  # Convertir todos a string
		placeholders.append("?")
	
	var sql = "INSERT INTO %s (%s) VALUES (%s)" % [
		table,
		", ".join(PackedStringArray(keys)),
		", ".join(PackedStringArray(placeholders))
	]
	
	print("📝 Ejecutando INSERT: ", sql)
	print("📝 Valores: ", values)
	
	if query(sql, values):
		# Obtener el último ID insertado
		if db.has_method("last_insert_rowid"):
			var id = db.last_insert_rowid
			print("✅ Insertado en " + table + " con ID: " + str(id))
			return id
		else:
			# Intentar obtener el ID con una consulta SELECT
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
	
	# Agregar parámetros WHERE
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

func close():
	if db:
		db.close_db()

# Función para verificar si una tabla existe
func table_exists(table_name: String) -> bool:
	var sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
	var result = select_query(sql, [table_name])
	return result and result.size() > 0

# Función para obtener información de la base de datos
func get_database_info() -> Dictionary:
	var info = {
		"path": database_path,
		"tables": []
	}
	
	var tables = select_query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
	for table in tables:
		info["tables"].append(table["name"])
	
	return info

# Función para obtener la estructura de una tabla
func get_table_structure(table_name: String) -> Array:
	return select_query("PRAGMA table_info(%s)" % table_name)

# Función para ejecutar consultas en lote
func execute_batch(sql_commands: Array) -> bool:
	for sql in sql_commands:
		if not query(sql):
			return false
	return true

# Función para contar registros en una tabla
func count(table: String, where: String = "", params = []) -> int:
	var sql = "SELECT COUNT(*) as count FROM %s" % table
	if where:
		sql += " WHERE " + where
	
	var result = select_query(sql, params)
	if result and result.size() > 0:
		return int(result[0]["count"])
	return 0
	
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
	
	# Declarar la variable results aquí, al inicio de la función
	var results = []
	
	# Método 1: Si el addon tiene fetch_array()
	if db.has_method("fetch_array"):
		var row = db.fetch_array()
		while row != null and row.size() > 0:
			# Convertir array a diccionario
			var dict = {}
			var column_names = obtener_nombres_columnas()
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
		# Intentar método alternativo
		print("⚠️ No se pudo obtener resultados, usando método alternativo")
		results = metodo_alternativo_obtener_resultados()
	
	return results

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

func test_conexion():
	print("\n🧪 TEST DE CONEXIÓN A BD")
	
	# Verificar si podemos ejecutar una consulta simple
	var test_sql = "SELECT 1 as test_value"
	var result = select_query(test_sql)
	
	if result != null and result.size() > 0:
		print("✅ Test de conexión exitoso")
		print("   Resultado: " + str(result[0]))
	else:
		print("❌ Test de conexión falló")
	
	# Verificar tablas de nuevo
	var tablas = select_query("SELECT name FROM sqlite_master WHERE type='table'")
	if tablas != null:
		print("📋 Tablas en BD: " + str(tablas.size()))
		for tabla in tablas:
			print("   - " + tabla["name"])
			
func inspeccionar_bd():
	print("=== INSPECCIÓN DE BD ===")
	
	# 1. Verificar si self es un objeto válido
	print("Tipo de self: ", typeof(self))
	
	# 2. Verificar propiedades disponibles en self
	print("\nPropiedades de self (BD):")
	for propiedad in get_property_list():
		if propiedad.name not in ["script", "Script Variables", "Node"]:
			print("  - ", propiedad.name, " (", typeof(get(propiedad.name)), ")")
	
	# 3. Verificar métodos disponibles en self
	print("\nMétodos de self (BD):")
	var metodos = get_method_list()
	for metodo in metodos:
		if metodo.name.find("_") != 0:  # Excluir métodos privados
			print("  - ", metodo.name)
			
			# Mostrar parámetros si los tiene
			if metodo.args and metodo.args.size() > 0:
				print("    Parámetros: ", metodo.args)
	
	# 4. Verificar db específicamente
	print("\nPropiedades de db:")
	if db != null:
		print("  Tipo de db: ", typeof(db))
		
		# Intentar obtener métodos del objeto db
		if db.has_method("get_method_list"):
			var metodos_db = db.get_method_list()
			print("  Métodos disponibles en db:")
			for metodo_db in metodos_db:
				if metodo_db.name.find("_") != 0:
					print("    - ", metodo_db.name)
		else:
			# Si no tiene get_method_list, mostrar algunas propiedades conocidas
			print("  db es un objeto de tipo: ", db)
			# Intentar algunas propiedades comunes
			for prop in ["path", "open", "last_error", "error"]:
				if db.get(prop) != null:
					print("    - ", prop, ": ", db.get(prop))
	
	# 5. Probar algunas operaciones comunes
	print("\n=== PRUEBAS DE OPERACIONES ===")
	
	# Probar select_query
	print("\nProbando select_query...")
	var resultado_select = select_query("SELECT 1 as test")
	print("  Resultado: ", resultado_select)
	print("  Tipo: ", typeof(resultado_select))
	
	# Probar table_exists
	print("\nVerificando tabla 'quejas_reclamaciones'...")
	var existe = table_exists("quejas_reclamaciones")
	print("  Existe: ", existe)
	
	# 6. Inspeccionar estructura de respuesta
	if resultado_select != null and typeof(resultado_select) == TYPE_ARRAY:
		print("\nEstructura de array resultante:")
		print("  Tamaño: ", resultado_select.size())
		if resultado_select.size() > 0:
			print("  Primer elemento tipo: ", typeof(resultado_select[0]))
			if typeof(resultado_select[0]) == TYPE_DICTIONARY:
				print("  Keys del primer elemento: ", resultado_select[0].keys())
	
	print("\n=== FIN DE INSPECCIÓN ===")
	
func probar_consultas():
	print("\n=== PRUEBA DE CONSULTAS DIFERENTES ===")
	
	# Probar diferentes tipos de consultas
	var consultas = [
		"SELECT * FROM quejas_reclamaciones LIMIT 1",
		"SELECT COUNT(*) as total FROM quejas_reclamaciones",
		"SELECT name FROM sqlite_master WHERE type='table'",
        "PRAGMA table_info(quejas_reclamaciones)"
	]
	
	for consulta in consultas:
		try_query(consulta)
		
func try_query(sql: String):
	print("\nConsulta: ", sql)
	var result = Bd.select_query(sql)
	print("  Resultado tipo: ", typeof(result))
	
	if typeof(result) == TYPE_ARRAY:
		print("  Tamaño array: ", result.size())
		if result.size() > 0:
			if typeof(result[0]) == TYPE_DICTIONARY:
				print("  Keys: ", result[0].keys())
				if result[0].size() < 10:  # No imprimir demasiado
					print("  Valores: ", result[0])
			else:
				print("  Primer valor: ", result[0])
	elif result != null:
		print("  Valor: ", result)
	else:
		print("  Nulo")

# Función para verificar funciones específicas
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
		"create_table",
		"drop_table"
	]
	
	for funcion in funciones_a_verificar:
		if Bd.has_method(funcion):
			print("✓ ", funcion, " - DISPONIBLE")
		else:
			print("✗ ", funcion, " - NO DISPONIBLE")
